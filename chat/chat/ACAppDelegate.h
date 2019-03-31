//
//  ACAppDelegate.h
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-27.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif

@class Reachability;
@class CTTelephonyNetworkInfo;
@interface ACAppDelegate : UIResponder <UIApplicationDelegate,CLLocationManagerDelegate

#ifdef NSFoundationVersionNumber_iOS_9_x_Max
,UNUserNotificationCenterDelegate
#endif
>
{
    CTTelephonyNetworkInfo      *_networkInfo;
    UIBackgroundTaskIdentifier  _bgTask;
    CLLocationManager           *_locationManager;
}

@property (strong, nonatomic) UIWindow      *window;

+(void)registerForRemoteNotification;
+(void)activeNotification:(NSDictionary*)pCallUserInfo;
+(BOOL)canShowNotification;
@end
