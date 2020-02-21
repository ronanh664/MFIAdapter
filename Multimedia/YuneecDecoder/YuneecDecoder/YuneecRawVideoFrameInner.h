//
//  YuneecRawVideoFrameInner.h
//  YuneecDecoder
//
//  Created by tbago on 17/2/6.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import <YuneecDecoder/YuneecDecoder.h>

@interface YuneecRawVideoFrameInner : YuneecRawVideoFrame

- (instancetype)initWithWidth:(uint32_t) width
                       height:(uint32_t) height
                    timeStamp:(uint64_t) timeStamp
                     duration:(uint32_t) duration;

- (void)pushFrameData:(uint32_t) lineSize
            frameByte:(uint8_t *) frameByte;

@end
