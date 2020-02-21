//
//  DiscUtility.m
//  BaseFramework
//
//  Created by tbago on 16/12/24.
//  Copyright © 2016年 tbago. All rights reserved.
//

#import "DiscUtility.h"

NSInteger getDiskFreeSize() {
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSInteger discSpace = 0;
    NSDictionary *systemAttributes = [defaultManager attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error == nil) {
        discSpace = [[systemAttributes objectForKey:NSFileSystemFreeSize] integerValue];
    }
    return discSpace;
}

NSString *getReadableDiscFreeSpace() {
    NSInteger discFreeSize = getDiskFreeSize();
    if (discFreeSize < 1024) {          ///< Bytes
        return [NSString stringWithFormat:@"%zdB", discFreeSize];
    }
    else if (discFreeSize < (1024 * 1024)) {    ///< KB
        double discSpaceFloatValue = discFreeSize / 1024.0;
        return [NSString stringWithFormat:@"%.1fKB", discSpaceFloatValue];
    }
    else if (discFreeSize < (1024 * 1024 * 1024)) { ///< MB
        double discSpaceFloatValue = discFreeSize / 1024.0 / 1024.0;
        return [NSString stringWithFormat:@"%.1fMB", discSpaceFloatValue];
    }
    else {          ///< GB
        double discSpaceFloatValue = discFreeSize / 1024.0 / 1024.0 / 1024.0;
        return [NSString stringWithFormat:@"%.2fGB", discSpaceFloatValue];
    }
}