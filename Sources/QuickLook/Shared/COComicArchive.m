#import "COComicArchive.h"
#import <XADMaster/XADArchive.h>
#import <XADMaster/CSHandle.h>
#import <ImageIO/ImageIO.h>

static const NSUInteger COMaxEntryBytes = 32 * 1024 * 1024;
static const unsigned long long COMaxArchiveBytes = 256ULL * 1024 * 1024;
static NSError *COComicError(NSString *message) {
    return [NSError errorWithDomain:@"jp.coo.cooViewer.QuickLook" code:1
                          userInfo:@{NSLocalizedDescriptionKey: message}];
}
static BOOL COSafeImageName(NSString *name) {
    if (!name.length || [name hasPrefix:@"/"] || [name containsString:@"\\"] ||
        [name containsString:@":"]) return NO;
    for (NSString *component in name.pathComponents) {
        if ([component isEqualToString:@".."] || [component hasPrefix:@"."] ||
            [component isEqualToString:@"__MACOSX"]) return NO;
    }
    // ImageIO decodes these on the host OS; unsupported codecs are skipped.
    return [@[@"jpg", @"jpeg", @"png", @"gif", @"bmp", @"tif", @"tiff",
              @"heic", @"heif", @"webp", @"avif"] containsObject:name.pathExtension.lowercaseString];
}
@implementation COComicArchive {
    NSURL *_url;
    NSArray<NSNumber *> *_indices;
    NSDictionary *_fileAttributes;
}
- (XADArchive *)openArchive:(NSError **)error {
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:_url.path error:error];
    if (![_url isFileURL] || ![attributes[NSFileType] isEqual:NSFileTypeRegular] ||
        [attributes[NSFileSize] unsignedLongLongValue] > COMaxArchiveBytes ||
        (_fileAttributes && (![attributes[NSFileSize] isEqual:_fileAttributes[NSFileSize]] ||
                            ![attributes[NSFileModificationDate] isEqual:_fileAttributes[NSFileModificationDate]]))) {
        if (error) *error = COComicError(@"Archive is unavailable, changed, or exceeds the 256 MiB limit.");
        return nil;
    }
    XADError xadError = XADNoError;
    XADArchive *archive = [[XADArchive alloc] initWithFile:_url.path error:&xadError];
    if (!archive || archive.isEncrypted || archive.isSolid || archive.numberOfEntries > 10000 || archive.numberOfEntries < 0) {
        if (error) *error = COComicError(@"Unsupported, encrypted, solid, damaged, or oversized archive.");
        return nil;
    }
    return archive;
}
- (instancetype)initWithURL:(NSURL *)url error:(NSError **)error {
    if (!(self = [super init])) return nil;
    NSTimeInterval started = NSProcessInfo.processInfo.systemUptime;
    _url = [url copy];
    if (![@[@"cbz", @"cbr", @"zip", @"rar"] containsObject:url.pathExtension.lowercaseString]) {
        if (error) *error = COComicError(@"Only CBZ, CBR, ZIP and RAR archives are supported.");
        return nil;
    }
    @try {
        XADArchive *archive = [self openArchive:error];
        if (!archive) return nil;
        NSMutableArray<NSDictionary *> *pages = [NSMutableArray array];
        for (int i = 0; i < archive.numberOfEntries; i++) {
            NSString *name = [archive nameOfEntry:i];
            if (!COSafeImageName(name) || [archive entryIsDirectory:i] || [archive entryIsLink:i] ||
                [archive entryIsEncrypted:i] || ![archive entryHasSize:i]) continue;
            off_t size = [archive uncompressedSizeOfEntry:i];
            if (size <= 0 || size > COMaxEntryBytes) continue;
            [pages addObject:@{@"name": name, @"index": @(i)}];
        }
        [pages sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            NSComparisonResult result = [a[@"name"] localizedStandardCompare:b[@"name"]];
            return result == NSOrderedSame ? [a[@"index"] compare:b[@"index"]] : result;
        }];
        _pageNames = [pages valueForKey:@"name"];
        _indices = [pages valueForKey:@"index"];
        _enumerationSeconds = NSProcessInfo.processInfo.systemUptime - started;
        _fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:error];
        if (!_pageNames.count) {
            if (error) *error = COComicError(@"No supported image pages were found.");
            return nil;
        }
    } @catch (NSException *exception) {
        if (error) *error = COComicError(@"Unable to read the archive.");
        return nil;
    }
    return self;
}
- (NSImage *)imageAtPage:(NSUInteger)page maxPixelSize:(NSUInteger)pixels error:(NSError **)error {
    if (page >= _indices.count) {
        if (error) *error = COComicError(@"Page is out of range.");
        return nil;
    }
    _imageReadAttempts++;
    @try {
        XADArchive *archive = [self openArchive:error];
        if (!archive) return nil;
        int index = _indices[page].intValue;
        if (index >= archive.numberOfEntries || ![[archive nameOfEntry:index] isEqual:_pageNames[page]]) {
            if (error) *error = COComicError(@"Archive changed while previewing.");
            return nil;
        }
        CSHandle *handle = [archive handleForEntry:index];
        NSMutableData *data = [NSMutableData data];
        NSTimeInterval deadline = NSProcessInfo.processInfo.systemUptime + 3.0;
        uint8_t buffer[32768];
        while (handle && data.length <= COMaxEntryBytes) {
            if (NSProcessInfo.processInfo.systemUptime > deadline) break;
            int count = [handle readAtMost:(int)MIN(sizeof(buffer), COMaxEntryBytes + 1 - data.length) toBuffer:buffer];
            if (count <= 0) {
                if (!data.length) break;
                NSTimeInterval decodeStarted = NSProcessInfo.processInfo.systemUptime;
                _imageDecodeAttempts++;
                CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
                NSDictionary *properties = source ? CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL)) : nil;
                double width = [properties[(id)kCGImagePropertyPixelWidth] doubleValue];
                double height = [properties[(id)kCGImagePropertyPixelHeight] doubleValue];
                if (width <= 0 || height <= 0 || width > 20000 || height > 20000 || width * height > 40000000) {
                    if (source) CFRelease(source);
                    _imageDecodeSeconds += NSProcessInfo.processInfo.systemUptime - decodeStarted;
                    break;
                }
                CGImageRef image = source ? CGImageSourceCreateThumbnailAtIndex(source, 0,
                    (__bridge CFDictionaryRef)@{(id)kCGImageSourceCreateThumbnailFromImageAlways: @YES,
                       (id)kCGImageSourceCreateThumbnailWithTransform: @YES,
                       (id)kCGImageSourceThumbnailMaxPixelSize: @(MAX(1, MIN(pixels, 4096))),
                       (id)kCGImageSourceShouldCacheImmediately: @YES}) : NULL;
                if (source) CFRelease(source);
                _imageDecodeSeconds += NSProcessInfo.processInfo.systemUptime - decodeStarted;
                if (image) {
                    _decodedImageCount++;
                    NSImage *result = [[NSImage alloc] initWithCGImage:image size:NSZeroSize];
                    CGImageRelease(image);
                    return result;
                }
                break;
            }
            [data appendBytes:buffer length:(NSUInteger)count];
        }
    } @catch (NSException *exception) { /* Corrupt archives fail without UI or extraction. */ }
    if (error) *error = COComicError(@"This page is unreadable or exceeds resource limits.");
    return nil;
}
- (NSImage *)firstReadableImageWithMaxPixelSize:(NSUInteger)pixels page:(NSUInteger *)page error:(NSError **)error {
    NSTimeInterval deadline = NSProcessInfo.processInfo.systemUptime + 5.0;
    // Bound retries: corrupt or unsupported images must not scan an entire book.
    for (NSUInteger i = 0; i < MIN(_pageNames.count, 8); i++) {
        @autoreleasepool {
            NSImage *image = [self imageAtPage:i maxPixelSize:pixels error:NULL];
            if (image) { if (page) *page = i; return image; }
        }
        if (NSProcessInfo.processInfo.systemUptime > deadline) break;
    }
    if (error) *error = COComicError(@"No readable cover within the first eight image candidates.");
    return nil;
}
@end
