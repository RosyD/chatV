//
//  NSDate+Additions.m
//  AcuCom
//
//  Created by wfs-aculearn on 14-4-2.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "NSDate+Additions.h"
#import <CommonCrypto/CommonCryptor.h>

@implementation NSDate (Additions)

+(NSString *)timeStringForRecentDate:(NSDate *)recentDate{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps  = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:recentDate];
    NSInteger hour = [comps hour];
    NSInteger min = [comps minute];
    return [NSString stringWithFormat:@"%02d:%02d",(int)hour,(int)min];
}

+ (NSString *)stringForRecentDate:(NSDate *)recentDate needTime:(BOOL)bNeedTime
{   // 规则：
    // 0当天则只显示时间: NSDateFormatterShortStyle    下午4:52
    // 1昨天
    // 2星期 （只显示最近四天的）
    // 3超过的则显示 NSDateFormatterShortStyle 11-9-17
    
    //[d timeIntervalSinceNow];
    NSString *result = nil;
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    // NSDateFormatterShortStyle    下午4:52
    // kCFDateFormatterMediumStyle  下午4:53:23
    // kCFDateFormatterLongStyle    格林尼治标准时间+0800下午4时55分03秒
    // kCFDateFormatterFullStyle    中国标准时间下午4时55分43秒
    //[dateFormatter setTimeStyle:kCFDateFormatterFullStyle];
    // NSDateFormatterShortStyle 11-9-17
    // NSDateFormatterMediumStyle 2012-06-17
    // NSDateFormatterLongStyle 2011年9月17日
    // NSDateFormatterFullStyle 2011年9月17日星期六
    //[dateFormatter setDateStyle:NSDateFormatterFullStyle];
    
    // 注意与语言不是一码事，指的是区域设置
//    NSLocale *curLocale = [NSLocale currentLocale];
//    [dateFormatter setLocale:curLocale];// 设置为当前区域
    
    NSInteger days = [NSDate daysBetweenDate:recentDate andDate:[NSDate date]];
#if 0
    if (days >= 0 && days < 7) {
        if (days == 0) {
//            NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
//            NSDateComponents *comps  = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:recentDate];
//            NSInteger hour = [comps hour];
//            NSInteger min = [comps minute];
//            result = [NSString stringWithFormat:@"%02d:%02d",(int)hour,(int)min];
            result = [NSDate timeStringForRecentDate:recentDate];
            bNeedTime = NO;
        }
        else if (days == 1) {
            result = NSLocalizedString(@"yesterday", nil);
        }
        else {
            NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
            NSDateComponents *comps  = [calendar components:NSWeekdayCalendarUnit fromDate:recentDate];
            NSInteger week = [comps weekday];
            switch (week)
            {
                case 2:
                {
                    result = NSLocalizedString(@"mon",nil);
                }
                    break;
                case 3:
                {
                    result = NSLocalizedString(@"Tue",nil);
                }
                    break;
                case 4:
                {
                    result = NSLocalizedString(@"Wed",nil);
                }
                    break;
                case 5:
                {
                    result = NSLocalizedString(@"Thu",nil);
                }
                    break;
                case 6:
                {
                    result = NSLocalizedString(@"Fri",nil);
                }
                    break;
                case 7:
                {
                    result = NSLocalizedString(@"Sat",nil);
                }
                    break;
                case 1:
                {
                    result = NSLocalizedString(@"Sun",nil);
                }
                    break;
                    
                default:
                    break;
            }
//            [dateFormatter setDateFormat:@"EEEE"];
//            result = [dateFormatter stringFromDate:recentDate];
        }
    } else {
        result = [NSDateFormatter localizedStringFromDate:recentDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
    }
#else
    if(0==days){
        result = [NSDate timeStringForRecentDate:recentDate];
        bNeedTime = NO;
    }
    else{
        


//        NSString *dateComponents = @"yyyy/M/d";
//        
//        NSLocale *curLocale = [NSLocale currentLocale];
//        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//        [dateFormatter setLocale:curLocale];
//        [dateFormatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:dateComponents options:0 locale:curLocale]];
//        
//        NSLog(@"%@",[dateFormatter stringFromDate:recentDate]);
        
        
        result = [NSDateFormatter localizedStringFromDate:recentDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
    }
#endif
    
    if(bNeedTime){
        result = [NSString stringWithFormat:@"%@ %@",result,[NSDate timeStringForRecentDate:recentDate]];
    }
    
    return result;
}

+(NSString *)stringForRecentDate:(NSDate *)recentDate{
    return [NSDate stringForRecentDate:recentDate needTime:NO];
}

+(NSString *)dateAndTimeStringForRecentDate:(NSDate *)recentDate{
    return [NSDate stringForRecentDate:recentDate needTime:YES];
}

+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    if (fromDateTime == nil || toDateTime == nil)
    {
        return 0;
    }
    
    NSDate *fromDate;
    NSDate *toDate;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate
                 interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate
                 interval:NULL forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSDayCalendarUnit
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}
@end

#import <CommonCrypto/CommonCryptor.h>

@implementation NSData (Encryption)

//这个加密和Java兼容
#if 1
- (NSData *)AES256ParmEncryptWithKey:(NSString *)key {
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [self length];
    
    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionECBMode|kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          NULL /* initialization vector (optional) */,
                                          [self bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    
    free(buffer); //free the buffer;
    return nil;
}

- (NSData *)AES256ParmDecryptWithKey:(NSString *)key {
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [self length];
    
    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionECBMode|kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          NULL /* initialization vector (optional) */,
                                          [self bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesDecrypted);
    
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    
    free(buffer); //free the buffer;
    return nil;
}

#else

- (NSData *)AES256ParmEncryptWithKey:(NSString *)key   //加密
{
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeAES128,
                                          NULL,
                                          [self bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}


- (NSData *)AES256ParmDecryptWithKey:(NSString *)key   //解密
{
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeAES128,
                                          NULL,
                                          [self bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesDecrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    free(buffer);
    return nil;
}
#endif

@end