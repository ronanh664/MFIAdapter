//
//  YuneecSDKManager.m
//  YuneecSDK
//
//  Created by tbago on 17/3/27.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecSDKManager.h"
#import <YuneecCameraSDK/YuneecSDKManager_Communication.h>
@implementation YuneecSDKManager

+ (instancetype)sharedInstance {
    static dispatch_once_t      onceToken;
    static YuneecSDKManager     *_instance;
    dispatch_once(&onceToken, ^{
        _instance = [[YuneecSDKManager alloc] init];
    });
    return _instance;
}


- (NSString *)CGO3RootServerAddress
{
    if (_CGO3RootServerAddress == nil) {
        _CGO3RootServerAddress = @"http://192.168.42.1/";
    }
    return _CGO3RootServerAddress;
}

- (NSString *)CGO3ServerMediaPath
{
    if (_CGO3ServerMediaPath == nil) {
        _CGO3ServerMediaPath = @"http://192.168.42.1/100MEDIA/";
    }
    return _CGO3ServerMediaPath;
}

- (NSString *)breezeServerMediaAddress
{
    if (_breezeServerMediaAddress == nil) {
        _breezeServerMediaAddress = @"http://192.168.42.1/DCIM/100MEDIA/";
    }
    return _breezeServerMediaAddress;
}

- (NSInteger)cameraMediaDownloadPort
{
    if (_cameraMediaDownloadPort == NULL) {
        _cameraMediaDownloadPort = 9800;
    }
    return _cameraMediaDownloadPort;
}

- (NSString *)cameraIpAddress
{
    if (_cameraIpAddress == nil) {
        _cameraIpAddress = @"192.168.42.1";
    }
    return _cameraIpAddress;
}

@end
