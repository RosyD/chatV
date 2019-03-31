//
//  ACMessageDB.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-28.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACMessageDB.h"
#import "ACDBManager.h"
#import "ACMessage.h"
#import "ACNetCenter.h"
#import "ACChatNetCenter.h"

@implementation ACMessageDB

+(BOOL)createTable:(NSInteger)nDB_Ver
{
//    __block BOOL bRet = NO;
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {

        FMDatabase_Enable_Error_logs(db);
        
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS file_msg_cache ("\
                        "messageID TEXT PRIMARY KEY, "\
                        "topicEntityID TEXT, "\
                        "messageEnumType INTEGER, "\
                        "seq INTEGER, "\
                        "length INTEGER, "\
                        "resourceID, "\
                        "thumbResourceID "\
                        ");"];
        
        [db executeUpdate:@"CREATE INDEX IF NOT EXISTS file_msg_cache_msgid_idx ON file_msg_cache(messageID);"];

        BOOL success = [db executeUpdate:
                        @"CREATE TABLE IF NOT EXISTS message ("\
                        "messageID TEXT PRIMARY KEY, "\
                        "topicEntityID TEXT, "\
                        "messageType TEXT, "\
                        "createTime DOUBLE, "\
                        "messageEnumType INTEGER, "\
                        "messageLongitude DOUBLE, "\
                        "messageLatitude DOUBLE, "\
                        "directionType INTEGER, "\
                        "sendUserID TEXT, "\
                        "seq INTEGER, "\
                        "content TEXT, "\
                        "messageUploadState INTEGER"\
                        ");"];
        
        //升级数据库

//        switch (nDB_Ver) {
//            case 0:
//            {
//                NSString *modify=@"alter table message add column msg_from text not null default ''";
//                [db executeUpdate:modify];
//                bRet = YES;
//            }
//            default:
//                break;
//        }
        
        [db executeUpdate:@"CREATE INDEX IF NOT EXISTS message_msgid_idx ON message(messageID);"];

        if (!success)
        {
            ITLog(@"message表创建失败");
        }
    }];
    return NO;
}

+(void)dropTable
{
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        BOOL success = [db executeUpdate:
                        @"DROP TABLE IF EXISTS message;"];
        if (!success)
        {
            ITLog(@"message表删除失败");
        }
        [db executeUpdate:@"DROP TABLE IF EXISTS file_msg_cache;"];
        [db executeUpdate:@"DROP INDEX IF EXISTS message_msgid_idx;"];
        [db executeUpdate:@"DROP INDEX IF EXISTS file_msg_cache_msgid_idx;"];
    }];
}

+(BOOL)updateMessageIDWithSourceMessageID:(NSString *)sourceMsgID targetMsgID:(NSString *)targetMsgID
{
    __block BOOL succ = false;
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        FMDatabase_Enable_Error_logs(db);

        NSString *sql = [NSString stringWithFormat:@"UPDATE message SET messageID='%@' WHERE messageID='%@' ",targetMsgID,sourceMsgID];
        succ = [db executeUpdate:sql];
        if (!succ)
        {
            ITLog(@"message表messageID替换失败,可能多个Msg快速生成了同一个ID？？");
        }
    }];
    return succ;
}

+(BOOL)saveMessageToDBWithMessage:(ACMessage *)message
{
    ITLogEX_If(nil==message, @"message==nil");
    
    __block BOOL succ;
    __block BOOL bIsInsert = NO;
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);

        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM message "\
                         "WHERE messageID='%@' ",
                         message.messageID];
        FMResultSet *resultSet = [db executeQuery:sql];
//        NSString* content = SQLite_String(message.content);
        NSString* content =    message.content;
        
        //如果有此消息,略过
        if (resultSet.next)
        {
            [resultSet close];
//            NSString *sql = [NSString stringWithFormat:@"UPDATE message SET "\
//                             "topicEntityID='%@', "\
//                             "messageType='%@', "\
//                             "createTime='%f', "\
//                             "messageEnumType='%d', "\
//                             "messageLongitude='%f', "\
//                             "messageLatitude='%f', "\
//                             "directionType='%d', "\
//                             "sendUserID='%@', "\
//                             "seq='%ld', "\
//                             "content='%@', "\
//                             "messageUploadState='%d' "\
//                             "WHERE messageID='%@' ",
//                             message.topicEntityID,
//                             message.messageType,
//                             message.createTime,
//                             message.messageEnumType,
//                             message.messageLocation.longitude,
//                             message.messageLocation.latitude,
//                             message.directionType,
//                             message.sendUserID,
//                             message.seq,
//                             content,
//                             (int)message.messageUploadState,
//                             message.messageID];
////            ITLog(sql);
//            BOOL success = [db executeUpdate:sql];
            
//            if (!success)
//            {
//                ITLog(@"message表更新记录失败");
//            }
            succ = [db executeUpdateWithFormat:@"UPDATE message SET "\
                                                "topicEntityID=%@, "\
                                                "messageType=%@, "\
                                                "createTime=%f, "\
                                                "messageEnumType=%d, "\
                                                "messageLongitude=%f, "\
                                                "messageLatitude=%f, "\
                                                "directionType=%d, "\
                                                "sendUserID=%@, "\
                                                "seq=%ld, "\
                                                "content=%@, "\
                                                "messageUploadState=%d "\
                                                "WHERE messageID=%@;",
                                                message.topicEntityID,
                                                message.messageType,
                                                message.createTime,
                                                message.messageEnumType,
                                                message.messageLocation.longitude,
                                                message.messageLocation.latitude,
                                                message.directionType,
                                                message.sendUserID,
                                                message.seq,
                                                content,
                                                (int)message.messageUploadState,
                                                message.messageID];
        }
        else
        {
//            NSString *sql = @"INSERT INTO message "\
//            "(messageID, topicEntityID, messageType, createTime, messageEnumType, messageLongitude, messageLatitude, directionType, sendUserID, seq, content, messageUploadState) "\
//            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";
//            
//            NSArray *array = [NSArray arrayWithObjects:topicEntity.entityID,[NSNumber numberWithDouble:topicEntity.updateTime],[NSNumber numberWithLong:topicEntity.lastestSequence],[NSNumber numberWithInt:topicEntity.entityType],topicEntity.title,topicEntity.icon,topicEntity.mpType,topicEntity.url,[NSNumber numberWithDouble:topicEntity.createTime],topicEntity.permString,[NSNumber numberWithLong:topicEntity.currentSequence],[NSNumber numberWithBool:topicEntity.isAdmin],topicEntity.lastestTextMessage,topicEntity.lastestMessageType,[NSNumber numberWithDouble:topicEntity.lastestMessageTime],topicEntity.lastestMessageUserID,topicEntity.singleChatUserID, nil];
//            
//            success = [db executeUpdate:sql withArgumentsInArray:array];
//            
            BOOL success = [db executeUpdateWithFormat:@"INSERT INTO message "\
                       "(messageID, topicEntityID, messageType, createTime, messageEnumType, messageLongitude, messageLatitude, directionType, sendUserID, seq, content, messageUploadState) "\
                       "VALUES (%@, %@, %@, %f, %d, %f, %f, %d, %@, %ld, %@, %d);",
                       message.messageID,
                       message.topicEntityID,
                       message.messageType,
                       message.createTime,
                       message.messageEnumType,
                       message.messageLocation.longitude,
                       message.messageLocation.latitude,
                       message.directionType,
                       message.sendUserID,
                       message.seq,
                       content,
                       message.messageUploadState];
            bIsInsert = success;
            if (!success)
            {
                ITLog(@"message表添加记录失败");
            }
            succ = success;
        }
    }];
    
    if(message.messageEnumType==ACMessageEnumType_Image&&
       message.seq!=ACMessage_seq_DEF){
        ACFileMessage* fileMessage = (ACFileMessage*)message;
        if(fileMessage.resourceID&&fileMessage.length>0){
            [ACMessageDB saveFileMessageCacheToDB:[ACFileMessageCache getFileMessageCacheWithFileMessage:fileMessage]
                                WithTopicEntityID:message.topicEntityID];
        }
    }
    
    return succ;
}

//删除topicEntity对应删除message
+(BOOL)deleteMessageFromDBWithTopicEntityID:(NSString *)topicEntityID
{
    __block BOOL succ;
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM message "\
                         "WHERE topicEntityID='%@' ",
                         topicEntityID];
        BOOL success = [db executeUpdate:sql];
        if (!success)
        {
            ITLog(@"message表删除记录失败");
        }
        succ = success;
        [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM file_msg_cache "\
                           "WHERE topicEntityID='%@';",
                           topicEntityID]];

    }];
    return succ;
}

//删除messageid对应的message
+(BOOL)deleteMessageFromDBWithMessageID:(NSString *)messageID
{
    __block BOOL succ;
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM message "\
                         "WHERE messageID='%@' ",
                         messageID];
        BOOL success = [db executeUpdate:sql];
        if (!success)
        {
            ITLog(@"message表删除记录失败");
        }
        succ = success;
    }];
    return succ;
}

+(NSMutableArray *)getUnSendMessageListWithTopicEntityID:(NSString *)topicEntityID
{
    __block NSMutableArray *unSendMsgList = [NSMutableArray array];
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM message "\
                         "WHERE topicEntityID='%@' and seq==%ld ORDER BY createTime desc",
                         topicEntityID,ACMessage_seq_DEF];
        FMResultSet *resultSet = [db executeQuery:sql];
        if (resultSet)
        {
            @autoreleasepool
            {
                while (resultSet.next)
                {
                    ACMessage *message = [ACMessage getMessageWithFMResultSet:resultSet];
                    if(![[ACNetCenter shareNetCenter].chatCenter messageIsSendingWithMessage:message]){
                        //正在发送中，不算失败
                        if (message.messageUploadState == ACMessageUploadState_Uploading){
                            message.messageUploadState = ACMessageUploadState_UploadFailed;
                        }
                        else if (message.messageUploadState == ACMessageUploadState_Transmiting){
                            message.messageUploadState = ACMessageUploadState_TransmitFailed;
                        }
                    }
                    
                    [unSendMsgList insertObject:message atIndex:0];
                    ITLogEX(@"%@",message);
                }
            }
            [resultSet close];
        }
    }];
    return unSendMsgList;
}



//根据topicEntityID获取messageList,lastSeq往上取10条
//+(NSMutableArray *)getMessageListFromDBWithTopicEntityID:(NSString *)topicEntityID lastSeq:(long)lastSeq limit:(int)nLimit{
//    return [self getMessageListFromDBWithTopicEntityID:topicEntityID lastSeq:lastSeq withLimit:nLimit];
//}

+(NSMutableArray *)getMessageListFromDBWithTopicEntityID:(NSString *)topicEntityID lastSeq:(long)lastSeq withLimit:(int)nLimit
{
    __block NSMutableArray *messageList = [NSMutableArray arrayWithCapacity:nLimit];
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM message "\
                         "WHERE topicEntityID='%@' and seq<=%ld and seq>%ld ORDER BY seq desc limit %d",
                         topicEntityID,lastSeq,lastSeq-nLimit,nLimit];
        FMResultSet *resultSet = [db executeQuery:sql];
        if (resultSet)
        {
            @autoreleasepool
            {
                while (resultSet.next)
                {
                    ACMessage *message = [ACMessage getMessageWithFMResultSet:resultSet];
                    if (message == nil)
                    {
                        
                    }
                    [messageList insertObject:message atIndex:0];
                }
            }
            [resultSet close];
        }
    }];
    return messageList;
}

//根据topicEntityID获取seqs
+(NSMutableArray *)getMessageSeqsFromDBWithTopicEntityID:(NSString *)topicEntityID fromSeq:(long)seq{
    __block NSMutableArray *messageList = [NSMutableArray arrayWithCapacity:500];
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        //不能使用 seq>=%ld
        NSString *sql = seq>0?[NSString stringWithFormat:@"SELECT seq FROM message "\
                         "WHERE topicEntityID='%@' and seq>%ld ORDER BY seq asc",
                               topicEntityID,seq]:[NSString stringWithFormat:@"SELECT seq FROM message "\
                                                   "WHERE topicEntityID='%@' ORDER BY seq asc",
                                                   topicEntityID];
        FMResultSet *resultSet = [db executeQuery:sql];
        if (resultSet)
        {
            @autoreleasepool
            {
                while (resultSet.next)
                {
                    [messageList addObject:@([resultSet longForColumnIndex:0])];
                }
            }
            [resultSet close];
        }
    }];
    return messageList;
}

//根据topicEntityID获取messageList,firstSeq往下取10条
+(NSMutableArray *)getMessageListFromDBWithTopicEntityID:(NSString *)topicEntityID firstSeq:(long)firstSeq  limit:(int)nLimit
{
    __block NSMutableArray *messageList = [NSMutableArray arrayWithCapacity:10];
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        
        NSString *sql = nLimit?[NSString stringWithFormat:@"SELECT * FROM message "\
                         "WHERE topicEntityID='%@' and seq<%ld and seq>=%ld ORDER BY seq asc limit %d",
                                  topicEntityID,firstSeq+nLimit,firstSeq,nLimit]:[NSString stringWithFormat:@"SELECT * FROM message "\
                                                                       "WHERE topicEntityID='%@' and seq>=%ld ORDER BY seq asc",
                                                                       topicEntityID,firstSeq];
        FMResultSet *resultSet = [db executeQuery:sql];
        if (resultSet)
        {
            @autoreleasepool
            {
                while (resultSet.next)
                {
                    ACMessage *message = [ACMessage getMessageWithFMResultSet:resultSet];
                    [messageList addObject:message];
                }
            }
            [resultSet close];
        }
    }];
    return messageList;
}

//根据lastCreateTime获取noteMessageList
+(NSMutableArray *)getWallBoardMessageListFromDBWithLastCreateTime:(double)lastCreateTime limit:(int)limit
{
    if (lastCreateTime == 0)
    {
        lastCreateTime = MAXFLOAT;
    }
    __block NSMutableArray *messageList = [NSMutableArray arrayWithCapacity:10];
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM message "\
                         "WHERE createTime<%f and messageEnumType=%d ORDER BY createTime desc limit %d",
                         lastCreateTime,ACMessageEnumType_WallBoard,limit];
        FMResultSet *resultSet = [db executeQuery:sql];
        if (resultSet)
        {
            @autoreleasepool
            {
                while (resultSet.next)
                {
                    ACMessage *message = [ACMessage getMessageWithFMResultSet:resultSet];
                    [messageList addObject:message];
                    if (message == nil)
                    {
                        
                    }
//                    [messageList insertObject:message atIndex:0];
                }
            }
            [resultSet close];
        }
    }];
    return messageList;
}



//保存Image，Video 缓存
+(void)saveFileMessageCacheToDB:(ACFileMessageCache *)fileMessage WithTopicEntityID:(NSString *)topicEntityID{


    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {

        FMDatabase_Enable_Error_logs(db);

        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM file_msg_cache "\
                         "WHERE messageID='%@' ",
                        fileMessage.messageID];
        FMResultSet *resultSet = [db executeQuery:sql];

        //如果有此消息,略过
        if (resultSet.next) {
            [resultSet close];
            NSString *sql = [NSString stringWithFormat:@"UPDATE file_msg_cache SET "\
                             "seq = '%ld', "\
                             "length='%ld', "\
                             "resourceID='%@', "\
                             "thumbResourceID='%@' "\
                             "WHERE messageID='%@' ",
                             fileMessage.seq,
                             fileMessage.length,
                             fileMessage.resourceID,
                             fileMessage.thumbResourceID,
                             fileMessage.messageID];            //            ITLog(sql);
            [db executeUpdate:sql];
            return;
        }

        [db executeUpdateWithFormat:@"INSERT INTO file_msg_cache "\
                   "(messageID, topicEntityID, messageEnumType, seq,length, resourceID, thumbResourceID) "\
                   "VALUES (%@, %@, %d, %ld, %ld,%@, %@);",
                        fileMessage.messageID,
                        topicEntityID,
                        fileMessage.messageEnumType,
                        fileMessage.seq,
                        fileMessage.length,
                        fileMessage.resourceID,
                        fileMessage.thumbResourceID];

    }];
}

//
//+(void)deleteACFileMessageCacheFromDBWithTopicEntityID:(NSString *)topicEntityID{
//    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
//
//        FMDatabase_Enable_Error_logs(db);
//
//        NSString *sql = [NSString stringWithFormat:@"DELETE FROM file_msg_cache "\
//                         "WHERE topicEntityID='%@';",
//                        topicEntityID];
//        [db executeUpdate:sql];
//    }];
//}

//取得可显示的Cache
+(NSMutableArray*)getACFileMessageCacheFromDBWithTopicEntityID:(NSString *)topicEntityID  firstSeq:(long)firstSeq{

    __block NSMutableArray *messageList;
    messageList = [NSMutableArray arrayWithCapacity:100];
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {

        FMDatabase_Enable_Error_logs(db);

        
        NSString *sql = nil;
        if(firstSeq<0){
            sql = [NSString stringWithFormat:@"SELECT * FROM file_msg_cache "\
                         "WHERE topicEntityID='%@' ORDER BY seq asc;",topicEntityID];
        }
        else{
            sql = [NSString stringWithFormat:@"SELECT * FROM file_msg_cache "\
                   "WHERE topicEntityID='%@' AND seq>%ld ORDER BY seq asc;",topicEntityID,firstSeq];
        }
        FMResultSet *resultSet = [db executeQuery:sql];
        if (resultSet)
        {
            @autoreleasepool
            {
                while (resultSet.next)
                {
                    //检查文件是否存在
                    [messageList addObject:[ACFileMessageCache getFileMessageCacheWithFMResultSet:resultSet]];
                }
            }
            [resultSet close];
        }
        if(firstSeq>0){
            //清除不再需要的
            [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM file_msg_cache "\
                               "WHERE topicEntityID='%@' AND seq<=%ld;",
                               topicEntityID,firstSeq]];
        }
    }];
  
    
    return messageList;
}

@end
