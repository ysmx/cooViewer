#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN
/// UI-independent, read-only access to comic archives using the app's XADMaster.
/// Never extracts to disk or follows archive links. Each operation closes its file.
@interface COComicArchive : NSObject
@property(nonatomic, readonly) NSArray<NSString *> *pageNames;
@property(nonatomic, readonly) NSUInteger imageReadAttempts;
@property(nonatomic, readonly) NSUInteger imageDecodeAttempts;
@property(nonatomic, readonly) NSUInteger decodedImageCount;
@property(nonatomic, readonly) NSTimeInterval enumerationSeconds;
@property(nonatomic, readonly) NSTimeInterval imageDecodeSeconds;
- (nullable instancetype)initWithURL:(NSURL *)url error:(NSError * _Nullable * _Nullable)error;
- (nullable NSImage *)imageAtPage:(NSUInteger)page maxPixelSize:(NSUInteger)pixels error:(NSError * _Nullable * _Nullable)error;
- (nullable NSImage *)firstReadableImageWithMaxPixelSize:(NSUInteger)pixels page:(NSUInteger * _Nullable)page error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
