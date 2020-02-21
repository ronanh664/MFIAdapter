//
//  YuneecRational.m
//  YuneecSDK
//
//  Created by tbago on 17/1/24.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecRational.h"

@implementation YuneecRational

- (instancetype)init {
    return [self initWithNumerator:0 denominator:0];
}

- (instancetype)initWithNumerator:(NSInteger) numerator
                      denominator:(NSInteger) denominator
{
    self = [super init];
    if (self) {
        _numerator = numerator;
        _denominator = denominator;
    }
    return self;
}

- (BOOL)equalValue:(YuneecRational *) inputRational {
    if (inputRational.numerator == self.numerator
        && inputRational.denominator == self.denominator) {
        return YES;
    }
    
    ///< check double value *10
    double inputValue = inputRational.numerator * 1.0 / inputRational.denominator;
    double selfValue = self.numerator * 1.0/ self.denominator;
    if (fabs(inputValue-selfValue) < 0.000001) {
        return YES;
    }
    return NO;
}

- (NSComparisonResult)compare:(YuneecRational *)inputRational {
    
    if (inputRational.numerator == self.numerator
        && inputRational.denominator == self.denominator) {
        return NSOrderedSame;
    }
    
    double inputValue = inputRational.numerator * 1.0 / inputRational.denominator;
    double selfValue = self.numerator * 1.0/ self.denominator;
    double difference = inputValue - selfValue;
    
    if (difference > 0) {
        return NSOrderedAscending;
    }
    else if (difference < 0) {
        return NSOrderedDescending;
    }
    else {
        return NSOrderedSame;
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"numerator: %ld, denominator: %ld", (long)self.numerator, (long)self.denominator];
}

@end
