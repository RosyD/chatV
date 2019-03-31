//
//  ACReadCountDB.m
//  AcuCom
//
//  Created by 王方帅 on 14-5-15.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACReadCountDB.h"
#import "ACReadCount.h"
#import "ACDBManager.h"
#import "ACMessage.h"

@implementation ACReadCountDB
//用于存储topicEntity对应seq的readCount

//@property (nonatomic,strong) NSString   *topicEntityID;
//@property (nonatomic) long              seq;
//@property (nonatomic) long              readCount;
+(BOOL)createTable:(NSInteger)nDB_Ver
{
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        BOOL success = [db executeUpdate:
                        @"CREATE TABLE IF NOT EXISTS readCount ("\
                        "topicEntityID TEXT, "\
                        "seq INTEGER, "\
                        "readCount INTEGER, "\
                        "PRIMARY KEY (topicEntityID,seq) "\
                        ");"];
        if (!success)
        {
            ITLog(@"readCount表创建失败");
        }
        else
        {
            ITLog(@"readCount表已经创建");
        }
    }];
    return NO;
}

+(void)dropTable
{
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        BOOL success = [db executeUpdate:
                        @"DROP TABLE IF EXISTS readCount;"];
        if (!success)
        {
            ITLog(@"readCount表删除失败");
        }
    }];
}

+(void)saveReadCountListToDBWithArray:(NSArray *)array
{
    for (ACReadCount *readCount in array)
    {
        if (readCount.topicEntityID)
        {
            [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
                
                FMDatabase_Enable_Error_logs(db);
                
                NSString *sql = [NSString stringWithFormat:@"SELECT * FROM readCount "\
                                 "WHERE topicEntityID='%@' and seq='%ld'",
                                 readCount.topicEntityID,readCount.seq];
                FMResultSet *resultSet = [db executeQuery:sql];
                if (resultSet.next)
                {
                    long readCountLong = [resultSet longForColumn:@"readCount"];
                    [resultSet close];
                    
                    BOOL isNeedUpdate = readCountLong != readCount.readCount;
                    if (isNeedUpdate)
                    {
                        sql = [NSString stringWithFormat:@"UPDATE readCount SET "\
                               "readCount='%ld' "\
                               "WHERE topicEntityID='%@' and seq='%ld'",
                               readCount.readCount,
                               readCount.topicEntityID,
                               readCount.seq];
                        BOOL succ = [db executeUpdate:sql];
                        if (!succ)
                        {
                            ITLog(@"UPDATE readCount失败");
                        }
                    }
                }
                else
                {
                    sql = [NSString stringWithFormat:@"INSERT INTO readCount "\
                           "(topicEntityID, seq, readCount) "\
                           "VALUES ('%@', %ld, %ld)",
                           readCount.topicEntityID,
                           readCount.seq,
                           readCount.readCount];
                    BOOL succ = [db executeUpdate:sql
                                 ];
                    if (!succ)
                    {
                        ITLog(@"INSERT readCount失败");
                    }
                }
            }];
        }
    }
}


+(NSArray *)getReadCountFromDBWithTopicEntityID:(NSString *)topicEntityID seqArray:(NSArray *)seqArray
{
    if ([seqArray count] == 0)
    {
        return nil;
    }
    __block NSMutableArray *readCountArray = [NSMutableArray arrayWithCapacity:[seqArray count]];
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        
        NSString *seqString = @"";
        for (int i = 0; i < ((int)[seqArray count])-1; i++)
        {
            NSNumber *seqNum = [seqArray objectAtIndex:i];
            seqString = [seqString stringByAppendingFormat:@"seq='%@' or ",seqNum];
        }
        if ([seqArray count]>0)
        {
            NSNumber *seqNum = [seqArray objectAtIndex:[seqArray count]-1];
            seqString = [seqString stringByAppendingFormat:@"seq='%@' ",seqNum];
        }
        
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM readCount "\
                         "WHERE topicEntityID='%@' and (%@)",
                         topicEntityID,seqString];
        FMResultSet *resultSet = [db executeQuery:sql];
        while (resultSet.next)
        {
            long lSeg = [resultSet longForColumn:@"seq"];
            if(lSeg<ACMessage_seq_DEF){
                ACReadCount *readCount = [[ACReadCount alloc] init];
                readCount.topicEntityID = [resultSet stringForColumn:@"topicEntityID"];
                readCount.seq = lSeg;
                readCount.readCount = [resultSet longForColumn:@"readCount"];
                [readCountArray addObject:readCount];
            }
        }
        [resultSet close];
    }];
    return readCountArray;
}

@end
