//
//  WifiDataTransferConfig.m
//  YuneecWifiDataTransfer
//
//  Created by tbago on 2017/8/30.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecWifiDataTransferConfig.h"

NSString * const        cameraIpAddress     = @"192.168.42.1";

NSString * const        cameraRtspAddress   = @"rtsp://192.168.42.1/live";

const NSInteger         cameraControllerReturnDataPort   = 14550;

const NSTimeInterval    cameraControllerSendDataTimeout  = 5.0;

NSString * const        flyingControllerIpAddress = @"192.168.42.1";

NSString * const        upgradeIpAddress = @"192.168.42.1";

const NSInteger         upgradePort = 9801;

const NSTimeInterval    upgradeSendDataTimeout = 5.0;
