//
//  RCResponseGetStateInfo.m
//  YuneecApp
//
//  Created by dj.yue on 2017/5/22.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "RCResponseGetStateInfo.h"

#pragma pack(push)
#pragma pack(1)

typedef struct CMD_GET_STATE_Response {
    uint8_t command;// = CMD_GET_STATE;
    uint8_t code;
    uint8_t state;  // bit0: 0-不在Bind状态 1-在Bind状态
    // bit1：0-不在校准过程中 1-正在校准
    
}CMD_GET_STATE_Response;

#pragma pack(pop)

@implementation RCResponseGetStateInfo

+ (id)infoWithPayload:(NSData *)payload withCommand:(RC_CMD_ID)command{
    struct CMD_GET_STATE_Response response;
    uint8_t *datas = (uint8_t *)payload.bytes;
    uint16_t length = payload.length;
    
    if (length < 2) {
        return nil;
    }
    memcpy(&response, datas, 2);
    if (response.command != CMD_GET_STATE) {
        return [RCResponseInfo infoWithPayload:payload withCommand:command];
    }
    
    RCResponseGetStateInfo *info = [[RCResponseGetStateInfo alloc] init];
    info.command = response.command;
    info.code = response.code;
    
    if (length == 2) {
        return info;
    }
//    
//    if (length != 3) {
//        return nil;
//    }
    memcpy(&response, datas, 3);
    
    info.isBinding = ((response.state & 0x01) == 0x01);
    info.isCalibrating = ((response.state & 0x02) == 0x02);
    return info;
}

@end
