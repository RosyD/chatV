//
//  ACGoogleHotspot.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-18.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface ACGoogleHotspot : NSObject

@property (nonatomic) CLLocationCoordinate2D    loaction;
@property (nonatomic,strong) NSString           *name;
@property (nonatomic,strong) NSString           *address;

+(NSMutableArray *)googleHotspotsWithJsonArray:(NSArray *)array;

@end
