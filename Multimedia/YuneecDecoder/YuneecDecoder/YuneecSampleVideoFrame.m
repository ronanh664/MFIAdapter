//
//  YuneecSampleVideoFrame.m
//  YuneecDecoder
//
//  Created by alexlin on 18/1/15.
//  Copyright © 2018年 yuneec. All rights reserved.
//

#import "YuneecSampleVideoFrame.h"

@implementation YuneecSampleVideoFrame

- (instancetype)initWithWidth:(uint32_t) width
                       height:(uint32_t) height
                    isCompressed:(BOOL) bIsCompressedData
                     Buffer:(CMSampleBufferRef) sampleBuffer
{
    self = [super init];
    if (self) {
        _width = width;
        _height = height;
        _bIsCompressedData = bIsCompressedData;
        _sampleBuffer = sampleBuffer;
    }
    return self;
}

@end
