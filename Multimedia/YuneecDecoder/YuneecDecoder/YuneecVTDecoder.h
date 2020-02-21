//
//  YuneecVTDecoder.h
//  YuneecDecoder
//
//  Created by YC-JG-YXKF-PC35 on 2017/2/13.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import <YuneecDecoder/YuneecDecoder.h>

@interface YuneecVTDecoder : YuneecDecoder

/**
 * Use this delegate to receive camera decode raw video frame and video resolution change.
 */
@property (nonatomic, weak, nullable) id<YuneecDecoderDelegate>   decoderDelegate;

@end
