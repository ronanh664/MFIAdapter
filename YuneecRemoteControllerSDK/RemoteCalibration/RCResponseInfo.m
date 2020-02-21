//
//  RCInfo.m
//  YuneecApp
//
//  Created by dj.yue on 2017/4/17.
//  Copyright © 2017年 dj.yue. All rights reserved.
//

#import "RCResponseInfo.h"
#import "RemoteCalibrationHeaders.h"

#pragma pack(push)
#pragma pack(1)

typedef struct Payload_Header {
    uint8_t command;
    uint8_t code;
}Payload_Header;

#pragma pack(pop)

@implementation RCResponseInfo

+ (id)                                                                                                                                                                               infoWithPayload:(NSData *)payload withCommand:(RC_CMD_ID)command{
    if (payload == nil) {
        return nil;
    }
    if (payload.length < 2) {
        return nil;
    }
    struct Payload_Header header;
//    memcpy(&header, payload.bytes, 2);
    header.command = command;
    
    id info;
    
    switch (command) {
        case CMD_GET_VERSION:
            info = [RCResponseGetVersionInfo infoWithPayload:payload withCommand:command];
            break;
        case CMD_GET_HW_INPUT_VAL:
            info = [RCResponseGetHwInputValInfo infoWithPayload:payload withCommand:command];
            break;
        case CMD_GET_STATE:
            info = [RCResponseGetStateInfo infoWithPayload:payload withCommand:command];
            break;
        default:
        {
            RCResponseInfo *commonInfo = [[RCResponseInfo alloc] init];
            commonInfo.command = header.command;
            commonInfo.code = header.code;
            info = commonInfo;
        }
            break;
    }
    return info;
}

- (NSNumber *)key {
    uint16_t key;
    uint8_t command = 0x1E;
    uint8_t cmd = self.command;
    memcpy((uint8_t *)&key + 1, &command, 1);
    memcpy((uint8_t *)&key, &cmd, 1);
    return @(key);
}

@end
