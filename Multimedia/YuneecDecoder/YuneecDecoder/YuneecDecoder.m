//
//  YuneecDecoder.m
//  YuneecDecoder
//
//  Copyright © 2017 Yuneec. All rights reserved.
//

#import "YuneecDecoder.h"
#import "YuneecFFMpegDecoder.h"
#import "YuneecVTDecoder.h"

#import "YuneecH264FrameInner.h"

/**
 * 同时支持利用FFMpeg和硬件解码
 * 采用队列＋Delegate回调来实现解码器操作
 */

@interface YuneecDecoder()

@property (strong, nonatomic) YuneecDecoder             *innerDecoder;
@property (nonatomic) BOOL                              isDecoderOpen;
///< decoder thread queue
@property (strong, nonatomic) NSThread                  *decoderThread;
@property (atomic) BOOL                                 stopDecoder;
@property (nonatomic) NSMutableArray                    *h264DataArray;
@property (strong, nonatomic) NSLock                    *queueLock;
@end

@implementation YuneecDecoder

- (BOOL)openCodec {
    self.isDecoderOpen = [self.innerDecoder openCodec];

    if (self.isDecoderOpen) {
        [self.queueLock lock];
        [self.h264DataArray removeAllObjects];
        [self.queueLock unlock];

        self.stopDecoder = NO;
        self.decoderThread = [[NSThread alloc] initWithTarget:self
                                                     selector:@selector(loopDecoderData)
                                                       object:nil];
        [self.decoderThread start];
    }
    return self.isDecoderOpen;
}

- (void)closeCodec {
    self.isDecoderOpen = NO;

    self.stopDecoder = YES;
    ///< clear queue data
    [self.queueLock lock];
    [self.h264DataArray removeAllObjects];
    [self.queueLock unlock];

    ///< wait thread execute complete
    while ([self.decoderThread isExecuting]) {
        [NSThread sleepForTimeInterval:0.01];
    }

    [self.innerDecoder closeCodec];
}

- (void)decodeVideoFrame:(NSData *) frameData
      decompassTimeStamp:(int64_t) decompassTimeStamp
        presentTimeStamp:(int64_t) presentTimeStamp
{
    if (!self.isDecoderOpen) {
        return;
    }
    YuneecH264FrameInner *h264Frame = [[YuneecH264FrameInner alloc] init];
    h264Frame.frameData = frameData;
    h264Frame.decompassTimeStamp = decompassTimeStamp;
    h264Frame.presentTimeStamp = presentTimeStamp;

    [self.queueLock lock];
    if (self.h264DataArray.count > 120) {
        [self.h264DataArray removeAllObjects];
    }
    [self.h264DataArray addObject:h264Frame];
    [self.queueLock unlock];
}

#pragma mark - private method

- (YuneecH264FrameInner *)getOneH264FrameFromQueue {
    YuneecH264FrameInner *h264Frame = nil;
    [self.queueLock lock];
    if (self.h264DataArray.count > 0) {
        h264Frame = [self.h264DataArray firstObject];
        [self.h264DataArray removeObject:h264Frame];
    }
    [self.queueLock unlock];
    return h264Frame;
}

- (void)loopDecoderData {
    while (!self.stopDecoder) {
        YuneecH264FrameInner *h264Frame = [self getOneH264FrameFromQueue];
        if (h264Frame != nil && h264Frame.frameData.length > 0) {
            [self.innerDecoder decodeVideoFrame:h264Frame.frameData
                             decompassTimeStamp:h264Frame.decompassTimeStamp
                               presentTimeStamp:h264Frame.presentTimeStamp];
        }
        else {
            [NSThread sleepForTimeInterval:0.005];
        }
    }
}

#pragma mark - get & set

- (NSMutableArray *)h264DataArray {
    if (_h264DataArray == nil) {
        _h264DataArray = [[NSMutableArray alloc] init];
    }
    return _h264DataArray;
}

- (NSLock *)queueLock {
    if (_queueLock == nil) {
        _queueLock = [[NSLock alloc] init];
    }
    return _queueLock;
}

@end

YuneecDecoder * createYuneecDecoder(id<YuneecDecoderDelegate> decoderDelegate, BOOL enableHardwareDecoder, BOOL enableLowDelay) {
    YuneecDecoder *outerDecoder = [[YuneecDecoder alloc] init];
    if (enableHardwareDecoder) {
        YuneecVTDecoder *VTDecoder = [[YuneecVTDecoder alloc] init];
        VTDecoder.decoderDelegate = decoderDelegate;
        outerDecoder.innerDecoder = VTDecoder;
    }
    else {
        YuneecFFMpegDecoder *ffmpegDecoder = [[YuneecFFMpegDecoder alloc] init];
        ffmpegDecoder.enableLowDelay    = enableLowDelay;
        ffmpegDecoder.decoderDelegate   = decoderDelegate;
        outerDecoder.innerDecoder       = ffmpegDecoder;
    }
    return outerDecoder;
}
