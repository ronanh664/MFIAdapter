//
//  YuneecCameraParameterConverter.h
//  YuneecSDK
//
//  Copyright © 2017 yuneec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YuneecCameraSDK/YuneecCameraDefine.h>

/**
 * 用于将相机返回的数据转化为SDK可以识别的类型;
 * 用于将SDK设置的数据转化为相机可以是别的类型;
 */
@interface YuneecCameraParameterConverter : NSObject

+ (YuneecCameraType)convertIntegerCameraTypeToEnumCameraType:(uint8_t) integerCameraType;

+ (BOOL)convertEnumVideoResolution:(YuneecCameraVideoResolution) videoResolution
                        videoWidth:(NSInteger *) videoWidth
                      videoHheight:(NSInteger *) videoHeight;

+ (BOOL)convertVideoWidth:(NSInteger) videoWidth
              videoHeight:(NSInteger) videoHeight
    toEnumVideoResolution:(YuneecCameraVideoResolution *) enumVideoResolution;

+ (BOOL)convertIntegerVideoFrameRate:(NSInteger) frameRate
                toEnumVideoFrameRate:(YuneecCameraVideoFrameRate *) enumVideoFrameRate;

+ (BOOL)convertEnumVideoFrameRate:(YuneecCameraVideoFrameRate) videoFrameRate
               toIntegerFrameRate:(NSInteger *) integerFrameRate;

+ (BOOL)convertEnumVideoStandard:(YuneecCameraVideoStandard) enumVideoStandard
          toIntegerVideoStandard:(NSInteger *) integerVideoStandard;

+ (BOOL)convertIntegerVideoStandard:(NSInteger) integerVideoStandard
                toEnumVideoStandard:(YuneecCameraVideoStandard *) enumVideoStandard;

+ (BOOL)convertEnumVideoFileFormat:(YuneecCameraVideoFileFormat) enumVideoFileFormat
          toIntegerVideoFileFormat:(NSInteger *) integerVideoFileFormat;

+ (BOOL)convertIntegerVideoFileFormat:(NSInteger) integerVideoFileFormat
                toEnumVideoFileFormat:(YuneecCameraVideoFileFormat *) enumVideoFileFormat;

+ (BOOL)convertPhotoResolution:(YuneecCameraPhotoResolution) photoResolution
                    photoWidth:(NSInteger *) photoWidth
                   photoHeight:(NSInteger *) photoHeight;

+ (BOOL)convertPhotoWidth:(NSInteger) photoWidth
              photoHeight:(NSInteger) photoHeight
    toEnumPhotoResolution:(YuneecCameraPhotoResolution *) enumPhotoResolution;

+ (BOOL)convertEnumPhotoAspectRatio:(YuneecCameraPhotoAspectRatio) enumPhotoAspectRatio
          toIntegerPhotoAspectRatio:(NSInteger *) integerPhotoAspectRatio;

+ (BOOL)convertEnumPhotoAspectRatio:(YuneecCameraPhotoAspectRatio) enumPhotoAspectRatio
   toSpecialIntegerPhotoAspectRatio:(NSInteger *) integerPhotoAspectRatio;

+ (BOOL)convertIntegerPhotoAspectRatio:(NSInteger) integerPhotoAspectRatio
                toEnumPhotoAspectRatio:(YuneecCameraPhotoAspectRatio *) enumPhotoAspectRatio;

+ (BOOL)convertEnumPhotoQuality:(YuneecCameraPhotoQuality) photoQuality
          toIntegerPhotoQuality:(NSInteger *) integerPhotoQuality;

+ (BOOL)convertIntegerPhotoQuality:(NSInteger) integerPhotoQuality
                toEnumPhotoQuality:(YuneecCameraPhotoQuality *) enumPhotoQuality;

+ (BOOL)convertEnumPhotoFormat:(YuneecCameraPhotoFormat) photoFormat
          toIntegerPhotoFormat:(NSInteger *) integerPhotoFormat;

+ (BOOL)convertIntegerPhotoFormat:(NSInteger) integerPhotoFormat
                toEnumPhotoFormat:(YuneecCameraPhotoFormat *) enumPhotoFormat;

+ (BOOL)convertEnumPhotoMode:(YuneecCameraPhotoMode) enumPhotoMode
          toIntegerPhotoMode:(NSInteger *) integerPhotoMode;

+ (BOOL)convertIntegerPhotoMode:(NSInteger) integerPhotoMode
                toEnumPhotoMode:(YuneecCameraPhotoMode *) enumPhotoMode;

+ (BOOL)convertEnumAEMode:(YuneecCameraAEMode) aeMode
          toIntegerAEMode:(NSInteger *) integerAEMode;

+ (BOOL)convertIntegerAEMode:(NSInteger) integerAEMode
                toEnumAEMode:(YuneecCameraAEMode *) enumAEMode;

/**
 * 相机返回的ShutterTime值都是错误的，此方法用于纠错相机数据
 *
 */
+ (void)correctShutterTimeValue:(NSUInteger) inputNumerator
               inputDenominator:(NSUInteger) inputDenominator
                outputNumerator:(NSUInteger *) outputNumerator
              outputDenominator:(NSUInteger *) outputDenominator;

+ (BOOL)convertEnumMeterMode:(YuneecCameraMeterMode) enumMeterMode
          toIntegerMeterMode:(NSInteger *) integerMeterMode;

+ (BOOL)convertIntegerMeterMode:(NSInteger) integerMeterMode
                toEnumMeterMode:(YuneecCameraMeterMode *) enumMeterMode;

+ (BOOL)convertEnumFlickerMode:(YuneecCameraFlickerMode) enumFlickerMode
          toIntegerFlickerMode:(NSInteger *) integerFlickerMode;

+ (BOOL)convertIntegerFlickerMode:(NSInteger) integerFlickerMode
                toEnumFlickerMode:(YuneecCameraFlickerMode *) enumFlickerMode;

+ (BOOL)convertEnumWhiteBalanceMode:(YuneecCameraWhiteBalanceMode) enumWhiteBalanceMode
          toIntegerWhiteBalanceMode:(NSInteger *) integerWhiteBalanceMode;

+ (BOOL)convertIntegerWhiteBalanceMode:(NSInteger) integerWhileBalanceMode
                toEnumWhiteBalanceMode:(YuneecCameraWhiteBalanceMode *) enumWhiteBalanceMode;

+ (BOOL)convertEnumImageQualityMode:(YuneecCameraImageQualityMode) enumImageQualityMode
          toIntegerImageQualityMode:(NSInteger *) integerImageQualityMode;

+ (BOOL)convertIntegerImageQualityMode:(NSInteger) integerImageQualityMode
                toEnumImageQualityMode:(YuneecCameraImageQualityMode *) enumImageQualityMode;

+ (BOOL)convertEnumVideoCompressionFormat:(YuneecCameraVideoCompressionFormat) enumVideoCompressionFormat
          toIntegerVideoCompressionFormat:(NSInteger *) integerVideoCompressionFormat;

+ (BOOL)convertIntegerVideoCompressionFormat:(NSInteger) integerVideoCompressionFormat
                toEnumVideoCompressionFormat:(YuneecCameraVideoCompressionFormat *) enumVideoCompressionFormat;

+ (BOOL)convertEnumStreamEncoderStyle:(YuneecCameraStreamEncoderStyle) enumStreamEncoderStyle
          toIntegerStreamEncoderStyle:(NSUInteger *) integerStreamEncoderStyle;

+ (BOOL)convertIntegerStreamEncoderStyle:(NSUInteger) integerStreamEncoderStyle
                 toEnumtreamEncoderStyle:(YuneecCameraStreamEncoderStyle *) enumStreamEncoderStyle;

#pragma mark - mavlink converter

+ (BOOL)convertEnumVideoResolution:(YuneecCameraVideoResolution) videoResolution
                enumVideoFrameRate:(YuneecCameraVideoFrameRate) videoFrameRate
           toMavlinkVideoParameter:(NSInteger *)mavlinkVideoParameter;

+ (BOOL)convertMavlinkVideoParameter:(NSInteger) mavlinkVideoParameter
               toEnumVideoResolution:(YuneecCameraVideoResolution *) enumVideoResolution
                  enumVideoFrameRate:(YuneecCameraVideoFrameRate *) enumVideoFrameRate;

+ (BOOL)convertEnumPhotoAspectRatio:(YuneecCameraPhotoAspectRatio) enumPhotoAspectRatio
       mavlinkPhotoAspectRatioWidth:(NSInteger *) mavlinkPhotoAspectRatioWidth
      mavlinkPhotoAspectRatioHeight:(NSInteger *) mavlinkPhotoAspectRatioHeight;

+ (BOOL)convertMavlinkPhotoAspectRatioFloatValue:(float) photoAspectRatioFloatValue
                          toEnumPhotoAspectRatio:(YuneecCameraPhotoAspectRatio *) enumPhotoAspectRatio;

+ (BOOL)convertEnumPhotoFormat:(YuneecCameraPhotoFormat) photoFormat
          toMavlinkPhotoFormat:(NSInteger *) mavlinkPhotoFormat;

+ (BOOL)convertMavlinkPhotoFormat:(NSInteger) mavlinkPhotoFormat
                toEnumPhotoFormat:(YuneecCameraPhotoFormat *) enumPhotoFormat;

+ (BOOL)convertMavlinkShutterTimeValue:(float) shutterTimeValue
                       outputNumerator:(NSUInteger *) outputNumerator
                     outputDenominator:(NSUInteger *) outputDenominator;

+ (BOOL)convertMavlinkExposureValue:(float) exposureValue
                    outputNumerator:(NSUInteger *) outputNumerator
                  outputDenominator:(NSUInteger *) outputDenominator;

+ (BOOL)convertEnumWhiteBalanceMode:(YuneecCameraWhiteBalanceMode) enumWhiteBalanceMode
   toMavlinkIntegerWhiteBalanceMode:(NSInteger *) integerWhiteBalanceMode;

+ (BOOL)convertMavlinkIntegerWhiteBalanceMode:(NSInteger) integerWhileBalanceMode
                       toEnumWhiteBalanceMode:(YuneecCameraWhiteBalanceMode *) enumWhiteBalanceMode;

+ (BOOL)convertCameraName:(NSString *)cameraName
             toCameraType:(YuneecCameraType *)cameraType;

@end
