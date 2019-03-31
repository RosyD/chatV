//
//  ACReadCount.h
//  AcuCom
//
//  Created by 王方帅 on 14-5-15.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ACReadCount : NSObject

@property (nonatomic,strong) NSString   *topicEntityID;
@property (nonatomic) long              seq;
@property (nonatomic) long              readCount;
@property (nonatomic) BOOL              succ;

+(NSArray *)getReadCountListWithArray:(NSArray *)array withEntityID:(NSString *)entityID;

//得到失败的readCount
+(NSArray *)getFailReadCountListWithArray:(NSArray *)array withEntityID:(NSString *)entityID;

@end
