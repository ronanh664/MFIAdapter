//
//  YuneecCameraStateImp.m
//  YuneecSDK
//
//  Created by tbago on 17/1/20.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecCameraStateImp.h"

#import "YuneecCameraParameterConverter.h"

#pragma pack(push)
#pragma pack(1)
typedef struct {
    uint32_t      totalStorageCapacity;     ///< 总容量（KB）
    uint32_t      freeStorageCapacity;      ///< 剩余容量（KB）
    uint32_t      recordTime;               ///< 表示录像时长（s）
    /**
     *  表示相机状态：
     *  0--idle
     *  1--streaming
     *  2--capturing
     *  3--recording
     *  0xff --invalid
     */
    uint8_t       cameraStatus;
    /**
     *  1--video
     *  2--photo
     *  0xff--invalid
     */
    uint8_t       cameraMode;
    uint16_t      shutterNumerator;
    uint16_t      shutterDenominator;
    uint32_t      ISO;
    uint16_t      rgain;
    uint16_t      ggain;
    uint16_t      bgain;
    uint8_t       timelapseStatus;
    uint16_t      coordinateX;
    uint16_t      coordinateY;
    uint16_t      areaWidth;
    uint16_t      areaHeight;
    uint8_t       cameraScene;
    
    int8_t        evNumerator;
    uint8_t       evDenominator;
    
    int8_t        dEVNumerator;
    uint8_t       dEVDenominator;
    
}CameraStateStruct;

typedef struct {
    /**
     *  0--auto
     1--sunny
     2--sunrise
     3--sunset
     4--cloudy
     5--flucrescent
     6--incandescent
     99--manual
     100--lock
     */
    uint8_t wb;
    /**
     *  0--auto
     1--manual
     */
    uint8_t aeEnable;
    /**
     *  0--center
     1--average
     2--spot
     */
    uint8_t meteringMode;
    uint16_t photoWidth;
    uint16_t photoHeight;
    /**
     *  0x01:jpg
     0x02:raw
     0x82:dng
     0x03:jpg+raw
     0x83:jpg+dng
     */
    uint8_t photoFormat;
    /**
     *  0:single
     2:burst
     3:timelapse
     4:aeb
     */
    uint8_t photoMode;
    uint16_t photoAmount;
    /**
     *  5:EV is 0.5
     */
    int8_t   evStep;
    uint32_t intervalMS;
    uint32_t photoTimes;
    uint8_t layers;
    uint8_t pitch;
    uint8_t yaw;
    uint8_t counts;
    uint8_t allPic;
    uint8_t takenPic;
    /**
     *  0 -- undo
     1--photoing
     2 --done
     */
    uint8_t takenAction;
    /**
     *  0--idle
     1--doing
     */
    uint8_t timerPhotoSta;
    /**
     *  0 -- closed
     1--opened
     */
    uint8_t audioSwitch;
} CameraAdditionalStateStruct;

typedef struct
{
    uint16_t	x;
    uint16_t	y;
    uint16_t	width;
    uint16_t	height;
    uint16_t	track;//0.01
    uint16_t	learn;//0.01
    
    uint16_t	tracked;
    uint16_t    detected;
    uint32_t    lost_num;
    uint16_t    ot_stop;
    
    uint32_t    model_var;
    uint32_t    real_var;
    
    uint32_t    candidate_box_num;
    uint32_t    detect_pass_var_num;
    uint32_t    detect_pass_ferns_num;
    uint32_t    detect_pass_nn_num;
    uint16_t    positive_sample_num;
    uint16_t    negative_sample_num;
    
    uint16_t    model_w_scale;
    uint16_t    model_h_scale;
    uint16_t    real_w_scale;
    uint16_t    real_h_scale;
    //
    uint16_t	omwIw_ratio_valid;
    uint16_t	omhIh_ratio_valid;
    uint16_t	om_ratio_valid;
    uint16_t	ot_valid_range_far;
    uint16_t	ot_valid_range_near ;
    uint16_t	invalid_real_range_far_count;
    uint16_t	invalid_real_range_near_count;
    uint16_t	run_time_per_frame;
    uint16_t	distance_camera_to_image_center;
    uint16_t	real_pitch_angle;
}CameraCVStruct;

typedef struct {
    uint8_t     iqType;
    uint16_t    videoWidth;
    uint16_t    videoHeight;
    uint8_t     videoFps;
    uint16_t    rtspResW;
    uint16_t    rtspResH;
    uint8_t     rtspFps;
    uint8_t     photoQuality;
    uint8_t     flickerMode;
    uint8_t     manualWb;
    uint8_t     encodeMode;
    uint8_t     sysMode;
    uint8_t     photoRatio;
    uint8_t     boardTemperature;
    uint32_t    reserved;
} CameraExtraParamStruct;

typedef struct {
    uint32_t    photo_amount_left;
    uint32_t    record_time_left;
    uint8_t     file_format;
    uint8_t     brightness;
    uint8_t     contrast;
    uint8_t     saturation;
    uint8_t     hue;
    uint8_t     sharpness;
    uint8_t     received[58];
} CameraNewParamStruct;

#pragma pack(pop)

@interface YuneecCameraStateImp()

@property (nonatomic) BOOL  cameraStateChanged;

@property (nonatomic, readwrite) NSUInteger                     totalStorageInKB;
@property (nonatomic, readwrite) NSUInteger                     freeStorageInKB;
@property (nonatomic, readwrite) YuneecCameraMode               cameraMode;
@property (nonatomic, readwrite) BOOL                           isRecordingVideo;
@property (nonatomic, readwrite) NSUInteger                     videoRecordTimeInSeconds;
@property (nonatomic, readwrite) BOOL                           isCapturingPhoto;
@property (nonatomic, readwrite) BOOL                           isCapturingPhotoTimelapse;
@property (nonatomic, readwrite) NSUInteger                     remainingPhotoCount;
@property (nonatomic, readwrite) NSUInteger                     remainingRecordTime;

@property (nonatomic, readwrite) YuneecCameraVideoResolution    videoResolution;
@property (nonatomic, readwrite) YuneecCameraVideoFrameRate     videoFrameRate;
@property (nonatomic, readwrite) YuneecCameraVideoFileFormat    videoFileFormat;

@property (nonatomic, readwrite) YuneecCameraPhotoResolution    photoResolution;
@property (nonatomic, readwrite) YuneecCameraPhotoAspectRatio   photoAspectRatio;
@property (nonatomic, readwrite) YuneecCameraPhotoFormat        photoFormat;
@property (nonatomic, readwrite) YuneecCameraPhotoQuality       photoQuality;
@property (nonatomic, readwrite) YuneecCameraPhotoMode          photoMode;
@property (nonatomic, readwrite) NSUInteger                     photoModeAmount;
@property (nonatomic, readwrite) NSUInteger                     photoModeMillisecond;
@property (nonatomic, readwrite) YuneecRational                 *photoModeEvStep;

@property (nonatomic, readwrite) YuneecCameraWhiteBalanceMode   whiteBalanceMode;

@property (nonatomic, readwrite) YuneecCameraAEMode             aeMode;
@property (nonatomic, readwrite) YuneecRational *               exposureValue;
@property (nonatomic, readwrite) YuneecRational *               shutterTime;
@property (nonatomic, readwrite) NSInteger                      isoValue;

@property (nonatomic, readwrite) YuneecCameraFlickerMode        flickerMode;

@property (nonatomic, readwrite) YuneecCameraImageQualityMode   imageQualityMode;

@property (nonatomic, readwrite) YuneecCameraMeterMode          meterMode;

@property (nonatomic, readwrite) NSUInteger                     boardTemperature;

@property (nonatomic, readwrite) YuneecCameraPanoramaState      panoramaState;
@property (nonatomic, readwrite) NSUInteger                     panoramaTotalPicture;
@property (nonatomic, readwrite) NSUInteger                     panoramaTakenPicture;

@property (strong, nonatomic) NSMutableArray                    *innerHistogramDataArray;
@end

@implementation YuneecCameraStateImp

@synthesize totalStorageInKB            = _totalStorageInKB;
@synthesize freeStorageInKB             = _freeStorageInKB;
@synthesize cameraMode                  = _cameraMode;
@synthesize isRecordingVideo            = _isRecordingVideo;
@synthesize videoRecordTimeInSeconds    = _videoRecordTimeInSeconds;
@synthesize isCapturingPhoto            = _isCapturingPhoto;
@synthesize isCapturingPhotoTimelapse   = _isCapturingPhotoTimelapse;
@synthesize remainingPhotoCount         = _remainingPhotoCount;
@synthesize remainingRecordTime         = _remainingRecordTime;

@synthesize videoResolution             = _videoResolution;
@synthesize videoFrameRate              = _videoFrameRate;
@synthesize videoFileFormat             = _videoFileFormat;

@synthesize photoResolution             = _photoResolution;
@synthesize photoAspectRatio            = _photoAspectRatio;
@synthesize photoFormat                 = _photoFormat;
@synthesize photoQuality                = _photoQuality;
@synthesize photoMode                   = _photoMode;
@synthesize photoModeAmount             = _photoModeAmount;
@synthesize photoModeMillisecond        = _photoModeMillisecond;
@synthesize photoModeEvStep             = _photoModeEvStep;

@synthesize whiteBalanceMode            = _whiteBalanceMode;

@synthesize aeMode                      = _aeMode;
@synthesize exposureValue               = _exposureValue;
@synthesize shutterTime                 = _shutterTime;
@synthesize isoValue                    = _isoValue;

@synthesize flickerMode                 = _flickerMode;
@synthesize imageQualityMode            = _imageQualityMode;
@synthesize meterMode                   = _meterMode;

@synthesize boardTemperature            = _boardTemperature;

@synthesize panoramaState               = _panoramaState;
@synthesize panoramaTotalPicture        = _panoramaTotalPicture;
@synthesize panoramaTakenPicture        = _panoramaTakenPicture;

- (instancetype)init {
    self = [super init];
    if (self) {
        _totalStorageInKB           = 0;
        _freeStorageInKB            = 0;
        _cameraMode                 = YuneecCameraModeUnknown;
        
        _isRecordingVideo           = NO;
        _videoRecordTimeInSeconds   = 0;
        
        _isCapturingPhoto           = NO;
        _isCapturingPhotoTimelapse  = NO;
        
        _videoResolution            = YuneecCameraVideoResolutionUnknown;
        _videoFrameRate             = YuneecCameraVideoFrameRateUnknown;
        _videoFileFormat            = YuneecCameraVideoFileFormatUnknown;
        
        _photoResolution            = YuneecCameraPhotoResolutionUnknown;
        _photoAspectRatio           = YuneecCameraPhotoAspectRatioUnknown;
        
        _photoFormat                = YuneecCameraPhotoFormatUnknown;
        
        _photoQuality               = YuneecCameraPhotoQualityUnknown;
        
        _photoMode                  = YuneecCameraPhotoModeUnknown;
        _photoModeAmount            = 0;
        _photoModeMillisecond       = 0;
        
        _whiteBalanceMode           = YuneecCameraWhiteBalanceModeUnknown;
        
        _aeMode                     = YuneecCameraAEModeUnknown;
        _isoValue                   = 0;
        
        _flickerMode                = YuneecCameraFlickerModeUnknown;
        
        _imageQualityMode           = YuneecCameraImageQualityModeUnknown;
        
        _meterMode                  = YuneecCameraMeterModeUnknown;
        
        _boardTemperature           = 0;
        
        _panoramaState              = YuneecCameraPanoramaStateNone;
        _panoramaTotalPicture       = 0;
        _panoramaTakenPicture       = 0;
    }
    return self;
}

- (BOOL)parserCameraStateData:(NSData *) cameraStateData {
///< reset state
    self.cameraStateChanged = NO;
    [self.innerHistogramDataArray removeAllObjects];
    
    uint8_t *receivedByte = (uint8_t *)[cameraStateData bytes];
    uint32_t dataIndex = 0;
    while (dataIndex + 4 < cameraStateData.length)
    {
        uint16_t dataType = (receivedByte[dataIndex]<<8) + receivedByte[dataIndex + 1];
        uint16_t dataLength = (receivedByte[dataIndex + 2]<<8) + receivedByte[dataIndex + 3];
        if (dataType == 1)      ///< 相机状态信息
        {
            if (dataLength >= sizeof(CameraStateStruct)) {
                CameraStateStruct cameraStateStruct;
                memcpy(&cameraStateStruct, receivedByte+dataIndex+4, sizeof(CameraStateStruct));
                
                cameraStateStruct.totalStorageCapacity    = ntohl(cameraStateStruct.totalStorageCapacity);
                cameraStateStruct.freeStorageCapacity     = ntohl(cameraStateStruct.freeStorageCapacity);
                cameraStateStruct.recordTime              = ntohl(cameraStateStruct.recordTime);
                cameraStateStruct.shutterNumerator        = ntohs(cameraStateStruct.shutterNumerator);
                cameraStateStruct.shutterDenominator      = ntohs(cameraStateStruct.shutterDenominator);
                cameraStateStruct.ISO                     = ntohl(cameraStateStruct.ISO);
                
                cameraStateStruct.rgain                   = ntohs(cameraStateStruct.rgain);
                cameraStateStruct.ggain                   = ntohs(cameraStateStruct.ggain);
                cameraStateStruct.bgain                   = ntohs(cameraStateStruct.bgain);
                
                cameraStateStruct.coordinateX             = ntohs(cameraStateStruct.coordinateX);
                cameraStateStruct.coordinateY             = ntohs(cameraStateStruct.coordinateY);
                cameraStateStruct.areaWidth               = ntohs(cameraStateStruct.areaWidth);
                cameraStateStruct.areaHeight              = ntohs(cameraStateStruct.areaHeight);
                
                [self syncCameraStateInfo:&cameraStateStruct];
            }
        }
        else if (dataType == 2)         ///< 直方图数据
        {
            for (uint32_t i = 0; i < dataLength; i++)
            {
                uint8_t value = receivedByte[dataIndex + 4 + i];
                [self.innerHistogramDataArray addObject:@(value)];
            }
        }
        else if (dataType == 3)         ///< Camera ohter data
        {
            if (dataLength >= sizeof(CameraAdditionalStateStruct))
            {
                CameraAdditionalStateStruct cameraAdditionalState;
                memcpy(&cameraAdditionalState, receivedByte+dataIndex+4, sizeof(CameraAdditionalStateStruct));
                
                cameraAdditionalState.photoWidth    = ntohs(cameraAdditionalState.photoWidth);
                cameraAdditionalState.photoHeight   = ntohs(cameraAdditionalState.photoHeight);
                cameraAdditionalState.photoAmount   = ntohs(cameraAdditionalState.photoAmount);
                cameraAdditionalState.intervalMS    = ntohl(cameraAdditionalState.intervalMS);
                cameraAdditionalState.photoTimes    = ntohl(cameraAdditionalState.photoTimes);
                
                [self syncCameraAdditionalStateInfo:&cameraAdditionalState];
            }
        }
        else if (dataType == 5)
        {
            if (dataLength >= sizeof(CameraExtraParamStruct)) {
                CameraExtraParamStruct cameraExtraState;
                memcpy(&cameraExtraState, receivedByte+dataIndex+4, sizeof(CameraExtraParamStruct));
                
                cameraExtraState.videoWidth     = ntohs(cameraExtraState.videoWidth);
                cameraExtraState.videoHeight    = ntohs(cameraExtraState.videoHeight);
                cameraExtraState.rtspResW       = ntohs(cameraExtraState.rtspResW);
                cameraExtraState.rtspResH       = ntohs(cameraExtraState.rtspResH);
                
                [self syncCameraExtraParamInfo:&cameraExtraState];
            }
        }
        else if (dataType == 8) {
            if (dataLength >= sizeof(CameraNewParamStruct)) {
                CameraNewParamStruct cameraNewParamStruct;
                memcpy(&cameraNewParamStruct, receivedByte+dataIndex+4, sizeof(CameraNewParamStruct));
                
                cameraNewParamStruct.photo_amount_left = ntohl(cameraNewParamStruct.photo_amount_left);
                cameraNewParamStruct.record_time_left = ntohl(cameraNewParamStruct.record_time_left);
                
                [self syncCameraNewParamInfo:&cameraNewParamStruct];
            }
        }
        else if (dataType == 0x200)     ///< CV struct
        {
            if (dataLength >= sizeof(CameraCVStruct))
            {
                CameraCVStruct  cvStruct;
                memcpy(&cvStruct, receivedByte+dataIndex+4, sizeof(CameraCVStruct));
                
                cvStruct.x                  = ntohs(cvStruct.x);
                cvStruct.y                  = ntohs(cvStruct.y);
                cvStruct.width              = ntohs(cvStruct.width);
                cvStruct.height             = ntohs(cvStruct.height);
                cvStruct.track              = ntohs(cvStruct.track);
                cvStruct.learn              = ntohs(cvStruct.learn);
                
                if (cvStruct.x == 0 || cvStruct.y == 0
                    || cvStruct.width == 0 || cvStruct.height == 0) {
                
                }
                else {
                }
            }
        }
        dataIndex += 4 + dataLength + 1;        ///< 4header + datalength + 1crc
    }
    
    return self.cameraStateChanged;
}

- (void)syncCameraStateInfo:(CameraStateStruct *) cameraStateStruct {
    self.cameraStateChanged = NO;
    
    self.totalStorageInKB = cameraStateStruct->totalStorageCapacity;
    
    self.freeStorageInKB  = cameraStateStruct->freeStorageCapacity;
    
    if (cameraStateStruct->cameraMode == 1) {
        self.cameraMode = YuneecCameraModeVideo;
    }
    else if (cameraStateStruct->cameraMode == 0) {
        self.cameraMode = YuneecCameraModePhoto;
    }
    else {
        self.cameraMode = YuneecCameraModeUnknown;
    }
    
    if (cameraStateStruct->cameraStatus == 1) {
        self.isRecordingVideo = YES;
    }
    else {
        self.isRecordingVideo = NO;
    }
    self.videoRecordTimeInSeconds = cameraStateStruct->recordTime;
    
    if (cameraStateStruct->cameraStatus == 2) {
        self.isCapturingPhoto = YES;
    }
    else {
        self.isCapturingPhoto = NO;
    }
    
    self.exposureValue = [[YuneecRational alloc] initWithNumerator:cameraStateStruct->evNumerator
                                                       denominator:cameraStateStruct->evDenominator];
    
    self.isoValue   = cameraStateStruct->ISO;
    NSUInteger outputNumerator;
    NSUInteger outputDenominator;
    [YuneecCameraParameterConverter correctShutterTimeValue:cameraStateStruct->shutterNumerator
                                           inputDenominator:cameraStateStruct->shutterDenominator
                                            outputNumerator:&outputNumerator
                                          outputDenominator:&outputDenominator];
    
    self.shutterTime = [[YuneecRational alloc] initWithNumerator:outputNumerator
                                                     denominator:outputDenominator];
}

- (void)syncCameraAdditionalStateInfo:(CameraAdditionalStateStruct *) cameraAdditionalStateStruct {
    YuneecCameraWhiteBalanceMode enumWhiteBalanceMode;
    BOOL ret = [YuneecCameraParameterConverter convertMavlinkIntegerWhiteBalanceMode:cameraAdditionalStateStruct->wb                       toEnumWhiteBalanceMode:&enumWhiteBalanceMode];
    
    if (ret) {
        self.whiteBalanceMode = enumWhiteBalanceMode;
    }
    
    YuneecCameraAEMode enumAEMode;
    ret = [YuneecCameraParameterConverter convertIntegerAEMode:cameraAdditionalStateStruct->aeEnable
                                                  toEnumAEMode:&enumAEMode];
    if (ret) {
        self.aeMode = enumAEMode;
    }
    
    YuneecCameraPhotoResolution enumPhotoResolution;
    ret = [YuneecCameraParameterConverter convertPhotoWidth:cameraAdditionalStateStruct->photoWidth
                                                photoHeight:cameraAdditionalStateStruct->photoHeight
                                      toEnumPhotoResolution:&enumPhotoResolution];
    if (ret) {
        self.photoResolution = enumPhotoResolution;
    }
    
    YuneecCameraPhotoFormat enumPhotoFormat;
    ret = [YuneecCameraParameterConverter convertMavlinkPhotoFormat:cameraAdditionalStateStruct->photoFormat
                                                  toEnumPhotoFormat:&enumPhotoFormat];
    if (ret) {
        self.photoFormat = enumPhotoFormat;
    }
    
    YuneecCameraPhotoMode enumPhotoMode;
    ret = [YuneecCameraParameterConverter convertIntegerPhotoMode:cameraAdditionalStateStruct->photoMode
                                                  toEnumPhotoMode:&enumPhotoMode];
    if (ret) {
        self.photoMode = enumPhotoMode;
    }
    self.photoModeAmount        = cameraAdditionalStateStruct->photoAmount;
    self.photoModeMillisecond   = cameraAdditionalStateStruct->intervalMS;
    self.photoModeEvStep        = [[YuneecRational alloc] initWithNumerator:cameraAdditionalStateStruct->evStep denominator:10];
    
    self.isCapturingPhotoTimelapse = cameraAdditionalStateStruct->timerPhotoSta;
    
    YuneecCameraMeterMode enumMeterMode;
    ret = [YuneecCameraParameterConverter convertIntegerMeterMode:cameraAdditionalStateStruct->meteringMode
                                                  toEnumMeterMode:&enumMeterMode];
    if (ret) {
        self.meterMode = enumMeterMode;
    }
    
    if (cameraAdditionalStateStruct->takenAction == 0) {
        self.panoramaState = YuneecCameraPanoramaStateNone;
    }
    else if (cameraAdditionalStateStruct->takenAction == 1) {
        self.panoramaState = YuneecCameraPanoramaStateTakingPhoto;
    }
    else if (cameraAdditionalStateStruct->takenAction == 2) {
        self.panoramaState = YuneecCameraPanoramaStateTakenDone;
    }
    else if (cameraAdditionalStateStruct->takenAction == 3) {
        self.panoramaState = YuneecCameraPanoramaStateGimbalUnexceptedStop;
    }
    else if (cameraAdditionalStateStruct->takenAction == 4) {
        self.panoramaState = YuneecCameraPanoramaStateCameraUnexceptedStop;
    }
    else if (cameraAdditionalStateStruct->takenAction == 5) {
        self.panoramaState = YuneecCameraPanoramaStateInitFailed;
    }
    
    self.panoramaTotalPicture = cameraAdditionalStateStruct->allPic;
    self.panoramaTakenPicture = cameraAdditionalStateStruct->takenPic;
}


- (void)syncCameraExtraParamInfo:(CameraExtraParamStruct *) cameraExtraParamStruct {
    YuneecCameraVideoResolution enumVideoResolution;
    BOOL ret = [YuneecCameraParameterConverter convertVideoWidth:cameraExtraParamStruct->videoWidth
                                                     videoHeight:cameraExtraParamStruct->videoHeight
                                           toEnumVideoResolution:&enumVideoResolution];
    if (ret) {
        self.videoResolution = enumVideoResolution;
    }
    
    YuneecCameraVideoFrameRate enumVideoFrameRate;
    ret = [YuneecCameraParameterConverter convertIntegerVideoFrameRate:cameraExtraParamStruct->videoFps
                                                  toEnumVideoFrameRate:&enumVideoFrameRate];
    if (ret) {
        self.videoFrameRate = enumVideoFrameRate;
    }
    
    YuneecCameraPhotoQuality enumPhotoQuality;
    ret = [YuneecCameraParameterConverter convertIntegerPhotoQuality:cameraExtraParamStruct->photoQuality
                                                  toEnumPhotoQuality:&enumPhotoQuality];
    if (ret) {
        self.photoQuality = enumPhotoQuality;
    }
    
    YuneecCameraFlickerMode enumFlickerMode;
    ret = [YuneecCameraParameterConverter convertIntegerFlickerMode:cameraExtraParamStruct->flickerMode
                                                  toEnumFlickerMode:&enumFlickerMode];
    if (ret) {
        self.flickerMode = enumFlickerMode;
    }
    
    YuneecCameraImageQualityMode enumImageQualityMode;
    ret = [YuneecCameraParameterConverter convertIntegerImageQualityMode:cameraExtraParamStruct->iqType
                                                  toEnumImageQualityMode:&enumImageQualityMode];
    if (ret) {
        self.imageQualityMode = enumImageQualityMode;
    }
    
    YuneecCameraPhotoAspectRatio enumPhotoAspectRatio;
    ret = [YuneecCameraParameterConverter convertIntegerPhotoAspectRatio:cameraExtraParamStruct->photoRatio
                                                  toEnumPhotoAspectRatio:&enumPhotoAspectRatio];
    if (ret) {
        self.photoAspectRatio = enumPhotoAspectRatio;
    }
    
    self.boardTemperature = cameraExtraParamStruct->boardTemperature;
}

- (void)syncCameraNewParamInfo:(CameraNewParamStruct *) cameraNewParamStruct {
    BOOL ret = NO;
    YuneecCameraVideoFileFormat enumVideoFileFormat;
    ret = [YuneecCameraParameterConverter convertIntegerVideoFileFormat:cameraNewParamStruct->file_format
                                                  toEnumVideoFileFormat:&enumVideoFileFormat];
    if (ret) {
        self.videoFileFormat = enumVideoFileFormat;
    }
    
    self.remainingPhotoCount = cameraNewParamStruct->photo_amount_left;
    self.remainingRecordTime = cameraNewParamStruct->record_time_left;
}

#pragma mark - get & set

- (void)setTotalStorageInKB:(NSUInteger)totalStorageInKB {
    if (_totalStorageInKB != totalStorageInKB) {
        _totalStorageInKB = totalStorageInKB;
        self.cameraStateChanged = YES;
    }
}

- (void)setFreeStorageInKB:(NSUInteger)freeStorageInKB {
    if (_freeStorageInKB != freeStorageInKB) {
        _freeStorageInKB = freeStorageInKB;
        self.cameraStateChanged = YES;
    }
}

- (void)setCameraMode:(YuneecCameraMode)cameraMode {
    if (_cameraMode != cameraMode) {
        _cameraMode = cameraMode;
        self.cameraStateChanged = YES;
    }
}

- (void)setIsRecordingVideo:(BOOL)isRecordingVideo {
    if (_isRecordingVideo != isRecordingVideo) {
        _isRecordingVideo = isRecordingVideo;
        self.cameraStateChanged = YES;
    }
}

- (void)setVideoRecordTimeInSeconds:(NSUInteger)videoRecordTimeInSeconds {
    if (_videoRecordTimeInSeconds != videoRecordTimeInSeconds) {
        _videoRecordTimeInSeconds = videoRecordTimeInSeconds;
        self.cameraStateChanged = YES;
    }
}

- (void)setIsCapturingPhoto:(BOOL)isCapturingPhoto {
    if (_isCapturingPhoto != isCapturingPhoto) {
        _isCapturingPhoto = isCapturingPhoto;
        self.cameraStateChanged = YES;
    }
}

- (void)setIsCapturingPhotoTimelapse:(BOOL)isCapturingPhotoTimelapse {
    if (_isCapturingPhotoTimelapse != isCapturingPhotoTimelapse) {
        _isCapturingPhotoTimelapse = isCapturingPhotoTimelapse;
        self.cameraStateChanged = YES;
    }
}

- (void)setVideoResolution:(YuneecCameraVideoResolution)videoResolution {
    if (_videoResolution != videoResolution) {
        _videoResolution = videoResolution;
        self.cameraStateChanged = YES;
    }
}

- (void)setVideoFrameRate:(YuneecCameraVideoFrameRate)videoFrameRate {
    if (_videoFrameRate != videoFrameRate) {
        _videoFrameRate = videoFrameRate;
        self.cameraStateChanged = YES;
    }
}

- (void)setVideoFileFormat:(YuneecCameraVideoFileFormat)videoFileFormat {
    if (_videoFileFormat != videoFileFormat) {
        _videoFileFormat = videoFileFormat;
        self.cameraStateChanged = YES;
    }
}

- (void)setPhotoResolution:(YuneecCameraPhotoResolution)photoResolution {
    if (_photoResolution != photoResolution) {
        _photoResolution = photoResolution;
        self.cameraStateChanged = YES;
    }
}

- (void)setPhotoAspectRatio:(YuneecCameraPhotoAspectRatio)photoAspectRatio {
    if (_photoAspectRatio != photoAspectRatio) {
        _photoAspectRatio = photoAspectRatio;
        self.cameraStateChanged = YES;
    }
}

- (void)setPhotoFormat:(YuneecCameraPhotoFormat)photoFormat {
    if (_photoFormat != photoFormat) {
        _photoFormat = photoFormat;
        self.cameraStateChanged = YES;
    }
}

- (void)setPhotoQuality:(YuneecCameraPhotoQuality)photoQuality {
    if (_photoQuality != photoQuality) {
        _photoQuality = photoQuality;
        self.cameraStateChanged = YES;
    }
}
- (void)setPhotoMode:(YuneecCameraPhotoMode)photoMode {
    if (_photoMode != photoMode) {
        _photoMode = photoMode;
        self.cameraStateChanged = YES;
    }
}

- (void)setPhotoModeAmount:(NSUInteger)photoModeAmount {
    if (_photoModeAmount != photoModeAmount) {
        _photoModeAmount = photoModeAmount;
        self.cameraStateChanged = YES;
    }
}

- (void)setPhotoModeMillisecond:(NSUInteger)photoModeMillisecond {
    if (_photoModeMillisecond != photoModeMillisecond) {
        _photoModeMillisecond = photoModeMillisecond;
        self.cameraStateChanged = YES;
    }
}

- (void)setPhotoModeEvStep:(YuneecRational *)photoModeEvStep {
    if (![_photoModeEvStep equalValue:_photoModeEvStep]) {
        _photoModeEvStep = photoModeEvStep;
        self.cameraStateChanged = YES;
    }
}

- (void)setWhiteBalanceMode:(YuneecCameraWhiteBalanceMode)whiteBalanceMode {
    if (_whiteBalanceMode != whiteBalanceMode) {
        _whiteBalanceMode = whiteBalanceMode;
        self.cameraStateChanged = YES;
    }
}

- (void)setAeMode:(YuneecCameraAEMode)aeMode {
    if (_aeMode != aeMode) {
        _aeMode = aeMode;
        self.cameraStateChanged = YES;
    }
}

- (void)setExposureValue:(YuneecRational *)exposureValue {
    if (![_exposureValue equalValue:exposureValue]) {
        _exposureValue = exposureValue;
        self.cameraStateChanged = YES;
    }
}

- (void)setShutterTime:(YuneecRational *)shutterTime {
    if (![_shutterTime equalValue:shutterTime]) {
        _shutterTime = shutterTime;
        self.cameraStateChanged = YES;
    }
}

- (void)setIsoValue:(NSInteger)isoValue {
    if (_isoValue != isoValue) {
        _isoValue = isoValue;
        self.cameraStateChanged = YES;
    }
}

- (void)setFlickerMode:(YuneecCameraFlickerMode)flickerMode {
    if (_flickerMode != flickerMode) {
        _flickerMode = flickerMode;
        self.cameraStateChanged = YES;
    }
}

- (void)setImageQualityMode:(YuneecCameraImageQualityMode)imageQualityMode {
    if (_imageQualityMode != imageQualityMode) {
        _imageQualityMode = imageQualityMode;
        self.cameraStateChanged = YES;
    }
}

- (void)setMeterMode:(YuneecCameraMeterMode)meterMode {
    if (_meterMode != meterMode) {
        _meterMode = meterMode;
        self.cameraStateChanged = YES;
    }
}

- (void)setBoardTemperature:(NSUInteger)boardTemperature {
    if (_boardTemperature != boardTemperature) {
        _boardTemperature = boardTemperature;
        self.cameraStateChanged = YES;
    }
}

- (void)setPanoramaState:(YuneecCameraPanoramaState)panoramaState {
    if (_panoramaState != panoramaState) {
        _panoramaState = panoramaState;
        self.cameraStateChanged = YES;
    }
}

- (NSArray *)histogramDataArray {
    return _innerHistogramDataArray;
}

- (NSMutableArray *)innerHistogramDataArray {
    if (_innerHistogramDataArray == nil) {
        _innerHistogramDataArray = [[NSMutableArray alloc] init];
    }
    return _innerHistogramDataArray;
}
@end
