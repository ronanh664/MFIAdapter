//
//  YuneecMediaError.h
//  YuneecSDK
//
//  Created by Mine on 2017/2/4.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Yuneec Media Error Code
 */
typedef NS_ENUM(NSUInteger, YuneecMediaErrorCode) {
    /**
     * No error
     */
    YuneecMediaErrorNoError                         = 0x0000,
    /**
     * The camera type is unknown
     */
    YuneecMediaErrorUnknownCameraType               = -30001,
    /**
     * No such file
     */
    YuneecMediaErrorNoSuchFile                      = -30002,
    /**
     * Fetch media time out
     */
    YuneecMediaErrorConnectionTimeout               = -30003,
    /**
     * Delete media error(special one)
     */
    YuneecMediaErrorDeleteMediaError                = -30004,
    /**
     * Fail to delete one file
     */
    YuneecMediaErrorDeleteMediaFailure              = -30005,
    /**
     * Uninitialized camera
     */
    YuneecMediaErrorNullCamera                      = -30006,
    /**
     * The media has no thumnail
     */
    YuneecMediaErrorNoThumnail                      = -30007,
    /**
     * Media type error
     */
    YuneecMediaErrorMediaTypeWrong                  = -30008,
    /**
     * This media has no preview video
     */
    YuneecMediaErrorNoPreviewVideo                  = -30009,
    /**
     * Nonsupport DNG file
     */
    YuneecMediaErrorMediaNonsupportDNGFile           = -30010,
    /**
     * Fail to move one file
     */
    YuneecMediaErrorMoveMediaFailure                 = -30011,
    /**
     * Udp port not set
     */
    YuneecMediaErrorUdpPortNotSet                   = -30012,
    /**
     * Build json data error
     */
    YuneecMediaErrorBuildJSONDataError              = -30013,
    /**
     * Empty media
     */
    YuneecMediaErrorEmptyMedia                      = -30014,
    /**
     * Error unknown
     */
    YuneecMediaErrorUnknown                         = -30099,
};

extern NSString * _Nonnull const YuneecSDKCameraMeidaErrorDomain;

NSError * _Nullable convertCameraMediaErrorCodeToNSError(YuneecMediaErrorCode errorCode);

NSError * _Nullable convertSpecialCameraMediaErrorCodeToNSError(NSInteger errorCount, NSInteger total, NSString * _Nullable errorMessage);
