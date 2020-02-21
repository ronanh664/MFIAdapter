//
//  DebugOutputInstance.m
//  BaseFramework
//
//  Created by tbago on 14/12/2017.
//  Copyright © 2017 tbago. All rights reserved.
//

#import "DebugOutput.h"
#import <BaseFramework/NSDateAndNSStringConversion.h>

@implementation DebugOutput

#pragma mark - init

+ (instancetype)sharedInstance {
    static DebugOutput *sInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[DebugOutput alloc] init];
    });
    return sInstance;
}

#pragma mark - public method

- (void)addOneDebugOutputString:(NSString *) debugOutputString
                debugOutputType:(DebugOutputType) debugOutputType
{
    if (debugOutputType == DebugOutputTypeConsole) {
#ifdef DEBUG
        NSLog(@"%@", debugOutputString);
#endif
        return;
    }
    if (self.delegate != nil) {
        NSString *printTime = convertNSDateToFormatNSString([NSDate date], @"HH:mm:ss SSS");
        NSString *fullString = [NSString stringWithFormat:@"%@ %@", printTime, debugOutputString];

        if ([self.delegate respondsToSelector:@selector(debugOutputInstance:didAddNewString:debugOutputType:)]) {
            [self.delegate debugOutputInstance:self didAddNewString:fullString debugOutputType:debugOutputType];
        }
    }
    else {
#ifdef DEBUG
        NSLog(@"%zd:%@", debugOutputType, debugOutputString);
#endif
    }
}
@end
