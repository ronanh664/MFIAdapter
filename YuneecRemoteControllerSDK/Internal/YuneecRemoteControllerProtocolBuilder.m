//
//  YuneecRemoteControllerProtocolBuilder.m
//  YuneecRemoteControllerSDK
//
//  Created by tbago on 27/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import "YuneecRemoteControllerProtocolBuilder.h"
#import "YuneecRemoteControllerUtility.h"

#pragma pack(push)
#pragma pack(1)
typedef struct {
    uint8_t     header;
    uint8_t     route;
    uint16_t    length;
} RemoteControllerHeader;
#pragma pack(pop)

static const uint8_t kRemoteControllerHeader        = 0x40;
static const uint8_t kRemoteControllerSendRoute     = 0x31;

static const uint8_t kRemoteControllerReceiveRoute      = 0x13;
static const uint8_t kRemoteControllerBroadcastRoute    = 0x15;

@implementation YuneecRemoteControllerProtocolBuilder

+ (NSData *)buildProtocolDataWithContentData:(NSData *) contentData {
    uint32_t headerLength = sizeof(RemoteControllerHeader);
    uint32_t protocolBufferSize = (uint32_t)(headerLength + contentData.length + 1);
    uint8_t *protocolBuffer = (uint8_t *)malloc(protocolBufferSize);

    RemoteControllerHeader header;
    header.header   = kRemoteControllerHeader;
    header.route    = kRemoteControllerSendRoute;
    header.length   = contentData.length + 1;
    memcpy(protocolBuffer, &header, headerLength);
    memcpy(protocolBuffer+headerLength, contentData.bytes, contentData.length);

    uint8_t crc8 = calcCrc8(protocolBuffer, protocolBufferSize - 1);
    memcpy(protocolBuffer+protocolBufferSize-1, &crc8, 1);

    NSData *protocolData = [[NSData alloc] initWithBytes:protocolBuffer length:protocolBufferSize];

    free(protocolBuffer);

    return protocolData;
}

+ (NSData * _Nullable)parserContentDataFromProtocolData:(NSData *) protocolData {
    uint32_t protocolDataLength = (uint32_t)protocolData.length;
    if (protocolDataLength < 6) {
        return nil;
    }
    uint8_t *protocolDataByte = (uint8_t *)protocolData.bytes;
    RemoteControllerHeader header;
    uint32_t headerLength = sizeof(RemoteControllerHeader);
    memcpy(&header, protocolDataByte, headerLength);

    if (header.header != kRemoteControllerHeader) {
        return nil;
    }
    BOOL validRoute = NO;
    if (header.route == kRemoteControllerReceiveRoute || header.route == kRemoteControllerBroadcastRoute) {
        validRoute = YES;
    }
    if (!validRoute) {
        return nil;
    }

    if (header.length != protocolDataLength - headerLength) {
        return nil;
    }
    uint8_t crc8 = calcCrc8(protocolDataByte, protocolDataLength - 1);
    if (crc8 != *(protocolDataByte+protocolDataLength-1)) {
        return nil;
    }
    NSData *contentData = [NSData dataWithBytes:protocolDataByte+headerLength length:header.length-1];
    return contentData;
}

@end
