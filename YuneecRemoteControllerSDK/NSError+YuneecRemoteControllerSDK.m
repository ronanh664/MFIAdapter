//
//  NSError+YuneecRemoteControllerSDK.m
//  YuneecRemoteControllerSDK
//
//  Created by tbago on 27/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import "NSError+YuneecRemoteControllerSDK.h"

NSString * _Nonnull const kYuneecRemoteControllerSDKErrorDomain = @"com.yuneec.remotecontrollersdk";

@implementation NSError (YuneecRemoteControllerSDK)

+ (instancetype _Nullable)buildRemoteControllerErrorWithCode:(YuneecRemoteControllerErrorCode) errorCode {
    NSString *errorString = [self convertErrorCodeToString:errorCode];
    if (errorString != nil) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: errorString};
        return [NSError errorWithDomain:kYuneecRemoteControllerSDKErrorDomain
                                   code:errorCode
                               userInfo:userInfo];
    }
    else {
        return nil;
    }
}

#pragma mark - private method

+ (NSString *)convertErrorCodeToString:(YuneecRemoteControllerErrorCode) errorCode {
    NSString *errorString = nil;
    switch(errorCode) {
        case YuneecRemoteControllerErrorNoError:
            errorString = @"Success";
            break;
        case YuneecRemoteControllerErrorUnsupport:
            errorString = @"Unsupport command";
            break;
        case YuneecRemoteControllerErrorInvalidParam:
            errorString = @"Invalid param";
            break;
        case YuneecRemoteControllerErrorInvalidSetting:
            errorString = @"Invalid setting";
            break;
        case YuneecRemoteControllerErrorBusy:
            errorString = @"Busy";
            break;
        case YuneecRemoteControllerErrorNotMatch:
            errorString = @"Not match";
            break;
        case YuneecRemoteControllerErrorGpsNotFixed:
            errorString = @"Gps not found";
            break;

        case YuneecRemoteControllerErrorDisconnected:
            errorString = @"Disconnected";
            break;
        case YuneecRemoteControllerErrorInactive:
            errorString = @"Inactive";
            break;
        case YuneecRemoteControllerErrorInterfaceDisabled:
            errorString = @"Interface disabled";
            break;
        case YuneecRemoteControllerErrorScanning:
            errorString = @"Scanning";
            break;
        case YuneecRemoteControllerErrorAuthenticating:
            errorString = @"Authenticating";
            break;
        case YuneecRemoteControllerErrorAssociating:
            errorString = @"Associating";
            break;
        case YuneecRemoteControllerErrorAssociated:
            errorString = @"Associated";
            break;
        case YuneecRemoteControllerError4WayHandShake:
            errorString = @"4 way handshake";
            break;
        case YuneecRemoteControllerErrorGroupHandShake:
            errorString = @"group handshake";
            break;

        case YuneecRemoteControllerFirmwareNotExit:
            errorString = @"Firmware not eixts";
            break;
        case YuneecRemoteControllerFirmwareRetryMaxCount:
            errorString = @"Upload firmware failed with max retry count";
            break;

        case YuneecRemoteControllerErrorTimeout:
            errorString = @"Response timeout";
            break;
        case YuneecRemoteControllerErrorClientBusy:
            errorString = @"Client is busy";
            break;
        case YuneecRemoteControllerErrorLength:
            errorString = @"Data length error";
            break;
        case YuneecRemoteControllerErrorUnknown:
            errorString = @"Unknown error";
            break;
    }
    return errorString;
}

@end
