//
//  YuneecFFMpegDecoder.m
//  YuneecDecoder
//
//  Created by tbago on 17/1/26.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecFFMpegDecoder.h"
#import <FFMpegDecoder/FFMpegDecoder.h>
#import <FFMpegLowDelayDecoder/FFMpegLowDelayDecoder.h>

#import "YuneecH264FrameInner.h"
#import "YuneecRawVideoFrameInner.h"

#ifdef DEBUG
#define DNSLog(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define DNSLog(format, ...)
#endif

@interface YuneecFFMpegDecoder()

@property (strong, nonatomic) FFMpegDecoderEnumerator           *ffDecoderEnumerator;
@property (strong, nonatomic) FFMpegDecoder                     *ffDecoder;

@property (strong, nonatomic) FFMpegLowDelayDecoderEnumerator   *ffLowDelayDecoderEnumerator;
@property (strong, nonatomic) FFMpegLowDelayDecoder             *ffLowDelayDecoder;

@property (nonatomic) uint32_t                                  videoWidth;
@property (nonatomic) uint32_t                                  videoHeight;

@end

@implementation YuneecFFMpegDecoder

- (BOOL)openCodec {
    self.videoWidth     = 0;
    self.videoHeight    = 0;

    BOOL openDecoderRet = NO;
    if (!self.enableLowDelay) {
        self.ffDecoder = [self.ffDecoderEnumerator createFFMpegDecoderByCodecId:R_CODEC_ID_H264];
        if (self.ffDecoder == nil) {
            DNSLog(@"Cannot find H264 decoder.");
            return NO;
        }

        AVCodecParam *codecParam = [[AVCodecParam alloc] init];
        codecParam.numThreads           = 1;
        openDecoderRet = [self.ffDecoder openCodec:codecParam];
        if (!openDecoderRet) {
            DNSLog(@"Open ffmpeg decoder failed.");
        }
    }
    else {
        self.ffLowDelayDecoder = [self.ffLowDelayDecoderEnumerator createFFMpegDecoderByCodecId:R_CODEC_ID_H264];
        if (self.ffLowDelayDecoder == nil) {
            DNSLog(@"Cannot find H264 low delay decoder.");
            return NO;
        }
        AVLowDelayCodecParam *codecParam = [[AVLowDelayCodecParam alloc] init];
        codecParam.numThreads           = 1;
        openDecoderRet = [self.ffLowDelayDecoder openCodec:codecParam];
        if (!openDecoderRet) {
            DNSLog(@"Open ffmpeg low delay decoder failed.");
        }
    }

    return openDecoderRet;
}

- (void)closeCodec {
    ///< close ffmpeg decoder
    if (self.ffDecoder != nil) {
        NSAssert(self.ffLowDelayDecoder == nil, @"FFLowDelayDecoder must be nil");
        [self.ffDecoder closeCodec];
        self.ffDecoder = nil;
    }
    if (self.ffLowDelayDecoder != nil) {
        NSAssert(self.ffDecoder == nil, @"FFDecoder must be nil");
        [self.ffLowDelayDecoder closeCodec];
        self.ffDecoder = nil;
    }
}

- (void)decodeVideoFrame:(NSData *) frameData
      decompassTimeStamp:(int64_t) decompassTimeStamp
        presentTimeStamp:(int64_t) presentTimeStamp
{
    CompassedFrame *ffCompassedFrame = [[CompassedFrame alloc] init];

    ffCompassedFrame.streamType         = VideoStream;
    ffCompassedFrame.codecID            = R_CODEC_ID_H264;
    ffCompassedFrame.decompassTimeStamp = -1;
    ffCompassedFrame.presentTimeStamp   = -1;
    ffCompassedFrame.frameData          = frameData;

    RawVideoFrame *videoFrame = nil;
    if (self.ffLowDelayDecoder) {
        videoFrame = [self.ffLowDelayDecoder decodeVideoFrame:ffCompassedFrame];
    }
    else {
        videoFrame = [self.ffDecoder decodeVideoFrame:ffCompassedFrame];
    }
    if (videoFrame != nil) {
        @autoreleasepool {
            [self buildYuneecRawVideoFrame:videoFrame];
        }
    }
}

- (void)buildYuneecRawVideoFrame:(RawVideoFrame *) videoFrame {
    if (self.decoderDelegate != nil) {
        if (videoFrame.width != self.videoWidth
            || videoFrame.height != self.videoHeight) {
            self.videoWidth = videoFrame.width;
            self.videoHeight = videoFrame.height;
            
            if ([self.decoderDelegate respondsToSelector:@selector(decoder:didChangeVideoWidth:videoHeight:)]) {
                [self.decoderDelegate decoder:self didChangeVideoWidth:self.videoWidth videoHeight:self.videoHeight];
            }
        }
        
        YuneecRawVideoFrameInner *yuneecVideoFrame = [[YuneecRawVideoFrameInner alloc] initWithWidth:videoFrame.width
                                                                                              height:videoFrame.height
                                                                                           timeStamp:videoFrame.timeStamp
                                                                                            duration:videoFrame.duration];
        for (uint32_t i = 0; i < videoFrame.lineSizeArray.count; i++)
        {
            uint32_t lineSize = (uint32_t)[videoFrame.lineSizeArray[i] integerValue];
            NSData *frameData = videoFrame.frameDataArray[i];
            [yuneecVideoFrame pushFrameData:lineSize frameByte:(uint8_t *)frameData.bytes];
        }
        
        if ([self.decoderDelegate respondsToSelector:@selector(decoder:didDecoderVideoFrame:)]) {
            [self.decoderDelegate decoder:self didDecoderVideoFrame:yuneecVideoFrame];
        }
    }
}

#pragma mark - get & set

- (FFMpegDecoderEnumerator *)ffDecoderEnumerator {
    if (_ffDecoderEnumerator == nil) {
        _ffDecoderEnumerator = [[FFMpegDecoderEnumerator alloc] init];
        [_ffDecoderEnumerator initDecoderArray];
    }
    return _ffDecoderEnumerator;
}

- (FFMpegLowDelayDecoderEnumerator *)ffLowDelayDecoderEnumerator {
    if (_ffLowDelayDecoderEnumerator == nil) {
        _ffLowDelayDecoderEnumerator = [[FFMpegLowDelayDecoderEnumerator alloc] init];
        [_ffLowDelayDecoderEnumerator initDecoderArray];
    }
    return _ffLowDelayDecoderEnumerator;
}

@end
