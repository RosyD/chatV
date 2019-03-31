//
//  NSString+Additions.h
//  AcuCom
//
//  Created by wfs-aculearn on 14-4-2.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Additions)

-(CGSize)getAutoSizeWithLimitWidth:(float)limitWidth andLimitHight:(float)fLimitHight font:(UIFont *)font;
-(float)getHeightAutoresizeWithLimitWidth:(float)limitWidth font:(UIFont *)font;
-(BOOL)startWith:(NSString*)pStart;
-(NSString*)URL_Encode;

@end

@interface NSString (emailValidation)
- (BOOL)isValidEmail;
@end
