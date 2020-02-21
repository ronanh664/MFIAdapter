//
//  YuneecMedia.m
//  YuneecSDK
//
//  Created by Mine on 2017/3/9.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecMedia.h"
#import "YuneecMedia_Extension.h"
#import "YuneecUdpDownloader.h"
#import "YuneecMediaError.h"
#import <BaseFramework/BaseFramework.h>

@interface YuneecMedia ()
@property (nonatomic, strong) dispatch_queue_t fetchMediaQueue;
@end

@implementation YuneecMedia

#pragma mark - kvo

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    // do nothing
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"fileType"]) {
        self.mediaType = [self getMediaType:value];
    }
    else if ([key isEqualToString:@"duration"]) {
        self.videoDuration = [value floatValue];
    }
    else if ([key isEqualToString:@"imgWidth"]) {
        self.videoResolution = [self getVideoResolution:[value integerValue]];
    }
    else if ([key isEqualToString:@"hasDNG"]) {
        self.hasDNG = ((NSNumber *)value).boolValue;
    }
    else {
        [super setValue:value forKey:key];
    }
}

#pragma mark - public method

- (void)fetchThumbnailWithFilePath:(NSString *)filePath block:(void (^)(NSError * _Nullable))block {
    
    NSString *fileName = self.thumbnailMedia.fileName;
    [self fetchMediaDataWithFileName:fileName filePath:filePath progress:nil block:block];
}

- (void)fetchImageDataWithFilePath:(NSString *)filePath progress:(void (^)(float, BOOL * _Nullable))progress block:(void (^)(NSError * _Nullable))block {
    
    NSString *fileName = self.fileName;
    [self fetchMediaDataWithFileName:fileName filePath:filePath progress:progress block:block];
}

- (void)fetchVideoDataWithFilePath:(NSString *)filePath progress:(void (^)(float, BOOL * _Nullable))progress block:(void (^)(NSError * _Nullable))block {
    
    NSString *fileName = self.fileName;
    [self fetchMediaDataWithFileName:fileName filePath:filePath progress:progress block:block];
}

- (void)fetchPreviewVideoDataWithFilePath:(NSString *)filePath progress:(void (^)(float, BOOL * _Nullable))progress block:(void (^)(NSError * _Nullable))block {
    
    NSString *fileName = self.previewMedia.fileName;
    [self fetchMediaDataWithFileName:fileName filePath:filePath progress:progress block:block];
}

#pragma mark - media download

- (void)fetchMediaDataWithFileName:(NSString *)fileName filePath:(NSString *)filePath progress:(void (^)(float, BOOL * _Nullable))progress block:(void (^)(NSError * _Nullable))block {

    NSString *tempDirectory = [self getTempDirectory:fileName];
    
    if (fileName == nil) {
        block(convertCameraMediaErrorCodeToNSError(YuneecMediaErrorNoSuchFile));
        return;
    }
    // create fetch media queue
    YuneecUdpDownloader *downloader = [[YuneecUdpDownloader alloc] init];
    dispatch_async(self.fetchMediaQueue, ^{
        
        if (progress == NULL) {
            // start download without progress
            [downloader downdloadWithFileName:fileName storagePath:tempDirectory progressBlock:nil completion:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        //NSLog(@"-------fetch media error: %@, %@", error, filePath);
                        block(error);
                    }else {
                        NSString *tempPath = [tempDirectory stringByAppendingPathComponent:fileName];
                        BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:tempPath];
                        if (isExist) {
                            BOOL success = moveFileToPath(tempPath, filePath, nil);
                            if (success) {
                                block(nil);
                            }else {
                                block(convertCameraMediaErrorCodeToNSError(YuneecMediaErrorMoveMediaFailure));
                            }
                        }
                    }
                });
            }];

        }else {
            // start download with progress
            [downloader downdloadWithFileName:fileName storagePath:tempDirectory progressBlock:^(float currentProgress) {
                BOOL isStop = NO;
                progress(currentProgress, &isStop);
                if (isStop) {
                    
                    [downloader stopDownloadWithBlock:^(NSError * _Nullable error) {
                        if (error) {
                            //NSLog(@"Fail to stop download: %@", error);
                        }
                    }];
                }
            } completion:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        [downloader stopDownloadWithBlock:^(NSError * _Nullable error) {
                            if (error) {
                                //NSLog(@"Fail to stop download: %@", error);
                            }
                        }];
                        block(error);
                    }else {
                        NSString *tempPath = [tempDirectory stringByAppendingPathComponent:fileName];
                        BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:tempPath];
                        if (isExist) {
                            BOOL success = moveFileToPath(tempPath, filePath, nil);
                            if (success) {
                                block(nil);
                            }else {
                                block(convertCameraMediaErrorCodeToNSError(YuneecMediaErrorMoveMediaFailure));
                            }
                        }
                    }
                });
            }];
        }
    });
}

#pragma mark - helper

- (YuneecMediaVideoResolution)getVideoResolution:(NSInteger) videoWidth {
    switch(videoWidth)
    {
        case 4096:
            return YuneecMediaVideoResolution4096x2160;
        case 3840:
            return YuneecMediaVideoResolution3840x2160;
        case 2720:
            return YuneecMediaVideoResolution2720x1530;
        case 2704:
            return YuneecMediaVideoResolution2704x1520;
        case 2560:
            return YuneecMediaVideoResolution2560x1440;
        case 1920:
            return YuneecMediaVideoResolution1920x1080;
        case 1280:
            return YuneecMediaVideoResolution1280x720;
        default:
            return YuneecMediaVideoResolutionUnknown;
    }
    return YuneecMediaVideoResolutionUnknown;
}

- (YuneecMediaType)getMediaType:(NSString *)mediaType {
    if ([mediaType isEqualToString:@"JPG"] || [mediaType isEqualToString:@"jpg"] || [mediaType isEqualToString:@"JPEG"] || [mediaType isEqualToString:@"jpeg"]) {
        return YuneecMediaTypeJPEG;
    }else if ([mediaType isEqualToString:@"DNG"] || [mediaType isEqualToString:@"dng"]) {
        return YuneecMediaTypeDNG;
    }else if ([mediaType isEqualToString:@"MP4"] || [mediaType isEqualToString:@"mp4"] || [mediaType isEqualToString:@"MOV"] || [mediaType isEqualToString:@"mov"]) {
        return YuneecMediaTypeMP4;
    }else if ([mediaType isEqualToString:@"THM"] || [mediaType isEqualToString:@"thm"]) {
        return YuneecMediaTypeThm;
    }else if ([mediaType isEqualToString:@"2ND"] || [mediaType isEqualToString:@"2nd"]) {
        return YuneecMediaType2nd;
    }
    return YuneecMediaTypeUnknown;
}

- (NSString *)getFilePath:(NSString *)filePath fileName:(NSString *)fileName {
    
    if ([filePath hasSuffix:@"/"] && filePath.length > 1) {
        filePath = [filePath substringWithRange:NSMakeRange(0, filePath.length)];
    }
    createDirectoryIfNotExists(filePath, nil);
    NSString *fullPath = [filePath stringByAppendingPathComponent:fileName];
    if (fileExistsAtPath(fullPath)) {
        deleteFileAtPath(fullPath, nil);
    }
    return fullPath;
}

- (NSString *)getTempDirectory:(NSString *)fileName {
    NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"YuneecTemp"];
    createDirectoryIfNotExists(directory, nil);
    NSString *path = [directory stringByAppendingPathComponent:fileName];
    if (fileExistsAtPath(path)) {
        deleteFileAtPath(path, nil);
    }
    return directory;
}

#pragma mark - lazy

- (dispatch_queue_t)fetchMediaQueue
{
    if (!_fetchMediaQueue) {
        _fetchMediaQueue = dispatch_queue_create("com.yuneecsdk.fetchMediaQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _fetchMediaQueue;
}

@end
