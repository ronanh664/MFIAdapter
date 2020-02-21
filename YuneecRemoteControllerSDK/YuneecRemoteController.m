//
//  YuneecRemoteController.m
//  YuneecRemoteControllerSDK
//
//  Created by tbago on 27/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import "YuneecRemoteController.h"
#import "YuneecRemoteControllerSendCommand.h"
#import "YuneecRemoteControllerUtility.h"

typedef void (^DebugLogBlock)(NSString *debugLog);

@interface YuneecRemoteController()

@property (strong, nonatomic) YuneecRemoteControllerSendCommand     *sendCommandInstance;
@property (strong, nonatomic) NSTimer                           *droneMonitorTimer;
@property (assign, nonatomic) uint32_t                          droneLostCount;
@property (assign, nonatomic, readwrite) BOOL                    bDroneLost;
@property (copy, nonatomic) DebugLogBlock                           debugLogBlock;

@property (nonatomic, assign) uint16_t                              transferFirmwareSequence;
@end

@implementation YuneecRemoteController

#pragma mark - init & dealloc

NSString* const otaServerUrl = @"https://d3qzlqwby7grio.cloudfront.net/H520/";

- (void)closeRemoteController {
    _debugLogBlock = nil;
    [self.sendCommandInstance close];
}

#pragma mark - public methods
- (void)startMonitorDroneConnection {
    [self startDroneConnectionMonitorTimer];
}

- (void)stopMonitorDroneConnection {
    [self stopDroneConnectionMonitorTimer];
}

#pragma mark - debug

- (void)setDebugLogBlock:(void (^)(NSString * _Nonnull)) block {
    _debugLogBlock = block;
}

#pragma mark - version & type

- (void)getType:(void(^)(NSError * _Nullable error,
                         NSString * _Nullable type)) block
{
    /*
     payload = {
     uint8_t command = CMD_GET_CONTROL_TYPE;
     uint8_t code;
     uint16_t typeLen;
     uint8_t type[typeLen]; //utf8字符串转byte数组
     }
     */
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeGetControllerType
                                               extraData:nil
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       if (error != nil) {
                                                           block(error, nil);
                                                           return;
                                                       }
                                                       uint8_t *byteData = (uint8_t *)data.bytes;
                                                       uint32_t dataLength = (uint32_t)data.length;
                                                       if (dataLength < 5) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], nil);
                                                           return;
                                                       }
                                                       uint32_t currentIndex = 1;
                                                       uint8_t code = byteData[currentIndex++];
                                                       if (code != 0) {
                                                           YuneecRemoteControllerErrorCode errorCode = convertOriginErrorCodeToNSErrorCode(code);
                                                           block([NSError buildRemoteControllerErrorWithCode:errorCode], nil);
                                                           return;
                                                       }

                                                       NSString *remoteControllerType = nil;
                                                       uint16_t remoteControllerTypeLen = byteData[currentIndex] + (byteData[currentIndex+1]<<8);
                                                       currentIndex += 2;
                                                       if (remoteControllerTypeLen > 0) {
                                                           remoteControllerType = [[NSString alloc] initWithBytes:byteData+currentIndex
                                                                                                           length:remoteControllerTypeLen
                                                                                                         encoding:NSUTF8StringEncoding];
                                                       }
                                                       block(nil, remoteControllerType);
                                                   } timeout:1.0];
}

- (void)getVersionInfo:(void(^)(NSError * _Nullable error,
                                NSString * _Nullable hardwareVersion,
                                NSString * _Nullable firmwareVersion,
                                NSString * _Nullable mcuVersion)) block
{
    /*
     payload = {
     uint8_t command = CMD_GET_VERSION;
     uint8_t code;
     uint16_t hardwareVersionLen;
     uint8_t hardwareVersion[hardwareVersionLen]; //utf8字符串转byte数组
     uint16_t firmwareVersionLen;
     uint8_t firmwareVersion[firmwareVersionLen]; //utf8字符串转byte数组
     uint16_t mcuVersionLen;
     uint8_t mcuVersion[firmwareVersionLen]; //utf8字符串转byte数组
     }
     */
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeGetVersion
                                               extraData:nil
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       if (error != nil) {
                                                           block(error, nil, nil, nil);
                                                           return;
                                                       }
                                                       uint8_t *byteData = (uint8_t *)data.bytes;
                                                       uint32_t dataLength = (uint32_t)data.length;
                                                       if (dataLength < 11) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], nil, nil, nil);
                                                           return;
                                                       }
                                                       uint32_t currentIndex = 1;
                                                       uint8_t code = byteData[currentIndex++];
                                                       if (code != 0) {
                                                           YuneecRemoteControllerErrorCode errorCode = convertOriginErrorCodeToNSErrorCode(code);
                                                           block([NSError buildRemoteControllerErrorWithCode:errorCode], nil, nil, nil);
                                                           return;
                                                       }

                                                       NSString *hardwareVersion = nil;
                                                       uint16_t hardwareVersionLen = byteData[currentIndex] + (byteData[currentIndex+1]<<8);
                                                       currentIndex += 2;
                                                       if (hardwareVersionLen > 0) {
                                                           hardwareVersion = [[NSString alloc] initWithBytes:byteData+currentIndex
                                                                                                      length:hardwareVersionLen
                                                                                                    encoding:NSUTF8StringEncoding];
                                                       }
                                                       currentIndex = currentIndex + hardwareVersionLen;

                                                       NSString *firmwareVersion = nil;
                                                       uint16_t firmwareVersionLen = byteData[currentIndex] + (byteData[currentIndex+1]<<8);
                                                       currentIndex += 2;
                                                       if (firmwareVersionLen > 0) {
                                                           firmwareVersion = [[NSString alloc] initWithBytes:byteData+currentIndex
                                                                                                      length:firmwareVersionLen
                                                                                                    encoding:NSUTF8StringEncoding];
                                                       }
                                                       currentIndex = currentIndex+firmwareVersionLen;

                                                       NSString *mcuVersion = nil;
                                                       uint16_t mcuVersionLen = byteData[currentIndex] + (byteData[currentIndex+1]<<8);
                                                       currentIndex += 2;
                                                       if (mcuVersionLen > 0) {
                                                           mcuVersion = [[NSString alloc] initWithBytes:byteData+currentIndex
                                                                                                 length:mcuVersionLen
                                                                                               encoding:NSUTF8StringEncoding];
                                                       }
                                                       block(nil, hardwareVersion, firmwareVersion, mcuVersion);
                                                   } timeout:kRemoteControllerDefaultTimeout];
}

#pragma mark - autopilot bind
- (void)scanAutoPilot:(void(^)(NSError *_Nullable error,
                                NSArray * _Nullable autoPilotIds)) block
{
    /*
     --> payload = {
     uint8_t command = CMD_SCAN_AUTOPILOT;
     }
     <-- payload = {
     uint8_t command = CMD_SCAN_AUTOPILOT;
     uint8_t code;
     uint8_t count;
     uint32_t aircraftIds[count]
     }
     */
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeScanAutoPilot
                                               extraData:nil
                                             oldProtocol:YES
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       if (error != nil) {
                                                           block(error, nil);
                                                           return;
                                                       }
                                                       uint8_t *byteData = (uint8_t *)data.bytes;
                                                       uint32_t dataLength = (uint32_t)data.length;
                                                       if (dataLength < 2) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], nil);
                                                           return;
                                                       }
                                                       uint32_t currentIndex = 1;
                                                       uint8_t code = byteData[currentIndex++];
                                                       if (code != 0) {
                                                           YuneecRemoteControllerErrorCode errorCode = convertOriginErrorCodeToNSErrorCode(code);
                                                           block([NSError buildRemoteControllerErrorWithCode:errorCode], nil);
                                                           return;
                                                       }
                                                       
                                                       if (dataLength < 3) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], nil);
                                                           return;
                                                       }
                                                       
                                                       NSMutableArray *autoPilotIds = [[NSMutableArray alloc] init];
                                                       uint8_t autoPilotIdCount = byteData[currentIndex++];
                                                       for (uint32_t index = 0; index < autoPilotIdCount; index++)
                                                       {
                                                           if (currentIndex+2 >= dataLength) {
                                                               break;
                                                           }
                                                           uint32_t autoPilotID = byteData[currentIndex] + (byteData[currentIndex+1]<<8) + (byteData[currentIndex+2]<<16) +
                                                           (byteData[currentIndex+3]<<24);
                                                           currentIndex += 2;
                                                           [autoPilotIds addObject:[NSNumber numberWithInteger:autoPilotID]];
                                                       }
                                                       block(nil, autoPilotIds);
                                                   } timeout:kRemoteControllerScanAutoPilotTimeout];
}

- (void)bindAutoPilot:(NSString *) autoPilotId
                 block:(void(^)(NSError *_Nullable error)) block
{
    /*
     --> payload = {
     uint8_t command = CMD_BIND_AUTOPILOT;
     uint32_t aircraftId;
     }
     */
    NSLog(@"Auto Pilot Id %@", autoPilotId);
    uint32_t pilotId = [autoPilotId intValue];
    uint16_t autoPilotIdDataLength = sizeof(uint32_t);
    uint32_t extraDataBufferLength = (uint32_t)(autoPilotIdDataLength);
    uint8_t *extraDataBuffer = (uint8_t *)malloc(extraDataBufferLength);
    
    memcpy(extraDataBuffer, &pilotId, autoPilotIdDataLength);
    NSData *extraData = [[NSData alloc] initWithBytes:extraDataBuffer length:extraDataBufferLength];
    free(extraDataBuffer);
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeBindAutoPilot
                                               extraData:extraData
                                             oldProtocol:YES
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       [self parserCommonResultData:data error:error block:block];
                                                   } timeout:kRemoteControllerDefaultTimeout];
}

#pragma mark - camera bind

- (void)scanCameraWifi:(void(^)(NSError *_Nullable error,
                                NSArray<YuneecRemoteControllerCameraWifiInfo *> * _Nullable wifiArray)) block
{
    /*
     payload = {
     uint8_t command = CMD_SCAN_CAMERA;
     uint8_t code;
     uint8_t count;
     CameraScanResult cameras[count];
     }
     typedef struct CameraScanResult {
     uint16_t len;
     uint8_t ssid[len]; //utf8字符串转byte数组
     uint16_t frequency;
     int16_t signalLevel;
     } CameraScanResult;
     */
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeScanCamera
                                               extraData:nil
                                             oldProtocol:YES
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       if (error != nil) {
                                                           block(error, nil);
                                                           return;
                                                       }
                                                       uint8_t *byteData = (uint8_t *)data.bytes;
                                                       uint32_t dataLength = (uint32_t)data.length;
                                                       if (dataLength < 2) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], nil);
                                                           return;
                                                       }
                                                       uint32_t currentIndex = 1;
                                                       uint8_t code = byteData[currentIndex++];
                                                       if (code != 0) {
                                                           YuneecRemoteControllerErrorCode errorCode = convertOriginErrorCodeToNSErrorCode(code);
                                                           block([NSError buildRemoteControllerErrorWithCode:errorCode], nil);
                                                           return;
                                                       }

                                                       if (dataLength < 3) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], nil);
                                                           return;
                                                       }

                                                       NSMutableArray<YuneecRemoteControllerCameraWifiInfo *> *wifiArray = [[NSMutableArray alloc] init];
                                                       uint8_t wifiCount = byteData[currentIndex++];
                                                       for (uint32_t wifiIndex = 0; wifiIndex < wifiCount; wifiIndex++)
                                                       {
                                                           if (currentIndex+2 >= dataLength) {
                                                               break;
                                                           }
                                                           uint16_t wifiSSIDLen = byteData[currentIndex] + (byteData[currentIndex+1]<<8);
                                                           currentIndex += 2;

                                                           if (currentIndex+wifiSSIDLen >= dataLength) {
                                                               break;
                                                           }
                                                           NSString *wifiSSID = [[NSString alloc] initWithBytes:byteData+currentIndex
                                                                                                         length:wifiSSIDLen
                                                                                                       encoding:NSUTF8StringEncoding];
                                                           currentIndex += wifiSSIDLen;

                                                           if (currentIndex+2 >= dataLength) {
                                                               break;
                                                           }
                                                           uint16_t frequency = byteData[currentIndex] + (byteData[currentIndex+1]<<8);
                                                           currentIndex += 2;

                                                           if (currentIndex+2 >= dataLength) {
                                                               break;
                                                           }
                                                           int16_t signalLevel = byteData[currentIndex] + (byteData[currentIndex+1]<<8);
                                                           currentIndex += 2;

                                                           YuneecRemoteControllerCameraWifiInfo *wifiInfo = [[YuneecRemoteControllerCameraWifiInfo alloc] init];
                                                           wifiInfo.SSID = wifiSSID;
                                                           wifiInfo.frequency = frequency;
                                                           wifiInfo.signalLevel = signalLevel;
                                                           [wifiArray addObject:wifiInfo];
                                                       }
                                                       block(nil, wifiArray);
                                                   } timeout:kRemoteControllerScanWifiTimeout];
}

- (void)bindCameraWifi:(NSString *) wifiSSID
              password:(NSString *) password
                 block:(void(^)(NSError *_Nullable error)) block
{
    /*
     upload payload = {
     uint8_t command = CMD_BIND_CAMERA;
     uint16_t ssidLen;
     uint8_t ssid[ssidLen];//utf8字符串转byte数组
     uint16_t passLen;
     uint8_t pass[passLen]; //utf8字符串转byte数组
     }
     */
    NSData *wifiSSIDData = [wifiSSID dataUsingEncoding:NSUTF8StringEncoding];
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    uint32_t extraDataBufferLength = (uint32_t)(2 + wifiSSIDData.length + 2 + passwordData.length);
    uint8_t *extraDataBuffer = (uint8_t *)malloc(extraDataBufferLength);
    uint16_t wifiSSIDDataLength = (uint16_t)wifiSSIDData.length;
    memcpy(extraDataBuffer, &wifiSSIDDataLength, 2);
    memcpy(extraDataBuffer+2, wifiSSIDData.bytes, wifiSSIDDataLength);
    uint16_t passwordDataLength = (uint16_t)passwordData.length;
    memcpy(extraDataBuffer+2+wifiSSIDDataLength, &passwordDataLength, 2);
    memcpy(extraDataBuffer+2+wifiSSIDDataLength+2, passwordData.bytes, passwordDataLength);
    NSData *extraData = [[NSData alloc] initWithBytes:extraDataBuffer length:extraDataBufferLength];
    free(extraDataBuffer);
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeBindCamera
                                               extraData:extraData
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       [self parserCommonResultData:data error:error block:block];
                                                   } timeout:kRemoteControllerBindTimeout];
}

- (void)unbindCameraWifi:(void(^)(NSError * _Nullable error)) block {
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeUnbindCamera
                                               extraData:nil
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       [self parserCommonResultData:data error:error block:block];
                                                   } timeout:kRemoteControllerDefaultTimeout];
}

- (void)unbindRC:(void(^)(NSError * _Nullable error)) block {
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeUnbindAutoPilot
                                               extraData:nil
                                             oldProtocol:YES
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       [self parserCommonResultData:data error:error block:block];
                                                   } timeout:kRemoteControllerDefaultTimeout];
}

- (void)exitBind:(void(^)(NSError * _Nullable error)) block {
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeExitBind
                                               extraData:nil
                                             oldProtocol:YES
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       [self parserCommonResultData:data error:error block:block];
                                                   } timeout:kRemoteControllerDefaultTimeout];
}

- (void)getCameraWifiBindStatus:(void(^)(NSError * _Nullable error,
                                         YuneecRemoteControllerBindCameraWifiInfo * _Nullable bindWifiInfo)) block
{
    /*
     payload = {
     uint8_t command = CMD_GET_CAMERA_INFO;
     uint8_t code;
     uint16_t ssidLen;
     uint8_t ssid[ssidLen]; //utf8字符串转byte数组
     uint16_t ipLen;
     uint8_t ip[ipLen]; //utf8字符串转byte数组
     uint16_t frequency;
     int16_t signallevel;
     }
     */
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeGetCameraInfo
                                               extraData:nil
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       if (error != nil) {
                                                           block(error, nil);
                                                           return;
                                                       }
                                                       uint8_t *byteData = (uint8_t *)data.bytes;
                                                       uint32_t dataLength = (uint32_t)data.length;
                                                       if (dataLength < 2) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], nil);
                                                           return;
                                                       }
                                                       uint32_t currentIndex = 1;
                                                       uint8_t code = byteData[currentIndex++];
                                                       if (code != 0) {
                                                           YuneecRemoteControllerErrorCode errorCode = convertOriginErrorCodeToNSErrorCode(code);
                                                           block([NSError buildRemoteControllerErrorWithCode:errorCode], nil);
                                                           return;
                                                       }

                                                       uint16_t wifiSSIDLen = byteData[currentIndex] + byteData[currentIndex+1];
                                                       currentIndex += 2;
                                                       NSString *wifiSSID = nil;
                                                       if (wifiSSIDLen > 0) {
                                                           wifiSSID = [[NSString alloc] initWithBytes:byteData+currentIndex
                                                                                                               length:wifiSSIDLen
                                                                                                               encoding:NSUTF8StringEncoding];
                                                       }
                                                       currentIndex += wifiSSIDLen;

                                                       uint16_t ipAddressLen = byteData[currentIndex] + byteData[currentIndex+1];
                                                       currentIndex += 2;
                                                       NSString *ipAddress = nil;
                                                       if (ipAddressLen > 0) {
                                                           ipAddress = [[NSString alloc] initWithBytes:byteData+currentIndex
                                                                                                length:ipAddressLen
                                                                                              encoding:NSUTF8StringEncoding];
                                                       }
                                                       currentIndex += ipAddressLen;

                                                       uint16_t frequency = byteData[currentIndex] + byteData[currentIndex+1];
                                                       currentIndex += 2;
                                                       int16_t signalLevel = byteData[currentIndex] + byteData[currentIndex+1];

                                                       YuneecRemoteControllerBindCameraWifiInfo *bindWifiInfo = [[YuneecRemoteControllerBindCameraWifiInfo alloc] init];
                                                       bindWifiInfo.SSID        = wifiSSID;
                                                       bindWifiInfo.ipAddress   = ipAddress;
                                                       bindWifiInfo.frequency   = frequency;
                                                       bindWifiInfo.signalLevel = signalLevel;
                                                       block(nil, bindWifiInfo);
                                                   } timeout:kRemoteControllerDefaultTimeout];
}

#pragma mark get & set

- (void)getSDCardInfo:(void(^)(NSError * _Nullable error,
                               BOOL isInserted,
                               NSInteger freeSpace,
                               NSInteger totalSpace)) block
{
    /*
     payload = {
     uint8_t command = CMD_GET_SDCARD_INFO;
     uint8_t code;
     uint8_t isInserted;        //0未插入，1已插入
     uint64_t free;             //单位byte
     uint64_t total;            //单位byte
     }
     */
    typedef struct  {
        uint8_t isInserted;        //0未插入，1已插入
        uint64_t free;             //单位byte
        uint64_t total;            //单位byte
    }RemoteControllerSDCardInfo;
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeGetSDCardInfo
                                               extraData:nil
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       if (error != nil) {
                                                           block(error, 0, 0, 0);
                                                           return;
                                                       }
                                                       uint8_t *byteData = (uint8_t *)data.bytes;
                                                       uint32_t dataLength = (uint32_t)data.length;
                                                       if (dataLength < 2 ) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], NO, 0, 0);
                                                           return;
                                                       }

                                                       uint32_t currentIndex = 1;
                                                       uint8_t code = byteData[currentIndex++];
                                                       if (code != 0) {
                                                           YuneecRemoteControllerErrorCode errorCode = convertOriginErrorCodeToNSErrorCode(code);
                                                           block([NSError buildRemoteControllerErrorWithCode:errorCode], NO, 0, 0);
                                                           return;
                                                       }

                                                       uint32_t SDCardInfoLength = sizeof(RemoteControllerSDCardInfo);
                                                       if (dataLength < 2 + SDCardInfoLength) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], NO, 0, 0);
                                                           return;
                                                       }

                                                       RemoteControllerSDCardInfo sdCardInfo;
                                                       memcpy(&sdCardInfo, byteData+currentIndex, SDCardInfoLength);
                                                       block(nil, sdCardInfo.isInserted, sdCardInfo.free, sdCardInfo.total);
                                                   } timeout:kRemoteControllerDefaultTimeout];
}

- (void)getBatteryInfo:(void(^)(NSError *_Nullable error,
                                uint32_t capacity,
                                float temperature,
                                BOOL isChange)) block
{
    /*
     payload = {
     uint8_t command = CMD_GET_BATTERY;
     uint8_t code;
     uint8_t capacity; //百分比0~100
     uint16_t temperature; //摄氏度取一位小数后*10
     uint8_t isCharge; //0为false，1为true
     }
     */
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeGetBattery
                                               extraData:nil
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       if (error != nil) {
                                                           block(error, 0, 0, 0);
                                                           return;
                                                       }
                                                       uint8_t *byteData = (uint8_t *)data.bytes;
                                                       uint32_t dataLength = (uint32_t)data.length;
                                                       if (dataLength < 6) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], 0, 0, NO);
                                                           return;
                                                       }
                                                       uint32_t currentIndex = 1;
                                                       uint8_t code = byteData[currentIndex++];
                                                       if (code != 0) {
                                                           YuneecRemoteControllerErrorCode errorCode = convertOriginErrorCodeToNSErrorCode(code);
                                                           block([NSError buildRemoteControllerErrorWithCode:errorCode], 0, 0, NO);
                                                           return;
                                                       }

                                                       uint8_t capacity = byteData[currentIndex++];
                                                       uint16_t temperature = byteData[currentIndex] + (byteData[currentIndex+1]<<8);
                                                       currentIndex += 2;
                                                       BOOL isChange = byteData[currentIndex];
                                                       block(nil, capacity, temperature/10.0, isChange);
                                                   } timeout:kRemoteControllerDefaultTimeout];
}

- (void)getGPSInfo:(void(^)(NSError *_Nullable error,
                            YuneecRemoteControllerGPSInfo *gpsInfo)) block
{
    /**
     payload = {
     uint8_t command = CMD_GET_GPS;
     uint8_t code;
     uint32_t longitude;    ///< *e7后取整
     uint32_t latitude;     ///< *e7后取整
     uint16_t altitude;     ///< *100后取整
     uint8_t satellites;    ///< 星数
     uint16_t accuracy;     ///< 精度
     uint16_t speed;        ///< 延角度方向速率m/s，*10后取整
     uint16_t angle;        ///< 从北顺时针偏移,单位度
     }
     */
    typedef struct {
        uint32_t longitude;    ///< *e7后取整
        uint32_t latitude;     ///< *e7后取整
        uint16_t altitude;     ///< *100后取整
        uint8_t satellites;    ///< 星数
        uint16_t accuracy;     ///< 精度
        uint16_t speed;        ///< 延角度方向速率m/s，*10后取整
        uint16_t angle;        ///< 从北顺时针偏移,单位度
    }RemoteControllerGPSInfo;

    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeGetGPS
                                               extraData:nil
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       if (error != nil) {
                                                           block(error, nil);
                                                           return;
                                                       }
                                                       uint8_t *byteData = (uint8_t *)data.bytes;
                                                       uint32_t dataLength = (uint32_t)data.length;
                                                       if (dataLength < 2) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], nil);
                                                           return;
                                                       }
                                                       uint32_t currentIndex = 1;
                                                       uint8_t code = byteData[currentIndex++];
                                                       if (code != 0) {
                                                           YuneecRemoteControllerErrorCode errorCode = convertOriginErrorCodeToNSErrorCode(code);
                                                           block([NSError buildRemoteControllerErrorWithCode:errorCode], nil);
                                                           return;
                                                       }

                                                       uint32_t remoteControllerGPSInfoLength = sizeof(RemoteControllerGPSInfo);
                                                       if (dataLength < 2 + remoteControllerGPSInfoLength) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], nil);
                                                           return;
                                                       }

                                                       RemoteControllerGPSInfo gpsInfoStruct;
                                                       memcpy(&gpsInfoStruct, byteData+currentIndex, remoteControllerGPSInfoLength);
                                                       YuneecRemoteControllerGPSInfo *gpsInfo = [[YuneecRemoteControllerGPSInfo alloc] init];
                                                       gpsInfo.latitude     = gpsInfoStruct.latitude/10000000.0;
                                                       gpsInfo.longitude    = gpsInfoStruct.longitude/10000000.0;
                                                       gpsInfo.altitude     = gpsInfoStruct.altitude/100.0;
                                                       gpsInfo.satellites   = gpsInfoStruct.satellites;
                                                       gpsInfo.speed        = gpsInfoStruct.speed;
                                                       gpsInfo.angle        = gpsInfoStruct.speed/10.0;
                                                       gpsInfo.angle        = gpsInfoStruct.angle;
                                                       block(nil, gpsInfo);

                                                   } timeout:kRemoteControllerDefaultTimeout];
}

- (void)getHardwareInfo:(void(^)(NSError * _Nullable error,
                                 YuneecRemoteControllerHardwareInfo * _Nullable hardwareInfo)) block
{
    /*
     payload = {
     uint8_t command = CMD_GET_HW_INPUT_VAL
     uint8_t code;
     uint8_t jcount;//摇杆数
     uint8_t kcount;//旋钮数
     uint8_t scount;//switch开关数
     uint8_t bcount;//button按钮数
     int16_t jvalues[jcount];//摇杆值
     int16_t kvalues[kcount];//旋钮值
     int16_t svalues[scount];//switch开关值
     int16_t bvalues[bcount];//button按钮值
     }
     */
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeGetHardwareValue
                                               extraData:nil
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       if (error != nil) {
                                                           block(error, nil);
                                                           return;
                                                       }
                                                       uint8_t *byteData = (uint8_t *)data.bytes;
                                                       uint32_t dataLength = (uint32_t)data.length;
                                                       if (dataLength < 6) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], nil);
                                                           return;
                                                       }
                                                       uint32_t currentIndex = 1;
                                                       uint8_t code = byteData[currentIndex++];
                                                       if (code != 0) {
                                                           YuneecRemoteControllerErrorCode errorCode = convertOriginErrorCodeToNSErrorCode(code);
                                                           block([NSError buildRemoteControllerErrorWithCode:errorCode], nil);
                                                           return;
                                                       }

                                                       YuneecRemoteControllerHardwareInfo   *hardwareInfo = [[YuneecRemoteControllerHardwareInfo alloc] init];
                                                       hardwareInfo.joystickCount   = byteData[currentIndex++];
                                                       hardwareInfo.knobCount       = byteData[currentIndex++];
                                                       hardwareInfo.switchCount     = byteData[currentIndex++];
                                                       hardwareInfo.buttonCount     = byteData[currentIndex++];

                                                       NSMutableArray *joystickValueArray = [[NSMutableArray alloc] init];
                                                       for (uint32_t i = 0; i < hardwareInfo.joystickCount; i++) {
                                                           int16_t joystickValue = byteData[currentIndex] + (byteData[currentIndex+1]<<8);
                                                           [joystickValueArray addObject:@(joystickValue)];
                                                           currentIndex += 2;
                                                       }
                                                       hardwareInfo.joystickValueArray = joystickValueArray;

                                                       NSMutableArray *knobValueArray = [[NSMutableArray alloc] init];
                                                       for (uint32_t i = 0; i < hardwareInfo.knobCount; i++) {
                                                           int16_t knobValue = byteData[currentIndex] + (byteData[currentIndex+1]<<8);
                                                           [knobValueArray addObject:@(knobValue)];
                                                           currentIndex += 2;
                                                       }
                                                       hardwareInfo.knobValueArray = knobValueArray;

                                                       NSMutableArray *switchValueArray = [[NSMutableArray alloc] init];
                                                       for (uint32_t i = 0; i < hardwareInfo.switchCount; i++) {
                                                           int16_t switchValue = byteData[currentIndex] + (byteData[currentIndex+1]<<8);
                                                           [switchValueArray addObject:@(switchValue)];
                                                           currentIndex += 2;
                                                       }
                                                       hardwareInfo.switchValueArray = switchValueArray;

                                                       NSMutableArray *buttonValueArray = [[NSMutableArray alloc] init];
                                                       for (uint32_t i = 0; i < hardwareInfo.buttonCount; i++) {
                                                           int16_t buttonValue = byteData[currentIndex] + (byteData[currentIndex+1]<<8);
                                                           [buttonValueArray addObject:@(buttonValue)];
                                                           currentIndex += 2;
                                                       }
                                                       hardwareInfo.buttonValueArray = buttonValueArray;

                                                       block(nil, hardwareInfo);
                                                   } timeout:kRemoteControllerDefaultTimeout];
}

- (void)getChannelMapValue:(void(^)(NSError * _Nullable error,
                                    NSArray<NSNumber *> *mapValueArray)) block
{
    /*
     payload = {
     uint8_t command = CMD_GET_CH_MAP;
     uint8_t code;
     uint8_t map[4]; // Default map[4] = {0, 3, 2, 1}; 其中J1~J4对应0~3
     // map[0] = 0　代表用J1作为第一个通道的输入
     // map[1] = 3　代表用J4作为第二个通道的输入
     // map[2] = 2　代表用J3作为第三个通道的输入
     // map[3] = 1　代表用J2作为第四个通道的输入
     }
     */
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeGetChannelMap
                                               extraData:nil
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       if (error != nil) {
                                                           block(error, nil);
                                                           return;
                                                       }
                                                       uint8_t *byteData = (uint8_t *)data.bytes;
                                                       uint32_t dataLength = (uint32_t)data.length;
                                                       if (dataLength < 6) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], nil);
                                                           return;
                                                       }
                                                       uint32_t currentIndex = 1;
                                                       uint8_t code = byteData[currentIndex++];
                                                       if (code != 0) {
                                                           YuneecRemoteControllerErrorCode errorCode = convertOriginErrorCodeToNSErrorCode(code);
                                                           block([NSError buildRemoteControllerErrorWithCode:errorCode], nil);
                                                           return;
                                                       }

                                                       NSMutableArray *mapValueArray = [[NSMutableArray alloc] init];
                                                       for (uint32_t i = 0; i < 4; i++) {
                                                           int16_t mapValue = byteData[currentIndex++];
                                                           [mapValueArray addObject:@(mapValue)];
                                                       }
                                                       block(nil, mapValueArray);
                                                   } timeout:kRemoteControllerDefaultTimeout];
}

- (void)setChannelMapValue:(NSArray<NSNumber *> *) mapValueArray
                     block:(void(^)(NSError * _Nullable error)) block
{
    NSParameterAssert(mapValueArray.count == 4);
    /*
     --> payload = {
     uint8_t command ＝ CMD_SET_CH_MAP;
     uint8_t map[4]; //参考CMD_GET_CH_MAP
     }
     */
    const uint32_t kMapCount = 4;
    uint8_t *extraDataByte = (uint8_t *)malloc(kMapCount);
    for (uint32_t i = 0; i < kMapCount; i++) {
        extraDataByte[i] = mapValueArray[i].integerValue;
    }
    NSData *extraData = [[NSData alloc] initWithBytes:extraDataByte length:kMapCount];
    free(extraDataByte);

    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeSetChannelMap
                                               extraData:extraData
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       [self parserCommonResultData:data error:error block:block];
    } timeout:kRemoteControllerDefaultTimeout];
}

- (void)startFirmwareUpgrade:(NSString *) hardwareVersion
             firmwareVersion:(NSString *) firmwareVersion
                  mcuVersion:(NSString *) mcuVersion
                firmwareName:(NSString *) firmwareName
                firmwareSize:(NSInteger) firmwareSize
                        type:(NSString *) type
                       block:(void(^)(NSError * _Nullable error)) block
{
    /*
     --> payload = {
     uint8_t command = CMD_START_UPDATE;
     PackageInfo pkgInfo;
     }
     typedef struct PackageInfo {
     uint16_t hardwareVersionLen;
     uint8_t hardwareVersion[hardwareVersionLen]; //utf8字符串转byte数组
     uint16_t firmwareVersionLen;
     uint8_t firmwareVersion[firmwareVersionLen]; //utf8字符串转byte数组
     uint16_t mcuVersionLen;
     uint8_t mcuVersion[firmwareVersionLen]; //utf8字符串转byte数组
     uint16_t fileNameLen;
     uint8_t fileName[fileNameLen]; //utf8字符串转byte数组
     uint32_t fileSize; //文件大小,单位:字节
     uint16_t typeLen;
     uint8_t type[typeLen]; //遥控器类型,utf8字符串转byte数组
     } PackageInfo;
     */

    NSData *hardwareVersionData         = [hardwareVersion dataUsingEncoding:NSUTF8StringEncoding];
    uint16_t hardwareVersionDataLength  = (uint16_t)hardwareVersionData.length;
    NSData *firmwareVersionData         = [firmwareVersion dataUsingEncoding:NSUTF8StringEncoding];
    uint16_t firmwareVersionDataLength  = (uint16_t)firmwareVersionData.length;
    NSData *mcuVersionData              = [mcuVersion dataUsingEncoding:NSUTF8StringEncoding];
    uint16_t mcuVersionDataLength       = (uint16_t)mcuVersionData.length;
    NSData *firmwareNameData            = [firmwareName dataUsingEncoding:NSUTF8StringEncoding];
    uint16_t firmwareNameDataLength     = (uint16_t)firmwareNameData.length;
    NSData *typeData                    = [type dataUsingEncoding:NSUTF8StringEncoding];
    uint16_t typeDataLength             = (uint16_t)typeData.length;

    uint32_t extraDataBufferLength = (uint32_t)(2 + hardwareVersionDataLength +
                                                2 + firmwareVersionDataLength +
                                                2 + mcuVersionDataLength +
                                                2 + firmwareNameDataLength +
                                                4 +
                                                2 + typeDataLength);
    uint8_t *extraDataBuffer = (uint8_t *)malloc(extraDataBufferLength);
    uint32_t index = 0;

    memcpy(extraDataBuffer+index, &hardwareVersionDataLength, 2);
    index += 2;
    memcpy(extraDataBuffer+index, hardwareVersionData.bytes, hardwareVersionDataLength);
    index += hardwareVersionDataLength;

    memcpy(extraDataBuffer+index, &firmwareVersionDataLength, 2);
    index += 2;
    memcpy(extraDataBuffer+index, firmwareVersionData.bytes, firmwareVersionDataLength);
    index += firmwareVersionDataLength;

    memcpy(extraDataBuffer+index, &mcuVersionDataLength, 2);
    index += 2;
    memcpy(extraDataBuffer+index, mcuVersionData.bytes, mcuVersionDataLength);
    index += mcuVersionDataLength;

    memcpy(extraDataBuffer+index, &firmwareNameDataLength, 2);
    index += 2;
    memcpy(extraDataBuffer+index, firmwareNameData.bytes, firmwareNameDataLength);
    index += firmwareNameDataLength;

    memcpy(extraDataBuffer+index, &firmwareSize, 4);
    index += 4;

    memcpy(extraDataBuffer+index, &typeDataLength, 2);
    index += 2;
    memcpy(extraDataBuffer+index, typeData.bytes, typeDataLength);
    index += typeDataLength;

    NSData *extraData = [[NSData alloc] initWithBytes:extraDataBuffer length:extraDataBufferLength];
    free(extraDataBuffer);

    self.transferFirmwareSequence = 0;
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeStartUpdate
                                               extraData:extraData
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       [self parserCommonResultData:data error:error block:block];
                                                   } timeout:kRemoteControllerDefaultTimeout];
}

- (void)transferFirmwareData:(NSData *) firmwareData
                   retryData:(BOOL) retryData
                       block:(void(^)(NSError * _Nullable error)) block
{
    if (retryData) {
        _transferFirmwareSequence--;
    }
    uint32_t extraDataBufferLength = (uint32_t)firmwareData.length + 2;
    uint8_t *extraDataBuffer = (uint8_t *)malloc(extraDataBufferLength);
    memcpy(extraDataBuffer, &_transferFirmwareSequence, 2);
    memcpy(extraDataBuffer+2, firmwareData.bytes, firmwareData.length);
    NSData *extraData = [[NSData alloc] initWithBytes:extraDataBuffer length:extraDataBufferLength];
    free(extraDataBuffer);

    _transferFirmwareSequence++;
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeTransferData
                                               extraData:extraData
                                             oldProtocol:YES
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       [self parserCommonResultData:data error:error block:block];
                                                   } timeout:3.0];
}

- (void)cancelFirmwareUpgrade:(void(^)(NSError * _Nullable error)) block {
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeCancelUpdate
                                               extraData:nil
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       [self parserCommonResultData:data error:error block:block];
                                                   } timeout:kRemoteControllerDefaultTimeout];
}

- (void)sendFirmwareMD5Value:(NSString *) MD5Value
                       block:(void(^)(NSError * _Nullable error)) block
{
    NSData *MD5Data = [MD5Value dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t *extraDataBuffer = (uint8_t *)malloc(MD5Data.length + 2);
    uint16_t MD5DataLength = MD5Data.length;
    memcpy(extraDataBuffer, &MD5DataLength, 2);
    memcpy(extraDataBuffer+2, MD5Data.bytes, MD5Data.length);
    NSData *extraData = [[NSData alloc] initWithBytes:extraDataBuffer length:MD5DataLength+2];
    free(extraDataBuffer);
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeSendMD5
                                               extraData:extraData block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                   [self parserCommonResultData:data error:error block:block];
                                               } timeout:kRemoteControllerDefaultTimeout];
}

- (void)getFirmwareUpgradeStatus:(void(^)(NSError * _Nullable error, float progress)) block {
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeGetUpgradeStatus
                                               extraData:nil
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       if (error != nil) {
                                                           block(error, -1.0);
                                                       }
                                                       uint8_t *byteData = (uint8_t *)data.bytes;
                                                       uint32_t dataLength = (uint32_t)data.length;
                                                       if (dataLength < 3) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], -1.0);
                                                           return;
                                                       }
                                                       uint32_t currentIndex = 1;
                                                       uint8_t code = byteData[currentIndex++];
                                                       if (code != 0) {
                                                           YuneecRemoteControllerErrorCode errorCode = convertOriginErrorCodeToNSErrorCode(code);
                                                           block([NSError buildRemoteControllerErrorWithCode:errorCode], -1.0);
                                                           return;
                                                       }
                                                       block(nil, byteData[currentIndex]/100.0);
                                                   } timeout:kRemoteControllerDefaultTimeout];
}

#pragma mark - private mehtod

- (void)parserCommonResultData:(NSData * _Nonnull) data
                         error:(NSError * _Nullable) error
                         block:(void(^)(NSError * _Nullable error)) block
{
    if (error != nil) {
        block(error);
        return;
    }
    uint8_t *byteData = (uint8_t *)data.bytes;
    uint32_t dataLength = (uint32_t)data.length;
    if (dataLength < 2) {
        block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength]);
        return;
    }
    uint32_t currentIndex = 1;
    uint8_t code = byteData[currentIndex++];
    if (code != 0) {
        YuneecRemoteControllerErrorCode errorCode = convertOriginErrorCodeToNSErrorCode(code);
        block([NSError buildRemoteControllerErrorWithCode:errorCode]);
        return;
    }
    block(nil);
}

#pragma mark - private mehtod

- (void)outputDebugString:(NSString *) debugString {
    if (self.debugLogBlock != nil) {
        self.debugLogBlock(debugString);
    }
}

- (void)startDroneConnectionMonitorTimer {
    [self stopDroneConnectionMonitorTimer];
    self.droneLostCount = 0;
    self.bDroneLost = NO;
    self.droneMonitorTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(checkDroneConnection)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void)stopDroneConnectionMonitorTimer {
    if(self.droneMonitorTimer != nil) {
        [self.droneMonitorTimer invalidate];
        self.droneMonitorTimer = nil;
    }
}

- (void) notifyConnectionStateUpdate:(BOOL)bConnected {
    if(self.delegate != nil) {
        [self.delegate remoteController:self updateDroneConnectionStatus:bConnected];
    }
}

- (void)checkDroneConnection {
    [self getCameraWifiBindStatus:^(NSError * _Nullable error, YuneecRemoteControllerBindCameraWifiInfo * _Nullable bindWifiInfo) {
        if (error != nil) {
            //NSLog(@"fail to get bind status...");
            self.droneLostCount++;
            if(self.droneLostCount > 3) {
                // drone communication keep lost for 5 times
                if(!self.bDroneLost) {
                    self.bDroneLost = YES;
                    self.droneLostCount = 0;
                    [self notifyConnectionStateUpdate:NO];
                }
            }
        }
        else {
            //NSString *wifiString = [NSString stringWithFormat:@"Bind camera:%@", bindWifiInfo.SSID];
            //NSLog(@"bind wifi = %@", wifiString);
            self.droneLostCount = 0;
            if(self.bDroneLost) {
                self.bDroneLost = NO;
                [self notifyConnectionStateUpdate:YES];
            }
        }
    }];
}

#pragma mark - get & set

- (YuneecRemoteControllerSendCommand *)sendCommandInstance {
    if (_sendCommandInstance == nil) {
        _sendCommandInstance = [[YuneecRemoteControllerSendCommand alloc] init];
    }
    return _sendCommandInstance;
}

/**
 * Remote Calibration Settings
 */
/**
 * 遥控器硬件值
 * responseHwInput 遥控器个按钮值;
 */
- (void)getHwInput:(void(^)(NSError * _Nullable error,RCResponseGetHwInputValInfo * _Nullable responseHwInput))block{
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeGetHardwareValue
                                               extraData:nil
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       if (error != nil) {
                                                           block(error, nil);
                                                           return;
                                                       }
                                                       uint8_t *byteData = (uint8_t *)data.bytes;
                                                       uint32_t dataLength = (uint32_t)data.length;
                                                       if (dataLength < 2) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], nil);
                                                           return;
                                                       }
                                                       uint32_t currentIndex = 1;
                                                       uint8_t code = byteData[currentIndex++];
                                                       if (code != 0) {
                                                           YuneecRemoteControllerErrorCode errorCode = convertOriginErrorCodeToNSErrorCode(code);
                                                           block([NSError buildRemoteControllerErrorWithCode:errorCode], nil);
                                                           return;
                                                       }
                                                       RCResponseGetHwInputValInfo*sendRCVersionMode = [RCResponseGetHwInputValInfo infoWithPayload:data withCommand:CMD_GET_HW_INPUT_VAL];
                                                       block(nil, sendRCVersionMode);
                                                   } timeout:kRemoteControllerDefaultTimeout];
}
/**
 * 获取遥控器的(Bind/Calibrate)状态
 * responseState 是否绑定状态和是否正在校准状态;
 */
- (void)getState:(void(^)(NSError * _Nullable error,RCResponseGetStateInfo * _Nullable responseState))block{
    
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeGetState
                                               extraData:nil
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       if (error != nil) {
                                                           block(error, nil);
                                                           return;
                                                       }
                                                       uint8_t *byteData = (uint8_t *)data.bytes;
                                                       uint32_t dataLength = (uint32_t)data.length;
                                                       if (dataLength < 2) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], nil);
                                                           return;
                                                       }
                                                       uint32_t currentIndex = 1;
                                                       uint8_t code = byteData[currentIndex++];
                                                       if (code != 0) {
                                                           YuneecRemoteControllerErrorCode errorCode = convertOriginErrorCodeToNSErrorCode(code);
                                                           block([NSError buildRemoteControllerErrorWithCode:errorCode], nil);
                                                           return;
                                                       }
                                                       RCResponseGetStateInfo * getStateMode = [RCResponseGetStateInfo infoWithPayload:data withCommand:CMD_GET_STATE];
                                                       block(nil, getStateMode);
                                                   } timeout:kRemoteControllerDefaultTimeout];
}
/**
 开始遥控器校准
 */
- (void)startRCCalibration:(void(^)(NSError * _Nullable error,RCResponseInfo *responseInfo))block{
    uint8_t i = RCCalibrateActionStart;
    NSData *data = [NSData dataWithBytes: &i length: sizeof(i)];
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeCalibrate
                                               extraData:data
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       if (error != nil) {
                                                           block(error, nil);
                                                           return;
                                                       }
                                                       uint8_t *byteData = (uint8_t *)data.bytes;
                                                       uint32_t dataLength = (uint32_t)data.length;
                                                       if (dataLength < 2) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], nil);
                                                           return;
                                                       }
                                                       uint32_t currentIndex = 1;
                                                       uint8_t code = byteData[currentIndex++];
                                                       if (code != 0) {
                                                           YuneecRemoteControllerErrorCode errorCode = convertOriginErrorCodeToNSErrorCode(code);
                                                           block([NSError buildRemoteControllerErrorWithCode:errorCode], nil);
                                                           return;
                                                       }
                                                       RCResponseInfo * getStateMode = [RCResponseInfo infoWithPayload:data withCommand:CMD_CALIBRATE];
                                                       block(nil, getStateMode);
                                                   } timeout:kRemoteControllerDefaultTimeout];
}

/**
 停止遥控器校准
 */
- (void)stopRCCalibration:(void(^)(NSError * _Nullable error,RCResponseInfo *responseInfo))block{
    uint8_t i = RCCalibrateActionCancel;
    NSData *data = [NSData dataWithBytes: &i length: sizeof(i)];
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeCalibrate
                                               extraData:data
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       if (error != nil) {
                                                           block(error, nil);
                                                           return;
                                                       }
                                                       uint8_t *byteData = (uint8_t *)data.bytes;
                                                       uint32_t dataLength = (uint32_t)data.length;
                                                       if (dataLength < 2) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], nil);
                                                           return;
                                                       }
                                                       uint32_t currentIndex = 1;
                                                       uint8_t code = byteData[currentIndex++];
                                                       if (code != 0) {
                                                           YuneecRemoteControllerErrorCode errorCode = convertOriginErrorCodeToNSErrorCode(code);
                                                           block([NSError buildRemoteControllerErrorWithCode:errorCode], nil);
                                                           return;
                                                       }
                                                       RCResponseInfo * getStateMode = [RCResponseInfo infoWithPayload:data withCommand:CMD_CALIBRATE];
                                                       block(nil, getStateMode);
                                                   } timeout:kRemoteControllerDefaultTimeout];
}

/**
 取消遥控器校准
 */
- (void)cancelRCCalibration:(void(^)(NSError * _Nullable error,RCResponseInfo *responseInfo))block{
    uint8_t i = RCCalibrateActionCancel;
    NSData *data = [NSData dataWithBytes: &i length: sizeof(i)];
    [self.sendCommandInstance sendCommandWithCommandType:RemoteControllerSendCommandTypeCalibrate
                                               extraData:data
                                                   block:^(NSData * _Nonnull data, NSError * _Nullable error) {
                                                       if (error != nil) {
                                                           block(error, nil);
                                                           return;
                                                       }
                                                       uint8_t *byteData = (uint8_t *)data.bytes;
                                                       uint32_t dataLength = (uint32_t)data.length;
                                                       if (dataLength < 2) {
                                                           block([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerErrorLength], nil);
                                                           return;
                                                       }
                                                       uint32_t currentIndex = 1;
                                                       uint8_t code = byteData[currentIndex++];
                                                       if (code != 0) {
                                                           YuneecRemoteControllerErrorCode errorCode = convertOriginErrorCodeToNSErrorCode(code);
                                                           block([NSError buildRemoteControllerErrorWithCode:errorCode], nil);
                                                           return;
                                                       }
                                                       RCResponseInfo * getStateMode = [RCResponseInfo infoWithPayload:data withCommand:CMD_CALIBRATE];
                                                       block(nil, getStateMode);
                                                   } timeout:kRemoteControllerDefaultTimeout];
    
}
@end
