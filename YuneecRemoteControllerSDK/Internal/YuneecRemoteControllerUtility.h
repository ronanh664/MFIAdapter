//
//  YuneecRemoteControllerUtility.h
//  YuneecRemoteControllerSDK
//
//  Created by tbago on 27/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSError+YuneecRemoteControllerSDK.h"

typedef NS_ENUM(NSInteger, OriginRemoteControllerErrorCode) {
    OriginRemoteControllerErrorNoError  = 0,                    ///< 成功
    OriginRemoteControllerErrorUnsupport,                       ///< 不支持
    OriginRemoteControllerErrorInvalidParam,                    ///< 参数异常
    OriginRemoteControllerErrorInvalidSetting,                  ///< 非法设定
    OriginRemoteControllerErrorBusy,                            ///< 系统繁忙
    OriginRemoteControllerErrorNotMatch,                        ///< 版本不匹配
    OriginRemoteControllerErrorGpsNotFixed,                     ///< GPS没定位
    OriginRemoteControllerErrorDisconnected         = 128,      ///< Disconnected
    OriginRemoteControllerErrorInactive             = 129,      ///< inactive
    OriginRemoteControllerErrorInterfaceDisabled    = 130,      ///< interface disabled
    OriginRemoteControllerErrorScanning             = 131,      ///< scanning
    OriginRemoteControllerErrorAuthenticating       = 132,      ///< authenticating
    OriginRemoteControllerErrorAssociating          = 133,      ///< associating
    OriginRemoteControllerErrorAssociated           = 134,      ///< associated
    OriginRemoteControllerError4WayHandShake        = 135,      ///< 4 Way handshake
    OriginRemoteControllerErrorGroupHandShake       = 136,      ///< group handshake
    OriginRemoteControllerErrorUnknown              = 255,      ///< 未知异常
};

uint8_t calcCrc8(uint8_t * buffer, uint32_t bufferLength);

YuneecRemoteControllerErrorCode convertOriginErrorCodeToNSErrorCode(OriginRemoteControllerErrorCode originErrorCode);
