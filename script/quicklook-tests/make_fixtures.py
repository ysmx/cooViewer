"""Synthetic, nonpersonal archives for the Quick Look smoke tests."""
import binascii, pathlib, struct, subprocess, sys, zipfile, zlib
out = pathlib.Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
def png(rgb):
    def chunk(t, d):
        return struct.pack('>I', len(d)) + t + d + struct.pack('>I', binascii.crc32(t+d)&0xffffffff)
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 48, 64, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress((b'\0'+bytes(rgb)*48)*64)) + chunk(b'IEND', b'')
def make_zip(name, entries):
    with zipfile.ZipFile(out/name, 'w', zipfile.ZIP_DEFLATED) as z:
        for path, data in entries: z.writestr(path, data)
# RAR 4.x stored entries; independently generated from the public format layout.
def header(typ, flags, body):
    h = struct.pack('<BHH', typ, flags, 7+len(body)) + body
    return struct.pack('<H', binascii.crc32(h)&0xffff)+h
def make_rar(name, entries):
    rar = b'Rar!\x1a\x07\x00' + header(0x73, 0, b'\0'*6)
    for path, data in entries:
        n=path.encode(); body=struct.pack('<IIBIIBBHI',len(data),len(data),3,binascii.crc32(data)&0xffffffff,0,20,0x30,len(n),0x20)+n
        rar += header(0x74,0x8000,body)+data
    rar += header(0x7b,0,b'')
    (out/name).write_bytes(rar)
red, blue = png((240,40,40)), png((30,80,240))
for ext in ['cbz','zip','cbr','rar']:
    make = make_zip if ext in ['cbz','zip'] else make_rar
    normal = [('page10.png', blue), ('page2.png', red)]
    make('normal.'+ext, normal)
    make('mixed.'+ext, [('00-readme.txt', b'not a page'), ('payload.bin', b'not a page'),
                         ('__MACOSX/cover.png', blue), ('.hidden.png', blue)]+normal)
    make('empty.'+ext, [('readme.txt', b'no images'), ('payload.bin', b'data')])
    make('fallback.'+ext, [('1.png', b'not an image'), ('2.png', red)])
    # Truncate a real format header, rather than only testing random text.
    (out/('broken.'+ext)).write_bytes((out/('normal.'+ext)).read_bytes()[:12])
make_zip('changed.cbz', [('1.png', red)])
with zipfile.ZipFile(out/'symlink.cbz', 'w') as z:
    link = zipfile.ZipInfo('1.png'); link.create_system = 3
    link.external_attr = (0o120777 << 16)
    z.writestr(link, '/tmp/cooviewer-must-not-follow.png')
make_zip('unsafe.cbz', [('../cover.png', red), ('/cover.png', red), ('__MACOSX/cover.png', red), ('.hidden.png', red)])
make_zip('large-entry.cbz', [('1.png', b'0'*(32*1024*1024+1))])
make_zip('many.cbz', [(str(i)+'.txt', b'x') for i in range(10001)])
with open(out/'large-archive.cbz', 'wb') as f: f.truncate(256*1024*1024+1)
(out/'cover.png').write_bytes(red)
for ext in ['cbz','zip']:
    subprocess.run(['/usr/bin/zip', '-q', '-j', '-P', 'test-only', str(out/('encrypted.'+ext)), str(out/'cover.png')], check=True)
# Large, lossless pages with a visible grid and colored header/footer for fit/quality QA.
def quality_png(number, width=1600, height=2400):
    grid = b'\0'+b''.join(bytes((100,100,100) if x % 160 < 3 else (245,245,245)) for x in range(width))
    horizontal = b'\0'+bytes((90,90,90))*width
    color = (220,45,45) if number == 1 else (35,70,220)
    band = b'\0'+bytes(color)*width
    encoder = zlib.compressobj(); compressed = []
    for y in range(height):
        row = band if y < height//10 or y >= height-height*3//40 else horizontal if y % 160 < 3 else grid
        compressed.append(encoder.compress(row))
    compressed.append(encoder.flush())
    def chunk(t, d):
        return struct.pack('>I',len(d))+t+d+struct.pack('>I',binascii.crc32(t+d)&0xffffffff)
    return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',width,height,8,2,0,0,0))+chunk(b'IDAT',b''.join(compressed))+chunk(b'IEND',b'')
make_zip('quality.zip', [('1.png',quality_png(1)), ('2.png',quality_png(2))])
make_zip('many-pages.zip', [(f'{i:03}.png',page) for page in [quality_png(1)] for i in range(70)])
make_zip('fallback-many.zip', [('0.png',b'broken image'),('1.png',quality_png(1)),('2.png',quality_png(2))])
make_zip('large-image.zip', [('1.png',quality_png(1,4000,6000)),('2.png',red)])
print('Created synthetic Quick Look fixtures:', out)
