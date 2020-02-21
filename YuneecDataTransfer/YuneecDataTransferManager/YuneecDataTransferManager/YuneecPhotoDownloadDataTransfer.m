//
//  YuneecPhotoDownloadDataTransfer.m
//  YuneecDataTransferManager
//
//  Created by hank on 26/03/2018.
//  Copyright © 2018 yuneec. All rights reserved.
//

#import "YuneecPhotoDownloadDataTransfer.h"
#import <YuneecMFiDataTransfer/YuneecMFiPhotoDownloadDataTransfer.h>

@interface YuneecPhotoDownloadDataTransfer () <YuneecMFiPhotoDownloadDataTransferDelegate>

@property (nonatomic, strong) YuneecMFiPhotoDownloadDataTransfer *MFiPhotoDownloadDataTransfer;

@end

@implementation YuneecPhotoDownloadDataTransfer

#pragma mark - init
- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _MFiPhotoDownloadDataTransfer = [[YuneecMFiPhotoDownloadDataTransfer alloc] init];
    _MFiPhotoDownloadDataTransfer.delegate = self;
}

#pragma mark - public method

- (void)sendData:(NSData *)data {
    [self.MFiPhotoDownloadDataTransfer sendData:data];
}

#pragma mark - YuneecMFiPhotoDownloadDataTransferDelegate

- (void)MFiPhotoDownloadDataTransfer:(YuneecMFiPhotoDownloadDataTransfer *)dataTransfer
                      didReceiveData:(NSData *)data
{
    if (self.delegate != nil) {
        [self.delegate photoDownloadDataTranfer:self didReceiveData:data];
    }
}

@end
