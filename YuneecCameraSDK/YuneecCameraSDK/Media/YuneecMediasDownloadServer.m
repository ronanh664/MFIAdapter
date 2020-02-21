//
//  YNCFB_MediasDownloadServer.m
//  OBClient
//
//  Created by hank on 26/03/2018.
//  Copyright © 2018 yuneec. All rights reserved.
//

#import "YuneecMediasDownloadServer.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import <YuneecCameraSDK/YuneecCameraSDK.h>
#import <YuneecDataTransferManager/YuneecDataTransferManager.h>

@interface YuneecMediasDownloadServer() <GCDAsyncSocketDelegate, YuneecPhotoDownloadDataTransferDelegate>
{
    GCDAsyncSocket *tcpMediaServerSocket;
    GCDAsyncSocket *newMediaServerSocket;
}
@property (nonatomic, strong) YuneecDataTransferManager *dataTransferManager;
@property (nonatomic, strong) dispatch_queue_t downloadQueue;
@end

static const uint16_t Camera_Media_TCP_port = 12588;
static NSString *const Camera_Media_TCP_IPAddress = @"127.0.0.1";
static const NSUInteger Camera_Media_Transfer_PacketSize = 64 * 1024 - 1;

@implementation YuneecMediasDownloadServer

#pragma mark - init

+ (instancetype)sharedInstance {
    static YuneecMediasDownloadServer *sInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[YuneecMediasDownloadServer alloc] init];
    });
    return sInstance;
}


- (void)openTCPSocket
{
//    NSLog(@"+++++ start tcp socket");
    [self setupMediasDownloadPort];
    [self dataTransferManager];
    dispatch_queue_t dQueue = dispatch_queue_create("com.yuneec.cameraSettingUDPServerQueue", DISPATCH_QUEUE_CONCURRENT);
    NSError *error = nil;
    tcpMediaServerSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dQueue];
    [tcpMediaServerSocket acceptOnInterface:Camera_Media_TCP_IPAddress port:Camera_Media_TCP_port error:&error];
    [tcpMediaServerSocket setAutoDisconnectOnClosedReadStream:NO];
    if (error) {
        NSLog(@"%@", error);
    }
}

- (void)closeTCPSocket
{
//    NSLog(@"+++++++closeTCPSocket");
    [YuneecSDKManager sharedInstance].useCustomMediaCommunication = NO;
    if (tcpMediaServerSocket != nil) {
        [tcpMediaServerSocket setDelegate:nil];
        [tcpMediaServerSocket disconnect];
        tcpMediaServerSocket = nil;
    }
}

- (void)setupMediasDownloadPort
{
    [YuneecSDKManager sharedInstance].useCustomMediaCommunication = YES;
    [YuneecSDKManager sharedInstance].customMediaPort = Camera_Media_TCP_port;
    [YuneecSDKManager sharedInstance].customMediaIpAddress = Camera_Media_TCP_IPAddress;
    [YuneecSDKManager sharedInstance].customMediaTransferPacketSize = Camera_Media_Transfer_PacketSize;
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
   if (sock == newMediaServerSocket) {
//       NSLog(@"++++did write data");
        [newMediaServerSocket readDataWithTimeout:-1.0f tag:1];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (sock == newMediaServerSocket) {
//        NSLog(@"++++did read data");
        [self.dataTransferManager.photoDownloadDataTransfer sendData:data];
        [sock readDataWithTimeout:-1.0f tag:1];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    if (sock.localPort == Camera_Media_TCP_port) {
//        NSLog(@"+++++did accept new socket");
        newMediaServerSocket = newSocket;
        [newMediaServerSocket readDataWithTimeout:-1.0f tag:1];
    }
}

- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock {
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    
}

#pragma mark - YuneecPhotoDownloadDataTransferDelegate
- (void)photoDownloadDataTranfer:(YuneecPhotoDownloadDataTransfer *)dataTransfer
                  didReceiveData:(NSData *)data
{
//    NSLog(@"++++receive data");
    if (newMediaServerSocket != nil) {
        if(_downloadQueue == nil) {
            _downloadQueue = dispatch_queue_create("com.yuneec.photoDownload", DISPATCH_QUEUE_SERIAL);
        }
        dispatch_async(_downloadQueue, ^{
            [newMediaServerSocket writeData:data withTimeout:-1.0f tag:1];
        });
    }
}

- (YuneecDataTransferManager *)dataTransferManager
{
    if (!_dataTransferManager) {
//        NSLog(@"++++++delegate");
        _dataTransferManager = [[YuneecDataTransferManager alloc] init];
        _dataTransferManager.photoDownloadDataTransfer.delegate = self;
    }
    return _dataTransferManager;
}


@end
