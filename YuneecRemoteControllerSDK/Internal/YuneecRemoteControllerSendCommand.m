//
//  YuneecRemoteControllerSendCommand.m
//  YuneecRemoteControllerSDK
//
//  Created by tbago on 27/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import "YuneecRemoteControllerSendCommand.h"

#import <YuneecDataTransferManager/YuneecDataTransferManager.h>
#import <YuneecDataTransferManager/YuneecRemoteControllerDataTransfer.h>

#import "NSError+YuneecRemoteControllerSDK.h"
#import "YuneecRemoteControllerProtocolBuilder.h"
#import "YuneecRemoteControllerMavlinkBuilder.h"
#import "YuneecRemoteControllerKey.h"

static const uint8_t kOldRemoteControllerProtocolHeader        = 0x40;

@interface YuneecRemoteControllerSendCommand()<YuneecRemoteControllerDataTransferDelegate>

@property (weak, nonatomic) YuneecDataTransferManager        *dataTransferManager;
@property (nonatomic, strong) NSMutableDictionary           *responseBlockDict; // store block for sending command, type is key
@property (nonatomic, strong) NSMutableDictionary           *responseTimerDict; // store timer for sending command, type is key
@property (nonatomic, strong) NSLock *responseLock;
@end

@implementation YuneecRemoteControllerSendCommand

- (instancetype)init {
    self = [super init];
    if (self) {
        _responseBlockDict = [NSMutableDictionary new];
        _responseTimerDict = [NSMutableDictionary new];
        _responseLock = [NSLock new];
    }
    return self;
}

- (void)sendCommandWithCommandType:(RemoteControllerSendCommandType) commandType
                         extraData:(NSData * _Nullable) extraData
                             block:(void(^)(NSData *data, NSError * _Nullable error)) block timeout:(NSTimeInterval)timeout {
    [self sendCommandWithCommandType:commandType extraData:extraData oldProtocol:NO block:block timeout:timeout];
}

- (void)sendCommandWithCommandType:(RemoteControllerSendCommandType) commandType
                         extraData:(NSData * _Nullable) extraData
                       oldProtocol:(BOOL) oldProtocol
                             block:(void(^)(NSData *data, NSError * _Nullable error)) block timeout:(NSTimeInterval)timeout
{
    [self.responseLock lock];
    NSNumber *keyNum = [NSNumber numberWithInt:commandType];
    if(_responseBlockDict[keyNum] != nil) {
        // Does not support sending multiple commands with same type, return error with busy
        [self.responseLock unlock];
        block(nil, [NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorClientBusy]);
        return;
    }
    NSData *protocolData = [self buildProtocolData:commandType
                                         extraData:extraData
                                       oldProtocol:oldProtocol];
    if (oldProtocol) {
        [self.dataTransferManager.remoteControllerDataTranfer sendOldProtocolData:protocolData];
    }
    else {
        [self.dataTransferManager.remoteControllerDataTranfer sendData:protocolData];
    }
    _responseBlockDict[keyNum] = [block copy];

    NSTimer *timer  = [NSTimer timerWithTimeInterval:timeout target:self selector:@selector(handleReponseTimeout:) userInfo:@{@"key":keyNum} repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    _responseTimerDict[keyNum] = timer;
    [self.responseLock unlock];
}

- (void)handleReponseTimeout:(NSTimer *)timer {
    [self.responseLock lock];
    NSNumber *keyNum = timer.userInfo[@"key"];
    void (^responseBlock)(NSData *data, NSError * _Nullable error)  = self.responseBlockDict[keyNum];
    if (responseBlock != nil) {
        responseBlock(nil, [NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorTimeout]);
    }
    self.responseBlockDict[keyNum] = nil;///<clear block
    [(NSTimer *)self.responseTimerDict[keyNum] invalidate];
    self.responseTimerDict[keyNum] = nil;
    [self.responseLock unlock];
}

- (void)close {
    [self.responseLock lock];
    for (NSTimer *timer in _responseTimerDict.allValues) {
        [timer invalidate];
    }

    for (id keyNum in _responseBlockDict.allKeys) {
        void (^responseBlock)(NSData *data, NSError * _Nullable error)  = self.responseBlockDict[keyNum];
        if (responseBlock != nil) {
            responseBlock(nil, [NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorTimeout]);
        }
    }
    [_responseBlockDict removeAllObjects];
    [_responseTimerDict removeAllObjects];
    [self.responseLock unlock];
}

#pragma mark - private method

- (NSData *)buildProtocolData:(RemoteControllerSendCommandType) commandType
                    extraData:(NSData * _Nullable) extraData
                  oldProtocol:(BOOL) oldProtocol
{
    uint32_t bufferLength = (uint32_t)(1 + extraData.length);
    uint8_t *buffer = (uint8_t *)malloc(bufferLength);
    memcpy(buffer, &commandType, 1);
    if (extraData.length > 0) {
        memcpy(buffer+1, extraData.bytes, extraData.length);
    }
    NSData *contentData = [NSData dataWithBytes:buffer length:bufferLength];
    free(buffer);

    if (oldProtocol) {
        NSData *protocolData = [YuneecRemoteControllerProtocolBuilder buildProtocolDataWithContentData:contentData];
        return protocolData;
    }
    else {
        NSData *mavlinkData = [YuneecRemoteControllerMavlinkBuilder buildMavlinkDataWithContentData:contentData];
        return mavlinkData;
    }
}

#pragma mark - YuneecRemoteControllerDataTransferDelegate

- (void)remoteControllerDataTranfer:(YuneecRemoteControllerDataTransfer *)dataTransfer
                     didReceiveData:(NSData *)data {
    uint8_t *dataByte = (uint8_t *)data.bytes;
    NSData *contentData = nil;
    if (dataByte[0] == kOldRemoteControllerProtocolHeader) {
        contentData = [YuneecRemoteControllerProtocolBuilder parserContentDataFromProtocolData:data];
        if (contentData.length > 0) {
            uint8_t *contentDataByte = (uint8_t *)contentData.bytes;
            uint8_t command = *contentDataByte;
            if (command == RemoteControllerSendCommandTypeTransferData) {
                //contentData = nil;
            }
        }
    }
    else {
        contentData = [YuneecRemoteControllerMavlinkBuilder parserContentDataFromMavlinkData:data];
        if (contentData.length > 0) {
            uint8_t *contentDataByte = (uint8_t *)contentData.bytes;
            uint8_t command = *contentDataByte;
            if (command == RemoteControllerSendCommandTypeScanCamera) {
                contentData = nil;
            }
        }
    }
    //[RCMessageReportEventInfo infoWithPayload:contentData withCommand:(MSG_REPORT_EVENT)];
    [[YuneecRemoteControllerKey sharedInstance] infoWithPayload:contentData withCommand:(MSG_REPORT_EVENT)];
    if (contentData != nil) {
        uint8_t type = *((uint8_t *)contentData.bytes);
        NSNumber *keyNum = [NSNumber numberWithUnsignedChar:type];
        [self.responseLock lock];
        if(_responseTimerDict[keyNum] != nil) {
            [(NSTimer *)_responseTimerDict[keyNum] invalidate];
        }
        void (^responseBlock)(NSData *data, NSError * _Nullable error)  = _responseBlockDict[keyNum];
        _responseBlockDict[keyNum] = nil;
        _responseTimerDict[keyNum]= nil;
        [self.responseLock unlock];
        if (responseBlock != nil) {
            responseBlock(contentData, nil);
        }
    }
}

#pragma mark - get & set

- (YuneecDataTransferManager *)dataTransferManager {
    if (_dataTransferManager == nil) {
        _dataTransferManager = [YuneecDataTransferManager sharedInstance];
        _dataTransferManager.remoteControllerDataTranfer.delegate = self;
    }
    return _dataTransferManager;
}

@end
