//
//  YuneecCameraFileTransfer.m
//  YuneecCameraSDK
//
//  Created by tbago on 16/03/2018.
//  Copyright © 2018 yuneec. All rights reserved.
//

#import "YuneecCameraFileTransfer.h"

#import <YuneecDataTransferManager/YuneecDataTransferManager.h>
#import <BaseFramework/DebugLog.h>

#import "YuneecCameraUtility.h"
#import "NSError+YuneecCameraSDK.h"

typedef void (^ProgressBlock)(float process);
typedef void (^CompletionBlock)(NSError *_Nullable error);


typedef NS_ENUM(NSInteger, MessageType) {
    TYPE_FILENAME = 0,
    TYPE_FILEDATA,
    TYPE_QUIT,  ///< cancel when uploading
    TYPE_ACHIEVED,
    TYPE_RENAME_FILE,
    TYPE_ACK_FILENAME,
    TYPE_ACK_ACHIEVED,
    TYPE_ACK_RENAME_FILE,
    TYPE_WARN_FILE_NAME_TOO_LONG,
    TYPE_WARN_TOO_MANY_CONNECTIONS,
    TYPE_WARN_SYSCALL_ERR,
    TYPE_WARN_CRC_ERR,
    TYPE_NUM_MAX,
};

#pragma pack(push)
#pragma pack(1)

typedef struct {
    uint16_t  id;           ///< client id, not used in current ver
    uint16_t  type;         ///< message type
    uint32_t  sequence_no;  ///< message sequence number
    uint32_t  checksum;     ///< CRC32 checksum, not used in current ver
    uint32_t  payload_size; ///< buffer size
} MessagePackageHeader;

#pragma pack(pop)


static const uint64_t kDefaultTimeoutValue = (10 * NSEC_PER_SEC);
static const uint64_t kDefaultTimeoutForFileTransferPerMega = (2.5 * NSEC_PER_SEC); // min 0.4MB/s

@interface YuneecCameraFileTransfer() <YuneecUpgradeDataTransferDelegate>

@property (nonatomic, copy) NSString                    *filePath;
@property (nonatomic, copy) ProgressBlock               progressBlock;
@property (nonatomic, copy) CompletionBlock             completionBlock;

@property (nonatomic, weak) YuneecUpgradeDataTransfer   *dataTransfer;

@property (nonatomic, assign) NSInteger                 messageSeq;
@property (nonatomic, copy) NSData                      *bufferData;        ///< cache data for resend
@property (nonatomic, strong) NSFileHandle              *readFileHandle;
@property (nonatomic) NSInteger                         transferPackageSize;
@property (nonatomic) NSInteger                         fileByteSize;
@property (nonatomic) NSInteger                         alreadySendByte;

@property (nonatomic) BOOL                              beginTransferFileData;

@property (nonatomic) BOOL                              transferFileNameSuccess;
@property (nonatomic) BOOL                              transferFileArchiveSucess;
@property (nonatomic) BOOL                              transferFileRenameSuccess;
@end

@implementation YuneecCameraFileTransfer

#pragma mark - init & dealloc

- (instancetype)init {
    self = [super init];
    if (self) {
        _transferPackageSize = 6000;
    }
    return self;
}

- (void)dealloc {
    self.progressBlock = nil;
    self.completionBlock = nil;
}

#pragma mark - public method

- (void)transferFileToCamera:(NSString *) filePath
               progressBlock:(void (^)(float progress)) progressBlock
             completionBlock:(void (^)(NSError *_Nullable error)) completionBlock
{
    self.filePath = filePath;

    self.progressBlock = progressBlock;
    self.completionBlock = completionBlock;

    self.dataTransfer = [YuneecDataTransferManager sharedInstance].upgradeDataTransfer;
    self.dataTransfer.delegate = self;

    [self.dataTransfer disconnectToServer];
    BOOL ret = [self.dataTransfer connectToServer];
    if (!ret) {
        completionBlock([NSError buildCameraErrorForCode:YuneecCameraFileTransferConnectionFailed]);
        return;
    }

    self.messageSeq = 0;
    self.beginTransferFileData = NO;
    [self transferFileName];
}

#pragma mark - private method

- (void)transferFileName {
    self.transferFileNameSuccess = NO;
    NSString *tempFileName = @"yuneec.temp";
    NSData *fileNameData = [tempFileName dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *fileNameWithNullData = [[NSMutableData alloc] initWithData:fileNameData];
    char nullData[1] = {0};
    [fileNameWithNullData appendBytes:nullData length:1];
    self.bufferData = [self buildMesssagePackageWithMessageType:TYPE_FILENAME
                                                   playLoadData:fileNameWithNullData];

    DNSLog(@"Upgrade : send file name = %@", tempFileName);
    [self.dataTransfer sendData:self.bufferData];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kDefaultTimeoutValue), dispatch_get_main_queue(), ^{
        if (!self.transferFileNameSuccess) {
            [self callCompleateBlockWithError:[NSError buildCameraErrorForCode:YuneecCameraFileTransferTimeout]];
        }
    });
}

- (void)prepareTransferFileData {
    self.transferFileNameSuccess = YES;
    self.readFileHandle = [NSFileHandle fileHandleForReadingAtPath:self.filePath];

    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:NULL];
    self.fileByteSize    = [fileAttributes fileSize];
    if(self.fileByteSize == 0) {
        // should not move forward if file size is 0.
        return;
    }
    self.alreadySendByte = 0;

    self.beginTransferFileData = YES;
    [self transferFileData];

    // convert bytes to MB
    int64_t timeout = (self.fileByteSize >> 20) * kDefaultTimeoutForFileTransferPerMega;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeout), dispatch_get_main_queue(), ^{
        [self callCompleateBlockWithError:[NSError buildCameraErrorForCode:YuneecCameraFileTransferTimeout]];
    });
}

- (void)transferFileData {
    NSData *fileData = [self.readFileHandle readDataOfLength:self.transferPackageSize];
    if (fileData.length == 0) {
        [self transferArchivedData];
        self.beginTransferFileData = NO;
    }
    self.bufferData = [self buildMesssagePackageWithMessageType:TYPE_FILEDATA
                                                   playLoadData:fileData];
    [self.dataTransfer sendData:self.bufferData];

    self.alreadySendByte += self.bufferData.length;
    if(self.progressBlock != nil) {
        self.progressBlock(self.alreadySendByte*1.0/self.fileByteSize);
    }
}

- (void)transferArchivedData {
    DNSLog(@"Upgrade : Call transfer archived data");
    self.transferFileArchiveSucess = NO;
    self.bufferData = [self buildMesssagePackageWithMessageType:TYPE_ACHIEVED
                                                   playLoadData:nil];
    [self.dataTransfer sendData:self.bufferData];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kDefaultTimeoutValue * 3), dispatch_get_main_queue(), ^{
        if (!self.transferFileArchiveSucess) {
            [self callCompleateBlockWithError:[NSError buildCameraErrorForCode:YuneecCameraFileTransferTimeout]];
        }
    });
}

- (void)transferReNameFileData {
    DNSLog(@"Upgrade : Rename file");
    self.transferFileArchiveSucess = YES;
    self.transferFileRenameSuccess = NO;
    NSString *fileName = [self.filePath lastPathComponent];
    NSData *fileNameData = [fileName dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *fileNameWithNullData = [[NSMutableData alloc] initWithData:fileNameData];
    char nullData[1] = {0};
    [fileNameWithNullData appendBytes:nullData length:1];
    self.bufferData = [self buildMesssagePackageWithMessageType:TYPE_RENAME_FILE playLoadData:fileNameWithNullData];
    [self.dataTransfer sendData:self.bufferData];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kDefaultTimeoutValue * 3), dispatch_get_main_queue(), ^{
        if (!self.transferFileRenameSuccess) {
            [self callCompleateBlockWithError:[NSError buildCameraErrorForCode:YuneecCameraFileTransferTimeout]];
        }
    });
}

- (NSData *)buildMesssagePackageWithMessageType:(MessageType) messageType
                                   playLoadData:(NSData *) payloadData
{
    MessagePackageHeader headerPackage;
    NSInteger headerPackageLength = sizeof(MessagePackageHeader);
    memset(&headerPackage, 0, headerPackageLength);
    headerPackage.id             = htons(0);  /* Reserved */
    headerPackage.type           = htons(messageType);
    headerPackage.sequence_no    = htonl((uint32_t)(self.messageSeq++));
    headerPackage.payload_size   = htonl((uint32_t)payloadData.length);
    headerPackage.checksum       =  htonl(CRC32FileTransferCalculation(0, (uint8_t *)&headerPackage, (uint32_t)headerPackageLength));   //crc32

    uint32_t byteBufferLength = (uint32_t)(headerPackageLength + payloadData.length);
    uint8_t * byteBuffer = (uint8_t *)malloc(byteBufferLength);
    memcpy(byteBuffer, &headerPackage, headerPackageLength);
    memcpy(byteBuffer+headerPackageLength, payloadData.bytes, payloadData.length);

    NSData *returnData = [[NSData alloc] initWithBytes:byteBuffer length:byteBufferLength];

    free(byteBuffer);

    return returnData;
}

- (void)parserReceiveData:(NSData *) data {
    DNSLog(@"Upgrade : Receive data:%@", data);
    NSInteger headerPackageLength = sizeof(MessagePackageHeader);

    if (data.length < headerPackageLength) {
        [self callCompleateBlockWithError:[NSError buildCameraErrorForCode:YuneecCameraFileTransferReceiveWrongData]];
        return;
    }

    MessagePackageHeader headerPackage;
    memcpy(&headerPackage, data.bytes, headerPackageLength);
    uint32_t checksum = ntohl(headerPackage.checksum);
    headerPackage.checksum = htonl(0);
    uint32_t calcCRC32 = CRC32FileTransferCalculation(0, (uint8_t *)&headerPackage, (uint32_t)headerPackageLength);
    if (calcCRC32 != checksum) {
        [self callCompleateBlockWithError:[NSError buildCameraErrorForCode:YuneecCameraErrorReturnDataInvalid]];
        return;
    }

    headerPackage.id            = htons(headerPackage.id);
    headerPackage.type          = htons(headerPackage.type);
    headerPackage.sequence_no   = htons(headerPackage.sequence_no);
    headerPackage.payload_size  = htons(headerPackage.payload_size);
    if (headerPackage.type == TYPE_ACK_FILENAME) {
        [self prepareTransferFileData];
    }
    else if (headerPackage.type == TYPE_ACK_ACHIEVED) {
        [self transferReNameFileData];
    }
    else if (headerPackage.type == TYPE_ACK_RENAME_FILE) {
        self.transferFileRenameSuccess = YES;
        [self callCompleateBlockWithError:nil];
    }
    else if (headerPackage.type == TYPE_WARN_FILE_NAME_TOO_LONG) {
        [self callCompleateBlockWithError:[NSError buildCameraErrorForCode:YuneecCameraFileTransferFileNameTooLong]];
    }
    else if (headerPackage.type == TYPE_WARN_TOO_MANY_CONNECTIONS) {
        [self callCompleateBlockWithError:[NSError buildCameraErrorForCode:YuneecCameraFileTransferTooManyConnection]];
    }
    else if (headerPackage.type == TYPE_WARN_SYSCALL_ERR) {
        [self callCompleateBlockWithError:[NSError buildCameraErrorForCode:YuneecCameraFileTransferSysCallError]];
    }
    else if (headerPackage.type == TYPE_WARN_CRC_ERR) {
        [self callCompleateBlockWithError:[NSError buildCameraErrorForCode:YuneecCameraFileTransferCRCError]];
    }
}

- (void)callCompleateBlockWithError:(NSError *_Nullable) error {
    if (self.completionBlock != nil) {
        self.completionBlock(error);
        self.completionBlock = nil;
        self.progressBlock = nil;
    }
}

#pragma mark - YuneecUpgradeDataTransferDelegate

- (void)upgradeDataTransferDidSendData {
    if (self.beginTransferFileData) {
        [self transferFileData];
    }
}

- (void)upgradeDataTransfer:(YuneecUpgradeDataTransfer *) dataTransfer
             didReceiveData:(NSData *) data {
    [self parserReceiveData:data];
}
@end
