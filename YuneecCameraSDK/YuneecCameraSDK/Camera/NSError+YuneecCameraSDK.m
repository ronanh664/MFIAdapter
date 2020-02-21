//
//  NSError+YuneecCameraSDK.m
//  YuneecCameraSDK
//
//  Created by kimiz on 2017/10/12.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "NSError+YuneecCameraSDK.h"

NSString * _Nonnull const YuneecCameraSDKErrorDomain = @"com.yuneec.camerasdk";

@implementation NSError (YuneecCameraSDK)

+ (instancetype _Nullable)buildCameraErrorForCode:(NSInteger)errorCode {
    NSString *errorString = [self getErrorStringForCode:errorCode];
    if (nil == errorString) {
        errorString = @"camera failed to execute";
    }
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: errorString};
    return [NSError errorWithDomain:YuneecCameraSDKErrorDomain code:errorCode userInfo:userInfo];
}

+ (NSString *)getErrorStringForCode:(NSInteger)errorCode {
    NSString *errorString = nil;
    switch(errorCode)
    {
        case YuneecCameraErrorIsDisconnected:
            errorString = @"camera_error_message_is_disconnect";
            break;
        case YuneecCameraErrorIsNotInitialized:
            errorString = @"camera_error_message_is_not_initialized";
            break;
        case YuneecCameraErrorIsInProgress:
            errorString = @"camera_error_message_is_in_progress";
            break;
        case YuneecCameraErrorIsNotSupport:
            errorString = @"camera_error_message_is_not_supported";
            break;
        case YuneecCameraErrorFailed:
            errorString = @"camera_error_message_failed";
            break;
        case YuneecCameraErrorTimeout:
            errorString = @"camera_error_message_timeout";
            break;
        case YuneecCameraInvalidParameter:
            errorString = @"camera_error_message_invalid_parameter";
            break;
        case YuneecCameraErrorWrongParamId:
            errorString = @"camera_error_message_wrong_param_id";
            break;
        case YuneecCameraErrorWrongParamValue:
            errorString = @"camera_error_message_wrong_param_value";
            break;
        case YuneecCameraErrorReturnDataInvalid:
            errorString = @"camera_error_message_return_data_invalid";
            break;
        case YuneecCameraErrorIsNotVideoMode:
            errorString = @"camera_error_message_is_not_video_mode";
            break;
        case YuneecCameraErrorIsNotPhotoMode:
            errorString = @"camera_error_message_is_not_photo_mode";
            break;
        case YuneecCameraErrorIsRecordingVideo:
            errorString = @"camera_error_message_is_recording_video";
            break;
        case YuneecCameraErrorIsNotRecordingVideo:
            errorString = @"camera_error_message_is_not_recording_video";
            break;
        case YuneecCameraFileTransferInvalidFileNameAck:
            errorString = @"file_transfer_error_message_invalid_file_name_ack";
            break;
        case YuneecCameraFileTransferTimeout:
            errorString = @"file_transfer_error_message_timeout";
            break;
        case YuneecCameraFileTransferReceiveWrongData:
            errorString = @"file_transfer_error_message_receive_wrong_data";
            break;
        case YuneecCameraFileTransferTooManyConnection:
            errorString = @"file_transfer_error_message_too_many_connection";
            break;
        case YuneecCameraFileTransferCRCError:
            errorString = @"file_transfer_error_message_crc_error";
            break;
        case YuneecCameraFileTransferConnectionFailed:
            errorString = @"file_transfer_error_message_connection_failed";
            break;
        case YuneecCameraFileTransferFileNameTooLong:
            errorString = @"file_transfer_error_message_file_name_too_long";
            break;
        case YuneecCameraFileTransferSysCallError:
            errorString = @"file_transfer_error_message_sys_call_error";
            break;
    }
    
    NSBundle *bundle = [NSBundle bundleForClass:[NSClassFromString(@"YuneecCamera") class]];
    return NSLocalizedStringFromTableInBundle(errorString, nil, bundle, nil);
}

@end
