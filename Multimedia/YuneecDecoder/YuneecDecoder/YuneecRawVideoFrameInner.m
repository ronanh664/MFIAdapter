//
//  YuneecRawVideoFrameInner.m
//  YuneecDecoder
//
//  Created by tbago on 17/2/6.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecRawVideoFrameInner.h"

@interface YuneecRawVideoFrameInner()

@property (strong, nonatomic) NSMutableArray            *innerLineSizeArray;
@property (strong, nonatomic) NSMutableArray            *innerFrameDataArray;
@end

@implementation YuneecRawVideoFrameInner

@synthesize width       = _width;
@synthesize height      = _height;
@synthesize timeStamp   = _timeStamp;
@synthesize duration    = _duration;

- (instancetype)initWithWidth:(uint32_t) width
                       height:(uint32_t) height
                    timeStamp:(uint64_t) timeStamp
                     duration:(uint32_t) duration
{
    self = [super init];
    if (self) {
        _width = width;
        _height = height;
    }
    return self;
}

- (void)pushFrameData:(uint32_t) lineSize
            frameByte:(uint8_t *) frameByte{
    
    [self.innerLineSizeArray addObject:@(lineSize)];
    
    NSInteger byteLength = [self calcFrameByteLength];
    NSData *frameData = [[NSData alloc] initWithBytes:frameByte length:byteLength];
    
    [self.innerFrameDataArray addObject:frameData];
}

#pragma mark - private method

- (NSInteger)calcFrameByteLength {
    NSInteger byteLength = 0;
    NSInteger lineIndex = self.innerLineSizeArray.count - 1;

    ///< only for yuv
    if (lineIndex == 0) {
        byteLength = [self.innerLineSizeArray[lineIndex] integerValue] * self.height;
    }
    else if (lineIndex > 0) {
        byteLength = [self.innerLineSizeArray[lineIndex] integerValue] * (self.height>>1);
    }
    
    return byteLength;
}

#pragma mark - get & set

- (NSMutableArray *)innerLineSizeArray {
    if (_innerLineSizeArray == nil) {
        _innerLineSizeArray = [[NSMutableArray alloc] init];
    }
    return _innerLineSizeArray;
}

- (NSMutableArray *)innerFrameDataArray {
    if (_innerFrameDataArray == nil) {
        _innerFrameDataArray = [[NSMutableArray alloc] init];
    }
    return _innerFrameDataArray;
}

- (NSArray *)lineSizeArray {
    return self.innerLineSizeArray;
}

- (NSArray *)frameDataArray {
    return self.innerFrameDataArray;
}
@end
