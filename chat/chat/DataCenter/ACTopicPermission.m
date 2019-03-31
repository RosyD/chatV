//
//  ACTopicPermission.m
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-31.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACTopicPermission.h"

NSString *const ChatFeatures_Text =     @"txt";//没语音
NSString *const ChatFeatures_Image =    @"img";
NSString *const ChatFeatures_Video =    @"vid";
NSString *const ChatFeatures_Location = @"loc";
NSString *const ChatFeatures_Contact =  @"con";
NSString *const ChatFeatures_LocationAlert = @"lrt";
NSString *const ChatFeatures_Sticker =  @"sti";
NSString *const ChatFeatures_ReplyToLatestSender =  @"bre";

@interface ACTopicPermission(){
    int _delete;
    int _showParticipants;
    int _addAdmins;
    int _deleteParticipants;
    int _update;
}
@end

@implementation ACTopicPermission


-(BOOL)canDeleteSession{ //删除会话
    return ACPerm_Topic_Session_DELETE_DENNY!=_delete;
}

-(BOOL)needCheckLastAdmin{
    return ACPerm_Topic_Session_DELETE_TERMINATEGROUP==_delete;
}

-(BOOL) canUpdateInfo{      //允许修改Icon 标题 URL 等
    return ACPerm_Topic_Info_UPDATE_ALLOW==_update;
}

-(BOOL) canAddAdmins{       //是否可以修改管理员 Admin
    return ACPerm_Topic_ADDADMINS_ALLOW==_addAdmins;
}

-(BOOL) canAddParticipants{    //添加参与者
    return ACPerm_Topic_ADDPARTICIPANTS_ALLOW==_addParticipants;
}

-(BOOL) canDelParticipants{    //删除参与者
    return ACPerm_Topic_DELETEPARTICIPANTS_ALLOW==_deleteParticipants;
}

-(BOOL) canViewParticipants{    //查看参与者
    return ACPerm_Topic_SHOWPARTICIPANTS_ALLOW==_showParticipants;
}

#define kChat    @"chat"
#define kRe      @"re"
#define kSpbd    @"spbd"
#define kProf    @"prof"
#define kFunc    @"func"
#define kDmsg    @"dmsg"
#define kRloc    @"rloc"


- (id)initWithDicPerm:(NSDictionary *)dicPerm
{
    self = [super init];
    if (self) {
        [self setPermWithDicPerm:dicPerm];
    }
    return self;
}

#define ACTopicPermission_Get(__Field_Def__)   [ACUtility getValueWithName:__Field_Def__##_Field fromDict:dicPerm andDefault:__Field_Def__##_Default];


-(void)setPermWithDicPerm:(NSDictionary *)dicPerm
{
    _delete             =   ACTopicPermission_Get(ACPerm_Topic_Session_DELETE);
    _showParticipants   =   ACTopicPermission_Get(ACPerm_Topic_SHOWPARTICIPANTS);
    _addAdmins          =   ACTopicPermission_Get(ACPerm_Topic_ADDADMINS);
    _addParticipants    =   ACTopicPermission_Get(ACPerm_Topic_ADDPARTICIPANTS);
    _deleteParticipants =   ACTopicPermission_Get(ACPerm_Topic_DELETEPARTICIPANTS);
    _update             =   ACTopicPermission_Get(ACPerm_Topic_Info_UPDATE);
    
    self.chatInChat = [[dicPerm objectForKey:kChat] intValue];
    self.reply = [[dicPerm objectForKey:kRe] intValue];
    self.addToSpringboard = [[dicPerm objectForKey:kSpbd] intValue];
    self.profile = [[dicPerm objectForKey:kProf] intValue];
    self.destruct = [[dicPerm objectForKey:kDmsg] intValue];
    self.reportLocation = [[dicPerm objectForKey:kRloc] intValue];
    self.featureArray = [dicPerm objectForKey:kFunc];
    
    //public static final String FIELD_PERMISSION_NOTE = "nt"; //是否能看到Note， 决定客户端是否现实Note这个按钮
    //public static final String FIELD_PERMISSION_ADDNOTE = "ant"; //是否允许新建Note
    //public static final String FIELD_PERMISSION_UPDATENOTE = "unt"; //是否允许修改Note
    //public static final String FIELD_PERMISSION_DELETENOTE = "dnt"; //是否允许删除Note
    //public static final String FIELD_PERMISSION_DELETENOTECOMMENT = "dcmt"; //是否允许删除Note的Comment
    _note_allow      =   [ACUtility getValueWithName:@"nt" fromDict:dicPerm andDefault:ACNotePermission_NOTE_ALLOW];
    _note_add        =   [ACUtility getValueWithName:@"ant" fromDict:dicPerm andDefault:ACNotePermission_ADDNOTE_ALLOW];
    _note_update     =   [ACUtility getValueWithName:@"unt" fromDict:dicPerm andDefault:ACNotePermission_UPDATENOTE_OWN];
    _note_del        =   [ACUtility getValueWithName:@"dnt" fromDict:dicPerm andDefault:ACNotePermission_DELETENOTE_OWN];
    _note_delComment =   [ACUtility getValueWithName:@"dcmt" fromDict:dicPerm andDefault:ACNotePermission_DELETECOMMENT_OWN];
    _note_addComment = [ACUtility getValueWithName:@"admt" fromDict:dicPerm andDefault:ACNotePermission_ADDCOMMENT_EVERYONE];
}

+(id)topicPermissionWithDicPerm:(NSDictionary *)dicPerm
{
    __autoreleasing ACTopicPermission *topicPerm = [[ACTopicPermission alloc] initWithDicPerm:dicPerm];
    return topicPerm;
}

@end
