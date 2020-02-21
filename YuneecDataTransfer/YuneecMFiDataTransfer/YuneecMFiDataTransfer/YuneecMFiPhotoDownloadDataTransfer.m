//
//  YuneecMFiPhotoDownloadDataTransfer.m
//  YuneecMFiDataTransfer
//
//  Created by hank on 26/03/2018.
//  Copyright © 2018 yuneec. All rights reserved.
//

#import "YuneecMFiPhotoDownloadDataTransfer.h"
#import "YuneecMFiInnerDataTransfer.h"

@interface YuneecMFiPhotoDownloadDataTransfer () <YuneecMFiInnerPhotoDownloadDataTranferDelegate>

@end

@implementation YuneecMFiPhotoDownloadDataTransfer

#pragma mark - init

- (instancetype)init {
    self = [super init];
    if (self) {
        [YuneecMFiInnerDataTransfer sharedInstance].photoDownloadDelegate = self;
    }
    return self;
}

#pragma mark - public method

- (void)sendData:(NSData *) data {
    [[YuneecMFiInnerDataTransfer sharedInstance] sendMFiData:data
                                                protocolType:YuneecMFiProtocolTypePhotoDownload];
}

#pragma mark - YuneecMFiInnerPhotoDownloadDataTranferDelegate

- (void)MFiInnerDataTransfer:(YuneecMFiInnerDataTransfer *)MFiDataTransfer
              didReceiveData:(NSData *)data
{
    if (self.delegate) {
//        NSLog(@"++++++++delegate2");
        [self.delegate MFiPhotoDownloadDataTransfer:self didReceiveData:data];
    }
}


@end
