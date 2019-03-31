//
//  ACLocationAlert.m
//  chat
//
//  Created by 王方帅 on 14-5-29.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACLocationAlert.h"
#import "ACMessage.h"

#define kDistanceMeters     @"distanceMeters"
#define kEventUid           @"eventUid"
#define kLa                 @"la"
#define kLo                 @"lo"
#define kLocationType       @"locationType"


@implementation ACLocationAlert

- (instancetype)initWithEventDic:(NSDictionary *)eventDic
{
    self = [super init];
    if (self) {
        _locationType = [[eventDic objectForKey:kLocationType] intValue];
        if(locationType_locationNow!=_locationType&&
           locationType_locationInDistanceOfLocation!=_locationType){
            return nil;
        }
        
        self.distanceMeters = [[eventDic objectForKey:kDistanceMeters] doubleValue];
        self.eventUid = [eventDic objectForKey:kEventUid];
        self.la = [[eventDic objectForKey:kLa] doubleValue];
        self.lo = [[eventDic objectForKey:kLo] doubleValue];
        self.teid = [eventDic objectForKey:kTeid];
        self.time_begin = time(NULL);
        
        NSString *obj = [eventDic objectForKey:kObj];
        if (obj)
        {
            self.obj = obj;
        }
    }
    return self;
}

-(NSDictionary*) getPostDictFromCoordinate:(CLLocationCoordinate2D)coordinate{
    if(locationType_locationInDistanceOfLocation==_locationType){
        
        CLLocation *location1 = [[CLLocation alloc] initWithLatitude:coordinate.latitude
                                                           longitude:coordinate.longitude];
        CLLocation *location2 = [[CLLocation alloc] initWithLatitude:_la
                                                           longitude:_lo];
        CLLocationDistance meters=[location1 distanceFromLocation:location2];
        if (meters >= _distanceMeters){
            //这个状态不再执行定位功能了
            return nil;
        }
    }
    else if(locationType_locationNow!=_locationType){
        return nil;
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithDouble:coordinate.latitude],kLa,
                                    [NSNumber numberWithDouble:coordinate.longitude],kLo,
                                    @"network",kType,
                                    _eventUid, @"uid",
                                    _teid,@"id",
                                    _obj,kObj,
                                    nil];
}

@end
