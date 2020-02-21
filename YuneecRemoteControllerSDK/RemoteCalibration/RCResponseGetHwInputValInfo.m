//
//  RCResponseGetHwInputValInfo.m
//  YuneecApp
//
//  Created by dj.yue on 2017/4/25.
//  Copyright © 2017年 dj.yue. All rights reserved.
//

#import "RCResponseGetHwInputValInfo.h"

#pragma pack(push)
#pragma pack(1)
typedef struct CMD_CMD_GET_HW_INPUT_VAL_Response {
    uint8_t command;// CMD_GET_HW_INPUT_VAL
    uint8_t code;
    uint8_t jcount;//摇杆数
    uint8_t kcount;//旋钮数
    uint8_t scount;//switch开关数
    uint8_t bcount;//button按钮数
    int16_t *jvalues;//摇杆值
    int16_t *kvalues;//旋钮值
    int16_t *svalues;//switch开关值
    int16_t *bvalues;//button按钮值
}CMD_CMD_GET_HW_INPUT_VAL_Response;
#pragma pack(pop)

@implementation RCResponseGetHwInputValInfo

+ (id)infoWithPayload:(NSData *)payload withCommand:(RC_CMD_ID)command{
    struct CMD_CMD_GET_HW_INPUT_VAL_Response response;
    uint8_t *datas = (uint8_t *)payload.bytes;
    uint16_t length = payload.length;
    
    if (length < 2) {
        return nil;
    }
    memcpy(&response, datas, 2);
    response.command = command;
    if (command != CMD_GET_HW_INPUT_VAL) {
        return [RCResponseInfo infoWithPayload:payload withCommand:command];
    }
    
    RCResponseGetHwInputValInfo *info = [[RCResponseGetHwInputValInfo alloc] init];
    info.command = response.command;
    info.code = response.code;
    if (length < 3) {///<失败时可能没有附加信息
        return info;
    }
    datas += 2;
    length -= 2;
    if (length < 4) {
        return  nil;
    }
    memcpy((uint8_t *)&response + 2, datas, 4);///j,k,s,b count
    datas += 4;
    length -= 4;

//    if (length != (response.jcount + response.kcount + response.scount + response.bcount) * 2) {
//        return nil;
//    }
    response.jvalues = malloc(2 * response.jcount);
    response.kvalues = malloc(2 * response.kcount);
    response.svalues = malloc(2 * response.scount);
    response.bvalues = malloc(2 * response.bcount);
    
    memcpy(response.jvalues, datas, response.jcount * 2);
    datas += response.jcount * 2;
    memcpy(response.kvalues, datas, response.kcount * 2);
    datas += response.kcount * 2;
    memcpy(response.svalues, datas, response.scount * 2);
    datas += response.scount * 2;
    memcpy(response.bvalues, datas, response.bcount * 2);
    //datas += response.bcount * 2;
    
    NSMutableArray *muJ = [NSMutableArray new];
    NSMutableArray *muK = [NSMutableArray new];
    NSMutableArray *muS = [NSMutableArray new];
    NSMutableArray *muB = [NSMutableArray new];
    
    for (int i = 0; i < response.jcount; i ++) {
        [muJ addObject:@(response.jvalues[i])];
    }
    for (int i = 0; i < response.kcount; i ++) {
        [muK addObject:@(response.kvalues[i])];
    }
    for (int i = 0; i < response.scount; i ++) {
        [muS addObject:@(response.svalues[i])];
    }
    for (int i = 0; i < response.bcount; i ++) {
        [muB addObject:@(response.bvalues[i])];
    }
    
    free(response.jvalues);
    free(response.kvalues);
    free(response.svalues);
    free(response.bvalues);
    
    info.jValues = muJ;
    info.kValues = muK;
    info.sValues = muS;
    info.bValues = muB;
    
    return info;
}

@end
