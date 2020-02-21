//
//  YuneecMFiConnectionState.m
//  YuneecMFiDataTransfer
//
//  Created by tbago on 16/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import "YuneecMFiConnectionState.h"
#import "YuneecMFiInnerDataTransfer.h"

@interface YuneecMFiConnectionState()

@property (nonatomic, assign) BOOL          isConnected;

@end

static NSString * kAccessoryManufacturerPrefix = @"YUNEEC";

@implementation YuneecMFiConnectionState


#pragma mark - public method

- (void)startMonitorConnectionState {
    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
    [self registerEADNotifications];

    [self searchExternalAccessory];
}

- (void)stopMonitorConnectionState {
    [[EAAccessoryManager sharedAccessoryManager] unregisterForLocalNotifications];
    [self unregisterEADNotifications];
}

#pragma mark - Private method

- (void)searchExternalAccessory {
    for (EAAccessory *accessory in [EAAccessoryManager sharedAccessoryManager].connectedAccessories) {
        if ([self checkIfAccessoryIsYuneecDevice:accessory]) {
            [YuneecMFiInnerDataTransfer sharedInstance].connectedAccessory = accessory;
            self.isConnected = YES;
            break;
        }
    }
}

- (void)registerEADNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccessoryDidConnectNotification:) name:EAAccessoryDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccessoryDidDisconnectNotification:) name:EAAccessoryDidDisconnectNotification object:nil];
}

- (void)unregisterEADNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EAAccessoryDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EAAccessoryDidDisconnectNotification object:nil];
}

#pragma mark - Notification

- (void)handleAccessoryDidConnectNotification:(NSNotification *)notification {
    EAAccessory *connectedAccessory = [notification.userInfo objectForKey:EAAccessoryKey];
    if ([self checkIfAccessoryIsYuneecDevice:connectedAccessory]) {
        [YuneecMFiInnerDataTransfer sharedInstance].connectedAccessory = connectedAccessory;
        self.isConnected = YES;
    }
}

- (void)handleAccessoryDidDisconnectNotification:(NSNotification *)notification {
    EAAccessory *accessory = [notification.userInfo objectForKey:EAAccessoryKey];
    if ([self checkIfAccessoryIsYuneecDevice:accessory]) {
        self.isConnected = NO;
        [YuneecMFiInnerDataTransfer sharedInstance].connectedAccessory = nil;
    }
}

- (BOOL)checkIfAccessoryIsYuneecDevice:(EAAccessory *)accessory {
    return [[accessory.manufacturer uppercaseString] hasPrefix:kAccessoryManufacturerPrefix];
}

#pragma mark - set & get

- (void)setIsConnected:(BOOL)isConnected {
    if (_isConnected != isConnected) {
        _isConnected = isConnected;

        if (_isConnected) {
            [[YuneecMFiInnerDataTransfer sharedInstance] openMFiDataTransfer];
        }
        else {
            [[YuneecMFiInnerDataTransfer sharedInstance] closeMFiDataTransfer];
        }
        
        // delegate
        if (self.connectionDelegate != nil && [self.connectionDelegate respondsToSelector:@selector(MFiConnectionState:connectionStateChanged:)]) {
            [self.connectionDelegate MFiConnectionState:self connectionStateChanged:isConnected];
        }
    }
}

@end
