//
//  ACReadSeq.h
//  AcuCom
//
//  Created by 王方帅 on 14-5-15.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kUid    @"uid"

@interface ACReadSeq : NSObject

@property (nonatomic,strong) NSString   *topicEntityID;
@property (nonatomic,strong) NSString   *userID;
@property (nonatomic) long              seq;

- (instancetype)initWithTopicReadEvent:(NSDictionary *)topicReadEvent;

@end
