//
//  RCResponseGetVersionInfo.m
//  YuneecApp
//
//  Created by dj.yue on 2017/4/26.
//  Copyright © 2017年 dj.yue. All rights reserved.
//

#import "RCResponseGetVersionInfo.h"

#pragma pack(push)
#pragma pack(1)

typedef struct CMD_GET_VERSION_Response {
    uint8_t command;// = CMD_GET_VERSION;
    uint8_t code;
    uint16_t hardwareVersionLen;
    uint8_t *hardwareVersion; //utf8字符串转byte数组
    uint16_t firmwareVersionLen;
    uint8_t *firmwareVersion; //utf8字符串转byte数组
    uint16_t mcuVersionLen;
    uint8_t *mcuVersion; //utf8字符串转byte数组
    
}CMD_GET_VERSION_Response;

#pragma pack(pop)

@implementation RCResponseGetVersionInfo

+ (id)infoWithPayload:(NSData *)payload withCommand:(RC_CMD_ID)command{
    struct CMD_GET_VERSION_Response response;
    uint8_t *datas = (uint8_t *)payload.bytes;
    uint16_t length = payload.length;
    
    if (length < 2) {
        return nil;
    }
    memcpy(&response, datas, 2);
    if (response.command != CMD_GET_VERSION) {
        return [RCResponseInfo infoWithPayload:payload withCommand:command];
    }
    
    RCResponseGetVersionInfo *info = [[RCResponseGetVersionInfo alloc] init];
    info.command = response.command;
    info.code = response.code;
    if (length < 3) {///<失败时可能没有附加信息
        return info;
    }
    
    datas += 2;
    length -= 2;
    
    if (length < 2) {
        return nil;
    }
    
    memcpy(&response.hardwareVersionLen, datas, 2);
    datas += 2;
    length -= 2;
    
    if (length < response.hardwareVersionLen) {
        return nil;
    }
    response.hardwareVersion = malloc(response.hardwareVersionLen);
    memcpy(response.hardwareVersion, datas, response.hardwareVersionLen);
    datas += response.hardwareVersionLen;
    length -= response.hardwareVersionLen;
    info.hardwareVersion = [[NSString alloc] initWithBytes:response.hardwareVersion
                                                    length:response.hardwareVersionLen
                                                  encoding:NSUTF8StringEncoding];
    free(response.hardwareVersion);
    
    if (length < 2) {
        return nil;
    }
    
    memcpy(&response.firmwareVersionLen, datas, 2);
    datas += 2;
    length -= 2;
    
    if (length < response.firmwareVersionLen) {
        return nil;
    }
    response.firmwareVersion = malloc(response.firmwareVersionLen);
    memcpy(response.firmwareVersion, datas, response.firmwareVersionLen);
    datas += response.firmwareVersionLen;
    length -= response.firmwareVersionLen;
    info.firmwareVersion = [[NSString alloc] initWithBytes:response.firmwareVersion
                                                    length:response.firmwareVersionLen
                                                  encoding:NSUTF8StringEncoding];
    free(response.firmwareVersion);
    
    if (length < 2) {
        return nil;
    }
    
    memcpy(&response.mcuVersionLen, datas, 2);
    datas += 2;
    length -= 2;
    
    if (length < response.mcuVersionLen) {
        return nil;
    }
    response.mcuVersion = malloc(response.mcuVersionLen);
    memcpy(response.mcuVersion, datas, response.mcuVersionLen);
    //datas += response.mcuVersionLen;
    //length -= response.mcuVersionLen;
    info.mcuVersion = [[NSString alloc] initWithBytes:response.mcuVersion
                                               length:response.mcuVersionLen
                                             encoding:NSUTF8StringEncoding];
    free(response.mcuVersion);
    
    return info;
}

@end
