//
//  ACGoogleHotspot.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-18.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACGoogleHotspot.h"

@implementation ACGoogleHotspot

- (id)initWithDic:(NSDictionary *)hotspotDic
{
    self = [super init];
    if (self) {
        NSDictionary *location = [[hotspotDic objectForKey:@"geometry"] objectForKey:@"location"];
        self.loaction = CLLocationCoordinate2DMake([[location objectForKey:@"lat"] doubleValue], [[location objectForKey:@"lng"] doubleValue]);
        _name = [hotspotDic objectForKey:@"name"];
        _address = [hotspotDic objectForKey:@"vicinity"];
        if(nil==_address){
            _address =  hotspotDic[@"formatted_address"];
        }
    }
    return self;
}

+(NSMutableArray *)googleHotspotsWithJsonArray:(NSArray *)array
{
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:[array count]];
    for (NSDictionary *dic in array)
    {
        ACGoogleHotspot *hotspot = [[ACGoogleHotspot alloc] initWithDic:dic];
        [returnArray addObject:hotspot];
    }
    return returnArray;
}

@end
