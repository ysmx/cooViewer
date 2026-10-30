"""Validate the built app's QL document/type/signature/architecture integration."""
import pathlib, plistlib, subprocess, sys
app = pathlib.Path(sys.argv[1])
def info(bundle):
    return plistlib.loads((bundle/'Contents/Info.plist').read_bytes())
main = info(app)
imports = {d['UTTypeIdentifier']: d for d in main['UTImportedTypeDeclarations']}
for ext, uti in [('cbz','cx.c3.cbz-archive'), ('cbr','cx.c3.cbr-archive'), ('rar','com.rarlab.rar-archive')]:
    assert ext in imports[uti]['UTTypeTagSpecification']['public.filename-extension'], (ext, uti)
for ext, uti in [('zip','public.zip-archive'), ('rar','com.rarlab.rar-archive')]:
    doc = next(d for d in main['CFBundleDocumentTypes'] if ext in d.get('CFBundleTypeExtensions', []))
    assert uti in doc['LSItemContentTypes'], (ext, 'document type mismatch')
    assert doc['CFBundleTypeIconFile'] == 'doc_'+ext, (ext, 'document icon changed')
    assert doc['LSHandlerRank'] == 'Alternate', (ext, 'handler priority changed')
required = {'cx.c3.cbz-archive','cx.c3.cbr-archive','public.zip-archive','com.rarlab.rar-archive','org.7-zip.7-zip-archive','jp.coo.cooViewer.lha-archive','public.tar-archive','org.gnu.gnu-zip-tar-archive','public.tar-bzip2-archive','org.tukaani.tar-xz-archive','public.cpio-archive','com.sun.java-archive'}
for name, point in [('cooViewerThumbnail','thumbnail'),('cooViewerPreview','preview')]:
    bundle = app/'Contents/PlugIns'/(name+'.appex')
    d = info(bundle); e = d['NSExtension']
    assert d['CFBundleShortVersionString'] == main['CFBundleShortVersionString']
    assert d['CFBundleVersion'] == main['CFBundleVersion']
    assert d['LSMinimumSystemVersion'] == '10.15'
    if point == 'preview': assert not e['NSExtensionAttributes'].get('QLIsDataBasedPreview', False)
    assert e['NSExtensionPointIdentifier'] == 'com.apple.quicklook.'+point
    types = set(e['NSExtensionAttributes']['QLSupportedContentTypes'])
    assert required <= types
    assert not types.intersection({'public.archive','public.data','public.image','com.adobe.pdf'})
    print('PASS:', name, 'extended archive UTType declarations and OS boundary')
assert main['LSMinimumSystemVersion'] == '10.14'
for bundle in [app] + sorted((app/'Contents/PlugIns').glob('*.appex')):
    d = info(bundle)
    arches = subprocess.check_output(['lipo','-archs',str(bundle/'Contents/MacOS'/d['CFBundleExecutable'])], text=True).split()
    assert set(arches) == {'arm64','x86_64'}, (bundle.name, arches)
    subprocess.run(['codesign','--verify','--deep','--strict',str(bundle)], check=True)
    signature = subprocess.run(['codesign','-dvv',str(bundle)], capture_output=True, text=True, check=True).stderr
    assert 'Signature=adhoc' in signature and 'TeamIdentifier=not set' in signature
    print('PASS:', bundle.name, 'Universal binary and strict ad hoc signature')
print('PASS: app document icons, Alternate rank, imported types and 10.14 minimum preserved')
