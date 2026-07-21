//
//  XADWrapper.m
//  cooViewer
//
//  Created by coo on 08/01/20.
//  Copyright 2008 coo. All rights reserved.
//

#import "XADWrapper.h"
#import "XADItem.h"
#import <errno.h>


@implementation XADWrapper

static BOOL COXADCanOpenArchivePath(NSString *path)
{
	if (![[NSFileManager defaultManager] isReadableFileAtPath:path]) {
		NSLog(@"cooViewer XADWrapper open failed: path=%@ not readable", path);
		return NO;
	}
	FILE *file = fopen([path fileSystemRepresentation], "rb");
	if (!file) {
		NSLog(@"cooViewer XADWrapper open failed: path=%@ errno=%d", path, errno);
		return NO;
	}
	fclose(file);
	return YES;
}

-(id)initWithPath:(NSString*)path{
    self = [super init];
    if (self) {
        NSTimeInterval archiveStartTime = [NSDate timeIntervalSinceReferenceDate];
        NSLog(@"cooViewer XADWrapper open begin: path=%@", path);
        if (!COXADCanOpenArchivePath(path)) {
            [self release];
            return nil;
        }
        XADError error = XADNoError;
        archive = [[XADArchive alloc] initWithFile:path error:&error];
        if (!archive) {
            NSLog(@"cooViewer XADWrapper open failed: path=%@ error=%d",
                  path,
                  error);
            [self release];
            return nil;
        }
        contentArray = [[NSMutableArray array] retain];
        contentIndexArray = [[NSMutableArray array] retain];
        filePath=[path retain];
        
        password=nil;
        
        int i;
        for (i=0; i<[archive numberOfEntries]; i++) {
            [contentIndexArray addObject:[archive nameOfEntry:i]];
            if (![archive entryIsDirectory:i] && [archive sizeOfEntry:i] != 0) {
                [contentArray addObject:[[XADItem alloc] initWithPath:[archive nameOfEntry:i] andWrapper:self]];
            } else {
                //NSLog(@"isdir %@",[archive nameOfEntry:i]);
            }
        }
        NSTimeInterval elapsed = [NSDate timeIntervalSinceReferenceDate] - archiveStartTime;
        if (elapsed >= 1.0) {
            NSLog(@"cooViewer XADWrapper open slow: path=%@ elapsed=%.3f entries=%d contents=%lu",
                  path,
                  elapsed,
                  [archive numberOfEntries],
                  (unsigned long)[contentArray count]);
        }
    }
    return self;
}
- (void)dealloc
{
	if(archive)[archive release];
	if(filePath)[filePath release];
	if(contentArray)[contentArray release];
	if(contentIndexArray)[contentIndexArray release];
	
	[super dealloc];
}



	//access
-(int)itemCount
{
	return [archive numberOfEntries];
}

-(int)xadIndexOfName:(NSString *)name
{
	return (int)[contentIndexArray indexOfObject:name];
}


-(id)itemForPath:(NSString *)path
{
	//NSLog(@"%@ %i",path,[archive _entryIndexOfName:path]);
	return [archive contentsOfEntry:[self xadIndexOfName:path]];
}

-(id)itemAtIndex:(int)index
{
	//使ってない
	//return [archive contentsOfEntry:index];
	return [self itemForPath:[[contentArray objectAtIndex:index] path]];
}

-(id)itemArray
{
	return contentArray;
}
-(id)contents
{
	return contentArray;
}

	//ファイルパス
-(NSString *)filePath
{
	return filePath;
}

-(BOOL)crypted
{
	if ([archive isEncrypted]) {
		return YES;
	}
	return NO;
}

-(NSString *)password
{
	return password;
}

-(void)setPassword:(NSString *)inStr
{
	if(password)[password release];
	password=nil;
	if(inStr){
		password=[inStr retain];
		[archive setPassword:password];
	}
}

-(XADArchive*)archive
{
	return archive;
}

-(NSStringEncoding)encoding
{
	return [archive nameEncoding];
}

-(BOOL)uncompress:(int)index as:(NSString*)fileName
{
	return [archive _extractEntry:[self xadIndexOfName:[[contentArray objectAtIndex:index] path]] as:fileName deferDirectories:NO dataFork:YES resourceFork:YES];
}
@end
