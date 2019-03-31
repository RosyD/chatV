//
//  ACTopicPermission.h
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-31.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACPermission.h"


//是否可删除 Session
#define ACPerm_Topic_Session_DELETE_Field           @"del"
#define ACPerm_Topic_Session_DELETE_Default         ACPerm_Topic_Session_DELETE_CACHEONLY
#define ACPerm_Topic_Session_DELETE_DENNY           0
#define ACPerm_Topic_Session_DELETE_LEAVEGROUP      1   //假删除
#define ACPerm_Topic_Session_DELETE_CACHEONLY       2   //假删除
#define ACPerm_Topic_Session_DELETE_TERMINATEGROUP  3   //组删除
//#define ACPerm_Topic_Session_DELETE_CHECKADMIN      4   //需要检查是不是last admin

//展示参与者列表
#define ACPerm_Topic_SHOWPARTICIPANTS_Field     @"part"
#define ACPerm_Topic_SHOWPARTICIPANTS_Default   ACPerm_Topic_SHOWPARTICIPANTS_ALLOW
#define ACPerm_Topic_SHOWPARTICIPANTS_DENNY     0
#define ACPerm_Topic_SHOWPARTICIPANTS_ALLOW     1

//是否可以修改管理员 Admin
#define ACPerm_Topic_ADDADMINS_Field      @"adm"
#define ACPerm_Topic_ADDADMINS_Default    ACPerm_Topic_ADDADMINS_DENNY
#define ACPerm_Topic_ADDADMINS_DENNY      0
#define ACPerm_Topic_ADDADMINS_ALLOW      1

//显示添加参与者按钮
#define ACPerm_Topic_ADDPARTICIPANTS_Field      @"add"
#define ACPerm_Topic_ADDPARTICIPANTS_Default    ACPerm_Topic_ADDPARTICIPANTS_ALLOW
#define ACPerm_Topic_ADDPARTICIPANTS_DENY       0
#define ACPerm_Topic_ADDPARTICIPANTS_ALLOW      1
#define ACPerm_Topic_ADDPARTICIPANTS_TONEWGROUP 2

//删除参与者列表
#define ACPerm_Topic_DELETEPARTICIPANTS_Field   @"delp"
#define ACPerm_Topic_DELETEPARTICIPANTS_Default ACPerm_Topic_DELETEPARTICIPANTS_DENY
#define ACPerm_Topic_DELETEPARTICIPANTS_DENY    0
#define ACPerm_Topic_DELETEPARTICIPANTS_ALLOW   1


//允许修改Icon 标题 等
#define ACPerm_Topic_Info_UPDATE_Field    @"upd"
#define ACPerm_Topic_Info_UPDATE_Default  ACPerm_Topic_Info_UPDATE_DENY
#define ACPerm_Topic_Info_UPDATE_DENY     0
#define ACPerm_Topic_Info_UPDATE_ALLOW    1


enum ACTopicPermission_ChatInChat//群聊中进入单聊允许
{
    ACTopicPermission_ChatInChat_Deny = 0,
    ACTopicPermission_ChatInChat_Allow = 1,
};

enum ACTopicPermission_Reply//是否显示输入框
{
    ACTopicPermission_Reply_Deny = 0,
    ACTopicPermission_Reply_Allow = 1,
    ACTopicPermission_Reply_ToAdmins = 2,//
};

enum ACTopicPermission_AddToSpringboard//添加到收藏夹--暂时不加
{
    ACTopicPermission_AddToSpringboard_Deny = 0,
    ACTopicPermission_AddToSpringboard_Allow = 1,
    ACTopicPermission_AddToSpringboard_Force = 2,//强制添加到收藏夹
};

enum ACTopicPermission_ParticipantProfile//参与者简介
{
    ACTopicPermission_ParticipantProfile_Deny = 0,
    ACTopicPermission_ParticipantProfile_Allow = 1,
};

enum ACTopicPermission_DestructMessage//阅读后删除消息
{
    ACTopicPermission_DestructMessage_Deny = 0,
    ACTopicPermission_DestructMessage_Allow = 1,
};

enum ACTopicPermission_ReportLocation//报告经纬度
{
    ACTopicPermission_ReportLocation_Deny = 0,
    ACTopicPermission_ReportLocation_Allow = 1,
};


//public static final String FIELD_PERMISSION_NOTE = "nt"; //是否能看到Note， 决定客户端是否现实Note这个按钮
enum ACNotePermission_NOTE
{
    ACNotePermission_NOTE_NENY = 0,
    ACNotePermission_NOTE_ALLOW = 1, //默认是允许看Note
};

//public static final String FIELD_PERMISSION_ADDNOTE = "ant"; //是否允许新建Note

enum ACNotePermission_ADDNOTE
{
    ACNotePermission_ADDNOTE_NENY = 0,
    ACNotePermission_ADDNOTE_ALLOW = 1, //默认允许新建Note
};

//public static final String FIELD_PERMISSION_UPDATENOTE = "unt"; //是否允许修改Note
enum ACNotePermission_UPDATENOTE    //是否允许修改Note
{
    ACNotePermission_UPDATENOTE_NONE = 0,   //不允许修改Note
    ACNotePermission_UPDATENOTE_OWN = 1,    //默认允许修改自己发送的Note
    ACNotePermission_UPDATENOTE_EVERYONE = 2,   //允许修改所有人的Note
};


//public static final String FIELD_PERMISSION_DELETENOTE = "dnt"; //是否允许删除Note

enum ACNotePermission_DELETENOTE{
    ACNotePermission_DELETENOTE_NONE = 0, //不允许删除Note
    ACNotePermission_DELETENOTE_OWN = 1,    //默认允许删除自己的Note
    ACNotePermission_DELETENOTE_EVERYONE = 2, //允许删除所有人的Note
};


//public static final String FIELD_PERMISSION_DELETENOTECOMMENT = "dcmt"; //是否允许删除Note的Comment
enum ACNotePermission_ADDCOMMENT{
    ACNotePermission_ADDCOMMENT_NONE = 0, //不允许删除任何Comment
    ACNotePermission_ADDCOMMENT_OWN = 1, //默认允许删除自己发送的Comment
    ACNotePermission_ADDCOMMENT_EVERYONE = 2, //允许删除所有人发送的Comment
};


//public static final String FIELD_PERMISSION_DELETENOTECOMMENT = "dcmt"; //是否允许删除Note的Comment
enum ACNotePermission_DELETECOMMENT{
    ACNotePermission_DELETECOMMENT_NONE = 0, //不允许删除任何Comment
    ACNotePermission_DELETECOMMENT_OWN = 1, //默认允许删除自己发送的Comment
    ACNotePermission_DELETECOMMENT_EVERYONE = 2, //允许删除所有人发送的Comment
};





extern NSString *const ChatFeatures_Text;//没语音
extern NSString *const ChatFeatures_Image;
extern NSString *const ChatFeatures_Video;
extern NSString *const ChatFeatures_Location;
extern NSString *const ChatFeatures_Contact;
extern NSString *const ChatFeatures_LocationAlert;
extern NSString *const ChatFeatures_Sticker;
extern NSString *const ChatFeatures_ReplyToLatestSender;

@interface ACTopicPermission : ACPermission

@property (nonatomic) int               addParticipants; //添加参与者

@property (nonatomic) int               chatInChat;//chat群聊中进入单聊允许
@property (nonatomic) int               reply;//re是否显示输入框
@property (nonatomic) int               addToSpringboard;//spbd暂时不加
@property (nonatomic) int               profile;//prof参与者简介
@property (nonatomic) int               destruct;//dmsg阅读后删除消息
@property (nonatomic) int               reportLocation;//rloc报告经纬度
@property (nonatomic,strong) NSArray    *featureArray;//func


@property (nonatomic) enum ACNotePermission_NOTE            note_allow;
@property (nonatomic) enum ACNotePermission_ADDNOTE         note_add;
@property (nonatomic) enum ACNotePermission_UPDATENOTE      note_update;
@property (nonatomic) enum ACNotePermission_DELETENOTE      note_del;
@property (nonatomic) enum ACNotePermission_ADDCOMMENT      note_addComment;
@property (nonatomic) enum ACNotePermission_DELETECOMMENT   note_delComment;



- (id)initWithDicPerm:(NSDictionary *)dicPerm;//用权限字典创建权限对象

-(void)setPermWithDicPerm:(NSDictionary *)dicPerm;

+(id)topicPermissionWithDicPerm:(NSDictionary *)dicPerm;

@end
