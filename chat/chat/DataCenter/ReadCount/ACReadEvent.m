//
//  ACReadEvent.m
//  AcuCom
//
//  Created by 王方帅 on 14-5-16.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACReadEvent.h"
#import "ACReadSeq.h"
#import "ACReadSeqDB.h"

NSString *const kACReadSeqUpdateNotification = @"kACReadSeqUpdateNotification";

@implementation ACReadEvent

+(ACReadSeq *)updateReadSeqEventWithDic:(NSDictionary *)dic
{
    ACReadSeq *readSeq = [[ACReadSeq alloc] initWithTopicReadEvent:dic];
    [ACReadSeqDB saveReadSeqToDBWithReadSeq:readSeq needUpdate:NO];
    [ACUtility postNotificationName:kACReadSeqUpdateNotification object:readSeq];
    
    return readSeq;
}

@end
