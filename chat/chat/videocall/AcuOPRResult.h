//
//  AcuOPRResult.h
//  AcuConference
//
//  Created by aculearn on 13-7-26.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AcuServerProperty.h"

@interface AcuOPRResult : NSObject
{
@public
    AcuServerProperty   *am;
    AcuServerProperty   *mainAS;
    NSMutableArray      *asList;
    
    NSString            *session;
    NSString            *sessionStatus;
    NSString            *amStatus;
    
    NSString            *prefix;
    NSString            *gatewayIP;
    NSString            *iisIP;
    NSString            *gatewayParam;
	NSString            *myStream;
}

@end
