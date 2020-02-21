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

typedef NS_ENUM(NSUInteger, H264NalType) {
    NAL_SLICE           = 1,
    NAL_DPA             = 2,
    NAL_DPB             = 3,
    NAL_DPC             = 4,
    NAL_IDR_SLICE       = 5,
    NAL_SEI             = 6,
    NAL_SPS             = 7,
    NAL_PPS             = 8,
    NAL_AUD             = 9,
    NAL_END_SEQUENCE    = 10,
    NAL_END_STREAM      = 11,
    NAL_FILLER_DATA     = 12,
    NAL_SPS_EXT         = 13,
    NAL_AUXILIARY_SLICE = 19,
    NAL_FF_IGNORE       = 0xff0f001,
    NAL_Unknown         = 100,
};

extern const AVRational gGloabalTimeBase;

/**
 *  Convert ffmpeg codec id to global resuable codec id
 *
 *  @param ffCodecID ffmpeg codec id
 *
 *  @return global codec id
 */
ResuableCodecID FFMpegCodecIDToMeidaCodecID(enum AVCodecID ffCodecID);

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
