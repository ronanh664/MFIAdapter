//
//  YuneecCameraParameter.m
//  YuneecSDK
//
//  Created by tbago on 17/1/22.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecCameraParameter.h"

NSString *const YuneecCameraSupportVideoResolutionAndFrameRateChangeKey = @"YuneecCameraSupportVideoResolutionAndFrameRateChangeKey";

NSString *const YuneecCameraSupportShutterTimeChangeKey = @"YuneecCameraSupportShutterTimeChangeKey";

@interface YuneecCameraParameter()

@property (nonatomic, readwrite) YuneecCameraType                   currentCameraType;
@property (nonatomic, readwrite) YuneecCameraVideoStandard          currentVideoStandard;
@property (nonatomic, readwrite) YuneecCameraVideoCompressionFormat currentVideoCompressionFormat;
@property (nonatomic, readwrite) YuneecCameraMode                   currentCameraMode;

@end

@implementation YuneecCameraParameter

+ (instancetype)sharedInstance {
    static YuneecCameraParameter *sInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[YuneecCameraParameter alloc] init];
    });
    return sInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentCameraType              = YuneecCameraTypeUnknown;
        _currentVideoStandard           = YuneecCameraVideoStandardUnknown;
        _currentVideoCompressionFormat  = YuneecCameraVideoCompressionFormatUnknown;
    }
    return self;
}

- (void)setCameraType:(YuneecCameraType)cameraType {
    self.currentCameraType = cameraType;
}

- (void)setCameraVideoStandard:(YuneecCameraVideoStandard) cameraVideoStandard {
    self.currentVideoStandard = cameraVideoStandard;
}

- (void)setCameraVideoCompressionFormat:(YuneecCameraVideoCompressionFormat)cameraCompressionFormat {
    self.currentVideoCompressionFormat = cameraCompressionFormat;
}

- (NSArray<NSNumber *> *)supportVideoResolution {
    if (self.currentCameraType == YuneecCameraTypeBreeze
        || self.currentCameraType == YuneecCameraTypeBreeze2
        || self.currentCameraType == YuneecCameraTypeFirebird
        || self.currentCameraType == YuneecCameraTypeHDRacer)
    {
        ///< Breeze Firbird support camera type
        return @[
                    @(YuneecCameraVideoResolution3840x2160),
                    @(YuneecCameraVideoResolution1920x1080),
                    @(YuneecCameraVideoResolution1280x720)
                ];
    }
    else if (self.currentCameraType == YuneecCameraTypeQ400)
    {
        ///< Q400 support camera type
        return @[
                    @(YuneecCameraVideoResolution4096x2160),
                    @(YuneecCameraVideoResolution3840x2160),
                    @(YuneecCameraVideoResolution2560x1440),
                    @(YuneecCameraVideoResolution1920x1080),
                    @(YuneecCameraVideoResolution1280x720)
                ];
    }
    else if (self.currentCameraType == YuneecCameraTypeCGOPro
             || self.currentCameraType == YuneecCameraTypeE90)
    {
        return @[
                    @(YuneecCameraVideoResolution4096x2160),
                    @(YuneecCameraVideoResolution3840x2160),
                    @(YuneecCameraVideoResolution2720x1530),
                    @(YuneecCameraVideoResolution1920x1080),
                    @(YuneecCameraVideoResolution1280x720)
                 ];
    }
    else if (self.currentCameraType == YuneecCameraTypeCGO3Plus
             || self.currentCameraType == YuneecCameraTypeE50)
    {
        return @[
                    @(YuneecCameraVideoResolution4096x2160),
                    @(YuneecCameraVideoResolution3840x2160),
                    @(YuneecCameraVideoResolution2560x1440),
                    @(YuneecCameraVideoResolution1920x1080),
                 ];
    }
    else if (self.currentCameraType == YuneecCameraTypeOB)
    {
        return @[
                    @(YuneecCameraVideoResolution4096x2160),
                    @(YuneecCameraVideoResolution3840x2160),
                    @(YuneecCameraVideoResolution2688x1520),
                    @(YuneecCameraVideoResolution1920x1080),
                    @(YuneecCameraVideoResolution1280x720),
                 ];
    }
    else if (self.currentCameraType == YuneecCameraTypeV18S)
    {
        return @[
                 @(YuneecCameraVideoResolution3840x2160),
                 @(YuneecCameraVideoResolution1920x1080),
                 @(YuneecCameraVideoResolution1280x720),
                 ];
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportVideoFrameRate {
    if (self.currentCameraType == YuneecCameraTypeBreeze
        || self.currentCameraType == YuneecCameraTypeBreeze2
        || self.currentCameraType == YuneecCameraTypeV18S
        || self.currentCameraType == YuneecCameraTypeFirebird
        || self.currentCameraType == YuneecCameraTypeHDRacer) {
        return @[@(YuneecCameraVideoFrameRate30FPS),
                 @(YuneecCameraVideoFrameRate60FPS)];
    }
    else if (self.currentCameraType == YuneecCameraTypeQ400) {
        return @[@(YuneecCameraVideoFrameRate24FPS),
                 @(YuneecCameraVideoFrameRate25FPS),
                 @(YuneecCameraVideoFrameRate30FPS),
                 @(YuneecCameraVideoFrameRate48FPS),
                 @(YuneecCameraVideoFrameRate50FPS),
                 @(YuneecCameraVideoFrameRate60FPS),
                 @(YuneecCameraVideoFrameRate120FPS),
                 @(YuneecCameraVideoFrameRate240FPS)];
    }
    else {
        return [self supportVideoFrameRateByVideoResolution:(YuneecCameraVideoResolution)[[self.supportVideoResolution lastObject] integerValue]];
    }
}

- (NSArray<NSNumber *> *)supportVideoFrameRateByVideoResolution:(YuneecCameraVideoResolution) videoResolution
{
    if (self.currentCameraType == YuneecCameraTypeBreeze
        || self.currentCameraType == YuneecCameraTypeBreeze2
        || self.currentCameraType == YuneecCameraTypeFirebird
        || self.currentCameraType == YuneecCameraTypeHDRacer)
    {
        switch (videoResolution) {
            case YuneecCameraVideoResolution3840x2160:
                return @[@(YuneecCameraVideoFrameRate30FPS)];
                break;
            case YuneecCameraVideoResolution1920x1080:
                return @[@(YuneecCameraVideoFrameRate30FPS)];
                break;
            case YuneecCameraVideoResolution1280x720:
                return @[@(YuneecCameraVideoFrameRate60FPS)];
                break;
            default:
                return @[];
        }
    }
    else if (self.currentCameraType == YuneecCameraTypeV18S)
    {
        switch (videoResolution) {
            case YuneecCameraVideoResolution3840x2160:
                return @[@(YuneecCameraVideoFrameRate30FPS)];
                break;
            case YuneecCameraVideoResolution1920x1080:
                return @[@(YuneecCameraVideoFrameRate30FPS),
                         @(YuneecCameraVideoFrameRate60FPS),];
                break;
            case YuneecCameraVideoResolution1280x720:
                return @[@(YuneecCameraVideoFrameRate60FPS)];
                break;
            default:
                return @[];
        }
    }
    else if (self.currentCameraType == YuneecCameraTypeQ400)
    {
        switch (videoResolution) {
            case YuneecCameraVideoResolution4096x2160:
                return @[@(YuneecCameraVideoFrameRate24FPS),
                         @(YuneecCameraVideoFrameRate25FPS),
                         @(YuneecCameraVideoFrameRate48FPS),
                         @(YuneecCameraVideoFrameRate50FPS),];
                break;
            case YuneecCameraVideoResolution3840x2160:
                return @[@(YuneecCameraVideoFrameRate24FPS),
                         @(YuneecCameraVideoFrameRate25FPS),
                         @(YuneecCameraVideoFrameRate30FPS),
                         @(YuneecCameraVideoFrameRate48FPS),
                         @(YuneecCameraVideoFrameRate50FPS),
                         @(YuneecCameraVideoFrameRate60FPS),];
                break;
            case YuneecCameraVideoResolution2560x1440:
                return @[@(YuneecCameraVideoFrameRate24FPS),
                         @(YuneecCameraVideoFrameRate25FPS),
                         @(YuneecCameraVideoFrameRate30FPS)];
                break;
            case YuneecCameraVideoResolution1920x1080:
                return @[@(YuneecCameraVideoFrameRate24FPS),
                         @(YuneecCameraVideoFrameRate25FPS),
                         @(YuneecCameraVideoFrameRate30FPS),
                         @(YuneecCameraVideoFrameRate48FPS),
                         @(YuneecCameraVideoFrameRate50FPS),
                         @(YuneecCameraVideoFrameRate60FPS),
                         @(YuneecCameraVideoFrameRate120FPS),
                         ];
                break;
            case YuneecCameraVideoResolution1280x720:
                return @[@(YuneecCameraVideoFrameRate240FPS)];
                break;
            default:
                return @[];
                break;
        }
    }
    else if (self.currentCameraType == YuneecCameraTypeCGOPro
             || self.currentCameraType == YuneecCameraTypeE90)
    {
        if (self.currentVideoCompressionFormat == YuneecCameraVideoCompressionFormatH265
            && self.currentVideoStandard == YuneecCameraVideoStandardNTSC)
        {
            switch (videoResolution)
            {
                case YuneecCameraVideoResolution4096x2160:
                case YuneecCameraVideoResolution3840x2160:
                    return @[
                              @(YuneecCameraVideoFrameRate24FPS),
                              @(YuneecCameraVideoFrameRate30FPS),
                              @(YuneecCameraVideoFrameRate60FPS),
                            ];
                    break;
                case YuneecCameraVideoResolution2720x1530:
                case YuneecCameraVideoResolution1920x1080:
                    return @[
                              @(YuneecCameraVideoFrameRate24FPS),
                              @(YuneecCameraVideoFrameRate30FPS),
                              @(YuneecCameraVideoFrameRate48FPS),
                              @(YuneecCameraVideoFrameRate60FPS),
                             ];
                    break;
                case YuneecCameraVideoResolution1280x720:
                    return @[
                              @(YuneecCameraVideoFrameRate24FPS),
                              @(YuneecCameraVideoFrameRate30FPS),
                              @(YuneecCameraVideoFrameRate48FPS),
                              @(YuneecCameraVideoFrameRate60FPS),
                              @(YuneecCameraVideoFrameRate120FPS),
                             ];
                    break;
                default:
                    return @[];
                    break;
            }
        }
        else if (self.currentVideoCompressionFormat == YuneecCameraVideoCompressionFormatH265
                 && self.currentVideoStandard == YuneecCameraVideoStandardPAL)
        {
            switch (videoResolution)
            {
                case YuneecCameraVideoResolution4096x2160:
                case YuneecCameraVideoResolution3840x2160:
                    return @[
                              @(YuneecCameraVideoFrameRate24FPS),
                              @(YuneecCameraVideoFrameRate25FPS),
                              @(YuneecCameraVideoFrameRate50FPS),
                             ];
                    break;
                case YuneecCameraVideoResolution2720x1530:
                case YuneecCameraVideoResolution1920x1080:
                case YuneecCameraVideoResolution1280x720:
                    return @[
                              @(YuneecCameraVideoFrameRate24FPS),
                              @(YuneecCameraVideoFrameRate25FPS),
                              @(YuneecCameraVideoFrameRate48FPS),
                              @(YuneecCameraVideoFrameRate50FPS),
                             ];
                    break;
                default:
                    return @[];
                    break;
            }
        }
        else if (self.currentVideoCompressionFormat == YuneecCameraVideoCompressionFormatH264
                 && self.currentVideoStandard == YuneecCameraVideoStandardNTSC)
        {
            switch (videoResolution)
            {
                case YuneecCameraVideoResolution4096x2160:
                case YuneecCameraVideoResolution3840x2160:
                case YuneecCameraVideoResolution2720x1530:
                    return @[
                              @(YuneecCameraVideoFrameRate24FPS),
                              @(YuneecCameraVideoFrameRate30FPS),
                              @(YuneecCameraVideoFrameRate48FPS),
                              @(YuneecCameraVideoFrameRate60FPS),
                             ];
                    break;
                case YuneecCameraVideoResolution1920x1080:
                case YuneecCameraVideoResolution1280x720:
                    return @[
                              @(YuneecCameraVideoFrameRate24FPS),
                              @(YuneecCameraVideoFrameRate30FPS),
                              @(YuneecCameraVideoFrameRate48FPS),
                              @(YuneecCameraVideoFrameRate60FPS),
                              @(YuneecCameraVideoFrameRate120FPS),
                             ];
                    break;
                default:
                    return @[];
                    break;
            }
        }
        else if (self.currentVideoCompressionFormat == YuneecCameraVideoCompressionFormatH264
                 && self.currentVideoStandard == YuneecCameraVideoStandardPAL)
        {
            switch (videoResolution)
            {
                case YuneecCameraVideoResolution4096x2160:
                case YuneecCameraVideoResolution3840x2160:
                case YuneecCameraVideoResolution2720x1530:
                case YuneecCameraVideoResolution1920x1080:
                case YuneecCameraVideoResolution1280x720:
                    return @[
                             @(YuneecCameraVideoFrameRate24FPS),
                             @(YuneecCameraVideoFrameRate25FPS),
                             @(YuneecCameraVideoFrameRate48FPS),
                             @(YuneecCameraVideoFrameRate50FPS),
                             ];
                    break;
                default:
                    return @[];
                    break;
            }
        }
        else {
            return nil;
        }
    }
    else if (self.currentCameraType == YuneecCameraTypeCGO3Plus
             || self.currentCameraType == YuneecCameraTypeE50)
    {
        switch (videoResolution)
        {
            case YuneecCameraVideoResolution4096x2160:
                return @[@(YuneecCameraVideoFrameRate24FPS),
                         @(YuneecCameraVideoFrameRate25FPS)];
                break;
            case YuneecCameraVideoResolution3840x2160:
            case YuneecCameraVideoResolution2560x1440:
                return @[@(YuneecCameraVideoFrameRate24FPS),
                         @(YuneecCameraVideoFrameRate25FPS),
                         @(YuneecCameraVideoFrameRate30FPS)];
                break;
            case YuneecCameraVideoResolution1920x1080:
                return @[@(YuneecCameraVideoFrameRate24FPS),
                         @(YuneecCameraVideoFrameRate25FPS),
                         @(YuneecCameraVideoFrameRate30FPS),
                         @(YuneecCameraVideoFrameRate48FPS),
                         @(YuneecCameraVideoFrameRate50FPS),
                         @(YuneecCameraVideoFrameRate60FPS),
                         @(YuneecCameraVideoFrameRate120FPS),
                         ];
                break;
            default:
                return @[];
                break;
        }
    }
    else if (self.currentCameraType == YuneecCameraTypeOB)
    {
        if (self.currentVideoStandard == YuneecCameraVideoStandardPAL) {
            switch (videoResolution)
            {
                case YuneecCameraVideoResolution4096x2160:
                    return @[@(YuneecCameraVideoFrameRate24FPS),
                             @(YuneecCameraVideoFrameRate25FPS),
                             ];
                    break;
                case YuneecCameraVideoResolution3840x2160:
                case YuneecCameraVideoResolution2688x1520:
                    return @[@(YuneecCameraVideoFrameRate24FPS),
                             @(YuneecCameraVideoFrameRate25FPS),
                             @(YuneecCameraVideoFrameRate30FPS),
                             ];
                    break;
                case YuneecCameraVideoResolution1920x1080:
                case YuneecCameraVideoResolution1280x720:
                    return @[@(YuneecCameraVideoFrameRate24FPS),
                             @(YuneecCameraVideoFrameRate25FPS),
                             @(YuneecCameraVideoFrameRate30FPS),
                             @(YuneecCameraVideoFrameRate48FPS),
                             @(YuneecCameraVideoFrameRate50FPS),
                             @(YuneecCameraVideoFrameRate60FPS),
                             @(YuneecCameraVideoFrameRate120FPS),
                             ];
                    break;
                default:
                    return @[];
                    break;
            }
        }
        else {
            switch (videoResolution)
            {
                case YuneecCameraVideoResolution4096x2160:
                    return @[@(YuneecCameraVideoFrameRate24FPS),
                             @(YuneecCameraVideoFrameRate25FPS),
                             ];
                    break;
                case YuneecCameraVideoResolution3840x2160:
                case YuneecCameraVideoResolution2688x1520:
                    return @[@(YuneecCameraVideoFrameRate24FPS),
                             @(YuneecCameraVideoFrameRate25FPS),
                             @(YuneecCameraVideoFrameRate30FPS),
                             ];
                    break;
                case YuneecCameraVideoResolution1920x1080:
                case YuneecCameraVideoResolution1280x720:
                    return @[@(YuneecCameraVideoFrameRate24FPS),
                             @(YuneecCameraVideoFrameRate25FPS),
                             @(YuneecCameraVideoFrameRate30FPS),
                             @(YuneecCameraVideoFrameRate48FPS),
                             @(YuneecCameraVideoFrameRate50FPS),
                             @(YuneecCameraVideoFrameRate60FPS),
                             @(YuneecCameraVideoFrameRate120FPS),
                             ];
                    break;
                default:
                    return @[];
                    break;
            }
        }
    }
    else {
        return nil;
    }
}

- (NSArray<NSDictionary *> *)supportVideoResolutionAndFrameRate {
    NSMutableArray *supportArray = [[NSMutableArray alloc] init];
    for (NSNumber *videoResulution in [self supportVideoResolution]) {
        for (NSNumber *frameRate in [self supportVideoFrameRateByVideoResolution:(YuneecCameraVideoResolution)[videoResulution integerValue]]) {
            NSDictionary *dic = @{@"videoResolution"    : videoResulution,
                                  @"frameRate"          : frameRate};
            [supportArray addObject:dic];
        }
    }
    return supportArray;
}

- (NSArray<NSNumber *> *)supportVideoStandard {
    if (self.currentCameraType == YuneecCameraTypeBreeze
        || self.currentCameraType == YuneecCameraTypeBreeze2
        || self.currentCameraType == YuneecCameraTypeFirebird
        || self.currentCameraType == YuneecCameraTypeHDRacer
        || self.currentCameraType == YuneecCameraTypeQ400
        || self.currentCameraType == YuneecCameraTypeV18S) {
        return @[];
    }
    else if (self.currentCameraType == YuneecCameraTypeCGOPro
             || self.currentCameraType == YuneecCameraTypeE90
             || self.currentCameraType == YuneecCameraTypeOB) {
            return @[@(YuneecCameraVideoStandardNTSC),
                     @(YuneecCameraVideoStandardPAL)];
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportVideoMode {
    if (self.currentCameraType == YuneecCameraTypeV18S) {
        return @[@(YuneecCameraVideoModeNormal),
                 @(YuneecCameraVideoModeTimeLapse)];
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportPhotoResolution {
    if (self.currentCameraType == YuneecCameraTypeBreeze
        || self.currentCameraType == YuneecCameraTypeBreeze2
        ||self.currentCameraType == YuneecCameraTypeFirebird
        || self.currentCameraType == YuneecCameraTypeHDRacer)
    {
        return @[@(YuneecCameraPhotoResolution4160x3120)];
    }
    else if (self.currentCameraType == YuneecCameraTypeQ400
             || self.currentCameraType == YuneecCameraTypeCGOPro
             || self.currentCameraType == YuneecCameraTypeE90)
    {
        return @[@(YuneecCameraPhotoResolution4160x3120),
                 @(YuneecCameraPhotoResolution4000x3000),
                 @(YuneecCameraPhotoResolution3968x2232),
                 @(YuneecCameraPhotoResolution3936x2624),
                 @(YuneecCameraPhotoResolution3264x2448),
                 @(YuneecCameraPhotoResolution3008x3000),
                 @(YuneecCameraPhotoResolution2592x1944)];
    }else if (self.currentCameraType == YuneecCameraTypeV18S) {
        return @[@(YuneecCameraPhotoResolution4160x3120)];
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportPhotoAspectRatio {
    if (self.currentCameraType == YuneecCameraTypeCGOPro
        || self.currentCameraType == YuneecCameraTypeE90
        || self.currentCameraType == YuneecCameraTypeFirebird
        || self.currentCameraType == YuneecCameraTypeHDRacer)
    {
        return @[@(YuneecCameraPhotoAspectRatio4_3),
                 @(YuneecCameraPhotoAspectRatio16_9),
                 @(YuneecCameraPhotoAspectRatio3_2)];
    }
    else if (self.currentCameraType == YuneecCameraTypeOB)
    {
        return @[@(YuneecCameraPhotoAspectRatio4_3),
                 @(YuneecCameraPhotoAspectRatio16_9)];
    }
    else if (self.currentCameraType == YuneecCameraTypeV18S)
    {
        return @[@(YuneecCameraPhotoAspectRatio4_3),
                 @(YuneecCameraPhotoAspectRatio16_9)];
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportPhotoQuality {
    if (self.currentCameraType == YuneecCameraTypeBreeze
        || self.currentCameraType == YuneecCameraTypeBreeze2
        || self.currentCameraType == YuneecCameraTypeQ400
        || self.currentCameraType == YuneecCameraTypeCGOPro
        || self.currentCameraType == YuneecCameraTypeE90)
    {
        return @[@(YuneecCameraPhotoQualityHigh),
                 @(YuneecCameraPhotoQualityNormal)];
    }
    else if (self.currentCameraType == YuneecCameraTypeFirebird
             || self.currentCameraType == YuneecCameraTypeHDRacer
             || self.currentCameraType == YuneecCameraTypeOB)
    {
        return @[@(YuneecCameraPhotoQualityLow),
                 @(YuneecCameraPhotoQualityNormal),
                 @(YuneecCameraPhotoQualityHigh),
                 @(YuneecCameraPhotoQualityUltraHigh)];
    }
    else if (self.currentCameraType == YuneecCameraTypeV18S)
    {
        return @[@(YuneecCameraPhotoQualityNormal),
                 @(YuneecCameraPhotoQualityHigh),
                 @(YuneecCameraPhotoQualityUltraHigh)];
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportPhotoFormat {
    if (self.currentCameraType == YuneecCameraTypeBreeze
        || self.currentCameraType == YuneecCameraTypeBreeze2)
    {
        return @[@(YuneecCameraPhotoFormatJpg)];
    }
    else if (self.currentCameraType == YuneecCameraTypeQ400
             || self.currentCameraType == YuneecCameraTypeFirebird
             || self.currentCameraType == YuneecCameraTypeHDRacer
             || self.currentCameraType == YuneecCameraTypeCGOPro
             || self.currentCameraType == YuneecCameraTypeE90)
    {
        return @[@(YuneecCameraPhotoFormatJpg),
                 @(YuneecCameraPhotoFormatJpgRaw),
                 @(YuneecCameraPhotoFormatJpgDng)];
    }
    else if (self.currentCameraType == YuneecCameraTypeCGO3Plus
             || self.currentCameraType == YuneecCameraTypeE50)
    {
        return @[@(YuneecCameraPhotoFormatJpg),
                 @(YuneecCameraPhotoFormatDng),
                 @(YuneecCameraPhotoFormatJpgDng)];
    }
    else if (self.currentCameraType == YuneecCameraTypeOB) {
        return @[@(YuneecCameraPhotoFormatJpg),
                 @(YuneecCameraPhotoFormatJpgRaw)];
    }
    else if (self.currentCameraType == YuneecCameraTypeV18S) {
        return @[@(YuneecCameraPhotoFormatJpg),
                 @(YuneecCameraPhotoFormatJpgDng)];
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportPhotoMode {
    if (self.currentCameraType == YuneecCameraTypeBreeze
        || self.currentCameraType == YuneecCameraTypeBreeze2)
    {
        return @[@(YuneecCameraPhotoModeSingle)];
    }
    else if (self.currentCameraType == YuneecCameraTypeQ400
             || self.currentCameraType == YuneecCameraTypeFirebird
             || self.currentCameraType == YuneecCameraTypeHDRacer)
    {
        return @[
                    @(YuneecCameraPhotoModeSingle),
                    @(YuneecCameraPhotoModeTimeLapse),
                    @(YuneecCameraPhotoModeBurst),
                    @(YuneecCameraPhotoModeAeb)
                 ];
    }
    else if (self.currentCameraType == YuneecCameraTypeCGOPro
             || self.currentCameraType == YuneecCameraTypeE90) {
        return @[
                    @(YuneecCameraPhotoModeSingle),
                    @(YuneecCameraPhotoModeTimeLapse),
                    @(YuneecCameraPhotoModeBurst),
                    @(YuneecCameraPhotoModeAeb),
                    @(YuneecCameraPhotoModePanoramaHorizon),
                    @(YuneecCameraPhotoModePanoramaHemisphere),
                ];
    }
    else if (self.currentCameraType == YuneecCameraTypeE50)
    {
        return @[
                    @(YuneecCameraPhotoModeSingle),
                    @(YuneecCameraPhotoModeTimeLapse),
                    @(YuneecCameraPhotoModeBurst),
                    @(YuneecCameraPhotoModePanoramaHorizon),
                    @(YuneecCameraPhotoModePanoramaHemisphere),
                 ];
    }
    else if (self.currentCameraType == YuneecCameraTypeCGO3Plus) {
        return @[
                    @(YuneecCameraPhotoModeSingle),
                    @(YuneecCameraPhotoModeTimeLapse),
                    @(YuneecCameraPhotoModeBurst),
                 ];
    }
    else if (self.currentCameraType == YuneecCameraTypeOB) {
        return @[
                 @(YuneecCameraPhotoModeSingle),
                 @(YuneecCameraPhotoModeTimeLapse),
                 @(YuneecCameraPhotoModeBurst),
                 @(YuneecCameraPhotoModeAeb),
                 @(YuneecCameraPhotoModePanorama360),
                 @(YuneecCameraPhotoModeGesture),
                 @(YuneecCameraPhotoModeFaceRecognition),
                 ];
    }
    else if (self.currentCameraType == YuneecCameraTypeV18S) {
        return @[
                 @(YuneecCameraPhotoModeSingle),
                 @(YuneecCameraPhotoModeGesture),
                 @(YuneecCameraPhotoModeFaceRecognition),
                 ];
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportPhotoModeBurstAmount {
    if (self.currentCameraType == YuneecCameraTypeQ400
        || self.currentCameraType == YuneecCameraTypeFirebird
        || self.currentCameraType == YuneecCameraTypeHDRacer
        || self.currentCameraType == YuneecCameraTypeCGOPro
        || self.currentCameraType == YuneecCameraTypeE90
        || self.currentCameraType == YuneecCameraTypeCGO3Plus
        || self.currentCameraType == YuneecCameraTypeE50
        || self.currentCameraType == YuneecCameraTypeOB)
    {
        return @[@(3), @(5), @(7)];
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportPhotoModeTimer {
    if (self.currentCameraType == YuneecCameraTypeOB) {
        return @[@(2), @(5), @(10)];
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportPhotoModeTimelapseMillisecond {
    if (self.currentCameraType == YuneecCameraTypeQ400
        || self.currentCameraType == YuneecCameraTypeFirebird
        || self.currentCameraType == YuneecCameraTypeHDRacer
        || self.currentCameraType == YuneecCameraTypeCGOPro
        || self.currentCameraType == YuneecCameraTypeE90
        || self.currentCameraType == YuneecCameraTypeCGO3Plus
        || self.currentCameraType == YuneecCameraTypeE50)
    {
        return @[@(2000), @(5000), @(10000), @(15000), @(20000)];
    }
    else if (self.currentCameraType == YuneecCameraTypeOB) {
        return @[@(2000), @(5000), @(10000)];
    }
    else {
        return nil;
    }
}

- (NSArray<YuneecRational *> *)supportPhotoModeAebEvStepByAmount:(NSInteger) burstAmount {
    if (self.currentCameraType == YuneecCameraTypeQ400
        || self.currentCameraType == YuneecCameraTypeFirebird
        || self.currentCameraType == YuneecCameraTypeHDRacer
        || self.currentCameraType == YuneecCameraTypeCGOPro
        || self.currentCameraType == YuneecCameraTypeE90
        || self.currentCameraType == YuneecCameraTypeOB) {
        if (burstAmount == 3) {
            return @[
                        [[YuneecRational alloc] initWithNumerator:-20 denominator:10],
                        [[YuneecRational alloc] initWithNumerator:-15 denominator:10],
                        [[YuneecRational alloc] initWithNumerator:-10 denominator:10],
                        [[YuneecRational alloc] initWithNumerator:-5  denominator:10],
                        [[YuneecRational alloc] initWithNumerator:0   denominator:10],
                        [[YuneecRational alloc] initWithNumerator:5   denominator:10],
                        [[YuneecRational alloc] initWithNumerator:10  denominator:10],
                        [[YuneecRational alloc] initWithNumerator:15  denominator:10],
                        [[YuneecRational alloc] initWithNumerator:20  denominator:10]
                     ];
        }
        else if (burstAmount == 5) {
            return @[
                        [[YuneecRational alloc] initWithNumerator:-10 denominator:10],
                        [[YuneecRational alloc] initWithNumerator:-5  denominator:10],
                        [[YuneecRational alloc] initWithNumerator:0   denominator:10],
                        [[YuneecRational alloc] initWithNumerator:5   denominator:10],
                        [[YuneecRational alloc] initWithNumerator:10  denominator:10],
                     ];
        }
        else if (burstAmount == 7) {
            return @[
                        [[YuneecRational alloc] initWithNumerator:-5  denominator:10],
                        [[YuneecRational alloc] initWithNumerator:0   denominator:10],
                        [[YuneecRational alloc] initWithNumerator:5   denominator:10],
                     ];
        }
        else {
            return nil;
        }
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportAEMode {
    if (self.currentCameraType ==YuneecCameraTypeBreeze
        || self.currentCameraType == YuneecCameraTypeBreeze2
        || self.currentCameraType == YuneecCameraTypeCGO3Plus
        || self.currentCameraType == YuneecCameraTypeE50
        || self.currentCameraType == YuneecCameraTypeV18S)
    {
        return @[
                    @(YuneecCameraAEModeAuto),
                    @(YuneecCameraAEModeManual),
                 ];
    }
    else if (self.currentCameraType == YuneecCameraTypeQ400
             || self.currentCameraType == YuneecCameraTypeFirebird
             || self.currentCameraType == YuneecCameraTypeHDRacer
             || self.currentCameraType == YuneecCameraTypeCGOPro
             || self.currentCameraType == YuneecCameraTypeE90
             || self.currentCameraType == YuneecCameraTypeOB)
    {
        return @[
                    @(YuneecCameraAEModeAuto),
                    @(YuneecCameraAEModeManual),
                    @(YuneecCameraAEModeLock),
                 ];
    }
    else {
        return nil;
    }
}

- (NSArray<YuneecRational *> *)supportExposureValue {
    if (self.currentCameraType == YuneecCameraTypeBreeze
        || self.currentCameraType == YuneecCameraTypeBreeze2
        || self.currentCameraType == YuneecCameraTypeQ400
        || self.currentCameraType == YuneecCameraTypeCGO3Plus
        || self.currentCameraType == YuneecCameraTypeE50)
    {
        return @[
                  [[YuneecRational alloc] initWithNumerator:-20 denominator:10],
                  [[YuneecRational alloc] initWithNumerator:-15 denominator:10],
                  [[YuneecRational alloc] initWithNumerator:-10 denominator:10],
                  [[YuneecRational alloc] initWithNumerator:-5  denominator:10],
                  [[YuneecRational alloc] initWithNumerator:0   denominator:10],
                  [[YuneecRational alloc] initWithNumerator:5   denominator:10],
                  [[YuneecRational alloc] initWithNumerator:10  denominator:10],
                  [[YuneecRational alloc] initWithNumerator:15  denominator:10],
                  [[YuneecRational alloc] initWithNumerator:20  denominator:10]
                ];
    }
    else if (self.currentCameraType == YuneecCameraTypeCGOPro
             || self.currentCameraType == YuneecCameraTypeE90
             || self.currentCameraType == YuneecCameraTypeFirebird
             || self.currentCameraType == YuneecCameraTypeHDRacer
             || self.currentCameraType == YuneecCameraTypeOB
             || self.currentCameraType == YuneecCameraTypeV18S)
    {
        return @[
                 [[YuneecRational alloc] initWithNumerator:-30 denominator:10],
                 [[YuneecRational alloc] initWithNumerator:-25 denominator:10],
                 [[YuneecRational alloc] initWithNumerator:-20 denominator:10],
                 [[YuneecRational alloc] initWithNumerator:-15 denominator:10],
                 [[YuneecRational alloc] initWithNumerator:-10 denominator:10],
                 [[YuneecRational alloc] initWithNumerator:-5  denominator:10],
                 [[YuneecRational alloc] initWithNumerator:0   denominator:10],
                 [[YuneecRational alloc] initWithNumerator:5   denominator:10],
                 [[YuneecRational alloc] initWithNumerator:10  denominator:10],
                 [[YuneecRational alloc] initWithNumerator:15  denominator:10],
                 [[YuneecRational alloc] initWithNumerator:20  denominator:10],
                 [[YuneecRational alloc] initWithNumerator:25  denominator:10],
                 [[YuneecRational alloc] initWithNumerator:30  denominator:10],
                ];
    }
    else {
        return nil;
    }
}

- (void)setCameraMode:(YuneecCameraMode) cameraMode {
    self.currentCameraMode = cameraMode;
}

- (NSArray<YuneecRational *> *)supportShutterTime {
    if (self.currentCameraType == YuneecCameraTypeBreeze
        || self.currentCameraType == YuneecCameraTypeBreeze2
        || self.currentCameraType == YuneecCameraTypeQ400)
    {
        return @[
                 [[YuneecRational alloc] initWithNumerator:8    denominator:1],
                 [[YuneecRational alloc] initWithNumerator:7    denominator:1],
                 [[YuneecRational alloc] initWithNumerator:6    denominator:1],
                 [[YuneecRational alloc] initWithNumerator:5    denominator:1],
                 [[YuneecRational alloc] initWithNumerator:4    denominator:1],
                 [[YuneecRational alloc] initWithNumerator:3    denominator:1],
                 [[YuneecRational alloc] initWithNumerator:2    denominator:1],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:1],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:30],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:60],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:125],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:250],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:500],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:1000],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:2000],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:4000],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:8000],
                ];
    }
    else if (self.currentCameraType == YuneecCameraTypeOB)
    {
        return @[
                 [[YuneecRational alloc] initWithNumerator:8    denominator:1],
                 [[YuneecRational alloc] initWithNumerator:4    denominator:1],
                 [[YuneecRational alloc] initWithNumerator:2    denominator:1],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:1],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:2],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:4],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:8],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:16],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:30],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:60],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:125],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:250],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:500],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:1000],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:2000],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:4000],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:8000],
                 ];
    }
    else if (self.currentCameraType == YuneecCameraTypeV18S)
    {
        return @[
                 [[YuneecRational alloc] initWithNumerator:1    denominator:8000],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:4000],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:2000],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:1000],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:500],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:250],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:125],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:60],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:30],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:16],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:8],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:4],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:2],
                 [[YuneecRational alloc] initWithNumerator:1    denominator:1],
                 [[YuneecRational alloc] initWithNumerator:2    denominator:1],
                 [[YuneecRational alloc] initWithNumerator:4    denominator:1],
                 [[YuneecRational alloc] initWithNumerator:6    denominator:1],
                 [[YuneecRational alloc] initWithNumerator:8    denominator:1],
                 ];
    }
    else if (self.currentCameraType == YuneecCameraTypeFirebird
             || self.currentCameraType == YuneecCameraTypeHDRacer)
    {
        if (self.currentCameraMode == YuneecCameraModePhoto) {
            return @[
                     [[YuneecRational alloc] initWithNumerator:8    denominator:1],
                     [[YuneecRational alloc] initWithNumerator:7    denominator:1],
                     [[YuneecRational alloc] initWithNumerator:6    denominator:1],
                     [[YuneecRational alloc] initWithNumerator:5    denominator:1],
                     [[YuneecRational alloc] initWithNumerator:4    denominator:1],
                     [[YuneecRational alloc] initWithNumerator:3    denominator:1],
                     [[YuneecRational alloc] initWithNumerator:2    denominator:1],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:1],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:15],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:30],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:60],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:125],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:250],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:500],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:1000],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:2000],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:4000],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:8000],
                     ];
        }
        else if (self.currentCameraMode == YuneecCameraModeVideo) {
            return @[
                     [[YuneecRational alloc] initWithNumerator:1    denominator:30],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:60],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:125],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:250],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:500],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:1000],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:2000],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:4000],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:8000],
                     ];
        }
        else {
            return @[];
        }
    }
    else if (self.currentCameraType == YuneecCameraTypeCGOPro
             || self.currentCameraType == YuneecCameraTypeE90)
    {
        if (self.currentCameraMode == YuneecCameraModePhoto)
        {
            return @[
                     [[YuneecRational alloc] initWithNumerator:8    denominator:1],
                     [[YuneecRational alloc] initWithNumerator:7    denominator:1],
                     [[YuneecRational alloc] initWithNumerator:6    denominator:1],
                     [[YuneecRational alloc] initWithNumerator:5    denominator:1],
                     [[YuneecRational alloc] initWithNumerator:4    denominator:1],
                     [[YuneecRational alloc] initWithNumerator:320  denominator:100],
                     [[YuneecRational alloc] initWithNumerator:3    denominator:1],
                     [[YuneecRational alloc] initWithNumerator:250  denominator:100],
                     [[YuneecRational alloc] initWithNumerator:2    denominator:1],
                     [[YuneecRational alloc] initWithNumerator:160  denominator:100],
                     [[YuneecRational alloc] initWithNumerator:130  denominator:100],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:1],
                     [[YuneecRational alloc] initWithNumerator:100  denominator:125],
                     [[YuneecRational alloc] initWithNumerator:100  denominator:167],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:2],
                     [[YuneecRational alloc] initWithNumerator:100  denominator:250],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:3],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:4],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:5],
                     [[YuneecRational alloc] initWithNumerator:100  denominator:625],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:10],
                     [[YuneecRational alloc] initWithNumerator:100  denominator:125],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:15],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:20],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:25],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:30],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:40],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:50],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:60],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:80],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:100],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:120],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:160],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:200],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:240],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:320],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:400],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:500],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:640],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:800],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:1000],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:1250],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:1600],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:2000],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:2500],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:3200],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:4000],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:5000],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:6400],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:8000],
                     ];
        }
        else if (self.currentCameraMode == YuneecCameraModeVideo)
        {
            return @[
                     [[YuneecRational alloc] initWithNumerator:1    denominator:30],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:40],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:50],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:60],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:80],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:100],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:120],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:160],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:200],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:240],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:320],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:400],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:500],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:640],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:800],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:1000],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:1250],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:1600],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:2000],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:2500],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:3200],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:4000],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:5000],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:6400],
                     [[YuneecRational alloc] initWithNumerator:1    denominator:8000],
                     ];
        }
        else {
            return @[];
        }
    }
    else if (self.currentCameraType == YuneecCameraTypeCGO3Plus
             || self.currentCameraType == YuneecCameraTypeE50)
    {
        return @[
                    [[YuneecRational alloc] initWithNumerator:1    denominator:30],
                    [[YuneecRational alloc] initWithNumerator:1    denominator:60],
                    [[YuneecRational alloc] initWithNumerator:1    denominator:125],
                    [[YuneecRational alloc] initWithNumerator:1    denominator:250],
                    [[YuneecRational alloc] initWithNumerator:1    denominator:500],
                    [[YuneecRational alloc] initWithNumerator:1    denominator:1000],
                    [[YuneecRational alloc] initWithNumerator:1    denominator:2000],
                    [[YuneecRational alloc] initWithNumerator:1    denominator:4000],
                    [[YuneecRational alloc] initWithNumerator:1    denominator:8000],
                ];
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportISOValue {
    if (self.currentCameraType == YuneecCameraTypeBreeze
        || self.currentCameraType == YuneecCameraTypeBreeze2
        || self.currentCameraType == YuneecCameraTypeQ400
        || self.currentCameraType == YuneecCameraTypeFirebird
        || self.currentCameraType == YuneecCameraTypeHDRacer)
    {
        return @[ @(100), @(150), @(200), @(300), @(400), @(600), @(800), @(1600), @(3200), @(6400)];
    }
    else if (self.currentCameraType == YuneecCameraTypeCGOPro
             || self.currentCameraType == YuneecCameraTypeE90) {
        return @[ @(100), @(200), @(400), @(800), @(1600), @(3200), @(6400)];
    }
    else if (self.currentCameraType == YuneecCameraTypeOB) {
        if (self.currentCameraMode == YuneecCameraModeVideo) {
            return @[ @(100), @(200), @(400), @(800), @(1600), @(3200)];
        }else {
            return @[ @(100), @(200), @(400), @(800), @(1600)];
        }
    }
    else if (self.currentCameraType == YuneecCameraTypeV18S) {
        return @[ @(100), @(200), @(400), @(800), @(1600), @(3200)];
    }
    else if (self.currentCameraType == YuneecCameraTypeCGO3Plus
             || self.currentCameraType == YuneecCameraTypeE50)
    {
        return @[ @(100), @(150), @(200), @(300), @(400), @(600), @(800), @(1600), @(3200)];
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportMeterMode {
    if (self.currentCameraType == YuneecCameraTypeBreeze
        || self.currentCameraType == YuneecCameraTypeBreeze2
        || self.currentCameraType == YuneecCameraTypeQ400
        || self.currentCameraType == YuneecCameraTypeFirebird
        || self.currentCameraType == YuneecCameraTypeHDRacer
        || self.currentCameraType == YuneecCameraTypeCGOPro
        || self.currentCameraType == YuneecCameraTypeE90
        || self.currentCameraType == YuneecCameraTypeCGO3Plus
        || self.currentCameraType == YuneecCameraTypeE50
        || self.currentCameraType == YuneecCameraTypeOB
        || self.currentCameraType == YuneecCameraTypeV18S)
    {
        return @[
                  @(YuneecCameraMeterModeCenter),
                  @(YuneecCameraMeterModeAverage),
                  @(YuneecCameraMeterModeSpot)
                ];
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportFlickerMode {
    if (self.currentCameraType == YuneecCameraTypeBreeze
        || self.currentCameraType == YuneecCameraTypeBreeze2
        || self.currentCameraType == YuneecCameraTypeQ400
        || self.currentCameraType == YuneecCameraTypeFirebird
        || self.currentCameraType == YuneecCameraTypeHDRacer
        || self.currentCameraType == YuneecCameraTypeCGOPro
        || self.currentCameraType == YuneecCameraTypeE90
        || self.currentCameraType == YuneecCameraTypeOB
        || self.currentCameraType == YuneecCameraTypeV18S)
    {
        return @[ @(YuneecCameraFlickerModeAuto),
                  @(YuneecCameraFlickerMode60Hz),
                  @(YuneecCameraFlickerMode50Hz)];
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportWhiteBalanceMode {
    if (self.currentCameraType == YuneecCameraTypeQ400
        || self.currentCameraType == YuneecCameraTypeCGO3Plus
        || self.currentCameraType == YuneecCameraTypeE50
        || self.currentCameraType == YuneecCameraTypeBreeze
        || self.currentCameraType == YuneecCameraTypeBreeze2)
    {
        return @[ @(YuneecCameraWhiteBalanceModeAuto),
                  @(YuneecCameraWhiteBalanceModeSunny),
                  @(YuneecCameraWhiteBalanceModeSunrise),
                  @(YuneecCameraWhiteBalanceModeCloudy),
                  @(YuneecCameraWhiteBalanceModeFlucrescent),
                  @(YuneecCameraWhiteBalanceModeIncandescent),
                  @(YuneecCameraWhiteBalanceModeLock)];
    }
    else if (self.currentCameraType == YuneecCameraTypeFirebird
             || self.currentCameraType == YuneecCameraTypeHDRacer
             || self.currentCameraType == YuneecCameraTypeCGOPro
             || self.currentCameraType == YuneecCameraTypeE90) {
        return @[ @(YuneecCameraWhiteBalanceModeAuto),
                  @(YuneecCameraWhiteBalanceModeSunny),
                  @(YuneecCameraWhiteBalanceModeSunrise),
                  @(YuneecCameraWhiteBalanceModeSunset),
                  @(YuneecCameraWhiteBalanceModeCloudy),
                  @(YuneecCameraWhiteBalanceModeFlucrescent),
                  @(YuneecCameraWhiteBalanceModeIncandescent),
                  @(YuneecCameraWhiteBalanceModeLock),
                  @(YuneecCameraWhiteBalanceModeManual)];
    }
    else if (self.currentCameraType == YuneecCameraTypeOB) {
        return @[ @(YuneecCameraWhiteBalanceModeAuto),
                  @(YuneecCameraWhiteBalanceModeSunny),
                  @(YuneecCameraWhiteBalanceModeCloudy),
                  @(YuneecCameraWhiteBalanceModeFlucrescent),
                  @(YuneecCameraWhiteBalanceModeIncandescent),
                  @(YuneecCameraWhiteBalanceModeLock),
                  @(YuneecCameraWhiteBalanceModeManual)];
    }
    else if (self.currentCameraType == YuneecCameraTypeV18S) {
        return @[ @(YuneecCameraWhiteBalanceModeAuto),
                  @(YuneecCameraWhiteBalanceModeSunny),
                  @(YuneecCameraWhiteBalanceModeCloudy),
                  @(YuneecCameraWhiteBalanceModeFlucrescent),
                  @(YuneecCameraWhiteBalanceModeIncandescent),
                  @(YuneecCameraWhiteBalanceModeLock)];
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportManualWhiteBalanceValue {
    
    uint32_t minValue = 30;
    uint32_t maxValue = 80;
    
    if (self.currentCameraType == YuneecCameraTypeV18S) {
        minValue = 28;
    }
    
    NSMutableArray<NSNumber *> *manualWhiteBalanceArray = [[NSMutableArray alloc] init];
    for (uint32_t i = minValue; i <= maxValue; i++) {
        [manualWhiteBalanceArray addObject:@(i)];
    }
    return manualWhiteBalanceArray;
}

- (NSArray<NSNumber *> *)supportImageQualityMode {
    if (self.currentCameraType == YuneecCameraTypeBreeze
        || self.currentCameraType == YuneecCameraTypeBreeze2
        || self.currentCameraType == YuneecCameraTypeQ400
        || self.currentCameraType == YuneecCameraTypeHDRacer
        || self.currentCameraType == YuneecCameraTypeCGO3Plus
        || self.currentCameraType == YuneecCameraTypeE50
        || self.currentCameraType == YuneecCameraTypeOB)
    {
        return @[ @(YuneecCameraImageQualityModeNature),
                  @(YuneecCameraImageQualityModeSaturation),
                  @(YuneecCameraImageQualityModeRaw),
                  @(YuneecCameraImageQualityModeNight)
                ];
    }
    else if (self.currentCameraType == YuneecCameraTypeFirebird
             || self.currentCameraType == YuneecCameraTypeHDRacer
             || self.currentCameraType == YuneecCameraTypeCGOPro
             || self.currentCameraType == YuneecCameraTypeE90) {
        return @[ @(YuneecCameraImageQualityModeNature),
                  @(YuneecCameraImageQualityModeSaturation),
                  @(YuneecCameraImageQualityModeRaw),
                  @(YuneecCameraImageQualityModeNight),
                  @(YuneecCameraImageQualityModeLog),
                ];
    }
    else if (self.currentCameraType == YuneecCameraTypeV18S) {
        return @[ @(YuneecCameraImageQualityModeNature),
                  @(YuneecCameraImageQualityModeSaturation),
                  @(YuneecCameraImageQualityModeSoft),
                  ];
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportVideoCompressionFormat {
    if (self.currentCameraType == YuneecCameraTypeBreeze
        || self.currentCameraType == YuneecCameraTypeBreeze2
        || self.currentCameraType == YuneecCameraTypeFirebird
        || self.currentCameraType == YuneecCameraTypeHDRacer
        || self.currentCameraType == YuneecCameraTypeV18S) {
        return @[ @(YuneecCameraVideoCompressionFormatH264)];
    }
    else if (self.currentCameraType == YuneecCameraTypeCGOPro
             || self.currentCameraType == YuneecCameraTypeE90
             || self.currentCameraType == YuneecCameraTypeQ400)
    {
        return @[ @(YuneecCameraVideoCompressionFormatH264),
                  @(YuneecCameraVideoCompressionFormatH265)];
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportVideoFileFormat {
    if (self.currentCameraType == YuneecCameraTypeBreeze
        || self.currentCameraType == YuneecCameraTypeBreeze2
        || self.currentCameraType == YuneecCameraTypeQ400
        || self.currentCameraType == YuneecCameraTypeCGO3Plus
        || self.currentCameraType == YuneecCameraTypeE50) {
        return @[ @(YuneecCameraVideoFileFormatMOV)];
    }
    else if (self.currentCameraType == YuneecCameraTypeCGOPro
             || self.currentCameraType == YuneecCameraTypeE90
             || self.currentCameraType == YuneecCameraTypeFirebird
             || self.currentCameraType == YuneecCameraTypeHDRacer
             || self.currentCameraType == YuneecCameraTypeOB
             || self.currentCameraType == YuneecCameraTypeV18S)
    {
        return @[ @(YuneecCameraVideoFileFormatMOV),
                  @(YuneecCameraVideoFileFormatMP4)];
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportStreamEncoderStyle {
    return @[@(YuneecCameraStreamEncoderStyleNo),
             @(YuneecCameraStreamEncoderStyleSliceAndIntra)];
}

- (NSArray<NSNumber *> *)supportImageFlipDegree {
    return @[@(YuneecCameraImageFlipDegree0),
             @(YuneecCameraImageFlipDegree90),
             @(YuneecCameraImageFlipDegree180),
             @(YuneecCameraImageFlipDegree270)];
}

- (NSArray<NSNumber *> *)supportStyle {
    if (self.currentCameraType == YuneecCameraTypeV18S) {
        return @[@(YuneecCameraStyleStandard),
                 @(YuneecCameraStyleLandscape),
                 @(YuneecCameraStyleSoft),
                 @(YuneecCameraStyleCustom)];
    }
    else {
        return nil;
    }
}

- (NSArray<NSNumber *> *)supportCenterPoints {
    return @[@(YuneecCameraCenterPointsTypeNone),
             @(YuneecCameraCenterPointsTypeCircle),
             @(YuneecCameraCenterPointsTypeCross),
             @(YuneecCameraCenterPointsTypeSquareWithNoPoint),
             @(YuneecCameraCenterPointsTypeSquareWithPoint)];
    
}

- (void)setCurrentVideoStandard:(YuneecCameraVideoStandard)currentVideoStandard {
    if (_currentVideoStandard != currentVideoStandard)
    {
        _currentVideoStandard = currentVideoStandard;
        [self callChangeVideoResolutionAndFrameRateDelegate];
    }
}

- (void)setCurrentVideoCompressionFormat:(YuneecCameraVideoCompressionFormat)currentVideoCompressionFormat {
    if (_currentVideoCompressionFormat != currentVideoCompressionFormat) {
        _currentVideoCompressionFormat = currentVideoCompressionFormat;
        [self callChangeVideoResolutionAndFrameRateDelegate];
    }
}

- (void)callChangeVideoResolutionAndFrameRateDelegate {
    if (self.cameraParameterDelegate != nil)
    {
        if ([self.cameraParameterDelegate respondsToSelector:@selector(cameraParameter:didChangeParameter:)]) {
            [self.cameraParameterDelegate cameraParameter:self
                                       didChangeParameter:YuneecCameraSupportVideoResolutionAndFrameRateChangeKey];
        }
    }
}

- (void)setCurrentCameraMode:(YuneecCameraMode)currentCameraMode {
    if (_currentCameraMode != currentCameraMode) {
        _currentCameraMode = currentCameraMode;
        if (self.currentCameraType == YuneecCameraTypeCGOPro
            || self.currentCameraType == YuneecCameraTypeE90
            || self.currentCameraType == YuneecCameraTypeCGO3Plus
            || self.currentCameraType == YuneecCameraTypeE50
            || self.currentCameraType == YuneecCameraTypeFirebird
            || self.currentCameraType == YuneecCameraTypeHDRacer)
        {
            [self callChangeShutterTimeDelegate];
        }
    }
}

- (void)callChangeShutterTimeDelegate {
    if (self.cameraParameterDelegate != nil) {
        if ([self.cameraParameterDelegate respondsToSelector:@selector(cameraParameter:didChangeParameter:)]) {
            [self.cameraParameterDelegate cameraParameter:self
                                       didChangeParameter:YuneecCameraSupportShutterTimeChangeKey];
        }
    }
}

@end
