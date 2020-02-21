//
//  TrackingLog.m
//  BaseFramework
//
//  Created by tbago on 17/1/13.
//  Copyright © 2017年 tbago. All rights reserved.
//

#import "TrackingLog.h"
#import "FileUtility.h"
#import "NSDateAndNSStringConversion.h"

@interface TrackingLog()

@property (nonatomic) BOOL                  enableTrackingLog;
@property (nonatomic, copy) NSString        *defaultFilePath;
@property (strong, nonatomic) NSFileHandle  *trackingFileHandle;

@end

@implementation TrackingLog

+ (instancetype)sharedInstance {
    static TrackingLog *sInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[TrackingLog alloc] init];
    });
    return sInstance;
}

#pragma mark - init and dealloc

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)dealloc {
    if (self.trackingFileHandle != nil) {
        [self.trackingFileHandle synchronizeFile];
        [self.trackingFileHandle closeFile];
    }
}

#pragma mark - public method

- (BOOL)initTrackingLog:(BOOL) enableTrackingLog
                newFile:(BOOL) newFile
{
    self.enableTrackingLog = enableTrackingLog;
    if (!enableTrackingLog) {
        return YES;
    }
    
    if (newFile) {
        deleteFileAtPath(self.defaultFilePath, nil);
    }
    
    createFileIfNotExits(self.defaultFilePath, nil);
    
    self.trackingFileHandle = [NSFileHandle fileHandleForWritingAtPath:self.defaultFilePath];
    if (self.trackingFileHandle == nil) {
        return NO;
    }
    [self.trackingFileHandle seekToEndOfFile];
    
    return YES;
}

- (void)logOneInfoWithFormat:(NSString *)format, ... {
    if (!self.enableTrackingLog) {
        return;
    }
    
    va_list args;
    
    if (format) {
        va_start(args, format);
        
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        
        NSLog(@"%@", message);
        
        NSString *currentDateString = convertNSDateToFormatNSString([NSDate date], @"yyyy-MM-dd HH:mm:ss:SSS");
        message = [NSString stringWithFormat:@"%@ %@", currentDateString, message];
        message = [message stringByAppendingString:@"\n"];
        [self logStringToFile:message];
        
        va_end(args);
    }
}
#pragma mark - private method

- (void)logStringToFile:(NSString *) stringValue {
    NSData *logData = [stringValue dataUsingEncoding:NSUTF8StringEncoding];
    
    @try {
        [self.trackingFileHandle writeData:logData];
        
        [self.trackingFileHandle synchronizeFile];
    } @catch (NSException *exception) {
        
    }
}

#pragma mark - get & set

- (NSString *)defaultFilePath {
    if (_defaultFilePath == nil) {
        _defaultFilePath = getDocumentDirectory();
        _defaultFilePath = [_defaultFilePath stringByAppendingPathComponent:@"tracking.log"];
    }
    return _defaultFilePath;
}

@end
