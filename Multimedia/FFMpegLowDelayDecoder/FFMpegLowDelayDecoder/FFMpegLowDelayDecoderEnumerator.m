//
//  FFMpegDecoderEnumerator.m
//  FFMpegDecoder
//
//  Created by tbago on 16/12/29.
//  Copyright © 2016年 tbago. All rights reserved.
//

#import "FFMpegLowDelayDecoderEnumerator.h"

#import <MediaBase/MediaCodecInfo.h>

#import "FFMpegCommon.h"
#import "FFMpegLowDelayDecoder.h"

#include "libavcodec/avcodec.h"

@interface FFMpegLowDelayDecoderEnumerator()

@property (strong, nonatomic) NSMutableArray    *innerCodecInfoArray;

@end

@implementation FFMpegLowDelayDecoderEnumerator

- (void)initDecoderArray
{
    avcodec_register_all();
    av_log_set_level(AV_LOG_QUIET);
    
    AVCodec *pAVCodec = NULL;
    do {
        pAVCodec = av_codec_next(pAVCodec);
        if (pAVCodec != NULL && av_codec_is_decoder(pAVCodec) != 0)
        {
            enum AVMediaType mediaType = avcodec_get_type(pAVCodec->id);
            MediaDecoderType decoderType = MediaUnknownDecoder;
            switch (mediaType)
            {
                case AVMEDIA_TYPE_VIDEO:
                    decoderType = MediaVideoDecoder;
                    break;
                case AVMEDIA_TYPE_AUDIO:
                    decoderType = MediaAudioDecoder;
                    break;
                case AVMEDIA_TYPE_SUBTITLE:
                    decoderType = MediaSubtitleDecoder;
                    break;
                default:
                    break;
            }
            if (decoderType == MediaUnknownDecoder) {
                continue;
            }
            
            MediaCodecInfo *newCodecInfo = [[MediaCodecInfo alloc] init];
            newCodecInfo.type    = decoderType;
            newCodecInfo.codecID = FFMpegCodecIDToMeidaCodecID(pAVCodec->id);
            newCodecInfo.name    = [NSString stringWithUTF8String:pAVCodec->name];
            newCodecInfo.score   = 100;
            
            [self.innerCodecInfoArray addObject:newCodecInfo];
        }
    } while(pAVCodec != NULL);
}

- (FFMpegLowDelayDecoder *)createFFMpegDecoderByCodecId:(ResuableCodecID) codecID {
    for (MediaCodecInfo * codecInfo in self.innerCodecInfoArray) {
        if (codecInfo.codecID == codecID) {
            return [[FFMpegLowDelayDecoder alloc] initWithCodecInfo:codecInfo];
        }
    }
    return NULL;
}

#pragma mark - get & set

- (NSMutableArray *)innerCodecInfoArray {
    if (_innerCodecInfoArray == nil) {
        _innerCodecInfoArray = [[NSMutableArray alloc] init];
    }
    return _innerCodecInfoArray;
}

- (NSArray *)codecInfoArray {
    return self.innerCodecInfoArray;
}

@end
