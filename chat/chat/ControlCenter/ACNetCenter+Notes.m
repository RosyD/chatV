//
//  ACNetCenter+Notes.m
//  chat
//
//  Created by Aculearn on 14/12/17.
//  Copyright (c) 2014年 Aculearn. All rights reserved.
//

#import "ACNetCenter+Notes.h"
#import "ACAddress.h"
#import "JSONKit.h"


//NSString * const kNetCenterNotes_Note_LoadList_Notifition = @"加载Note列表";
NSString * const kNetCenterNotes_Note_Upload_Success_Notifition = @"上传Note成功"; //成功
NSString * const kNetCenterNotes_Note_Upload_Fail_Notifition = @"上传Note失败";    //失败
NSString * const kNetCenterNotes_Note_Upload_NoNetword_Notifition = @"上传Note无网络"; //没有网络
//NSString * const kNetCenterNotes_Note_Update_Notifition = @"更新Note文本";
//NSString * const kNetCenterNotes_Note_Delete_Notifition = @"删除Note";


//NSString * const kNetCenterNotes_Comment_LoadList_Notifition = @"加载Comment列表";
//NSString * const kNetCenterNotes_Comment_Upload_Notifition = @"上传Comment";
//NSString * const kNetCenterNotes_Comment_Delete_Notifition = @"删除Comment";
//NSString * const kNetCenterNotes_Comment_Upate_Notifition = @"更新Comment";



//NSString * const kNetCenterNotes_Note_GetWebLinkInfo_Notifition = @"取得URL信息"; //加载连接信息

/*


NSString * const kNetCenterSendNoteSuccNotifation = @"kNetCenterSendNoteSuccNotifation";
NSString * const kNetCenterSendNoteFailNotifation = @"kNetCenterSendNoteFailNotifation";
NSString * const kNetCenterSendNoteNotNetwordNotifation = @"kNetCenterSendNoteNotNetwordNotifation";


NSString * const kNetCenterNotes_LoadNoteList_Notifition = @"kNetCenterNotes_LoadNoteList_Notifition";
NSString * const kNetCenterNotes_LoadNote_Notifition = @"kNetCenterNotes_LoadNote_Notifition";
NSString * const kNetCenterNotes_LoadCommentList_Notifition = @"kNetCenterNotes_LoadCommentList_Notifition";
NSString * const kNetCenterNotes_LoadResource_Notifition = @"kNetCenterNotes_LoadResource_Notifition";
NSString * const kNetCenterNotes_Loadwebsite_Notifition = @"kNetCenterNotes_Loadwebsite_Notifition";

NSString * const kNetCenterNotes_UpdateNoteContent_Notifition = @"kNetCenterNotes_UpdateNoteContent_Notifition";
NSString * const kNetCenterNotes_DeleteNote_Notifition = @"kNetCenterNotes_DeleteNote_Notifition";
NSString * const kNetCenterNotes_DeleteComment_Notifition = @"kNetCenterNotes_DeleteComment_Notifition";

NSString * const kNetCenterNotes_UploadNote_Notifition = @"kNetCenterNotes_UploadNote_Notifition";
NSString * const kNetCenterNotes_UploadComment_Notifition = @"kNetCenterNotes_UploadComment_Notifition";*/


@implementation ACNetCenter (Notes_Additions)



+(void)Notes_sendNoteMessage:(ACNoteMessage*)pMsg withTopicEntityID:(NSString *)topicEntityID{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
 
        
        NSString * const acSendNoteMessageUrl = [NSString stringWithFormat:@"%@/rest/apis/note/%@/upload",[[ACNetCenter shareNetCenter] acucomServer],topicEntityID];
        
//  http://192.168.2.158:8070/rest/apis/note/14f56f540a010d7effa122fc94a23ab6/upload
        
        NSDictionary *postDic = [pMsg getNoteMessagePostDict];
        ITLog(([postDic JSONString]));
        //        noteMessage.content = [postDic JSONString];
//        wallBoardMessage.messageUploadState = ACMessageUploadState_Uploading;
        //        [ACMessageDB saveMessageToDBWithMessage:noteMessage];
        
        
        [[ACNetCenter shareNetCenter] startDownloadWithFileName:nil fileType:ACFile_Type_SendNoteOrWallboard urlString:acSendNoteMessageUrl saveAddress:nil tempAddress:nil progressDelegate:pMsg postDictionary:postDic postPathArray:nil object:pMsg requestMethod:requestMethodType_Post];
    });
}



//加载Commment
-(void) Notes_LoadCommentList:(ACNoteMessage*)pMsg withStartTime:(NSInteger)startTime withEndTime:(NSInteger)endTime withLimit:(int)limit{
    /*
     获取Comment列表接口， 返回的Comment数据按时间倒叙排列， startTime是更大的时间， endTime是更小的时间， (time < startTime && time > endTime)， 这两个时间可以为空， limit是返回Note的数量限制。
     /rest/apis/note/{noteTopicId}/comments?s={startTime}&e={endTime}&l={limit}
     GET
     Response
     {
     "comments" : [
     {
     "type" : 10, // 1是Note， 10是Comment
     "pid" : "是Comment， pid是NoteId",
     "desp" : "文字内容",
     "terminal" : "android",
     "user" : {user json object}
     }
     ]
     }*/
    
//    NSString* pStartTime =  startTime?[@(startTime) stringValue]:@"";
//    NSString* pEndTime =  endTime?[@(endTime) stringValue]:@"";
//    
//    NSString * const urlString =    [acuCom_Server stringByAppendingFormat:@"/rest/apis/note/%@/comments?s=%@&e=%@&l=%d",pMsg.id,pStartTime,pEndTime,limit];
//    
//    [self startDownloadWithFileName:nil fileType:ACFile_Type_NoteComment_List_Json urlString:urlString saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Get];
    
}


//+(void)Notes_sendNoteComment:(ACNoteComment*)pComment withNoteMessage:(ACNoteMessage*)pMsg{
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        
//        NSString * const acSendCommentUrl = [NSString stringWithFormat:@"%@/rest/apis/note/%@/comment/upload",acuCom_Server,pMsg.id];
//
//        //"/rest/apis/note/" + noteId + "/comment/upload";
//        
//        NSDictionary *postDic = [pComment getNoteCommentPostDict];
//        
//        [[ACNetCenter shareNetCenter] startDownloadWithFileName:nil fileType:ACFile_Type_Note_SendComment urlString:acSendCommentUrl saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:postDic postPathArray:nil object:pComment requestMethod:requestMethodType_Post];
//    });
//}




//删除Note
+(void)Notes_DeleteNote:(ACNoteMessage*)pMsg{
    /*
     URI: rest/apis/note/{noteTopicId}
     Method: DELETE
     Path variables:
     */
    [ACNetCenter callURL:[NSString stringWithFormat:@"%@/rest/apis/note/%@",[[ACNetCenter shareNetCenter] acucomServer],pMsg.id]
         forMethodDelete:YES
               withBlock:nil];
}

+(void)Notes_UpdateNote:(ACNoteMessage*)pMsg{
    /*
URI: rest/apis/note/{noteTopicId}
Method: PUT
    Path variables:
    
noteTopicId: note的ID
    
Request:
    
    {
        "desp" : "update content",
    }
Response:
    
    {
        "code" : 1
    }*/
    [ACNetCenter callURL:[NSString stringWithFormat:@"%@/rest/apis/note/%@",[[ACNetCenter shareNetCenter] acucomServer],pMsg.id]
                 forPut:YES
            withPostData:[NSDictionary dictionaryWithObjectsAndKeys:pMsg.content,@"desp", nil]
               withBlock:nil];
}


//发送notesMessage消息
+(void)Notes_sendWallBoardMessage:(ACWallBoard_Message *)wallBoardMessage
{
//    ITLog(@"");
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSString * const acSendWallBoardMessageUrl = [NSString stringWithFormat:@"%@/rest/apis/wallboardtopic",[[ACNetCenter shareNetCenter] acucomServer]];
        
        /*WB
         ACNoteMessage* pTempNoteMsg =   wallBoardMessage.messageContent;
         
         NSMutableArray *postPathArray = [NSMutableArray arrayWithCapacity:[pTempNoteMsg.imgOrVideoList count]];
         for (int i = 0; i < [pTempNoteMsg.imgOrVideoList count]; i++)
         {
         ACNoteContentImageOrVideo *page = [pTempNoteMsg.imgOrVideoList objectAtIndex:i];
         NSString *filePath = [ACAddress getAddressWithFileName:page.resourceID fileType:page.acFileType isTemp:NO subDirName:nil];
         
         NSString *thumbPath = [ACAddress getAddressWithFileName:page.thumbResourceID fileType:page.acFileType isTemp:NO subDirName:nil];
         NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:filePath,kSrc,thumbPath,kThumb, nil];
         [postPathArray addObject:dic];
         }
         */
        
        NSDictionary *postDic = [wallBoardMessage getContentDicIsNeedHeight:NO];
        ITLog(([postDic JSONString]));
        //        noteMessage.content = [postDic JSONString];
        wallBoardMessage.messageUploadState = ACMessageUploadState_Uploading;
        //        [ACMessageDB saveMessageToDBWithMessage:noteMessage];
        
        
        //ACFile_Type_SendNote
        
        [[ACNetCenter shareNetCenter] startDownloadWithFileName:nil fileType:ACFile_Type_SendNoteOrWallboard urlString:acSendWallBoardMessageUrl saveAddress:nil tempAddress:nil progressDelegate:wallBoardMessage.messageContent postDictionary:postDic postPathArray:nil object:wallBoardMessage requestMethod:requestMethodType_Post];
    });
}



@end
