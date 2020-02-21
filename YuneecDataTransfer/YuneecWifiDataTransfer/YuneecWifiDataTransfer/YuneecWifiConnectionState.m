//
//  YuneecWifiConnectionState.m
//  YuneecWifiDataTransfer
//
//  Created by tbago on 2017/9/6.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecWifiConnectionState.h"

#import <UIKit/UIKit.h>
#import <arpa/inet.h>
#import <BaseFramework/DeviceUtility.h>
#import "Reachability.h"

#import "YuneecWifiDataTransferConfig.h"

@interface YuneecWifiConnectionState()

///< Wi-Fi state
@property (strong, nonatomic) Reachability      *internetReachability;
@property (nonatomic, readwrite) BOOL           connected;
///< When the device is connect to the camera via Wi-Fi, the IP address valid prefix array.
@property (strong, nonatomic) NSArray           *validIPAddressPrefixArray;
@end

@implementation YuneecWifiConnectionState

#pragma mark - init & dealloc
- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name:kReachabilityChangedNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kReachabilityChangedNotification
                                                  object:nil];
}

#pragma mark - public method

- (void)startMonitorConnectionState {
    [self startMonitorWifiState];
}

- (void)stopMonitorConnectionState {
    [self stopMonitorWifiState];
}

#pragma mark - wifi state

- (void)startMonitorWifiState {
    [self stopMonitorWifiState];
    
    [self.internetReachability startNotifier];
    [self updateInternetConnectionWithReachability:self.internetReachability];
}

- (void)stopMonitorWifiState {
    [self.internetReachability stopNotifier];
    self.connected = NO;
}

- (void)checkValidWifiConnect {
#if TARGET_IPHONE_SIMULATOR
    self.connected = NO;
    return;
#else
    NSString *currentIpAddress = getDeviceIPAddress();
    for (NSString *validIPAddressPrefix in self.validIPAddressPrefixArray) {
        if ([currentIpAddress hasPrefix:validIPAddressPrefix]) {
            self.connected = YES;
            return;
        }
    }
    self.connected = NO;
#endif
}

- (void)updateInternetConnectionWithReachability:(Reachability *) reachability {
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    switch (netStatus)
    {
        case NotReachable:
            self.connected = NO;
            break;
        case ReachableViaWWAN:
            self.connected = NO;
            break;
        case ReachableViaWiFi:
            [self checkValidWifiConnect];
            break;
        default:
            break;
    }
}

- (void)reachabilityChanged:(NSNotification *) notification
{
    Reachability* curReach = [notification object];
    
    //    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    
    [self updateInternetConnectionWithReachability:curReach];
}

- (void)setConnected:(BOOL)connected {
    if (_connected != connected)
    {
        _connected = connected;
        if (self.connectionDelegate != nil)
        {
            if ([self.connectionDelegate respondsToSelector:@selector(wifiConnectionState:connectionStateChanged:)]) {
                [self.connectionDelegate wifiConnectionState:self connectionStateChanged:_connected];
            }
        }
    }
}

- (void)setConnectionDelegate:(id<YuneecWifiConnectionStateDelegate>) connectionDelegate {
    _connectionDelegate = connectionDelegate;
    if ([_connectionDelegate respondsToSelector:@selector(wifiConnectionState:connectionStateChanged:)]) {
        [self.connectionDelegate wifiConnectionState:self connectionStateChanged:_connected];
    }
}

- (NSArray *)validIPAddressPrefixArray {
    if (_validIPAddressPrefixArray == nil) {
        _validIPAddressPrefixArray = @[@"192.168.42"];
    }
    return _validIPAddressPrefixArray;
}

- (Reachability *)internetReachability {
    if (_internetReachability == nil) {
        struct sockaddr_in address;
        address.sin_len         = sizeof(address);
        address.sin_family      = AF_INET;
        address.sin_port        = htons(80);
        address.sin_addr.s_addr = inet_addr([cameraIpAddress UTF8String]);
        memset(&address.sin_zero, 0, sizeof(address.sin_zero));

        const struct sockaddr *addressPoint = (struct sockaddr *)&address;
        _internetReachability = [Reachability reachabilityWithAddress:addressPoint];
    }
    return _internetReachability;
}

@end
