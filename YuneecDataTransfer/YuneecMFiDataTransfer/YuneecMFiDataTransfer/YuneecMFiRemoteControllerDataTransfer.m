//
//  YuneecMFiRemoteControllerDataTransfer.m
//  YuneecMFiDataTransfer
//
//  Created by tbago on 27/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import "YuneecMFiRemoteControllerDataTransfer.h"
#import "YuneecMFiInnerDataTransfer.h"

@interface YuneecMFiRemoteControllerDataTransfer()<YuneecMFiInnerRemoteControllerDataTransferDelegate>

@end

@implementation YuneecMFiRemoteControllerDataTransfer

#pragma mark - init

- (instancetype)init {
    self = [super init];
    if (self) {
        [YuneecMFiInnerDataTransfer sharedInstance].remoteControllerDelegate = self;
    }
    return self;
}

#pragma mark - pubic method

- (void)sendData:(NSData *)data {
    [[YuneecMFiInnerDataTransfer sharedInstance] sendMFiData:data
                                                protocolType:YuneecMFiProtocolTypeMavlink2Protocol];
}

- (void)sendOldProtocolData:(NSData *) data {
    [[YuneecMFiInnerDataTransfer sharedInstance] sendMFiData:data
                                                protocolType:YuneecMFiProtocolTypeController];
}

#pragma mark - YuneecMFiInnerRemoteControllerDataTranferDelegate

- (void)MFiInnerDataTransfer:(YuneecMFiInnerDataTransfer *) MFiDataTranfer
              didReceiveData:(NSData *) data
{
    if (self.delegate != nil) {
        [self.delegate MFiRemoteControllerDataTransfer:self didReceiveData:data];
    }
}
@end
