//
//  YuneecMediaUdpDownloader.m
//  YuneecSDK
//
//  Created by Mine on 2017/4/26.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecUdpDownloader.h"
#include "dwf_client_api_extern.h"
#import "YuneecSDKManager.h"
#import "YuneecSDKManager_Communication.h"
#import "YuneecMediaError.h"
#import "YuneecMediaConfig.h"

///< MFi limit
const NSInteger udpMaxPacketSize = (0xF000);

typedef void(^ProgressBlock)(float progress);

@interface YuneecUdpDownloader ()
{
    void *downloader;
    char json[1024*1024];
}

@property (nonatomic, copy) ProgressBlock   progressBlock;
@property (nonatomic, copy) NSString        *udpAddress;
@property (nonatomic, assign) int           udpPort;
@property (nonatomic, assign) int     maxPacketSize;
@property (nonatomic, assign) BOOL          stopDownload;   ///< stop download, stop query progress
@property (nonatomic, assign) BOOL          pauseDownload;  ///< pause download, pause query progress

@property (nonatomic, strong) dispatch_source_t progressTimer;
@property (nonatomic, assign) NSInteger         lastProgress;
@end

@implementation YuneecUdpDownloader

- (instancetype)init {
    self = [super init];
    if (self) {

        downloader = yuneec_download_instance_new(NULL, 1, FALSE, self.maxPacketSize, self.udpAddress.UTF8String, self.udpPort);
    }
    return self;
}

- (void)dealloc {
    if(self.progressTimer != nil) {
        dispatch_source_cancel(self.progressTimer);
        self.progressTimer = nil;
    }
    [self deallocDownloader];
}

- (void)deallocDownloader {
    if (downloader != NULL) {
        yuneec_download_instance_destroy(downloader);
        downloader = nil;
    }
}

#pragma mark - public

- (void)queryFileListWithBlock:(void(^ _Nonnull)(NSError *_Nullable error, NSArray *_Nullable fileArray))block {

    NSInteger ret = 0, retry = 2;
    // Retry one more time if querying the file list fails.
    do {
        ret = yuneec_download_get_jsonlist(downloader, 0X01, json, sizeof(json), 5000);
        if((ret != 0) && retry > 0) {
            [NSThread sleepForTimeInterval:1.0f];
        }
    } while (ret && --retry);
    if (ret != 0) {
        block([self getDownloadError:ret], nil);
    }else {
        // ASCII
        NSString *jsonString = [[NSString alloc] initWithBytes:json length:sizeof(json) encoding:(NSASCIIStringEncoding)];
        jsonString = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
        // UTF8 string
        // NSString *jsonString = [[NSString alloc] initWithUTF8String:json];

        NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;

        if (data.length < 1) {
            block(convertCameraMediaErrorCodeToNSError(YuneecMediaErrorBuildJSONDataError), nil);
            return;
        }

        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves |NSJSONWritingPrettyPrinted error:&error];
//        NSLog(@"++++dic:%@", dic);
        if (error) {
            block(convertCameraMediaErrorCodeToNSError(YuneecMediaErrorBuildJSONDataError), nil);
        }else {
            id objects = dic[@"media"];
            if ([objects isKindOfClass:[NSArray class]]) {
                NSArray *fileArray = objects;
                NSMutableArray *removedDNGMediasArray = [NSMutableArray arrayWithCapacity:0];
                for (int i = 0; i < fileArray.count; i++) {
                    @autoreleasepool {
                        id mediaObject = fileArray[i];
                        if ([mediaObject isKindOfClass:[NSDictionary class]]) {
                            NSDictionary *mediaDictionary = mediaObject;
                            if (![mediaDictionary[@"fileType"] isEqualToString:@"DNG"]) {
                                mediaObject[@"hasDNG"]= @(0);
                                [removedDNGMediasArray addObject:mediaObject];
                            }
                            else {
                                if (i - 1 >= 0) {
                                    id upMediaObject = fileArray[i - 1];
                                    if ([upMediaObject isKindOfClass:[NSDictionary class]]) {
                                        NSString *currentFileName = mediaObject[@"fileName"];
                                        NSString *upfileName = upMediaObject[@"fileName"];
                                        if ([currentFileName.stringByDeletingPathExtension isEqualToString:upfileName.stringByDeletingPathExtension]) {
                                            upMediaObject[@"hasDNG"] = @(1);
                                        }
                                        else {
                                            NSLog(@"+++ not find right JPG file.");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                if (removedDNGMediasArray.count > 0) {
                    block(nil, removedDNGMediasArray.copy);
                    return;
                }
            }
            block(convertCameraMediaErrorCodeToNSError(YuneecMediaErrorEmptyMedia), nil);
        }
    }
}

- (void)downdloadWithFileName:(NSString *)fileName storagePath:(NSString *)storagePath progressBlock:(void(^)(float progress))progressBlock completion:(void(^)(NSError *error))completion {

    self.stopDownload = NO;
    self.pauseDownload = NO;

    // create downloader
    dispatch_async(dispatch_queue_create("yuneec_download_get_jsonlist", DISPATCH_QUEUE_SERIAL), ^{
        NSInteger ret = yuneec_download_file_start(downloader, fileName.UTF8String, storagePath.UTF8String, 5000);
        self.progressBlock = nil;
        if (ret != 0) {
            // download cancelled by user
            if (ret == YNC_ERR_STOP_DOWNLOAD_FILE) {
                return;
            }
            completion([self getDownloadError:ret]);
        }else {
            completion(nil);
        }
    });

    if (progressBlock == nil) {
        return;
    }else {
        self.progressBlock = progressBlock;
        [self queryDownloadProgress];
    }

}

- (void)stopDownloadWithBlock:(void (^)(NSError * _Nullable))block {

    self.stopDownload = YES;

    NSInteger ret = yuneec_download_file_quit(downloader);
    if (ret != 0) {
        block([self getDownloadError:ret]);
    }else {
        block(nil);
    }

    self.progressBlock = nil;
    if(self.progressTimer != nil) {
        dispatch_source_cancel(self.progressTimer);
        self.progressTimer = nil;
    }
}

- (void)pauseDownloadWithBlock:(void (^)(NSError * _Nullable))block {

    self.pauseDownload = YES;

    NSInteger ret = yuneec_download_file_pause(downloader);
    if (ret != 0) {
        block([self getDownloadError:ret]);
    }else {
        block(nil);
    }
}

- (void)resumeDownloadWithBlock:(void (^)(NSError * _Nullable))block {
    self.pauseDownload = NO;

    NSInteger ret = yuneec_download_file_resume(downloader);
    if (ret != 0) {
        block([self getDownloadError:ret]);
    }else {
        block(nil);

        // continue to query progress
        [self queryDownloadProgress];
    }
}

- (void)deleteFiles:(NSArray<NSString *> *)fileNameArray block:(void (^)(NSError *))block {

    NSDictionary *jsonDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:fileNameArray,@"media", nil];

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];

    if (error) {
        block(convertCameraMediaErrorCodeToNSError(YuneecMediaErrorBuildJSONDataError));
        return;
    }

    NSInteger ret = yuneec_download_file_delete(downloader, (char *)jsonData.bytes, (int)jsonData.length, 5000);

    if (ret != 0) {
        block([self getDownloadError:ret]);
    }else {
        block(nil);
    }
}

#pragma mark - private

- (void)queryDownloadProgress {

    if (self.progressBlock == nil) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        // query download progress
        self.progressTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
        dispatch_source_set_timer(self.progressTimer, DISPATCH_TIME_NOW, 200 * NSEC_PER_MSEC, 0.0);

        _lastProgress = 0;
        dispatch_source_set_event_handler(self.progressTimer, ^{
            NSInteger currentProgress = yuneec_download_get_progress(downloader);
            if (currentProgress > 0 && currentProgress < 100 && self.progressBlock != nil && !self.stopDownload){
//                NSLog(@"download progress = %ld", currentProgress);
                self.progressBlock(currentProgress / 100.0);
                _lastProgress = currentProgress;
            }
            else {
                dispatch_source_cancel(self.progressTimer);
                self.progressTimer = nil;
            }
        });
        dispatch_resume(self.progressTimer);
    });
}

- (NSError *)getDownloadError:(YuneecUdpDownloaderError)errorCode {
    NSString *errorString = [self getDownloadErrorString:errorCode];
//    NSLog(@"*****errorString:%@", errorString);
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: errorString};
    return [NSError errorWithDomain:@"com.yuneec.yuneecsdk.cameraDownloader" code:errorCode userInfo:userInfo];
}

- (NSString *)getDownloadErrorString:(YuneecUdpDownloaderError)errorCode {
    switch (errorCode) {
        case YNC_ERR_NONE:
            return @"Download success.";
        case YNC_ERR_CRC:
            return @"Download failed, packet data crc error.";
        case YNC_ERR_TOTAL_CRC:
            return @"Download failed, file data crc error.";
        case YNC_ERR_FILE_NOT_EXIST:
            return @"Download failed, file not exists at server.";
        case YNC_ERR_FILE_TOO_BIG:
            return @"Download failed, file size too big.";
        case YNC_ERR_APP_CREATE_FILE:
            return @"Download failed, create file failed.";
        case YNC_ERR_CAM_OPEN_FILE:
            return @"Download failed, camera open file failed.";
        case YNC_ERR_PAUSE:
            return @"Download failed, pause download failed.";
        case YNC_ERR_RESTART:
            return @"Download failed, restart download failed.";
        case YNC_ERR_RESPONSE_FILELIST:
            return @"Download failed, receive file list from server failed.";
        case YNC_ERR_QUIT:
            return @"Download failed, cancel download failed.";
        case YNC_ERR_BAD_PARAMETER:
            return @"Download failed, parameter error.";
        case YNC_ERR_TIMEOUT:
            return @"Download failed, package send timeout.";
        case YNC_ERR_WRONG_SOCKFD:
            return @"Download failed, wrong socket.";
        case YNC_ERR_CONFIG:
            return @"Download failed, network error.";
        case YNC_ERR_DELETE_FILE:
            return @"Download failed, delete file failed.";
        case YNC_ERR_STOP_DOWNLOAD_FILE:
            return @"Stop download file success.";
        default:
            return @"Unknown error.";
    }
}

#pragma mark - set & get

- (int)maxPacketSize {
    YuneecSDKManager *manager = [YuneecSDKManager sharedInstance];
    if (manager.customMediaTransferPacketSize > 0) {
        return (int)[YuneecSDKManager sharedInstance].customMediaTransferPacketSize;
    }

    return (int)udpMaxPacketSize;
}

- (int)udpPort {
    if ([YuneecSDKManager sharedInstance].useCustomMediaCommunication) {
        return (int)[YuneecSDKManager sharedInstance].customMediaPort;
    }
    return (int)[YuneecSDKManager sharedInstance].cameraMediaDownloadPort;
}

- (NSString *)udpAddress {
    if ([YuneecSDKManager sharedInstance].useCustomMediaCommunication) {
        return [YuneecSDKManager sharedInstance].customMediaIpAddress;
    }
    return [YuneecSDKManager sharedInstance].cameraIpAddress;
}

@end
