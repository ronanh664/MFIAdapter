//
//  YuneecCameraStateImp.h
//  YuneecSDK
//
//  Created by tbago on 17/1/20.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import <YuneecCameraSDK/YuneecCameraSDK.h>
#import <YuneecCameraSDK/YuneecCameraState.h>

@interface YuneecCameraStateImp : YuneecCameraState

/**
 * parser camera state data
 *
 * @param cameraStateData input camera state data to parser
 * @return weather camera state changed
 */
- (BOOL)parserCameraStateData:(NSData *) cameraStateData;

@property (strong, nonatomic) NSArray                       *histogramDataArray;

@end
