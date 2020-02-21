//
//  YuneecMediaError.m
//  YuneecSDK
//
//  Created by Mine on 2017/2/4.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecMediaError.h"

NSString * const  _Nonnull YuneecSDKCameraMeidaErrorDomain   = @"com.yuneec.yuneecsdk.cameraMedia";

NSString * convertYuneecCameraMediaErrorCodeToString(YuneecMediaErrorCode errorCode);


#pragma mark - Public

NSError * convertCameraMediaErrorCodeToNSError(YuneecMediaErrorCode errorCode) {
    if (errorCode == YuneecMediaErrorNoError) {
        return nil;
    }
    
    NSString *errorString = convertYuneecCameraMediaErrorCodeToString(errorCode);
    
    return [NSError errorWithDomain:YuneecSDKCameraMeidaErrorDomain
                               code:errorCode
                           userInfo:@{NSLocalizedDescriptionKey: errorString}];
}

NSError * _Nullable convertSpecialCameraMediaErrorCodeToNSError(NSInteger errorCount, NSInteger total, NSString *errorMessage) {
    
    NSString *errorString = [NSString stringWithFormat:@"%ld of %ld has been failed to delete.", (long)errorCount, (long)total];
    
    if (errorMessage) {
        errorString = [NSString stringWithFormat:@"%@ %@", errorMessage, errorString];
    }
    
    return [NSError errorWithDomain:YuneecSDKCameraMeidaErrorDomain
                               code:YuneecMediaErrorDeleteMediaError
                           userInfo:@{NSLocalizedDescriptionKey: errorString}];
}


#pragma mark - Private

/**
 * 后期需要做多语言实现，暂时先只支持英语
 */
NSString * convertYuneecCameraMediaErrorCodeToString(YuneecMediaErrorCode errorCode)
{
    NSString *errorString = @"Unknown error";
    switch(errorCode)
    {
        case YuneecMediaErrorUnknownCameraType:
            errorString = @"Please set camera type first.";
            break;
        case YuneecMediaErrorNoSuchFile:
            errorString = @"There is no such file.";
            break;
        case YuneecMediaErrorConnectionTimeout:
            errorString = @"The connection is timeout.";
            break;
        case YuneecMediaErrorDeleteMediaFailure:
            errorString = @"Failed to delete media.";
            break;
        case YuneecMediaErrorNullCamera:
            errorString = @"The camera is null.";
            break;
        case YuneecMediaErrorNoThumnail:
            errorString = @"The media doesn't has thumnail.";
            break;
        case YuneecMediaErrorMediaTypeWrong:
            errorString = @"Media type wrong.";
            break;
        case YuneecMediaErrorNoPreviewVideo:
            errorString = @"The media has no preview video.";
            break;
        case YuneecMediaErrorMediaNonsupportDNGFile:
            errorString = @"Can not display DNG file at current device.";
            break;
        case YuneecMediaErrorMoveMediaFailure:
            errorString = @"Failed to move media, please check if directory exits.";
            break;
        case YuneecMediaErrorUdpPortNotSet:
            errorString = @"Fetch meida faild, please check the communication protocol settings.";
            break;
        case YuneecMediaErrorBuildJSONDataError:
            errorString = @"Build json data error.";
            break;
        case YuneecMediaErrorEmptyMedia:
            errorString = @"No meida at SD card";
            break;
        default:
            break;
    }
    return errorString;
}
