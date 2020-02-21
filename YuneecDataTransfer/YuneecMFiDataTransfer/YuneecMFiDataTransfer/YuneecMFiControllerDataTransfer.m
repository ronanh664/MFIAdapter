//
//  YuneecMFiControllerDataTransfer.m
//  YuneecMFiDataTransfer
//
//  Created by tbago on 17/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import "YuneecMFiControllerDataTransfer.h"
#import "YuneecMFiInnerDataTransfer.h"

@interface YuneecMFiControllerDataTransfer() <YuneecMFiInnerControllerDataTransferDelegate>

@end

@implementation YuneecMFiControllerDataTransfer

#pragma mark - init

- (instancetype)init {
    self = [super init];
    if (self) {
        [YuneecMFiInnerDataTransfer sharedInstance].controllerDataDelegate = self;
    }
    return self;
}

#pragma mark - public method

- (void)sendData:(NSData *) data {
    [[YuneecMFiInnerDataTransfer sharedInstance] sendMFiData:data
                                                protocolType:YuneecMFiProtocolTypeMavlink2Protocol];
}

#pragma mark - YuneecMFiInnerControllerDataTransferDelegate

- (void)MFiInnerDataTransfer:(YuneecMFiInnerDataTransfer *) MFiDataTransfer
        didReceiveCameraData:(NSData *) data
{
    if (self.cameraControllerDelegate != nil) {
        [self.cameraControllerDelegate MFiControllerDataTransfer:self didReceiveCameraData:data];
    }
}

- (void)MFiInnerDataTransfer:(YuneecMFiInnerDataTransfer *) MFiDataTransfer
didReceiveFlyingControllerData:(NSData *) data
{
    if (self.flyingControllerDelegate != nil) {
        [self.flyingControllerDelegate MFiControllerDataTransfer:self didReceiveFlyingControllerData:data];
    }
}

- (void)MFiInnerDataTransfer:(YuneecMFiInnerDataTransfer *) MFiDataTransfer
  didReceiveUpgradeStateData:(NSData *) upgradeStateData {
    if (self.upgradeStateDelegate != nil) {
        [self.upgradeStateDelegate MFiControllerDataTransfer:self didReceiveUpgradeStateData:upgradeStateData];
    }
}

@end
