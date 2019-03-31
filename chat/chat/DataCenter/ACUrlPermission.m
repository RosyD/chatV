//
//  ACUrlPermission.m
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-31.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACUrlPermission.h"
#import "ACEntity.h"
#import "ACDataCenter.h"

@interface ACUrlPermission(){
    int     _delete;
    int     _update;
    int     _addAdmins;
    int     _editParticipants;
    int     _viewParticipants;
}
@end

@implementation ACUrlPermission


-(BOOL)canDeleteSession{ //删除会话
    return ACPerm_URL_Session_DELETE_DENNY!=_delete;
}

-(BOOL)needCheckLastAdmin{
    return ACPerm_URL_Session_DELETE_TERMINATE==_delete;
}

-(BOOL) canUpdateInfo{      //允许修改Icon 标题 URL 等
    return ACPerm_URL_Info_UPDATE_ALLOW==_update;
}
-(BOOL) canAddAdmins{       //是否可以修改管理员 Admin
    return ACPerm_URL_ADDADMINS_ALLOW==_addAdmins;
}
-(BOOL) canAddParticipants{    //添加参与者
    return ACPerm_URL_EDITPARTICIPANTS_ALLOW==_editParticipants;
}
-(BOOL) canDelParticipants{    //删除参与者
    return ACPerm_URL_EDITPARTICIPANTS_ALLOW==_editParticipants;
}


-(BOOL) canViewParticipants{    //查看参与者
    return ACPerm_URL_VIEWPARTICIPANTS_ALLOW==_viewParticipants;
}

#define ACUrlPermission_Get(__Field_Def__)   [ACUtility getValueWithName:__Field_Def__##_Field fromDict:dicPerm andDefault:__Field_Def__##_Default];

- (id)initWithDicPerm:(NSDictionary *)dicPerm withEntityID:(NSString *)entityID
{
    self = [super init];
    if (self) {
        [self setPermWithDicPerm:dicPerm withEntityID:entityID];
    }
    return self;
}


-(void)setPermWithDicPerm:(NSDictionary *)dicPerm withEntityID:(NSString *)entityID
{
    _delete             = ACUrlPermission_Get(ACPerm_URL_Session_DELETE);
    _update             = ACUrlPermission_Get(ACPerm_URL_Info_UPDATE);
    _viewSurveyReport   = ACUrlPermission_Get(ACPerm_URL_VIEWSURVEYREPORT);
    _addAdmins          = ACUrlPermission_Get(ACPerm_URL_ADDADMINS);
    _editParticipants   = ACUrlPermission_Get(ACPerm_URL_EDITPARTICIPANTS);
    _viewParticipants   = ACUrlPermission_Get(ACPerm_URL_VIEWPARTICIPANTS);
    
    /*
    for (ACTopicEntity *entity in [ACDataCenter shareDataCenter].topicEntityArray)
    {
        if ([entity.entityID isEqualToString:entityID])
        {
            self.addToSpringboard = (enum ACUrlPermission_AddToSpringboard)entity.perm.addToSpringboard;
            break;
        }
    }*/
}

+(id)urlPermissionWithDicPerm:(NSDictionary *)dicPerm withEntityID:(NSString *)entityID
{
    __autoreleasing ACUrlPermission *topicPerm = [[ACUrlPermission alloc] initWithDicPerm:dicPerm withEntityID:entityID];
    return topicPerm;
}

@end
