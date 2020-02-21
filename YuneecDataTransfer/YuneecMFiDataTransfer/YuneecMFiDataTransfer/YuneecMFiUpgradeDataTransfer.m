//
//  YuneecMFiUpgradeDataTransfer.m
//  YuneecMFiDataTransfer
//
//  Created by tbago on 16/03/2018.
//  Copyright © 2018 yuneec. All rights reserved.
//

#import "YuneecMFiUpgradeDataTransfer.h"
#import "YuneecMFiInnerDataTransfer.h"

@interface YuneecMFiUpgradeDataTransfer() <YuneecMFiInnerUpgradeDataTransferDelegate>

@end

@implementation YuneecMFiUpgradeDataTransfer

#pragma mark - init

- (instancetype)init {
    self = [super init];
    if (self) {
        [YuneecMFiInnerDataTransfer sharedInstance].upgradeDelegate = self;
    }
    return self;
}

- (BOOL)connectToServer {
    return YES;
}

- (void)disconnectToServer {

}

- (void)sendData:(NSData *) data {
    [[YuneecMFiInnerDataTransfer sharedInstance] sendMFiData:data
                                                protocolType:YuneecMFiProtocolTypeOTA];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 8*NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        [self callMFiUpgradeDataTransferDidSendData];
    });
}

#pragma mark - YuneecMFiInnerUpgradeDataTransferDelegate

- (void)callMFiUpgradeDataTransferDidSendData {
    if (self.delegate!= nil && [self.delegate respondsToSelector:@selector(MFiUpgradeDataTransferDidSendData)]) {
        [self.delegate MFiUpgradeDataTransferDidSendData];
    }
}

- (void)MFiInnerDataTransfer:(YuneecMFiInnerDataTransfer *) MFiDataTranfer
              didReceiveData:(NSData *) data
{
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(MFiUpgradeDataTransfer:didReceiveData:)]) {
        [self.delegate MFiUpgradeDataTransfer:self didReceiveData:data];
    }
}

@end
