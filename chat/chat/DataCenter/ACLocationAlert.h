//
//  ACLocationAlert.h
//  chat
//
//  Created by 王方帅 on 14-5-29.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

enum locationType
{
    locationType_locationNow = 2,/**不计算距离，直接报告位置信息*/
    locationType_locationInDistanceOfLocation = 1,/**需要计算距离，符合条件的才报告位置信息*/
};

#define kObj                @"obj"

@interface ACLocationAlert : NSObject

- (instancetype)initWithEventDic:(NSDictionary *)eventDic;

@property (nonatomic) NSInteger             distanceMeters;
@property (nonatomic,strong) NSString       *eventUid;
@property (nonatomic) double                la;
@property (nonatomic) double                lo;
@property (nonatomic) enum locationType     locationType;
@property (nonatomic,strong) NSString       *teid;
@property (nonatomic,strong) NSString       *obj;
@property (nonatomic)        time_t         time_begin; //time(NULL)


-(NSDictionary*) getPostDictFromCoordinate:(CLLocationCoordinate2D)coordinate;
//取得需要发送的Post信息

@end
