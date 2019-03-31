//
//  ACLBSCenter.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-18.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "ACLocationAlert.h"

@interface ACLBSCenter : NSObject<CLLocationManagerDelegate>

+(void) initACLBSCenter; //初始化LBS

//+(ACLBSCenter *)shareLBSCenter;

+(void)locationAlertWithDic:(NSDictionary *)dic;
+(void)remoteAlertWithDic:(NSDictionary *)dic fetchCompletionHandler:(void(^)(UIBackgroundFetchResult)) completionHandler;

//-(void)startUpdatingLocation;

+(void)autoUpdatingLocation_Begin;
+(void)autoUpdatingLocation_End;

+(BOOL)userAllowLocation;

@end
