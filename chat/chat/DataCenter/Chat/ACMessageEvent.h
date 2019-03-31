//
//  ACMessageEvent.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-11.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>


#define JHNotification_UserInfo_topicID @"chat_topic"
#define JHNotification_UserInfo_noteID @"note_id"

extern NSString *const kMessageAddNotification;
@class ACMessage;
@class ACTopicEntity;
@interface ACMessageEvent : NSObject

//添加message
+(void)messageAddWithDic:(NSDictionary *)dic;

+(void)updateTopicEntity:(ACTopicEntity *)entity LastInfoWithMessage:(ACMessage *)message hadRead:(BOOL)hadRead;

+(NSString *)getLasestTextMessageWithMessageType:(int)type
                                         content:(NSString *)content
                                          userID:(NSString *)userID
                                        userName:(NSString *)userName
                                       topicType:(NSString *)mpType
                               TopicDestructType:(int)destructType;


//getMessageList后更新未读数和阅后即焚lastMessage
//+(ACTopicEntity*)updateTopicEntityHadReadWithMessage:(ACMessage *)message;

@end
