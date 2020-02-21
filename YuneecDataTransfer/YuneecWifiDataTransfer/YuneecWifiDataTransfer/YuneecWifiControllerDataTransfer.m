//
//  YuneecWifiControllerDataTransfer.m
//  YuneecWifiDataTransfer
//
//  Created by tbago on 2017/9/18.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecWifiControllerDataTransfer.h"

#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>

#import <c_library_v2/common/mavlink.h>

#import "YuneecWifiDataTransferConfig.h"

static const NSUInteger     defaultSendDataPort = 49160;

@interface YuneecWifiControllerDataTransfer() <GCDAsyncUdpSocketDelegate>

///< dynamic controller port
@property (nonatomic, assign) NSUInteger            controllerPort;
@property (nonatomic, assign) BOOL                  initControllerPort;

@property (nonatomic, strong) GCDAsyncUdpSocket     *udpSocket;

@end

@implementation YuneecWifiControllerDataTransfer

#pragma mark - init

- (instancetype)init {
    self = [super init];
    if (self) {
        _initControllerPort = NO;
    }
    return self;
}

- (void)dealloc {
    [self closeUdpSocket];
}

- (void)close {
    // UDP socket should be closed before destroy
    [self closeUdpSocket];
}

- (void)closeUdpSocket {
    @synchronized (self) {
        if(_udpSocket != nil) {
            [_udpSocket pauseReceiving];
            [_udpSocket close];
            _udpSocket = nil;
        }
    }
}

- (void)sendData:(NSData *) data {
    NSUInteger sendDataPort;
    if (!self.initControllerPort) {
        sendDataPort = defaultSendDataPort;
    }
    else {
        sendDataPort = self.controllerPort;
    }

    [self.udpSocket sendData:data
                      toHost:cameraIpAddress
                        port:sendDataPort
                 withTimeout:cameraControllerSendDataTimeout
                         tag:0];
}

#pragma mark - GCDAsyncUdpSocketDelegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error {

}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock
   didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    if (!self.initControllerPort) {      ///< init camera controller send data port
        NSString *cameraHost = [[NSString alloc] init];
        uint16_t cameraPort = 0;
        [GCDAsyncUdpSocket getHost:&cameraHost port:&cameraPort fromAddress:address];
        self.controllerPort     = cameraPort;
        self.initControllerPort = YES;
    }
    [self parserControllerData:data];
}

- (void)parserControllerData:(NSData *) data {
    uint8_t *byteData = (uint8_t *)data.bytes;
    uint32_t byteLen = (uint32_t)data.length;

    mavlink_message_t      receive_message;
    mavlink_status_t       status;
    for (uint32_t i = 0; i < byteLen; i++)
    {
        uint8_t byte = byteData[i];
        if (mavlink_parse_char(0, byte, &receive_message, &status)) {
            if (receive_message.compid == 100) {
                // FIXME: UPDATE_STATUS_FEEDBACK does not exist in common mavlink.
//                if (receive_message.msgid == MAVLINK_MSG_ID_UPDATE_STATUS_FEEDBACK) {
//                    if (self.upgradeStateDelegate != nil) {
//                        NSData *messageData = [[NSData alloc] initWithBytes:&receive_message length:sizeof(mavlink_message_t)];
//                        [self.upgradeStateDelegate wifiControllerDataTransfer:self didReceiveUpgradeStateData:messageData];
//                    }
//                }
//                else
                    if (self.cameraControllerDelegate != nil) {
                    NSData *messageData = [[NSData alloc] initWithBytes:&receive_message length:sizeof(mavlink_message_t)];
                    [self.cameraControllerDelegate wifiControllerDataTransfer:self didReceiveCameraData:messageData];
                }
            }
            else if (receive_message.compid == 1) {
                if (self.flyingControllerDelegate != nil) {
                    NSData *messageData = [[NSData alloc] initWithBytes:&receive_message length:sizeof(mavlink_message_t)];
                    [self.flyingControllerDelegate wifiControllerDataTransfer:self didReceiveFlyingControllerData:messageData];
                }
            }
        }
    }
}

#pragma mark - get & set

- (GCDAsyncUdpSocket *)udpSocket {
    @synchronized (self) {
        if (_udpSocket == nil) {
            _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self
                                                       delegateQueue:dispatch_get_main_queue()];
            NSError *error = nil;
            if (![_udpSocket bindToPort:14550 error:&error]) {
                NSLog(@"Bing port failed,%@", error);
            }

            if (![_udpSocket beginReceiving:&error]) {
                NSLog(@"Begin receive data failed,%@", error);
            }
        }
        return _udpSocket;
    }
}

@end
