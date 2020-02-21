//
//  YuneecCameraStreamDataTransfer.h
//  YuneecDataTransferManager
//
//  Created by tbago on 16/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class YuneecCameraStreamDataTransfer;

@protocol YuneecCameraStreamDataTransferDelegate <NSObject>

@required
/**
 * receive H.264 data from camera
 *
 * @param cameraStreamDataTransfer the data transfer instance
 * @param h264Data H.264 data
 * @param keyFrame key frame flag
 * @param decompassTimeStamp Video frame decompass timestamp value (100ns)
 * @param presentTimeStamp Video frame present timestamp value (100ns)
 * @param extraData stream extra data
 */
- (void)cameraStreamDataTransfer:(YuneecCameraStreamDataTransfer *) cameraStreamDataTransfer
              didReceiveH264Data:(NSData *) h264Data
                        keyFrame:(BOOL) keyFrame
              decompassTimeStamp:(int64_t) decompassTimeStamp
                presentTimeStamp:(int64_t) presentTimeStamp
                       extraData:(NSData * __nullable) extraData;

@end

@interface YuneecCameraStreamDataTransfer : NSObject

/*
 * Use this delegate for receive H264 video frame
 */
@property (nonatomic, weak, nullable) id<YuneecCameraStreamDataTransferDelegate>   cameraStreamDelegate;

@property (assign, nonatomic) BOOL enableLowDelay;

/**
 * Open camera stream for transfer H264 frame
 *
 * @return weather open success
 */
- (BOOL)openCameraSteamDataTransfer;

/**
 * The close stream function may block current thread
 */
- (void)closeCameraStreamDataTransfer;

@end

NS_ASSUME_NONNULL_END
