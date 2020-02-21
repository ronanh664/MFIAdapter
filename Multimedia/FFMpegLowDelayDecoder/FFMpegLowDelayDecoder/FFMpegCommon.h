//
//  FFMpegCommon.h
//  FFMpegDemuxer
//
//  Created by tbago on 16/12/19.
//  Copyright © 2016年 tbago. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaBase/ResuableCodecID.h>
#import <MediaBase/ResuablePixelFormat.h>
#import <MediaBase/ResuableSampleFormat.h>

#include "libavformat/avformat.h"
#include "libavcodec/avcodec.h"

extern const AVRational gGloabalTimeBase;

/**
 *  Convert ffmpeg codec id to global resuable codec id
 *
 *  @param ffCodecID ffmpeg codec id
 *
 *  @return global codec id
 */
ResuableCodecID FFMpegCodecIDToMeidaCodecID(enum AVCodecID ffCodecID);

enum AVCodecID MediaCodecIDToFFMpegCodecID(ResuableCodecID resuableCodecID);

/**
 *  Convert ffmpeg pixel format to global resuable pixel format
 *
 *  @param ffPixelFormat ffmpeg pixel format
 *
 *  @return global pixel format
 */
ResuablePixelFormat FFMpegPixelFormatToMediaPixelFormat(enum AVPixelFormat ffPixelFormat);

/**
 *  Convert ffmpeg sample format to global resuable sample format
 *
 *  @param sample_fmt ffmpeg sample format
 *
 *  @return global sample format
 */
ResuableSampleFormat FFMpegSampleFormatToMediaSampleFormat(enum AVSampleFormat sample_fmt);
