//
//  AcuStartSessionCancelParam.m
//  chat
//
//  Created by Aculearn on 15-3-12.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#import "AcuStartSessionCancelParam.h"

@implementation AcuStartSessionCancelParam

@synthesize sessionCanceledInside;
@synthesize sessionCanceledOutside;
@synthesize sessionCanceled;
@synthesize sessionCanceledCommandSended;

+ (instancetype)sharedInstance
{
    static id instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        sessionCanceledInside = NO;
        sessionCanceledOutside = NO;
        sessionCanceled = NO;
        sessionCanceledCommandSended = NO;
    }
    
    return self;
}

@end
