//
//  AcuServerProperty.m
//  AcuConference
//
//  Created by aculearn on 13-7-26.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import "AcuServerProperty.h"

@implementation AcuServerProperty

- (id)init
{
    self = [super init];
    if (self)
    {
        iisIP = @"";
        gatewayIP = @"";
        type = @"am";
        waittime = @"0";
        delaytime = @"0";
        priority = @"0";
    }
    
    return self;
}

@end
