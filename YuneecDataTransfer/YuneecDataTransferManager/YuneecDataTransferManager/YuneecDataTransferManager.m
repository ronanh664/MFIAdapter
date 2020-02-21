//
//  YuneecDataTransferManager.m
//  YuneecDataTransferManager
//
//  Created by tbago on 16/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import "YuneecDataTransferManager.h"
#import "YuneecCameraStreamDataTransfer_TransferType.h"
#import "YuneecControllerDataTransfer_TranferType.h"
#import "YuneecUpgradeDataTransfer_TransferType.h"

@interface YuneecDataTransferManager()

@property (strong, nonatomic) YuneecCameraStreamDataTransfer        *streamDataTransfer;
@property (strong, nonatomic) YuneecControllerDataTransfer          *controllerDataTransfer;
@property (strong, nonatomic) YuneecRemoteControllerDataTransfer    *remoteControllerDataTransfer;
@property (strong, nonatomic) YuneecUpgradeDataTransfer             *upgradeDataTransfer;
@property (strong, nonatomic) YuneecPhotoDownloadDataTransfer       *photoDownloadDataTransfer;

@property (assign, nonatomic) YuneecDataTransferConnectionType      transferType;
@property (assign, nonatomic) YuneecDataTransferConnectionType      streamTransferType;

@end

@implementation YuneecDataTransferManager

#pragma mark - init

+ (instancetype)sharedInstance {
    static YuneecDataTransferManager *sInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[YuneecDataTransferManager alloc] init];
    });
    return sInstance;
}

- (id)init {
    self = [super init];
    self.transferType = YuneecDataTransferConnectionTypeNone;
    self.streamTransferType = YuneecDataTransferConnectionTypeNone;
    return self;
}

#pragma mark - public method

- (void)setCurrentDataTransferType:(YuneecDataTransferConnectionType) transferType {
    if(_transferType == transferType) {
        return;
    }
    _transferType = transferType;
    self.controllerDataTransfer.transferType    = _transferType;
    self.upgradeDataTransfer.transferType       = _transferType;
}

- (void)setStreamDataTransferType:(YuneecDataTransferConnectionType) transferType {
    if(_streamTransferType == transferType) {
        return;
    }
    _streamTransferType = transferType;
    self.streamDataTransfer.transferType        = _streamTransferType;
}

- (YuneecCameraStreamDataTransfer *)streamDataTransfer {
    if (_streamDataTransfer == nil) {
        _streamDataTransfer = [[YuneecCameraStreamDataTransfer alloc] init];
    }
    return _streamDataTransfer;
}

- (YuneecControllerDataTransfer *)controllerDataTransfer {
    if (_controllerDataTransfer == nil) {
        _controllerDataTransfer = [[YuneecControllerDataTransfer alloc] init];
    }
    return _controllerDataTransfer;
}

- (YuneecRemoteControllerDataTransfer *)remoteControllerDataTranfer {
    if (self.transferType == YuneecDataTransferConnectionTypeMFi) {
        if (_remoteControllerDataTransfer == nil) {
            _remoteControllerDataTransfer = [[YuneecRemoteControllerDataTransfer alloc] init];
        }
        return _remoteControllerDataTransfer;
    }
    else {
        return nil;
    }
}

- (YuneecUpgradeDataTransfer *)upgradeDataTransfer {
    if (_upgradeDataTransfer == nil) {
        _upgradeDataTransfer = [[YuneecUpgradeDataTransfer alloc] init];
    }
    return _upgradeDataTransfer;
}

- (YuneecPhotoDownloadDataTransfer *)photoDownloadDataTransfer
{
    if (_photoDownloadDataTransfer == nil) {
        _photoDownloadDataTransfer = [[YuneecPhotoDownloadDataTransfer alloc] init];
    }
    return _photoDownloadDataTransfer;
}
@end
