//
//  ACNetCenter.h
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-28.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACConfigs.h"
#import "ACChatNetCenter.h"
#import "Reachability.h"
#import "ASIHTTPRequest.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "ACSuit.h"
#import "JSONKit.h"


//extern NSString * const acuCom_Server;
//extern NSString * const login_Server;
//extern NSString * const acuCom_Sticker_Host;


//#define kUserLoginInputDomain   @"LoginInputDomain" //客户端使用,已经停止使用domain了

#define kUserProfileInfo      @"user_profile" //用户配置信息
#define kAccount              @"account"
#define kAccount_debug        @"account_debug"  //用于保存Debug的Account信息
#define kPwd            @"pwd"
#define kPwd_Auto_login @"showPwdInLogin"
#define kPwd_Auto_login_Ver @"showPwdInLogin_Ver"
//#define kAcuComTcpInfo  @"tcp"
#define kAcuComWssInfo  @"wss"
#define kAcuComServer   @"acuComServer"
#define kDomain         @"domain"
#define kUserID         @"userid"
#define kUser           @"user"
#define kCookie         @"Cookie"
#define kCookieObject   @"CookieObject"
#define kCode           @"code"
#define kIcon           @"icon"
#define kDeviceToken    @"deviceToken"
#define kName           @"name"
#define kDescription    @"description"
#define KWidth          @"width"
#define KHeight         @"height"

#define kUserGroups     @"userGroups"
#define kGroupID        @"groupID"

#define kMsgList        @"msgList"
#define kIsLoadNew      @"isLoadNew"

#define kProgress       @"progress"

#define kStickerDirFileName @"stickerDir.json"

#define REQUEST_TOPIC_MAPPING_ROOT [NSString stringWithFormat:@"%@%@",[[ACNetCenter shareNetCenter] acucomServer],@"/rest/apis/chat/"]
//#define REQUEST_URL_MAPPING_ROOT [NSString stringWithFormat:@"%@%@",[[ACNetCenter shareNetCenter] acucomServer],@"/rest/apis/url/"]

#define kSyncDataJsonName @"syncData.json"

#define kDownloadSuitList   @"kDownloadSuitList"


#define kSuit               @"suit"
#define kSuitID             @"suitID"

#define kSetCid             @"set-cid"
#define kCid                @"cid"
#define kCFBundleVersion    @"CFBundleVersion"
#define kCFBundleVersion_Old @"CFBundleVersion_old"
 


#define kAclDomain      @"acldomain"
#define kS              @"s"
#define kAclSid         @"aclsid"
#define kAclTerminal    @"aclterminal"

enum ResponseCodeType
{
    ResponseCodeType_Nomal = 1,
    ResponseCodeType_SERVER_NOUSERINSERVER_CODE = 57, //ResponseCodeType_LoginFailed = 57,//自动登录失败返回登录页面,服务器没有这个账号
    ResponseCodeType_APPNOTCONECTTED_ERROR_CODE = 600,

    ResponseCodeType_LoginServerBusy = 1142,//Server is busy now, please login later
    ResponseCodeType_SessionInvalidStart = 4000,//会话失效，自动重新登录start
    ResponseCodeType_SessionInvalidStop = 5000,//重新登录stop
    
    
    ResponseCodeType_SERVER_LOGINFROMOTHERDEVICE_CODE = 1060,//ResponseCodeType_SessionClosed = 1060,//另一设备登录此账号，返回登录页
    ResponseCodeType_ERROR_USERID_NOT_EXIST = 1088, //Cannot find user id
    
//    ResponseCodeType_ChannelClosed = 1202,//轮询返回，进后台后关闭,return不做处理
    ResponseCodeType_ERRORCODE_SERVER_UNAVAILABLE = 503,
    ResponseCodeType_UNVALUABLESERVER_NEEDRELOGIN = 4001,
    ResponseCodeType_ERROR_CLIENT_NOT_AUTHORISED = 1199,
    ResponseCodeType_ERROR_FIRM_SUSPENDED = 5211,
    ResponseCodeType_ERROR_FIRM_USER_NOT_EXIST = 5212,
    ResponseCodeType_ERROR_USER_NOT_EXIST = 5196,
    ResponseCodeType_ERROR_USERLOGIN_CLIENT_NOT_AUTHORISED = 1200,//用户未授权
    ResponseCodeType_SERVER_PASSWORDCHANGED_CODE = 1220,
    ResponseCodeType_Reconnecting = 1226,//断网重连，多线程同一channel
    
    ResponseCodeType_Note_Deleted = 1239, //当code等于1239时， Note不存在
    
    ResponseCodeType_ShareLocation_End =  1400, //位置共享结束
    
    ResponseCodeType_ERROR_AUTHORITYCHANGED_FAILED = 1248, //服务器增加错误代码 1248，客户端收到此代码时，表明自己提交的admin权限的请求已经失败，原因是当前身份已经不是admin。客户端显示随1248一起返回的文字，并获取新的权限，并重新绘制界面。
};

/*
if(e.getCode() == Runtime.SERVER_NOUSERINSERVER_CODE
   || e.getCode() == Runtime.ERROR_FIRM_SUSPENDED
   || e.getCode() == Runtime.ERROR_FIRM_USER_NOT_EXIST
   || e.getCode() == Runtime.ERROR_USER_NOT_EXIST
   || e.getCode() == Runtime.ERROR_USERLOGIN_CLIENT_NOT_AUTHORISED
   || e.getCode() == Runtime.ERROR_CLIENT_NOT_AUTHORISED) {
    DataUtil.errorAppearNeedTurn2Login(context.getString(R.string.server_nouser_error));
    ((HailStormService)context).terminate();
}
*/

enum HttpCodeType
{
    HttpCodeType_ServerUpdate = 503,//服务器升级,找不到server，自动重新登录分配server
    HttpCodeType_ServerError = 500,
    HttpCodeType_NetworkError = 502,
    HttpCodeType_Success = 200,//成功
};

enum requestMethodType
{
    requestMethodType_Get,//select
    requestMethodType_Post,//add
    requestMethodType_Put,//update
    requestMethodType_Delete,//delete
};

//enum loopInquireStatus
//{
//    loopInquireStatus_ing,
//    loopInquireStatus_close,
//};

enum LoopInquireState   //
{
    LoopInquireState_notConnected,
    LoopInquireState_Connecting,
    LoopInquireState_synchronizing,
    LoopInquireState_synchronized,
};

extern NSString * const kNetCenterLoginSuccRSNotifation;
extern NSString * const kNetCenterLoginFailRSNotifation;
extern NSString * const kNetCenterLogoutNotifation;
extern NSString * const kNetCenterSyncFinishNotifation;
extern NSString * const kNetCenterGetContactPersonRootListNotifation;
extern NSString * const kNetCenterGetContactPersonGroupListNotifation;
extern NSString * const kNetCenterGetContactPersonSingleListNotifation;
extern NSString * const kNetCenterCreateGroupChatNotifation;
extern NSString * const kNetCenterGetContactPersonSearchListNotifation;
extern NSString * const kNetCenterGetChatMessageNotifation;
extern NSString * const kNetCenterDownloadVideoSuccessNotifation;
extern NSString * const kNetCenterDownloadFileSuccessNotifation;
extern NSString * const kNetCenterDownloadStickerSuccessNotifation;
extern NSString * const kNetCenterDownloadAudioSuccessNotifation;
extern NSString * const kNetCenterGetParticipantsNotifation;
extern NSString * const kNetCenterAddParticipantNotifation;
extern NSString * const kNetCenterUpdateTopicEntityInfoNotifation;
extern NSString * const kNetCenterUpdateUrlEntityInfoNotifation;
extern NSString * const kNetCenterGetReadCountNotifation;
extern NSString * const kNetCenterGetSingleReadSeqNotifation;
extern NSString * const kNetCenterGetHadReadListNotifation;
extern NSString * const kNetCenterStickerDirJsonRecvNotifation;
extern NSString * const kNetCenterStickerZipDownloadSuccNotifation;
extern NSString * const kNetCenterSearchMessageNotifation;
extern NSString * const kNetCenterSearchNoteNotifation;
extern NSString * const kNetCenterSearchUserNotifation;
extern NSString * const kNetCenterSearchUserGroupNotifation;
//extern NSString * const kNetCenterSearchHighLightNotifation;
extern NSString * const kNetCenterSearchCountNotifation;
extern NSString * const kNetCenterResponseCodeErrorNotifation;
extern NSString * const kNetCenterChangePasswordNotifation;
extern NSString * const kNetCenterTopicEntityDeleteNotifation;
extern NSString * const kNetCenterNetworkFailNotifation;
extern NSString * const kNetCenterGetReadCountFailNotifation;
extern NSString * const kNetCenterGetReadSeqFailNotifation;
extern NSString * const kNetCenterGetCategoriesNotifation;
extern NSString * const kNetCenterGetSuitsOfCategoryNotifation;
extern NSString * const kNetCenterGetUserOwnStickersNotifation;
extern NSString * const kNetCenterRemoveUserOwnStickerNotifation;
extern NSString * const kNetCenterAddAndSuitDownloadNotifation;
extern NSString * const kNetCenterSuitDownloadNotifation;
extern NSString * const kNetCenterDownloadStickerNotifation;
extern NSString * const kNetCenterGetAllSuitsNotifation;
extern NSString * const kNetCenterSuitDeleteNotifation;
extern NSString * const kNetCenterGetSuitInfoNotifition;
extern NSString * const kNetCenterStickerSortNotifition;
extern NSString * const kNetCenterSuitProgressUpdateNotifition;
extern NSString * const kNetCenterErrorAuthorityChangedFailed_1248;

extern NSString * const kNetCenterWebRTC_Notifition;
#define kNetCenterWebRTC_Notifition_type    @"type"
#define kNetCenterWebRTC_Notifition_info    @"info"

@class ACLocationAlert;
@class ASIHTTPRequest;
@class ACNoteMessage;
@class ACNoteContentImageOrVideo;
@class ACBaseEntity;
@class ACTopicEntity;

@interface ACNetCenter : NSObject <UIAlertViewDelegate>
{
    BOOL        _isLogoutDeleteLoop;
    long        _eventCounter;
//好像没用    CTTelephonyNetworkInfo  *_networkInfo;
    NSMutableArray          *_nowDownloadingWithProgress; //当前下载的信息，包含进度条
    NSMutableArray          *_nowUsedASIHTTPRequests;
    NSMutableArray          *_stickerDownloadingArray;
    NSString *_acucomServer;
//    NSString *_accountsServer;
    NSString *_login_Server;
    
    NSString*   _login_ServerDefault; //缺省
//    int         _nDebugType; // 0:不调试 1:http 2:https
    
    
    dispatch_queue_t   _loopInquireGCD;
    NSTimeInterval  _lastLoopInquireTI;//上一次轮询的时间戳
//    BOOL            _loopInquireUseTcp; 暂不使用
    int             _loopInquireUseTcpConnectRetryCount; //重连连接次数
    NSString*       _loopInquireTcpServer;
    NSInteger       _loopInquireTcpTickTimeS; //心跳间隔(秒)
#ifndef ACNetCenter_UseWebSocket
    //    NSData*         _loopInquireTcpPkgEnd;  //包结束标志 "=end="
    //    NSInteger       _loopInquireTcpServerPort;
    //    NSData*         _loopInquireTcpTickString; //NoUse
    //    NSString*       _loopInquireTcpPWD;
    //    NSMutableData*  _loopInquireTcpReadedData;
#endif
    
}

+(ACNetCenter *)shareNetCenter;
+(NSString*) urlHead_Chat;    //[acucomServer]/rest/apis/chat
+(NSString*) urlHead_ChatWithTopicID:(NSString*)pTopicID; //[acucomServer]/rest/apis/chat/[topicID]
+(NSString*) urlHead_ChatWithTopic:(ACBaseEntity*)pTopic; //[acucomServer]/rest/apis/chat/[pTopic.entityID]
-(NSString *) acucomServer;     //数据服务器
//-(NSString *) accountsServer;   //
-(NSString *) loginServer;      //登录服务器
//-(void) setAccountsServer: (NSString *) accountServerStr;
//-(void) setAcuServer: (NSString *) acuServerStr;
-(void) setLoginServer:(NSString *) loginServerStr;


@property (nonatomic,strong) ACChatNetCenter    *chatCenter;

@property (nonatomic) UIViewController          *createTopicEntityVC;//当前创建新聊天组的VC，用来确认哪一个VC执行对应的创建成功方法
//@property (strong, nonatomic) Reachability      *networkRech;
@property (nonatomic) NetworkStatus             previousStatus;
@property (nonatomic) BOOL                      bShowDisconnectStatInfo; //显示断开状态
@property (nonatomic) BOOL                      isForeground;//loopInquire需要判断前台
//@property (nonatomic) NSTimeInterval            lastLoopInquireTI;//上一次轮询的时间戳
@property (nonatomic) BOOL                      backgrounLoopInquireClose;
@property (nonatomic) BOOL                      isFromUILogin; //是否是从UI登录
//@property (nonatomic) enum loopInquireStatus    loopInquireStatus;
@property (nonatomic) enum LoopInquireState    loopInquireState;
@property (nonatomic) ASIHTTPRequest            *sendNoteOrWallboardRequest;
//@property (nonatomic) enum LoginState           loginState;
@property (nonatomic,strong) NSString           *cancelID;//通道ID,多线程调用时可区分是否同一设备
@property (nonatomic,strong) NSMutableDictionary    *suitDownloadDic;



//自动登录
-(void)autoLoginDelay:(int)nDelay;
-(void)autoLoginForAppLaunch; //程序启动时自动登录

//设置本地调试, 0:不调试 1:http 2:https
-(void)setLocalDebug:(int)nDebugType;

//登录服务器
-(void)loginAcucomServerWithAccount:(NSString *)account
                                pwd:(NSString *)pwd
                             userLoginInputDomain:(NSString *)userLoginInputDomain;


//loopInquire失败后延迟重连
-(void)delayAfterLoopInquire;



//放弃当前全部套接口
-(void)cancelNowNetCall;


//获取联系人根列表
-(void)getContactPersonRootList;

//获取联系人组子列表
-(void)getContactPersonSubGroupListWithGroupID:(NSString *)groupID withOffset:(int)offset withLimit:(int)limit;

//获取联系人组子列表包括CR
-(void)getContactPersonSubGroupListWithGroupID:(NSString *)groupID withOffset:(int)offset withLimit:(int)limit withCR:(NSString*)pCR;


//获取联系人单个用户列表
-(void)getContactPersonSinglePersonListWithGroupID:(NSString *)groupID withOffset:(int)offset withLimit:(int)limit withCR:(NSString*)pCR;

//根据关键词获取联系人列表
#define searchContactListWithKey_FuncType_Nouse 0
#define searchContactListWithKey_FuncType_GetCount 1    //取得搜索结果数
#define searchContactListWithKey_FuncType_GetUserForName 2    //取得搜索用户name的结果
#define searchContactListWithKey_FuncType_GetUserForAccount 3    //取得通过account搜索的结果
-(void)searchContactListWithKey:(NSString *)key withOffset:(int)offset withLimit:(int)limit withGroupIDs:(NSString *)groupIDs withCRs:(NSString*)pCRs withFunctype:(int)searchContactListWithKey_FuncType;

//创建TopicEntity聊天组
-(void)createTopicEntityWithChatType:(NSString *)chatType withTitle:(NSString *)title withGroupIDArray:(NSArray *)groupIDArray withUserIDArray:(NSArray *)userIDArray exMap:(NSDictionary *)exMap;

//获取聊天消息列表
-(void)getChatMessageListWithGroupID:(NSString *)groupID withOffset:(long)offset withLimit:(int)limit isLoadNew:(BOOL)isLoadNew isDeleted:(BOOL)isDeleted;

//发送已读回执
-(void)hasBeenReadTopicEntityWithEntityID:(NSString *)entityID withSequence:(long)sequence;

//获得fileMessage的资源url
-(NSString *)getUrlWithEntityID:(NSString *)entityID messageID:(NSString *)messageID resourceID:(NSString *)resourceID;

//为下载URL拼凑?length=%ld
+(NSString*)getdownloadURL:(NSString*)urlString withFileLength:(NSInteger)lLength;

//下载fileMessage中的文件
-(void)downloadFileWithEntityID:(NSString *)entityID messageID:(NSString *)messageID resourceID:(NSString *)resourceID progressDelegate:(NSObject*)progressDelegate fileName:(NSString *)fileName withFileLength:(long)lLength;
//下载fileMessage中得视频
-(void)downloadMoiveFileWithEntityID:(NSString *)entityID messageID:(NSString *)messageID resourceID:(NSString *)resourceID progressDelegate:(NSObject*)progressDelegate  withFileLength:(long)lLength;

//下载fileMessage中得音频
-(void)downloadAudioFileWithEntityID:(NSString *)entityID messageID:(NSString *)messageID resourceID:(NSString *)resourceID progressDelegate:(NSObject*)progressDelegate  withFileLength:(long)lLength;

//检查有进度的下载
-(void)checkDownloadingWithFileMessage:(ACFileMessage*)pFileMsg;
//-(void)cancelDownloadingWithProgress:(NSObject*)progressDelegate;

//下载Note的视频
-(void)downloadNote:(ACNoteMessage*)noteMessage VideoContent:(ACNoteContentImageOrVideo*) pVideo;

//获取参与者列表
-(void)getParticipantInfoWithEntity:(ACBaseEntity*)entify;

//添加参与者到当前组
-(void)addParticipantToCurrentEntity:(ACBaseEntity*)entify withGroupIDArray:(NSArray *)groupIDArray withUserIDArray:(NSArray *)userIDArray;

//获取topicEntity指定seqs[]的readCount
-(void)getReadCountWithSeqsArray:(NSArray *)seqsArray topicEntityID:(NSString *)topicEntityID;

//一对一聊天获取对方读到的Seq
-(void)getReadSeqWithTopicEntityID:(NSString *)topicEntityID singleChatUid:(NSString *)singleChatUid;

//获得对应seq的已读列表
-(void)getHadReadListWithTopicEntityID:(NSString *)topicEntityID seq:(long)seq;

-(void)getStickerWithStickerPath:(NSString *)stickerPath stickerName:(NSString *)stickerName messageID:(NSString *)messageID;

//得到sticker目录json
-(void)getStickerDirJson;

-(void)getStickerZipWithTitle:(NSString *)title withDelegate:(id)delegate;

//scan用，locationAlert创建之后
//-(void)uploadLocationToScan:(CLLocationCoordinate2D)coordinate locationAlert:(ACLocationAlert *)locationAlert;

//上传经纬度，用于locationAlert
//-(void)uploadLocationToLocationAlert:(ACLocationAlert *)locationAlert coordinate:(CLLocationCoordinate2D)coordinate;
-(void)uploadLocationToLocationAlert:(NSArray*)pAlertDatas;

//搜索消息或Note
-(void)searchMessage_Note:(BOOL)forNote withKey:(NSString *)key offset:(int)offset limit:(int)limit;

//搜索用户
-(void)searchUserWithKey:(NSString *)key offset:(int)offset limit:(int)limit forAccount:(BOOL)bForAccount;

//搜索用户组
-(void)searchUserGroupWithKey:(NSString *)key offset:(int)offset limit:(int)limit;

//搜索高亮显示关键字
+(void)searchHighLightWithKey:(NSString *)key topicEntityID:(NSString *)topicEntityID withBlock:(void (^)(NSArray *highlights)) pFunc;

//获得搜索数量
-(void)getSearchCountWithKey:(NSString *)key;

-(void)changePassword:(NSString *)password;

//获得分类
-(void)getCategories;

//获得某个分类下的sticker套装
-(void)getSuitsOfCategoryID:(NSString *)categoryID withOffset:(int)offset withLimit:(int)limit;

//获得所有sticker套装
-(void)getAllSuitsWithOffset:(int)offset withLimit:(int)limit;

//获得用户自己的stickers
-(void)getUserOwnStickers;

//根据suitID删除自己的sticker套装
-(void)removeUserOwnStickerWithSuitID:(NSString *)suitID;

//增加sticker套装到自己的stickers
-(void)addStickerSuitToMyStickersAndDownloadWithSuitID:(NSString *)suitID progressDelegate:(ACSuit *)delegate;

//下载sticker套装通过suitID
-(void)downloadWithSuitID:(NSString *)suitID progressDelegate:(ACSuit *)delegate;

//下载单个sticker
-(void)downloadStickerWithResourceID:(NSString *)resourceID;

-(void)startDownloadWithFileName:(NSString *)fileNameID fileType:(uint)fileType urlString:(NSString *)urlString saveAddress:(NSString *)saveAddress tempAddress:(NSString *)tempAddress progressDelegate:(NSObject*)progressDelegate postDictionary:(NSDictionary *)postDictionary postPathArray:(NSArray *)postPathArray object:(id)object requestMethod:(int)requestMethod;

//得到requestHeader
-(NSMutableDictionary *)getRequestHeader;
//通过类型设置requestMethod
-(NSString *)getRequestMethodWithType:(int)type;




/*
 NSDictionary *responseDic = [[[request.responseData objectFromJSONData] JSONString] objectFromJSONString];
 
 int responseCode = [[responseDic objectForKey:kCode] intValue];
 if (responseCode == ResponseCodeType_Nomal)
 

dispatch_async(dispatch_get_main_queue(), ^{ 
 });
 */

//bForDelete: delete get
typedef void (^callURL_block)(ASIHTTPRequest* request,BOOL bIsFail);

+(void)callURL:(NSString*)pURLString forMethodDelete:(BOOL)bForDelete withBlock:(callURL_block) pFunc;

//forPost: post put
+(void)callURL:(NSString*)pURLString forPut:(BOOL)bForPut withPostData:(NSDictionary*)pPostData withBlock:(callURL_block) pFunc;


//登出
-(void)logOut:(BOOL)bFromUI withBlock:(callURL_block) pFunc;

//将网络返回的信息转换为JOSN对象
+(NSDictionary*)getJOSNFromHttpData:(NSData*) pData;

//处理 ERROR_AUTHORITYCHANGED_FAILED
+(void)ERROR_AUTHORITYCHANGED_FAILED_Error_Func:(NSDictionary*)pDict;

//处理服务器返回的特殊响应
-(BOOL)checkServerResponseCode:(enum ResponseCodeType) responseCode withResponseDic:(NSDictionary *)responseDic;

@end

#import "ACNetCenter+loopInquire.h"



//@interface ACDownloadUnit : NSObject

//@property (nonatomic,strong) NSString *fileNameID;
//@property (nonatomic) uint fileType;
//@property (nonatomic,strong) NSString *urlString;
//@property (nonatomic,strong) NSString *saveAddress;
//@property (nonatomic,strong) NSString *tempAddress;
//@property (nonatomic,weak) id delegate;

//@end
