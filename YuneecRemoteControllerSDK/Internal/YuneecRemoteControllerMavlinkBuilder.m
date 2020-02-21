//
//  YuneecRemoteControllerMavlinkBuilder.m
//  YuneecRemoteControllerSDK
//
//  Created by tbago on 05/12/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import "YuneecRemoteControllerMavlinkBuilder.h"
#import <c_library_v2/yuneec/mavlink.h>

static const NSInteger  kRemoteControllerSystemId       = 0x01;
static const NSInteger  kRemoteControllerComponentId    = 250;

@implementation YuneecRemoteControllerMavlinkBuilder

+ (NSData *)buildMavlinkDataWithContentData:(NSData *) contentData {
    mavlink_message_t       message;
    mavlink_mav_rc_cmd_t    mav_rc_cmd;
    memset(&mav_rc_cmd, 0, sizeof(mavlink_mav_rc_cmd_t));
    uint8_t *contentByte        = (uint8_t *)contentData.bytes;
    uint32_t contentByteLength  = (uint32_t)contentData.length;
    mav_rc_cmd.command = contentByte[0];
    if (contentByteLength > 1) {
        memcpy(mav_rc_cmd.params, contentByte+1, contentByteLength - 1);
    }
    uint16_t package_len = mavlink_msg_mav_rc_cmd_encode(kRemoteControllerSystemId, kRemoteControllerComponentId,
                                                         &message, &mav_rc_cmd);
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)

    NSData *mavlinkData = [[NSData alloc] initWithBytes:buf length:package_len];
    free(buf);
    return mavlinkData;
}

+ (NSData * _Nullable)parserContentDataFromMavlinkData:(NSData *) mavlinkData {
//    NSLog(@"data:%@", mavlinkData);
    uint8_t *byteData = (uint8_t *)mavlinkData.bytes;
    uint32_t byteLen = (uint32_t)mavlinkData.length;

    mavlink_message_t      receive_message;
    memset(&receive_message, 0, sizeof(mavlink_message_t));
    memcpy(&receive_message, byteData, byteLen);

//    NSLog(@"receive system id:%d, component id:%d, message id:%d", receive_message.sysid, receive_message.compid, receive_message.msgid);
    if (receive_message.msgid == MAVLINK_MSG_ID_MAV_RC_CMD_ACK) {
        mavlink_mav_rc_cmd_ack_t    rc_cmd_ack;
        mavlink_msg_mav_rc_cmd_ack_decode(&receive_message, &rc_cmd_ack);
        NSData *contentData = [[NSData alloc] initWithBytes:&rc_cmd_ack length:sizeof(mavlink_mav_rc_cmd_ack_t)];
        return contentData;
    }
    return nil;
}

@end
