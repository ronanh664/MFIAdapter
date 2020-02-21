//
//  RCMessageReportEventInfo.m
//  YuneecApp
//
//  Created by dj.yue on 2017/5/3.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "RCMessageReportEventInfo.h"

#pragma pack(push)
#pragma pack(1)
NSString * const kOBRemoteMSGReportEventNotification   = @"kOBRemoteMSGReportEventNotification";

typedef struct MSG_REPORT_EVENT_Message {
    uint8_t command;// = MSG_REPORT_EVENT;
    uint8_t code;
    uint8_t eventid;    // 1~10 for Button1~10; 11~20 for Switch1~10; 21~30 for Wheel1~10
    int8_t value; // For Button:0-release 1-prees 2-long press;
    // For Switch: 0-middle 1-right 2-left;
    // For Whell: 1-turn left -1-turn right
    
}MSG_REPORT_EVENT_Message;

#pragma pack(pop)

@implementation RCMessageReportEventInfo

+ (id)infoWithPayload:(NSData *)payload  withCommand:(RC_CMD_ID)command{
    struct MSG_REPORT_EVENT_Message response;
    uint8_t *datas = (uint8_t *)payload.bytes;
    uint16_t length = payload.length;
    
    if (length < 2) {
        return nil;
    }
    memcpy(&response, datas, 2);
    if (response.command != MSG_REPORT_EVENT) {
        return nil;
    }
    RCMessageReportEventInfo *info = [[RCMessageReportEventInfo alloc] init];
    info.command = response.command;
    info.code = response.code;
    if (length < 3) {///<失败时可能没有附加信息
        return info;
    }
    datas += 2;
    length -= 2;
//    if (length != 2) {
//        return nil;
//    }
    memcpy(&response.eventid, datas, 2);
    info.eventid = response.eventid;
    info.value = response.value;
    NSDictionary* userInfo = @{@"OBEventid": @(info.eventid),
                               @"OBEventValue": @(info.value)};
    if ([NSThread isMainThread]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kOBRemoteMSGReportEventNotification object:nil userInfo:userInfo];
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kOBRemoteMSGReportEventNotification object:nil userInfo:userInfo];
        });
    }
    return info;
}

@end
