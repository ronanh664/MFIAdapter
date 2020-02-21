//
//  YuneecCameraSDKManager.m
//  YuneecCameraSDK
//
//  Created by tbago on 2017/9/5.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecCameraSDKManager.h"

@implementation YuneecCameraSDKManager

+ (NSString *)getSDKVersion {
    NSDictionary* infoDict = [[NSBundle bundleForClass:[YuneecCameraSDKManager class]] infoDictionary];
    NSString * mainVersion = infoDict[@"CFBundleShortVersionString"];
    
    NSString * buildVersion = infoDict[@"CFBundleVersion"];
    return [NSString stringWithFormat:@"%@.%@", mainVersion, buildVersion];
}

@end
