//
//  YuneecMFiInnerDataTransfer.m
//  YuneecMFiDataTransfer
//
//  Created by tbago on 23/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import "YuneecMFiInnerDataTransfer.h"

#import <UIKit/UIKit.h>
#import <BaseFramework/DebugOutput.h>

#import "YuneecMFiDefine.h"
#import "YuneecMFiSessionManager.h"
#import "YuneecMFiSessionController.h"
#import "YuneecMFiControllerProtocolBuilder.h"

#import <c_library_v2/yuneec/mavlink.h>

#ifdef DEBUG
#define DNSLog(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define DNSLog(format, ...)
#endif

@interface YuneecMFiInnerDataTransfer()

@property (nonatomic, strong) NSMutableData *receivedData;

@end

@implementation YuneecMFiInnerDataTransfer

+ (instancetype)sharedInstance {
    static YuneecMFiInnerDataTransfer *sInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[YuneecMFiInnerDataTransfer alloc] init];
    });
    return sInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleSessionControllerDidReceivedDataNotification:) name:kYuneecMFiSessionDataReceivedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleApplicationWillTerminateNotification:) name:UIApplicationWillTerminateNotification
                                                   object:nil];
#ifdef DEBUG
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleSessionControllerDebugNotification:)
                                                     name:kYuneecMFiSessionDebugNotification
                                                   object:nil];
#endif
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kYuneecMFiSessionDataReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
#ifdef DEBUG
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kYuneecMFiSessionDebugNotification object:nil];
#endif
}

#pragma mark - public method

- (BOOL)openMFiDataTransfer {
    NSAssert(self.connectedAccessory != nil, @"EAAssessory is nil");
    [[YuneecMFiSessionManager sharedInstance] createSessionControllersWithAccessory:self.connectedAccessory];
    return YES;
}

- (void)closeMFiDataTransfer {
    [[YuneecMFiSessionManager sharedInstance] closeSessionControllers];
}

- (void)sendMFiData:(NSData *) data
       protocolType:(YuneecMFiProtocolType) protocolType
{
    NSData *buildData = [YuneecMFiControllerProtocolBuilder buildProtocolDataWithProtocolType:protocolType contentData:data];
    if ([YuneecMFiSessionManager sharedInstance].mfiSessionControllerArray.count > 0) {
        YuneecMFiSessionController *sessionController = [YuneecMFiSessionManager sharedInstance].mfiSessionControllerArray[0];
        [sessionController writeData:buildData];
    }
}

#pragma mark - notification
- (void)handleSessionControllerDidReceivedDataNotification:(NSNotification *) notification {
    YuneecMFiSessionController *sessionController = (YuneecMFiSessionController *)[notification object];
    NSInteger index = [[YuneecMFiSessionManager sharedInstance].mfiSessionControllerArray indexOfObject:sessionController];
    if (index == NSNotFound) {
        DebugOutputError(@"receive unsupport protocol string");
        return;
    }

    NSData *receivedData = notification.userInfo[@"data"];
    MfiParsedInfo parsedInfo;
    memset(&parsedInfo, 0, sizeof(MfiParsedInfo));
    [self.receivedData appendData:receivedData];
    // 接收的包长度
    NSUInteger headerLength = 8;
    if(_receivedData.length == 0) {
        return;
    }

    while(_receivedData.length > 0) {
        NSUInteger receivedDataLength = _receivedData.length;
        if (receivedDataLength < headerLength) {
            break;
        }
        uint8_t *receivedDataBytes = (uint8_t *)_receivedData.bytes;
        // 包头不是0x66，检索这个包中有没有0x66的包
        if (receivedDataBytes[0] != 0x66 || receivedDataBytes[1] != 0x66) {
            NSLog(@"+++++not 0x66");
            uint32_t invalidDataLength = 0;
            BOOL bFoundSync = NO;
            for(int i = 0; i < receivedDataLength - 1; i++) {
                if((receivedDataBytes[i] == 0x66) && (receivedDataBytes[i+1] == 0x66)) {
                    invalidDataLength = i;
                    if((receivedDataLength - invalidDataLength) > (headerLength + 1)) {
                        bFoundSync = YES;
                    }
                    [self.receivedData replaceBytesInRange:NSMakeRange(0, i) withBytes:NULL length:0];
                    // 更新receivedDataLength， receivedDataBytes
                    receivedDataLength = self.receivedData.length;
                    receivedDataBytes = (uint8_t *)_receivedData.bytes;
                    if (receivedDataBytes[0] == 0x66 || receivedDataBytes[1] == 0x66) {
                        NSLog(@"+++++sync found 0x6666");
                    }
                    break;
                }
            }
            if (bFoundSync == NO) {
                NSLog(@"+++++sync not found 0x6666");
                break;
            }
        }
        uint16_t payloadLength;
        memcpy(&payloadLength, receivedDataBytes + 2, 2);

        NSData *contentData = nil;
        NSUInteger aCompletionDataLength = payloadLength + headerLength;
        if (receivedDataLength == aCompletionDataLength) {
            contentData = [YuneecMFiControllerProtocolBuilder parserContentDataFromProtocolData:_receivedData.copy parsedInfo:&parsedInfo];
        } else if (receivedDataLength > aCompletionDataLength) {
            // 拆包
            NSData *firstCompletionData = [self.receivedData subdataWithRange:NSMakeRange(0, aCompletionDataLength)];
            contentData = [YuneecMFiControllerProtocolBuilder parserContentDataFromProtocolData:firstCompletionData parsedInfo:&parsedInfo];

        } else {
            // 不做处理，等待下一个包
            break;
        }
        [self.receivedData replaceBytesInRange:NSMakeRange(0, aCompletionDataLength) withBytes:NULL length:0];
        if(contentData == nil) {
            break;
        }
        if(parsedInfo.bDataLacking) {
            // data is lacking in one payload , consume more
            continue;
        }
        if (YuneecMFiProtocolTypeController == parsedInfo.protocolType) {
            if (self.remoteControllerDelegate != nil) {
                [self.remoteControllerDelegate MFiInnerDataTransfer:self didReceiveData:contentData];
            }
        }
        else if (YuneecMFiProtocolTypeVideoStream == parsedInfo.protocolType) {
            if (self.cameraStreamDelegate != nil) {
                int64_t videoPts = (int64_t)parsedInfo.pts;
                if(parsedInfo.pts == -1) {
                    // PTS is invalid, convert uint32 to int64
                    videoPts = -1;
                }
                [self.cameraStreamDelegate MFiInnerDataTransfer:self
                                             didReceiveH264Data:contentData
                                             decompassTimeStamp:-1
                                               presentTimeStamp:videoPts];
            }
        }
        else if (YuneecMFiProtocolTypeMavlink2Protocol == parsedInfo.protocolType) {
            [self parserMavlinkData:contentData];
        }
        else if (parsedInfo.protocolType == YuneecMFiProtocolTypeOTA) {
            if (self.upgradeDelegate != nil) {
                [self.upgradeDelegate MFiInnerDataTransfer:self didReceiveData:contentData];
            }
        }
        else if (YuneecMFiProtocolTypePhotoDownload == parsedInfo.protocolType) {
            if (self.photoDownloadDelegate != nil) {
                [self.photoDownloadDelegate MFiInnerDataTransfer:self
                                                  didReceiveData:contentData];
            }
        }
    }
}



- (void)handleApplicationWillTerminateNotification:(NSNotification *) notification {
    // must close session when app has been terminated
    [self closeMFiDataTransfer];
}

- (void)parserMavlinkData:(NSData *) mavlinkData {
    //    NSString *debugString = [NSString stringWithFormat:@"mavlink:%@", mavlinkData];
    //    DebugOutputInfo(debugString);

    uint8_t *byteData = (uint8_t *)mavlinkData.bytes;
    uint32_t byteLen = (uint32_t)mavlinkData.length;

    mavlink_message_t      receive_message;
    mavlink_status_t       status;
    for (uint32_t i = 0; i < byteLen; i++)
    {
        uint8_t byte = byteData[i];
        uint8_t parse_ret = mavlink_parse_char(0, byte, &receive_message, &status);
        if (parse_ret) {
            if ((receive_message.compid == 100) || (receive_message.compid == 154)) {
                if (self.controllerDataDelegate != nil) {
                    NSData *messageData = [[NSData alloc] initWithBytes:&receive_message length:sizeof(mavlink_message_t)];
                    if (receive_message.msgid == MAVLINK_MSG_ID_UPDATE_STATUS_FEEDBACK) {
                        [self.controllerDataDelegate MFiInnerDataTransfer:self
                                               didReceiveUpgradeStateData:messageData];
                    }
                    else {
                        [self.controllerDataDelegate MFiInnerDataTransfer:self
                                                     didReceiveCameraData:messageData];

                        // NOTE: We need to forward this to didReceiveFlyingControllerData because
                        //       that way it gets forwarded in the same way as the rest of this
                        //       traffic via UDP to the SDK port on 14540.
                        // NOTE: Also, we need to send the wire format (mavlinkData) and not the unpacked
                        //       mavlink_message_t.
                        NSData *messageData = [[NSData alloc] initWithBytes:&receive_message length:sizeof(mavlink_message_t)];
                        [self.controllerDataDelegate MFiInnerDataTransfer:self
                                                    didReceiveFlyingControllerData:mavlinkData];
                    }
                }
            }
            else if (receive_message.compid != 250) {
                if (self.controllerDataDelegate != nil) {
                    // FIXME: Note, previously this would send messageData containing a mavlink_message_t instead
                    //        of the wire format required for the SDK.
                    NSData *messageData = [[NSData alloc] initWithBytes:&receive_message length:sizeof(mavlink_message_t)];
                    [self.controllerDataDelegate MFiInnerDataTransfer:self
                                       didReceiveFlyingControllerData:mavlinkData];
                }
            }
            else {
                if (self.remoteControllerDelegate != nil) {
                    NSData *messageData = [[NSData alloc] initWithBytes:&receive_message length:sizeof(mavlink_message_t)];
                    [self.remoteControllerDelegate MFiInnerDataTransfer:self didReceiveData:messageData];
                }
            }
        }
        //        NSLog(@"ret:%d, parse state:%d", parse_ret, status.parse_state);
    }
}

#ifdef DEBUG
- (void)handleSessionControllerDebugNotification:(NSNotification *) notification {
    DNSLog(@"debug message:%@", notification.userInfo[@"msg"]);
}
#endif

- (NSMutableData *)receivedData
{
    if (!_receivedData) {
        self.receivedData = [[NSMutableData alloc] init];
    }
    return _receivedData;
}

@end
