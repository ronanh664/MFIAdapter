//
//  YuneecDataTransferUpgradeDataTransfer.m
//  YuneecDataTransferManager
//
//  Created by tbago on 16/03/2018.
//  Copyright © 2018 yuneec. All rights reserved.
//

#import "YuneecUpgradeDataTransfer.h"

#import <YuneecMFiDataTransfer/YuneecMFiUpgradeDataTransfer.h>
#import <YuneecWifiDataTransfer/YuneecWifiUpgradeDataTransfer.h>

#import "YuneecUpgradeDataTransfer_TransferType.h"

@interface YuneecUpgradeDataTransfer()<YuneecWifiUpgradeDataTransferDelegate,
                                       YuneecMFiUpgradeDataTransferDelegate>

///< wifi
@property (strong, nonatomic) YuneecWifiUpgradeDataTransfer     *wifiUpgradeDataTransfer;

///< MFi
@property (strong, nonatomic) YuneecMFiUpgradeDataTransfer      *MFiUpgradeDataTransfer;

@end

@implementation YuneecUpgradeDataTransfer

#pragma mark - public method

- (BOOL)connectToServer {
    if (self.wifiUpgradeDataTransfer != nil) {
        return [self.wifiUpgradeDataTransfer connectToServer];
    }
    else if (self.MFiUpgradeDataTransfer != nil) {
        return [self.MFiUpgradeDataTransfer connectToServer];
    }
    return NO;
}

- (void)disconnectToServer {
    if (self.wifiUpgradeDataTransfer != nil) {
        [self.wifiUpgradeDataTransfer disconnectToServer];
    }
    else if (self.MFiUpgradeDataTransfer != nil) {
        [self.MFiUpgradeDataTransfer disconnectToServer];
    }
}

- (void)sendData:(NSData *) data {
    if (self.wifiUpgradeDataTransfer != nil) {
        [self.wifiUpgradeDataTransfer sendData:data];
    }
    else if (self.MFiUpgradeDataTransfer != nil) {
        [self.MFiUpgradeDataTransfer sendData:data];
    }
}

#pragma mark - YuneecWifiUpgradeDataTransferDelegate

- (void)wifiUpgradeDataTransferDidSendData {
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(upgradeDataTransferDidSendData)]) {
        [self.delegate upgradeDataTransferDidSendData];
    }
}

- (void)wifiUpgradeDataTransfer:(YuneecWifiUpgradeDataTransfer *) dataTransfer
                 didReceiveData:(NSData *) data {
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(upgradeDataTransfer:didReceiveData:)]) {
        [self.delegate upgradeDataTransfer:self didReceiveData:data];
    }
}

#pragma mark - YuneecMFiUpgradeDataTransferDelegate

- (void)MFiUpgradeDataTransferDidSendData {
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(upgradeDataTransferDidSendData)]) {
        [self.delegate upgradeDataTransferDidSendData];
    }
}

- (void)MFiUpgradeDataTransfer:(YuneecMFiUpgradeDataTransfer *) dataTransfer
                didReceiveData:(NSData *) data {
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(upgradeDataTransfer:didReceiveData:)]) {
        [self.delegate upgradeDataTransfer:self didReceiveData:data];
    }
}

#pragma mark - get & set

- (void)setTransferType:(YuneecDataTransferConnectionType)transferType {
    _transferType = transferType;

    if (_transferType == YuneecDataTransferConnectionTypeNone) {
        if (_MFiUpgradeDataTransfer != nil) {
            _MFiUpgradeDataTransfer.delegate = nil;
            _MFiUpgradeDataTransfer = nil;
        }
        if (_wifiUpgradeDataTransfer != nil) {
            _wifiUpgradeDataTransfer.delegate = nil;
            _wifiUpgradeDataTransfer = nil;
        }
    }
    else if (_transferType == YuneecDataTransferConnectionTypeWifi) {
        if (_MFiUpgradeDataTransfer != nil) {
            _MFiUpgradeDataTransfer.delegate = nil;
            _MFiUpgradeDataTransfer = nil;
        }

        NSAssert(_wifiUpgradeDataTransfer == nil, @"wifi data transfer is not nil");
        _wifiUpgradeDataTransfer = [[YuneecWifiUpgradeDataTransfer alloc] init];
        _wifiUpgradeDataTransfer.delegate = self;
    }
    else if (_transferType == YuneecDataTransferConnectionTypeMFi) {
        if (_wifiUpgradeDataTransfer != nil) {
            _wifiUpgradeDataTransfer.delegate = nil;
            _wifiUpgradeDataTransfer = nil;
        }

        NSAssert(_MFiUpgradeDataTransfer == nil, @"MFi data transfer is not nil");
        _MFiUpgradeDataTransfer = [[YuneecMFiUpgradeDataTransfer alloc] init];
        _MFiUpgradeDataTransfer.delegate = self;
    }
}

@end
