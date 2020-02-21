//
//  YuneecMFiCameraStreamDataTransfer.m
//  YuneecMFiDataTransfer
//
//  Created by tbago on 17/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import "YuneecMFiCameraStreamDataTransfer.h"
#import "YuneecMFiInnerDataTransfer.h"

@interface YuneecMFiCameraStreamDataTransfer() <YuneecMFiInnerCameraStreamDataDelegate>

@property (copy, nonatomic) NSData              *storeExtraData;

@end

@implementation YuneecMFiCameraStreamDataTransfer

#pragma mark - public method

- (BOOL)openCameraSteamDataTransfer {
    [YuneecMFiInnerDataTransfer sharedInstance].cameraStreamDelegate = self;
    return YES;
}

- (void)closeCameraStreamDataTransfer {
    [YuneecMFiInnerDataTransfer sharedInstance].cameraStreamDelegate = nil;
}

#pragma mark - YuneecMFiInnerCameraStreamDataDelegate

- (void)MFiInnerDataTransfer:(YuneecMFiInnerDataTransfer *) MFiDataTransfer
          didReceiveH264Data:(NSData *) h264Data
          decompassTimeStamp:(int64_t) decompassTimeStamp
            presentTimeStamp:(int64_t) presentTimeStamp
{
    if (self.cameraStreamDelegate != nil) {
         NSData *frameData = [h264Data copy];
        [self paraseH264DataToGetCameraExtraData:(uint8_t *)frameData.bytes
                                  h264ByteLength:(uint32_t)frameData.length];
        [self.cameraStreamDelegate MFiCameraStreamDataTransfer:self
                                            didReceiveH264Data:frameData
                                                      keyFrame:NO
                                            decompassTimeStamp:decompassTimeStamp
                                              presentTimeStamp:presentTimeStamp
                                                     extraData:self.storeExtraData];
    }
}

#pragma mark - parser H.264 extra data

- (void)paraseH264DataToGetCameraExtraData:(uint8_t*) h264Byte
                            h264ByteLength:(uint32_t) h264ByteLength
{
    if (h264ByteLength < 4) {
        return;
    }
    uint64_t cursor = 0;
    uint64_t nal_unit_length = 0;
    uint8_t  nal_unit_type = 0;

    do {
        nal_unit_length = [self GetOneNalUnit:&nal_unit_type
                                      pBuffer:h264Byte+cursor
                                   bufferSize:h264ByteLength-cursor];
        if (nal_unit_type == 12) {
            uint8_t *nalDataIndex = h264Byte+cursor;

            const uint32_t nalHeaderDataLength = 5;    ///< remove h264 nalu header (0x00 0x00 0x00 0x01 0x12)
            uint32_t nalDataLength = (uint32_t)(nal_unit_length - nalHeaderDataLength);

            uint8_t *tempBuffer = (uint8_t *)malloc(nalDataLength);
            memcpy(tempBuffer, nalDataIndex+nalHeaderDataLength, nalDataLength);
            uint32_t realDataLength = [self removeEmulationPrevention:tempBuffer
                                                                 size:nalDataLength];

            self.storeExtraData = [[NSData alloc] initWithBytes:tempBuffer length:realDataLength];

            free(tempBuffer);
            break;
        }
        cursor += nal_unit_length;
    } while (cursor < h264ByteLength);
}

- (uint64_t) GetOneNalUnit:(uint8_t *) pNaluType
                   pBuffer:(uint8_t *) pBuffer
                bufferSize:(uint64_t) bufferSize
{
    uint32_t pos = 0;
    uint32_t tempValue = 0;

    for (uint32_t code = 0xffffffff; pos < 4; pos++) {
        tempValue = pBuffer[pos];
        code = (code<<8)|tempValue;
    }

    *pNaluType = pBuffer[pos++] & 0x1F;
    for (uint32_t code=0xffffffff; pos < bufferSize; pos++) {
        tempValue = pBuffer[pos];
        if ((code=(code<<8)|tempValue) == 0x00000001) {
            break; //next start code is found
        }
    }
    if (pos == bufferSize) {
        // next start code is not found, this must be the last nalu
        return bufferSize;
    } else {
        return pos-4+1;
    }
}

- (int32_t)removeEmulationPrevention:(uint8_t*) pdata
                                size:(int32_t) size
{
    unsigned char *readPtr, *writePtr;
    //    unsigned char byte;
    unsigned int i,tmp;
    unsigned int zeroCount;
    tmp = size;
    readPtr = writePtr = pdata;
    zeroCount = 0;
    for (i = tmp; i--;)
    {
        if ((zeroCount == 2) && (*readPtr == 0x03))
        {
            /* emulation prevention byte shall be followed by one of the
             * following bytes: 0x00, 0x01, 0x02, 0x03. This implies that
             * emulation prevention 0x03 byte shall not be the last byte
             * of the stream. */
            // if ( (i == 0) || (*(readPtr+1) > 0x03) ){
            //LOGV("last byte shall not be 0x03\n");
            // return 0xFFFF;
            //}
            /* do not write emulation prevention byte */
            readPtr++;
            zeroCount = 0;
        }
        else
        {
            /* NAL unit shall not contain byte sequences 0x000000,
             * 0x000001 or 0x000002 */
            if ( (zeroCount == 2) && (*readPtr <= 0x02) ){
                //LOGV("nal unit shall not contain byte 0x000000,0x000001,0x000002\n");
                return 0xFFFF;

            }

            if (*readPtr == 0) {
                zeroCount++;
            }
            else {
                zeroCount = 0;
            }
            *writePtr++ = *readPtr++;
        }
    }

    /* (readPtr - writePtr) indicates number of "removed" emulation
     * prevention bytes -> subtract from stream buffer size */
    return (size - (unsigned char)(readPtr - writePtr));
}

@end
