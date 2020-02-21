//
//  YuneecRemoteControllerSendCommand.h
//  YuneecRemoteControllerSDK
//
//  Created by tbago on 27/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RemoteControllerSendCommandType) {
///< 查询指令
    RemoteControllerSendCommandTypeGetBattery           = 0x01,     ///< 遥控器电池
    RemoteControllerSendCommandTypeGetGPS               = 0x02,     ///< 遥控器gps
    RemoteControllerSendCommandTypeGetGPSTime           = 0x03,     ///< 获取遥控器gps时间
    RemoteControllerSendCommandTypeGetHardwareValue     = 0x04,     ///< 获取摇控器硬件值
    RemoteControllerSendCommandTypeGetChannelMap        = 0x05,     ///< 获取遥控器摇杆操作模式
    RemoteControllerSendCommandTypeSetChannelMap        = 0x06,     ///< 设置遥控器摇杆操作模式
    RemoteControllerSendCommandTypeGetChannelCurve      = 0x07,     ///< 获取遥控器通道公式
    RemoteControllerSendCommandTypeSetChannelCurve      = 0x08,     ///< 设置遥控器通道公式
    RemoteControllerSendCommandTypeGetChannelsValue     = 0x09,     ///< 获取遥控器所有通道值
    RemoteControllerSendCommandTypeSetChannelSetting    = 0x0A,     ///< 设置通道值配置
    RemoteControllerSendCommandTypeScanAutoPilot        = 0x0B,     ///< 扫描飞机
    RemoteControllerSendCommandTypeBindAutoPilot        = 0x0C,     ///< 绑定飞机
    RemoteControllerSendCommandTypeUnbindAutoPilot      = 0x0D,     ///< 解绑飞机
    RemoteControllerSendCommandTypeGetAutoPilotBindInfo = 0x0E,     ///< 获取当前绑定飞机信息
    RemoteControllerSendCommandTypeExitBind             = 0x0F,     ///< 退出飞机绑定模式
    RemoteControllerSendCommandTypeScanCamera           = 0x10,     ///< 扫描相机
    RemoteControllerSendCommandTypeBindCamera           = 0x11,     ///< 绑定相机
    RemoteControllerSendCommandTypeUnbindCamera         = 0x12,     ///< 解绑相机
    RemoteControllerSendCommandTypeGetCameraInfo        = 0x13,     ///< 获取当前绑定相机信息
    RemoteControllerSendCommandTypeGetSDCardInfo        = 0x14,     ///< 获取遥控器SDCard信息
    RemoteControllerSendCommandTypeGetControllerType    = 0x15,     ///< 获取遥控器类型
    RemoteControllerSendCommandTypeGetVersion           = 0x16,     ///< 获取遥控器版本信息
    RemoteControllerSendCommandTypeStartUpdate          = 0x17,     ///< 开始升级遥控器
    RemoteControllerSendCommandTypeTransferData         = 0x18,     ///< 分段传输文件内容
    RemoteControllerSendCommandTypeCancelUpdate         = 0x19,     ///< 取消升级
    RemoteControllerSendCommandTypeSendMD5              = 0x1A,     ///< 发送MD5值
    RemoteControllerSendCommandTypeGetUpgradeStatus     = 0x1B,     ///< 查询升级状态
    RemoteControllerSendCommandTypeGetChannelSetting    = 0x0C,     ///< 获取通道值配置
    RemoteControllerSendCommandTypeSendPayload          = 0x1D,     ///< 通过2.4G透传Payload给飞机
    RemoteControllerSendCommandTypeCalibrate            = 0x1E,     ///< 开始、停止校准
    RemoteControllerSendCommandTypeSetGPS               = 0x1F,     ///< 设置是否使用遥控器自带的GPS
    RemoteControllerSendCommandTypeGetState             = 0x20,     ///< 获得遥控器的(Bind/Calibrate)状态

///< 工厂测试
    RemoteControllerSendCommandTypeWriteSN              = 0x60,     ///< 写SN
    RemoteControllerSendCommandTypeReadSN               = 0x61,     ///< 读SN
    RemoteControllerSendCommandTypeGetRFVersion         = 0x62,     ///< 获取RF版本信息
    RemoteControllerSendCommandTypeGPIOSet              = 0x63,     ///< 设置LED,Buzzer,Motor GPIO

///< 消息指令
    RemoteControllerSendCommandTypeTelemetryData        = 0x80,     ///< 回传飞机信息
    RemoteControllerSendCommandTypeReportEvent          = 0x81,     ///< 上报事件
    RemoteControllerSendCommandTypeBypassExtraPackage   = 0x82,     ///< 透传飞机Extra Feedback包

    RemoteControllerSendCommandTypeUnknown              = 0xff,
};

#define kRemoteControllerDefaultTimeout         (0.4f)  // 0.4s
#define kRemoteControllerBindTimeout            (2.0f)  // 2s
#define kRemoteControllerScanWifiTimeout        (20.0f) // 20s
#define kRemoteControllerScanAutoPilotTimeout   (20.0f) // 20s

@interface YuneecRemoteControllerSendCommand : NSObject

- (void)sendCommandWithCommandType:(RemoteControllerSendCommandType) commandType
                         extraData:(NSData * _Nullable) extraData
                             block:(void(^)(NSData *data, NSError * _Nullable error)) block timeout:(NSTimeInterval)timeout;

- (void)sendCommandWithCommandType:(RemoteControllerSendCommandType) commandType
                         extraData:(NSData * _Nullable) extraData
                       oldProtocol:(BOOL) oldProtocol
                             block:(void(^)(NSData *data, NSError * _Nullable error)) block timeout:(NSTimeInterval)timeout;
- (void)close;

@end

NS_ASSUME_NONNULL_END
