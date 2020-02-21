//
//  YuneecMFiControllerProtocolBuilder.m
//  YuneecMFiDataTransfer
//
//  Created by tbago on 23/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import "YuneecMFiControllerProtocolBuilder.h"

typedef NS_ENUM(NSUInteger, ControllerProtocolIDType) {
    ControllerProtocolIDTypeVideoStream     = 554,
    ControllerProtocolIDTypeController      = 1108,
    ControllerProtocolIDTypeCamera          = 9528,
    ControllerProtocolIDTypePhotoDownload   = 9800,
    ControllerProtocolIDTypeOTA             = 9801,
    ControllerProtocolIDTypeMavlink2        = 10011,
    ControllerProtocolIDTypeReserved        = 10012,
};

#pragma pack(push)
#pragma pack(1)
typedef struct {
    uint16_t    header;
    uint16_t    length;
    uint16_t    protocolID;
    uint8_t     flag;
} ControllerProtocolHeader;

typedef struct {
    uint32_t   pts;
    uint32_t   totalLength;
    uint32_t   offset;
} ControllerVideoHeader;

#pragma pack(pop)

@implementation YuneecMFiControllerProtocolBuilder

#pragma mark - public method

+ (NSData *)buildProtocolDataWithProtocolType:(YuneecMFiProtocolType) protocolType
                                  contentData:(NSData *) contentData
{
    ControllerProtocolHeader    header;
    uint32_t headerLength = sizeof(ControllerProtocolHeader);
    header.header = 0x6666;
    header.length = (uint16_t)contentData.length;
    header.protocolID = [self convertMFiProtocolTypeToControllerProtocolID:protocolType];
    header.flag = 0;

    uint8_t crc8 = [self calcCrc8:(uint8_t *)&header bufferLength:headerLength];

    uint32_t protocolDataLength = headerLength + 1 + (uint32_t)contentData.length;
    uint8_t *protocolDataBuffer = (uint8_t *)malloc(protocolDataLength);
    memcpy(protocolDataBuffer, &header, headerLength);
    memcpy(protocolDataBuffer+headerLength, &crc8, 1);
    memcpy(protocolDataBuffer+headerLength+1, contentData.bytes, contentData.length);

    NSData *protocolData = [[NSData alloc] initWithBytes:protocolDataBuffer length:protocolDataLength];
    free(protocolDataBuffer);
    return protocolData;
}

static NSMutableData *videoContentData = nil;
+ (NSData * _Nullable)parserContentDataFromProtocolData:(NSData *) protocolData
                                             parsedInfo:(MfiParsedInfo *) pInfo {
    const uint32_t protocolDataLength = (uint32_t)protocolData.length;
    ControllerProtocolHeader    header;
    uint32_t headerLength = sizeof(ControllerProtocolHeader);
    NSData *contentData = nil;

    if(pInfo == nil) {
        NSLog(@"error. pInfo is invalid");
        return nil;
    }
    memset(pInfo, 0, sizeof(MfiParsedInfo));
    if (protocolDataLength < headerLength + 1) {
        return nil;
    }

    uint8_t *protocolDataByte = (uint8_t *)protocolData.bytes;
    memcpy(&header, protocolDataByte, headerLength);
    uint32_t invalidDataLength = 0;
    if (header.header != 0x6666) {
        BOOL bFoundSync = NO;
        // search for next sync, searching each byte
        for(int i=0; i<protocolDataLength-1; i++) {
            if((protocolDataByte[i] == 0x66) && (protocolDataByte[i+1] == 0x66)) {
                invalidDataLength = i;
                if((protocolDataLength - invalidDataLength) > (headerLength + 1)) {
                    bFoundSync = YES;
                    protocolDataByte += invalidDataLength;
                    memcpy(&header, protocolDataByte, headerLength);
                    NSLog(@"Skip %zd bytes invalid data", invalidDataLength);
                    break;
                }
                else {
                    NSLog(@"Found sync, but data is lack");
                    return nil;
                }
            }
        }
        if(!bFoundSync) {
            NSLog(@"Did not found header sync");
            return nil;
        }
    }

    pInfo->protocolType = [self convertProtocolIDToMFiProtocolType:header.protocolID];
    uint8_t calcCrc8 = [self calcCrc8:(uint8_t *)&header bufferLength:headerLength];
    uint8_t protocolCrc8 = *(protocolDataByte+headerLength);
    if (calcCrc8 != protocolCrc8) {     ///< crc check failed
        NSLog(@"CRC error, calcCrc=%zd, protocolCrc=%zd", calcCrc8, protocolCrc8);
        return nil;
    }

    pInfo->headerLength = (sizeof(ControllerProtocolHeader) + 1);
    // Check whether video has got a complete NALU
    if(YuneecMFiProtocolTypeVideoStream == pInfo->protocolType) {
        if (*(uint32_t *)(protocolDataByte+headerLength+1) == 0x01000000) {
            contentData = [[NSData alloc] initWithBytes:protocolDataByte+headerLength+1 length:header.length];
            pInfo->pts = -1; // PTS is invalid
            return contentData;
        }
        // Video stream has a special header(ControllerVideoHeader), header should be parsed and removed
        ControllerVideoHeader videoHeader;
        memcpy(&videoHeader, protocolDataByte+headerLength+1, sizeof(ControllerVideoHeader));
        //NSLog(@"videoHeader.pts=%u, videoHeader.total=%u, videoHeader.offset=%u", videoHeader.pts, videoHeader.totalLength, videoHeader.offset);
        if(videoHeader.offset == 0) {
            videoContentData = nil;
        }
        if((videoHeader.totalLength <= videoHeader.offset) ||
           (videoHeader.totalLength < (header.length - sizeof(ControllerVideoHeader))) ||
           (videoHeader.offset > 0xFFFFF) ||
           (videoHeader.totalLength > 0xFFFFF)) {
            // header is invalid, drop invalid content
            videoContentData = nil;
            return nil;
        }
        uint32_t dataOffset = headerLength+1+sizeof(ControllerVideoHeader);
        uint32_t dataLength = header.length - sizeof(ControllerVideoHeader);
        if(videoContentData == nil) {
            videoContentData = [[NSMutableData alloc] initWithBytes:protocolDataByte+dataOffset length:dataLength];
        }
        else {
            [videoContentData appendBytes:protocolDataByte+dataOffset length:dataLength];
        }

        pInfo->headerLength = (sizeof(ControllerProtocolHeader) + 1 + sizeof(ControllerVideoHeader));
        if(videoHeader.offset + dataLength == videoHeader.totalLength) {
            // Get a complete NALU
            if(videoContentData.length != videoHeader.totalLength) {
                NSLog(@"ERROR, NALU length=%lu, expected=%u", videoContentData.length, videoHeader.totalLength);
            }
            pInfo->pts = videoHeader.pts;
            return videoContentData;
        }
        else {
            //Waiting for more data
            pInfo->bDataLacking = YES;
            NSData *parsedData = [protocolData subdataWithRange:NSMakeRange(dataOffset, dataLength)];
            return parsedData;
        }
    }
    else {
         contentData = [[NSData alloc] initWithBytes:protocolDataByte+headerLength+1 length:header.length];
        return contentData;
    }
}

#pragma mark - private method

+ (ControllerProtocolIDType)convertMFiProtocolTypeToControllerProtocolID:(YuneecMFiProtocolType) protocolType {
    switch (protocolType) {
        case YuneecMFiProtocolTypeVideoStream:
            return ControllerProtocolIDTypeVideoStream;
            break;
        case YuneecMFiProtocolTypeController:
            return ControllerProtocolIDTypeController;
            break;
        case YuneecMFiProtocolTypeCamera:
            return ControllerProtocolIDTypeCamera;
            break;
        case YuneecMFiProtocolTypePhotoDownload:
            return ControllerProtocolIDTypePhotoDownload;
            break;
        case YuneecMFiProtocolTypeOTA:
            return ControllerProtocolIDTypeOTA;
            break;
        case YuneecMFiProtocolTypeMavlink2Protocol:
            return ControllerProtocolIDTypeMavlink2;
            break;
        case YuneecMFiProtocolTypeReserved:
            return ControllerProtocolIDTypeReserved;
            break;
    }
}

+ (YuneecMFiProtocolType)convertProtocolIDToMFiProtocolType:(ControllerProtocolIDType) protocolIDType {
    switch (protocolIDType) {
        case ControllerProtocolIDTypeVideoStream:
            return YuneecMFiProtocolTypeVideoStream;
            break;
        case ControllerProtocolIDTypeController:
            return YuneecMFiProtocolTypeController;
            break;
        case ControllerProtocolIDTypeCamera:
            return YuneecMFiProtocolTypeCamera;
            break;
        case ControllerProtocolIDTypePhotoDownload:
            return YuneecMFiProtocolTypePhotoDownload;
            break;
        case ControllerProtocolIDTypeOTA:
            return YuneecMFiProtocolTypeOTA;
            break;
        case ControllerProtocolIDTypeMavlink2:
            return YuneecMFiProtocolTypeMavlink2Protocol;
            break;
        case ControllerProtocolIDTypeReserved:
            return YuneecMFiProtocolTypeReserved;
            break;
    }
}

static const uint8_t crc8_table[256] =  {0, 7, 14, 9, 28, 27, 18, 21, 56, 63, 54, 49, 36, 35, 42, 45, 112, 119, 126, 121, 108, 107,
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

+ (uint8_t)calcCrc8:(uint8_t *) buffer bufferLength:(uint32_t) bufferLength
{
    uint8_t crc8 = 0;
    for (uint32_t i=0; i<bufferLength; i++) {
        crc8 = crc8_table[crc8^buffer[i]];
    }
    return crc8;
}

@end
