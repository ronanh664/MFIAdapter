//
//  DeviceUtility.m
//  BaseFramework
//
//  Created by tbago on 16/12/24.
//  Copyright © 2016年 tbago. All rights reserved.
//

#import "DeviceUtility.h"
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>
#import <sys/utsname.h>
#include <arpa/inet.h>
#include <ifaddrs.h>
#import <SystemConfiguration/CaptiveNetwork.h>      ///< wifi SSID

NSString *getDeviceTypeName() {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* code = [NSString stringWithCString:systemInfo.machine
                                        encoding:NSUTF8StringEncoding];

    static NSDictionary* deviceNamesByCode = nil;
    if (deviceNamesByCode == nil) {
        deviceNamesByCode = @{@"i386"      : @"Simulator",
                              @"x86_64"    : @"Simulator",
                              ///< iPod
                              @"iPod1,1"   : @"iPod Touch",        // (Original)
                              @"iPod2,1"   : @"iPod Touch 2",      // (Second Generation)
                              @"iPod3,1"   : @"iPod Touch 3",      // (Third Generation)
                              @"iPod4,1"   : @"iPod Touch 4",      // (Fourth Generation)
                              @"iPod7,1"   : @"iPod Touch 5",      // (6th Generation)
                              ///< iPhone
                              @"iPhone1,1" : @"iPhone",            // (Original)
                              @"iPhone1,2" : @"iPhone",            // (3G)
                              @"iPhone2,1" : @"iPhone",            // (3GS)
                              @"iPhone3,1" : @"iPhone 4",          // (GSM)
                              @"iPhone3,3" : @"iPhone 4",          // (CDMA/Verizon/Sprint)
                              @"iPhone4,1" : @"iPhone 4S",         //
                              @"iPhone5,1" : @"iPhone 5",          // (model A1428, AT&T/Canada)
                              @"iPhone5,2" : @"iPhone 5",          // (model A1429, everything else)
                              @"iPhone5,3" : @"iPhone 5c",         // (model A1456, A1532 | GSM)
                              @"iPhone5,4" : @"iPhone 5c",         // (model A1507, A1516, A1526 (China), A1529 | Global)
                              @"iPhone6,1" : @"iPhone 5s",         // (model A1433, A1533 | GSM)
                              @"iPhone6,2" : @"iPhone 5s",         // (model A1457, A1518, A1528 (China), A1530 | Global)
                              @"iPhone7,1" : @"iPhone 6 Plus",     //
                              @"iPhone7,2" : @"iPhone 6",          //
                              @"iPhone8,1" : @"iPhone 6S",         //
                              @"iPhone8,2" : @"iPhone 6S Plus",    //
                              @"iPhone8,4" : @"iPhone SE",         //
                              @"iPhone9,1" : @"iPhone 7",          //
                              @"iPhone9,3" : @"iPhone 7",          //
                              @"iPhone9,2" : @"iPhone 7 Plus",     //
                              @"iPhone9,4" : @"iPhone 7 Plus",     //
                              @"iPhone10,1": @"iPhone 8",          // (model A1863, A1906, A1907)
                              @"iPhone10,4": @"iPhone 8",          // (model A1905)
                              @"iPhone10,2": @"iPhone 8 Plus",     // (model A1864, A1898, A1899)
                              @"iPhone10,5": @"iPhone 8 Plus",     // (model A1897)
                              @"iPhone10,3": @"iPHone X",          // (model A1865, A1902)
                              @"iPhone10,6": @"iPhone X",          // (model A1901)
                              ///< iPad
                              @"iPad1,1"   : @"iPad",              // (model A1219, A1337)
                              @"iPad2,1"   : @"iPad 2",            // (model A1395)
                              @"iPad2,2"   : @"iPad 2",            // (model A1396)
                              @"iPad2,3"   : @"iPad 2",            // (model A1397)
                              @"iPad2,4"   : @"iPad 2",            // (model A1395)
                              @"iPad3,1"   : @"iPad 3",            // (model A1416)
                              @"iPad3,2"   : @"iPad 3",            // (model A1403)
                              @"iPad3,3"   : @"iPad 3",            // (model A1430)
                              @"iPad3,4"   : @"iPad 4",            // (model A1458)
                              @"iPad3,5"   : @"iPad 4",            // (model A1459)
                              @"iPad3,6"   : @"iPad 4",            // (model A1460)
                              @"iPad4,1"   : @"iPad Air",          // (model A1474)
                              @"iPad4,2"   : @"iPad Air",          // (model A1475)
                              @"iPad4,3"   : @"iPad Air",          // (model A1476)
                              @"iPad5,3"   : @"iPad Air 2",        // (model A1566)
                              @"iPad5,4"   : @"iPad Air 2",        // (model A1567)
                              @"iPad6,7"   : @"iPad Pro (12.9\")", // (model A1584)
                              @"iPad6,8"   : @"iPad Pro (12.9\")", // (model A1652)
                              @"iPad6,3"   : @"iPad Pro (9.7\")",  // (model A1673)
                              @"iPad6,4"   : @"iPad Pro (9.7\")",  // (model A1674, A1675)
                              @"iPad6,11"  : @"iPad 5",            // (model A1822)
                              @"iPad6,12"  : @"iPad 5",            // (model A1823)
                              @"iPad7,1"   : @"iPad Pro 2 (12.9\")",// (model A1670)
                              @"iPad7,2"   : @"iPad Pro 2 (12.9\")",// (model A1671, A1821)
                              @"iPad7,3"   : @"iPad Pro (10.5\")",  // (model A1701)
                              @"iPad7,4"   : @"iPad Pro (10.5\")", // (model A1709)
                              ///< iPad Mini
                              @"iPad2,5"   : @"iPad Mini",         // (model A1432)
                              @"iPad2,6"   : @"iPad Mini",         // (model A1454)
                              @"iPad2,7"   : @"iPad Mini",         // (model A1455)
                              @"iPad4,4"   : @"iPad Mini 2",       // (model A1489)
                              @"iPad4,5"   : @"iPad Mini 2",       // (model A1490)
                              @"iPad4,6"   : @"iPad Mini 2",       // (model A1491)
                              @"iPad4,7"   : @"iPad Mini 3",       // (model A1599)
                              @"iPad4,8"   : @"iPad Mini 3",       // (model A1600)
                              @"iPad4,9"   : @"iPad Mini 3",       // (model A1601)
                              @"iPad5,1"   : @"iPad Mini 4",       // (model A1538)
                              @"iPad5,2"   : @"iPad Mini 4",       // (model A1550)
                              };
    }
    
    NSString* deviceName = [deviceNamesByCode objectForKey:code];
    
    if (!deviceName) {
        deviceName = code;
    }
    
    return deviceName;

}

NSString *getDeviceTypeCode() {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

NSString *getDeviceSystemVersion() {
    return [[UIDevice currentDevice] systemVersion];
}

BOOL isIPadDevice() {
    UIDevice *device = [UIDevice currentDevice];
    if ([device respondsToSelector:@selector(userInterfaceIdiom)]
        && device.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return YES;
    }
    return NO;
}

BOOL isIPadPro12Point9InchDevice() {
    NSString *deviceTypeName = getDeviceTypeName();
    if ([deviceTypeName isEqualToString:@"iPad Pro (12.9\")"]) {
        return YES;
    }
    return NO;
}

#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_RETINA ([[UIScreen mainScreen] scale] >= 2.0)

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

BOOL is3Point5InchIPhoneDevice() {
    return (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0);
}

BOOL is4InchIPhoneDevice() {
    return (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0);
}

BOOL is4Point7InchIPhoneDevice() {
    return (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0);
}

BOOL is5Point5InchIPhoneDevice() {
    return (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0);
}

NSString *getDeviceIPAddress() {
    NSString *address = @"";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
                }
                
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

NSString * getCurrentWifiSSID() {
    NSString *ssid = nil;
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info[@"SSID"]) {
            ssid = info[@"SSID"];
        }
    }
    return ssid;
}
