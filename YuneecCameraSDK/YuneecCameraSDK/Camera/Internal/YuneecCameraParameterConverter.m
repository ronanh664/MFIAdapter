//
//  YuneecCameraParameterConverter.m
//  YuneecSDK
//
//  Created by tbago on 2017/6/19.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecCameraParameterConverter.h"

@implementation YuneecCameraParameterConverter

+ (YuneecCameraType)convertIntegerCameraTypeToEnumCameraType:(uint8_t) integerCameraType {
    YuneecCameraType cameraType = YuneecCameraTypeUnknown;
    switch (integerCameraType)
    {
        case 1:
            cameraType = YuneecCameraTypeBreeze;
            break;
        case 2:
            cameraType = YuneecCameraTypeCGOPro;
            break;
        case 3:
            cameraType = YuneecCameraTypeCGO3Plus;
            break;
        case 4:
            cameraType = YuneecCameraTypeCGOET;
            break;
        case 5:
            cameraType = YuneecCameraTypeCGOT;
            break;
        case 6:
            cameraType = YuneecCameraTypeV30;
            break;
        case 7:
            cameraType = YuneecCameraTypeFirebird;
            break;
        case 8:
            cameraType = YuneecCameraTypeQ400;
            break;
        case 9:
            cameraType = YuneecCameraTypeBreeze2;
            break;
        case 10:
            cameraType = YuneecCameraTypeE50;
            break;
        case 11:
            cameraType = YuneecCameraTypeE90;
            break;
        case 12:
            cameraType = YuneecCameraTypeE10T;
            break;
        case 13:
            cameraType = YuneecCameraTypeE30Z;
            break;
        case 14:
            cameraType = YuneecCameraTypeHDRacer;
            break;
        default:
            break;
    }
    return cameraType;
}

+ (BOOL)convertEnumVideoResolution:(YuneecCameraVideoResolution) videoResolution
                        videoWidth:(NSInteger *) videoWidth
                      videoHheight:(NSInteger *) videoHeight
{
    BOOL ret = YES;
    switch (videoResolution)
    {
        case YuneecCameraVideoResolution4096x2160:
            *videoWidth = 4096;
            *videoHeight = 2160;
            break;
        case YuneecCameraVideoResolution3840x2160:
            *videoWidth = 3840;
            *videoHeight = 2160;
            break;
        case YuneecCameraVideoResolution2720x1530:
            *videoWidth = 2720;
            *videoHeight = 1530;
            break;
        case YuneecCameraVideoResolution2704x1520:
            *videoWidth = 2704;
            *videoHeight = 2160;
            break;
        case YuneecCameraVideoResolution2560x1440:
            *videoWidth = 2560;
            *videoHeight = 1440;
            break;
        case YuneecCameraVideoResolution1920x1080:
            *videoWidth = 1920;
            *videoHeight = 1080;
            break;
        case YuneecCameraVideoResolution1280x720:
            *videoWidth = 1280;
            *videoHeight = 720;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertVideoWidth:(NSInteger) videoWidth
              videoHeight:(NSInteger) videoHeight
    toEnumVideoResolution:(YuneecCameraVideoResolution *) enumVideoResolution
{
    BOOL ret = YES;
    switch(videoWidth)
    {
        case 4096:
            *enumVideoResolution = YuneecCameraVideoResolution4096x2160;
            break;
        case 3840:
            *enumVideoResolution = YuneecCameraVideoResolution3840x2160;
            break;
        case 2720:
            *enumVideoResolution = YuneecCameraVideoResolution2720x1530;
            break;
        case 2704:
            *enumVideoResolution = YuneecCameraVideoResolution2704x1520;
            break;
        case 2560:
            *enumVideoResolution = YuneecCameraVideoResolution2560x1440;
            break;
        case 1920:
            *enumVideoResolution = YuneecCameraVideoResolution1920x1080;
            break;
        case 1280:
            *enumVideoResolution = YuneecCameraVideoResolution1280x720;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertIntegerVideoFrameRate:(NSInteger) frameRate
                toEnumVideoFrameRate:(YuneecCameraVideoFrameRate *) enumVideoFrameRate
{
    BOOL ret = YES;
    switch (frameRate)
    {
        case 24:
            *enumVideoFrameRate = YuneecCameraVideoFrameRate24FPS;
            break;
        case 25:
            *enumVideoFrameRate = YuneecCameraVideoFrameRate25FPS;
            break;
        case 30:
            *enumVideoFrameRate = YuneecCameraVideoFrameRate30FPS;
            break;
        case 48:
            *enumVideoFrameRate = YuneecCameraVideoFrameRate48FPS;
            break;
        case 50:
            *enumVideoFrameRate = YuneecCameraVideoFrameRate50FPS;
            break;
        case 60:
            *enumVideoFrameRate = YuneecCameraVideoFrameRate60FPS;
            break;
        case 100:
            *enumVideoFrameRate = YuneecCameraVideoFrameRate100FPS;
            break;
        case 120:
            *enumVideoFrameRate = YuneecCameraVideoFrameRate120FPS;
            break;
        case 240:
            *enumVideoFrameRate = YuneecCameraVideoFrameRate240FPS;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertEnumVideoFrameRate:(YuneecCameraVideoFrameRate) videoFrameRate
               toIntegerFrameRate:(NSInteger *) integerFrameRate
{
    BOOL ret = YES;
    switch (videoFrameRate)
    {
        case YuneecCameraVideoFrameRate24FPS:
            *integerFrameRate = 24;
            break;
        case YuneecCameraVideoFrameRate25FPS:
            *integerFrameRate = 25;
            break;
        case YuneecCameraVideoFrameRate30FPS:
            *integerFrameRate = 30;
            break;
        case YuneecCameraVideoFrameRate48FPS:
            *integerFrameRate = 48;
            break;
        case YuneecCameraVideoFrameRate50FPS:
            *integerFrameRate = 50;
            break;
        case YuneecCameraVideoFrameRate60FPS:
            *integerFrameRate = 60;
            break;
        case YuneecCameraVideoFrameRate100FPS:
            *integerFrameRate = 100;
            break;
        case YuneecCameraVideoFrameRate120FPS:
            *integerFrameRate = 120;
            break;
        case YuneecCameraVideoFrameRate240FPS:
            *integerFrameRate = 240;
            break;
        default:
            ret = NO;
    }
    return ret;
}

+ (BOOL)convertEnumVideoStandard:(YuneecCameraVideoStandard) enumVideoStandard
          toIntegerVideoStandard:(NSInteger *) integerVideoStandard
{
    BOOL ret = YES;
    switch (enumVideoStandard)
    {
        case YuneecCameraVideoStandardNTSC:
            *integerVideoStandard = 0;
            break;
        case YuneecCameraVideoStandardPAL:
            *integerVideoStandard = 1;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertIntegerVideoStandard:(NSInteger) integerVideoStandard
                toEnumVideoStandard:(YuneecCameraVideoStandard *) enumVideoStandard
{
    BOOL ret = YES;
    switch (integerVideoStandard)
    {
        case 0:
            *enumVideoStandard = YuneecCameraVideoStandardNTSC;
            break;
        case 1:
            *enumVideoStandard = YuneecCameraVideoStandardPAL;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertEnumVideoFileFormat:(YuneecCameraVideoFileFormat) enumVideoFileFormat
          toIntegerVideoFileFormat:(NSInteger *) integerVideoFileFormat
{
    BOOL ret = YES;
    switch (enumVideoFileFormat)
    {
        case YuneecCameraVideoFileFormatMP4:
            *integerVideoFileFormat = 0x01;
            break;
        case YuneecCameraVideoFileFormatMOV:
            *integerVideoFileFormat = 0x00;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertIntegerVideoFileFormat:(NSInteger) integerVideoFileFormat
                toEnumVideoFileFormat:(YuneecCameraVideoFileFormat *) enumVideoFileFormat
{
    BOOL ret = YES;
    switch(integerVideoFileFormat)
    {
        case 0x01:
            *enumVideoFileFormat = YuneecCameraVideoFileFormatMP4;
            break;
        case 0x00:
            *enumVideoFileFormat = YuneecCameraVideoFileFormatMOV;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertPhotoResolution:(YuneecCameraPhotoResolution) photoResolution
                    photoWidth:(NSInteger *) photoWidth
                   photoHeight:(NSInteger *) photoHeight
{
    BOOL ret = YES;
    switch (photoResolution)
    {
        case YuneecCameraPhotoResolution4160x3120:
            *photoWidth = 4160;
            *photoHeight = 3120;
            break;
        case YuneecCameraPhotoResolution4000x3000:
            *photoWidth = 4000;
            *photoHeight = 3000;
            break;
        case YuneecCameraPhotoResolution3968x2232:
            *photoWidth = 3968;
            *photoHeight = 2232;
            break;
        case YuneecCameraPhotoResolution3936x2624:
            *photoWidth = 3936;
            *photoHeight = 2624;
            break;
        case YuneecCameraPhotoResolution3264x2448:
            *photoWidth = 3264;
            *photoHeight = 2448;
            break;
        case YuneecCameraPhotoResolution3008x3000:
            *photoWidth = 3008;
            *photoHeight = 3000;
            break;
        case YuneecCameraPhotoResolution2592x1944:
            *photoWidth = 2592;
            *photoHeight = 1944;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertPhotoWidth:(NSInteger) photoWidth
              photoHeight:(NSInteger) photoHeight
    toEnumPhotoResolution:(YuneecCameraPhotoResolution *) enumPhotoResolution
{
    BOOL ret = YES;
    switch (photoWidth)
    {
        case 4160:
            *enumPhotoResolution = YuneecCameraPhotoResolution4160x3120;
            break;
        case 4000:
            *enumPhotoResolution = YuneecCameraPhotoResolution4000x3000;
            break;
        case 3968:
            *enumPhotoResolution = YuneecCameraPhotoResolution3968x2232;
            break;
        case 3936:
            *enumPhotoResolution = YuneecCameraPhotoResolution3936x2624;
            break;
        case 3264:
            *enumPhotoResolution = YuneecCameraPhotoResolution3264x2448;
            break;
        case 3008:
            *enumPhotoResolution = YuneecCameraPhotoResolution3008x3000;
            break;
        case 2592:
            *enumPhotoResolution = YuneecCameraPhotoResolution2592x1944;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertEnumPhotoAspectRatio:(YuneecCameraPhotoAspectRatio) enumPhotoAspectRatio
          toIntegerPhotoAspectRatio:(NSInteger *) integerPhotoAspectRatio
{
    BOOL ret = YES;
    switch (enumPhotoAspectRatio)
    {
        case YuneecCameraPhotoAspectRatio4_3:
            *integerPhotoAspectRatio = 2;
            break;
        case YuneecCameraPhotoAspectRatio16_9:
            *integerPhotoAspectRatio = 3;
            break;
        case YuneecCameraPhotoAspectRatio3_2:
            *integerPhotoAspectRatio = 1;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertEnumPhotoAspectRatio:(YuneecCameraPhotoAspectRatio) enumPhotoAspectRatio
   toSpecialIntegerPhotoAspectRatio:(NSInteger *) integerPhotoAspectRatio
{
    BOOL ret = YES;
    switch (enumPhotoAspectRatio)
    {
        case YuneecCameraPhotoAspectRatio4_3:
            *integerPhotoAspectRatio = 130;
            break;
        case YuneecCameraPhotoAspectRatio16_9:
            *integerPhotoAspectRatio = 131;
            break;
        case YuneecCameraPhotoAspectRatio3_2:
            *integerPhotoAspectRatio = 1;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertIntegerPhotoAspectRatio:(NSInteger)integerPhotoAspectRatio
                toEnumPhotoAspectRatio:(YuneecCameraPhotoAspectRatio *)enumPhotoAspectRatio
{
    BOOL ret = YES;
    switch (integerPhotoAspectRatio)
    {
        case 2:
            *enumPhotoAspectRatio = YuneecCameraPhotoAspectRatio4_3;
            break;
        case 3:
            *enumPhotoAspectRatio = YuneecCameraPhotoAspectRatio16_9;
            break;
        case 1:
            *enumPhotoAspectRatio = YuneecCameraPhotoAspectRatio3_2;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertEnumPhotoQuality:(YuneecCameraPhotoQuality) photoQuality
          toIntegerPhotoQuality:(NSInteger *) integerPhotoQuality
{
    BOOL ret = YES;
    switch (photoQuality)
    {
        case YuneecCameraPhotoQualityLow:
            *integerPhotoQuality = 0;
            break;
        case YuneecCameraPhotoQualityNormal:
            *integerPhotoQuality = 1;
            break;
        case YuneecCameraPhotoQualityHigh:
            *integerPhotoQuality = 2;
            break;
        case YuneecCameraPhotoQualityUltraHigh:
            *integerPhotoQuality = 3;
            break;
        case  YuneecCameraPhotoQualityUnknown:
            ret= NO;
            break;
        defalut:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertIntegerPhotoQuality:(NSInteger) integerPhotoQuality
                toEnumPhotoQuality:(YuneecCameraPhotoQuality *) enumPhotoQuality
{
    BOOL ret = YES;
    switch (integerPhotoQuality)
    {
        case 0:
            *enumPhotoQuality = YuneecCameraPhotoQualityLow;
            break;
        case 1:
            *enumPhotoQuality = YuneecCameraPhotoQualityNormal;
            break;
        case 2:
            *enumPhotoQuality = YuneecCameraPhotoQualityHigh;
            break;
        case 3:
            *enumPhotoQuality = YuneecCameraPhotoQualityUltraHigh;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertEnumPhotoFormat:(YuneecCameraPhotoFormat) photoFormat
          toIntegerPhotoFormat:(NSInteger *) integerPhotoFormat
{
    BOOL ret = YES;
    switch (photoFormat)
    {
        case YuneecCameraPhotoFormatJpg:
            *integerPhotoFormat = 0x01;
            break;
        case YuneecCameraPhotoFormatRaw:
            *integerPhotoFormat = 0x02;
            break;
        case YuneecCameraPhotoFormatDng:
            *integerPhotoFormat = 0x82;
            break;
        case YuneecCameraPhotoFormatJpgRaw:
            *integerPhotoFormat = 0x03;
            break;
        case YuneecCameraPhotoFormatJpgDng:
            *integerPhotoFormat = 0x83;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertIntegerPhotoFormat:(NSInteger) integerPhotoFormat
                toEnumPhotoFormat:(YuneecCameraPhotoFormat *) enumPhotoFormat
{
    BOOL ret = YES;
    switch (integerPhotoFormat)
    {
        case 0x01:
            *enumPhotoFormat = YuneecCameraPhotoFormatJpg;
            break;
        case 0x02:
            *enumPhotoFormat = YuneecCameraPhotoFormatRaw;
            break;
        case 0x82:
            *enumPhotoFormat = YuneecCameraPhotoFormatDng;
            break;
        case 0x03:
            *enumPhotoFormat = YuneecCameraPhotoFormatJpgRaw;
            break;
        case 0x83:
            *enumPhotoFormat = YuneecCameraPhotoFormatJpgDng;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertEnumPhotoMode:(YuneecCameraPhotoMode) enumPhotoMode
          toIntegerPhotoMode:(NSInteger *) integerPhotoMode
{
    BOOL ret = YES;
    switch (enumPhotoMode)
    {
        case YuneecCameraPhotoModeSingle:
            *integerPhotoMode = 0x00;
            break;
        case YuneecCameraPhotoModeTimeLapse:
            *integerPhotoMode = 0x02;
            break;
        case YuneecCameraPhotoModeBurst:
            *integerPhotoMode = 0x03;
            break;
        case YuneecCameraPhotoModeAeb:
            *integerPhotoMode = 0x04;
            break;
        case YuneecCameraPhotoModePanoramaHorizon:
            *integerPhotoMode = 0x05;
            break;
        case YuneecCameraPhotoModePanoramaHemisphere:
            *integerPhotoMode = 0x06;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertIntegerPhotoMode:(NSInteger) integerPhotoMode
                toEnumPhotoMode:(YuneecCameraPhotoMode *) enumPhotoMode
{
    BOOL ret = YES;
    switch(integerPhotoMode)
    {
        case 0x00:
            *enumPhotoMode = YuneecCameraPhotoModeSingle;
            break;
        case 0x02:
            *enumPhotoMode = YuneecCameraPhotoModeTimeLapse;
            break;
        case 0x03:
            *enumPhotoMode = YuneecCameraPhotoModeBurst;
            break;
        case 0x04:
            *enumPhotoMode = YuneecCameraPhotoModeAeb;
            break;
        case 0x05:
            *enumPhotoMode = YuneecCameraPhotoModePanoramaHorizon;
            break;
        case 0x06:
            *enumPhotoMode = YuneecCameraPhotoModePanoramaHemisphere;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertEnumAEMode:(YuneecCameraAEMode) aeMode
          toIntegerAEMode:(NSInteger *) integerAEMode
{
    BOOL ret = YES;
    switch (aeMode)
    {
        case YuneecCameraAEModeAuto:
            *integerAEMode = 0;
            break;
        case YuneecCameraAEModeManual:
            *integerAEMode = 1;
            break;
        case YuneecCameraAEModeLock:
            *integerAEMode = 2;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertIntegerAEMode:(NSInteger) integerAEMode
                toEnumAEMode:(YuneecCameraAEMode *) enumAEMode
{
    BOOL ret = YES;
    switch (integerAEMode)
    {
        case 0:
            *enumAEMode = YuneecCameraAEModeAuto;
            break;
        case 1:
            *enumAEMode = YuneecCameraAEModeManual;
            break;
        case 2:
            *enumAEMode = YuneecCameraAEModeLock;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (void)correctShutterTimeValue:(NSUInteger) inputNumerator
               inputDenominator:(NSUInteger) inputDenominator
                outputNumerator:(NSUInteger *) outputNumerator
              outputDenominator:(NSUInteger *) outputDenominator
{
    if (inputDenominator == 0xffff) {
        double shutterTimeDoubleValue = inputNumerator * 1.0 / inputDenominator;
//        NSInteger shutterTimeIndex = 0;
//        const NSInteger longShutterTimeCount = 16;
        if (shutterTimeDoubleValue > 0.025) {    ///< 0.03333333333333 (1/30)
            *outputNumerator = 1;
            *outputDenominator = 30;
        }
        else if (shutterTimeDoubleValue > 0.014) {    ///< 0.01666666666667 (1/60)
            *outputNumerator = 1;
            *outputDenominator = 60;
        }
        else if (shutterTimeDoubleValue > 0.006) {         ///< 0.008 (1/125)
            *outputNumerator = 1;
            *outputDenominator = 125;
        }
        else if (shutterTimeDoubleValue > 0.003) {       ///< 0.004 (1/250)
            *outputNumerator = 1;
            *outputDenominator = 250;
        }
        else if (shutterTimeDoubleValue > 0.0015) {       ///< 0.002 (1/500)
            *outputNumerator = 1;
            *outputDenominator = 500;
        }
        else if (shutterTimeDoubleValue > 0.00075) {       ///< 0.001 (1/1000)
            *outputNumerator = 1;
            *outputDenominator = 1000;
        }
        else if (shutterTimeDoubleValue > 0.0004) {       ///< 0.0005 (1/2000)
            *outputNumerator = 1;
            *outputDenominator = 2000;
        }
        else if (shutterTimeDoubleValue > 0.0002) {       ///< 0.00025 (1/4000)
            *outputNumerator = 1;
            *outputDenominator = 4000;
        }
        else if (shutterTimeDoubleValue > 0.0001) {       ///< 0.000125 (1/8000)
            *outputNumerator = 1;
            *outputDenominator = 8000;
        }
    }
    else if (inputDenominator == 1) {
        *outputNumerator = inputNumerator;
        *outputDenominator = inputDenominator;
    }
    else {
        *outputNumerator = inputNumerator;
        *outputDenominator = inputDenominator;
    }
}

+ (BOOL)convertEnumMeterMode:(YuneecCameraMeterMode) enumMeterMode
          toIntegerMeterMode:(NSInteger *) integerMeterMode
{
    BOOL ret = YES;
    switch (enumMeterMode)
    {
        case YuneecCameraMeterModeCenter:
            *integerMeterMode = 0;
            break;
        case YuneecCameraMeterModeAverage:
            *integerMeterMode = 1;
            break;
        case YuneecCameraMeterModeSpot:
            *integerMeterMode = 2;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertIntegerMeterMode:(NSInteger) integerMeterMode
                toEnumMeterMode:(YuneecCameraMeterMode *) enumMeterMode
{
    BOOL ret = YES;
    switch (integerMeterMode)
    {
        case 0:
            *enumMeterMode = YuneecCameraMeterModeCenter;
            break;
        case 1:
            *enumMeterMode = YuneecCameraMeterModeAverage;
            break;
        case 2:
            *enumMeterMode = YuneecCameraMeterModeSpot;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertEnumFlickerMode:(YuneecCameraFlickerMode) enumFlickerMode
          toIntegerFlickerMode:(NSInteger *) integerFlickerMode
{
    BOOL ret = YES;
    switch (enumFlickerMode)
    {
        case YuneecCameraFlickerModeAuto:
            *integerFlickerMode = 0;
            break;
        case YuneecCameraFlickerMode60Hz:
            *integerFlickerMode = 1;
            break;
        case YuneecCameraFlickerMode50Hz:
            *integerFlickerMode = 2;
            break;
        case YuneecCameraFlickerModeNo60Hz:
            *integerFlickerMode = 10;
            break;
        case YuneecCameraFlickerModeNo50Hz:
            *integerFlickerMode = 20;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertIntegerFlickerMode:(NSInteger) integerFlickerMode
                toEnumFlickerMode:(YuneecCameraFlickerMode *) enumFlickerMode
{
    BOOL ret = YES;
    switch (integerFlickerMode)
    {
        case 0:
            *enumFlickerMode = YuneecCameraFlickerModeAuto;
            break;
        case 1:
            *enumFlickerMode = YuneecCameraFlickerMode60Hz;
            break;
        case 2:
            *enumFlickerMode = YuneecCameraFlickerMode50Hz;
            break;
        case 10:
            *enumFlickerMode = YuneecCameraFlickerModeNo60Hz;
            break;
        case 20:
            *enumFlickerMode = YuneecCameraFlickerModeNo50Hz;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertEnumWhiteBalanceMode:(YuneecCameraWhiteBalanceMode) enumWhiteBalanceMode
          toIntegerWhiteBalanceMode:(NSInteger *) integerWhiteBalanceMode
{
    BOOL ret = YES;
    switch(enumWhiteBalanceMode)
    {
        case YuneecCameraWhiteBalanceModeAuto:
            *integerWhiteBalanceMode = 0;
            break;
        case YuneecCameraWhiteBalanceModeSunny:
            *integerWhiteBalanceMode = 1;
            break;
        case YuneecCameraWhiteBalanceModeSunrise:
            *integerWhiteBalanceMode = 2;
            break;
        case YuneecCameraWhiteBalanceModeSunset:
            *integerWhiteBalanceMode = 3;
            break;
        case YuneecCameraWhiteBalanceModeCloudy:
            *integerWhiteBalanceMode = 4;
            break;
        case YuneecCameraWhiteBalanceModeFlucrescent:
            *integerWhiteBalanceMode = 5;
            break;
        case YuneecCameraWhiteBalanceModeIncandescent:
            *integerWhiteBalanceMode = 6;
            break;
        case YuneecCameraWhiteBalanceModeManual:
            *integerWhiteBalanceMode = 99;
            break;
        case YuneecCameraWhiteBalanceModeLock:
            *integerWhiteBalanceMode = 100;
            break;
        case YuneecCameraWhiteBalanceModeManualColorTemp:
            *integerWhiteBalanceMode = 101;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertIntegerWhiteBalanceMode:(NSInteger) integerWhileBalanceMode
                toEnumWhiteBalanceMode:(YuneecCameraWhiteBalanceMode *) enumWhiteBalanceMode
{
    BOOL ret = YES;
    switch (integerWhileBalanceMode)
    {
        case 0:
            *enumWhiteBalanceMode = YuneecCameraWhiteBalanceModeAuto;
            break;
        case 1:
            *enumWhiteBalanceMode = YuneecCameraWhiteBalanceModeSunny;
            break;
        case 2:
            *enumWhiteBalanceMode = YuneecCameraWhiteBalanceModeSunrise;
            break;
        case 3:
            *enumWhiteBalanceMode = YuneecCameraWhiteBalanceModeSunset;
            break;
        case 4:
            *enumWhiteBalanceMode = YuneecCameraWhiteBalanceModeCloudy;
            break;
        case 5:
            *enumWhiteBalanceMode = YuneecCameraWhiteBalanceModeFlucrescent;
            break;
        case 6:
            *enumWhiteBalanceMode = YuneecCameraWhiteBalanceModeIncandescent;
            break;
        case 99:
            *enumWhiteBalanceMode = YuneecCameraWhiteBalanceModeManual;
            break;
        case 100:
            *enumWhiteBalanceMode = YuneecCameraWhiteBalanceModeLock;
            break;
        case 101:
            *enumWhiteBalanceMode = YuneecCameraWhiteBalanceModeManualColorTemp;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertEnumImageQualityMode:(YuneecCameraImageQualityMode) enumImageQualityMode
          toIntegerImageQualityMode:(NSInteger *) integerImageQualityMode
{
    BOOL ret = YES;
    switch (enumImageQualityMode)
    {
        case YuneecCameraImageQualityModeNature:
            *integerImageQualityMode = 0;
            break;
        case YuneecCameraImageQualityModeSaturation:
            *integerImageQualityMode = 1;
            break;
        case YuneecCameraImageQualityModeRaw:
            *integerImageQualityMode = 2;
            break;
        case YuneecCameraImageQualityModeNight:
            *integerImageQualityMode = 3;
            break;
        case YuneecCameraImageQualityModeLog:
            *integerImageQualityMode = 4;
            break;
        case YuneecCameraImageQualityModeSoft:
            *integerImageQualityMode = 6;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertIntegerImageQualityMode:(NSInteger) integerImageQualityMode
                toEnumImageQualityMode:(YuneecCameraImageQualityMode *) enumImageQualityMode
{
    BOOL ret = YES;
    switch (integerImageQualityMode)
    {
        case 0:
            *enumImageQualityMode = YuneecCameraImageQualityModeNature;
            break;
        case 1:
            *enumImageQualityMode = YuneecCameraImageQualityModeSaturation;
            break;
        case 2:
            *enumImageQualityMode = YuneecCameraImageQualityModeRaw;
            break;
        case 3:
            *enumImageQualityMode = YuneecCameraImageQualityModeNight;
            break;
        case 4:
            *enumImageQualityMode = YuneecCameraImageQualityModeLog;
            break;
        case 6:
            *enumImageQualityMode = YuneecCameraImageQualityModeSoft;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertEnumVideoCompressionFormat:(YuneecCameraVideoCompressionFormat) enumVideoCompressionFormat
          toIntegerVideoCompressionFormat:(NSInteger *) integerVideoCompressionFormat
{
    BOOL ret = YES;
    switch (enumVideoCompressionFormat)
    {
        case YuneecCameraVideoCompressionFormatH264:
            *integerVideoCompressionFormat = 1;
            break;
        case YuneecCameraVideoCompressionFormatH265:
            *integerVideoCompressionFormat = 3;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertIntegerVideoCompressionFormat:(NSInteger) integerVideoCompressionFormat
                toEnumVideoCompressionFormat:(YuneecCameraVideoCompressionFormat *) enumVideoCompressionFormat
{
    BOOL ret = YES;
    switch (integerVideoCompressionFormat)
    {
        case 1:
            *enumVideoCompressionFormat = YuneecCameraVideoCompressionFormatH264;
            break;
        case 3:
            *enumVideoCompressionFormat = YuneecCameraVideoCompressionFormatH265;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertEnumStreamEncoderStyle:(YuneecCameraStreamEncoderStyle) enumStreamEncoderStyle
          toIntegerStreamEncoderStyle:(NSUInteger *) integerStreamEncoderStyle
{
    BOOL ret = YES;
    switch (enumStreamEncoderStyle)
    {
        case YuneecCameraStreamEncoderStyleNo:
            *integerStreamEncoderStyle = 0x00;
            break;
        case YuneecCameraStreamEncoderStyleIntra:
            *integerStreamEncoderStyle = 0x01;
            break;
        case YuneecCameraStreamEncoderStyleSlice:
            *integerStreamEncoderStyle = 0x10;
            break;
        case YuneecCameraStreamEncoderStyleSliceAndIntra:
            *integerStreamEncoderStyle = 0x11;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertIntegerStreamEncoderStyle:(NSUInteger) integerStreamEncoderStyle
                 toEnumtreamEncoderStyle:(YuneecCameraStreamEncoderStyle *) enumStreamEncoderStyle
{
    BOOL ret = YES;
    switch(integerStreamEncoderStyle)
    {
        case 0x00:
            *enumStreamEncoderStyle = YuneecCameraStreamEncoderStyleNo;
            break;
        case 0x01:
            *enumStreamEncoderStyle = YuneecCameraStreamEncoderStyleIntra;
            break;
        case 0x10:
            *enumStreamEncoderStyle = YuneecCameraStreamEncoderStyleSlice;
            break;
        case 0x11:
            *enumStreamEncoderStyle = YuneecCameraStreamEncoderStyleSliceAndIntra;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

#pragma mark - mavlink converter

+ (BOOL)convertEnumVideoResolution:(YuneecCameraVideoResolution) videoResolution
                enumVideoFrameRate:(YuneecCameraVideoFrameRate) videoFrameRate
           toMavlinkVideoParameter:(NSInteger *)mavlinkVideoParameter {
    BOOL ret = YES;
    switch (videoResolution)
    {
        case YuneecCameraVideoResolution4096x2160:
            switch (videoFrameRate) {
                case YuneecCameraVideoFrameRate25FPS:
                    *mavlinkVideoParameter = 0;
                    break;
                case YuneecCameraVideoFrameRate24FPS:
                    *mavlinkVideoParameter = 1;
                    break;
                default:
                    ret = NO;
                    break;
            }
            break;
        case YuneecCameraVideoResolution3840x2160:
            switch (videoFrameRate) {
                case YuneecCameraVideoFrameRate30FPS:
                    *mavlinkVideoParameter = 2;
                    break;
                case YuneecCameraVideoFrameRate25FPS:
                    *mavlinkVideoParameter = 3;
                    break;
                case YuneecCameraVideoFrameRate24FPS:
                    *mavlinkVideoParameter = 4;
                    break;
                default:
                    ret = NO;
                    break;
            }
            break;
        case YuneecCameraVideoResolution2688x1520:
            switch (videoFrameRate) {
                case YuneecCameraVideoFrameRate30FPS:
                    *mavlinkVideoParameter = 5;
                    break;
                case YuneecCameraVideoFrameRate25FPS:
                    *mavlinkVideoParameter = 6;
                    break;
                case YuneecCameraVideoFrameRate24FPS:
                    *mavlinkVideoParameter = 7;
                    break;
                default:
                    ret = NO;
                    break;
            }
            break;
        case YuneecCameraVideoResolution1920x1080:
            switch (videoFrameRate) {
                case YuneecCameraVideoFrameRate120FPS:
                    *mavlinkVideoParameter = 8;
                    break;
                case YuneecCameraVideoFrameRate60FPS:
                    *mavlinkVideoParameter = 9;
                    break;
                case YuneecCameraVideoFrameRate50FPS:
                    *mavlinkVideoParameter = 10;
                    break;
                case YuneecCameraVideoFrameRate48FPS:
                    *mavlinkVideoParameter = 11;
                    break;
                case YuneecCameraVideoFrameRate30FPS:
                    *mavlinkVideoParameter = 12;
                    break;
                case YuneecCameraVideoFrameRate25FPS:
                    *mavlinkVideoParameter = 13;
                    break;
                case YuneecCameraVideoFrameRate24FPS:
                    *mavlinkVideoParameter = 14;
                    break;
                default:
                    ret = NO;
                    break;
            }
            break;
        case YuneecCameraVideoResolution1280x720:
            switch (videoFrameRate) {
                case YuneecCameraVideoFrameRate120FPS:
                    *mavlinkVideoParameter = 15;
                    break;
                case YuneecCameraVideoFrameRate60FPS:
                    *mavlinkVideoParameter = 16;
                    break;
                case YuneecCameraVideoFrameRate50FPS:
                    *mavlinkVideoParameter = 17;
                    break;
                case YuneecCameraVideoFrameRate48FPS:
                    *mavlinkVideoParameter = 18;
                    break;
                case YuneecCameraVideoFrameRate30FPS:
                    *mavlinkVideoParameter = 19;
                    break;
                case YuneecCameraVideoFrameRate25FPS:
                    *mavlinkVideoParameter = 20;
                    break;
                case YuneecCameraVideoFrameRate24FPS:
                    *mavlinkVideoParameter = 21;
                    break;
                default:
                    ret = NO;
                    break;
            }
            break;
        default:
            ret = NO;
            break;
    }
    
    return ret;
}

+ (BOOL)convertMavlinkVideoParameter:(NSInteger) mavlinkVideoParameter
               toEnumVideoResolution:(YuneecCameraVideoResolution *) enumVideoResolution
                  enumVideoFrameRate:(YuneecCameraVideoFrameRate *) enumVideoFrameRate
{
    BOOL ret = YES;
    switch (mavlinkVideoParameter)
    {
        case 0:
            *enumVideoResolution = YuneecCameraVideoResolution4096x2160;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate25FPS;
            break;
        case 1:
            *enumVideoResolution = YuneecCameraVideoResolution4096x2160;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate24FPS;
            break;
        case 2:
            *enumVideoResolution = YuneecCameraVideoResolution3840x2160;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate30FPS;
            break;
        case 3:
            *enumVideoResolution = YuneecCameraVideoResolution3840x2160;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate25FPS;
            break;
        case 4:
            *enumVideoResolution = YuneecCameraVideoResolution3840x2160;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate24FPS;
            break;
        case 5:
            *enumVideoResolution = YuneecCameraVideoResolution2688x1520;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate30FPS;
            break;
        case 6:
            *enumVideoResolution = YuneecCameraVideoResolution3840x2160;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate25FPS;
            break;
        case 7:
            *enumVideoResolution = YuneecCameraVideoResolution3840x2160;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate24FPS;
            break;
        case 8:
            *enumVideoResolution = YuneecCameraVideoResolution1920x1080;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate120FPS;
            break;
        case 9:
            *enumVideoResolution = YuneecCameraVideoResolution1920x1080;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate60FPS;
            break;
        case 10:
            *enumVideoResolution = YuneecCameraVideoResolution1920x1080;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate50FPS;
            break;
        case 11:
            *enumVideoResolution = YuneecCameraVideoResolution1920x1080;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate48FPS;
            break;
        case 12:
            *enumVideoResolution = YuneecCameraVideoResolution1920x1080;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate30FPS;
            break;
        case 13:
            *enumVideoResolution = YuneecCameraVideoResolution1920x1080;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate25FPS;
            break;
        case 14:
            *enumVideoResolution = YuneecCameraVideoResolution1920x1080;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate24FPS;
            break;
        case 15:
            *enumVideoResolution = YuneecCameraVideoResolution1280x720;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate120FPS;
            break;
        case 16:
            *enumVideoResolution = YuneecCameraVideoResolution1280x720;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate60FPS;
            break;
        case 17:
            *enumVideoResolution = YuneecCameraVideoResolution1280x720;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate50FPS;
            break;
        case 18:
            *enumVideoResolution = YuneecCameraVideoResolution1280x720;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate48FPS;
            break;
        case 19:
            *enumVideoResolution = YuneecCameraVideoResolution1280x720;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate30FPS;
            break;
        case 20:
            *enumVideoResolution = YuneecCameraVideoResolution1280x720;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate25FPS;
            break;
        case 21:
            *enumVideoResolution = YuneecCameraVideoResolution1280x720;
            *enumVideoFrameRate = YuneecCameraVideoFrameRate25FPS;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertEnumPhotoAspectRatio:(YuneecCameraPhotoAspectRatio) enumPhotoAspectRatio
       mavlinkPhotoAspectRatioWidth:(NSInteger *) mavlinkPhotoAspectRatioWidth
      mavlinkPhotoAspectRatioHeight:(NSInteger *) mavlinkPhotoAspectRatioHeight
{
    BOOL ret = YES;
    switch (enumPhotoAspectRatio)
    {
        case YuneecCameraPhotoAspectRatio4_3:
            *mavlinkPhotoAspectRatioWidth = 4;
            *mavlinkPhotoAspectRatioHeight = 3;
            break;
        case YuneecCameraPhotoAspectRatio16_9:
            *mavlinkPhotoAspectRatioWidth = 16;
            *mavlinkPhotoAspectRatioHeight = 9;
            break;
        case YuneecCameraPhotoAspectRatio3_2:
            *mavlinkPhotoAspectRatioWidth = 3;
            *mavlinkPhotoAspectRatioHeight = 2;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertMavlinkPhotoAspectRatioFloatValue:(float) photoAspectRatioFloatValue
                          toEnumPhotoAspectRatio:(YuneecCameraPhotoAspectRatio *) enumPhotoAspectRatio
{
    BOOL ret = YES;
    if (photoAspectRatioFloatValue > 1.7) {             ///< 1.7777 ( 16 : 9 )
        *enumPhotoAspectRatio = YuneecCameraPhotoAspectRatio16_9;
    }
    else if (photoAspectRatioFloatValue >= 1.5) {       ///< 1.5    ( 3 : 2 )
        *enumPhotoAspectRatio = YuneecCameraPhotoAspectRatio3_2;
    }
    else if (photoAspectRatioFloatValue > 1.3) {        ///< 1.3333 ( 4 : 3 )
        *enumPhotoAspectRatio = YuneecCameraPhotoAspectRatio4_3;
    }else {
        ret = NO;
    }
    return ret;
}

+ (BOOL)convertEnumPhotoFormat:(YuneecCameraPhotoFormat) photoFormat
          toMavlinkPhotoFormat:(NSInteger *) mavlinkPhotoFormat
{
    BOOL ret = YES;
    switch (photoFormat)
    {
        case YuneecCameraPhotoFormatJpg:
            *mavlinkPhotoFormat = 0x00;
            break;
        case YuneecCameraPhotoFormatRaw:
        case YuneecCameraPhotoFormatDng:
            *mavlinkPhotoFormat = 0x01;
            break;
        case YuneecCameraPhotoFormatJpgRaw:
        case YuneecCameraPhotoFormatJpgDng:
            *mavlinkPhotoFormat = 0x02;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertMavlinkPhotoFormat:(NSInteger) mavlinkPhotoFormat
                toEnumPhotoFormat:(YuneecCameraPhotoFormat *) enumPhotoFormat
{
    BOOL ret = YES;
    switch (mavlinkPhotoFormat)
    {
        case 0x00:
            *enumPhotoFormat = YuneecCameraPhotoFormatJpg;
            break;
        case 0x01:
            *enumPhotoFormat = YuneecCameraPhotoFormatDng;
            break;
        case 0x02:
            *enumPhotoFormat = YuneecCameraPhotoFormatJpgDng;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertMavlinkShutterTimeValue:(float) shutterTimeValue
                       outputNumerator:(NSUInteger *) outputNumerator
                     outputDenominator:(NSUInteger *) outputDenominator
{
    BOOL ret = YES;
    if (shutterTimeValue >= 1) {                ///< integer value
        *outputNumerator = (NSUInteger)shutterTimeValue;
        *outputDenominator = 1;
    }
    else if (shutterTimeValue > 0.4) {          ///< 0.5 (1/2)
        *outputNumerator = 1;
        *outputDenominator = 2;
    }
    else if (shutterTimeValue > 0.2) {          ///< 0.25 (1/4)
        *outputNumerator = 1;
        *outputDenominator = 4;
    }
    else if (shutterTimeValue > 0.12) {         ///< 0.125 (1/8)
        *outputNumerator = 1;
        *outputDenominator = 8;
    }
    else if (shutterTimeValue > 0.06) {         ///< 0.0625 (1/16)
        *outputNumerator = 1;
        *outputDenominator = 16;
    }
    else if (shutterTimeValue > 0.03) {        ///< 0.03333333333333 (1/30)
        *outputNumerator = 1;
        *outputDenominator = 30;
    }
    else if (shutterTimeValue > 0.015) {        ///< 0.01666666666667 (1/60)
        *outputNumerator = 1;
        *outputDenominator = 60;
    }
    else if (shutterTimeValue > 0.006) {        ///< 0.008 (1/125)
        *outputNumerator = 1;
        *outputDenominator = 125;
    }
    else if (shutterTimeValue > 0.003) {        ///< 0.004 (1/250)
        *outputNumerator = 1;
        *outputDenominator = 250;
    }
    else if (shutterTimeValue > 0.0015) {       ///< 0.002 (1/500)
        *outputNumerator = 1;
        *outputDenominator = 500;
    }
    else if (shutterTimeValue > 0.00075) {       ///< 0.001 (1/1000)
        *outputNumerator = 1;
        *outputDenominator = 1000;
    }
    else if (shutterTimeValue > 0.0004) {       ///< 0.0005 (1/2000)
        *outputNumerator = 1;
        *outputDenominator = 2000;
    }
    else if (shutterTimeValue > 0.0002) {       ///< 0.00025 (1/4000)
        *outputNumerator = 1;
        *outputDenominator = 4000;
    }
    else if (shutterTimeValue > 0.0001) {       ///< 0.000125 (1/8000)
        *outputNumerator = 1;
        *outputDenominator = 8000;
    }else {
        ret = NO;
    }
    return ret;
}

+ (BOOL)convertMavlinkExposureValue:(float) exposureValue
                    outputNumerator:(NSUInteger *) outputNumerator
                  outputDenominator:(NSUInteger *) outputDenominator
{
    BOOL ret = YES;
    if (exposureValue >= 3.0) {                ///< 30 / 10
        *outputNumerator = 30;
        *outputDenominator = 10;
    }
    else if (exposureValue >= 2.5) {          ///< 25 / 10
        *outputNumerator = 25;
        *outputDenominator = 10;
    }
    else if (exposureValue >= 2.0) {          ///< 20 / 10
        *outputNumerator = 20;
        *outputDenominator = 10;
    }
    else if (exposureValue >= 1.5) {          ///< 15 / 10
        *outputNumerator = 15;
        *outputDenominator = 10;
    }
    else if (exposureValue >= 1.0) {          ///< 10 / 10
        *outputNumerator = 10;
        *outputDenominator = 10;
    }
    else if (exposureValue >= 0.5) {          ///< 5 / 10
        *outputNumerator = 5;
        *outputDenominator = 10;
    }
    else if (exposureValue >= 0) {          ///< 0 / 10
        *outputNumerator = 0;
        *outputDenominator = 10;
    }
    else if (exposureValue >= -0.5) {          ///< -5 / 10
        *outputNumerator = -5;
        *outputDenominator = 10;
    }
    else if (exposureValue >= -1.0) {          ///< -10 / 10
        *outputNumerator = -10;
        *outputDenominator = 10;
    }
    else if (exposureValue >= -1.5) {          ///< -15 / 10
        *outputNumerator = -15;
        *outputDenominator = 10;
    }
    else if (exposureValue >= -2.0) {          ///< -20 / 10
        *outputNumerator = -20;
        *outputDenominator = 10;
    }
    else if (exposureValue >= -2.5) {          ///< -25 / 10
        *outputNumerator = -25;
        *outputDenominator = 10;
    }
    else if (exposureValue >= -3.0) {          ///< -30 / 10
        *outputNumerator = -30;
        *outputDenominator = 10;
    }else {
        ret = NO;
    }
    return ret;
}

+ (BOOL)convertEnumWhiteBalanceMode:(YuneecCameraWhiteBalanceMode) enumWhiteBalanceMode
   toMavlinkIntegerWhiteBalanceMode:(NSInteger *) integerWhiteBalanceMode
{
    BOOL ret = YES;
    switch(enumWhiteBalanceMode)
    {
        case YuneecCameraWhiteBalanceModeAuto:
            *integerWhiteBalanceMode = 0;
            break;
        case YuneecCameraWhiteBalanceModeIncandescent:
            *integerWhiteBalanceMode = 1;
            break;
        case YuneecCameraWhiteBalanceModeSunrise:
            *integerWhiteBalanceMode = 2;
            break;
        case YuneecCameraWhiteBalanceModeSunset:
            *integerWhiteBalanceMode = 3;
            break;
        case YuneecCameraWhiteBalanceModeSunny:
            *integerWhiteBalanceMode = 4;
            break;
        case YuneecCameraWhiteBalanceModeCloudy:
            *integerWhiteBalanceMode = 5;
            break;
        case YuneecCameraWhiteBalanceModeFlucrescent:
            *integerWhiteBalanceMode = 7;
            break;
        case YuneecCameraWhiteBalanceModeLock:
            *integerWhiteBalanceMode = 99;
            break;
        case YuneecCameraWhiteBalanceModeManual:
            *integerWhiteBalanceMode = 100;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertMavlinkIntegerWhiteBalanceMode:(NSInteger) integerWhileBalanceMode
                toEnumWhiteBalanceMode:(YuneecCameraWhiteBalanceMode *) enumWhiteBalanceMode
{
    BOOL ret = YES;
    switch (integerWhileBalanceMode)
    {
        case 0:
            *enumWhiteBalanceMode = YuneecCameraWhiteBalanceModeAuto;
            break;
        case 1:
            *enumWhiteBalanceMode = YuneecCameraWhiteBalanceModeIncandescent;
            break;
        case 2:
            *enumWhiteBalanceMode = YuneecCameraWhiteBalanceModeSunrise;
            break;
        case 3:
            *enumWhiteBalanceMode = YuneecCameraWhiteBalanceModeSunset;
            break;
        case 4:
            *enumWhiteBalanceMode = YuneecCameraWhiteBalanceModeSunny;
            break;
        case 5:
            *enumWhiteBalanceMode = YuneecCameraWhiteBalanceModeCloudy;
            break;
        case 7:
            *enumWhiteBalanceMode = YuneecCameraWhiteBalanceModeFlucrescent;
            break;
        case 99:
            *enumWhiteBalanceMode = YuneecCameraWhiteBalanceModeLock;
            break;
        case 100:
            *enumWhiteBalanceMode = YuneecCameraWhiteBalanceModeManual;
            break;
        default:
            ret = NO;
            break;
    }
    return ret;
}

+ (BOOL)convertCameraName:(NSString *)cameraName
             toCameraType:(YuneecCameraType *)cameraType {
    BOOL ret = YES;
    if ([cameraName.lowercaseString containsString:@"ob"]) {
        *cameraType = YuneecCameraTypeOB;
    }
    else if ([cameraName.lowercaseString containsString:@"hdracer"]) {
        *cameraType = YuneecCameraTypeHDRacer;
    }
    else if ([cameraName.lowercaseString containsString:@"firebird"]) {
        *cameraType = YuneecCameraTypeFirebird;
    }
    else if ([cameraName.lowercaseString containsString:@"breeze"]) {
        *cameraType = YuneecCameraTypeBreeze;
    }
    else if ([cameraName.lowercaseString containsString:@"cgoet"]) {
        *cameraType = YuneecCameraTypeCGOET;
    }
    else if ([cameraName.lowercaseString containsString:@"cgopro"]) {
        *cameraType = YuneecCameraTypeCGOPro;
    }
    else if ([cameraName.lowercaseString containsString:@"cgot"]) {
        *cameraType = YuneecCameraTypeCGOT;
    }
    else if ([cameraName.lowercaseString containsString:@"cgo3plus"]) {
        *cameraType = YuneecCameraTypeCGO3Plus;
    }
    else if ([cameraName.lowercaseString containsString:@"e90"]) {
        *cameraType = YuneecCameraTypeE90;
    }else {
        *cameraType = YuneecCameraTypeUnknown;
        ret = NO;
    }
    return ret;
    
}

@end
