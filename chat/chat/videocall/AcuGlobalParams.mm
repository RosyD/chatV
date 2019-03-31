//
//  AcuGlobalParams.m
//  AcuConference
//
//  Created by aculearn on 13-7-8.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import "AcuGlobalParams.h"

static AcuGlobalParams* gParams = nil;

@implementation AcuGlobalParams

@synthesize ProtocolType;

+ (AcuGlobalParams*) sharedInstance {
    @synchronized(self)
    {
        if (!gParams) {
            gParams = [[self alloc] init];
        }
        
        return gParams;
    }
    
    return nil;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        ProtocolType = -1;
    }
    
    return self;
}


@end
