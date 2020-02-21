//
//  YuneecMediaHttp.m
//  YuneecSDK
//
//  Created by Mine on 2017/4/28.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecMediaHttp.h"
#import "YuneecMediaHttp_Extension.h"
#import "YuneecMediaConfig.h"
#import "YuneecMediaError.h"
#import <BaseFramework/BaseFramework.h>

typedef void(^FetchMediaDataBlock)(NSError *_Nullable error);
typedef void(^FetchMediaProgress)(float progress, BOOL *_Nullable stop);

@interface YuneecMediaHttp ()<NSURLSessionDownloadDelegate>
@property (nonatomic, copy) FetchMediaDataBlock fetchMediaDataBlock;
@property (nonatomic, copy) FetchMediaProgress fetchMediaProgress;
@property (nonatomic, copy) NSString *destFilePath;
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation YuneecMediaHttp

#pragma mark - Public methods

- (void)fetchThumbnailWithFilePath:(NSString *)filePath block:(void (^)(NSError * _Nullable))block {
    if (self.serverThumbnailPath == nil) {
        block(convertCameraMediaErrorCodeToNSError(YuneecMediaErrorNoThumnail));
        return;
    }
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = fetchMediaHttpTimeout;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    
    NSURL *url = [NSURL URLWithString:self.serverThumbnailPath];
    NSURLSessionTask *sessionTask = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [session finishTasksAndInvalidate];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (nil == error) {
                if (fileExistsAtPath(filePath)) {
                    deleteFileAtPath(filePath, nil);
                }
                BOOL success = [data writeToFile:filePath atomically:NO];
                if (success) {
                    block(nil);
                }else {
                    block(convertCameraMediaErrorCodeToNSError(YuneecMediaErrorMoveMediaFailure));
                }
            }else {
                block(error);
            }
        });
    }];
    [sessionTask resume];
}

- (void)fetchImageDataWithFilePath:(NSString *)filePath progress:(void (^)(float, BOOL * _Nullable))progress block:(void (^)(NSError * _Nullable))block {
    
    if (nil == block) {
        return;
    }
    
    if (self.mediaType == YuneecMediaTypeMP4 || self.mediaType == YuneecMediaTypeUnknown) {
        NSError *error = convertCameraMediaErrorCodeToNSError(YuneecMediaErrorMediaTypeWrong);
        block(error);
        return;
    }
    
    if (self.mediaType == YuneecMediaTypeDNG) {
        NSError *error = convertCameraMediaErrorCodeToNSError(YuneecMediaErrorMediaNonsupportDNGFile);
        block(error);
        return;
    }
    
    [self fetchMediaDataWithWithURL:self.serverPath filePath:filePath progress:progress block:block];

}

- (void)fetchVideoDataWithFilePath:(NSString *)filePath progress:(void (^)(float, BOOL * _Nullable))progress block:(void (^)(NSError * _Nullable))block {
    if (nil == block) {
        return;
    }
    
    if (self.mediaType != YuneecMediaTypeMP4 || self.mediaType == YuneecMediaTypeUnknown) {
        NSError *error = convertCameraMediaErrorCodeToNSError(YuneecMediaErrorMediaTypeWrong);
        block(error);
        return;
    }
    
    [self fetchMediaDataWithWithURL:self.serverPath filePath:filePath progress:progress block:block];
}

- (void)fetchPreviewVideoDataWithFilePath:(NSString *)filePath progress:(void (^)(float, BOOL * _Nullable))progress block:(void (^)(NSError * _Nullable))block {
    if (nil == block) {
        return;
    }
    
    if (self.mediaType != YuneecMediaTypeMP4 || self.mediaType == YuneecMediaTypeUnknown) {
        NSError *error = convertCameraMediaErrorCodeToNSError(YuneecMediaErrorMediaTypeWrong);
        block(error);
        return;
    }
    
    [self fetchMediaDataWithWithURL:self.serverPreviewPath filePath:filePath progress:progress block:block];
}

#pragma mark - media download 

- (void)fetchMediaDataWithWithURL:(NSString *)urlString filePath:(NSString *)filePath progress:(void (^)(float, BOOL * _Nullable))progress block:(void (^)(NSError * _Nullable))block {
    
    if (nil != progress) {
        self.fetchMediaProgress = progress;
    }
    self.fetchMediaDataBlock = block;
    self.destFilePath = filePath;
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = fetchMediaHttpTimeout;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:urlString]];
    [dataTask resume];
    self.session = session;
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    ///< caculate progress
    float progress = 1.0 * totalBytesWritten / totalBytesExpectedToWrite;
    BOOL isStop = NO;
    if (self.fetchMediaProgress) {
        self.fetchMediaProgress(progress, &isStop);
    }
    if (isStop) {
        [downloadTask cancel];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    [self endSessionAndCancelTasks];
    
    ///< handle Error
    if (nil != error && nil != self.fetchMediaDataBlock) {
        self.fetchMediaDataBlock(error);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    ///< change data task into download task
    completionHandler(NSURLSessionResponseBecomeDownload);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
    ///< msut call this delegate in order to execute other delegate methods
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    ///< finish download
    if (fileExistsAtPath(self.destFilePath)) {
        deleteFileAtPath(self.destFilePath, nil);
    }
    BOOL success = [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:self.destFilePath] error:nil];

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (success) {
            weakSelf.fetchMediaDataBlock(nil);
        }else {
            weakSelf.fetchMediaDataBlock(convertCameraMediaErrorCodeToNSError(YuneecMediaErrorMoveMediaFailure));
        }
    });
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    [self cleanupSession];
}

#pragma mark - private method

- (void)cleanupSession
{
    [self setSession:nil];
}

- (void)endSessionAndCancelTasks
{
    if (_session)
    {
        [self.session invalidateAndCancel];
    }
}

@end
