//
//  YuneecDataTransferConnectionState.m
//  YuneecDataTransferManager
//
//  Created by tbago on 16/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import "YuneecDataTransferConnectionState.h"
#import "YuneecDataTransferManager.h"
#import <YuneecWifiDataTransfer/YuneecWifiConnectionState.h>
#import <YuneecMFiDataTransfer/YuneecMFiConnectionState.h>

@interface YuneecDataTransferConnectionState() <YuneecWifiConnectionStateDelegate,
                                                YuneecMFiConnectionStateDelegate>
///< wifi
@property (strong, nonatomic) YuneecWifiConnectionState             *wifiConnectionState;
@property (assign, nonatomic) BOOL                                  wifiConnected;
///< mfi
@property (strong, nonatomic) YuneecMFiConnectionState              *MFiConnectionState;
@property (assign, nonatomic) BOOL                                  MFiConnected;
///< others
@property (assign, nonatomic) YuneecDataTransferConnectionType      currentConnectionType;

@end

@implementation YuneecDataTransferConnectionState

#pragma mark - init

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentConnectionType = YuneecDataTransferConnectionTypeNone;
    }
    return self;
}

#pragma mark - public method

- (void)startMonitorConnectionState {
    [self.wifiConnectionState startMonitorConnectionState];
    [self.MFiConnectionState startMonitorConnectionState];
}

- (void)stopMonitorConnectionState {
    [self.wifiConnectionState stopMonitorConnectionState];
    [self.MFiConnectionState stopMonitorConnectionState];
}

- (void)manualChangeConnectionType:(YuneecDataTransferConnectionType) connectionType {
    _currentConnectionType = connectionType;

    [[YuneecDataTransferManager sharedInstance] setCurrentDataTransferType:connectionType];
}

- (YuneecDataTransferConnectionType)getCurrentConnectionType {
    return _currentConnectionType;
}

#pragma mark - YuneecWifiConnectionStateDelegate

- (void)wifiConnectionState:(YuneecWifiConnectionState *) wifiConnectionState connectionStateChanged:(BOOL) connected {
    self.wifiConnected = connected;
}

#pragma mark - YuneecMFiConnectionStateDelegate

- (void)MFiConnectionState:(YuneecMFiConnectionState *)MFiConnectionState connectionStateChanged:(BOOL)connected {
    self.MFiConnected = connected;
}

#pragma mark - get & set

- (void)setWifiConnected:(BOOL)wifiConnected {
    if (_wifiConnected != wifiConnected) {
        _wifiConnected = wifiConnected;
        if (_wifiConnected) {
            ///< wifi已经连接，且当前是MFi连接状态，则不改变当前MFi连接状态
            if (self.currentConnectionType == YuneecDataTransferConnectionTypeMFi) {
                ///< do nothing
            }
            ///< 当前是未连接状态，则切换为Wifi连接状态
            else if (self.currentConnectionType == YuneecDataTransferConnectionTypeNone) {
                self.currentConnectionType = YuneecDataTransferConnectionTypeWifi;
            }
        }
        else {      ///< 当前是wifi连接方式，同时收到wifi断开连接的状态，则切换连接状态为未连接状态
            if (self.currentConnectionType == YuneecDataTransferConnectionTypeWifi) {
                self.currentConnectionType = YuneecDataTransferConnectionTypeNone;
            }
        }
    }
}

- (void)setMFiConnected:(BOOL)MFiConnected {
    if (_MFiConnected != MFiConnected) {
        _MFiConnected = MFiConnected;
        if (_MFiConnected) {
            ///< MFi已经连接，且当前是wifi连接状态，需要单独通知界面，但底层默认不切换当前状态，需要用户手动切换
            if (self.currentConnectionType == YuneecDataTransferConnectionTypeWifi) {
                if (self.connectionDelegate != nil) {
                    if ([self.connectionDelegate respondsToSelector:@selector(connectionState:changeConnectionType:fromType:)]) {
                        [self.connectionDelegate connectionState:self changeConnectionType:YuneecDataTransferConnectionTypeMFi fromType:_currentConnectionType];
                    }
                }
            }
            ///< 当前是未连接状态，则切换为MFi连接状态
            else if (self.currentConnectionType == YuneecDataTransferConnectionTypeNone) {
                self.currentConnectionType = YuneecDataTransferConnectionTypeMFi;
            }
        }
        else {
            if (self.currentConnectionType == YuneecDataTransferConnectionTypeMFi) {
                if(_wifiConnected) {
                    // switch to Wifi connection if Wifi is connected
                    self.currentConnectionType = YuneecDataTransferConnectionTypeWifi;
                }
                else {
                    self.currentConnectionType = YuneecDataTransferConnectionTypeNone;
                }
            }
        }
    }
}

- (void)setCurrentConnectionType:(YuneecDataTransferConnectionType)currentConnectionType {
    if (_currentConnectionType != currentConnectionType) {
        ///< 先通知当前连接状态变化，再改变当前状态
        if (self.connectionDelegate != nil) {
            if ([self.connectionDelegate respondsToSelector:@selector(connectionState:changeConnectionType:fromType:)]) {
                [self.connectionDelegate connectionState:self changeConnectionType:currentConnectionType fromType:_currentConnectionType];
            }
        }
        _currentConnectionType = currentConnectionType;
    }
}


- (YuneecWifiConnectionState *)wifiConnectionState {
    if (_wifiConnectionState == nil) {
        _wifiConnectionState = [[YuneecWifiConnectionState alloc] init];
        _wifiConnectionState.connectionDelegate = self;
    }
    return _wifiConnectionState;
}

- (YuneecMFiConnectionState *)MFiConnectionState {
    if (_MFiConnectionState == nil) {
        _MFiConnectionState = [[YuneecMFiConnectionState alloc] init];
        _MFiConnectionState.connectionDelegate = self;
    }
    return _MFiConnectionState;
}

@end
