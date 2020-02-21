//
//  YuneecWifiCameraStreamDataTransfer.m
//  YuneecWifiDataTransfer
//
//  Created by tbago on 2017/9/6.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecWifiCameraStreamDataTransfer.h"

#import <FFMpegDemuxer/FFMpegDemuxer.h>
#import <FFMpegLowDelayDemuxer/FFMpegLowDelayDemuxer.h>

#import "YuneecWifiDataTransferConfig.h"

#ifdef DEBUG
#define DNSLog(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define DNSLog(format, ...)
#endif

@interface YuneecWifiCameraStreamDataTransfer()

@property (strong, nonatomic) FFMpegDemuxer             *ffmpegDemuxer;
@property (strong, nonatomic) FFMpegLowDelayDemuxer     *ffmpegLowDelayDemuxer;
@property (atomic)  BOOL                                stopLoopReadFrame;
@property (atomic)  BOOL                                bOpenStreamSuccess;
@property (strong, nonatomic) NSThread                  *readThread;

@end

@implementation YuneecWifiCameraStreamDataTransfer

- (BOOL)openCameraSteamDataTransfer {
    BOOL openStreamRet = NO;
    _bOpenStreamSuccess = NO;
    openStreamRet = [self openInputStream];

    if (openStreamRet) {
        _bOpenStreamSuccess = YES;
        self.stopLoopReadFrame = NO;
    }
    self.readThread = [[NSThread alloc] initWithTarget:self selector:@selector(loopReadStreamData) object:nil];
    [self.readThread start];
    // return YES even failed to open input to avoid blocking thread, read thread will keep trying
    return YES;
}

- (void)closeCameraStreamDataTransfer {
    self.stopLoopReadFrame = YES;
    if (self.enableLowDelay) {
        [self.ffmpegLowDelayDemuxer stopReading];
    }
    else {
        [self.ffmpegDemuxer stopReading];
    }
    while ([self.readThread isExecuting]) {
        sleep(0.005);
    }
    if (self.enableLowDelay) {
        [self.ffmpegLowDelayDemuxer closeInputFile];
    }
    else {
        [self.ffmpegDemuxer closeInputFile];
    }
}

#pragma mark - private method

- (BOOL) openInputStream {
    BOOL openStreamRet = NO;
    if (self.enableLowDelay) {
        openStreamRet = [self.ffmpegLowDelayDemuxer openFileByPath:cameraRtspAddress];
    }
    else {
        openStreamRet = [self.ffmpegDemuxer openFileByPath:cameraRtspAddress];
    }
    return openStreamRet;
}

- (void)loopReadStreamData
{
    while(!self.stopLoopReadFrame)
    {
        CompassedFrame *compassedFrame = nil;

        if(!_bOpenStreamSuccess) {
            _bOpenStreamSuccess = [self openInputStream];
            DNSLog(@"reopen demuxer");
            if(!_bOpenStreamSuccess) {
                sleep(0.5);
                continue;
            }
        }
        if (self.enableLowDelay) {
            compassedFrame = [self.ffmpegLowDelayDemuxer readFrame];
            if (compassedFrame == nil) {
                if (self.ffmpegLowDelayDemuxer.eof && !self.stopLoopReadFrame) { ///< 读取出错，重新启动分离器
                    DNSLog(@"reopen demuxer");
                    [self.ffmpegLowDelayDemuxer openFileByPath:cameraRtspAddress];
                }
                else {
                    sleep(0.01);
                    continue;
                }
            }
        }
        else {
            compassedFrame = [self.ffmpegDemuxer readFrame];
            if (compassedFrame == nil) {
                if (self.ffmpegDemuxer.eof && !self.stopLoopReadFrame) { ///< 读取出错，重新启动分离器
                    [self.ffmpegDemuxer openFileByPath:cameraRtspAddress];
                }
                else {
                    sleep(0.2);
                    continue;
                }
            }
        }
        if (compassedFrame != nil) {
            [self processCompassedFrame:compassedFrame];
        }
    }
}

- (void)processCompassedFrame:(CompassedFrame *) compassedFrame {
    if (compassedFrame.streamType != VideoStream) {
        return;
    }
    
    if (self.cameraStreamDelegate != nil) {
        NSData *frameData = [compassedFrame.frameData copy];
        NSData *extraData = [compassedFrame.extraData copy];
//        NSLog(@"read frame size:%zd, pts:%zd", frameData.length, compassedFrame.presentTimeStamp);
        [self.cameraStreamDelegate wifiCameraStreamDataTransfer:self
                                             didReceiveH264Data:frameData
                                                       keyFrame:compassedFrame.keyFrame
                                             decompassTimeStamp:compassedFrame.decompassTimeStamp
                                               presentTimeStamp:compassedFrame.presentTimeStamp
                                                      extraData:extraData];
    }
}

#pragma mark - Get & Set

- (FFMpegDemuxer *)ffmpegDemuxer {
    if (_ffmpegDemuxer == nil) {
        _ffmpegDemuxer = createFFMpegDemuxer();
    }
    return _ffmpegDemuxer;
}

- (FFMpegLowDelayDemuxer *)ffmpegLowDelayDemuxer {
    if (_ffmpegLowDelayDemuxer == nil) {
        _ffmpegLowDelayDemuxer = createFFMpegLowDelayDemuxer();
    }
    return _ffmpegLowDelayDemuxer;
}
@end
