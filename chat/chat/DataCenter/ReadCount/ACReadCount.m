//
//  ACReadCount.m
//  AcuCom
//
//  Created by 王方帅 on 14-5-15.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACReadCount.h"
#import "ACMessage.h"

#define kCnt    @"cnt"

@implementation ACReadCount

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.succ = YES;
    }
    return self;
}

- (instancetype)initWithReadCountDic:(NSDictionary *)readCountDic withEntityID:(NSString *)entityID
{
    self = [super init];
    if (self) {
        self.topicEntityID = entityID;
        self.seq           = [[readCountDic objectForKey:kSeq] longValue];
        self.readCount     = [[readCountDic objectForKey:kCnt] longValue];
        self.succ          = YES;
    }
    return self;
}

+(NSArray *)getReadCountListWithArray:(NSArray *)array withEntityID:(NSString *)entityID
{
    NSMutableArray *readCountArray = [NSMutableArray arrayWithCapacity:[array count]];
    for (NSDictionary *readCountDic in array)
    {
        ACReadCount *readCount = [[ACReadCount alloc] initWithReadCountDic:readCountDic withEntityID:entityID];
        [readCountArray addObject:readCount];
    }
    return readCountArray;
}

//得到失败的readCount
+(NSArray *)getFailReadCountListWithArray:(NSArray *)array withEntityID:(NSString *)entityID
{
    NSMutableArray *readCountArray = [NSMutableArray arrayWithCapacity:[array count]];
    for (NSNumber *num in array)
    {
        ACReadCount *readCount  = [[ACReadCount alloc] init];
        readCount.topicEntityID = entityID;
        readCount.seq           = [num longValue];
        readCount.readCount     = -1;
        readCount.succ          = NO;
        [readCountArray addObject:readCount];
    }
    return readCountArray;
}

@end
