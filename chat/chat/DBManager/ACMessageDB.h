//
//  ACMessageDB.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-28.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ACMessage;
@class ACFileMessage;
@class ACFileMessageCache;

@interface ACMessageDB : NSObject

+(BOOL)createTable:(NSInteger)nDB_Ver;

+(void)dropTable;

+(BOOL)saveMessageToDBWithMessage:(ACMessage *)message;//先select，有update，没有insert

//得到未发送的消息列表
+(NSMutableArray *)getUnSendMessageListWithTopicEntityID:(NSString *)topicEntityID;

//发送message成功后更新messageID
+(BOOL)updateMessageIDWithSourceMessageID:(NSString *)sourceMsgID targetMsgID:(NSString *)targetMsgID;

//删除topicEntity对应删除message
+(BOOL)deleteMessageFromDBWithTopicEntityID:(NSString *)topicEntityID;

//根据topicEntityID获取messageList,lastSeq往上取10条
//+(NSMutableArray *)getMessageListFromDBWithTopicEntityID:(NSString *)topicEntityID lastSeq:(long)lastSeq;
+(NSMutableArray *)getMessageListFromDBWithTopicEntityID:(NSString *)topicEntityID lastSeq:(long)lastSeq withLimit:(int)nLimit;

//根据topicEntityID获取seqs
+(NSMutableArray *)getMessageSeqsFromDBWithTopicEntityID:(NSString *)topicEntityID fromSeq:(long)seq;

//根据topicEntityID获取messageList,firstSeq往下取10条
+(NSMutableArray *)getMessageListFromDBWithTopicEntityID:(NSString *)topicEntityID firstSeq:(long)firstSeq limit:(int)nLimit;


//根据lastCreateTime获取noteMessageList
+(NSMutableArray *)getWallBoardMessageListFromDBWithLastCreateTime:(double)lastCreateTime limit:(int)limit;

//删除messageid对应的message
+(BOOL)deleteMessageFromDBWithMessageID:(NSString *)messageID;


//保存Image，Video 缓存
+(void)saveFileMessageCacheToDB:(ACFileMessageCache *)fileMessage WithTopicEntityID:(NSString *)topicEntityID;
//删除
//+(void)deleteACFileMessageCacheFromDBWithTopicEntityID:(NSString *)topicEntityID;
//取得可显示的Cache,firstSeq>=0表示是阅后即焚消息
+(NSMutableArray*)getACFileMessageCacheFromDBWithTopicEntityID:(NSString *)topicEntityID firstSeq:(long)firstSeq;

@end
