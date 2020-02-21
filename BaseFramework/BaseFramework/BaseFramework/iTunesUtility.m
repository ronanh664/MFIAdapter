//
//  iTunesUtility.m
//  BaseFramework
//
//  Created by tbago on 16/12/24.
//  Copyright © 2016年 tbago. All rights reserved.
//

#import "iTunesUtility.h"
#import <UIKit/UIApplication.h>

void openAppStoreByiTunesId(NSString * iTunesId) {
    NSString *iTunesLink = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=%@", iTunesId];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
}

void getiTunesAppVersionByiTunesId(NSString *iTunesId,
                                   void(^block)(NSError *error, NSString *versionString))
{
    NSString *openURLString = [NSString stringWithFormat:@"https://itunes.apple.com/lookup?id=%@", iTunesId];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:openURLString]
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:5];
    
    [request setHTTPMethod:@"GET"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                  {
                                    if (error == nil)
                                    {
                                        NSError *jsonConvertError = nil;
                                        NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                                                       options:0
                                                                                                         error:&jsonConvertError];
                                        if (jsonConvertError == nil)
                                        {
                                            NSNumber *resultCount = [jsonDictionary objectForKey:@"resultCount"];
                                            NSString *iTunesAppVersion = nil;
                                            if ([resultCount intValue] == 1)      ///< found the product
                                            {
                                                if ([jsonDictionary objectForKey:@"results"])
                                                {
                                                    NSArray *resultArray = [jsonDictionary objectForKey:@"results"];
                                                    if ([resultArray count] > 0)
                                                    {
                                                        NSDictionary *resultDictionary = resultArray[0];
                                                        if ([resultDictionary count] > 0)
                                                        {
                                                            if ([resultDictionary objectForKey:@"version"]) {
                                                                NSString *tempVersion  = [resultDictionary objectForKey:@"version"];
                                                                if (tempVersion != nil) {
                                                                    iTunesAppVersion = tempVersion;
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            if (iTunesAppVersion.length == 0) {
                                                block(nil, nil);
                                            }
                                            else {
                                                block(nil, iTunesAppVersion);
                                            }
                                        }
                                        else {
                                            block(error, nil);
                                        }
                                    }
                                    else {
                                        block(error, nil);
                                    }
                                }];
    
    [task resume];
}