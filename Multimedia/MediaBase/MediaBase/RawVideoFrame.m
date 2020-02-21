//
//  RawVideoFrame.m
//  MediaBase
//
//  Created by tbago on 16/12/29.
//  Copyright © 2016年 tbago. All rights reserved.
//

#import "RawVideoFrame.h"

@interface RawVideoFrame()

@property (nonatomic, readwrite) ResuablePixelFormat   pixelFormat;
@property (nonatomic, readwrite) uint32_t              width;
@property (nonatomic, readwrite) uint32_t              height;

@property (strong, nonatomic) NSMutableArray    *innerLineSizeArray;
@property (strong, nonatomic) NSMutableArray    *innerFrameDataArray;

@end

@implementation RawVideoFrame

- (instancetype)init {
    return nil;
}

- (instancetype)initWithPixFormat:(ResuablePixelFormat) pixelFormat
                            width:(uint32_t) width
                           height:(uint32_t) height
{
    self = [super init];
    if (self) {
        self.pixelFormat = pixelFormat;
        self.width = width;
        self.height = height;
    }
    return self;
}

#pragma mark - public method

- (void)pushFrameData:(uint32_t)lineSize
            frameByte:(uint8_t *)frameByte {
    
    [self.innerLineSizeArray addObject:@(lineSize)];
    
    NSInteger byteLength = [self calcFrameByteLength];
    NSData *frameData = [[NSData alloc] initWithBytes:frameByte length:byteLength];
    
    [self.innerFrameDataArray addObject:frameData];
}

#pragma mark - private method

- (NSInteger)calcFrameByteLength {
    NSInteger byteLength = 0;
    NSInteger lineIndex = self.innerLineSizeArray.count - 1;
    switch(self.pixelFormat)
    {
        case R_PIX_FMT_YUVJ420P:
        case R_PIX_FMT_YUV420P:
        case R_PIX_FMT_YUV420P10LE:
            if (lineIndex == 0) {
                byteLength = [self.innerLineSizeArray[lineIndex] integerValue] * self.height;
            }
            else if (lineIndex > 0) {
                byteLength = [self.innerLineSizeArray[lineIndex] integerValue] * (self.height>>1);
            }
            break;
        case R_PIX_FMT_RGB24:     // Packed pixel, 3 bytes per pixel, RGBRGB...
        case R_PIX_FMT_BGR24:
            byteLength = [self.innerLineSizeArray[lineIndex] integerValue] * self.height * 3;
            break;
        default:
            NSLog(@"not support pixformat");
            break;
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
