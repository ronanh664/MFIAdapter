//
//  YuneecMFiSessionController.h
//  MFITest
//
//  Created by kimiz on 2017/8/24.
//  Copyright © 2017年 Yuneec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>

@interface YuneecMFiSessionController : NSObject

@property (nonatomic, readonly) EAAccessory *accessory;
@property (nonatomic, readonly) NSString *protocolString;

- (instancetype)initWithAccesory:(EAAccessory *)accesory
                  protocolString:(NSString *)protocolString;

- (BOOL)openSession;

- (void)closeSession;

- (void)writeData:(NSData *)data;

@end
