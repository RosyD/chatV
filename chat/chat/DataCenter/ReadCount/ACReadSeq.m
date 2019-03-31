//
//  ACReadSeq.m
//  AcuCom
//
//  Created by 王方帅 on 14-5-15.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACReadSeq.h"
#import "ACMessage.h"

@implementation ACReadSeq

- (instancetype)initWithTopicReadEvent:(NSDictionary *)topicReadEvent
{
    self = [super init];
    if (self) {
        self.topicEntityID = [topicReadEvent objectForKey:kTeid];
        self.seq = [[topicReadEvent objectForKey:kSeq] longValue];
        self.userID = [topicReadEvent objectForKey:kUid];
    }
    return self;
}

@end
