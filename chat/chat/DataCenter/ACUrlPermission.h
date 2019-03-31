//
//  ACUrlPermission.h
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-31.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACPermission.h"


//删除会话
#define ACPerm_URL_Session_DELETE_Field @"del"
#define ACPerm_URL_Session_DELETE_Default       ACPerm_URL_Session_DELETE_ALLOW
#define ACPerm_URL_Session_DELETE_DENNY         0
#define ACPerm_URL_Session_DELETE_ALLOW         1
#define ACPerm_URL_Session_DELETE_TERMINATE     3
//#define ACPerm_URL_Session_DELETE_CHECKADMIN      4   //需要检查是不是last admin

//允许修改Icon 标题 URL 等
#define ACPerm_URL_Info_UPDATE_Field    @"upd"
#define ACPerm_URL_Info_UPDATE_Default  ACPerm_URL_Info_UPDATE_DENY
#define ACPerm_URL_Info_UPDATE_DENY     0
#define ACPerm_URL_Info_UPDATE_ALLOW    1

//urlEntity 调查报告
#define ACPerm_URL_VIEWSURVEYREPORT_Field   @"svy"
#define ACPerm_URL_VIEWSURVEYREPORT_Default ACPerm_URL_VIEWSURVEYREPORT_DENY
#define ACPerm_URL_VIEWSURVEYREPORT_DENY    0
#define ACPerm_URL_VIEWSURVEYREPORT_ALLOW   1

/*
 preview的意思是只能看，不能做join和submit的操作；
 availble是不光可以看，还能join或submit;
 surveyreport的意思是打开survey,是不是直接显示report页面
 */
//暂不使用 private Integer view = VIEW_AVAILABLE;
//public static final int VIEW_PREVIEW = 0;
//public static final int VIEW_AVAILABLE = 1;
//public static final int VIEW_SURVEYREPORT = 2;

//是否可以修改管理员 Admin
#define ACPerm_URL_ADDADMINS_Field      @"adm"
#define ACPerm_URL_ADDADMINS_Default    ACPerm_URL_ADDADMINS_DENNY
#define ACPerm_URL_ADDADMINS_DENNY      0
#define ACPerm_URL_ADDADMINS_ALLOW      1

//private int editParticipants = EDITPARTICIPANTS_DENNY;
//允许编辑参与者
#define ACPerm_URL_EDITPARTICIPANTS_Field  @"par"
#define ACPerm_URL_EDITPARTICIPANTS_Default ACPerm_URL_EDITPARTICIPANTS_DENNY
#define ACPerm_URL_EDITPARTICIPANTS_DENNY  0
#define ACPerm_URL_EDITPARTICIPANTS_ALLOW  1

//private int viewParticipants = VIEWPARTICIPANTS_ALLOW;
//查看参与者
#define ACPerm_URL_VIEWPARTICIPANTS_Field  @"vpar"
#define ACPerm_URL_VIEWPARTICIPANTS_Default ACPerm_URL_VIEWPARTICIPANTS_ALLOW
#define ACPerm_URL_VIEWPARTICIPANTS_DENNY  0
#define ACPerm_URL_VIEWPARTICIPANTS_ALLOW  1



@interface ACUrlPermission : ACPermission

@property   (nonatomic) int     viewSurveyReport;

- (id)initWithDicPerm:(NSDictionary *)dicPerm withEntityID:(NSString *)entityID;//用权限字典创建权限对象

-(void)setPermWithDicPerm:(NSDictionary *)dicPerm withEntityID:(NSString *)entityID;

+(id)urlPermissionWithDicPerm:(NSDictionary *)dicPerm withEntityID:(NSString *)entityID;

@end
