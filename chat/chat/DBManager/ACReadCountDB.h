//
//  ACReadCountDB.h
//  AcuCom
//
//  Created by 王方帅 on 14-5-15.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ACReadCountDB : NSObject

+(BOOL)createTable:(NSInteger)nDB_Ver;

+(void)dropTable;

+(void)saveReadCountListToDBWithArray:(NSArray *)array;

+(NSArray *)getReadCountFromDBWithTopicEntityID:(NSString *)topicEntityID seqArray:(NSArray *)seqArray;

@end
