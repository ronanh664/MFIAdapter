//
//  YuneecRemoteControllerMavlinkBuilder.h
//  YuneecRemoteControllerSDK
//
//  Created by tbago on 05/12/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YuneecRemoteControllerMavlinkBuilder : NSObject

+ (NSData *)buildMavlinkDataWithContentData:(NSData *) contentData;

+ (NSData * _Nullable)parserContentDataFromMavlinkData:(NSData *) mavlinkData;

@end

NS_ASSUME_NONNULL_END
