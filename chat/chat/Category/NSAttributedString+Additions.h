//
//  NSAttributedString+Additions.h
//  chat
//
//  Created by 王方帅 on 14-7-10.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (Additions)

-(float)getHeightAutoresizeWithLimitWidth:(float)limitWidth;

-(float)getWidthAutoresizeWithLimitWidth:(float)limitWidth;

@end
