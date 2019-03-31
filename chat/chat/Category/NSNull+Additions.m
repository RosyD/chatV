//
//  NSNull+Additions.m
//  chat
//
//  Created by 王方帅 on 14-6-11.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "NSNull+Additions.h"

@implementation NSNull (Additions)

-(double)doubleValue
{
    return 0.0;
}

-(int)intValue
{
    return 0;
}

-(float)floatValue
{
    return 0.0;
}

- (NSInteger)integerValue
{
    return 0;
}

- (long long)longLongValue
{
    return 0;
}

-(BOOL)isEqualToString:(NSString *)string
{
    return NO;
}

-(NSObject *)objectForKey:(NSString *)key
{
    return nil;
}

-(NSObject *)objectAtIndex:(NSInteger)index
{
    return nil;
}

-(NSObject *)_isResizable
{
    return nil;
}

-(CGImageRef)CGImage
{
    return nil;
}

@end
