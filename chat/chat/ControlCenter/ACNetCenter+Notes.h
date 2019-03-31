//
//  ACNetCenter+Notes.h
//  chat
//
//  Created by Aculearn on 14/12/17.
//  Copyright (c) 2014年 Aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACNetCenter.h"
#import "ACNoteMessage.h"


//extern NSString * const kNetCenterNotes_Comment_LoadList_Notifition;
//extern NSString * const kNetCenterNotes_Comment_Upload_Notifition;
//extern NSString * const kNetCenterNotes_Comment_Delete_Notifition;
//extern NSString * const kNetCenterNotes_Comment_Upate_Notifition;


//extern NSString * const kNetCenterNotes_Note_LoadList_Notifition;
extern NSString * const kNetCenterNotes_Note_Upload_Success_Notifition; //成功
extern NSString * const kNetCenterNotes_Note_Upload_Fail_Notifition;    //失败
extern NSString * const kNetCenterNotes_Note_Upload_NoNetword_Notifition; //没有网络
//extern NSString * const kNetCenterNotes_Note_Update_Notifition;
//extern NSString * const kNetCenterNotes_Note_Delete_Notifition;

//extern NSString * const kNetCenterNotes_Note_GetWebLinkInfo_Notifition; //加载连接信息




@interface ACNetCenter (Notes_Additions)


//加载信息
//-(void) Notes_LoadNoteList_WithTopicEntityID:(NSString *)topicEntityID withStartTime:(NSInteger)startTime withEndTime:(NSInteger)endTime withLimit:(int)limit;

//加载Commment
//-(void) Notes_LoadCommentList:(ACNoteMessage*)pMsg withStartTime:(NSInteger)startTime withEndTime:(NSInteger)endTime withLimit:(int)limit;


//发送Wallboard
+(void)Notes_sendWallBoardMessage:(ACWallBoard_Message *)wallBoardMessage;

//发送notesMessage消息
+(void)Notes_sendNoteMessage:(ACNoteMessage*)pMsg  withTopicEntityID:(NSString *)topicEntityID;

//发送Note Comment
//+(void)Notes_sendNoteComment:(ACNoteComment*)pComment withNoteMessage:(ACNoteMessage*)pMsg;


//删除Note
+(void)Notes_DeleteNote:(ACNoteMessage*)pMsg;

//更新Note
+(void)Notes_UpdateNote:(ACNoteMessage*)pMsg;


@end
