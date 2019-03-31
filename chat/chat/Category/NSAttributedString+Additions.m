//
//  NSAttributedString+Additions.m
//  chat
//
//  Created by 王方帅 on 14-7-10.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "NSAttributedString+Additions.h"

@implementation NSAttributedString (Additions)

-(float)getHeightAutoresizeWithLimitWidth:(float)limitWidth
{
    CGSize size = [self boundingRectWithSize:CGSizeMake(limitWidth, MAXFLOAT) options:(NSStringDrawingOptions)(NSStringDrawingUsesLineFragmentOrigin |NSStringDrawingUsesFontLeading) context:nil].size;
    return size.height;
}

-(float)getWidthAutoresizeWithLimitWidth:(float)limitWidth
{
    CGSize size = [self boundingRectWithSize:CGSizeMake(limitWidth, MAXFLOAT) options:(NSStringDrawingOptions)(NSStringDrawingUsesLineFragmentOrigin |NSStringDrawingUsesFontLeading) context:nil].size;
    return size.width;
}

@end
