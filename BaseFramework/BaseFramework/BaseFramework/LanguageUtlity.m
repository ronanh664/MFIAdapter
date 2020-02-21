//
//  LanguageUtlity.m
//  BaseFramework
//
//  Created by tbago on 16/12/24.
//  Copyright © 2016年 tbago. All rights reserved.
//

#import "LanguageUtlity.h"

#pragma mark - check current environment language

BOOL isChinaLanguage() {
    NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
    if ([language isEqualToString:@"zh-Hans"]) {
        return YES;
    }
    return NO;
}

BOOL isFranchLanguage() {
    NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
    if ([language isEqualToString:@"fr"]) {
        return YES;
    }
    return NO;
}

BOOL isItalyLanguage() {
    NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
    if ([language isEqualToString:@"it"]) {
        return YES;
    }
    return NO;
}

BOOL isSpanishLanguage() {
    NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
    if ([language isEqualToString:@"es"]) {
        return YES;
    }
    return NO;
}

BOOL isGermanLanguage() {
    NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
    if ([language isEqualToString:@"de"]) {
        return YES;
    }
    return NO;
}

BOOL isDutchLanguage() {
    NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
    if ([language isEqualToString:@"nl"]) {
        return YES;
    }
    return NO;
}
