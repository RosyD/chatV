//
//  AcuServerProperty.h
//  AcuConference
//
//  Created by aculearn on 13-7-26.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AcuServerProperty : NSObject
{
@public
    NSString *iisIP;
    NSString *gatewayIP;
    NSString *type;
    NSString *waittime;
    NSString *delaytime;
    NSString *priority;
}

@end
