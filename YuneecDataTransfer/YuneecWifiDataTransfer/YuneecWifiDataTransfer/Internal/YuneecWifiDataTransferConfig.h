//
//  WifiDataTransferConfig.h
//  YuneecWifiDataTransfer
//
//  Created by tbago on 2017/8/30.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * The camera ip address
 */
extern NSString * const     cameraIpAddress;

/**
 * The camera rtsp address
 */
extern NSString * const     cameraRtspAddress;

/**
 * The camera controller return data port
 */
extern const NSInteger      cameraControllerReturnDataPort;

/**
 * The camera controller send data timeout value
 */
extern const NSTimeInterval cameraControllerSendDataTimeout;

extern NSString * const     flyingControllerIpAddress;

/**
 * firmware upgrade ip address
 */
extern NSString * const     upgradeIpAddress;

/**
 * firmware upgrade port
 */
extern const NSInteger      upgradePort;

/**
 * firmware send data timeout value
 */
extern const NSTimeInterval upgradeSendDataTimeout;

