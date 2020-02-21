//
//  MovieInfo.m
//  MediaBase
//
//  Created by tbago on 16/12/16.
//  Copyright © 2016年 tbago. All rights reserved.
//

#import "MovieInfo.h"

@interface MovieInfo()
@property (strong, nonatomic) NSMutableArray        *innerStreamArray;
@property (strong, nonatomic) NSMutableDictionary   *innerMetaData;
@end

@implementation MovieInfo

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

#pragma mark - public method

- (void)addStreamInfoToMovieInfo:(StreamInfo *)streamInfo {
    [self.innerStreamArray addObject:streamInfo];
}

- (void)addMetaDataToMovieInfo:(NSString *)key
                         value:(NSString *)value {
    self.innerMetaData[key] = value;
}

#pragma mark - get & set

- (NSArray *)streamArray {
    return _innerStreamArray;
}

- (NSDictionary *)metaData {
    return _innerMetaData;
}

- (NSMutableArray *)innerStreamArray {
    if (_innerStreamArray == nil) {
        _innerStreamArray = [[NSMutableArray alloc] init];
    }
    return _innerStreamArray;
}

- (NSMutableDictionary *)innerMetaData {
    if (_innerMetaData == nil) {
        _innerMetaData = [[NSMutableDictionary alloc] init];
    }
    return _innerMetaData;
}
@end
