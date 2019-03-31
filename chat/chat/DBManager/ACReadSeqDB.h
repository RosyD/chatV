//
//  ACReadSeqDB.h
//  AcuCom
//
//  Created by 王方帅 on 14-5-15.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACReadSeq;
@interface ACReadSeqDB : NSObject

+(BOOL)createTable:(NSInteger)nDB_Ver;

+(void)dropTable;

//更新置readSeq为最大值，以便下次readCount都从网络获取最新值（重新登录，轮询曾经断过）
+(void)updateReadSeqDBToSeqMax;

+(void)saveReadSeqToDBWithReadSeq:(ACReadSeq *)readSeq needUpdate:(BOOL)needUpdate;

+(ACReadSeq *)getReadSeqFromDBWithTopicEntityID:(NSString *)topicEntityID;

@end
