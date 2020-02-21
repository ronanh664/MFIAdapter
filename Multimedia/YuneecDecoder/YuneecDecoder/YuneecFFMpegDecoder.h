//
//  YuneecFFMpegDecoder.h
//  YuneecDecoder
//
//  Created by tbago on 17/1/26.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <YuneecDecoder/YuneecDecoder.h>

@interface YuneecFFMpegDecoder : YuneecDecoder

/**
 * Use this delegate to receive camera decode raw video frame and video resolution change.
 */
@property (nonatomic, weak, nullable) id<YuneecDecoderDelegate>   decoderDelegate;

@property (assign, nonatomic) BOOL                                enableLowDelay;

@end
