//
//  YuneecMediaUtility.m
//  YuneecSDK
//
//  Created by Mine on 2017/2/4.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecMediaUtility.h"

@implementation YuneecMediaUtility

const NSTimeInterval httpTimeout = 8.0;

NSDate *convertStringToNSDate(NSString *stringDate, NSString *format) {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:format];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en"]];
    
    NSDate *destDate= [dateFormatter dateFromString:stringDate];
    return destDate;
}

@end
