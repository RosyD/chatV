//
//  NSDate+Additions.h
//  AcuCom
//
//  Created by wfs-aculearn on 14-4-2.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Additions)

+(NSString *)timeStringForRecentDate:(NSDate *)recentDate;
+(NSString *)stringForRecentDate:(NSDate *)recentDate;
+(NSString *)dateAndTimeStringForRecentDate:(NSDate *)recentDate;

@end

@interface NSData (Encryption)


- (NSData *)AES256ParmEncryptWithKey:(NSString *)key;   //加密
- (NSData *)AES256ParmDecryptWithKey:(NSString *)key;   //解密

@end