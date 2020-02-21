//
//  YuneecMFiInnerDataTransfer.h
//  YuneecMFiDataTransfer
//
//  Created by tbago on 23/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>

#import "YuneecMFiDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class YuneecMFiInnerDataTransfer;

@protocol YuneecMFiInnerCameraStreamDataDelegate <NSObject>

- (void)MFiInnerDataTransfer:(YuneecMFiInnerDataTransfer *) MFiDataTransfer
          didReceiveH264Data:(NSData *) h264Data
          decompassTimeStamp:(int64_t) decompassTimeStamp
            presentTimeStamp:(int64_t) presentTimeStamp;

@end

@protocol YuneecMFiInnerControllerDataTransferDelegate <NSObject>

- (void)MFiInnerDataTransfer:(YuneecMFiInnerDataTransfer *) MFiDataTransfer
              didReceiveCameraData:(NSData *) data;

- (void)MFiInnerDataTransfer:(YuneecMFiInnerDataTransfer *) MFiDataTransfer
didReceiveFlyingControllerData:(NSData *) data;

- (void)MFiInnerDataTransfer:(YuneecMFiInnerDataTransfer *) MFiDataTransfer
  didReceiveUpgradeStateData:(NSData *) upgradeStateData;

@end

@protocol YuneecMFiInnerRemoteControllerDataTransferDelegate <NSObject>

- (void)MFiInnerDataTransfer:(YuneecMFiInnerDataTransfer *) MFiDataTransfer
              didReceiveData:(NSData *) data;

@end

@protocol YuneecMFiInnerUpgradeDataTransferDelegate <NSObject>
@required
- (void)MFiInnerDataTransfer:(YuneecMFiInnerDataTransfer *) MFiDataTransfer
              didReceiveData:(NSData *) data;

@end

@protocol YuneecMFiInnerPhotoDownloadDataTranferDelegate <NSObject>

- (void)MFiInnerDataTransfer:(YuneecMFiInnerDataTransfer *) MFiDataTransfer
              didReceiveData:(NSData *)data;

@end

@interface YuneecMFiInnerDataTransfer : NSObject

/**
 * Use this delegate for receive H264 video frame
 */
@property (nonatomic, weak, nullable) id<YuneecMFiInnerCameraStreamDataDelegate>            cameraStreamDelegate;

/**
 * Use this delegate for receive controller data
 */
@property (nonatomic, weak, nullable) id<YuneecMFiInnerControllerDataTransferDelegate>      controllerDataDelegate;

/**
 * Use this delegate for receive remote controller data
 */
@property (nonatomic, weak, nullable) id<YuneecMFiInnerRemoteControllerDataTransferDelegate> remoteControllerDelegate;

/**
 * Use this delegate for upgrade
 */
@property (nonatomic, weak, nullable) id<YuneecMFiInnerUpgradeDataTransferDelegate>          upgradeDelegate;

/**
 * Use this delegate for photo download
 */
@property (nonatomic, weak, nullable) id<YuneecMFiInnerPhotoDownloadDataTranferDelegate> photoDownloadDelegate;

+ (instancetype)sharedInstance;

- (BOOL)openMFiDataTransfer;

- (void)closeMFiDataTransfer;

- (void)sendMFiData:(NSData *) data
       protocolType:(YuneecMFiProtocolType) protocolType;

/**
 * 来源于MFiConnectionState中监听到的 EAAccessory
 */
@property (strong, nonatomic, nullable) EAAccessory           *connectedAccessory;

@end

NS_ASSUME_NONNULL_END
