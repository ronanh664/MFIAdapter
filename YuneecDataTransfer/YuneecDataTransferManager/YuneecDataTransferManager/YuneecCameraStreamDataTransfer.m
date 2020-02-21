//
//  YuneecCameraStreamDataTransfer.m
//  YuneecDataTransferManager
//
//  Created by tbago on 16/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import "YuneecCameraStreamDataTransfer.h"

#import <YuneecWifiDataTransfer/YuneecWifiCameraStreamDataTransfer.h>
#import <YuneecMFiDataTransfer/YuneecMFiCameraStreamDataTransfer.h>

#import "YuneecCameraStreamDataTransfer_TransferType.h"

@interface YuneecCameraStreamDataTransfer()<YuneecWifiCameraStreamDataTransferDelegate,
                                            YuneecMFiCameraStreamDataTransferDelegate>

///< wifi
@property (strong, nonatomic) YuneecWifiCameraStreamDataTransfer    *wifiCameraStreamDataTransfer;

///< MFi
@property (strong, nonatomic) YuneecMFiCameraStreamDataTransfer     *MFiCameraStreamDataTransfer;

@end

@implementation YuneecCameraStreamDataTransfer

#pragma mark - public method

- (BOOL)openCameraSteamDataTransfer {
    if (self.wifiCameraStreamDataTransfer != nil) {
        return [self.wifiCameraStreamDataTransfer openCameraSteamDataTransfer];
    }
    else if (self.MFiCameraStreamDataTransfer != nil) {
        return [self.MFiCameraStreamDataTransfer openCameraSteamDataTransfer];
    }
    return NO;
}

- (void)closeCameraStreamDataTransfer {
    if (self.wifiCameraStreamDataTransfer != nil) {
        [self.wifiCameraStreamDataTransfer closeCameraStreamDataTransfer];
    }
    else if (self.MFiCameraStreamDataTransfer != nil) {
        [self.MFiCameraStreamDataTransfer closeCameraStreamDataTransfer];
    }
}

#pragma mark - YuneecWifiCameraStreamDataTransferDelegate

- (void)wifiCameraStreamDataTransfer:(YuneecWifiCameraStreamDataTransfer *) cameraStreamDataTransfer
                  didReceiveH264Data:(NSData *) h264Data
                            keyFrame:(BOOL) keyFrame
                  decompassTimeStamp:(int64_t) decompassTimeStamp
                    presentTimeStamp:(int64_t) presentTimeStamp
                           extraData:(NSData * __nullable) extraData
{
    if (self.cameraStreamDelegate != nil) {
        [self.cameraStreamDelegate cameraStreamDataTransfer:self
                                         didReceiveH264Data:h264Data
                                                   keyFrame:keyFrame
                                         decompassTimeStamp:decompassTimeStamp
                                           presentTimeStamp:presentTimeStamp
                                                  extraData:extraData];
    }
}

#pragma mark - YuneecMFiCameraStreamDataTransferDelegate

- (void)MFiCameraStreamDataTransfer:(YuneecMFiCameraStreamDataTransfer *) cameraStreamDataTransfer
                 didReceiveH264Data:(NSData *) h264Data
                           keyFrame:(BOOL) keyFrame
                 decompassTimeStamp:(int64_t) decompassTimeStamp
                   presentTimeStamp:(int64_t) presentTimeStamp
                          extraData:(NSData * __nullable) extraData
{
    if (self.cameraStreamDelegate != nil) {
        [self.cameraStreamDelegate cameraStreamDataTransfer:self
                                         didReceiveH264Data:h264Data
                                                   keyFrame:keyFrame
                                         decompassTimeStamp:decompassTimeStamp
                                           presentTimeStamp:presentTimeStamp
                                                  extraData:extraData];
    }
}

#pragma mark - get & set

- (void)setTransferType:(YuneecDataTransferConnectionType)transferType {
    _transferType = transferType;
    if (_transferType == YuneecDataTransferConnectionTypeNone) {
        if (_MFiCameraStreamDataTransfer != nil) {
            _MFiCameraStreamDataTransfer.cameraStreamDelegate = nil;
            [_MFiCameraStreamDataTransfer closeCameraStreamDataTransfer];
            _MFiCameraStreamDataTransfer = nil;
        }
        if (_wifiCameraStreamDataTransfer != nil) {
            _wifiCameraStreamDataTransfer.cameraStreamDelegate = nil;
            [_wifiCameraStreamDataTransfer closeCameraStreamDataTransfer];
            _wifiCameraStreamDataTransfer = nil;
        }
    }

    else if (_transferType == YuneecDataTransferConnectionTypeWifi) {
        if (_MFiCameraStreamDataTransfer != nil) {
            _MFiCameraStreamDataTransfer.cameraStreamDelegate = nil;
            [_MFiCameraStreamDataTransfer closeCameraStreamDataTransfer];
            _MFiCameraStreamDataTransfer = nil;
        }

        NSAssert(_wifiCameraStreamDataTransfer == nil, @"wifi data transfer is not nil");
        _wifiCameraStreamDataTransfer = [[YuneecWifiCameraStreamDataTransfer alloc] init];
        _wifiCameraStreamDataTransfer.cameraStreamDelegate = self;
    }

    else if (_transferType == YuneecDataTransferConnectionTypeMFi) {
        if (_wifiCameraStreamDataTransfer != nil) {
            _wifiCameraStreamDataTransfer.cameraStreamDelegate = nil;
            [_wifiCameraStreamDataTransfer closeCameraStreamDataTransfer];
            _wifiCameraStreamDataTransfer = nil;
        }

        NSAssert(_MFiCameraStreamDataTransfer == nil, @"MFi data transfer is not nil");
        _MFiCameraStreamDataTransfer = [[YuneecMFiCameraStreamDataTransfer alloc] init];
        _MFiCameraStreamDataTransfer.cameraStreamDelegate = self;
    }
}

- (void)setEnableLowDelay:(BOOL)enableLowDelay {
    if (_wifiCameraStreamDataTransfer != nil) {
        _wifiCameraStreamDataTransfer.enableLowDelay = enableLowDelay;
    }
}
@end
