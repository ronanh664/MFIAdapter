//
//  MFiSessionController.m
//  MFITest
//
//  Created by kimiz on 2017/8/24.
//  Copyright © 2017年 Yuneec. All rights reserved.
//

#import "YuneecMFiSessionController.h"
#import "YuneecMFiDefine.h"

#ifdef DEBUG
#define DEBUG_NOTIFICATION_WITH_MESSAGE(x)  [[NSNotificationCenter defaultCenter] postNotificationName:kYuneecMFiSessionDebugNotification object:nil userInfo:@{@"msg":x}]
#endif

#define EAD_INPUT_BUFFER_SIZE 1024 * 4

@interface YuneecMFiSessionController ()<NSStreamDelegate>

@property (nonatomic, strong) EASession *session;
@property (nonatomic, strong) EAAccessory *accessory;
@property (nonatomic, strong) NSString *protocolString;
@property (nonatomic, strong) NSMutableArray<NSData *> *writeDataArray;
@property (nonatomic, strong) NSLock *writeDataLock;
@property (nonatomic, assign) BOOL isWriting;

@end

@implementation YuneecMFiSessionController

#pragma mark - Private Methods

// buffer data write
- (void)_writeData {
    if (self.isWriting) {
        return;
    }
    if (self.writeDataArray.count != 0) {
        self.isWriting = YES;
        [self.writeDataLock lock];
        NSData *data = [self.writeDataArray firstObject];
        [self.writeDataArray removeObjectAtIndex:0];
        [self.writeDataLock unlock];
        [self _writeData:data];
        self.isWriting = NO;
    }
}

// low level write method - write data to the accessory while there is space available and data to write
- (void)_writeData:(NSData *)data {
    NSMutableData *writeData = [NSMutableData dataWithData:data];
    while ([_session.outputStream hasSpaceAvailable] && writeData.length > 0) {
        NSInteger bytesWritten = [_session.outputStream write:writeData.bytes maxLength:writeData.length];
        if (bytesWritten == -1) {
            //DEBUG_NOTIFICATION_WITH_MESSAGE(@"write error");
            return;
        }else if (bytesWritten > 0) {
            [writeData replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
            //NSString *debugMessage = [NSString stringWithFormat:@"write length:%zd, protocol:%@",bytesWritten,self.protocolString];
            //DEBUG_NOTIFICATION_WITH_MESSAGE(debugMessage);
        }
    }
}

// low level read method - read data while there is data and space available in the input buffer
- (void)_readData {
    
    uint8_t buf[EAD_INPUT_BUFFER_SIZE];
    NSMutableData *data = [[NSMutableData alloc] init];
    while ([_session.inputStream hasBytesAvailable]) {
        NSInteger bytesRead = [_session.inputStream read:buf maxLength:EAD_INPUT_BUFFER_SIZE];
        [data appendBytes:buf length:bytesRead];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kYuneecMFiSessionDataReceivedNotification object:self userInfo:@{@"data":data}];
}


#pragma mark - Public Methods

// initialize the accessory with the protocolString
- (instancetype)initWithAccesory:(EAAccessory *)accesory
                  protocolString:(NSString *)protocolString {
    YuneecMFiSessionController *controller = [[YuneecMFiSessionController alloc] init];
    controller.accessory = accesory;
    controller.protocolString = [protocolString copy];
    return controller;
}

- (void)dealloc {
    [self closeSession];
    self.accessory = nil;
    self.protocolString = nil;
    self.isWriting = NO;
    self.writeDataArray = nil;
    self.writeDataLock = nil;
}

// open a session with the accessory and set up the input and output stream on the default run loop
- (BOOL)openSession {
    _session = [[EASession alloc] initWithAccessory:_accessory forProtocol:_protocolString];
    if (_session) {
        _session.inputStream.delegate = self;
        [_session.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_session.inputStream open];
        
        _session.outputStream.delegate = self;
        [_session.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_session.outputStream open];
    }else {
        //NSLog(@"creating EASession failed.");
        //DEBUG_NOTIFICATION_WITH_MESSAGE(@"creating EASession failed.");
    }
    return (_session != nil);
}

// close the session with the accessory.
- (void)closeSession {
    [_session.inputStream close];
    [_session.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    _session.inputStream.delegate = nil;
    
    [_session.outputStream close];
    [_session.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    _session.outputStream.delegate = nil;
    
    _session = nil;
    [self.writeDataArray removeAllObjects];
}

// high level write data method
- (void)writeData:(NSData *)data {
    
    if (![_session.outputStream hasSpaceAvailable]) {
        [self.writeDataLock lock];
        [self.writeDataArray addObject:data];
        [self.writeDataLock unlock];
        return;
    }
    [self _writeData:data];
}


#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventNone:
            break;
        case NSStreamEventOpenCompleted:
            break;
        case NSStreamEventHasBytesAvailable:
            [self _readData];
            break;
        case NSStreamEventHasSpaceAvailable:
            [self _writeData];
            break;
        case NSStreamEventErrorOccurred:
            break;
        case NSStreamEventEndEncountered:
            break;
        default:
            break;
    }
}


#pragma mark - set & get

- (NSMutableArray<NSData *> *)writeDataArray {
    if (!_writeDataArray) {
        _writeDataArray = [[NSMutableArray alloc] init];
    }
    return _writeDataArray;
}

- (NSLock *)writeDataLock {
    if (!_writeDataLock) {
        _writeDataLock = [[NSLock alloc] init];
    }
    return _writeDataLock;
}


@end
