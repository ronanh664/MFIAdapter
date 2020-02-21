//
//  YuneecMFiControllerProtocolBuilder.h
//  YuneecMFiDataTransfer
//
//  Created by tbago on 23/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YuneecMFiDefine.h"

typedef struct {
    YuneecMFiProtocolType protocolType;
    uint32_t            pts;
    uint32_t            headerLength;
    BOOL                bDataLacking;
} MfiParsedInfo;

NS_ASSUME_NONNULL_BEGIN

@interface YuneecMFiControllerProtocolBuilder : NSObject

+ (NSData *)buildProtocolDataWithProtocolType:(YuneecMFiProtocolType) protocolType
                                  contentData:(NSData *) contentData;

+ (NSData * _Nullable)parserContentDataFromProtocolData:(NSData *) protocolData
                                             parsedInfo:(MfiParsedInfo *) pInfo;

@end

NS_ASSUME_NONNULL_END
