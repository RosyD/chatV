//
//  ACEntity.h
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-31.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACTopicPermission.h"
#import "ACUrlPermission.h"


enum EntityType
{
    EntityType_URL = 10,
    EntityType_Topic = 20
};

@interface ACBaseEntity : NSObject

@property (nonatomic,strong) NSString  *entityID;
@property (nonatomic) NSTimeInterval   updateTime;
@property (nonatomic) long             lastestSequence;
@property (nonatomic) int               entityType;
@property (nonatomic) BOOL              isToped; //是否置顶
@property (nonatomic) BOOL              isAdmin;
@property (nonatomic,strong) NSString   *mpType;//cSurvey
@property (nonatomic,strong) NSString   *permString;//权限字符串
@property (nonatomic,strong,readonly,getter=getShowTitle) NSString   *showTitle;
@property (nonatomic,strong,readonly)   NSString*  dictFieldName; //@"te":@"ue"
@property (nonatomic,strong,readonly)   NSString*  requestUrl;  //rest/apis/[chat,url]/{entityID}
@property (nonatomic,weak)  ACPermission*   perm;

- (id)initWithDic:(NSDictionary *)dic;

-(void) updateWithDict:(NSDictionary *)dic;

//-(NSDictionary *)getDic;

+(NSArray *)setEntityArrayWithDicArray:(NSArray *)dicArray;

+(NSArray *)getDicArrayWithEntityArray:(NSArray *)entityArray;

//取得标题并设置图标
-(NSString*)getShowTitleAndSetIcon:(UIImageView*)pIconImageView andCanEditForGroupInfoOption:(BOOL*)pCanEdit;

@end

#define kCategories     @"categories"
#define kCid            @"cid"

@interface ACCategory :NSObject

@property (nonatomic,strong) NSString   *name;
@property (nonatomic,strong) NSString   *cid;

@end

extern NSString *const cFreeChat;
extern NSString *const cSingleChat;
extern NSString *const cAdminChat;
extern NSString *const cEventChat;
extern NSString *const cLocationAlert;
extern NSString *const cWallboard;
extern NSString *const cSystemChat;

extern NSString * const kACTopicEntityTurnOffAlertsNotifation; 

@class FMResultSet;
@interface ACTopicEntity : ACBaseEntity

@property (nonatomic,strong) NSString   *title;//组名
@property (nonatomic,strong) NSString   *icon;//组icon
//@property (nonatomic,strong) NSString   *mpType;//cSingleChat
@property (nonatomic,strong) NSString   *url;//
@property (nonatomic) NSTimeInterval    createTime;//创建时间
@property (nonatomic,strong) ACTopicPermission *topicPerm;//权限

//(lastestSequence-currentSequence) 就是未读消息
@property (nonatomic) long              currentSequence;
@property (nonatomic,strong) NSString   *lastestTextMessage;
@property (nonatomic,strong) NSString   *lastestMessageType;
@property (nonatomic) NSTimeInterval    lastestMessageTime;
@property (nonatomic,strong) NSString   *lastestMessageUserID;
@property (nonatomic,strong) NSString   *singleChatUserID;//对方的userID
@property (nonatomic) BOOL              isTurnOffAlerts;
@property (nonatomic,strong) NSMutableArray    *categoriesArray;
@property (nonatomic,strong) NSString   *obj;
@property (nonatomic,strong) NSString   *createUserID;//创建者userID
@property (nonatomic) BOOL              isDeleted;
@property (nonatomic,strong) NSString   *relateTeID;//当前te关联的一对一会话ID
@property (nonatomic,strong) NSString   *relateType;//当前te关联的一对一会话类型 destruct或locaton
@property (nonatomic,strong) NSString   *relateChatUserID;//当前te关联的一对一会话对方的userID
@property (nonatomic,readonly) BOOL     isSigleChat;
@property (nonatomic) int     nSharingLocalUserCount; //正在分享位置用户数


- (id)initWithTopicDic:(NSDictionary *)topicDic;

//-(void)updateWithTopicDic:(NSDictionary *)topicDic;

//为option更新修改
-(void)updateEntityForOptionWithEventDic:(NSDictionary *)eventDic;


//创建topicEntity从数据库
+(ACTopicEntity *)getTopicEntityWithFMResultSet:(FMResultSet *)resultSet;

//保存是否静音并且发送给服务器
-(void)changeIsTurnOffAlertsAndSendToServer:(BOOL)isTurnOffAlerts withView:(UIView*)pView;

-(void)setSharingLocalUserCountAndSaveToDB:(int)nSharingLocalUserCount;

@end

extern NSString *const cSurvey;
extern NSString *const cEvent;
extern NSString *const cPage;
extern NSString *const cLink;

@interface ACUrlEntity : ACBaseEntity

@property (nonatomic,strong) NSString   *title;//组名
@property (nonatomic,strong) NSString   *icon;//组icon

@property (nonatomic,strong) NSString   *url;//
@property (nonatomic) NSTimeInterval    createTime;//创建时间
@property (nonatomic,strong) NSString   *createUserID;//创建者userID
@property (nonatomic,strong) ACUrlPermission *urlPerm;//权限

- (id)initWithUrlEventDic:(NSDictionary *)urlEventDic;

-(void)updateEntityWithEventDic:(NSDictionary *)eventDic;


//创建urlEntity从数据库
+(ACUrlEntity *)getUrlEntityWithFMResultSet:(FMResultSet *)resultSet;

@end
