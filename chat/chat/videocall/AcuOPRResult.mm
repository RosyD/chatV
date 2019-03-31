//
//  AcuOPRResult.m
//  AcuConference
//
//  Created by aculearn on 13-7-26.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import "AcuOPRResult.h"

@implementation AcuOPRResult

- (id)init
{
    self = [super init];
    if (self)
    {
        am = [AcuServerProperty new];
        mainAS = [AcuServerProperty new];
        asList = [NSMutableArray new];
        
        session = @"";
        sessionStatus = @"0";
        amStatus = @"0";
        
        prefix = @"-";
        gatewayIP = @"";
        iisIP = @"";
        gatewayParam = @"";
		myStream = @"";
    }
    
    return self;
}

@end
