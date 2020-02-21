//
//  YuneecMFiManager.h
//  YuneecDataTransfer
//
//  Created by kimiz on 2017/9/15.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>

NS_ASSUME_NONNULL_BEGIN

@interface YuneecMFiSessionManager : NSObject

@property (nonatomic, strong, readonly) NSMutableArray  *mfiSessionControllerArray;

+ (instancetype)sharedInstance;

- (void)createSessionControllersWithAccessory:(EAAccessory *) accessory;

- (void)closeSessionControllers;

@end

NS_ASSUME_NONNULL_END
