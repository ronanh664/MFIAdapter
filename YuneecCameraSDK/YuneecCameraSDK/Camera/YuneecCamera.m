//
//  YuneecCamera.m
//  YuneecCameraSDK
//
//  Created by tbago on 2017/9/5.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecCamera.h"

#import "YuneecCameraDefine.h"
#import "c_library_v2/yuneec/mavlink.h"

#import "YuneecCamera_CameraDelegates.h"
#import "YuneecCamera_CameraState.h"
#import "YuneecCameraParameterConverter.h"
#import "NSError+YuneecCameraSDK.h"

#import <YuneecDataTransferManager/YuneecDataTransferManager.h>
#import <YuneecDataTransferManager/YuneecControllerDataTransfer.h>

static const NSInteger kCameraSystemId    = 0x01;
static const NSInteger kCameraComponentId = 0x64;
static const NSInteger kGimbalSystemId    = 0x01;
static const NSInteger kGimbalComponentId = 0x9A;
static const NSInteger kAppComponentId    = 0xBE;
static NSTimeInterval kCameraCommandTimeout = 4.0f;
static NSTimeInterval kCameraCaptureTimeout = 2.0f;

typedef void(^CommonDataBlock)(NSData *data, NSError *error);

static NSString * const ParamIdCameraMode                      = @"CAM_MODE";
static NSString * const ParamIdAEMode                          = @"CAM_EXPMODE";
static NSString * const ParamIdISOValue                        = @"CAM_ISO";
static NSString * const ParamIdShutterTime                     = @"CAM_SHUTTERSPD";
static NSString * const ParamIdExposureValue                   = @"CAM_EV";
static NSString * const ParamIdVideoResolution                 = @"CAM_VIDRES";
static NSString * const ParamIdVideoFileFormat                 = @"CAM_FILEFMT";
static NSString * const ParamIdVideoCompressionFormat          = @"CAM_VIDFMT";
static NSString * const ParamIdPhotoAspectRatio                = @"CAM_PHOTORATIO";
static NSString * const ParamIdPhotoQuality                    = @"CAM_PHOTOQUAL";
static NSString * const ParamIdPhotoFormat                     = @"CAM_PHOTOFMT";
static NSString * const ParamIdPhotoMode                       = @"CAM_PHOTOMODE";
static NSString * const ParamIdImageQuality                    = @"CAM_COLORMODE";
static NSString * const ParamIdMeterMode                       = @"CAM_METERING";
static NSString * const ParamIdMeterModeCoordinate             = @"CAM_SPOTAREA";
static NSString * const ParamIdFlickerMode                     = @"CAM_FLICKER";
static NSString * const ParamIdWhiteBalanceMode                = @"CAM_WBMODE";
static NSString * const ParamIdManualWhiteBalanceValue         = @"CAM_CUSTOMWB";
static NSString * const ParamIdImageFlipDegree                 = @"CAM_IMAGEFLIP";
static NSString * const ParamIdStreamEncoderStyle              = @"CAM_LOWDELAY";
static NSString * const ParamIdCameraSystemTime                = @"CAM_SYSTEMTIME";
static NSString * const ParamIdCameraSystemVersionInfo         = @"CAM_FWBUNDLEVER";
static NSString * const ParamIdAudioRecording                  = @"CAM_AUDIOREC";               ///< not used
static NSString * const ParamIdOTAUpgrade                      = @"CAM_OTAUPGRADE";
static NSString * const ParamIdEISMode                         = @"CAM_EIS";

@interface YuneecCamera() <YuneecCameraControllerDataTransferDelegate, YuneecUpgradeStateDataTransferDelegate>

@property (weak, nonatomic) YuneecDataTransferManager                   *dataTransferManager;
@property (nonatomic, copy) CommonDataBlock                             commonDataBlock;

@property (nonatomic, assign) BOOL                                      isCallingInitCameraMethod;
@property (nonatomic, assign) BOOL                                      isCameraInitialized;
@property (nonatomic, assign) BOOL                                      forceUpdateState;
@property (nonatomic, assign) BOOL                                      isCapturingInProgress;

@property (nonatomic, strong) dispatch_source_t                         cameraTimer;
@property (nonatomic, strong) dispatch_source_t                         captureTimer;
@property (strong, nonatomic) NSLock                                    *delegateLock;

@end

@implementation YuneecCamera

#pragma mark - init

- (instancetype)init {
    self = [super init];
    if (self) {
        _isCameraInitialized            = NO;
        _isCallingInitCameraMethod      = NO;
        _isCapturingInProgress          = NO;
        _forceUpdateState               = NO;

        _delegates = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        [YuneecDataTransferManager sharedInstance].controllerDataTransfer.upgradeStateDelegate = self;
    }
    return self;
}

#pragma mark - delegate

- (void)addDelegate:(id<YuneecCameraDelegate>) cameraDelegate {
    [self.delegateLock lock];
    [self.delegates addObject:cameraDelegate];
    [self.delegateLock unlock];
    self.forceUpdateState = YES;
}

- (void)removeDelegate:(id<YuneecCameraDelegate>) cameraDelegate {
    [self.delegateLock lock];
    [self.delegates removeObject:cameraDelegate];
    [self.delegateLock unlock];
}

- (void)removeAllDelegates {
    [self.delegateLock lock];
    [self.delegates removeAllObjects];
    [self.delegateLock unlock];
}

- (void)readyToUpdate {
    self.forceUpdateState = YES;
}

#pragma mark - Camera init method

- (void)initCamera:(void(^)(NSError *_Nullable error)) block {
    
    if (self.isCameraInitialized) {
        block(nil);
        return;
    }
    
    self.isCallingInitCameraMethod = YES;
    mavlink_message_t       message;
    
    mavlink_heartbeat_t     heartbeat;
    heartbeat.custom_mode   = 0;
    heartbeat.type          = MAV_TYPE_AIRSHIP;
    heartbeat.autopilot     = MAV_AUTOPILOT_GENERIC;
    heartbeat.base_mode     = MAV_MODE_FLAG_CUSTOM_MODE_ENABLED;
    heartbeat.system_status = MAV_STATE_STANDBY;
    
    uint16_t package_len = mavlink_msg_heartbeat_encode(kCameraSystemId, kCameraComponentId, &message, &heartbeat);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserCommonResult:data block:^(NSError *error) {
                if (error) {
                    block(error);
                }else {
                    block(nil);
                }
                weakSelf.isCallingInitCameraMethod = NO;
            }];
        }else {
            block(error);
            weakSelf.isCallingInitCameraMethod = NO;
        }
    }];
    free(buf);
}

- (void)closeCamera {
    _isCameraInitialized            = NO;
    _isCallingInitCameraMethod      = NO;
    _isCapturingInProgress          = NO;
    _forceUpdateState               = NO;
}

#pragma mark - Camera Stream ExtraData Parser

- (void)parserStreamExtraData:(NSData *) extraData {
    BOOL cameraStateChanged = [self.cameraStateImp parserCameraStateData:extraData];
    if (cameraStateChanged || self.forceUpdateState) {
        [self.delegateLock lock];
        for (id delegate in self.delegates)
        {
            if ([delegate respondsToSelector:@selector(camera:didChangeCameraState:)]) {
                [delegate camera:self didChangeCameraState:self.cameraStateImp];
                self.forceUpdateState = NO;
            }
        }
        [self.delegateLock unlock];
    }
    NSArray *histogramDataArray = [self.cameraStateImp.histogramDataArray copy];
    if (histogramDataArray.count > 0) {
        [self.delegateLock lock];
        for (id delegate in self.delegates)
        {
            if ([delegate respondsToSelector:@selector(camera:didReceiveHistogramData:)]) {
                [delegate camera:self didReceiveHistogramData:histogramDataArray];
            }
        }
        [self.delegateLock unlock];
    }
}

#pragma mark - Camera basic command

- (void)setCameraMode:(YuneecCameraMode) cameraMode
                block:(void(^)(NSError * _Nullable error)) block {
    NSString *paramIdString = ParamIdCameraMode;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    NSInteger integerValue = 0;
    
    if (cameraMode == YuneecCameraModePhoto) {
        integerValue = 0;
    }else if (cameraMode == YuneecCameraModeVideo) {
        integerValue = 1;
    }
    
    uint8_t param_value[4] = {0x00, 0x00, 0x00, 0x00};
    param_value[0] = (uint8_t)integerValue;
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_UINT32;
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint8_t ret = mavlink_msg_to_send_buffer(buf, &message);
    #pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)getCameraMode:(void (^)(NSError * _Nullable, YuneecCameraMode))block {
  
    NSString *paramIdString = ParamIdCameraMode;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, YuneecCameraModeUnknown);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *paramIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:paramIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, YuneecCameraModeUnknown);
            return;
        }
        
        uint8_t value = param_ext_value.param_value[0];
        YuneecCameraMode cameraMode = YuneecCameraModeUnknown;
        if (value == 0) {
            cameraMode = YuneecCameraModePhoto;
        }else if (value == 1) {
            cameraMode = YuneecCameraModeVideo;
        }
        block(nil, cameraMode);
        
    }];
    
    free(buf);
}

- (void)startRecordingVideo:(void(^)(NSError * _Nullable error)) block {
    mavlink_command_long_t  command_long;
    memset(&command_long, 0, sizeof(mavlink_command_long_t));
    
    command_long.command            = MAV_CMD_VIDEO_START_CAPTURE;
    command_long.target_system      = kCameraSystemId;
    command_long.target_component   = kCameraComponentId;
    
    mavlink_message_t       message;
    uint16_t package_len = mavlink_msg_command_long_encode(kCameraSystemId, kAppComponentId, &message, &command_long);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserCommonResult:data block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)stopRecordingVideo:(void(^)(NSError * _Nullable error)) block {
    mavlink_command_long_t  command_long;
    memset(&command_long, 0, sizeof(mavlink_command_long_t));
    
    command_long.command            = MAV_CMD_VIDEO_STOP_CAPTURE;
    command_long.target_system      = kCameraSystemId;
    command_long.target_component   = kCameraComponentId;
    
    mavlink_message_t       message;
    uint16_t package_len    = mavlink_msg_command_long_encode(kCameraSystemId, kAppComponentId, &message, &command_long);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserCommonResult:data block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)takePhoto:(void(^)(NSError * _Nullable error)) block {
    mavlink_command_long_t  command_long;
    memset(&command_long, 0, sizeof(mavlink_command_long_t));
    
    command_long.param3             = 0x01;
    command_long.command            = MAV_CMD_IMAGE_START_CAPTURE;
    command_long.target_system      = kCameraSystemId;
    command_long.target_component   = kCameraComponentId;
    
    mavlink_message_t       message;
    uint16_t package_len    = mavlink_msg_command_long_encode(kCameraSystemId, kAppComponentId, &message, &command_long);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:ret];
    __weak typeof(self) weakSelf = self;
    
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserCommonResult:data block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)stopTakePhoto:(void(^)(NSError * _Nullable error)) block {
    mavlink_command_long_t  command_long;
    memset(&command_long, 0, sizeof(mavlink_command_long_t));
    
    command_long.command            = MAV_CMD_IMAGE_STOP_CAPTURE;
    command_long.target_system      = kCameraSystemId;
    command_long.target_component   = kCameraComponentId;
    
    mavlink_message_t       message;
    uint16_t package_len = mavlink_msg_command_long_encode(kCameraSystemId, kAppComponentId, &message, &command_long);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:ret];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserCommonResult:data block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)getCameraVersionInfo:(void(^)(NSError * _Nullable error, YuneecCameraType cameraType, NSString * _Nullable cameraName, NSString * _Nullable version, NSString * _Nullable branch)) block {
    
    mavlink_command_long_t  command_long;
    memset(&command_long, 0, sizeof(mavlink_command_long_t));
    
    command_long.command            = MAV_CMD_REQUEST_CAMERA_INFORMATION;
    command_long.target_system      = kCameraSystemId;
    command_long.target_component   = kCameraComponentId;
    
    mavlink_message_t       message;
    uint16_t package_len = mavlink_msg_command_long_encode(kCameraSystemId, kAppComponentId, &message, &command_long);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:ret];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (error) {
            [self invalidateCommonDataBlock];
            block(error, YuneecCameraTypeUnknown, nil, nil, nil);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid == MAVLINK_MSG_ID_COMMAND_ACK) {
            mavlink_command_ack_t command_ack;
            mavlink_msg_command_ack_decode(&receive_message, &command_ack);
            
            MAV_RESULT param_result = (MAV_RESULT)command_ack.result;
            if (param_result != MAV_RESULT_ACCEPTED) {
                [self invalidateCommonDataBlock];
                NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorFailed];
                block(error, YuneecCameraTypeUnknown, nil, nil, nil);
                return;
            }
        }
        else if (receive_message.msgid == MAVLINK_MSG_ID_CAMERA_INFORMATION) {
            [self invalidateCommonDataBlock];
            mavlink_camera_information_t camera_information;
            mavlink_msg_camera_information_decode(&receive_message, &camera_information);
            
            uint8_t majorVersion = camera_information.firmware_version & 0x000F;
            uint8_t middleVersion = (camera_information.firmware_version >> 8) & 0x000F;
            uint8_t minVersion = (camera_information.firmware_version >> 16) & 0x00FF;
            uint8_t branch = camera_information.firmware_version >> 24;
            NSString *versionString = [[NSString alloc] initWithFormat:@"%d.%d.%02d", majorVersion, middleVersion, minVersion];
            
            char *branchBuffer = (char *)malloc(1);
            memset(branchBuffer, branch, 1);
            NSString *branchString = [[NSString alloc] initWithUTF8String:branchBuffer];
            free(branchBuffer);
            
            NSString *cameraNameString = [[NSString alloc] initWithUTF8String:(char *)camera_information.model_name];
            
            YuneecCameraType cameraType = YuneecCameraTypeUnknown;
            [YuneecCameraParameterConverter convertCameraName:cameraNameString toCameraType:&cameraType];
            
            block(nil, cameraType, cameraNameString, versionString, branchString);
        }

    }];
    
    free(buf);
}

- (void)getSystemVersionInfo:(void(^)(NSError * _Nullable error, NSString * _Nullable name, NSString * _Nullable version, NSString * _Nullable buildVersion, NSString * _Nullable branch)) block {
    
    NSString *paramIdString = ParamIdCameraSystemVersionInfo;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, nil, nil, nil, nil);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:receivedParamIdString]) {
            block([NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId], nil, nil, nil ,nil);
            return;
        }
        
        // C21_A_1.0.01_BUILD398_20180416
        NSString *returnString = [NSString stringWithUTF8String:param_ext_value.param_value];
        if (nil != returnString) {
            NSArray *returnStringArray = [returnString componentsSeparatedByString:@"_"];
            if (returnStringArray.count >= 4) {
                NSString *name = returnStringArray[0];
                NSString *branch = returnStringArray[1];
                NSString *version = returnStringArray[2];
                NSString *buildVersion = @"0";
                if ([returnStringArray[3] hasPrefix:@"BUILD"]) {
                    buildVersion = [returnStringArray[3] substringFromIndex:5];
                }
                block(nil, name, version, buildVersion, branch);
                return;
            }
        }
        
        block([NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamValue], nil, nil, nil, nil);
    }];
    
    free(buf);
}


- (void)getGimbalVersionInfo:(void(^)(NSError * _Nullable error, NSString *_Nullable version)) block {
    mavlink_command_long_t  command_long;
    memset(&command_long, 0, sizeof(mavlink_command_long_t));

    command_long.command            = MAV_CMD_REQUEST_AUTOPILOT_CAPABILITIES;
    command_long.target_system      = kGimbalSystemId;
    command_long.target_component   = kGimbalComponentId;

    mavlink_message_t       message;
    uint16_t package_len = mavlink_msg_command_long_encode(kGimbalSystemId, kAppComponentId, &message, &command_long);

    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);

    NSData *sendData = [[NSData alloc] initWithBytes:buf length:ret];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (error) {
            [self invalidateCommonDataBlock];
            block(error, nil);
            return ;
        }

        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;

        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);

        if (receive_message.msgid == MAVLINK_MSG_ID_COMMAND_ACK) {
            mavlink_command_ack_t command_ack;
            mavlink_msg_command_ack_decode(&receive_message, &command_ack);

            MAV_RESULT param_result = (MAV_RESULT)command_ack.result;
            if (param_result != MAV_RESULT_ACCEPTED) {
                [self invalidateCommonDataBlock];
                NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorFailed];
                block(error, nil);
                return;
            }
        }
        else if (receive_message.msgid == MAVLINK_MSG_ID_AUTOPILOT_VERSION) {
            [self invalidateCommonDataBlock];
            mavlink_autopilot_version_t autopilot_version;
            mavlink_msg_autopilot_version_decode(&receive_message, &autopilot_version);

            uint32_t flight_sw_version = autopilot_version.flight_sw_version;
            NSString *versionString = [NSString stringWithFormat:@"%d.%d.%d", flight_sw_version>>24,
                                       (uint8_t)(flight_sw_version>>16),
                                       (uint8_t)(flight_sw_version>>8)];
            block(nil, versionString);
        }
   }];

    free(buf);
}

#pragma mark - Camera Settings

- (void)setAEMode:(YuneecCameraAEMode)aeMode block:(void (^)(NSError * _Nullable))block {
    
    NSString *paramIdString = ParamIdAEMode;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    uint8_t param_value = (uint8_t)aeMode;
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_UINT8;
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)getAEMode:(void (^)(NSError * _Nullable, YuneecCameraAEMode))block {
    
    NSString *paramIdString = ParamIdAEMode;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, YuneecCameraAEModeUnknown);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:receivedParamIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, YuneecCameraAEModeUnknown);
            return;
        }
        
        uint8_t value = param_ext_value.param_value[0];
        YuneecCameraAEMode aeMode = YuneecCameraAEModeUnknown;
        if (value == 0) {
            aeMode = YuneecCameraAEModeAuto;
        }else if (value == 1) {
            aeMode = YuneecCameraAEModeManual;
        }
        block(nil, aeMode);
        
    }];
    
    free(buf);
}

- (void)setISOValue:(NSInteger)isoValue block:(void (^)(NSError * _Nullable))block {
    
    NSString *paramIdString = ParamIdISOValue;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    uint32_t param_value = (uint32_t)isoValue;
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_UINT32;
    memcpy(&param_ext_set.param_id, &param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)getISOValue:(void (^)(NSError * _Nullable, NSInteger))block {
    
    NSString *paramIdString = ParamIdISOValue;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, 0);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:receivedParamIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, 0);
            return;
        }
        
        uint32_t isoValue;
        memcpy(&isoValue, param_ext_value.param_value, sizeof(isoValue));
        block(nil, isoValue);
        
    }];
    
    free(buf);
    
}

- (void)setShutterTimeValue:(YuneecRational *)shutterTime block:(void (^)(NSError * _Nullable))block {
    
    NSString *paramIdString = ParamIdShutterTime;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    float param_value = (float)(shutterTime.numerator * 1.0 / shutterTime.denominator);
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_REAL32;
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)getShutterTimeValue:(void (^)(NSError * _Nullable, YuneecRational * _Nullable))block {
    
    NSString *paramIdString = ParamIdShutterTime;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, nil);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:receivedParamIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, nil);
            return;
        }
        
        float receivedValue;
        memcpy(&receivedValue, param_ext_value.param_value, sizeof(receivedValue));
        
        NSUInteger shutterNumerator = 0;
        NSUInteger shutterDenominator = 0;
        BOOL ret = [YuneecCameraParameterConverter convertMavlinkShutterTimeValue:receivedValue
                                                                  outputNumerator:&shutterNumerator
                                                                outputDenominator:&shutterDenominator];
        
        if (ret) {
            YuneecRational *shutterTimeValue = [[YuneecRational alloc] initWithNumerator:shutterNumerator
                                                                             denominator:shutterDenominator];
            block(nil, shutterTimeValue);
        }else {
            block([NSError buildCameraErrorForCode:YuneecCameraErrorReturnDataInvalid], nil);
        }
        
    }];
    
    free(buf);
}

- (void)setExposureValue:(YuneecRational *)exposureValue block:(void (^)(NSError * _Nullable))block {
    
    NSString *paramIdString = ParamIdExposureValue;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    float param_value = (float)(exposureValue.numerator * 1.0 / exposureValue.denominator);
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_REAL32;
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)getExposureValue:(void (^)(NSError * _Nullable, YuneecRational * _Nullable))block {
    
    NSString *paramIdString = ParamIdExposureValue;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, nil);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:receivedParamIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, nil);
            return;
        }
        
        float receivedValue;
        memcpy(&receivedValue, param_ext_value.param_value, sizeof(receivedValue));
        
        NSUInteger exposureNumerator = 0;
        NSUInteger exposureDenominator = 0;
        
        BOOL ret = [YuneecCameraParameterConverter convertMavlinkExposureValue:receivedValue
                                                               outputNumerator:&exposureNumerator
                                                             outputDenominator:&exposureDenominator];
        if (ret) {
            YuneecRational *exposureValue = [[YuneecRational alloc] initWithNumerator:exposureNumerator
                                                                          denominator:exposureDenominator];
            block(nil, exposureValue);
        }else {
            block([NSError buildCameraErrorForCode:YuneecCameraErrorReturnDataInvalid], nil);
        }
        
    }];
    
    free(buf);
}

- (void)setVideoResolution:(YuneecCameraVideoResolution)videoResolution framerate:(YuneecCameraVideoFrameRate)frameRate block:(void (^)(NSError * _Nullable))block {
    
    NSString *paramIdString = ParamIdVideoResolution;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    NSInteger integerParameter = 0;
    BOOL ret = [YuneecCameraParameterConverter convertEnumVideoResolution:videoResolution enumVideoFrameRate:frameRate toMavlinkVideoParameter:&integerParameter];
    if (!ret) {
        block([NSError buildCameraErrorForCode:YuneecCameraInvalidParameter]);
        return;
    }
    
    uint8_t param_value[4] = {0x00, 0x00, 0x00, 0x00};
    param_value[0] = (uint8_t)integerParameter;
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_UINT32;
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    ret = mavlink_msg_to_send_buffer(buf, &message);
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)getVideoResolution:(void (^)(NSError * _Nullable, YuneecCameraVideoResolution, YuneecCameraVideoFrameRate))block {
    
    NSString *paramIdString = ParamIdVideoResolution;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, YuneecCameraVideoResolutionUnknown, YuneecCameraVideoFrameRateUnknown);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:receivedParamIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, YuneecCameraVideoResolutionUnknown, YuneecCameraVideoFrameRateUnknown);
            return;
        }
        
        uint32_t receivedValue;
        memcpy(&receivedValue, param_ext_value.param_value, sizeof(receivedValue));
        
        YuneecCameraVideoResolution videoResolution = YuneecCameraVideoResolutionUnknown;
        YuneecCameraVideoFrameRate videoFrameRate = YuneecCameraVideoFrameRateUnknown;
        
        BOOL ret = [YuneecCameraParameterConverter convertMavlinkVideoParameter:(NSInteger)receivedValue toEnumVideoResolution:&videoResolution enumVideoFrameRate:&videoFrameRate];
        if (ret) {
            block(nil, videoResolution, videoFrameRate);
        }else {
            block([NSError buildCameraErrorForCode:YuneecCameraErrorReturnDataInvalid], YuneecCameraVideoResolutionUnknown, YuneecCameraVideoFrameRateUnknown);
        }
        
    }];
    
    free(buf);
}

- (void)setVideoFileFormat:(YuneecCameraVideoFileFormat)videoFileFormat block:(void (^)(NSError * _Nullable))block {
    
    NSString *paramIdString = ParamIdVideoFileFormat;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    NSInteger integerParameter = 0;
    BOOL ret = [YuneecCameraParameterConverter convertEnumVideoFileFormat:videoFileFormat toIntegerVideoFileFormat:&integerParameter];
    if (!ret) {
        block([NSError buildCameraErrorForCode:YuneecCameraInvalidParameter]);
        return;
    }
    
    uint8_t param_value[4] = {0x00, 0x00, 0x00, 0x00};
    param_value[0] = (uint8_t)integerParameter;
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_UINT32;
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    ret = mavlink_msg_to_send_buffer(buf, &message);
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)getVideoFileFormat:(void (^)(NSError * _Nullable, YuneecCameraVideoFileFormat))block {
    
    NSString *paramIdString = ParamIdVideoFileFormat;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kCameraComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, YuneecCameraVideoFileFormatUnknown);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:receivedParamIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, YuneecCameraVideoFileFormatUnknown);
            return;
        }
        
        uint32_t receivedValue;
        memcpy(&receivedValue, param_ext_value.param_value, sizeof(receivedValue));
        
        YuneecCameraVideoFileFormat videoFileFormat = YuneecCameraVideoFileFormatUnknown;
        
        BOOL ret = [YuneecCameraParameterConverter convertIntegerVideoFileFormat:receivedValue toEnumVideoFileFormat:&videoFileFormat];
        if (ret) {
            block(nil, videoFileFormat);
        }else {
            block([NSError buildCameraErrorForCode:YuneecCameraErrorReturnDataInvalid], videoFileFormat);
        }
        
    }];
    
    free(buf);
}

- (void)setVideoCompressionFormat:(YuneecCameraVideoCompressionFormat)compressionFormat block:(void (^)(NSError * _Nullable))block {
    
    NSString *paramIdString = ParamIdVideoCompressionFormat;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    uint8_t param_value[4] = {0x00, 0x00, 0x00, 0x00};
    param_value[0] = (uint8_t)compressionFormat;
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_UINT32;
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint8_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)getVideoCompressionFormat:(void (^)(NSError * _Nullable, YuneecCameraVideoCompressionFormat))block {
    
    NSString *paramIdString = ParamIdVideoCompressionFormat;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, YuneecCameraVideoCompressionFormatUnknown);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:receivedParamIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, YuneecCameraVideoCompressionFormatUnknown);
            return;
        }
        
        uint32_t receivedValue;
        memcpy(&receivedValue, param_ext_value.param_value, sizeof(receivedValue));
        
        YuneecCameraVideoCompressionFormat videoCompressionFormat = (YuneecCameraVideoCompressionFormat)receivedValue;
        block(nil, videoCompressionFormat);
        
    }];
    
    free(buf);
}

- (void)setPhotoAspectRatio:(YuneecCameraPhotoAspectRatio)photoAspectRatio block:(void (^)(NSError * _Nullable))block {
    
    NSString *paramIdString = ParamIdPhotoAspectRatio;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    NSInteger integerPhotoAspectRatio = 0;
    BOOL ret = YES;
    if (self.cameraStateImp.cameraMode == YuneecCameraModePhoto) {
        ret = [YuneecCameraParameterConverter convertEnumPhotoAspectRatio:photoAspectRatio toIntegerPhotoAspectRatio:&integerPhotoAspectRatio];
    }else {
        // preset photo aspect ratio
        ret = [YuneecCameraParameterConverter convertEnumPhotoAspectRatio:photoAspectRatio toSpecialIntegerPhotoAspectRatio:&integerPhotoAspectRatio];
    }

    if (!ret) {
        block([NSError buildCameraErrorForCode:YuneecCameraInvalidParameter]);
        return;
    }
    
    uint8_t param_value[4] = {0x00, 0x00, 0x00, 0x00};
    param_value[0] = (uint8_t)integerPhotoAspectRatio;
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_UINT32;
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    ret = mavlink_msg_to_send_buffer(buf, &message);
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)getPhotoAspectRatio:(void (^)(NSError * _Nullable, YuneecCameraPhotoAspectRatio))block {
    
    NSString *paramIdString = ParamIdPhotoAspectRatio;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, YuneecCameraPhotoAspectRatioUnknown);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:receivedParamIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, YuneecCameraPhotoAspectRatioUnknown);
            return;
        }
        
        uint32_t receivedValue;
        memcpy(&receivedValue, param_ext_value.param_value, sizeof(receivedValue));
        
        YuneecCameraPhotoAspectRatio photoAspectRatio = YuneecCameraPhotoAspectRatioUnknown;
        
        BOOL ret = [YuneecCameraParameterConverter convertIntegerPhotoAspectRatio:receivedValue toEnumPhotoAspectRatio:&photoAspectRatio];
        if (ret) {
            block(nil, photoAspectRatio);
        }else {
            block([NSError buildCameraErrorForCode:YuneecCameraErrorReturnDataInvalid], photoAspectRatio);
        }
        
    }];
    
    free(buf);
}

- (void)setPhotoQuality:(YuneecCameraPhotoQuality)photoQuality block:(void (^)(NSError * _Nullable))block {
    
    NSString *paramIdString = ParamIdPhotoQuality;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    NSInteger integerPhotoQuality = 0;
    BOOL ret = [YuneecCameraParameterConverter convertEnumPhotoQuality:photoQuality
                                                 toIntegerPhotoQuality:&integerPhotoQuality];
    if (!ret) {
        block([NSError buildCameraErrorForCode:YuneecCameraInvalidParameter]);
        return;
    }
    uint8_t param_value[4] = {0x00, 0x00, 0x00, 0x00};
    param_value[0] = (uint8_t)integerPhotoQuality;
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_UINT32;
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    ret = mavlink_msg_to_send_buffer(buf, &message);
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)getPhotoQuality:(void (^)(NSError * _Nullable, YuneecCameraPhotoQuality))block {
    
    NSString *paramIdString = ParamIdPhotoQuality;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, YuneecCameraPhotoQualityUnknown);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:receivedParamIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, YuneecCameraPhotoQualityUnknown);
            return;
        }
        
        uint32_t receivedValue;
        memcpy(&receivedValue, param_ext_value.param_value, sizeof(receivedValue));
        
        YuneecCameraPhotoQuality photoQuality = YuneecCameraPhotoQualityUnknown;
        
        BOOL ret = [YuneecCameraParameterConverter convertIntegerPhotoQuality:(NSInteger)receivedValue toEnumPhotoQuality:&photoQuality];
        if (ret) {
            block(nil, photoQuality);
        }else {
            block([NSError buildCameraErrorForCode:YuneecCameraErrorReturnDataInvalid], photoQuality);
        }
        
    }];
    
    free(buf);
}

- (void)setPhotoFormat:(YuneecCameraPhotoFormat)photoFormat block:(void (^)(NSError * _Nullable))block {
    
    NSString *paramIdString = ParamIdPhotoFormat;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    NSInteger integerPhotoFormat = 0;
    BOOL ret = [YuneecCameraParameterConverter convertEnumPhotoFormat:photoFormat
                                                 toMavlinkPhotoFormat:&integerPhotoFormat];
    if (!ret) {
        block([NSError buildCameraErrorForCode:YuneecCameraInvalidParameter]);
        return;
    }
    
    uint8_t param_value[4] = {0x00, 0x00, 0x00, 0x00};
    param_value[0] = (uint8_t)integerPhotoFormat;
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_UINT32;
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    ret = mavlink_msg_to_send_buffer(buf, &message);
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)getPhotoFormat:(void (^)(NSError * _Nullable, YuneecCameraPhotoFormat))block {
    
    NSString *paramIdString = ParamIdPhotoFormat;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, YuneecCameraPhotoFormatUnknown);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:receivedParamIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, YuneecCameraPhotoFormatUnknown);
            return;
        }
        
        uint32_t receivedValue;
        memcpy(&receivedValue, param_ext_value.param_value, sizeof(receivedValue));
        
        YuneecCameraPhotoFormat photoFormat = YuneecCameraPhotoFormatUnknown;
        
        BOOL ret = [YuneecCameraParameterConverter convertMavlinkPhotoFormat:receivedValue toEnumPhotoFormat:&photoFormat];
        if (ret) {
            block(nil, photoFormat);
        }else {
            block([NSError buildCameraErrorForCode:YuneecCameraErrorReturnDataInvalid], photoFormat);
        }
        
    }];
    
    free(buf);
}

- (void)setPhotoMode:(YuneecCameraPhotoMode)photoMode amount:(NSUInteger)amount millisecond:(NSUInteger)millisecond evStep:(YuneecRational * _Nullable)evStep block:(void (^)(NSError * _Nullable))block {
    
    NSString *paramIdString = ParamIdPhotoMode;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    int16_t iAmount = 0;
    int8_t  iEvStepNumerator = 0;
    int8_t  iEvStepDenominator = 0;
    int32_t iMillisecond = 0;
    NSInteger iPhotoMode = 0;
    
    BOOL ret = [YuneecCameraParameterConverter convertEnumPhotoMode:photoMode toIntegerPhotoMode:&iPhotoMode];
    if (!ret) {
        block([NSError buildCameraErrorForCode:YuneecCameraInvalidParameter]);
        return;
    }
    
    ///< verify parameter, ignore invalid value
    if (photoMode == YuneecCameraPhotoModeSingle) {
        
    }
    else if (photoMode == YuneecCameraPhotoModeTimeLapse) {
        iMillisecond = (int32_t)millisecond;
    }
    else if (photoMode == YuneecCameraPhotoModeBurst) {
        iAmount = amount;
        iMillisecond = (int32_t)millisecond;
    }
    else if (photoMode == YuneecCameraPhotoModeAeb) {
        iAmount             = amount;
        iMillisecond        = (int32_t)millisecond;
        iEvStepNumerator    = evStep.numerator;
        iEvStepDenominator  = evStep.denominator;
    }
    
    uint8_t param_value[11] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    param_value[0] = (uint8_t)iPhotoMode;
    param_value[1] = (uint8_t)iAmount;
    param_value[2] = (uint8_t)(iAmount >> 8);
    param_value[3] = (uint8_t)iEvStepNumerator;
    param_value[4] = (uint8_t)iEvStepDenominator;
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_ENUM_END;  // FIXME: temporary type
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    ret = mavlink_msg_to_send_buffer(buf, &message);
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
    
}

- (void)getPhotoMode:(void (^)(NSError * _Nullable, YuneecCameraPhotoMode, NSUInteger, YuneecRational * _Nullable, NSUInteger))block {
    
    NSString *paramIdString = ParamIdPhotoMode;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, YuneecCameraPhotoModeUnknown, 0, nil, 0);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:receivedParamIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, YuneecCameraPhotoModeUnknown, 0, nil, 0);
            return;
        }
        
        uint8_t iPhotoMode = 0;
        int16_t iAmount = 0;
        int8_t  iEvStepNumerator = 0;
        int8_t  iEvStepDenominator = 0;
        
        memcpy(&iPhotoMode, param_ext_value.param_value, sizeof(iPhotoMode));
        memcpy(&iAmount, param_ext_value.param_value + 1, sizeof(iAmount));
        memcpy(&iEvStepNumerator, param_ext_value.param_value + 3, sizeof(iEvStepNumerator));
        memcpy(&iEvStepDenominator, param_ext_value.param_value + 4, sizeof(iEvStepDenominator));
        
        YuneecRational *evStep = [[YuneecRational alloc] initWithNumerator:iEvStepNumerator denominator:iEvStepDenominator];
        YuneecCameraPhotoMode photoMode = YuneecCameraPhotoModeUnknown;
        BOOL ret = [YuneecCameraParameterConverter convertIntegerPhotoMode:iPhotoMode toEnumPhotoMode:&photoMode];
        if (ret) {
            block(nil, photoMode, iAmount, evStep, 0);
        }else {
            block([NSError buildCameraErrorForCode:YuneecCameraErrorReturnDataInvalid], photoMode, 0, nil, 0);
        }
        
    }];
    
    free(buf);
}

- (void)setImageQualityMode:(YuneecCameraImageQualityMode)imageQualityMode block:(void (^)(NSError * _Nullable))block {
    
    NSString *paramIdString = ParamIdImageQuality;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    NSInteger integerImageQualityMode = 0;
    BOOL ret = [YuneecCameraParameterConverter convertEnumImageQualityMode:imageQualityMode                         toIntegerImageQualityMode:&integerImageQualityMode];
    
    if (!ret) {
        block([NSError buildCameraErrorForCode:YuneecCameraInvalidParameter]);
        return;
    }
    
    uint8_t param_value[4] = {0x00, 0x00, 0x00, 0x00};
    param_value[0] = (uint8_t)integerImageQualityMode;
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_UINT32;
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    ret = mavlink_msg_to_send_buffer(buf, &message);
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)getImageQualityMode:(void (^)(NSError * _Nullable, YuneecCameraImageQualityMode))block {
    
    NSString *paramIdString = ParamIdImageQuality;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, YuneecCameraImageQualityModeUnknown);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:receivedParamIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, YuneecCameraImageQualityModeUnknown);
            return;
        }
        
        uint32_t receivedValue;
        memcpy(&receivedValue, param_ext_value.param_value, sizeof(receivedValue));
        
        YuneecCameraImageQualityMode imageQualityMode = YuneecCameraImageQualityModeUnknown;
        
        BOOL ret = [YuneecCameraParameterConverter convertIntegerImageQualityMode:receivedValue toEnumImageQualityMode:&imageQualityMode];
        if (ret) {
            block(nil, imageQualityMode);
        }else {
            block([NSError buildCameraErrorForCode:YuneecCameraErrorReturnDataInvalid], imageQualityMode);
        }
        
    }];
    
    free(buf);
}

- (void)setMeterMode:(YuneecCameraMeterMode)meterMode block:(void (^)(NSError * _Nullable))block {
    
    NSString *paramIdString = ParamIdMeterMode;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    NSInteger integerMeterMode;
    BOOL ret = [YuneecCameraParameterConverter convertEnumMeterMode:meterMode
                                                 toIntegerMeterMode:&integerMeterMode];
    if (!ret) {
        block([NSError buildCameraErrorForCode:YuneecCameraInvalidParameter]);
        return;
    }
    uint8_t param_value[4] = {0x00, 0x00, 0x00, 0x00};
    param_value[0] = (uint8_t)meterMode;
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_UINT32;
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    ret = mavlink_msg_to_send_buffer(buf, &message);
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)getMeterMode:(void (^)(NSError * _Nullable, YuneecCameraMeterMode))block {
    
    NSString *paramIdString = ParamIdMeterMode;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, YuneecCameraMeterModeUnknown);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:receivedParamIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, YuneecCameraMeterModeUnknown);
            return;
        }
        
        uint32_t receivedValue;
        memcpy(&receivedValue, param_ext_value.param_value, sizeof(receivedValue));
        
        YuneecCameraMeterMode meterMode = YuneecCameraMeterModeUnknown;
        
        BOOL ret = [YuneecCameraParameterConverter convertIntegerMeterMode:receivedValue toEnumMeterMode:&meterMode];
        if (ret) {
            block(nil, meterMode);
        }else {
            block([NSError buildCameraErrorForCode:YuneecCameraErrorReturnDataInvalid], meterMode);
        }
        
    }];
    
    free(buf);
}

- (void)setMeterModeSpotCoordinate:(float)xCoordinate yCoordinate:(float)yCoordinate block:(void (^)(NSError * _Nullable))block {
    
    NSString *paramIdString = ParamIdMeterModeCoordinate;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    if (xCoordinate > 1.0 || yCoordinate > 1.0
        || xCoordinate < 0.0 || yCoordinate < 0.0) {
        block([NSError buildCameraErrorForCode:YuneecCameraInvalidParameter]);
        return;
    }
    
    uint8_t param_value[4] = {0x00, 0x00, 0x00, 0x00};
    param_value[0] = yCoordinate * 100;
    param_value[1] = xCoordinate * 100;
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_UINT32;
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
    
}

- (void)setFlickerMode:(YuneecCameraFlickerMode)flickerMode block:(void (^)(NSError * _Nullable))block {
    
    NSString *paramIdString = ParamIdFlickerMode;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    NSInteger integerFlickerMode;
    BOOL ret = [YuneecCameraParameterConverter convertEnumFlickerMode:flickerMode
                                                 toIntegerFlickerMode:&integerFlickerMode];
    if (!ret) {
        block([NSError buildCameraErrorForCode:YuneecCameraInvalidParameter]);
        return;
    }
    
    uint8_t param_value[4] = {0x00, 0x00, 0x00, 0x00};
    param_value[0] = (uint8_t)flickerMode;
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_UINT32;
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    ret = mavlink_msg_to_send_buffer(buf, &message);
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)getFlickerMode:(void (^)(NSError * _Nullable, YuneecCameraFlickerMode))block {
    
    NSString *paramIdString = ParamIdFlickerMode;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, YuneecCameraFlickerModeUnknown);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:receivedParamIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, YuneecCameraFlickerModeUnknown);
            return;
        }
        
        uint32_t receivedValue;
        memcpy(&receivedValue, param_ext_value.param_value, sizeof(receivedValue));
        
        YuneecCameraFlickerMode flickerMode = YuneecCameraFlickerModeUnknown;
        
        BOOL ret = [YuneecCameraParameterConverter convertIntegerFlickerMode:receivedValue toEnumFlickerMode:&flickerMode];
        if (ret) {
            block(nil, flickerMode);
        }else {
            block([NSError buildCameraErrorForCode:YuneecCameraErrorReturnDataInvalid], flickerMode);
        }
    }];
    
    free(buf);
}

- (void)setWhiteBalanceMode:(YuneecCameraWhiteBalanceMode)whiteBalanceMode block:(void (^)(NSError * _Nullable))block {
    
    NSString *paramIdString = ParamIdWhiteBalanceMode;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    NSInteger integerWhiteBalanceMode;
    BOOL ret = [YuneecCameraParameterConverter convertEnumWhiteBalanceMode:whiteBalanceMode
                                          toMavlinkIntegerWhiteBalanceMode:&integerWhiteBalanceMode];
    if (!ret) {
        block([NSError buildCameraErrorForCode:YuneecCameraInvalidParameter]);
        return;
    }
    
    uint8_t param_value[4] = {0x00, 0x00, 0x00, 0x00};
    param_value[0] = (uint8_t)integerWhiteBalanceMode;
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_UINT32;
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    ret = mavlink_msg_to_send_buffer(buf, &message);
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)getWhiteBalanceMode:(void (^)(NSError * _Nullable, YuneecCameraWhiteBalanceMode))block {
    
    NSString *paramIdString = ParamIdWhiteBalanceMode;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, YuneecCameraWhiteBalanceModeUnknown);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:receivedParamIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, YuneecCameraWhiteBalanceModeUnknown);
            return;
        }
        
        // NSLog(@"param_type:%d, param_count:%d, param_index:%d, param_value:%d", param_ext_value.param_type, param_ext_value.param_count, param_ext_value.param_index, param_ext_value.param_value);
        
        uint32_t receivedValue;
        memcpy(&receivedValue, param_ext_value.param_value, sizeof(receivedValue));
        
        YuneecCameraWhiteBalanceMode whiteBalanceMode = YuneecCameraWhiteBalanceModeUnknown;
        
        BOOL ret = [YuneecCameraParameterConverter convertMavlinkIntegerWhiteBalanceMode:receivedValue toEnumWhiteBalanceMode:&whiteBalanceMode];
        if (ret) {
            block(nil, whiteBalanceMode);
        }else {
            block([NSError buildCameraErrorForCode:YuneecCameraErrorReturnDataInvalid], whiteBalanceMode);
        }
    }];
    
    free(buf);
}

- (void)setManualWhileBalanceValue:(NSUInteger)manualWhiteBalanceValue block:(void (^)(NSError * _Nullable))block {
    
    NSString *paramIdString = ParamIdManualWhiteBalanceValue;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    uint16_t param_value = (uint16_t)(manualWhiteBalanceValue * 100);
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_UINT16;
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint8_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)getManualWhiteBalanceValue:(void (^)(NSError * _Nullable, NSUInteger))block {
    
    NSString *paramIdString = ParamIdManualWhiteBalanceValue;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, YuneecCameraWhiteBalanceModeUnknown);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:receivedParamIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, YuneecCameraWhiteBalanceModeUnknown);
            return;
        }
        
        // NSLog(@"param_type:%d, param_count:%d, param_index:%d, param_value:%d", param_ext_value.param_type, param_ext_value.param_count, param_ext_value.param_index, param_ext_value.param_value);
        
        uint16_t whiteBalanceValue;
        memcpy(&whiteBalanceValue, param_ext_value.param_value, sizeof(whiteBalanceValue));
        block(nil, whiteBalanceValue / 100);
        
    }];
    
    free(buf);
}

- (void)setImageFlipDegree:(YuneecCameraImageFlipDegree)imageFlipDegree block:(void (^)(NSError * _Nullable error))block {
    
    NSString *paramIdString = ParamIdImageFlipDegree;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    
    uint8_t param_value[4] = {0x00, 0x00, 0x00, 0x00};
    param_value[0] = (uint8_t)imageFlipDegree;
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_UINT32;
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)getImageFlipDegree:(void (^)(NSError * _Nullable, YuneecCameraImageFlipDegree))block {
    
    NSString *paramIdString = ParamIdImageFlipDegree;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, YuneecCameraImageFlipDegreeUnknown);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:receivedParamIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, YuneecCameraImageFlipDegreeUnknown);
            return;
        }
        
        // NSLog(@"param_type:%d, param_count:%d, param_index:%d, param_value:%d", param_ext_value.param_type, param_ext_value.param_count, param_ext_value.param_index, param_ext_value.param_value);
        
        uint32_t receivedValue;
        memcpy(&receivedValue, param_ext_value.param_value, sizeof(receivedValue));
        block(nil, (YuneecCameraImageFlipDegree)receivedValue);
        
    }];
    
    free(buf);
}

- (void)setCameraStreamEncoderStyle:(YuneecCameraStreamEncoderStyle)streamEncoderStyle block:(void (^)(NSError * _Nullable))block {
    
    NSString *paramIdString = ParamIdStreamEncoderStyle;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    NSUInteger integerStreamEncoderStype;
    BOOL ret = [YuneecCameraParameterConverter convertEnumStreamEncoderStyle:streamEncoderStyle
                                                 toIntegerStreamEncoderStyle:&integerStreamEncoderStype];
    if (!ret) {
        block([NSError buildCameraErrorForCode:YuneecCameraInvalidParameter]);
        return;
    }
    
    uint8_t param_value[4] = {0x00, 0x00, 0x00, 0x00};
    param_value[0] = (uint8_t)integerStreamEncoderStype;
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_UINT32;
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    ret = mavlink_msg_to_send_buffer(buf, &message);
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)getCameraStreamEncoderStyle:(void (^)(NSError * _Nullable, YuneecCameraStreamEncoderStyle))block {
    
    NSString *paramIdString = ParamIdStreamEncoderStyle;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    
    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));
    
    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, YuneecCameraStreamEncoderStyleUnknown);
            return ;
        }
        
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        
        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }
        
        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];
        
        if (![paramIdString isEqualToString:receivedParamIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, YuneecCameraStreamEncoderStyleUnknown);
            return;
        }
        
        // NSLog(@"param_type:%d, param_count:%d, param_index:%d, param_value:%d", param_ext_value.param_type, param_ext_value.param_count, param_ext_value.param_index, param_ext_value.param_value);
        
        uint32_t receivedValue;
        memcpy(&receivedValue, param_ext_value.param_value, sizeof(receivedValue));
        
        YuneecCameraStreamEncoderStyle streamEncoderStyle = YuneecCameraStreamEncoderStyleUnknown;
        
        BOOL ret = [YuneecCameraParameterConverter convertIntegerStreamEncoderStyle:receivedValue
                                                            toEnumtreamEncoderStyle:&streamEncoderStyle];
        if (ret) {
            block(nil, streamEncoderStyle);
        }else {
            block([NSError buildCameraErrorForCode:YuneecCameraErrorReturnDataInvalid], YuneecCameraStreamEncoderStyleUnknown);
        }
        
    }];
    
    free(buf);
}

- (void)setCameraSystemTime:(UInt64)systemTime block:(void (^)(NSError * _Nullable))block {
    
    NSString *paramIdString = ParamIdCameraSystemTime;
    
    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    UInt64 param_value = (UInt64)systemTime;
    
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));
    
    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_UINT64;
    memcpy(&param_ext_set.param_id, &param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));
    
    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)setEISMode:(NSInteger)eISValue block:(void (^)(NSError * _Nullable error))block {
    NSString *paramIdString = ParamIdEISMode;

    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));
    uint8_t param_value = (uint8_t)eISValue;

    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));

    param_ext_set.target_system         = kCameraSystemId;
    param_ext_set.target_component      = kCameraComponentId;
    param_ext_set.param_type            = MAV_PARAM_TYPE_UINT8;
    memcpy(&param_ext_set.param_id, param_id, sizeof(param_id));
    memcpy(&param_ext_set.param_value, &param_value, sizeof(param_value));

    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);

    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)

    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
    free(buf);
}

- (void)getEISMode:(void (^)(NSError * _Nullable error, NSInteger value))block {

    NSString *paramIdString = ParamIdEISMode;

    char param_id[16];
    memcpy(param_id, paramIdString.UTF8String, sizeof(param_id));

    mavlink_param_ext_request_read_t param_ext_request_read;
    memset(&param_ext_request_read, 0, sizeof(param_ext_request_read));

    param_ext_request_read.param_index = -1;
    param_ext_request_read.target_system = kCameraSystemId;
    param_ext_request_read.target_component = kCameraComponentId;
    memcpy(&param_ext_request_read.param_id, param_id, sizeof(param_id));

    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_request_read_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_request_read);

    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)

    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        [self invalidateCommonDataBlock];
        if (error) {
            block(error, -1);
            return ;
        }

        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;

        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);

        if (receive_message.msgid != MAVLINK_MSG_ID_PARAM_EXT_VALUE) {
            return;
        }

        mavlink_param_ext_value_t param_ext_value;
        mavlink_msg_param_ext_value_decode(&receive_message, &param_ext_value);
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_value.param_id];

        if (![paramIdString isEqualToString:receivedParamIdString]) {
            NSError *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            block(error, -1);
            return;
        }
        uint8_t value = param_ext_value.param_value[0];
        block(nil, value);
    }];

    free(buf);
}

- (void)formatCameraStorage:(void(^)(NSError * _Nullable error)) block {
    mavlink_command_long_t  command_long;
    memset(&command_long, 0, sizeof(mavlink_command_long_t));
    
    command_long.command            = MAV_CMD_STORAGE_FORMAT;
    command_long.target_system      = kCameraSystemId;
    command_long.target_component   = kCameraComponentId;
    
    mavlink_message_t       message;
    uint16_t package_len = mavlink_msg_command_long_encode(kCameraSystemId, kAppComponentId, &message, &command_long);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserCommonResult:data block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)resetAllCameraSettings:(void(^)(NSError * _Nullable error)) block {
    mavlink_command_long_t  command_long;
    memset(&command_long, 0, sizeof(mavlink_command_long_t));
    
    command_long.param1             = 0x01;
    command_long.command            = MAV_CMD_RESET_CAMERA_SETTINGS;
    command_long.target_system      = kCameraSystemId;
    command_long.target_component   = kCameraComponentId;
    
    mavlink_message_t       message;
    uint16_t package_len = mavlink_msg_command_long_encode(kCameraSystemId, kAppComponentId, &message, &command_long);
    
    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserCommonResult:data block:block];
        }else {
            block(error);
        }
    }];
    
    free(buf);
}

- (void)sendFirmwareMD5Value:(NSString *) md5Value
                       block:(void(^)(NSError * _Nullable error)) block
{
    mavlink_param_ext_set_t param_ext_set;
    memset(&param_ext_set, 0, sizeof(param_ext_set));

    NSString *paramIdString         = ParamIdOTAUpgrade;
    param_ext_set.param_type        = MAV_PARAM_TYPE_ENUM_END;
    strcpy(param_ext_set.param_id, paramIdString.UTF8String);
    strcpy(param_ext_set.param_value, md5Value.UTF8String);
    param_ext_set.target_system     = kCameraSystemId;
    param_ext_set.target_component  = kCameraComponentId;

    mavlink_message_t message;
    uint16_t package_len = mavlink_msg_param_ext_set_encode(kCameraSystemId, kAppComponentId, &message, &param_ext_set);

    uint8_t *buf = (uint8_t *)malloc(package_len);
    uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
#pragma unused(ret)
    NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
    free(buf);

    __weak typeof(self) weakSelf = self;
    [self sendData:sendData block:^(NSData *data, NSError *error) {
        if (data) {
            [weakSelf parserParamExtResult:data paramIdString:paramIdString block:block];
        }else {
            block(error);
        }
    }];
}

#pragma mark - Wi-Fi Name and Password

- (void)setWifiName:(NSString *) wifiName
              block:(void(^)(NSError * _Nullable error)) block
{
    sleep(0.1);
    block(nil);
}

- (void)getWifiName:(void(^)(NSError * _Nullable error,
                             NSString * _Nullable wifiName)) block
{
    sleep(0.1);
    block(nil, @"OB_123456");
}

- (void)setWifiPassword:(NSString *) wifiPassword
                  block:(void(^)(NSError * _Nullable error)) block
{
    sleep(0.1);
    block(nil);
}

#pragma mark - state

- (NSUInteger)getTotalStorageInKB {
    return self.cameraStateImp.totalStorageInKB;
}

- (NSUInteger)getFreeStorageInKB {
    return self.cameraStateImp.freeStorageInKB;
}

#pragma mark - YuneecUpgradeStateDataTransferDelegate

- (void)controllerDataTransfer:(YuneecControllerDataTransfer *) dataTransfer
    didReceiveUpgradeStateData:(NSData *) data
{
    if (self.upgradeStateDelegate != nil) {
        uint8_t *byteData = (uint8_t *)data.bytes;
        uint32_t byteLen = (uint32_t)data.length;
        
        mavlink_message_t      receive_message;
        memcpy(&receive_message, byteData, byteLen);
        if (receive_message.msgid == MAVLINK_MSG_ID_UPDATE_STATUS_FEEDBACK) {
            mavlink_update_status_feedback_t update_status_feedback;
            mavlink_msg_update_status_feedback_decode(&receive_message, &update_status_feedback);
            YuneecCameraUpgradeType type        = YuneecCameraUpgradeTypeUnknown;
            switch (update_status_feedback.module_name) {
                case 1:
                    type = YuneecCameraUpgradeTypeAutoPilot;
                    break;
                case 2:
                    type = YuneecCameraUpgradeTypeGimbal;
                    break;
                case 3:
                    type = YuneecCameraUpgradeTypeCamera;
                    break;
                case 4:
                    type = YuneecCameraUpgradeTypeRemoteController;
                    break;
                case 5:
                    type = YuneecCameraUpgradeTypeOpticalFlow;
                    break;
                case 6:
                    type = YuneecCameraUpgradeTypeDecompressFirmware;
                    break;
                default:
                    break;
            }
            YuneecCameraUpgradeStatus status    = YuneecCameraUpgradeStatusUnknown;
            switch (update_status_feedback.update_status) {
                case 0:
                    status = YuneecCameraUpgradeStatusReady;
                    break;
                case 1:
                    status = YuneecCameraUpgradeStatusInProgress;
                    break;
                case 2:
                    status = YuneecCameraUpgradeStatusFinished;
                    break;
                case 3:
                    status = YuneecCameraUpgradeStatusFailed;
                    break;
                default:
                    break;
            }
            [self.upgradeStateDelegate camera:self
                        didReceiveUpgradeType:type
                                upgradeStatus:status
                               upgradePercent:update_status_feedback.progress/100.0];
        }
    }
}

#pragma mark - send data

- (void)sendData:(NSData *)data block:(void(^)(NSData *data, NSError *error)) block {
    
    // FIXME: check camera init state before sending data
//    NSError *preError = [self preSendCommand];
//    if (preError) {
//        block(nil, preError);
//        return;
//    }
    
    self.commonDataBlock = block;
    [self.dataTransferManager.controllerDataTransfer sendData:data];
    [self startCameraTimer];
}

- (NSError *)preSendCommand {
    if (!self.isCallingInitCameraMethod && !self.isCameraInitialized) {
        return [NSError buildCameraErrorForCode:YuneecCameraErrorIsNotInitialized];
    }
    return nil;
}

#pragma mark - parser data

- (void)parserCommonResult:(NSData *)data block:(void(^)(NSError *error)) block {
    NSError *error = nil;
    if ([self parserMavlinkData:data paramIdString:nil error:&error]) {
        [self invalidateCommonDataBlock];
        block(error);
    }
}

- (void)parserParamExtResult:(NSData *)data paramIdString:(NSString *)paramIdString block:(void(^)(NSError *error)) block {
    NSError *error = nil;
    if ([self parserMavlinkData:data paramIdString:paramIdString error:&error]) {
        [self invalidateCommonDataBlock];
        block(error);
    }
}

- (void)parserRemoteControllerData:(NSData *)data {
    NSError *error = nil;
    BOOL ret = [self parserMavlinkData:data paramIdString:nil error:&error];

    if (ret && nil != error) {
        [self.delegateLock lock];
        for (id delegate in self.delegates)
        {
            if ([delegate respondsToSelector:@selector(camera:didReceiveErrorViaRemoteController:)]) {
                [delegate camera:self didReceiveErrorViaRemoteController:error];
            }
        }
        [self.delegateLock unlock];
    }
}

- (BOOL)parserMavlinkData:(NSData *)data paramIdString:(NSString *)paramIdString error:(__autoreleasing NSError **)error {
    
    BOOL ret = NO;
    
    uint8_t *byteData = (uint8_t *)data.bytes;
    uint32_t byteLen = (uint32_t)data.length;
    
    mavlink_message_t      receive_message;
    memcpy(&receive_message, byteData, byteLen);
    
    if (receive_message.msgid == MAVLINK_MSG_ID_HEARTBEAT) {
        // heart beat package
        if (!self.isCameraInitialized) {
            self.isCameraInitialized = YES;
            
            if (self.isCallingInitCameraMethod) {
                return YES;
            }
        }
    }
    else if (receive_message.msgid == MAVLINK_MSG_ID_PARAM_EXT_ACK) {
        mavlink_param_ext_ack_t param_ext_ack;
        mavlink_msg_param_ext_ack_decode(&receive_message, &param_ext_ack);
        
        NSString *receivedParamIdString = [NSString stringWithUTF8String:param_ext_ack.param_id];
        
        if (paramIdString != nil && ![paramIdString isEqualToString:receivedParamIdString]) {
            *error = [NSError buildCameraErrorForCode:YuneecCameraErrorWrongParamId];
            return YES;
        }
        
        PARAM_ACK param_result = (PARAM_ACK)param_ext_ack.param_result;
        switch (param_result) {
            case PARAM_ACK_ACCEPTED:
                ret = YES;
                break;
            case PARAM_ACK_VALUE_UNSUPPORTED:
                *error = [NSError buildCameraErrorForCode:YuneecCameraErrorIsNotSupport];
                ret = YES;
                break;
            case PARAM_ACK_FAILED:
                *error = [NSError buildCameraErrorForCode:YuneecCameraErrorFailed];
                ret = YES;
                break;
            case PARAM_ACK_IN_PROGRESS:
                *error = [NSError buildCameraErrorForCode:YuneecCameraErrorIsInProgress];
                ret = YES;
                break;
            case PARAM_ACK_ENUM_END:
                break;
            default:
                break;
        }
    }
    else if (receive_message.msgid == MAVLINK_MSG_ID_COMMAND_ACK) {
        mavlink_command_ack_t command_ack;
        mavlink_msg_command_ack_decode(&receive_message, &command_ack);
        
        MAV_RESULT param_result = (MAV_RESULT)command_ack.result;
        MAV_CMD command_id = (MAV_CMD)command_ack.command;
        
        switch (param_result) {
            case MAV_RESULT_ACCEPTED:
                if (command_id == MAV_CMD_IMAGE_START_CAPTURE) {
                    if (self.isCapturingInProgress) {
                        self.isCapturingInProgress = NO;
                        [self stopCaptureTimer];
                    }
                }
                ret = YES;
                break;
            case MAV_RESULT_UNSUPPORTED:
                *error = [NSError buildCameraErrorForCode:YuneecCameraErrorIsNotSupport];
                ret = YES;
                break;
            case MAV_RESULT_TEMPORARILY_REJECTED:
            case MAV_RESULT_DENIED:
            case MAV_RESULT_FAILED:
                *error = [NSError buildCameraErrorForCode:YuneecCameraErrorFailed];
                ret = YES;
                break;
            case MAV_RESULT_IN_PROGRESS:
                if (command_id == MAV_CMD_IMAGE_START_CAPTURE) {
                    if (!self.isCapturingInProgress) {
                        self.isCapturingInProgress = YES;
                    }
                    [self startCaptureTimer];
                }
                if (self.commonDataBlock != nil) {
                    [self startCameraTimer];
                }
                break;
            case MAV_RESULT_ENUM_END:
                break;
            default:
                break;
        }
    }
//    else if (receive_message.msgid == MAVLINK_MSG_ID_CAMERA_CAPTURE_STATUS) {
//        mavlink_camera_capture_status_t capture_status;
//        mavlink_msg_camera_capture_status_decode(&receive_message, &capture_status);
//        if (capture_status.image_status == 0 && self.isCapturingInProgress) {
//            self.isCapturingInProgress = NO;
//            [self stopCaptureTimer];
//        }
//    }
    
    return ret;
}

#pragma mark - private method

- (void)callCameraCaptureStateChangeDelegate:(BOOL)isCapturingPhoto {
    [self.delegateLock lock];
    for (id delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(camera:didChangeCameraCaptureState:)]) {
            [delegate camera:self didChangeCameraCaptureState:isCapturingPhoto];
        }
    }
    [self.delegateLock unlock];
}

- (void)invalidateCommonDataBlock {
    self.commonDataBlock = nil;
    [self stopCameraTimer];
}

- (void)startCameraTimer {
    [self stopCameraTimer];
    
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, kCameraCommandTimeout * NSEC_PER_SEC);
    dispatch_source_set_timer(timer, startTime, 0 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.commonDataBlock) {
                self.commonDataBlock(nil, [NSError buildCameraErrorForCode:YuneecCameraErrorTimeout]);
                [self invalidateCommonDataBlock];
            }
        });
    });
    dispatch_resume(timer);
    self.cameraTimer = timer;
}

- (void)stopCameraTimer {
    @synchronized(self) {
        if (self.cameraTimer) {
            dispatch_source_cancel(self.cameraTimer);
            self.cameraTimer = nil;
        }
    }
}

- (void)startCaptureTimer {
    [self stopCaptureTimer];
    
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, kCameraCaptureTimeout * NSEC_PER_SEC);
    dispatch_source_set_timer(timer, startTime, 0 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        [self stopCaptureTimer];
        self.isCapturingInProgress = NO;
    });
    dispatch_resume(timer);
    self.captureTimer = timer;
}

- (void)stopCaptureTimer {
    @synchronized(self) {
        if (self.captureTimer) {
            dispatch_source_cancel(self.captureTimer);
            self.captureTimer = nil;
        }
    }
}

#pragma mark - YuneecCameraControllerDataTransferDelegate

- (void)controllerDataTransfer:(YuneecControllerDataTransfer *) dataTransfer
          didReceiveCameraData:(NSData *) data {

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.commonDataBlock) {
            self.commonDataBlock(data, nil);
        }
        else {
            [self parserRemoteControllerData:data];
        }
    });
}

- (void)controllerDataTransfer:(YuneecControllerDataTransfer *)dataTransfer
               didReceiveError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.commonDataBlock) {
            self.commonDataBlock(nil, error);
            [self invalidateCommonDataBlock];
        }
    });
}

#pragma mark - get & set

- (void)setIsCapturingInProgress:(BOOL)isCapturingInProgress {
    if (_isCapturingInProgress != isCapturingInProgress) {
        _isCapturingInProgress = isCapturingInProgress;
        [self callCameraCaptureStateChangeDelegate:isCapturingInProgress];
    }
}

- (YuneecDataTransferManager *)dataTransferManager {
    if (_dataTransferManager == nil) {
        _dataTransferManager = [YuneecDataTransferManager sharedInstance];
        _dataTransferManager.controllerDataTransfer.cameraControllerDelegate = self;
    }
    return _dataTransferManager;
}

- (YuneecCameraStateImp *)cameraStateImp {
    if (_cameraStateImp == nil) {
        _cameraStateImp = [[YuneecCameraStateImp alloc] init];
    }
    return _cameraStateImp;
}

- (NSLock *)delegateLock {
    if (_delegateLock == nil) {
        _delegateLock = [[NSLock alloc] init];
    }
    return _delegateLock;
}

@end
