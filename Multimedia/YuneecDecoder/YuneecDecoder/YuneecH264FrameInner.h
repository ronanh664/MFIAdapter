//
//  YuneecH264FrameInner.h
//  YuneecDecoder
//
//  Created by tbago on 17/2/6.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YuneecH264FrameInner : NSObject

@property (copy, nonatomic) NSData      *frameData;
@property (nonatomic) int64_t           decompassTimeStamp;
@property (nonatomic) int64_t           presentTimeStamp;

@end
