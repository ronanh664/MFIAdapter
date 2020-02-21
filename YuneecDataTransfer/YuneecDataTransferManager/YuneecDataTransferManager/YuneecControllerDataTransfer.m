//
//  YuneecControllerDataTransfer.m
//  YuneecDataTransferManager
//
//  Created by tbago on 16/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import "YuneecControllerDataTransfer.h"

#import <YuneecWifiDataTransfer/YuneecWifiControllerDataTransfer.h>
#import <YuneecMFiDataTransfer/YuneecMFiControllerDataTransfer.h>

#import "YuneecControllerDataTransfer_TranferType.h"

@interface YuneecControllerDataTransfer()<YuneecWifiCameraControllerDataTransferDelegate,
                                          YuneecWifiFlyingControllerDataTransferDelegate,
                                          YuneecWifiUpgradeStateDataTransferDelegate,
                                          YuneecMFiCameraControllerDataTransferDelegate,
                                          YuneecMFiFlyingControllerDataTransferDelegate,
                                          YuneecMFiUpgradeStateDataTransferDelegate>

///< wifi
@property (strong, nonatomic) YuneecWifiControllerDataTransfer      *wifiControllerDataTransfer;

///< MFi
@property (strong, nonatomic) YuneecMFiControllerDataTransfer       *MFiControllerDataTransfer;

@end

@implementation YuneecControllerDataTransfer

#pragma mark - public method

- (void)sendData:(NSData *)data {
    if (self.wifiControllerDataTransfer != nil) {
        [self.wifiControllerDataTransfer sendData:data];
    }
    else if (self.MFiControllerDataTransfer != nil) {
        [self.MFiControllerDataTransfer sendData:data];
    }
}

#pragma mark - Wifi Controller data transfer delegate

- (void)wifiControllerDataTransfer:(YuneecWifiControllerDataTransfer *) dataTransfer
              didReceiveCameraData:(NSData *) data {
    if (self.cameraControllerDelegate != nil) {
        [self.cameraControllerDelegate controllerDataTransfer:self didReceiveCameraData:data];
    }
}

- (void)wifiControllerDataTransfer:(YuneecWifiControllerDataTransfer *) dataTransfer
    didReceiveFlyingControllerData:(NSData *) data {
    if (self.flyingControllerDelegate != nil) {
        [self.flyingControllerDelegate controllerDataTransfer:self didReceiveFlyingControllerData:data];
    }
}

- (void)wifiControllerDataTransfer:(YuneecWifiControllerDataTransfer *) dataTransfer
        didReceiveUpgradeStateData:(NSData *) data {
    if (self.upgradeStateDelegate != nil) {
        [self.upgradeStateDelegate controllerDataTransfer:self didReceiveUpgradeStateData:data];
    }
}

#pragma mark - MFi Controller data transfer delegate

- (void)MFiControllerDataTransfer:(YuneecMFiControllerDataTransfer *)dataTransfer didReceiveCameraData:(NSData *)data {
    if (self.cameraControllerDelegate != nil) {
        [self.cameraControllerDelegate controllerDataTransfer:self didReceiveCameraData:data];
    }
}

- (void)MFiControllerDataTransfer:(YuneecMFiControllerDataTransfer *)dataTransfer didReceiveFlyingControllerData:(NSData *)data {
    if (self.flyingControllerDelegate != nil) {
        [self.flyingControllerDelegate controllerDataTransfer:self didReceiveFlyingControllerData:data];
    }
}

- (void)MFiControllerDataTransfer:(YuneecMFiControllerDataTransfer *) dataTransfer
       didReceiveUpgradeStateData:(NSData *) data {
    if (self.upgradeStateDelegate != nil) {
        [self.upgradeStateDelegate controllerDataTransfer:self didReceiveUpgradeStateData:data];
    }
}

#pragma mark - get & set

- (void)setTransferType:(YuneecDataTransferConnectionType)transferType {
    _transferType = transferType;
    if (_transferType == YuneecDataTransferConnectionTypeNone) {
        if (_MFiControllerDataTransfer != nil) {
            _MFiControllerDataTransfer.cameraControllerDelegate = nil;
            _MFiControllerDataTransfer.flyingControllerDelegate = nil;
            _MFiControllerDataTransfer.upgradeStateDelegate     = nil;
            _MFiControllerDataTransfer = nil;
        }
        if (_wifiControllerDataTransfer != nil) {
            _wifiControllerDataTransfer.cameraControllerDelegate = nil;
            _wifiControllerDataTransfer.flyingControllerDelegate = nil;
            _wifiControllerDataTransfer.upgradeStateDelegate     = nil;
            [_wifiControllerDataTransfer close];
            _wifiControllerDataTransfer = nil;
        }
    }

    else if (_transferType == YuneecDataTransferConnectionTypeWifi) {
        if (_MFiControllerDataTransfer != nil) {
            _MFiControllerDataTransfer.cameraControllerDelegate = nil;
            _MFiControllerDataTransfer.flyingControllerDelegate = nil;
            _MFiControllerDataTransfer.upgradeStateDelegate     = nil;
            _MFiControllerDataTransfer = nil;
        }

        NSAssert(_wifiControllerDataTransfer == nil, @"wifi data transfer is not nil");
        _wifiControllerDataTransfer = [[YuneecWifiControllerDataTransfer alloc] init];
        _wifiControllerDataTransfer.cameraControllerDelegate = self;
        _wifiControllerDataTransfer.flyingControllerDelegate = self;
        _wifiControllerDataTransfer.upgradeStateDelegate     = self;
    }

    else if (_transferType == YuneecDataTransferConnectionTypeMFi) {
        if (_wifiControllerDataTransfer != nil) {
            _wifiControllerDataTransfer.cameraControllerDelegate = nil;
            _wifiControllerDataTransfer.flyingControllerDelegate = nil;
            _wifiControllerDataTransfer.upgradeStateDelegate     = nil;
            [_wifiControllerDataTransfer close];
            _wifiControllerDataTransfer = nil;
        }

        NSAssert(_MFiControllerDataTransfer == nil, @"MFi data transfer is not nil");
        _MFiControllerDataTransfer = [[YuneecMFiControllerDataTransfer alloc] init];
        _MFiControllerDataTransfer.cameraControllerDelegate = self;
        _MFiControllerDataTransfer.flyingControllerDelegate = self;
        _MFiControllerDataTransfer.upgradeStateDelegate     = self;
    }
}

@end
