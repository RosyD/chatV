//
//  NSString+Additions.m
//  AcuCom
//
//  Created by wfs-aculearn on 14-4-2.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "NSString+Additions.h"

@implementation NSString (Additions)


-(CGSize)getAutoSizeWithLimitWidth:(float)limitWidth andLimitHight:(float)fLimitHight font:(UIFont *)font{
    
    return [self boundingRectWithSize:CGSizeMake(limitWidth, fLimitHight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil].size;
    
    
//    NSDictionary *tdic = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil];
//    return [self boundingRectWithSize:CGSizeMake(limitWidth, fLimitHight)
//                                     options:(NSStringDrawingOptions)(NSStringDrawingUsesLineFragmentOrigin |NSStringDrawingUsesFontLeading)
//                                  attributes:tdic
//                                     context:nil].size;
    /*
    NSDictionary *tdic = [NSDictionary dictionaryWithObjectsAndKeys:self.font,NSFontAttributeName, nil];
    return  [self.text boundingRectWithSize:CGSizeMake(limitWidth, fLimitHight)
                                    options:(NSStringDrawingOptions)(
                                                                     NSStringDrawingTruncatesLastVisibleLine |NSStringDrawingUsesLineFragmentOrigin |NSStringDrawingUsesFontLeading)
                                 attributes:tdic
                                    context:nil].size;*/
    
    
}

-(float)getHeightAutoresizeWithLimitWidth:(float)limitWidth font:(UIFont *)font
{
//    CGSize size = [self sizeWithFont:font constrainedToSize:CGSizeMake(limitWidth, MAXFLOAT) lineBreakMode:NSLineBreakByCharWrapping];
//    return size.height;
    return [self getAutoSizeWithLimitWidth:limitWidth andLimitHight:MAXFLOAT font:font].height;
}

-(BOOL)startWith:(NSString*)pStart{
    if(pStart.length&&pStart.length<=self.length){
        NSString * pHeadString = [self substringToIndex:pStart.length];
        return [pHeadString isEqualToString:pStart];
    }
    return NO;
}

-(NSString*)URL_Encode{
    
    /*
     
     - (NSString*)encodeURL:(NSString *)string
     {
     NSString *newString = [NSMakeCollectable(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding([self stringEncoding]))) autorelease];
     if (newString) {
     return newString;
     }
     return @"";
     }
     */
    
    return (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                             
                                                                             NULL, /* allocator */
                                                                             
                                                                             (__bridge CFStringRef)self,
                                                                             
                                                                             NULL, /* charactersToLeaveUnescaped */
                                                                             
                                                                             (CFStringRef)@":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`",
                                                                             
                                                                             kCFStringEncodingUTF8);
}

@end


@implementation NSString (emailValidation)
-(BOOL)isValidEmail
{
    BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self];
}
@end
