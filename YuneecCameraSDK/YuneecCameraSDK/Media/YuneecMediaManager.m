//
//  YuneecMediaManager.m
//  YuneecSDK
//
//  Created by Mine on 2017/3/9.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecMediaManager.h"
#import "YuneecUdpDownloader.h"
#import "YuneecMedia.h"
#import "YuneecMedia_Extension.h"
#import "YuneecSDKManager.h"
#import "YuneecMediaError.h"
#import "YuneecMediaHttp.h"
#import "YuneecMediaHttpManager.h"

@interface YuneecMediaManager ()

@property (nonatomic, strong) dispatch_queue_t deleteMediaQueue;
@property (nonatomic, strong) dispatch_queue_t fetchMediaQueue;
@property (nonatomic, strong) YuneecUdpDownloader *downloader;

@end

@implementation YuneecMediaManager

- (instancetype)initWithCameraType:(YuneecCameraType)cameraType {
    if (cameraType == YuneecCameraTypeFirebird || cameraType == YuneecCameraTypeHDRacer
        || cameraType == YuneecCameraTypeE90 || cameraType == YuneecCameraTypeCGOPro)
    {
        // udp manager
        return [[YuneecMediaManager alloc] init];
    }
    else {
        // http manager
        YuneecMediaHttpManager *manager = [[YuneecMediaHttpManager alloc] init];
        manager.cameraType = cameraType;
        return manager;
    }
}

- (void)fetchMediaWithCompletion:(void (^)(NSArray<YuneecMedia *> * _Nullable, NSError * _Nullable))block {
    dispatch_async(self.fetchMediaQueue, ^{
        
        self.downloader = [[YuneecUdpDownloader alloc] init];
        [_downloader queryFileListWithBlock:^(NSError * _Nullable error, NSArray * _Nullable fileArray) {
            
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block(nil, error);
                });
                return;
            }
            
            NSMutableArray *fileLists = [[NSMutableArray alloc] init];
            [fileArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSDictionary *fileDictionary = (NSDictionary *)obj;
                YuneecMedia *file = [[YuneecMedia alloc] init];
                [file setValuesForKeysWithDictionary:fileDictionary];
                
                // thumbnail
                NSDictionary *thumbnailDictionary = fileDictionary[@"thumbnail"];
                if (nil != thumbnailDictionary) {
                    YuneecMedia *thumbnailMedia = [[YuneecMedia alloc] init];
                    [thumbnailMedia setValuesForKeysWithDictionary:thumbnailDictionary];
                    file.thumbnailMedia = thumbnailMedia;
                }
                
                // preview video
                NSDictionary *previewVideoDictionary = fileDictionary[@"second"];
                if (nil != previewVideoDictionary) {
                    YuneecMedia *previewMedia = [[YuneecMedia alloc] init];
                    [previewMedia setValuesForKeysWithDictionary:previewVideoDictionary];
                    file.previewMedia = previewMedia;
                }
                [fileLists addObject:file];
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                block(fileLists, nil);
            });
        }];
    });
    
}

- (void)deleteMedia:(NSArray<YuneecMedia *> *)mediaArray withCompletion:(void (^)(NSError * _Nullable))block {
    if (mediaArray.count < 1) {
        return;
    }
    
    NSMutableArray *fileNameArray = [[NSMutableArray alloc] init];
    for (YuneecMedia *file in mediaArray) {
        if (file.hasDNG) {
            NSString *fileName = [[file.fileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"DNG"];
            [fileNameArray addObject:fileName];
        }
        [fileNameArray addObject:file.fileName];
        if (file.mediaType == YuneecMediaTypeJPEG) {
            NSArray *array = [file.fileName componentsSeparatedByString:@"."];
            [fileNameArray addObject:[NSString stringWithFormat:@"%@.thm", array[0]]];
        } else if (file.mediaType == YuneecMediaTypeMP4) {
            NSArray *array = [file.fileName componentsSeparatedByString:@"."];
            [fileNameArray addObject:[NSString stringWithFormat:@"%@.2nd", array[0]]];
            [fileNameArray addObject:[NSString stringWithFormat:@"%@.THM", array[0]]];
        }
    }
    
    dispatch_async(self.deleteMediaQueue, ^{
        YuneecUdpDownloader *downloader = [[YuneecUdpDownloader alloc] init];
        [downloader deleteFiles:fileNameArray block:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    block(error);
                }else {
                    block(nil);
                }
            });
        }];
    });
    
}

- (void)deleteMedia:(NSArray<YuneecMedia *> *)mediaArray camera:(YuneecCamera *)camera withCompletion:(void (^)(NSError * _Nullable))block {
}

- (void)stopFetchListWithBlock:(void(^)(NSError *error))block
{
    [_downloader stopDownloadWithBlock:^(NSError * _Nullable error) {
        block(error);
    }];
}

#pragma mark - lazy

- (dispatch_queue_t)deleteMediaQueue
{
    if (!_deleteMediaQueue) {
        _deleteMediaQueue = dispatch_queue_create("com.yuneecsdk.deleteMediaQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _deleteMediaQueue;
}

- (dispatch_queue_t)fetchMediaQueue
{
    if (!_fetchMediaQueue) {
        _fetchMediaQueue = dispatch_queue_create("com.yuneecsdk.fetchMediaListQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _fetchMediaQueue;
}

- (void)dealloc
{
    NSLog(@"++++++downloader dealloc");
}

@end
