//
//  YuneecMFiDefine.h
//  YuneecDataTransfer
//
//  Created by kimiz on 2017/9/15.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#ifndef YUNEEC_MFI_DATA_TRANSFER_DEFINE_H_
#define YUNEEC_MFI_DATA_TRANSFER_DEFINE_H_

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, YuneecMFiProtocolType) {
    /**
     * 视频流
     */
    YuneecMFiProtocolTypeVideoStream,
    /**
     * 遥控器
     */
    YuneecMFiProtocolTypeController,
    /**
     * 相机控制
     */
    YuneecMFiProtocolTypeCamera,
    /**
     * 照片下载
     */
    YuneecMFiProtocolTypePhotoDownload,
    /**
     * OTA 升级
     */
    YuneecMFiProtocolTypeOTA,
    /**
     * 通用mavlink协议
     */
    YuneecMFiProtocolTypeMavlink2Protocol,
    /**
     * 保留
     */
    YuneecMFiProtocolTypeReserved,
};

extern NSString * const kYuneecMFiSessionDataReceivedNotification;

extern NSString * const kYuneecMFiSessionDebugNotification;

#endif /* YUNEEC_MFI_DATA_TRANSFER_DEFINE_H_ */
