//
//  ACNote.h
//  chat
//
//  Created by Aculearn on 14/12/17.
//  Copyright (c) 2014年 Aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "ACMessage.h"
#import "ACUser.h"

extern NSString *const ACNoteContent_TYPE_DESCRIPTION;
extern NSString *const ACNoteContent_TYPE_IMAGE;
extern NSString *const ACNoteContent_TYPE_VIDEO;
extern NSString *const ACNoteContent_TYPE_LOCATION;
extern NSString *const ACNoteContent_TYPE_LINK;


@interface ACNoteContentObject : NSObject
//    @property (nonatomic,strong) NSString   *contentID;
//    @property (nonatomic,strong) NSString   *contentType;   //ACNoteContent_TYPE_*

//    -(id)initWithDict:(NSDictionary*)pDict;
@end


/*
@interface ACNoteContentDescription : ACNoteContentObject
    @property (nonatomic,strong) NSString   *text;
//    -(id)initWithDict:(NSDictionary*)pDict;
@end
*/

@class ACNoteMessage;
@interface ACNoteContentImageOrVideo : ACNoteContentObject //图像
    @property (nonatomic)        BOOL       bIsImage;           //是图片
    @property (nonatomic,strong) NSString   *resourceID;    //"rid"
    @property (nonatomic,strong) NSString   *thumbResourceID;      //"trid"

//    @property (nonatomic,strong) NSString   *resourceLocalPath; //本地路径
//    @property (nonatomic,strong) NSString   *thumbLocalPath;

    @property (nonatomic)        long  length;
//    @property (nonatomic,strong) NSString   *sourceLocalPath; //资源文件的原始本地路径，仅用于内存
    @property (nonatomic)       NSInteger       height;//等比下的高度，cell中使用

    @property (nonatomic)        float       progress; //下载进度
    @property (nonatomic)         BOOL       video_downloading; //正在下载
//    @property (nonatomic)        NSInteger   video_duration;
    @property (nonatomic,strong) NSURL*     video_referenceURL; //video在相册簿中的url

    @property (nonatomic,readonly) enum ACFile_Type acFileType; //ac文件类型,ACFile_Type_WallboardPhoto:ACFile_Type_WallboardVideo

    @property (nonatomic,strong,readonly) NSString   *resourceFilePath;
    @property (nonatomic,strong,readonly) NSString   *thumbFilePath;
    @property (nonatomic,strong,readonly) NSString   *videoDownloadTempFilePath; //临时使用


    -(NSURL*)getResourceURLForThumb:(BOOL)bForThumb withNoteMessage:(ACNoteMessage*)noteMessage;
    -(NSString*)getResourceURLStringForThumb:(BOOL)bForThumb withNoteMessage:(ACNoteMessage*)noteMessage;

    -(instancetype)initForImage:(BOOL)bIsImage;
    -(instancetype)initWithDict:(NSDictionary*)pDict forImage:(BOOL)bIsImage;

@end


@interface ACNoteContentLocation : ACNoteContentObject //位置
    @property (nonatomic) CLLocationCoordinate2D        Location;//消息带经纬度
    @property (nonatomic,strong) NSString   *address;
    @property (nonatomic,strong) NSString   *name;
@end


@interface ACNoteContentWebsite : ACNoteContentObject //网站
    @property (nonatomic,strong) NSString   *linkIcon;
    @property (nonatomic,strong) NSString   *linkTitle;
    @property (nonatomic,strong) NSString   *linkURL; //实际地址
    @property (nonatomic,strong) NSString   *linkDesc; //描述
@end

//[[pNoteOrComment objectForKey:@"type"] intValue];
#define ACNoteObject_Type_Note      1   //数据类型是Note 
#define ACNoteObject_Type_Comment   10  //数据类型是Comment

@class ACTopicEntity;
@interface ACNoteObject : NSObject
    @property (nonatomic,strong) NSString   *id;     //本身的id
    @property (nonatomic,strong) NSString   *teid;  //ACTopicEntity.entityID
    @property (nonatomic,strong) ACUser*    creator;
    @property (nonatomic) long long         createTime; //为了保证32位和64为兼容,使用long long 格式化使用%lld
    @property (nonatomic) long long         updateTime;
    @property (nonatomic,strong) NSString   *content;   //文本内容
    @property (nonatomic,strong) NSString   *terminal;  //终端标示 ios android
    @property (nonatomic,readonly,getter=getIsNoteMessage) BOOL isNoteMessage; //是否是NoteMessage
    @property (nonatomic,readonly,getter=gettopicEntity) ACTopicEntity* topicEntity;


    @property (nonatomic) float     hightInList; //在列表中得高度

    -(instancetype)initWithDict:(NSDictionary*)pDict;
    +(instancetype)noteDataFromDict:(NSDictionary*)pDict; //通过Dict取得 ACNoteComment 或 ACNoteMessage
    +(NSInteger)addNoteDataFromDictArray:(NSArray*)pArray to:(NSMutableArray*)pToArray; //通过Dict的Array添加

@end



@interface ACNoteCommentBase : ACNoteObject //评论
    @property (nonatomic,strong)    NSString*   noteId;     //NoteID
    @property (nonatomic,strong,readonly) NSString* contentForCopy; //拷贝内容
//    @property (nonatomic,strong,getter=noteId, setter=setnoteId:) NSString*        noteId;
//暂时没有使用    @property (nonatomic,strong) NSArray*         referUsers;//ACUser
//    @property (nonatomic,strong) NSMutableArray*  referUids;//NSString 仅本地创建comment时使用

@end


@interface ACNoteCommentReply :ACNoteCommentBase //评论的回复
//    @property (nonatomic,strong)    NSString* pcid; //parent comment id
//    @property (nonatomic,strong)    NSString* pcuid; //parent comment user id
    @property (nonatomic,strong)    NSString* rcun; //reply comment user name


+(NSMutableArray<ACNoteCommentReply*>*) loadReplysWithDict:(NSDictionary*)pDict; //加载包含多个ACNoteCommentReply


@end

#define ACNoteCommentReply_LoadMore_MaxCount 5  //每次最多加载个数

@interface ACNoteComment :ACNoteCommentBase //评论
    @property (nonatomic,readonly) NSString* contentForNotify;
    @property (nonatomic) NSInteger loadedReplysTableViewHight; //回复的TableView高度
    @property (nonatomic) NSInteger commentReplyAllCount; //全部回复数
    @property (nonatomic,strong) NSMutableArray<ACNoteCommentReply*> *loadedCommentReplys; //加载的


-(NSDictionary *)getPostDictWithReply:(ACNoteCommentBase*)pReply; //取得发送的信息
-(void)sendCommentSuccessWithResponseDic:(NSDictionary*)responseDic;
-(void)sendReplySuccessWithResponseDic:(NSDictionary*)responseDic; //发送成功


-(void)moreRepliesLoaded:(NSArray*)array;
-(void)removeReply:(ACNoteCommentReply*)pRepy; //删除指定的回复


@end


#define kMultiCount     9

@class ASIFormDataRequest;
@interface ACNoteMessage : ACNoteObject //信息
    @property (nonatomic,strong) ACNoteContentLocation* location;
    @property (nonatomic,strong) ACNoteContentWebsite* link;
    @property (nonatomic,strong) NSMutableArray*    imageList; //ACNoteContentImageOrVideo
    @property (nonatomic,strong) NSMutableArray*    videoList; //ACNoteContentImageOrVideo
    @property (nonatomic,strong) NSMutableArray*    imgs_Videos_List;//ACNoteContentImageOrVideo 最多[kMultiCount]
//    @property (nonatomic,strong) NSMutableArray*    commentList; //ACNoteComment
    @property (nonatomic) NSInteger                 commentNum;   //评论数
    @property (nonatomic,strong,setter=setcategoryIDForWallBoard:) NSString*          categoryIDForWallBoard; //WallBoard的categoryID,nil表示不是WallBoard

    @property (nonatomic) float         progress;   //上传进度条

    -(void)updateMessageFromDict:(NSDictionary*)pDic;

    -(void)addImageOrVideo:(ACNoteContentImageOrVideo*)pContent;    //添加
    -(void)delImageOrVideo:(ACNoteContentImageOrVideo*)pContent;

    -(void)sendSuccessWithResponseDic:(NSDictionary*)responseDic forWallBoard:(BOOL)forWallBoard;   //上传成功

    -(void)setForASIFormDataRequest:(ASIFormDataRequest*)request;   //为上传数据准备request


    -(NSDictionary *)getNoteMessagePostDict; //发送的信息

@end


/*
@interface ACWallBoardMessage : ACNoteMessage
    @property (nonatomic,strong) NSString       *categoryID;
    @property (nonatomic,strong) ACMessage      *acMessageInfo;

    -(void) setContent:(NSDictionary *)content;
    -(NSDictionary *)getContentDicIsNeedHeight:(BOOL)isNeedHeight;
@end
*/

@interface ACWallBoard_Message : ACMessage   //它的内容其实就是ACNoteMessage的内容

//    @property (nonatomic,strong) NSString*      categoryID;
    @property (nonatomic,strong) ACNoteMessage  *messageContent;

    +(instancetype) createWallBoardMessageFormNoteMessage:(ACNoteMessage*)messageContent topicEnitity:(ACTopicEntity *)topicEntity;

    -(void) setContentFromDict:(NSDictionary *)content;
    -(NSDictionary *)getContentDicIsNeedHeight:(BOOL)isNeedHeight;

    -(void)sendSuccessWithResponseDic:(NSDictionary*)responseDic;
    -(void)setForASIFormDataRequest:(ASIFormDataRequest*)request;
@end



//@class ACTopicEntity;
//@interface ACNoteMessagesInTopicEntity : NSObject
//    @property (nonatomic,strong) NSMutableArray*    messageList; //ACNoteContentImage
//    @property (nonatomic,strong) ACTopicEntity*     topicEntity; //本消息的
//@end
