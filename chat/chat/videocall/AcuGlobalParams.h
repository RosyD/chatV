//
//  AcuGlobalParams.h
//  AcuConference
//
//  Created by aculearn on 13-7-8.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AcuGlobalParams : NSObject
@property (nonatomic, assign) int ProtocolType;

+ (AcuGlobalParams*) sharedInstance;

@end
