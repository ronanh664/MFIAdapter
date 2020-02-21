//
//  NSDateAndNSStringConversion.m
//  BaseFramework
//
//  Created by tbago on 16/12/24.
//  Copyright © 2016年 tbago. All rights reserved.
//

#import "NSDateAndNSStringConversion.h"

#pragma mark - NSDate to NSString

NSString* convertNSDateToFormatNSString(NSDate *date, NSString *format) {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:format];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en"]];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    return strDate;
}

NSString* convertNSDateToStandString(NSDate *date) {
    return convertNSDateToFormatNSString(date, @"yyyy-MM-dd HH:mm:ss");
}

NSString* convertNSDateToShortNSString(NSDate *date) {
    return convertNSDateToFormatNSString(date, @"HH:mm:ss");
}

#pragma mark - NSString to NSDate

NSDate *convertNSStringToNSDate(NSString *stringDate, NSString *format) {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:format];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en"]];

    NSDate *destDate = [dateFormatter dateFromString:stringDate];
    return destDate;
}