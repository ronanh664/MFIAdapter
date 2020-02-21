//
//  YuneecMFiManager.m
//  YuneecDataTransfer
//
//  Created by kimiz on 2017/9/15.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecMFiSessionManager.h"
#import "YuneecMFiSessionController.h"
#import <ExternalAccessory/ExternalAccessory.h>
#import "YuneecMFiDefine.h"

static NSString * const YuneecProtocolString = @"com.yuneec.controller";

@interface YuneecMFiSessionManager ()

@property (nonatomic, strong, readwrite) NSArray               *supportedProtocolStrings;
@property (nonatomic, strong, readwrite) NSMutableArray        *mfiSessionControllerArray;
@property (nonatomic, strong, readwrite) dispatch_queue_t      mfiSessionQueue;

@end

@implementation YuneecMFiSessionManager

+ (instancetype)sharedInstance {
    static YuneecMFiSessionManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

#pragma mark - Public method

- (void)createSessionControllersWithAccessory:(EAAccessory *) accessory {
    [self closeSessionControllers];

    __weak typeof(self) weakSelf = self;
    dispatch_async(self.mfiSessionQueue, ^{
        ///< create multiple session controller for each protocol
        for (NSUInteger i = 0 ; i < weakSelf.supportedProtocolStrings.count; i++) {
            NSString *supportedProtocolString = weakSelf.supportedProtocolStrings[i];
            if([supportedProtocolString isEqualToString:YuneecProtocolString]) {
                YuneecMFiSessionController *session = [[YuneecMFiSessionController alloc] initWithAccesory:accessory protocolString:supportedProtocolString];
                [session openSession];
                [weakSelf.mfiSessionControllerArray addObject:session];
            }
        }
        
        ///< must set run loop
        [[NSRunLoop currentRunLoop] addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] run];
    });
}

- (void)closeSessionControllers {
    [self.mfiSessionControllerArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        YuneecMFiSessionController *sessionController = obj;
        [sessionController closeSession];
    }];
    
    if (self.mfiSessionQueue) {
        dispatch_async(self.mfiSessionQueue, ^{
            [[NSRunLoop currentRunLoop] removePort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        });
        self.mfiSessionQueue = nil;
    }
    
    [self.mfiSessionControllerArray removeAllObjects];
}

#pragma mark - set & get

- (dispatch_queue_t)mfiSessionQueue {
    if (!_mfiSessionQueue) {
        _mfiSessionQueue = dispatch_queue_create("com.yuneec.mfiSessionManager", DISPATCH_QUEUE_CONCURRENT);
    }
    return _mfiSessionQueue;
}

- (NSMutableArray *)mfiSessionControllerArray {
    if (!_mfiSessionControllerArray) {
        _mfiSessionControllerArray = [[NSMutableArray alloc] init];
    }
    return _mfiSessionControllerArray;
}

- (NSArray *)supportedProtocolStrings {
    if (!_supportedProtocolStrings) {
        _supportedProtocolStrings = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedExternalAccessoryProtocols"];
    }
    return _supportedProtocolStrings;
}

@end
