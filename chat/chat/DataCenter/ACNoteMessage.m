//
//  ACNote.m
//  chat
//
//  Created by Aculearn on 14/12/17.
//  Copyright (c) 2014年 Aculearn. All rights reserved.
//

#import "ACNoteMessage.h"
#import "ACAddress.h"
#import "JSONKit.h"
#import "ACMessageDB.h"
#import "ACDataCenter.h"
#import "ACTopicEntityDB.h"
#import "ACDataCenter.h"
#import "ACTopicEntityEvent.h"
#import "ASIFormDataRequest.h"
#import "ACNetCenter.h"
#import "ACAddress.h"
#import "ACNetCenter+Notes.h"

NSString *const ACNoteContent_TYPE_DESCRIPTION = @"description";
NSString *const ACNoteContent_TYPE_IMAGE = @"image";
NSString *const ACNoteContent_TYPE_VIDEO = @"video";
NSString *const ACNoteContent_TYPE_LOCATION = @"location";
NSString *const ACNoteContent_TYPE_LINK = @"website";


NSString *const FIELD_ID = @"id";
NSString *const FIELD_TYPE = @"type";
NSString *const FIELD_DESC = @"desc";
NSString *const FIELD_RID = @"rid";
NSString *const FIELD_RPATH = @"localPath";
NSString *const FIELD_TRID = @"trid";
NSString *const FIELD_TPATH = @"thumblocalpath";
NSString *const FIELD_LENGTH = @"length";
NSString *const FIELD_DURATION = @"duration";

#define ACNoteComment_Type    10
#define ACNoteMessage_Type    1


@implementation ACNoteContentObject

/*
-(id)initWithDict:(NSDictionary*)pDict{
    self = [super init];
    if(self){
        _contentID  =   [pDict objectForKey:FIELD_ID];
        _contentType=   [pDict objectForKey:FIELD_TYPE];
    }
    return self;
}*/

@end

/*
@implementation ACNoteContentDescription

-(id)initWithDict:(NSDictionary*)pDict{
    self = [super initWithDict:pDict];
    if(self){
        _text   =   [pDict objectForKey:FIELD_DESC];
    }
    return self;
}
@end
*/


@implementation ACNoteContentImageOrVideo


-(instancetype)initForImage:(BOOL)bIsImage{
    self = [super init];
    if(self){
        _bIsImage   =   bIsImage;
    }
    return self;
}

-(instancetype)initWithDict:(NSDictionary*)pDict   forImage:(BOOL)bIsImage{
    self = [super init];
    if(self){
        _resourceID =   [pDict objectForKey:FIELD_RID];
        _thumbResourceID   =   [pDict objectForKey:FIELD_TRID];
        _length     =   [[pDict objectForKey:FIELD_LENGTH] longValue];
        _bIsImage   =   bIsImage;
    }
    return self;
}


-(enum ACFile_Type) acFileType{
    return _bIsImage?ACFile_Type_WallboardPhoto:ACFile_Type_WallboardVideo;
}


-(NSURL*)getResourceURLForThumb:(BOOL)bForThumb withNoteMessage:(ACNoteMessage*)noteMessage{
    return [NSURL URLWithString:[self getResourceURLStringForThumb:bForThumb withNoteMessage:noteMessage]];
}

-(NSString*)getResourceURLStringForThumb:(BOOL)bForThumb withNoteMessage:(ACNoteMessage*)noteMessage{
    NSString* pRetURL = [NSString stringWithFormat:@"%@/rest/apis/note/%@/upload/%@",[[ACNetCenter shareNetCenter] acucomServer],noteMessage.teid ,bForThumb?_thumbResourceID:_resourceID];
    if(bForThumb){
        return pRetURL;
    }

    //拼凑length
    return [ACNetCenter getdownloadURL:pRetURL withFileLength:_length];
}


-(NSString*)videoDownloadTempFilePath{
    NSAssert(!_bIsImage,@"videoDownloadTempFilePath");
    return [ACAddress getAddressWithFileName:_resourceID fileType:ACFile_Type_WallboardVideo isTemp:YES subDirName:nil];
}

-(NSString*)resourceFilePath{
    return [ACAddress getAddressWithFileName:_resourceID fileType:self.acFileType isTemp:NO subDirName:nil];
}

-(NSString*)thumbFilePath{
    return [ACAddress getAddressWithFileName:_thumbResourceID fileType:self.acFileType isTemp:NO subDirName:nil];
}


@end


@implementation ACNoteContentLocation

-(instancetype)initWithDict:(NSDictionary*)pDict{
    self = [super init];
    if(self){
        NSArray* pLola = [pDict objectForKey:@"lola"];
        if(pLola.count<2){
            return nil;
        }
        _Location = CLLocationCoordinate2DMake([pLola[1] doubleValue], [pLola[0] doubleValue]);
        _address  =   [pDict objectForKey:@"address"];
        _name =   [pDict objectForKey:@"locName"];
    }
    return self;
}

-(NSDictionary*) postDict{

/*
 {
 "type" : "location",
 "la" : 23.123213, //latitude
 "lo" : 24.3432432, //longitude
 "name" : "地名",
 "address" : "地址"
 }，
 */
    NSMutableDictionary* pDict =   [[NSMutableDictionary alloc] initWithObjectsAndKeys:ACNoteContent_TYPE_LOCATION,FIELD_TYPE,
    @(_Location.latitude),@"la",
    @(_Location.longitude),@"lo",nil];
    if(_name){
        [pDict setValue:_name forKey:@"name"];
    }
    if(_address){
        [pDict setValue:_address forKey:@"address"];
    }
    
   return pDict;
}

@end

NSString *const FIELD_LINK_ICON = @"icon";
NSString *const FIELD_LINK_TITLE = @"title";
NSString *const FIELD_LINK_DETAIL = @"link";
NSString *const FIELD_LINK_DESC = @"desp";

@implementation ACNoteContentWebsite

-(instancetype)initWithDict:(NSDictionary*)pDict{
    self = [super init];
    if(self){
        _linkIcon   =   [pDict objectForKey:FIELD_LINK_ICON];
        _linkTitle  =   [pDict objectForKey:FIELD_LINK_TITLE];
        _linkURL  =   [pDict objectForKey:FIELD_LINK_DETAIL];
        _linkDesc  =   [pDict objectForKey:FIELD_LINK_DESC];
        if(nil==_linkDesc){
            _linkDesc = @" ";
        }
    }
    return self;
}


-(NSDictionary*) postDict{
    
    /*
     {
     "type" : "website", //还可以为"description", "image", "audio", "video", "location", "website"
     "link" : "http://www.google.com",
     "title" : "Google",
     "icon" : "http://www.google.com/1.png",
     "desp" : "最好的搜索引擎",
     }，
     */
    
    NSMutableDictionary* pDict =   [[NSMutableDictionary alloc] initWithObjectsAndKeys:ACNoteContent_TYPE_LINK,FIELD_TYPE,_linkURL,@"link",nil];
    if(_linkTitle){
        [pDict setValue:_linkTitle forKey:@"title"];
    }
    
    if(_linkIcon){
        [pDict setValue:_linkIcon forKey:@"icon"];
    }
    
    if(_linkDesc){
        [pDict setValue:_linkDesc forKey:@"desp"];
    }
    
    return pDict;
}

@end


//NSString *const FIELD_TYPE = @"type";
NSString *const FIELD_PID = @"pid";
NSString *const FIELD_DESP = @"desp";
NSString *const FIELD_TERMINAL = @"terminal";
NSString *const FIELD_UPDATETIME = @"updateTime";
NSString *const FIELD_CREATETIME = @"createTime";
NSString *const FIELD_USER = @"user";



@implementation ACNoteObject

-(instancetype)initWithDict:(NSDictionary*)pDict{
    self = [super init];
    if(self){
        [self setDataFromDict:pDict];
     }
    return self;
}

-(NSDictionary*) postDict{
    /*
     {
     "type" : "description",
     "text" : "文字内容"
     }     */
    return @{FIELD_TYPE:ACNoteContent_TYPE_DESCRIPTION,
             @"text":self.content};
}

-(void)setDataFromDict:(NSDictionary*)pDict{
    _id    =  [pDict objectForKey:@"id"];
    _teid   =   [pDict objectForKey:kTeid];
    _content =  [pDict objectForKey:FIELD_DESP];
    _terminal =  [pDict objectForKey:FIELD_TERMINAL];
    _createTime = [[pDict objectForKey:FIELD_CREATETIME] longLongValue];
    _updateTime = [[pDict objectForKey:FIELD_UPDATETIME] longLongValue];
    if(nil==_creator){
        _creator    =   [[ACUser alloc] init];
    }
    [_creator setUserDic:[pDict objectForKey:FIELD_USER]];
}

//-(BOOL)getIsMyself{
//    if(_creator.userid.length){
//        return [_creator.userid isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:kUserID]];
//    }
//    return NO;
//}

-(BOOL)getIsNoteMessage{
    return NO;
}

-(ACTopicEntity*)gettopicEntity{
    NSArray* pEntity = [ACDataCenter shareDataCenter].topicEntityArray;
    for(ACTopicEntity* pTe in pEntity){
        if([pTe.entityID isEqualToString:_teid]){
            return pTe;
        }
    }
    return nil;
}

+(instancetype)noteDataFromDict:(NSDictionary*)pDict{ //通过Dict取得 ACNoteComment 或 ACNoteMessage
    int nType = [[pDict objectForKey:FIELD_TYPE] intValue];
    if(ACNoteComment_Type==nType){
        return [[ACNoteComment alloc] initWithDict:pDict];
    }
    if(ACNoteMessage_Type==nType){
        return [[ACNoteMessage alloc] initWithDict:pDict];
    }
    return nil;
}

+(NSInteger)addNoteDataFromDictArray:(NSArray*)pArray to:(NSMutableArray*)pToArray{ //通过Dict的Array添加
    NSInteger nCount = 0;
    for(NSDictionary* pDict in pArray){
        ACNoteObject* pObj = [ACNoteObject noteDataFromDict:pDict];
        if(pObj){
            nCount ++;
            [pToArray addObject:pObj];
        }
    }
    return nCount;
}



@end


NSString *const FIELD_REFERUSERS = @"referUsers";
/**仅本地创建comment发送时使用*/
NSString *const FIELD_REFERUSERIDS = @"referUserIds";






NSString *const FIELD_COMMENTNUMBER = @"cNum";
NSString *const FIELD_LOCNAME = @"locName";
NSString *const FIELD_LOC = @"loc";
NSString *const FIELD_AUDIOS = @"audios";
NSString *const FIELD_VIDEOS = @"videos";
NSString *const FIELD_IMAGES = @"images";
NSString *const FIELD_WEBS = @"webs";

#define kIdmap          @"idmap"

@implementation ACNoteMessage

-(instancetype)init{
    self = [super init];
    if(self){
        _imageList = [[NSMutableArray alloc] init];
        _videoList = [[NSMutableArray alloc] init];
        _imgs_Videos_List = [[NSMutableArray alloc] init];
    }
    return self;
}


-(void)updateMessageFromDict:(NSDictionary*)pDict{
    [super setDataFromDict:pDict];
    _commentNum =   [[pDict objectForKey:FIELD_COMMENTNUMBER] integerValue];
}

-(instancetype)initWithDict:(NSDictionary*)pDict{
    self = [super initWithDict:pDict];
    if(self){
        NSAssert(ACNoteMessage_Type==[[pDict objectForKey:FIELD_TYPE] intValue],@"ACNoteMessage 错误");

        _commentNum =   [[pDict objectForKey:FIELD_COMMENTNUMBER] integerValue];
        _imageList = [[NSMutableArray alloc] init];
        _videoList = [[NSMutableArray alloc] init];
        _imgs_Videos_List = [[NSMutableArray alloc] init];
        
        
        {
            NSDictionary* pLoc =    [pDict objectForKey:FIELD_LOC];
            if(pLoc){
                _location = [[ACNoteContentLocation alloc] initWithDict:pLoc];
            }
        }
        
        {
            NSArray* pFIELD_IMAGES =    [pDict objectForKey:FIELD_IMAGES];
            for(NSDictionary* pDict in pFIELD_IMAGES){
                [self addImageOrVideo:[[ACNoteContentImageOrVideo alloc] initWithDict:pDict forImage:YES]];
            }
        }
        
        {
            NSArray* pFIELD_VIDEOS =    [pDict objectForKey:FIELD_VIDEOS];
            for(NSDictionary* pDict in pFIELD_VIDEOS){
                [self addImageOrVideo:[[ACNoteContentImageOrVideo alloc] initWithDict:pDict forImage:NO]];
            }
        }
        
        {
            NSArray* pFIELD_WEBS =    [pDict objectForKey:FIELD_WEBS];
            if(pFIELD_WEBS.count){
                _link   =   [[ACNoteContentWebsite alloc] initWithDict:pFIELD_WEBS[0]];
            }
        }
    }
    return self;
}


-(BOOL)getIsNoteMessage{
    return YES;
}


-(NSArray*)getImageOrVideoIDs:(BOOL)bForImage ForThumb:(BOOL)bForThumb{
    NSMutableArray* pRet = [[NSMutableArray alloc] init];
    NSArray* pList =    bForImage?_imageList:_videoList;
    if(bForThumb){
        for(ACNoteContentImageOrVideo* pContent in pList){
            [pRet addObject:pContent.thumbResourceID];
        }
    }
    else{
        for(ACNoteContentImageOrVideo* pContent in pList){
            [pRet addObject:pContent.resourceID];
        }
    }
    return pRet;
}

-(NSDictionary *)getNoteMessagePostDict{
/*
 "elements" : [
 {
 "type" : "description", //还可以为"description", "image", "audio", "video", "location", "website"
 "text" : "文字内容"
 }，
 {
 "type" : "image" | "audio" | "video", //还可以为"description", "image", "audio", "video", "location", "website"
 "thumb" : "{客户端缩略图ID}", //上传后会被替换成服务器端ResourceId
 "src" : "{客户端资源ID}"
 }，
 {
 "type" : "location", //还可以为"description", "image", "audio", "video", "location", "website"
 "la" : 23.123213, //latitude
 "lo" : 24.3432432, //longitude
 "name" : "地名",
 "address" : "地址"
 }，
 {
 "type" : "website", //还可以为"description", "image", "audio", "video", "location", "website"
 "link" : "http://www.google.com",
 "title" : "Google",
 "icon" : "http://www.google.com/1.png",
 "desp" : "最好的搜索引擎",
 }，
 ] */
    
    
    NSMutableArray *pageArray = [NSMutableArray array];
    
    //text
    [pageArray addObject:[self postDict]];

    //image
/*
 {
 "type" : "image" | "audio" | "video", //还可以为"description", "image", "audio", "video", "location", "website"
 "thumb" : "{客户端缩略图ID}", //上传后会被替换成服务器端ResourceId
 "src" : "{客户端资源ID}"
 }，
 */
    for(ACNoteContentImageOrVideo* imgPage in _imgs_Videos_List){
        NSDictionary *pageDic = [NSDictionary dictionaryWithObjectsAndKeys:imgPage.bIsImage?ACMessageType_image:ACMessageType_video,kType,[NSString stringWithFormat:@"{%@}",imgPage.resourceID],kSrc,[NSString stringWithFormat:@"{%@}",imgPage.thumbResourceID],kThumb, nil];
        [pageArray addObject:pageDic];
    }
    
    if(_location){
        [pageArray addObject:[_location postDict]];
    }
    
    if(_link){
        [pageArray addObject:[_link postDict]];
    }
      
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys:pageArray,@"elements",nil],@"note",nil];
}



-(void)setcategoryIDForWallBoard:(NSString*)categoryID{
    _categoryIDForWallBoard =   categoryID?categoryID:@"";
}

-(void)addImageOrVideo:(ACNoteContentImageOrVideo*)pContent{
    if(pContent){
        [(pContent.bIsImage?_imageList:_videoList) addObject:pContent];
        [_imgs_Videos_List addObject:pContent];
    }
}

-(void)delImageOrVideo:(ACNoteContentImageOrVideo*)pContent{
    [(pContent.bIsImage?_imageList:_videoList) removeObject:pContent];
    [_imgs_Videos_List removeObject:pContent];
}


-(void)setForASIFormDataRequest:(ASIFormDataRequest*)request{   //为上传数据准备request
    
    for(ACNoteContentImageOrVideo* page in _imgs_Videos_List){
        [request setFile:[ACAddress getAddressWithFileName:page.resourceID fileType:page.acFileType isTemp:NO subDirName:nil] forKey:page.resourceID];
        
        [request setFile:[ACAddress getAddressWithFileName:page.thumbResourceID fileType:page.acFileType isTemp:NO subDirName:nil] forKey:[page.resourceID stringByAppendingString:@"_s"]];
    }
}

-(void)sendSuccessWithResponseDic:(NSDictionary*)responseDic  forWallBoard:(BOOL)forWallBoard{
    
    NSDictionary *idmapDic = [responseDic objectForKey:kIdmap];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *key in [idmapDic allKeys]){
        
        for (ACNoteContentImageOrVideo *page in _imgs_Videos_List){
            
            enum ACFile_Type  pageFileType = page.acFileType;
            
            if ([page.resourceID isEqualToString:key]){
                
                page.resourceID = [idmapDic objectForKey:key];
                
               
                NSString *sourcePath = [ACAddress getAddressWithFileName:[key stringByAppendingString:@"_m"] fileType:pageFileType  isTemp:NO subDirName:nil];
                
                if ([fileManager fileExistsAtPath:sourcePath]){
                    
                    //全屏图名字替换成大图名
                    NSString *objectPath = [ACAddress getAddressWithFileName:page.resourceID fileType: pageFileType isTemp:NO subDirName:nil];
                    
                    if ([fileManager fileExistsAtPath:sourcePath] && ![fileManager fileExistsAtPath:objectPath])
                    {
                        [fileManager moveItemAtPath:sourcePath toPath:objectPath error:nil];
                    }
                    
                    //原图删除
                    sourcePath = [ACAddress getAddressWithFileName:key fileType: pageFileType isTemp:NO subDirName:nil];
                    
                    if ([fileManager fileExistsAtPath:sourcePath])
                    {
                        [fileManager removeItemAtPath:sourcePath error:nil];
                    }
                }
                else
                {
                    sourcePath = [ACAddress getAddressWithFileName:key fileType: pageFileType isTemp:NO subDirName:nil];
                    
                    NSString *objectPath = [ACAddress getAddressWithFileName:page.resourceID fileType: pageFileType isTemp:NO subDirName:nil];
                    if ([fileManager fileExistsAtPath:sourcePath] && ![fileManager fileExistsAtPath:objectPath])
                    {
                        [fileManager moveItemAtPath:sourcePath toPath:objectPath error:nil];
                    }
                }
                continue;
            }
            
            if ([page.thumbResourceID isEqualToString:key]){
                
                page.thumbResourceID = [idmapDic objectForKey:key];
                
                NSString *sourcePath = [ACAddress getAddressWithFileName:key fileType: pageFileType isTemp:NO subDirName:nil];
                
                NSString *objectPath = [ACAddress getAddressWithFileName:page.thumbResourceID fileType: pageFileType isTemp:NO subDirName:nil];
                NSFileManager *fileManager = [NSFileManager defaultManager];
                if ([fileManager fileExistsAtPath:sourcePath] && ![fileManager fileExistsAtPath:objectPath])
                {
                    [fileManager moveItemAtPath:sourcePath toPath:objectPath error:nil];
                }
            }
        }
    }
    
    if(!forWallBoard){
        /*
          NSDictionary *idmapDic = [responseDic objectForKey:kIdmap];
         "note" : {
            "id" : "549a6716036492547ea5f336",
            "createTime" : 1419405078031,
            "updateTime" : 1419405078031
         }   
         */
        
        NSDictionary *noteDic = [responseDic objectForKey:@"note"];
        if(noteDic){
            self.id         = [noteDic objectForKey:@"id"];
            self.createTime = [[noteDic objectForKey:FIELD_CREATETIME] longLongValue];
            self.updateTime = [[noteDic objectForKey:FIELD_UPDATETIME] longLongValue];
            self.creator    =   [ACUser myself];
        }
        
        [ACUtility postNotificationName:kNetCenterNotes_Note_Upload_Success_Notifition object:self];
    }
}

//NOTE_MESSAGE_FIELD_ADDRESS
@end


@implementation ACNoteCommentBase

-(id)initWithDict:(NSDictionary*)pDict{
    self = [super initWithDict:pDict];
    if(self){
        [self setCommentDataFromDict:pDict];
    }
    return self;
}


-(void)setCommentDataFromDict:(NSDictionary*)pDict{
    NSAssert(ACNoteComment_Type==[[pDict objectForKey:FIELD_TYPE] intValue],@"ACNoteComment 错误");
    _noteId =   [pDict objectForKey:@"nid"];
    /*   NSArray* referUsersDicts =   [pDict objectForKey:FIELD_REFERUSERS];
     
     if(referUsersDicts.count){
     NSMutableArray* referUsers =  [[NSMutableArray alloc] init];
     for(NSDictionary* pUserDict in referUsersDicts){
     ACUser* pUser = [[ACUser alloc] init];
     [pUser setUserDic:pUserDict];
     [referUsers addObject:pUser];
     }
     _referUsers =   referUsers;
     }*/
}

-(NSString*)contentForCopy{
    return super.content;
}


@end


@implementation ACNoteCommentReply

-(id)initWithDict:(NSDictionary*)pDict{
    self = [super initWithDict:pDict];
    if(self){
        NSDictionary* pReply = pDict[@"reply"];
        _rcun =   pReply[@"rcun"];
//        if(_rcun&&([ACUser isMySelf:pReply[@"rcuid"]])){
//            _rcun = nil; //是自己不显示内容
//            //有名字并且不是自己
////            self.content = [NSString stringWithFormat:@"+%@ %@",pRcun,self.content];
//        }
    }
    return self;
}

-(NSString*)content{
    if(_rcun.length){
         return [NSString stringWithFormat:@"+%@ %@",_rcun,super.content];
    }
    return super.content;
}


+(NSMutableArray<ACNoteCommentReply*>*) loadReplysWithDict:(NSDictionary*)pDict{ //加载包含多个ACNoteCommentReply
    NSMutableArray* ret = [[NSMutableArray alloc] init];
    NSArray* pReplys =   [pDict objectForKey:@"comments"];
    for(NSDictionary* pDict in pReplys){
        ACNoteCommentReply *pReply = [[ACNoteCommentReply alloc] initWithDict:pDict];
        if(pReply){
            [ret addObject:pReply];
        }
    }
    return ret;
}
@end


@implementation ACNoteComment

-(instancetype)init{
    self = [super init];
    _loadedCommentReplys = [NSMutableArray new];
    return self;
}

-(id)initWithDict:(NSDictionary*)pDict{
    self = [super initWithDict:pDict];
    if(self){
        _commentReplyAllCount = [[pDict objectForKey:FIELD_COMMENTNUMBER] integerValue];
        _loadedCommentReplys = [ACNoteCommentReply loadReplysWithDict:pDict];
        //如果初始化加载超过1个，需要排序，服务器给的是从新到旧，而显示需要从旧到新
    }
    return self;
}

-(NSString*)contentForNotify{
    return [NSString stringWithFormat:@"%@:%@",self.creator.name,super.content];
}


-(NSDictionary *)getPostDictWithReply:(ACNoteCommentBase*)pReply{ //发送的信息
    NSDictionary* pReplyPostDict = nil;
    if(pReply){
//        NSString* rcid =    self.id;
//        NSString* rcuid =   self.creator.userid;
//        NSString* pcid =    pReply.id;
//        NSString* pcuid =   pReply.creator.userid;
        
//        if(nil==pReply){
//            pcid =    rcid;
//            pcuid =   rcuid;
//        }
        
        pReplyPostDict =    @{@"pcid":self.id,
                              @"pcuid":self.creator.userid,
                              @"rcid":pReply.id,
                              @"rcuid":pReply.creator.userid};
        
    }
    
    NSMutableArray *pageArray = [NSMutableArray array];
    //text
    [pageArray addObject:[self postDict]];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:pageArray,@"elements",pReplyPostDict,@"reply",nil];
}

-(void)sendCommentSuccessWithResponseDic:(NSDictionary*)responseDic{
    NSDictionary* comment = [responseDic objectForKey:@"comment"];
    [super setDataFromDict:comment];
    [self setCommentDataFromDict:comment];
    //    [ACUtility postNotificationName:kNetCenterNotes_Comment_Upload_Notifition object:self];
}
-(void)sendReplySuccessWithResponseDic:(NSDictionary*)responseDic{ //发送成功
    ACNoteCommentReply* pReply = [[ACNoteCommentReply alloc] initWithDict:[responseDic objectForKey:@"comment"]];
    if(pReply){
        _commentReplyAllCount ++;
        NSAssert(_loadedCommentReplys,@"_loadedCommentReplys");
        [_loadedCommentReplys addObject:pReply];
        self.updateTime =   pReply.createTime;
        self.hightInList = 0; //需要重新计算
    }
}

-(void)removeReply:(ACNoteCommentReply*)pRepy{ //删除指定的回复
    [_loadedCommentReplys removeObject:pRepy];
    _commentReplyAllCount --;
    self.hightInList = 0; //需要重新计算
}

-(void)moreRepliesLoaded:(NSArray*)array{
    
    [_loadedCommentReplys addObjectsFromArray:array];
    
    if(ACNoteCommentReply_LoadMore_MaxCount>array.count){
        _commentReplyAllCount = _loadedCommentReplys.count;
    }
    
    //从旧到新排序
    [_loadedCommentReplys sortUsingComparator:^NSComparisonResult(ACNoteCommentReply*  _Nonnull obj1, ACNoteCommentReply*  _Nonnull obj2) {
        return obj1.createTime>obj2.createTime?NSOrderedDescending:NSOrderedAscending;
    }];
    self.hightInList = 0; //需要重新计算高度
}

@end


@implementation ACWallBoard_Message


#define kPage       @"page"

#define kCat        @"cat"

#define kDescripation   @"description"
#define kImage          @"image"
#define kVideo          @"video"
#define kLocation       @"location"

#define kText           @"text"
#define kSrc            @"src"
#define kCat            @"cat"
#define kDescription    @"description"
#define kLocation       @"location"
#define kAddress        @"address"
//#define kTopic          @"topic"
#define kThumb          @"thumb"
#define kPage           @"page"

#define kCreateTime     @"createTime"


#define kHeight         @"height"

-(instancetype)init{
    self = [super init];
    if(self){
        _messageContent =   [[ACNoteMessage alloc] init];
        _messageContent.categoryIDForWallBoard = @"";
    }
    return self;
}

+(instancetype) createWallBoardMessageFormNoteMessage:(ACNoteMessage*)messageContent topicEnitity:(ACTopicEntity *)topicEntity{
    ACWallBoard_Message* pRet = (ACWallBoard_Message*)[ACMessage createMessageWithMessageType:ACMessageType_wallBoard topicEnitity:topicEntity messageContent:nil sendMsgID:nil location:nil];
    NSAssert(messageContent.categoryIDForWallBoard,@"categoryIDForWallBoard Error");
    pRet.messageContent =   messageContent;
    messageContent.createTime =   pRet.createTime;
    return pRet;
}


-(NSDictionary *)getContentDicIsNeedHeight:(BOOL)isNeedHeight
{
    NSMutableDictionary *postDic = [NSMutableDictionary dictionary];
   
    ACNoteMessage* pTempNoteMsg =   _messageContent;

    NSAssert(pTempNoteMsg.categoryIDForWallBoard,@"categoryIDForWallBoard Error");
    
    [postDic setObject:[NSDictionary dictionaryWithObjectsAndKeys:pTempNoteMsg.categoryIDForWallBoard,kCat, nil] forKey:kTopic];
    
    NSMutableArray *pageArray = [NSMutableArray array];
    if ([pTempNoteMsg.content length] > 0)
    {
        NSDictionary *descDic = [NSDictionary dictionaryWithObjectsAndKeys:kDescription,kType,pTempNoteMsg.content,kText, nil];
        [pageArray addObject:descDic];
    }
    
    if (pTempNoteMsg.location)
    {
        NSDictionary *locDic = [NSDictionary dictionaryWithObjectsAndKeys:kLocation,kType,[NSNumber numberWithDouble:pTempNoteMsg.location.Location.latitude],kLa,[NSNumber numberWithDouble:pTempNoteMsg.location.Location.longitude],kLo,pTempNoteMsg.location.address,kAddress, nil];
        [pageArray addObject:locDic];
    }
    
    for(ACNoteContentImageOrVideo* imgPage in pTempNoteMsg.imgs_Videos_List){
        NSDictionary *pageDic = [NSDictionary dictionaryWithObjectsAndKeys:imgPage.bIsImage?ACMessageType_image:ACMessageType_video,kType,[NSString stringWithFormat:@"{%@}",imgPage.resourceID],kSrc,[NSString stringWithFormat:@"{%@}",imgPage.thumbResourceID],kThumb,isNeedHeight?[NSNumber numberWithFloat:imgPage.height]:nil,kHeight, nil];
        [pageArray addObject:pageDic];
    }
    
    
    [postDic setObject:pageArray forKey:kPage];
    return postDic;
}

-(void) setContentFromDict:(NSDictionary *)contentDic{
    if(nil==contentDic){
        return;
    }
    
    ACNoteMessage* pTempNoteMsg =   _messageContent;
    
    pTempNoteMsg.categoryIDForWallBoard = [[contentDic objectForKey:kTopic] objectForKey:kCat];
    pTempNoteMsg.createTime =   self.createTime;
    
    NSArray *pageArray = [contentDic objectForKey:kPage];
    for (NSDictionary *dic in pageArray){
        NSString *type = [dic objectForKey:kType];
        if ([type isEqualToString:kDescripation]){
            pTempNoteMsg.content = [dic objectForKey:kText];
            continue;
        }
        
        if ([type isEqualToString:kLocation]){
            pTempNoteMsg.location = [[ACNoteContentLocation alloc] init];
            pTempNoteMsg.location.location = CLLocationCoordinate2DMake([[dic objectForKey:kLa] doubleValue], [[dic objectForKey:kLo] doubleValue]);
            pTempNoteMsg.location.address = [dic objectForKey:kAddress];
            continue;
        }
        
        if ([type isEqualToString:kImage] || [type isEqualToString:kVideo]){
            
            ACNoteContentImageOrVideo* pCont = [[ACNoteContentImageOrVideo alloc] initForImage:[type isEqualToString:kImage]];
            
            NSString *src = [dic objectForKey:kSrc];
            if ([src length] > 2){
                pCont.resourceID = [src substringWithRange:NSMakeRange(1, [src length]-2)];
            }
            
            NSString *thumb = [dic objectForKey:kThumb];
            if ([thumb length] > 2){
                pCont.thumbResourceID = [thumb substringWithRange:NSMakeRange(1, [thumb length]-2)];
            }
            NSNumber *height = [dic objectForKey:kHeight];
            if (height){
                pCont.height = [height floatValue];
            }
            
            [pTempNoteMsg addImageOrVideo:pCont];
        }
    }
}

-(void)sendSuccessWithResponseDic:(NSDictionary*)responseDic{
    ACNoteMessage* pTempNoteMsg =   _messageContent;
    ACMessage*  pACMessage = self;
    
    pACMessage.createTime = pTempNoteMsg.createTime = [[responseDic objectForKey:kCreateTime] doubleValue];
    [pTempNoteMsg sendSuccessWithResponseDic:responseDic forWallBoard:YES];
    
    NSDictionary *postDic = [self getContentDicIsNeedHeight:YES];
    pACMessage.content = [postDic JSONString];
    
    [ACMessageDB saveMessageToDBWithMessage:pACMessage];
    
    if ([ACDataCenter shareDataCenter].wallboardTopicEntity)
    {
        //保存noteMessage成功后修改wallboard的lastestMessageTime,保存数据库，allEntityArray重新排序
        [ACDataCenter shareDataCenter].wallboardTopicEntity.lastestMessageTime = pACMessage.createTime;
        [ACTopicEntityDB saveTopicEntityToDBWithTopicEntity:[ACDataCenter shareDataCenter].wallboardTopicEntity];
        [ACTopicEntityEvent UpdateEntityToArray:[ACDataCenter shareDataCenter].allEntityArray entity:[ACDataCenter shareDataCenter].wallboardTopicEntity];
    }
    
    [ACUtility postNotificationName:kNetCenterNotes_Note_Upload_Success_Notifition object:pACMessage];
    ITLog(@"ACFile_Type_SendWallboard 上传完成");
}

-(void)setForASIFormDataRequest:(ASIFormDataRequest*)request{
    [_messageContent setForASIFormDataRequest:request];
}



@end


