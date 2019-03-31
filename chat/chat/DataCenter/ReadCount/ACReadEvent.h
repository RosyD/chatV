//
//  ACReadEvent.h
//  AcuCom
//
//  Created by 王方帅 on 14-5-16.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kACReadSeqUpdateNotification;

@class ACReadSeq;
@interface ACReadEvent : NSObject

+(ACReadSeq *)updateReadSeqEventWithDic:(NSDictionary *)dic;

@end
