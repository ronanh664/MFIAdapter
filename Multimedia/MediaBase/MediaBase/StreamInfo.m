//
//  StreamInfo.m
//  MediaBase
//
//  Created by tbago on 16/12/16.
//  Copyright © 2016年 tbago. All rights reserved.
//

#import "StreamInfo.h"

@interface StreamInfo()
@property (strong, nonatomic) NSMutableDictionary   *innerMetaData;
@end

@implementation StreamInfo

- (instancetype)init {
    self = [super init];
    if (self) {
        _duration = -1;
    }
    return self;
}

#pragma mark - public method

- (void)addMetaDataToStreamInfo:(NSString *)key
                          value:(NSString *)value {
    self.innerMetaData[key] = value;
}

#pragma mark - get & set

- (NSDictionary *)metaData {
    return _innerMetaData;
}

- (NSMutableDictionary *)innerMetaData {
    if (_innerMetaData == nil) {
        _innerMetaData = [[NSMutableDictionary alloc] init];
    }
    return _innerMetaData;
}

@end
