//
//  ACReadSeqDB.m
//  AcuCom
//
//  Created by 王方帅 on 14-5-15.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACReadSeqDB.h"
#import "ACDBManager.h"
#import "ACReadSeq.h"
#import "ACEntity.h"
#import "ACDataCenter.h"
#import "ACMessage.h"

@implementation ACReadSeqDB
//用于存储topicEntity对应已经同步的Seq

+(BOOL)createTable:(NSInteger)nDB_Ver
{
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        BOOL success = [db executeUpdate:
                        @"CREATE TABLE IF NOT EXISTS readSeq ("\
                        "topicEntityID TEXT PRIMARY KEY, "\
                        "seq INTEGER "\
                        ");"];
        if (!success)
        {
            ITLog(@"readSeq表创建失败");
        }
    }];
    return NO;
}

+(void)dropTable
{
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        BOOL success = [db executeUpdate:
                        @"DROP TABLE IF EXISTS readSeq;"];
        if (!success)
        {
            ITLog(@"readSeq表删除失败");
        }
    }];
}

//更新置readSeq为最大值，以便下次readCount都从网络获取最新值（重新登录，轮询曾经断过）
+(void)updateReadSeqDBToSeqMax
{
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        
        NSString *entityIDSql = @"";
        NSMutableArray *array = [NSMutableArray array];
        for (int i = 0; i < [[ACDataCenter shareDataCenter].topicEntityArray count]; i++)
        {
            ACTopicEntity *topicEntity = [[ACDataCenter shareDataCenter].topicEntityArray objectAtIndex:i];
            if (![topicEntity.mpType isEqualToString:cSingleChat])
            {
                [array addObject:topicEntity];
            }
        }
        for (int i = 0; i < ((int)[array count])-1; i++)
        {
            ACTopicEntity *topicEntity = [array objectAtIndex:i];
            entityIDSql = [entityIDSql stringByAppendingFormat:@"topicEntityID='%@' or ",topicEntity.entityID];
        }
        if ([array count] > 0)
        {
            ACTopicEntity *topicEntity = [array lastObject];
            entityIDSql = [entityIDSql stringByAppendingFormat:@"topicEntityID='%@' ",topicEntity.entityID];
            
            NSString *sql = [NSString stringWithFormat:@"UPDATE readSeq SET "\
                             "seq='%ld' where %@",
                             ACMessage_seq_DEF,entityIDSql];
            BOOL succ = [db executeUpdate:sql];
            if (!succ)
            {
                ITLog(@"UPDATE readSeq SeqMax失败");
            }
        }
    }];
}

+(void)saveReadSeqToDBWithReadSeq:(ACReadSeq *)readSeq needUpdate:(BOOL)needUpdate
{
    if (readSeq.topicEntityID)
    {
        [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
            
            FMDatabase_Enable_Error_logs(db);
            
            NSString *sql = [NSString stringWithFormat:@"SELECT * FROM readSeq "\
                             "WHERE topicEntityID='%@' ",
                             readSeq.topicEntityID];
            FMResultSet *resultSet = [db executeQuery:sql];
            if (resultSet.next)
            {
                long seqTmp = [resultSet longForColumn:@"seq"];
                [resultSet close];
                
                BOOL isNeedUpdate = needUpdate || seqTmp < readSeq.seq;
                if (isNeedUpdate)
                {
                    sql = [NSString stringWithFormat:@"UPDATE readSeq SET "\
                           "seq='%ld' "\
                           "WHERE topicEntityID='%@' ",
                           readSeq.seq,
                           readSeq.topicEntityID];
                    BOOL succ = [db executeUpdate:sql];
                    if (!succ)
                    {
                        ITLog(@"UPDATE readSeq失败");
                    }
                }
            }
            else
            {
                sql = [NSString stringWithFormat:@"INSERT INTO readSeq "\
                       "(topicEntityID, seq) "\
                       "VALUES ('%@', '%ld')",
                       readSeq.topicEntityID,
                       readSeq.seq];
                BOOL succ = [db executeUpdate:sql];
                if (!succ)
                {
                    ITLog(@"INSERT readSeq失败");
                }
            }
        }];
    }
}

+(ACReadSeq *)getReadSeqFromDBWithTopicEntityID:(NSString *)topicEntityID
{
    __block ACReadSeq *readSeq = nil;
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM readSeq "\
                         "WHERE topicEntityID='%@' ",
                         topicEntityID];
        FMResultSet *resultSet = [db executeQuery:sql];
        if (resultSet.next)
        {
            readSeq = [[ACReadSeq alloc] init];
            readSeq.topicEntityID = [resultSet stringForColumn:@"topicEntityID"];
            readSeq.seq = [resultSet longForColumn:@"seq"];
        }
        [resultSet close];
    }];
    return readSeq;
}

@end
