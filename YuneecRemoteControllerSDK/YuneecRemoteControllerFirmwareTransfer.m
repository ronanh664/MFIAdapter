//
//  YuneecRemoteControllerUpgrade.m
//  YuneecRemoteControllerSDK
//
//  Created by tbago on 20/03/2018.
//  Copyright © 2018 yuneec. All rights reserved.
//

#import "YuneecRemoteControllerFirmwareTransfer.h"

#import <BaseFramework/FileUtility.h>
#import <BaseFramework/DebugLog.h>
#import <YuneecRemoteControllerSDK/YuneecRemoteController.h>
#import "NSError+YuneecRemoteControllerSDK.h"

static const NSInteger kFirmwarePackageDataLength = 2000;

@interface YuneecRemoteControllerFirmwareTransfer()

@property (nonatomic, weak) YuneecRemoteController      *remoteController;
@property (nonatomic, copy) NSString                    *firmwarePath;
@property (nonatomic, strong) NSFileHandle              *fileHandle;
@property (nonatomic, copy) NSString                    *fileName;
@property (nonatomic, assign) NSInteger                 fileSize;
@property (nonatomic, assign) NSInteger                 alreadySendDataSize;

@property (nonatomic, assign) NSInteger                 maxRetryCount;
@property (nonatomic, assign) NSInteger                 currentRetryCount;
@property (nonatomic, strong) NSData                    *bufferData;

@property (nonatomic, copy) void(^progressBlock)(float progress);
@property (nonatomic, copy) void(^completeBlock)(NSError *_Nullable error);

@end

@implementation YuneecRemoteControllerFirmwareTransfer

#pragma mark - init

- (instancetype)initWithRemoteController:(YuneecRemoteController *) remoteController {
    self = [super init];
    if (self) {
        _remoteController = remoteController;
    }
    return self;
}


#pragma mark - public method

- (void)transferFirmwareToRemoteController:(NSString *) firmwarePath
                             progressBlock:(void(^)(float progress)) progressBlock
                           completionBlock:(void(^)(NSError *_Nullable error)) completionBlock {
    self.firmwarePath = firmwarePath;
    self.progressBlock = progressBlock;
    self.completeBlock = completionBlock;

    [self startUpgrade];
}

- (void)cancelUpgrade {
    self.completeBlock = nil;
    self.progressBlock = nil;
    [self.remoteController cancelFirmwareUpgrade:^(NSError * _Nullable error) {}];
}

#pragma mark - private method

- (void)startUpgrade {
    NSError *firmwareInfoError = [self getLocalFirmwareInfo];
    if (firmwareInfoError != nil) {
        self.completeBlock(firmwareInfoError);
    }

    [self.remoteController getVersionInfo:^(NSError * _Nullable error, NSString * _Nullable hardwareVersion, NSString * _Nullable firmwareVersion, NSString * _Nullable mcuVersion) {
        if (error != nil) {
            self.completeBlock(error);
            return;
        }

        [self.remoteController getType:^(NSError * _Nullable error, NSString * _Nullable type) {
            if (error != nil) {
                self.completeBlock(error);
                return;
            }

            [self.remoteController startFirmwareUpgrade:hardwareVersion
                                        firmwareVersion:firmwareVersion
                                             mcuVersion:mcuVersion
                                           firmwareName:self.fileName
                                           firmwareSize:self.fileSize
                                                   type:type block:^(NSError * _Nullable error) {
                                                       if (error != nil) {
                                                           self.completeBlock(error);
                                                       }
                                                       [self prepareLoopSendFirmwareData];
            }];
        }];
    }];
}

- (void)prepareLoopSendFirmwareData {
    self.fileHandle = [NSFileHandle fileHandleForReadingAtPath:self.firmwarePath];

    self.bufferData         = nil;
    self.maxRetryCount      = 3;
    self.currentRetryCount  = 0;
    self.alreadySendDataSize= 0;

    [self loopSendFirmwareData];
}

- (void)loopSendFirmwareData {
    NSData *fileData = nil;
    if (self.bufferData != nil) {
        fileData = self.bufferData;
        self.currentRetryCount++;
    }
    else {
        self.currentRetryCount = 0;
        fileData = [self.fileHandle readDataOfLength:kFirmwarePackageDataLength];
    }

    if (self.currentRetryCount >= self.maxRetryCount) {
        self.completeBlock([NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerFirmwareRetryMaxCount]);
        [self cancelUpgrade];
        return;
    }

    if (fileData == nil || fileData.length == 0) {
        NSString *fileMD5 = calcFileMD5HashValueByFile(self.firmwarePath);
        [self.remoteController sendFirmwareMD5Value:fileMD5 block:^(NSError * _Nullable error) {
            if (error != nil) {
                self.completeBlock(error);
            }
            else {
                self.completeBlock(nil);
            }
        }];
    }
    else {
        [self.remoteController transferFirmwareData:fileData
                                          retryData:self.currentRetryCount>0
                                              block:^(NSError * _Nullable error) {
            if (error != nil) {
                self.bufferData = fileData;
                DNSLog(@"Transfer firmware data failed:%@", error.localizedDescription);
            }
            else {
                self.bufferData = nil;
                self.alreadySendDataSize += fileData.length;
                self.progressBlock(1.0 * self.alreadySendDataSize/self.fileSize);
            }
            [self performSelectorOnMainThread:@selector(loopSendFirmwareData)
                                   withObject:nil
                                waitUntilDone:NO
                                        modes:@[NSRunLoopCommonModes]];
        }];
    }
}

- (NSError * _Nullable)getLocalFirmwareInfo {
    if (!fileExistsAtPath(self.firmwarePath)) {
        return [NSError buildRemoteControllerErrorWithCode:YuneecRemoteControllerFirmwareNotExit];
    }
    self.fileName = [[self.firmwarePath lastPathComponent] componentsSeparatedByString:@"_"].lastObject;
//    NSLog(@"Transfer remote controller file name:%@", self.fileName);

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *fileAttributeError = nil;
    NSDictionary *fileAttributeDictionary = [fileManager attributesOfItemAtPath:self.firmwarePath error:&fileAttributeError];
    if (fileAttributeError != nil) {
        return fileAttributeError;
    }
    else {
        self.fileSize = [fileAttributeDictionary fileSize];
    }
    return nil;
}

@end
