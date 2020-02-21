//
//  YuneecRemoteControllerProtocolBuilder.h
//  YuneecRemoteControllerSDK
//
//  Created by tbago on 27/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YuneecRemoteControllerProtocolBuilder : NSObject

+ (NSData *)buildProtocolDataWithContentData:(NSData *) contentData;

+ (NSData * _Nullable)parserContentDataFromProtocolData:(NSData *) protocolData;

@end

NS_ASSUME_NONNULL_END
