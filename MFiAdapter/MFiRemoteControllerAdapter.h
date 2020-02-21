//
//  MFiRemoteControllerAdapter.h
//  MFiAdapter
//
//  Created by Sushma Sathyanarayana on 5/2/18.
//  Copyright © 2018 Yuneec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YuneecRemoteControllerSDK/YuneecRemoteControllerSDK.h>

/**
 Remote Controller Event ID
 */
typedef NS_ENUM(NSUInteger, MFiRemoteControllerEventIDkey) {
    ///Loiter Button (Button to the left of power button)
    CustomKeyLoiterButton = 1,
    ///RTL Button (Button to the right of power button)
    CustomKeyRTLButton = 2,
    ///Camera Button
    CustomKeyCameraButton = 3,
    ///Arm Button
    CustomKeyArmButton = 4,
    ///Video Button
    CustomKeyVideoButton = 5,
};

/// This interface provides methods to communicate with the Remote Controller(RC). It also provides methods to connect/bind to the vehicle from the RC.
@interface MFiRemoteControllerAdapter : NSObject

/**
 * Singleton object
 *
 * @return MFiRemoteControllerAdapter singleton instance
 */
+ (instancetype _Nonnull )sharedInstance;

/**
 * Monitor RC events
 *
 * Call this method to get event updates, when an RC button is pressed
 */
- (void) startMonitorRCEvent;

/**
 * Scan camera wifi
 *
 * @param completionCallback Completion function block
 * When the call is success, wifiArray will contain the list of wifi.
 */
- (void)scanCameraWifi:(void(^_Nullable)(NSError * _Nullable error,
                                          NSArray<YuneecRemoteControllerCameraWifiInfo *> * _Nullable wifiArray))completionCallback;

/**
 * Scan autopilot
 *
 * @param completionCallback Completion function block
 * When the call is success, autoPilotIds will contain a list aircraft Id's.
 */
- (void)scanAutoPilot:(void(^_Nullable)(NSError * _Nullable error,
                                         NSArray * _Nullable autoPilotIds))completionCallback;

/**
 * Bind to camera wifi
 *
 * @param wifiSSID wifi SSID
 * @param wifiPassword wifi Password
 * @param completionCallback Completion function block.
 */
- (void)bindCameraWifi:(NSString *_Nullable)wifiSSID
          wifiPassword:(NSString *_Nullable)wifiPassword
    completionCallback:(void(^_Nullable)(NSError * _Nullable error))completionCallback;

/**
 * Bind to auto pilot
 *
 * @param autoPilotId aircraft Id
 * @param completionCallback Completion function block.
 */
- (void)bindAutoPilot:(NSString *_Nullable)autoPilotId
    completionCallback:(void(^_Nullable)(NSError * _Nullable error))completionCallback;

/**
 * Unbind current camera wifi
 *
 * @param completionCallback Completion function block.
 */
- (void)unBindCameraWifi:(void(^_Nullable)(NSError * _Nullable error))completionCallback;

/**
 * Unbind RC
 *
 * @param completionCallback Completion function block.
 */
- (void)unBindRC:(void(^_Nullable)(NSError * _Nullable error))completionCallback;

/**
 * Exit RC bind
 * This function should be called after bindAutoPilot,
 * to successfully complete the binding process
 *
 * @param completionCallback Completion function block.
 */
- (void)exitBind:(void(^_Nullable)(NSError * _Nullable error))completionCallback;

/**
 * Get camera bind status
 *
 * @param completionCallback Completion function block
 * When already binding to camera wifi, bindWifiInfo will contain the camera wifi info.
 */
- (void)getCameraWifiBindStatus:(void(^_Nullable)(NSError * _Nullable error,
                                         YuneecRemoteControllerBindCameraWifiInfo * _Nullable bindWifiInfo))completionCallback;

/**
 * Upgrade firmware
 *
 * @param filePath firmware local store path
 * @param progressBlock progress block
 * @param completionBlock completion block
 */
- (void)firmwareUpdate:(NSString *) filePath
            progressBlock:(void (^)(float progress)) progressBlock
            completionBlock:(void (^)(NSError *_Nullable error)) completionBlock;

/**
 * Get RC firmware version
 *
 * @param completionBlock Completion block.
 */
- (void)getFirmwareVersionInfo:(void(^)(NSString * _Nullable firmwareVersion)) completionBlock;
@end
