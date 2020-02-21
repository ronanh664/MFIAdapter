//
//  FileUtility.m
//  BaseFramework
//
//  Created by tbago on 16/12/23.
//  Copyright © 2016年 tbago. All rights reserved.
//

#import "FileUtility.h"

#import <CommonCrypto/CommonDigest.h>

#pragma mark - App dicectory operation

NSString * getDocumentDirectory() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return paths[0];
}

NSString * getTempDirectory() {
    return NSTemporaryDirectory();
}

NSString * getCacheDirectory() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return paths[0];
}

NSString * getApplicationSupportDirectory() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    return paths[0];
}

#pragma mark - File Operation

BOOL createDirectoryIfNotExists(NSString *directoryPath, NSError **error) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    if ([fileManager fileExistsAtPath:directoryPath isDirectory:&isDirectory]) {
        if (isDirectory) {
            return YES;     ///< directory is alreay exits
        }
    }
    
    BOOL result = [fileManager createDirectoryAtPath:directoryPath
                         withIntermediateDirectories:NO
                                          attributes:nil
                                               error:error];
    return result;
}

BOOL createFileIfNotExits(NSString *filePath, NSString *error) {
    if (!fileExistsAtPath(filePath)) {
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    }
    return YES;
}

BOOL fileExistsAtPath(NSString *filePath) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    if ([fileManager fileExistsAtPath:filePath isDirectory:&isDirectory]) {
        if (!isDirectory) {
            return YES;
        }
    }
    return NO;
}

BOOL enumFileInDirectory(NSString* directoryPath, NSArray *fileExtArray, NSMutableArray *resultArray) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:directoryPath];
    NSString *file;
    while ((file = [dirEnum nextObject]))
    {
        NSString *fileExt = [[file pathExtension] lowercaseString];
        if (fileExtArray.count == 0 || [fileExtArray containsObject:fileExt])
        {
            NSString *filePath = [directoryPath stringByAppendingPathComponent:file];
            [resultArray addObject:filePath];
        }
    }
    return YES;
}

BOOL deleteFileAtPath(NSString *filePath, NSError **error) {
    BOOL result = NO;
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:filePath]) {
        result = [[NSFileManager defaultManager] removeItemAtPath:filePath error:error];
        return result;
    }
    return result;
}

BOOL moveFileToPath(NSString *sourcePath, NSString *destPath, NSError **error)
{
    if (fileExistsAtPath(destPath)) {
        deleteFileAtPath(destPath, error);
        if (*error != nil) {
            return NO;
        }
    }
    BOOL result = NO;
    result = [[NSFileManager defaultManager] moveItemAtPath:sourcePath
                                                     toPath:destPath
                                                      error:error];

    return result;
}

NSString *calcFileMD5HashValueByFile(NSString *filePath) {
    static NSInteger FileHashDefaultChunkSizeForReadingData = 1024*1024;    ///< 1MB
    
    NSFileHandle          *readFileHandle;
    readFileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    
    // Initialize the hash object
    CC_MD5_CTX hashObject;
    CC_MD5_Init(&hashObject);
    
    while (true) {
        NSData *bufferData = [readFileHandle readDataOfLength:FileHashDefaultChunkSizeForReadingData];
        
        CC_MD5_Update(&hashObject, bufferData.bytes, (CC_LONG)bufferData.length);
        
        if (bufferData.length < FileHashDefaultChunkSizeForReadingData) {
            break;
        }
    }
    
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
    
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    
    [readFileHandle closeFile];
    return [[NSString alloc] initWithUTF8String:hash];
    
}
