//
//  YuneecVTDecoder.m
//  YuneecDecoder
//
//  Created by YC-JG-YXKF-PC35 on 2017/2/13.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecVTDecoder.h"
#import <VideoToolbox/VideoToolbox.h>
#import "YuneecRawVideoFrameInner.h"
#import "YuneecSampleVideoFrame.h"
#import <AVFoundation/AVFoundation.h>

@interface YuneecVTDecoder ()

@property (nonatomic, assign) CMVideoFormatDescriptionRef formatDesc;
@property (nonatomic, assign) CMVideoFormatDescriptionRef lastFormatDesc;
@property (nonatomic, assign) VTDecompressionSessionRef decompressionSession;
@property (nonatomic, assign) int spsSize;
@property (nonatomic, assign) int ppsSize;
@property (nonatomic, assign) CMVideoDimensions dimensions;
@property (nonatomic, assign) BOOL bNeedDecodeData;
@property (nonatomic, assign) CVImageBufferRef dispImageBuffer;

@end

@implementation YuneecVTDecoder

const OSType defaultOutPixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;

#pragma mark - Inherit from super class

- (void)decodeVideoFrame:(NSData *)frameData decompassTimeStamp:(int64_t)decompassTimeStamp presentTimeStamp:(int64_t)presentTimeStamp {
    @autoreleasepool {
        [self decodeFrame:(uint8_t *)frameData.bytes withSize:(uint32_t)frameData.length];
    }
}

- (BOOL)openCodec {
    _bNeedDecodeData = NO;
    return YES;
}

- (void)closeCodec {
    [self releaseFormatDesc];
    [self releaseDcompressionSession];
    if(_lastFormatDesc != nil) {
        CFRelease(_lastFormatDesc);
        _lastFormatDesc = nil;
    }
}

#pragma mark - VideoToolBox Decode
- (void)decodeFrame:(uint8_t *)frame withSize:(uint32_t)frameSize {
    OSStatus status;
    uint8_t *data = NULL;///<单个nalu
    uint32_t nal_unit_length = 0;///<单个nalu长度
    uint8_t *dataPlus = NULL;///<所有nalu的组合
    uint32_t dataLengthPlus = 0;///<所有nalu数据长度
    uint8_t *pps = NULL;
    uint8_t *sps = NULL;
    uint32_t cursor = 0;
    uint8_t  nalu_type = 0;
    long blockLength = 0;
    CMSampleBufferRef sampleBuffer = NULL;
    CMBlockBufferRef blockBuffer = NULL;
    
    do {
        nal_unit_length = [self GetOneNalUnit:&nalu_type
                                      pBuffer:frame+cursor
                                   bufferSize:frameSize-cursor];
        uint8_t *nalDataIndex = frame+cursor;
        if (nalu_type == 7) {
            [self relaseData:sps];
            sps = malloc(nal_unit_length - 4);
            _spsSize = nal_unit_length;
            memcpy(sps, nalDataIndex + 4, nal_unit_length - 4);
        }
        if(nalu_type == 8) {
            [self relaseData:pps];
            pps = malloc(nal_unit_length - 4);
            _ppsSize = nal_unit_length;
            memcpy(pps, nalDataIndex + 4, nal_unit_length - 4);
            uint8_t*  parameterSetPointers[2] = {sps, pps};
            size_t parameterSetSizes[2] = {_spsSize-4, _ppsSize-4};
            [self releaseFormatDesc];
            status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2,
                                                                         (const uint8_t *const*)parameterSetPointers,
                                                                         parameterSetSizes, 4,
                                                                         &_formatDesc);
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(_formatDesc);
            if ((self.dimensions.width == 0) && (self.dimensions.height == 0)) {
                /* Init the self.dimensions to avoid one time blinking after playback */
                [self.decoderDelegate decoder:self didChangeVideoWidth:dimensions.width videoHeight:dimensions.height];
                self.dimensions = dimensions;
            }
            if(status == noErr)
            {
                if(_lastFormatDesc == nil) {
                    // create last valid format description for reference
                    OSStatus statusRef = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2,
                                                                             (const uint8_t *const*)parameterSetPointers,
                                                                             parameterSetSizes, 4,
                                                                             &_lastFormatDesc);
                    if(statusRef == noErr) {
                        CFRetain(_lastFormatDesc);
                    }
                    else {
                        _lastFormatDesc = nil;
                    }

                }
                if (_decompressionSession == NULL) {
                    [self createDecompSession];
                }
                else if (self.dimensions.width != dimensions.width || self.dimensions.height !=  dimensions.height) {
                    [self.decoderDelegate decoder:self didChangeVideoWidth:dimensions.width videoHeight:dimensions.height];
                    self.dimensions = dimensions;
                    [self releaseDcompressionSession];
                    [self createDecompSession];
                }
            }
            
        }
        if(nalu_type == 5 || nalu_type == 1) {
            data = malloc(nal_unit_length);
            memcpy(data, nalDataIndex, nal_unit_length);
            uint32_t dataLength32 = htonl (nal_unit_length - 4);
            memcpy (data, &dataLength32, sizeof (uint32_t));
            
            if (dataPlus == NULL) {//复制到dataPlus
                dataPlus = malloc(nal_unit_length);
                memcpy(dataPlus, data, nal_unit_length);
            }
            else {//加到dataPlus中
                dataPlus = realloc(dataPlus, dataLengthPlus + nal_unit_length);
                memcpy(dataPlus + dataLengthPlus, data, nal_unit_length);
            }
            dataLengthPlus += nal_unit_length;
            [self relaseData:data];
        }
        
        cursor += nal_unit_length;
    } while (cursor < frameSize);
    
    [self relaseData:sps];
    [self relaseData:pps];
    
    if (_formatDesc != NULL && _decompressionSession != NULL && dataLengthPlus != 0) {
        if((_lastFormatDesc != nil) && (!CMFormatDescriptionEqual(_formatDesc, _lastFormatDesc))) {
            CFRelease(_lastFormatDesc);
            _lastFormatDesc = nil;
            // formatDesc had been updated
            if (!VTDecompressionSessionCanAcceptFormatDescription(_decompressionSession, _formatDesc)) {
                NSLog(@"NOT supportted format, restart session");
                [self releaseDcompressionSession];
                [self createDecompSession];
            }
        }

        status = CMBlockBufferCreateWithMemoryBlock(NULL, dataPlus,
                                                    dataLengthPlus,
                                                    kCFAllocatorNull, NULL,
                                                    0,
                                                    dataLengthPlus,
                                                    0, &blockBuffer);
        if(status == noErr)
        {
            const size_t sampleSize = blockLength;
            status = CMSampleBufferCreate(kCFAllocatorDefault,
                                          blockBuffer, true, NULL, NULL,
                                          _formatDesc, 1, 0, NULL, 1,
                                          &sampleSize, &sampleBuffer);
        }
        
        if(status == noErr) {
            [self render:sampleBuffer];
        }
        else if(sampleBuffer != NULL) {
            CFRelease(sampleBuffer);
        }
        
        if (NULL != blockBuffer) {
            CFRelease(blockBuffer);
            blockBuffer = NULL;
        }
    }
    [self relaseData:dataPlus];
}

-(void) createDecompSession
{
    _decompressionSession = NULL;
//    VTDecompressionOutputCallbackRecord callBackRecord;
//    callBackRecord.decompressionOutputCallback = decompressionSessionDecodeFrameCallback;
    
//    callBackRecord.decompressionOutputRefCon = (__bridge void *)self;
    
    NSDictionary *destinationImageBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                                      [NSNumber numberWithBool:YES],
                                                      (id)kCVPixelBufferOpenGLESCompatibilityKey,
                                                      [NSNumber numberWithInt:defaultOutPixelFormat],
                                                      (id)kCVPixelBufferPixelFormatTypeKey,
                                                      nil];

    NSDictionary *videoDecoderSpecification = @{AVVideoCodecKey: AVVideoCodecH264};
    OSStatus status =  VTDecompressionSessionCreate(kCFAllocatorDefault, _formatDesc,
                                                    (__bridge CFDictionaryRef)videoDecoderSpecification,
                                                    (__bridge CFDictionaryRef)(destinationImageBufferAttributes),
                                                    NULL, &_decompressionSession);

    #pragma unused(status)
}

//static void decompressionSessionDecodeFrameCallback(void *decompressionOutputRefCon,
//                                                    void *sourceFrameRefCon,
//                                                    OSStatus status,
//                                                    VTDecodeInfoFlags infoFlags,
//                                                    CVImageBufferRef imageBuffer,
//                                                    CMTime presentationTimeStamp,
//                                                    CMTime presentationDuration)
//{
//    
//    if (status != noErr || !imageBuffer) {
//        NSLog(@"Error decompresssing frame at time: %.3f error: %d infoFlags: %u", (float)presentationTimeStamp.value/presentationTimeStamp.timescale, (int)status, (unsigned int)infoFlags);
//        return;
//    }
//    __weak YuneecVTDecoder *weakSelf = (__bridge YuneecVTDecoder *)decompressionOutputRefCon;
//    @autoreleasepool {
//        YuneecRawVideoFrame *videoFrame = [weakSelf convertCVImageBufferRefToRawVideoFrame:imageBuffer];
//        [weakSelf.decoderDelegate decoder:weakSelf didDecoderVideoFrame:videoFrame];
//    }
//}

- (YuneecRawVideoFrame *)convertCVImageBufferRefToRawVideoFrame:(CVImageBufferRef) imageBuffer
{
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    CGSize size = CVImageBufferGetDisplaySize(imageBuffer);
    YuneecRawVideoFrameInner *rawVideoFrame = [[YuneecRawVideoFrameInner alloc] initWithWidth:size.width
                                                                                       height:size.height
                                                                                    timeStamp:0
                                                                                     duration:0];
    uint8_t *yBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    [rawVideoFrame pushFrameData:size.width frameByte:yBuffer];
    
    uint8_t *uBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
    [rawVideoFrame pushFrameData:size.width/2 frameByte:uBuffer];
    
    uint8_t *vBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 2);
    [rawVideoFrame pushFrameData:size.width/2 frameByte:vBuffer];
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    return rawVideoFrame;
}

- (YuneecSampleVideoFrame *)getSampleFrameFromPixelBuffer:(CVPixelBufferRef) pixelBuffer
{
    if (!pixelBuffer){
        return nil;
    }

    // set invalid time
    CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
    // get video info
    CMVideoFormatDescriptionRef videoInfo = NULL;
    OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    NSParameterAssert(result == 0 && videoInfo != NULL);

    CMSampleBufferRef sampleBuffer = NULL;
    result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault,pixelBuffer, true, NULL, NULL, videoInfo, &timing, &sampleBuffer);
    if(result != 0 || sampleBuffer == NULL) {
        if(videoInfo != nil) {
            CFRelease(videoInfo);
        }
        return nil;
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    CGSize size = CVImageBufferGetDisplaySize(pixelBuffer);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    YuneecSampleVideoFrame *sampleVideoFrame = [[YuneecSampleVideoFrame alloc] initWithWidth:size.width
                                                                                    height:size.height
                                                                              isCompressed:NO
                                                                                    Buffer:sampleBuffer];
    CFRelease(pixelBuffer);
    CFRelease(videoInfo);
    return sampleVideoFrame;
}

- (void) render:(CMSampleBufferRef)inSampleBuffer
{
    VTDecodeFrameFlags flags = kVTDecodeFrame_EnableAsynchronousDecompression;
    VTDecodeInfoFlags flagOut;
    
    __weak typeof(self) weakSelf = self;
    if(!_bNeedDecodeData) {
        // for no video processing case, decode and display on view controller directly
        @autoreleasepool {
            YuneecSampleVideoFrame *inSampleFrame = [[YuneecSampleVideoFrame alloc] initWithWidth:self.dimensions.width
                                                              height:self.dimensions.height
                                                        isCompressed:YES
                                                            Buffer:inSampleBuffer];
            if(inSampleFrame != nil) {
                inSampleFrame.bHasVideoProc = weakSelf.bNeedDecodeData;
                [weakSelf.decoderDelegate decoder:weakSelf didDisplaySampleFrame:inSampleFrame];
                weakSelf.bNeedDecodeData = inSampleFrame.bHasVideoProc;
                CFRelease(inSampleBuffer);
                inSampleFrame = nil;
            }
         }
        return;
    }

    OSStatus status = VTDecompressionSessionDecodeFrameWithOutputHandler(_decompressionSession, inSampleBuffer, flags, &flagOut, ^(OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef  _Nullable imageBuffer, CMTime presentationTimeStamp, CMTime presentationDuration) {
        if (status != noErr || !imageBuffer) {
            NSLog(@"Error decompresssing frame at time: %.3f error: %d infoFlags: %u", (float)presentationTimeStamp.value/presentationTimeStamp.timescale, (int)status, (unsigned int)infoFlags);
            return;
        }

        if(_dispImageBuffer != NULL) {
            //CVPixelBufferRelease(_dispImageBuffer);
            _dispImageBuffer = NULL;
        }
        _dispImageBuffer = CVPixelBufferRetain(imageBuffer);
        @autoreleasepool {
            /* OpenGL display */
            //YuneecRawVideoFrame *videoFrame = [weakSelf convertCVImageBufferRefToRawVideoFrame:imageBuffer];
            //[weakSelf.decoderDelegate decoder:weakSelf didDecoderVideoFrame:videoFrame];
            //CFRelease(imageBuffer);

            /* Hardware display */
            YuneecSampleVideoFrame *sampleFrame = [weakSelf getSampleFrameFromPixelBuffer:imageBuffer];
            if(sampleFrame != nil) {
                sampleFrame.bHasVideoProc = weakSelf.bNeedDecodeData;
                [weakSelf.decoderDelegate decoder:weakSelf didDisplaySampleFrame:sampleFrame];
                weakSelf.bNeedDecodeData = sampleFrame.bHasVideoProc;
                CFRelease(sampleFrame.sampleBuffer);
                sampleFrame = nil;
            }
        }
    });

    if (status != noErr) {
        NSLog(@"decompress error:%d",(int)status);
        if (status == kVTInvalidSessionErr) {
            [self releaseDcompressionSession];
        }
    }
    else {
        status = VTDecompressionSessionWaitForAsynchronousFrames(_decompressionSession);
    }
    CFRelease(inSampleBuffer);
}

#pragma mark - Private methods

- (void)releaseDcompressionSession {
    @synchronized (self) {
        if(_decompressionSession) {
            VTDecompressionSessionWaitForAsynchronousFrames(_decompressionSession);
            VTDecompressionSessionInvalidate(_decompressionSession);
            CFRelease(_decompressionSession);
            _decompressionSession = NULL;
        }
    }
}

- (void)releaseFormatDesc {
    if (_formatDesc) {
        CFRelease(_formatDesc);
        _formatDesc = NULL;
    }
}

-(void)relaseData:(uint8_t*) tmpData{
    if (NULL != tmpData)
    {
        free (tmpData);
        tmpData = NULL;
    }
}


- (uint32_t) GetOneNalUnit:(uint8_t *) pNaluType
                   pBuffer:(uint8_t *) pBuffer
                bufferSize:(uint32_t) bufferSize
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

@end
