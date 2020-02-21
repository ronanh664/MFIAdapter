//
//  YuneecUdpDownloader.h
//  YuneecSDK
//
//  Created by Mine on 2017/3/9.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import <Foundation/Foundation.h>
@class YuneecMedia;

typedef NS_ENUM(NSInteger, YuneecUdpDownloaderError) {
    YNC_ERR_NONE    		   = -0x00,
    YNC_ERR_CRC     		   = -0x01,
    YNC_ERR_TOTAL_CRC          = -0x02,
    YNC_ERR_FILE_NOT_EXIST	   = -0x03,
    YNC_ERR_FILE_TOO_BIG       = -0x04,
    YNC_ERR_APP_CREATE_FILE	   = -0x05,
    YNC_ERR_CAM_OPEN_FILE	   = -0x06,
    YNC_ERR_PAUSE              = -0x07,
    YNC_ERR_RESTART     	   = -0x08,
    YNC_ERR_RESPONSE_FILELIST  = -0x09,
    YNC_ERR_QUIT   			   = -0x0A,
    YNC_ERR_BAD_PARAMETER      = -0x0B,
    YNC_ERR_TIMEOUT            = -0x0C,
    YNC_ERR_WRONG_SOCKFD       = -0x0D,
    YNC_ERR_CONFIG             = -0x0E,
    YNC_ERR_DELETE_FILE        = -0x0F,
    YNC_ERR_STOP_DOWNLOAD_FILE = -0x10,
};

@interface YuneecUdpDownloader : NSObject

/**
 Query file list from remote sd card
 
 @param block Return error when failed, return file lists when success.
 */
- (void)queryFileListWithBlock:(void(^ _Nonnull)(NSError *_Nullable error, NSArray *_Nullable fileArray))block;

/**
 Download file with progress
 
 @param fileName File name
 @param storagePath Path to storage the file
 @param progressBlock Return downloading progress, progress range is from 0.0 to 1.0
 @param completion Return error when failed, return nil when success.
 */
- (void)downdloadWithFileName:(NSString *_Nonnull)fileName storagePath:(NSString *_Nonnull)storagePath progressBlock:(void(^_Nullable)(float progress))progressBlock completion:(void(^_Nonnull)(NSError *_Nullable error))completion;

/**
 Stop file download
 
 @param block Return error when failed, return nil when success.
 */
- (void)stopDownloadWithBlock:(void(^ _Nonnull)(NSError *_Nullable error))block;

/**
 Pause file download
 
 @param block Return error when failed, return nil when success.
 */
- (void)pauseDownloadWithBlock:(void(^ _Nonnull)(NSError *_Nullable error))block;

/**
 Resume file download
 
 @param block Return error when failed, return nil when success.
 */
- (void)resumeDownloadWithBlock:(void(^ _Nonnull)(NSError *_Nullable error))block;

/**
 Delete files
 
 @param fileNameArray An array of file name
 @param block Return error when failed, return nil when success.
 */
- (void)deleteFiles:(NSArray<NSString *> *_Nonnull)fileNameArray block:(void(^ _Nonnull)(NSError *_Nullable error))block;

@end
