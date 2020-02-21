//
//  YuneecMediaHttpManager.m
//  YuneecSDK
//
//  Created by Mine on 2017/4/28.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecMediaHttpManager.h"
#import "YuneecMediaHttp_Extension.h"
#import "YuneecMedia_Extension.h"
#import "TFHpple.h"
#import "YuneecMediaConfig.h"
#import "YuneecMediaUtility.h"
#import "YuneecMediaError.h"
#import "YuneecCamera.h"

@interface YuneecMediaHttpManager ()
//@property (nonatomic, strong) NSMutableArray *mediaArray;
@property (nonatomic, strong) dispatch_queue_t deleteMediaQueue;
@end

@implementation YuneecMediaHttpManager

- (instancetype)init {
    if (self = [super init]) {
        _cameraType = YuneecCameraTypeUnknown;
    }
    return self;
}

#pragma mark - Public methods

- (void)fetchMediaWithCompletion:(void (^)(NSArray<YuneecMedia *> * _Nullable, NSError * _Nullable))block {
    if (self.cameraType == YuneecCameraTypeUnknown) {
        block(nil, convertCameraMediaErrorCodeToNSError(YuneecMediaErrorUnknownCameraType));
        return;
    }
    
    BOOL isCGOSerial = (self.cameraType == YuneecCameraTypeCGO3Plus || self.cameraType == YuneecCameraTypeCGOT || self.cameraType == YuneecCameraTypeCGOPro || self.cameraType == YuneecCameraTypeCGOET);
    
    if (isCGOSerial) {
        [self fetchCGOMediaWithCompletion:block];
    }else {
        [self fetchBreezeMediaWithCompletion:block];
    }
}

- (void)deleteMedia:(NSArray<YuneecMedia *> *_Nonnull)mediaArray camera:(YuneecCamera * _Nullable)camera withCompletion:(void (^_Nullable)(NSError *_Nullable error))block {
    
    @synchronized (self) {
        
        if (mediaArray.count == 0) {
            block(convertCameraMediaErrorCodeToNSError(YuneecMediaErrorNoSuchFile));
            return;
        }
        
        NSArray *deleteMediaArray = [[NSArray alloc] initWithArray:mediaArray];
        
        if (self.cameraType == YuneecCameraTypeUnknown) {
            block(convertCameraMediaErrorCodeToNSError(YuneecMediaErrorUnknownCameraType));
            return;
        }
        
        BOOL isCGOSerial = (self.cameraType == YuneecCameraTypeCGO3Plus || self.cameraType == YuneecCameraTypeCGOT || self.cameraType == YuneecCameraTypeCGOPro || self.cameraType == YuneecCameraTypeCGOET);
        
        if (!isCGOSerial && camera == nil) {
            block(convertCameraMediaErrorCodeToNSError(YuneecMediaErrorNullCamera));
            return;
        }
        
        __weak typeof(self) weakSelf = self;
        __block NSInteger errorCount = 0;
        __block NSString *errorString = nil;
        
        ///< create serial queue to delete file
        dispatch_async(self.deleteMediaQueue, ^{
            dispatch_semaphore_t semaphoreOneFile = dispatch_semaphore_create(0);
            
            if (isCGOSerial) {
                for (YuneecMedia *media in deleteMediaArray) {
                    NSString *fileName = media.fileName;
                    [weakSelf deleteCGOMediaWithFileName:fileName withCompletion:^(NSError * _Nullable error) {
                        if (nil != error) {
                            errorCount ++;
                            errorString = error.localizedDescription;
                        }
                        dispatch_semaphore_signal(semaphoreOneFile);
                    }];
                    dispatch_semaphore_wait(semaphoreOneFile, DISPATCH_TIME_FOREVER);
                }
            }else {
                for (YuneecMedia *media in deleteMediaArray) {
                    NSString *fileName = media.fileName;
                    fileName = [fileName stringByDeletingPathExtension];
                    fileName = [fileName substringFromIndex:7];     ///< Delete Breeze_ Prefix
#warning this method is breeze delete method, not mavlink2 protocol. if use mavlink2, maybe should code a new method.
//                    [camera deleteMediaWithFileName:fileName block:^(NSError * _Nullable error) {
//                        if (nil != error) {
//                            errorCount ++;
//                            errorString = error.localizedDescription;
//                        }
//                        dispatch_semaphore_signal(semaphoreOneFile);
//                    }];
                    dispatch_semaphore_wait(semaphoreOneFile, DISPATCH_TIME_FOREVER);
                }
            }
            
            ///< return result
            dispatch_async(dispatch_get_main_queue(), ^{
                if (errorCount != 0) {
                    NSError *error = convertSpecialCameraMediaErrorCodeToNSError(errorCount, deleteMediaArray.count, errorString);
                    block(error);
                }else {
                    block(nil);
                }
            });
        });
    }
}

#pragma mark - Private methods

- (void)fetchBreezeMediaWithCompletion:(void (^)(NSArray<YuneecMedia *> * _Nullable, NSError * _Nullable))block {
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = fetchMediaHttpTimeout;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    
    NSURL *url = [[NSURL alloc] initWithString:[YuneecSDKManager sharedInstance].breezeServerMediaAddress];
    
    NSURLSessionTask *sessionTask = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        [session finishTasksAndInvalidate];
        
        if (error) {
            block(nil, convertCameraMediaErrorCodeToNSError(YuneecMediaErrorConnectionTimeout));
            return;
        }
        
        NSMutableArray *mediaArray = [[NSMutableArray alloc] init];
        
        ///< parser xml file
        TFHpple * document  = [[TFHpple alloc] initWithHTMLData:data];
        NSArray * elements  = [document searchWithXPathQuery:@"//tbody/tr"];
        
        NSMutableArray *tempMediaArray = [[NSMutableArray alloc] init];
        
        for (TFHppleElement *element in elements)
        {
            if ([element.raw containsString:@"<td class=\"t\">application/octet-stream</td>"])
            {
                YuneecMediaHttp *media = [[YuneecMediaHttp alloc] init];
                media.mediaType = YuneecMediaTypeJPEG;
                for (TFHppleElement *childElement in element.children)
                {
                    NSString *childElementString = [childElement objectForKey:@"class"];
                    if ([childElementString isEqualToString:@"n"]) {
                        TFHppleElement *childChildElement = childElement.firstChild;
                        media.serverPath = [NSString stringWithFormat:@"%@%@", [YuneecSDKManager sharedInstance].breezeServerMediaAddress, [childChildElement objectForKey:@"href"]];
                        media.fileName = childChildElement.text;
                    }
                    else if ([childElementString isEqualToString:@"m"]) {
                        media.createDate = childElement.text;
                    }
                    else if ([childElementString isEqualToString:@"s"]) {
                        media.fileSize = childElement.text;
                    }
                }
                if (![media.fileName hasPrefix:@"."]) {
                    [tempMediaArray addObject:media];
                }
            }
        }
        
        ///< get video and picture
        [tempMediaArray enumerateObjectsUsingBlock:^(YuneecMediaHttp *tempMedia, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *mediaPathExtension = tempMedia.serverPath.pathExtension;
            if ([mediaPathExtension compare:@"mov" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                tempMedia.mediaType = YuneecMediaTypeMP4;
                [mediaArray addObject:tempMedia];
            }else if ([mediaPathExtension compare:@"jpg" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                tempMedia.mediaType = YuneecMediaTypeJPEG;
                [mediaArray addObject:tempMedia];
            }
        }];
        
        ///< get thumnail and get preview video for video resources
        [tempMediaArray enumerateObjectsUsingBlock:^(YuneecMediaHttp *tempMedia, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *mediaPathExtension = tempMedia.serverPath.pathExtension;
            if ([mediaPathExtension compare:@"thm" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                NSString *thumnailMediaName = [tempMedia.fileName stringByDeletingPathExtension];
                for (YuneecMediaHttp *meida in mediaArray) {
                    NSString *mediaName = [meida.fileName stringByDeletingPathExtension];
                    if ([mediaName isEqualToString:thumnailMediaName]) {
                        meida.serverThumbnailPath = tempMedia.serverPath;
                        break;
                    }
                }
            }else if ([mediaPathExtension compare:@"2nd" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                NSString *previewMediaName = [tempMedia.fileName stringByDeletingPathExtension];
                for (YuneecMediaHttp *meida in mediaArray) {
                    NSString *mediaName = [meida.fileName stringByDeletingPathExtension];
                    if ([mediaName isEqualToString:previewMediaName]) {
                        meida.serverPreviewPath = tempMedia.serverPath;
                        break;
                    }
                }
            }
        }];
        
        ///< sort meida by time
        [mediaArray sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            YuneecMedia *obj1Resource = (YuneecMedia *)obj1;
            YuneecMedia *obj2Resource = (YuneecMedia *)obj2;
            NSDate *obj1CreateDate = convertStringToNSDate(obj1Resource.createDate, @"YYYY-MMM-dd HH:mm:ss");
            NSDate *obj2CreateDate = convertStringToNSDate(obj2Resource.createDate, @"YYYY-MMM-dd HH:mm:ss");
            NSComparisonResult result = [obj1CreateDate compare:obj2CreateDate];
            return result != NSOrderedDescending;
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            block(mediaArray, nil);
        });
        
    }];
    [sessionTask resume];
    
}

- (void)fetchCGOMediaWithCompletion:(void (^)(NSArray<YuneecMedia *> * _Nullable, NSError * _Nullable))block {
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = fetchMediaHttpTimeout;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    
    NSURL *url = [[NSURL alloc] initWithString:[YuneecSDKManager sharedInstance].CGO3ServerMediaPath];
    
    NSURLSessionTask *sessionTask = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [session finishTasksAndInvalidate];
        if (error) {
            block(nil, convertCameraMediaErrorCodeToNSError(YuneecMediaErrorConnectionTimeout));
            return;
        }
        
        NSMutableArray *mediaArray = [[NSMutableArray alloc] init];
        
        ///< parser xml file
        TFHpple * document  = [[TFHpple alloc] initWithHTMLData:data];
        NSArray * elements  = [document searchWithXPathQuery:@"//tbody/tr"];
        
        for (TFHppleElement *element in elements)
        {
            if ([element.raw containsString:@"<td class=\"t\">image/jpeg</td>"])
            {
                
                YuneecMediaHttp *media = [[YuneecMediaHttp alloc] init];
                media.mediaType = YuneecMediaTypeJPEG;
                for (TFHppleElement *childElement in element.children)
                {
                    NSString *childElementString = [childElement objectForKey:@"class"];
                    if ([childElementString isEqualToString:@"n"]) {
                        TFHppleElement *childChildElement = childElement.firstChild;
                        media.serverPath = [NSString stringWithFormat:@"%@%@", [YuneecSDKManager sharedInstance].CGO3ServerMediaPath, [childChildElement objectForKey:@"href"]];
                        media.fileName = childChildElement.text;
                    }
                    else if ([childElementString isEqualToString:@"m"]) {
                        media.createDate = childElement.text;
                    }
                    else if ([childElementString isEqualToString:@"s"]) {
                        media.fileSize = childElement.text;
                    }
                }
                [mediaArray addObject:media];
            }
            else if ([element.raw containsString:@"application/octet-stream"])
            {
                YuneecMediaHttp *media = [[YuneecMediaHttp alloc] init];
                for (TFHppleElement *childElement in element.children)
                {
                    NSString *childElementString = [childElement objectForKey:@"class"];
                    if ([childElementString isEqualToString:@"n"]) {
                        TFHppleElement *childChildElement = childElement.firstChild;
                        media.serverPath = [NSString stringWithFormat:@"%@%@", [YuneecSDKManager sharedInstance].CGO3ServerMediaPath, [childChildElement objectForKey:@"href"]];
                        NSString *pathExtension = [media.serverPath pathExtension];
                        if ([pathExtension isEqualToString:@"mp4"]) {
                            media.mediaType = YuneecMediaTypeMP4;
                        }
                        else if ([pathExtension isEqualToString:@"dng"]) {
                            media.mediaType = YuneecMediaTypeDNG;
                        }
                        else {
                            media = nil;
                            break;
                        }
                        media.fileName = childChildElement.text;
                    }
                    else if ([childElementString isEqualToString:@"m"]) {
                        media.createDate = childElement.text;
                    }
                    else if ([childElementString isEqualToString:@"s"]) {
                        media.fileSize = childElement.text;
                    }
                }
                if (media != nil) {
                    if (media.mediaType == YuneecMediaTypeMP4) {
                        [mediaArray addObject:media];
                    }
                    else {
                        [mediaArray addObject:media];
                    }
                }
            }
        }
        
        ///< sort meida by time
        [mediaArray sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            YuneecMedia *obj1Resource = (YuneecMedia *)obj1;
            YuneecMedia *obj2Resource = (YuneecMedia *)obj2;
            NSDate *obj1CreateDate = convertStringToNSDate(obj1Resource.createDate, @"YYYY-MMM-dd HH:mm:ss");
            NSDate *obj2CreateDate = convertStringToNSDate(obj2Resource.createDate, @"YYYY-MMM-dd HH:mm:ss");
            NSComparisonResult result = [obj1CreateDate compare:obj2CreateDate];
            return result != NSOrderedDescending;
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            block(mediaArray, nil);
        });
        
    }];
    [sessionTask resume];
    
}

- (void)deleteCGOMediaWithFileName:(NSString *)fileName withCompletion:(void (^)(NSError * _Nullable error))block {
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = fetchMediaHttpTimeout;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    
    NSString *urlString = [[YuneecSDKManager sharedInstance].CGO3RootServerAddress stringByAppendingPathComponent:[NSString stringWithFormat:@"cgi-bin/cgi?CMD=DEL_MEDIA_FILE&filename=%@",fileName]];
    
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    
    NSURLSessionTask *sessionTask = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [session finishTasksAndInvalidate];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                NSInteger rval = [jsonDictionary[@"rval"] integerValue];
                if (rval != 0) {
                    NSError *error = convertCameraMediaErrorCodeToNSError(YuneecMediaErrorUnknown);
                    block(error);
                }else {
                    block(nil);
                }
            }else {
                NSError *error = convertCameraMediaErrorCodeToNSError(YuneecMediaErrorDeleteMediaFailure);
                block(error);
            }
        });
    }];
    
    [sessionTask resume];
}

#pragma mark - set & get

- (dispatch_queue_t)deleteMediaQueue
{
    if (!_deleteMediaQueue) {
        _deleteMediaQueue = dispatch_queue_create("com.yuneecsdk.deleteMediaQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _deleteMediaQueue;
}

@end
