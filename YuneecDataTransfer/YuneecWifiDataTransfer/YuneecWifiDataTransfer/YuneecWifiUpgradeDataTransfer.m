//
//  YuneecWifiUpgradeDataTransfer.m
//  YuneecWifiDataTransfer
//
//  Created by tbago on 16/03/2018.
//  Copyright © 2018 yuneec. All rights reserved.
//

#import "YuneecWifiUpgradeDataTransfer.h"

#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>

#import <BaseFramework/DebugLog.h>
#import "YuneecWifiDataTransferConfig.h"

@interface YuneecWifiUpgradeDataTransfer() <GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket     *tcpSocket;

@end

@implementation YuneecWifiUpgradeDataTransfer

- (BOOL)connectToServer {
    NSError *error = nil;
    BOOL ret = [self.tcpSocket connectToHost:upgradeIpAddress onPort:upgradePort error:&error];
    if (!ret) {
        DNSLog(@"Upgrade : Connect failed:%@", error.localizedDescription);
    }
    [self.tcpSocket readDataWithTimeout:-1 tag:0];
    return ret;
}

- (void)disconnectToServer {
    [self.tcpSocket disconnect];
}

- (void)sendData:(NSData *) data {
    [self.tcpSocket writeData:data withTimeout:upgradeSendDataTimeout tag:0];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    DNSLog(@"Upgrade : Connect to server success");
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    DNSLog(@"Upgrade : Read data success:%@", data);
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(wifiUpgradeDataTransfer:didReceiveData:)]) {
        [self.delegate wifiUpgradeDataTransfer:self didReceiveData:data];
    }
    [self.tcpSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    if ([self.delegate respondsToSelector:@selector(wifiUpgradeDataTransferDidSendData)]) {
        [self.delegate wifiUpgradeDataTransferDidSendData];
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *) error {
    DNSLog(@"Upgrade : Disconnect from server:%@", error.localizedDescription);
}

#pragma mark - get & set

- (GCDAsyncSocket *)tcpSocket {
    if (_tcpSocket == nil) {
        _tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _tcpSocket;
}
@end
