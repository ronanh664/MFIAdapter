//
//  YuneecMedia_Extension.h
//  YuneecSDK
//
//  Created by Mine on 2017/4/27.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecMedia.h"

@interface YuneecMedia ()
/**
 *  Returns the type of media file.
 */
@property (nonatomic, readwrite) YuneecMediaType mediaType;

/**
 *  Returns the name of the media file.
 */
@property (nonatomic, readwrite) NSString *_Nonnull fileName;

/**
 *  Returns the time when the media file was created as a string in
 *  the format "YYYY-MMM-dd HH:mm:ss".
 */
@property (nonatomic, readwrite) NSString *_Nonnull createDate;

/**
 *  Returns the size of the media file.
 */
@property (nonatomic, readwrite) NSString *_Nonnull fileSize;

/**
 Returns MD5 of the media file
 */
@property (nonatomic, readwrite) NSString *_Nullable fileMD5;

/**
 *  If the media file is a video, this property returns the duration
 *  of the video in seconds.
 */
@property (nonatomic, readwrite) float videoDuration;

/**
 *  If the media file is a video, this property returns the resolution
 *  of the video.
 */
@property (nonatomic, readwrite) YuneecMediaVideoResolution videoResolution;

/**
 Returns thumbnail of the media file
 */
@property (nonatomic, strong, readwrite) YuneecMedia *_Nullable thumbnailMedia;

/**
 Returns preview video of the media file
 */
@property (nonatomic, strong, readwrite) YuneecMedia *_Nullable previewMedia;

@end
