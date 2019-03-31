//
//  ACEntity.m
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-31.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACEntity.h"
#import "ACUrlPermission.h"
#import "ACNetCenter.h"
#import "ACUser.h"
#import "ACUserDB.h"
#import "ACMessageEvent.h"
#import "ACMessage.h"
#import "FMResultSet.h"
#import "JSONKit.h"
#import "ACDataCenter.h"
#import "ACConfigs.h"
#import "UIImageView+WebCache.h"
#import "ACTopicEntityDB.h"


@implementation ACBaseEntity
@synthesize permString = _permString;
@synthesize mpType = _mpType;

#define eid     @"eid"
#define utime   @"utime"
#define seq     @"seq"
#define type    @"type"
#define kCseq   @"cseq"

- (id)initWithDic:(NSDictionary *)dic
{
    self = [super init];
    if (self) {
        self.entityID = [dic objectForKey:eid];
        self.entityType = [[dic objectForKey:type] intValue];
        [self updateWithDict:dic];
    }
    return self;
}

-(void) updateWithDict:(NSDictionary *)dic{
    self.updateTime = [[dic objectForKey:utime] doubleValue];
    self.lastestSequence = [[dic objectForKey:seq] longValue];
}

-(NSDictionary *)getDic{
    NSAssert(NO,@"getDic");
    return nil;
}
//{
//    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:_entityID,eid,[NSNumber numberWithDouble:_updateTime],utime,[NSNumber numberWithInt:_entityType],type, nil];
//    if (_entityType == EntityType_Topic)
//    {
//        [dic setObject:[NSNumber numberWithLong:_lastestSequence] forKey:seq];
//        [dic setObject:[NSNumber numberWithLong:((ACTopicEntity *)self).currentSequence] forKey:kCseq];
//    }
//    return dic;
//}

#pragma mark -get方法
-(NSString *)entityID
{
    return _entityID?_entityID:@"";
}

-(NSString *)permString
{
    return _permString?_permString:@"";
}

-(NSString *)mpType
{
    return _mpType?_mpType:@"";
}

-(void)setMpType:(NSString *)mpType
{
    if ([mpType isKindOfClass:[NSString class]] && _mpType != mpType)
    {
        _mpType = mpType;
    }
}

-(void)setPermString:(NSString *)permString
{
//    if (_permString != permString)
    if(![permString isEqualToString:_permString]){ //发生变化
        _permString = permString;
        if ([self isKindOfClass:[ACTopicEntity class]])
        {
            self.perm = ((ACTopicEntity *)self).topicPerm = [ACTopicPermission topicPermissionWithDicPerm:[_permString objectFromJSONString]];
        }
        else if ([self isKindOfClass:[ACUrlEntity class]])
        {
            self.perm = ((ACUrlEntity *)self).urlPerm = [ACUrlPermission urlPermissionWithDicPerm:[_permString objectFromJSONString] withEntityID:self.entityID];
        }
    }
}



+(NSArray *)setEntityArrayWithDicArray:(NSArray *)dicArray
{
    NSMutableArray *entityArray = [NSMutableArray arrayWithCapacity:[dicArray count]];
    for (NSDictionary *dic in dicArray)
    {
        ACBaseEntity *entity = [[ACBaseEntity alloc] initWithDic:dic];
        [entityArray addObject:entity];
    }
    return entityArray;
}

+(NSArray *)getDicArrayWithEntityArray:(NSArray *)entityArray
{
    NSMutableArray *dicArray = [NSMutableArray arrayWithCapacity:[entityArray count]];
    for (ACBaseEntity *entity in entityArray)
    {
        NSMutableDictionary *dicTemp = [NSMutableDictionary dictionaryWithObjectsAndKeys:entity.entityID,eid,[NSNumber numberWithDouble:entity.updateTime],utime,[NSNumber numberWithInt:entity.entityType],type, nil];
        if (entity.entityType == EntityType_Topic)
        {
            [dicTemp setObject:[NSNumber numberWithLong:entity.lastestSequence] forKey:seq];
            [dicTemp setObject:[NSNumber numberWithLong:((ACTopicEntity *)entity).currentSequence] forKey:kCseq];
        }
        [dicArray addObject:dicTemp];
    }
    return dicArray;
}

@end

@implementation ACCategory

@end

NSString *const cFreeChat =     @"freechat";
NSString *const cSingleChat =   @"singlechat";
NSString *const cAdminChat =    @"adminchat";
NSString *const cEventChat =    @"event";
NSString *const cLocationAlert = @"locationalert";
NSString *const cWallboard =    @"robotpost.wallboard";
NSString *const cSystemChat = @"systemchat";

#define kId           @"id"
#define kTitle        @"title"
#define kCreateTime   @"createTime"
#define kIcon         @"icon"
#define kType         @"type"
#define kUpdateTime   @"updateTime"
#define kUrl          @"url"
#define kPerm         @"perm"
#define kEventGroupID     @"eventGroupId"
#define kObj          @"obj"
#define kParticipants     @"participants"
#define kRelateType     @"rtype"
#define kRelateTe     @"relate"
#define kSharelocation @"shareLocation"

#define kTe         @"te"
#define kLastestSeq @"latestSeq"
#define kAdmin      @"admin"
#define kMsg        @"msg"
#define kMsgType    @"msgType"
#define kMsgtype    @"msgtype"
#define kMsgTime    @"msgTime"
#define kMsgUser    @"msgUser"
#define kCurrentSeq @"currentSeq"
#define kCreator    @"creator"

@implementation ACTopicEntity
@synthesize obj = _obj;
@synthesize title = _title;
@synthesize icon = _icon;
@synthesize url = _url;
@synthesize lastestTextMessage = _lastestTextMessage;
@synthesize lastestMessageType = _lastestMessageType;
@synthesize lastestMessageUserID = _lastestMessageUserID;
@synthesize singleChatUserID = _singleChatUserID;
@synthesize relateTeID = _relateTeID;
@synthesize relateType = _relateType;
@synthesize relateChatUserID = _relateChatUserID;


- (id)initWithTopicDic:(NSDictionary *)topicDic
{
    self = [super init];
    if (self) {
        [self updateWithTopicDic:topicDic];
    }
    return self;
}

-(void)updateWithTopicDic:(NSDictionary *)topicDic{

    NSDictionary *teDic = [topicDic objectForKey:kTe];
    if (teDic == nil){ //用于search时组合topicEntity
        teDic = topicDic;
    }
    self.entityID = [teDic objectForKey:kId];
    self.title = [teDic objectForKey:kTitle];
    self.icon = [teDic objectForKey:kIcon];
    self.mpType = [teDic objectForKey:kType];
    self.url = [teDic objectForKey:kUrl];
    self.createTime = [[teDic objectForKey:kCreateTime] doubleValue];
    self.updateTime = [[teDic objectForKey:kUpdateTime] doubleValue];
    self.nSharingLocalUserCount = [teDic[kSharelocation] intValue];

    NSDictionary *permDic = [teDic objectForKey:kPerm];
    self.permString = [permDic JSONString];
    
    self.lastestSequence = [[topicDic objectForKey:kLastestSeq] longValue];
    
    ACUser *creater = [[ACUser alloc] init];
    [creater setUserDic:[teDic objectForKey:kCreator]];
    [ACUserDB saveUserToDBWithUser:creater];
    self.createUserID = creater.userid;
    
    self.isAdmin = [[topicDic objectForKey:kAdmin] boolValue];
    self.lastestMessageType = [topicDic objectForKey:kMsgType];
    if (!_lastestMessageType)
    {
        self.lastestMessageType = [topicDic objectForKey:kMsgtype];
    }
    NSDictionary *userDic = [topicDic objectForKey:kMsgUser];
    self.lastestMessageUserID = [userDic objectForKey:kId];
    
    ACUser *user = [[ACUser alloc] init];
    [user setUserDic:userDic];
    [ACUserDB saveUserToDBWithUser:user];
    if ([self.title isEqualToString:@"win8"] || ([self.mpType isEqualToString:cSingleChat] && [user.name isEqualToString:@"win8"]))
    {
        
    }


    enum ACMessageEnumType typeTmp = [ACMessage getMessageEnumTypeWithMessageType:_lastestMessageType];
    self.lastestTextMessage = [ACMessageEvent getLasestTextMessageWithMessageType:typeTmp
                                                                          content:[topicDic objectForKey:kMsg]
                                                                           userID:_lastestMessageUserID
                                                                         userName:[userDic objectForKey:kName]
                                                                        topicType:self.mpType
                                                                TopicDestructType:_topicPerm.destruct];

    self.currentSequence = [[topicDic objectForKey:kCurrentSeq] longValue];
    
    if ([self.mpType isEqualToString:cWallboard])
    {
        if ([ACDataCenter shareDataCenter].wallboardTopicEntity == nil)
        {
            self.lastestMessageTime = [[topicDic objectForKey:kMsgTime] doubleValue];
        }
        else
        {
            self.lastestMessageTime = [ACDataCenter shareDataCenter].wallboardTopicEntity.lastestMessageTime;
        }
    }
    else
    {
        self.lastestMessageTime = [[topicDic objectForKey:kMsgTime] doubleValue];
    }
    if (_lastestMessageTime == 0)
    {
        self.lastestMessageTime = self.updateTime;
    }
    
    self.entityType = EntityType_Topic;
    
    self.obj = [[teDic objectForKey:kObj] JSONString];
    self.relateTeID = [[teDic objectForKey:kObj] objectForKey:kRelateTe];
    self.relateType = [[teDic objectForKey:kObj] objectForKey:kRelateType];
    
    //Save用户信息
    BOOL    bNeedSaveUserInfoToDB =   YES;
    BOOL    bIsRelateChat = NO;
    BOOL    bIsSingleChat = [self.mpType isEqualToString:cSingleChat];
    if(self.relateTeID.length){
        bNeedSaveUserInfoToDB = NO;
        bIsRelateChat = YES;
    }
    
    NSArray *participants = [[teDic objectForKey:kObj] objectForKey:kParticipants];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *userid = [defaults objectForKey:kUserID];
    for (NSDictionary *participant in participants)
    {
        ACUser *user = [[ACUser alloc] init];
        [user setUserDic:participant];
        if (![user.userid isEqualToString:userid])
        {
            if(bNeedSaveUserInfoToDB){
                [ACUserDB saveUserToDBWithUser:user];
            }
            
            if(bIsRelateChat){
                self.relateChatUserID = user.userid;
            }
            else if(bIsSingleChat) {
                self.singleChatUserID = user.userid;
            }
        }
    }
    
    if(!bIsSingleChat){
        self.singleChatUserID = @"";
    }
    
    
//        if (self.relateTeID != nil && self.relateTeID.length > 0) {
//            NSArray *participants = [[teDic objectForKey:kObj] objectForKey:kParticipants];
//            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//            NSString *userid = [defaults objectForKey:kUserID];
//            for (NSDictionary *participant in participants)
//            {
//                ACUser *user = [[ACUser alloc] init];
//                [user setUserDic:participant];
//                if (![user.userid isEqualToString:userid])
//                {
//                    [ACUserDB saveUserToDBWithUser:user];
//                    self.relateChatUserID = user.userid;
//                }
//            }
//        }
//        
//        if ([_mpType isEqualToString:cSingleChat])
//        {
//            NSArray *participants = [[teDic objectForKey:kObj] objectForKey:kParticipants];
//            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//            NSString *userid = [defaults objectForKey:kUserID];
//            for (NSDictionary *participant in participants)
//            {
//                ACUser *user = [[ACUser alloc] init];
//                [user setUserDic:participant];
//                if (![user.userid isEqualToString:userid])
//                {
//                    [ACUserDB saveUserToDBWithUser:user];
//                    self.singleChatUserID = user.userid;
//                }
//            }
//        }
//        else
//        {
//            self.singleChatUserID = @"";
//        }
    self.isTurnOffAlerts = NO;
    self.isDeleted = NO;
}

-(void)updateWithDict:(NSDictionary *)eventDic
{
    NSDictionary_getAndCheckValueString(self.title,eventDic,kTitle);
    NSDictionary_getAndCheckValueString(self.icon,eventDic,kIcon);
//    NSDictionary_getAndCheckValueString(self.mpType,eventDic,kType);
    NSDictionary_getAndCheckValueString(self.url,eventDic,kUrl);
//    NSDictionary_getAndCheckValueDouble(self.createTime, eventDic, kCreateTime);
    self.nSharingLocalUserCount = [eventDic[kSharelocation] intValue];

    NSDictionary *permDic = [eventDic objectForKey:kPerm];
    if(permDic){
        self.permString = [permDic JSONString];
    }

    NSDictionary_getAndCheckValueLong(self.lastestSequence, eventDic, kLastestSeq);

    NSDictionary_getAndCheckValueBool(self.isAdmin,eventDic,kAdmin);


    NSString *lastestMessageType = [eventDic objectForKey:kMsgType];
    if (!lastestMessageType){
        lastestMessageType = [eventDic objectForKey:kMsgtype];
    }
    if (lastestMessageType != nil){
        self.lastestMessageType = lastestMessageType;
    }

    NSDictionary *msgUser =  [eventDic objectForKey:kMsgUser];
    NSString *lastestMessageUserID = [msgUser objectForKey:kId];
    if (lastestMessageUserID != nil){
        self.lastestMessageUserID = lastestMessageUserID;
    }
    enum ACMessageEnumType typeTmp = [ACMessage getMessageEnumTypeWithMessageType:_lastestMessageType];

    NSString *content = [eventDic objectForKey:kMsg];
    NSString *lastestTextMessage = [ACMessageEvent getLasestTextMessageWithMessageType:typeTmp
                                                                               content:content
                                                                                userID:lastestMessageUserID
                                                                              userName:[msgUser objectForKey:kName]
                                                                             topicType:self.mpType
                                                                     TopicDestructType:_topicPerm.destruct];
    if (lastestTextMessage != nil){
        self.lastestTextMessage = lastestTextMessage;
    }

    NSDictionary_getAndCheckValueLong(self.currentSequence,eventDic,kCurrentSeq);

    NSDictionary_getAndCheckValueDouble(self.updateTime, eventDic, kUpdateTime);

    NSNumber *lastestMessageTime = [eventDic objectForKey:kMsgTime];
    /*test*/
//    if ([self.mpType isEqualToString:cWallboard])
//    {
//
//    }
    /*test*/
    if (lastestMessageTime != nil && ![self.mpType isEqualToString:cWallboard])
    {
        self.lastestMessageTime = [lastestMessageTime doubleValue];
    }
    else
    {
        self.lastestMessageTime = self.updateTime;
    }
    NSDictionary *obj = [eventDic objectForKey:kObj];
    if (obj)
    {
        self.obj = [obj JSONString];
    }
}

-(void)setSharingLocalUserCountAndSaveToDB:(int)nSharingLocalUserCount{
    if(nSharingLocalUserCount!=_nSharingLocalUserCount){
        self.nSharingLocalUserCount =   nSharingLocalUserCount;
//        ACTopicEntityDB_TopicEntityShareLocation_save(self);
    }
}

//为option更新修改
-(void)updateEntityForOptionWithEventDic:(NSDictionary *)topicDic{
    
    NSDictionary *teDic = [topicDic objectForKey:kTe];
    if (teDic == nil)//用于search时组合topicEntity
    {
        teDic = topicDic;
    }
    
    NSDictionary_getAndCheckValueString(self.title,teDic,kTitle);
    NSDictionary_getAndCheckValueString(self.icon ,teDic,kIcon);
    NSDictionary_getAndCheckValueString(self.url,teDic,kUrl);
    NSDictionary_getAndCheckValueDouble(self.createTime,teDic,kCreateTime);
    NSDictionary_getAndCheckValueDouble(self.updateTime,teDic,kUpdateTime);
    
    NSDictionary *permDic = [teDic objectForKey:kPerm];
    if(permDic){
        self.permString = [permDic JSONString];
    }
}


-(BOOL)isSigleChat{
    return [self.mpType isEqualToString:cSingleChat];
}


NSString * const kACTopicEntityTurnOffAlertsNotifation =  @"ACTopicEntityTurnOffAlertsNotifation";

-(void)changeIsTurnOffAlertsAndSendToServer:(BOOL)isTurnOffAlerts  withView:(UIView*)pView{
  
    wself_define();
    callURL_block pCallURl_Block = ^(ASIHTTPRequest* request,BOOL bIsFail){
        NSDictionary *responseDic = [[[request.responseData objectFromJSONData] JSONString] objectFromJSONString];
        [pView hideProgressHUDWithAnimated:NO];
        if (ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]&&wself){
            wself.isTurnOffAlerts =  isTurnOffAlerts;
            [ACTopicEntityDB saveTopicEntityToDBWithTopicEntity:wself];
            [ACUtility postNotificationName:kACTopicEntityTurnOffAlertsNotifation object:nil];
        }
    };
    
    NSString* pCallURL = [NSString stringWithFormat:@"%@/rest/apis/chat/mutechat/%@",[ACNetCenter shareNetCenter].acucomServer,self.entityID];
    [pView showProgressHUD];
    if(isTurnOffAlerts){
        [ACNetCenter callURL:pCallURL forPut:NO withPostData:nil withBlock:pCallURl_Block];
    }
    else{
        [ACNetCenter callURL:pCallURL forMethodDelete:YES withBlock:pCallURl_Block];
    }
    
    
//    /rest/apis/chat/mutechat/7932b0497d9185a2b198b855157dbfb0   POST   { "code" : 1}
//    /rest/apis/chat/mutechat/7932b0497d9185a2b198b855157dbfb0   DELETE  { "code" : 1}
    
}



#pragma mark -get方法

-(NSString*)dictFieldName{
    return @"te";
}

-(NSString*)requestUrl{
    return [NSString stringWithFormat:@"%@/rest/apis/chat/%@",[[ACNetCenter shareNetCenter] acucomServer],self.entityID];
}

-(NSString *)title
{
    return _title?_title:@"";
}

-(void)setTitle:(NSString *)title
{
    if ([title isKindOfClass:[NSString class]] && _title != title)
    {
        _title = title;
    }
}

-(NSString *)icon
{
    return _icon?_icon:@"";
}

-(void)setIcon:(NSString *)icon
{
    if ([icon isKindOfClass:[NSString class]] && _icon != icon)
    {
        _icon = icon;
    }
}


-(NSString *)url
{
    return _url?_url:@"";
}

-(void)setUrl:(NSString *)url
{
    if ([url isKindOfClass:[NSString class]] && _url != url)
    {
        _url = url;
    }
}

-(NSString *)lastestTextMessage
{
    return _lastestTextMessage?_lastestTextMessage:@"";
}

-(void)setLastestTextMessage:(NSString *)lastestTextMessage
{
    if ([lastestTextMessage isKindOfClass:[NSString class]] && _lastestTextMessage != lastestTextMessage)
    {
        _lastestTextMessage = lastestTextMessage;
    }
}

-(NSString *)lastestMessageType
{
    return _lastestMessageType?_lastestMessageType:@"";
}

-(void)setLastestMessageType:(NSString *)lastestMessageType
{
    if ([lastestMessageType isKindOfClass:[NSString class]] && _lastestMessageType != lastestMessageType)
    {
        _lastestMessageType = lastestMessageType;
    }
}

-(NSString *)lastestMessageUserID
{
    return _lastestMessageUserID?_lastestMessageUserID:@"";
}

-(void)setLastestMessageUserID:(NSString *)lastestMessageUserID
{
    if ([lastestMessageUserID isKindOfClass:[NSString class]] && _lastestMessageUserID != lastestMessageUserID)
    {
        _lastestMessageUserID = lastestMessageUserID;
    }
}

-(NSString *)singleChatUserID
{
    return _singleChatUserID?_singleChatUserID:@"";
}


-(void)setSingleChatUserID:(NSString *)singleChatUserID
{
    if ([singleChatUserID isKindOfClass:[NSString class]] && _singleChatUserID != singleChatUserID)
    {
        _singleChatUserID = singleChatUserID;
    }
}

-(NSString *)relateTeID
{
    return _relateTeID?_relateTeID:@"";
}

-(void)setRelateTeID:(NSString *)relateTeID
{
    if ([relateTeID isKindOfClass:[NSString class]] && _relateTeID != relateTeID)
    {
        _relateTeID = relateTeID;
    }
}

-(NSString *)relateType
{
    return _relateType?_relateType:@"";
}

-(void)setRelateType:(NSString *)relateType
{
    if ([relateType isKindOfClass:[NSString class]] && _relateType != relateType)
    {
        _relateType = relateType;
    }
}

-(NSString *)relateChatUserID
{
    return _relateChatUserID?_relateChatUserID:@"";
}

-(void)setRelateChatUserID:(NSString *)relateChatUserID
{
    if([relateChatUserID isKindOfClass:[NSString class]] && _relateChatUserID != relateChatUserID)
    {
        _relateChatUserID = relateChatUserID;
    }
}

-(NSString *)obj
{
    return _obj?_obj:@"";
}

-(void)setObj:(NSString *)obj
{
    if (_obj != obj)
    {
        _obj = obj;
        if ([self.mpType isEqualToString:cWallboard])
        {
            NSDictionary *objDic = [obj objectFromJSONString];
            NSArray *categories = [objDic objectForKey:kCategories];
            self.categoriesArray = [NSMutableArray array];
            if(categories != nil && ![categories isEqual:[NSNull null]] &&  categories.count > 0) {
                for (NSDictionary *categoryDic in categories)
                {
                    ACCategory *category = [[ACCategory alloc] init];
                    category.name = [categoryDic objectForKey:kName];
                    category.cid = [categoryDic objectForKey:kCid];
                    [_categoriesArray addObject:category];
                }
            }
        }
    }
}

-(void)setLastestMessageTime:(NSTimeInterval)lastestMessageTime
{
    if (lastestMessageTime < 1300000000 && lastestMessageTime > 0)
    {
        
    }
    if (_lastestMessageTime != lastestMessageTime)
    {
        if (lastestMessageTime == 0)
        {
            if (_lastestMessageTime == 0)
            {
                _lastestMessageTime = self.updateTime;
            }
            else
            {
                if (![self.mpType isEqualToString:cWallboard] && _lastestMessageTime < self.updateTime)
                {
                    _lastestMessageTime = self.updateTime;
                }
            }
        }
        else
        {
            _lastestMessageTime = lastestMessageTime;
        }
    }
}

-(void)setCurrentSequence:(long)currentSequence
{
    if(_currentSequence>self.lastestSequence){
        return;
    }
    
#if TARGET_IPHONE_SIMULATOR
    //模拟器测试使用
    _currentSequence = currentSequence;
#else
    if(currentSequence>_currentSequence){
        //使用最大的那个
        _currentSequence = currentSequence;
    }
#endif
    
//    if(_currentSequence>self.lastestSequence){
//        _currentSequence =  self.lastestSequence;
//    }
    
    if (_topicPerm.destruct == ACTopicPermission_DestructMessage_Allow)
    {
        self.lastestTextMessage = nil;
    }
}


//创建topicEntity从数据库
+(ACTopicEntity *)getTopicEntityWithFMResultSet:(FMResultSet *)resultSet
{
    __autoreleasing ACTopicEntity *topicEntity = [[ACTopicEntity alloc] init];
    topicEntity.entityID = [resultSet stringForColumn:@"entityID"];
    topicEntity.updateTime = [resultSet doubleForColumn:@"updateTime"];
    topicEntity.lastestSequence = [resultSet longForColumn:@"lastestSequence"];
    topicEntity.entityType = [resultSet intForColumn:@"entityType"];
    topicEntity.title = [resultSet stringForColumn:@"title"];
    topicEntity.icon = [resultSet stringForColumn:@"icon"];
    topicEntity.mpType = [resultSet stringForColumn:@"mpType"];
    topicEntity.url = [resultSet stringForColumn:@"url"];
    topicEntity.createTime = [resultSet doubleForColumn:@"createTime"];
    topicEntity.createUserID = [resultSet stringForColumn:@"createUserID"];
    
    topicEntity.permString = [resultSet stringForColumn:@"permString"];
    
    topicEntity.currentSequence = [resultSet longForColumn:@"currentSequence"];
    topicEntity.isAdmin = [resultSet boolForColumn:@"isAdmin"];
    topicEntity.lastestTextMessage = [resultSet stringForColumn:@"lastestTextMessage"];
    topicEntity.lastestMessageType = [resultSet stringForColumn:@"lastestMessageType"];
    topicEntity.lastestMessageTime = [resultSet doubleForColumn:@"lastestMessageTime"];
    topicEntity.lastestMessageUserID = [resultSet stringForColumn:@"lastestMessageUserID"];
  
    topicEntity.relateTeID  =   [resultSet stringForColumn:@"relateTeID"];
    topicEntity.relateType  =   [resultSet stringForColumn:@"relateType"];
    topicEntity.relateChatUserID  =   [resultSet stringForColumn:@"relateChatUserID"];
    
    topicEntity.singleChatUserID = [resultSet stringForColumn:@"singleChatUserID"];
    topicEntity.isTurnOffAlerts = [resultSet intForColumn:@"isTurnOffAlerts"];
    topicEntity.obj = [resultSet stringForColumn:@"obj"];


    return topicEntity;
}

-(NSString*)getShowTitle{
    return [self getShowTitleAndSetIcon:nil andCanEditForGroupInfoOption:NULL];
}

//取得标题并设置图标
-(NSString*)getShowTitleAndSetIcon:(UIImageView*)pIconImageView  andCanEditForGroupInfoOption:(BOOL*)pCanEdit{
    BOOL bIconViewToCircle = YES;
    BOOL bCanEdit = NO;
    NSString* pRetTitle = @"";
    
    //    [_nameLabel setFrame_y:14];
    if ([self.mpType isEqualToString:cWallboard])
    {
        bIconViewToCircle = NO;
        if(pIconImageView){
            pIconImageView.image = [UIImage imageNamed:@"wallboard.png"];
        }
        pRetTitle = _title;
        //        [_nameLabel setFrame_y:24];
    }
    //单聊显示用户icon和name，组聊显示组icon和组名
    else if ([self.mpType isEqualToString:cSingleChat]) {

        ACUser *user = [ACUserDB getUserFromDBWithUserID:_singleChatUserID];

        //组icon
        if (pIconImageView) {
            NSString *imageName = @"icon_singlechat.png";
            if (user.icon) {
                [pIconImageView setImageWithIconString:user.icon
                                      placeholderImage:[UIImage imageNamed:imageName]
                                             ImageType:ImageType_TopicEntity];
            }
            else {
                bIconViewToCircle = NO;
                pIconImageView.image = [UIImage imageNamed:imageName];
            }
        }
        pRetTitle = user.name;
    }
    else if([self.mpType isEqualToString:cSystemChat]){
        if (pIconImageView) {
            bIconViewToCircle = NO;
            pIconImageView.image = [UIImage imageNamed:@"icon_systemChat"];
        }
        pRetTitle = _title;
    }
    else
    {
        //组icon
        NSString *imageName = @"icon_groupchat.png";

        //$$
        if(_relateTeID != nil && _relateTeID.length > 0) // 特殊会话
        {
            ACUser *user = [ACUserDB getUserFromDBWithUserID:_relateChatUserID];
            
            //组icon
            if(pIconImageView){
                if (user.icon)
                {
                    [pIconImageView setImageWithIconString:user.icon
                                          placeholderImage:[UIImage imageNamed:imageName]
                                                    ImageType:ImageType_TopicEntity];
                }
                else
                {
                    bIconViewToCircle = NO;
                    pIconImageView.image = [UIImage imageNamed:imageName];
                }
            }
            pRetTitle = user.name;
        }
        else{
            
            if(pIconImageView){
                if (_icon)
                {
                    if ([self.mpType isEqualToString:cLocationAlert])
                    {
                        bIconViewToCircle = NO;
                        [pIconImageView setImage:[UIImage imageNamed:@"LocationAlert.png"]];
                    }
                    else
                    {
                        [pIconImageView setImageWithIconString:_icon
                                              placeholderImage:[UIImage imageNamed:imageName]
                                                          ImageType:ImageType_TopicEntity];
                    }
                }
                else
                {
                    bIconViewToCircle = NO;
                    pIconImageView.image = [UIImage imageNamed:imageName];
                }
            }
            
            //组名
            bCanEdit    =   ![self.mpType isEqualToString:cLocationAlert];
            pRetTitle   =  _title;
        }
    }
    
    if(pIconImageView){
        if(bIconViewToCircle){
            [pIconImageView setToCircle];
        }
        else{
            [pIconImageView setRectRound:5];
        }
    }
    
    if(pCanEdit){
        *pCanEdit = bCanEdit&&self.perm.canUpdateInfo;
    }

    return pRetTitle;
}


@end

NSString *const cSurvey = @"survey";
NSString *const cEvent = @"eventurl";
NSString *const cLink = @"web";
NSString *const cPage = @"page";

@implementation ACUrlEntity


-(NSString*)dictFieldName{
    return @"ue";
}

-(NSString*)requestUrl{
    return [NSString stringWithFormat:@"%@/rest/apis/url/%@",[[ACNetCenter shareNetCenter] acucomServer],self.entityID];
}

- (id)initWithUrlEventDic:(NSDictionary *)urlEventDic
{
    self = [super init];
    if (self) {
        NSDictionary *urlDic = [urlEventDic objectForKey:kUrl];
        self.entityID = [urlDic objectForKey:kId];
        self.mpType = [urlDic objectForKey:kType];
        self.createTime = [[urlDic objectForKey:kCreateTime] doubleValue];

        ACUser *user = [[ACUser alloc] init];
        [user setUserDic:[urlDic objectForKey:kCreator]];
        [ACUserDB saveUserToDBWithUser:user];
        self.createUserID = user.userid;
      
        self.lastestSequence = 0;
        self.entityType = EntityType_URL;

        [self updateWithDict:urlDic];
    }
    return self;
}

-(void)updateEntityWithEventDic:(NSDictionary *)eventDic
{
    NSDictionary *urlDic = eventDic;
    if ([[eventDic objectForKey:kUrl] isKindOfClass:[NSDictionary class]]){
        urlDic = [eventDic objectForKey:kUrl];
    }
    else{
        urlDic = eventDic;
    }
    [self updateWithDict:urlDic];
}

-(void) updateWithDict:(NSDictionary*)dic{
    NSString *title = [dic objectForKey:kTitle];
    if (title != nil){
        self.title = title;
    }
    NSString *icon = [dic objectForKey:kIcon];
    if (icon != nil){
        self.icon = icon;
    }
//    NSString *mpType = [dic objectForKey:kType];
//    if (mpType != nil)
//    {
//        self.mpType = mpType;
//    }
    NSString *url = [dic objectForKey:kUrl];
    if (url != nil){
        self.url = url;
    }
//    NSString *createTime = [dic objectForKey:kCreateTime];
//    if (createTime != nil)
//    {
//        self.createTime = [createTime doubleValue];
//    }
    NSString *updateTime = [dic objectForKey:kUpdateTime];
    if (updateTime != nil){
        self.updateTime = [updateTime doubleValue];
    }
    NSDictionary *perm = [dic objectForKey:kPerm];
    if (perm != nil){
        self.permString = [perm JSONString];
    }
}

-(void)setUrl:(NSString *)url
{
    _url = url;
}

//创建urlEntity从数据库
+(ACUrlEntity *)getUrlEntityWithFMResultSet:(FMResultSet *)resultSet
{
    __autoreleasing ACUrlEntity *urlEntity = [[ACUrlEntity alloc] init];
    urlEntity.entityID = [resultSet stringForColumn:@"entityID"];
    urlEntity.updateTime = [resultSet doubleForColumn:@"updateTime"];
    urlEntity.lastestSequence = [resultSet longForColumn:@"lastestSequence"];
    urlEntity.entityType = [resultSet intForColumn:@"entityType"];
    urlEntity.title = [resultSet stringForColumn:@"title"];
    urlEntity.icon = [resultSet stringForColumn:@"icon"];
    urlEntity.mpType = [resultSet stringForColumn:@"mpType"];
    urlEntity.url = [resultSet stringForColumn:@"url"];
    urlEntity.createTime = [resultSet doubleForColumn:@"createTime"];
    urlEntity.createUserID = [resultSet stringForColumn:@"createUserID"];
    
    urlEntity.permString = [resultSet stringForColumn:@"permString"];
    return urlEntity;
}

//取得标题并设置图标
-(NSString*)getShowTitleAndSetIcon:(UIImageView*)pIconImageView andCanEditForGroupInfoOption:(BOOL*)pCanEdit{
    if(pIconImageView){
        NSString* pDefImageName = nil;
        if ([self.mpType isEqualToString:cEvent]){
            pDefImageName = @"icon_event.png";
        }
        else if ([self.mpType isEqualToString:cSurvey]){
            pDefImageName = @"icon_survey.png";
        }
        else if ([self.mpType isEqualToString:cLink]){
            pDefImageName = @"icon_link.png";
        }
        else if ([self.mpType isEqualToString:cPage]){
            pDefImageName = @"icon_page.png";
        }
        
        UIImage* pImageDef = [UIImage imageNamed:pDefImageName];
        
        if (_icon){
            [pIconImageView setToCircle];
            [pIconImageView setImageWithIconString:_icon placeholderImage:pImageDef ImageType:ImageType_UrlEntity];
        }
        else{
            [pIconImageView setRectRound:5];
            pIconImageView.image = pImageDef;
        }
    }
    
    if(pCanEdit){
        *pCanEdit = self.perm.canUpdateInfo;
    }
    
    return _title;
}


@end
