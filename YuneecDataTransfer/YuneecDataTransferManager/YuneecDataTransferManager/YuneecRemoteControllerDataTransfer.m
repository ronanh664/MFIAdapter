//
//  YuneecRemoteControllerDataTransfer.m
//  YuneecDataTransferManager
//
//  Created by tbago on 27/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import "YuneecRemoteControllerDataTransfer.h"

#import <YuneecMFiDataTransfer/YuneecMFiRemoteControllerDataTransfer.h>

@interface YuneecRemoteControllerDataTransfer()<YuneecMFiRemoteControllerDataTransferDelegate>

///< MFi
@property (strong, nonatomic) YuneecMFiRemoteControllerDataTransfer     *MFiRemoteControllerDataTransfer;

@end

@implementation YuneecRemoteControllerDataTransfer

#pragma mark - init
- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _MFiRemoteControllerDataTransfer = [[YuneecMFiRemoteControllerDataTransfer alloc] init];
    _MFiRemoteControllerDataTransfer.delegate = self;
}

#pragma mark - public method

- (void)sendData:(NSData *)data {
    [self.MFiRemoteControllerDataTransfer sendData:data];
}

- (void)sendOldProtocolData:(NSData *) data {
    [self.MFiRemoteControllerDataTransfer sendOldProtocolData:data];
}

#pragma mark - YuneecMFiRemoteControllerDataTransferDelegate

- (void)MFiRemoteControllerDataTransfer:(YuneecMFiRemoteControllerDataTransfer *) dataTransfer
                         didReceiveData:(NSData *) data
{
    if (self.delegate != nil) {
        [self.delegate remoteControllerDataTranfer:self didReceiveData:data];
    }
}
@end
