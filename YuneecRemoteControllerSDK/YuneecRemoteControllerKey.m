//
//  YuneecRemoteControllerKey.m
//  YuneecApp
//
//  Created by dj.yue on 2017/5/3.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import "YuneecRemoteControllerKey.h"

#pragma pack(push)
#pragma pack(1)

typedef struct MSG_REPORT_EVENT_Message {
    uint8_t command;// = MSG_REPORT_EVENT;
    uint8_t code;
    uint8_t eventid;    // 1~10 for Button1~10; 11~20 for Switch1~10; 21~30 for Wheel1~10; 41 for Wifi; 42 for Battery; 43 for HDMI
    int8_t value;
    // For Button:0-release 1-prees 2-long press;
    // For Switch: 0-middle 1-right 2-left;
    // For Wheel: 1-turn left -1-turn right
    // For Wifi: 0-disconnected, 1-connected, 2-Auth failed
    // For battery: Percentage of battery power (for example, 15 means 15% remaining)
    // For HDMI: 0-disconnected, 1-connected

}MSG_REPORT_EVENT_Message;

#pragma pack(pop)

@implementation YuneecRemoteControllerKey
+ (instancetype)sharedInstance {
    static YuneecRemoteControllerKey * sInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[YuneecRemoteControllerKey alloc] init];
    });
    return sInstance;
}

- (void)infoWithPayload:(NSData *)payload  withCommand:(RC_CMD_ID)command{
    struct MSG_REPORT_EVENT_Message response;
    uint8_t *datas = (uint8_t *)payload.bytes;
    uint16_t length = payload.length;

    if (length < 2) {
        return;
    }
    memcpy(&response, datas, 2);
    if (response.command != MSG_REPORT_EVENT) {
        return;
    }
    if (length < 3) {///<There may be no additional information when it fails>
        return;
    }
    datas += 2;
    length -= 2;
    memcpy(&response.eventid, datas, 2);
    self.eventid = response.eventid;
    self.value = response.value;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(reportEventInfoUpdateRCCustomKeyEventid:withEventValue:)]) {
            [self.delegate reportEventInfoUpdateRCCustomKeyEventid:self.eventid withEventValue:self.value];
        }
    });
}

@end
