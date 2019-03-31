//
//  ACMapShareLocalVC.h
//  chat
//
//  Created by Aculearn on 16/5/6.
//  Copyright © 2016年 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "ACMapShareLocalDef.h"
#import "ACChatMessageViewController.h"


extern  NSString*  const shareLocalNotifyForUserInfoChangeEvent;

@interface ACMapShareLocalVC : UIViewController<MKMapViewDelegate,UIActionSheetDelegate>


+(void) showForSuperVC:(nonnull ACChatMessageViewController*)superVC;
+(void) checkChangeUsers:(NSArray<NSDictionary*>*) usrsDict withVC:(nonnull ACChatMessageViewController*)pVC;
+(void) updataLocation:(CLLocationCoordinate2D)loc withVC:(nonnull ACChatMessageViewController*)pVC;
+(BOOL) canUpdataLocation:(CLLocationCoordinate2D)loc withOldLoc:(CLLocationCoordinate2D)locOld; //是否可以发送
+(void) exitShareLocalwithVC:(nonnull ACChatMessageViewController*)pVC;

@end
