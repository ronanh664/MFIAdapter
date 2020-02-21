//
//  RCRequestCommonInfo.m
//  YuneecApp
//
//  Created by dj.yue on 2017/4/20.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "RCRequestInfo.h"


// MARK: remote control defined structs
#pragma pack(push)
#pragma pack(1)

static const Byte CRC8T[256] = {0, 7, 14, 9, 28, 27, 18, 21, 56, 63, 54, 49, 36, 35, 42, 45, 112, 119, 126, 121, 108, 107,
    98, 101, 72, 79, 70, 65, 84, 83, 90, 93, 224, 231, 238, 233, 252, 251, 242, 245, 216, 223, 214, 209, 196,
    195, 202, 205, 144, 151, 158, 153, 140, 139, 130, 133, 168, 175, 166, 161, 180, 179, 186, 189, 199, 192,
    201, 206, 219, 220, 213, 210, 255, 248, 241, 246, 227, 228, 237, 234, 183, 176, 185, 190, 171, 172, 165,
    162, 143, 136, 129, 134, 147, 148, 157, 154, 39, 32, 41, 46, 59, 60, 53, 50, 31, 24, 17, 22, 3, 4, 13, 10,
    87, 80, 89, 94, 75, 76, 69, 66, 111, 104, 97, 102, 115, 116, 125, 122, 137, 142, 135, 128, 149, 146, 155,
    156, 177, 182, 191, 184, 173, 170, 163, 164, 249, 254, 247, 240, 229, 226, 235, 236, 193, 198, 207, 200,
    221, 218, 211, 212, 105, 110, 103, 96, 117, 114, 123, 124, 81, 86, 95, 88, 77, 74, 67, 68, 25, 30, 23, 16,
    5, 2, 11, 12, 33, 38, 47, 40, 61, 58, 51, 52, 78, 73, 64, 71, 82, 85, 92, 91, 118, 113, 120, 127, 106, 109,
    100, 99, 62, 57, 48, 55, 34, 37, 44, 43, 6, 1, 8, 15, 26, 29, 20, 19, 174, 169, 160, 167, 178, 181, 188,
    187, 150, 145, 152, 159, 138, 141, 132, 131, 222, 217, 208, 215, 194, 197, 204, 203, 230, 225, 232, 239,
    250, 253, 244, 243};

typedef struct CMD_CALIBRATE_Request {
    uint8_t command;// = CMD_CALIBRATE;
    uint8_t value;// 0:停止校准 1:开始校准
}CMD_CALIBRATE_Request;



#pragma pack(pop)


@interface RCRequestInfo ()
@property (nonatomic, assign) RC_CMD_ID command;
@end

@implementation RCRequestInfo

- (NSData *)buildPayload {
    return nil;
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

@implementation RCRequestCalibrateInfo

- (id)init {
    self = [super init];
    if (self) {
        self.command = CMD_CALIBRATE;
    }
    return self;
}

- (NSData *)buildPayload {
    struct CMD_CALIBRATE_Request calibrate;
    calibrate.command = self.command;
    calibrate.value = self.action;
    NSData *payloadData = [NSData dataWithBytes:&calibrate length:sizeof(calibrate)];
    payloadData = [self packerWithData:payloadData];
    return payloadData;
}

unsigned char calc_crc8(unsigned char *buf, int len)
{
    unsigned char crc8 = 0;
    int i = 0;
    for (i=0; i<len; i++) {
        crc8 = CRC8T[crc8^buf[i]];
    }
    return crc8;
}
- (NSData *)packerWithData:(NSData *)data {
    uint8_t* packerData = malloc(5 + data.length);
    uint16_t length = data.length + 1;
    //    length = htons(length);
    memset(packerData, 0x40, 1);///header
    memset(packerData + 1, 0x18, 1);///route
    memcpy(packerData + 2, &length, 2);///length
    
    memcpy(packerData + 4, data.bytes, data.length); ///payload
    
    uint8_t crc8 = calc_crc8(packerData, 4 + (int)data.length);
    memcpy(packerData + 4 + data.length, &crc8, 1);///crc
    
    NSData *res = [NSData dataWithBytes:packerData length:5 + data.length];
    free(packerData);
    return res;
}






@end
