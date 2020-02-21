//
//  YuneecMediaHttp_Extension.h
//  YuneecSDK
//
//  Created by Mine on 2017/4/28.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecMediaHttp.h"

@interface YuneecMediaHttp ()

/**
 Media's original resource server path
 */
@property (nonatomic, copy, readwrite) NSString *serverPath;

/**
 Media's thumbnail resource server path
 */
@property (nonatomic, copy, readwrite) NSString *serverThumbnailPath;

/**
 Media's video preview resource server path
 Note: Only supports for video media on Breeze camera
 */
@property (nonatomic, copy, readwrite) NSString *serverPreviewPath;

@end
