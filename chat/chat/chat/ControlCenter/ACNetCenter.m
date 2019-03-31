
//
//  ACNetCenter.m
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-28.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACNetCenter.h"
#import "ASIFormDataRequest.h"
#import "ACAddress.h"
#import "OpenUDID.h"
#import "ACDataCenter.h"
#import "ACTopicEntityEvent.h"
#import "ACUrlEntityEvent.h"
#import "ACEntity.h"
#import "ACUser.h"
#import "ACMessage.h"
#import "ACParticipant.h"
#import "Reachability.h"
#import "ACMessageDB.h"
#import "ACPersonInfoViewController.h"
#import "ACReadCount.h"
#import "ACReadSeq.h"
#import "ACReadCountDB.h"
#import "ACReadSeqDB.h"
#import "ACUserDB.h"
#import "ACStickerPackage.h"
#import "ACLocationAlert.h"
#import "ACSearchDetailController.h"
#import "ACTopicEntityDB.h"
#import "ACStickerCategory.h"
#import "ACSuit.h"
#import "GZIP.h"
#import "NSString+Additions.h"
#import "ACNetCenter+Notes.h"
#import "ACNoteMessage.h"
#import "ACNetCenter+Notes.h"
#import "ACChangePasswordController.h"
#import "MMDrawerController.h"

#import "ACVideoCall.h"
#import "AcuComDebugServerDef.h"
#import "NSDate+Additions.h"


//如果需要修改密码，请修改 ACLoginViewController2中的onForgetPWD
#if TARGET_IPHONE_SIMULATOR
//    #define USE_DEBUG_SERVER_FLAG       1 //1 http 2 https 3:GChat;
#elif DEBUG
//    #define USE_DEBUG_SERVER_FLAG   1
#endif

#ifdef USE_DEBUG_SERVER_FLAG
    //  58103836@qq.com
    //
    #define USE_DEBUG_SERVER_USERNAME   @"xiaobing@aculearn.com.cn"
    #define USE_DEBUG_SERVER_PWD        @"654321"
#endif

@interface ACDownloadingWithProgressItem : NSObject{
    @public
    NSObject*           progressDelegate;
    ASIHTTPRequest*     pRequest;
}
@end

@implementation ACDownloadingWithProgressItem
@end

#define UIAlertView_tag_for_ChangePassword  100

#define ACNetCenter_TimeOutSencods  10  //网络超时时间



#define REQUEST_USERGROUP_ROOT [NSString stringWithFormat:@"%@%@",[[ACNetCenter shareNetCenter] acucomServer],@"/rest/apis/usergroup/"]

#define REQUEST_READCOUNT_URL(ID) [NSString stringWithFormat:@"%@%@%@",[[ACNetCenter shareNetCenter] acucomServer],@"/rest/apis/robot/read?id=",ID]



#define kPackage        @"package.zip"

NSString * const kNetCenterLoginSuccRSNotifation = @"kNetCenterLoginSuccRSNotifation";
NSString * const kNetCenterLoginFailRSNotifation = @"kNetCenterLoginFailRSNotifation";
NSString * const kNetCenterLogoutNotifation = @"kNetCenterLogoutNotifation";
NSString * const kNetCenterSyncFinishNotifation = @"kNetCenterSyncFinishNotifation";
NSString * const kNetCenterGetContactPersonRootListNotifation = @"kNetCenterGetContactPersonRootListNotifation";
NSString * const kNetCenterGetContactPersonGroupListNotifation = @"kNetCenterGetContactPersonGroupListNotifation";
NSString * const kNetCenterGetContactPersonSingleListNotifation = @"kNetCenterGetContactPersonSingleListNotifation";
NSString * const kNetCenterCreateGroupChatNotifation = @"kNetCenterCreateGroupChatNotifation";
NSString * const kNetCenterGetContactPersonSearchListNotifation = @"kNetCenterGetContactPersonSearchListNotifation";
NSString * const kNetCenterGetChatMessageNotifation = @"kNetCenterGetChatMessageNotifation";
NSString * const kNetCenterDownloadVideoSuccessNotifation = @"kNetCenterDownloadVideoSuccessNotifation";
NSString * const kNetCenterDownloadFileSuccessNotifation = @"kNetCenterDownloadFileSuccessNotifation";
NSString * const kNetCenterDownloadStickerSuccessNotifation = @"kNetCenterDownloadStickerSuccessNotifation";
NSString * const kNetCenterDownloadAudioSuccessNotifation = @"kNetCenterDownloadAudioSuccessNotifation";
NSString * const kNetCenterGetParticipantsNotifation = @"kNetCenterGetParticipantsNotifation";
NSString * const kNetCenterAddParticipantNotifation = @"kNetCenterAddParticipantNotifation";
NSString * const kNetCenterUpdateTopicEntityInfoNotifation = @"kNetCenterUpdateTopicEntityInfoNotifation";
NSString * const kNetCenterUpdateUrlEntityInfoNotifation = @"kNetCenterUpdateUrlEntityInfoNotifation";
NSString * const kNetCenterGetReadCountNotifation = @"kNetCenterGetReadCountNotifation";
NSString * const kNetCenterGetSingleReadSeqNotifation = @"kNetCenterGetSingleReadSeqNotifation";
NSString * const kNetCenterGetHadReadListNotifation = @"kNetCenterGetHadReadListNotifation";
NSString * const kNetCenterStickerDirJsonRecvNotifation = @"kNetCenterStickerDirJsonRecvNotifation";
NSString * const kNetCenterStickerZipDownloadSuccNotifation = @"kNetCenterStickerZipDownloadSuccNotifation";
NSString * const kNetCenterSearchMessageNotifation = @"kNetCenterSearchMessageNotifation";
NSString * const kNetCenterSearchNoteNotifation = @"kNetCenterSearchNoteNotifation";
NSString * const kNetCenterSearchUserNotifation = @"kNetCenterSearchUserNotifation";
NSString * const kNetCenterSearchUserGroupNotifation = @"kNetCenterSearchUserGroupNotifation";
//NSString * const kNetCenterSearchHighLightNotifation = @"kNetCenterSearchHighLightNotifation";
NSString * const kNetCenterSearchCountNotifation = @"kNetCenterSearchCountNotifation";
NSString * const kNetCenterResponseCodeErrorNotifation = @"kNetCenterResponseCodeErrorNotifation";
NSString * const kNetCenterChangePasswordNotifation = @"kNetCenterChangePasswordNotifation";
NSString * const kNetCenterTopicEntityDeleteNotifation = @"kNetCenterChangePasswordNotifation";
NSString * const kNetCenterNetworkFailNotifation = @"kNetCenterNetworkFailNotifation";
NSString * const kNetCenterGetReadCountFailNotifation = @"kNetCenterGetReadCountFailNotifation";
NSString * const kNetCenterGetReadSeqFailNotifation = @"kNetCenterGetReadSeqFailNotifation";
NSString * const kNetCenterGetCategoriesNotifation = @"kNetCenterGetCategoriesNotifation";
NSString * const kNetCenterGetSuitsOfCategoryNotifation = @"kNetCenterGetSuitsOfCategoryNotifation";
NSString * const kNetCenterGetUserOwnStickersNotifation = @"kNetCenterGetUserOwnStickersNotifation";
NSString * const kNetCenterRemoveUserOwnStickerNotifation = @"kNetCenterRemoveUserOwnStickerNotifation";
NSString * const kNetCenterAddAndSuitDownloadNotifation = @"kNetCenterAddAndSuitDownloadNotifation";
NSString * const kNetCenterSuitDownloadNotifation = @"kNetCenterSuitDownloadNotifation";
NSString * const kNetCenterDownloadStickerNotifation = @"kNetCenterDownloadStickerNotifation";
NSString * const kNetCenterGetAllSuitsNotifation = @"kNetCenterGetAllSuitsNotifation";
NSString * const kNetCenterSuitDeleteNotifation = @"kNetCenterSuitDeleteNotifation";
NSString * const kNetCenterGetSuitInfoNotifition = @"kNetCenterGetSuitInfoNotifition";
NSString * const kNetCenterStickerSortNotifition = @"kNetCenterStickerSortNotifition";
NSString * const kNetCenterSuitProgressUpdateNotifition = @"kNetCenterSuitProgressUpdateNotifition";
NSString * const kNetCenterErrorAuthorityChangedFailed_1248 = @"kNetCenterErrorAuthorityChangedFailed_1248";
NSString * const kNetCenterWebRTC_Notifition = @"kNetCenterWebRTC_Notifition";


#define kResult     @"result"

static ACNetCenter *_netCenter = nil;
NSString* g__pMySelfUserID = nil; //用户自己的UserID

@implementation ACNetCenter

- (id)init
{
    self = [super init];
    if (self) {
        //读取配置
    #ifndef acuCom_Server_Def
        [self setLocalDebug:NO];
    #endif
        
        _nowDownloadingWithProgress= [[NSMutableArray alloc] init];
        _nowUsedASIHTTPRequests = [[NSMutableArray alloc] initWithCapacity:10];
        _loopInquireGCD         = dispatch_queue_create("loopInquireGCD", NULL);
        _chatCenter             = [[ACChatNetCenter alloc] init];
        _previousStatus         = -1;
        _isLogoutDeleteLoop     = NO;
        _loopInquireState       = LoopInquireState_notConnected;
        _lastLoopInquireTI      = [[NSDate date] timeIntervalSince1970];

/*好像没用
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];

        _networkInfo            = [[CTTelephonyNetworkInfo alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(radioAccessChanged) name:
         CTRadioAccessTechnologyDidChangeNotification object:nil];*/
        
        _cancelID               = nil;

        _suitDownloadDic        = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#define acuCom_LocalDebug_LoginServer_https   @"https://192.168.1.185:90"
//#define acuCom_LocalDebug_AcucomServer_https  @"https://192.168.1.185"

//走代理
//#define acuCom_LocalDebug_LoginServer_http  @"https://192.168.1.155:90"
//#define acuCom_LocalDebug_AcucomServer_http @"https://192.168.1.155"

//直连

#define acuCom_LocalDebug_LoginServer_http  @"http://192.168.1.231:10050"
//#define acuCom_LocalDebug_AcucomServer_http @"http://192.168.1.231:8070"

#ifndef acuCom_LocalDebug_LoginServer_http
    #define acuCom_LocalDebug_LoginServer_http  @"http://192.168.1.168:90"
//    #define acuCom_LocalDebug_AcucomServer_http @"http://192.168.1.168"
#endif

#define GChat_LoginServer   @"https://accounts.gchat.apps.go.th"


//设置本地调试, 0:不调试 1:http 2:https
-(void)setLocalDebug:(int)nDebugType{
//    _acucomServer   =   nil; 下次登录时使用旧的acucomServer
    
#ifdef USE_DEBUG_SERVER_FLAG
    if(0==nDebugType){
        nDebugType = USE_DEBUG_SERVER_FLAG;
    }
#endif
    _login_Server   =   nil;
//    _nDebugType     =   nDebugType;
    
    if(nDebugType){
        if(1==nDebugType){
            _login_Server = acuCom_LocalDebug_LoginServer_http;
        }
        else if(3==nDebugType){
            _login_Server   =   GChat_LoginServer;
        }
        else{
            //缺省
            _login_Server   =   acuCom_LocalDebug_LoginServer_https;
        }
        _login_Server   =   [_login_Server stringByAppendingString:@"/rest/oauth/login"];
    }
    else{
//        NSMutableDictionary* dict = [[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ac_config" ofType:@"plist"]];
//        NSString* ploginServer =    [dict objectForKey:@"loginServer"];
//        if(ploginServer.length==0){
//            ploginServer =  @"http://acucom1.aculearn.com";
//        }
#ifdef acuCom_Debug_Login_Server
        _login_ServerDefault    =   [acuCom_Debug_Login_Server stringByAppendingString:@"/rest/oauth/login"];
#else
        _login_ServerDefault    =   [[[ACConfigs acOem_ConfigInfo] objectForKey:@"loginServer"] stringByAppendingString:@"/rest/oauth/login"];
#endif
    }
}

//-(NSString *) accountsServer {
//    return _accountsServer;
//}

+(NSString*) urlHead_Chat{    //[acucomServer]/rest/apis/chat/
    return [NSString stringWithFormat:@"%@/rest/apis/chat",[[self shareNetCenter] acucomServer]];
}
+(NSString*) urlHead_ChatWithTopicID:(NSString*)pTopicID{
    return [NSString stringWithFormat:@"%@/%@",[self urlHead_Chat],pTopicID];
}

+(NSString*) urlHead_ChatWithTopic:(ACBaseEntity*)pTopic{ //[acucomServer]/rest/apis/chat/[pTopic.entityID]
    return [self urlHead_ChatWithTopicID:pTopic.entityID];
}


-(NSString *) acucomServer {
#ifdef acuCom_Server_Def
    return _acucomServer != nil ? _acucomServer : acuCom_Server;
#else
    return _acucomServer;
#endif
}

-(NSString * ) loginServer {
#ifdef acuCom_Server_Def
    return _login_Server != nil ? _login_Server : login_Server;
#else
    return _login_Server != nil ? _login_Server : _login_ServerDefault;
#endif
}

//-(void) setAccountsServer: (NSString *) accountServerStr {
//    _accountsServer = accountServerStr;
//}
-(void) setAcuServer: (NSString *) acuServerStr {
    _acucomServer = acuServerStr;
}
-(void) setLoginServer:(NSString *)loginServerStr {
    _login_Server = loginServerStr;
}

+(ACNetCenter *)shareNetCenter
{
    if (_netCenter == nil)
    {
        _netCenter = [[ACNetCenter alloc] init];
    }
    return _netCenter;
}

-(void)setBackgrounLoopInquireClose:(BOOL)backgrounLoopInquireClose
{
    if (_backgrounLoopInquireClose != backgrounLoopInquireClose){
        _backgrounLoopInquireClose = backgrounLoopInquireClose;
        if (_isForeground){
            [self loopInquire];
        }
    }
}

//#define AcuCom_TCP_CfgInfo_Min_ValueCount   4
-(void)_setTcpInfoForFirstLogin:(NSDictionary*)tcpDict saveToDefault:(NSUserDefaults*)userdefault{
            //                            _loopInquireUseTcp = YES;
    
//    if(tcpDict.count>AcuCom_TCP_CfgInfo_Min_ValueCount)
    {
        _loopInquireTcpServer   =   [tcpDict objectForKey:@"host"];
//        _loopInquireTcpServerPort   = [[tcpDict objectForKey:@"port"] integerValue];
//        _loopInquireTcpPkgEnd   =   [[tcpDict objectForKey:@"eb"] dataUsingEncoding:NSUTF8StringEncoding];
        //                            _loopInquireTcpTickString   =   [[tcpDict objectForKey:@"hbc"] dataUsingEncoding:NSUTF8StringEncoding];
        _loopInquireTcpTickTimeS =   [[tcpDict objectForKey:@"hbt"] integerValue]/1000;
        
        if(_loopInquireTcpTickTimeS<10){
            _loopInquireTcpTickTimeS = 10;
        }
        _loopInquireUseTcpConnectRetryCount = 0; //重试次数
//        _loopInquireTcpPWD = [tcpDict objectForKey:@"aeskey"];
    }
    
    if(userdefault){
        [userdefault setObject:tcpDict forKey:kAcuComWssInfo];
        [userdefault setObject:_acucomServer forKey:kAcuComServer];
    }
}

-(void)_doSecondLogin{
    
    self.isFromUILogin = NO;
    [ACConfigs shareConfigs].loginState = LoginState_logined;

    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterLoginSuccRSNotifation object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kPersonInfoPutSuccessNotifation object:nil];

    _lastLoopInquireTI = [[NSDate date] timeIntervalSince1970];
    [self loopInquire];
    
    [self getStickerDirJson];
//好像没用    [self monitorReachabilityStart];
    
    //处理启动时设置的VideoCall RemoteNotification 信息
    [[ACVideoCall shareVideoCall] checkAppLanuchVideoCall];
    
    //检查新版本
    [[ACConfigs shareConfigs] newAppVersionCheckWithBlock:nil];
}

-(void)autoLoginDelay:(int)nDelayS
{
    static  BOOL    bautoLoginDelayIsRuning = NO; //避免重复
    if(bautoLoginDelayIsRuning){
        ITLogEX(@"autoLoginDelay(%d) 重复",nDelayS);
        return;
    }
    
    if(nDelayS>0){
        bautoLoginDelayIsRuning = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, nDelayS*NSEC_PER_SEC), dispatch_get_global_queue(0, 0), ^{
            bautoLoginDelayIsRuning = NO;
            [self autoLoginDelay:0];
        });
        //延时启动
        return;
    }

    bautoLoginDelayIsRuning = NO;

    //自动登录
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *account = [defaults objectForKey:kAccount_debug];
    if(account.length<6){
        account =   [defaults objectForKey:kAccount];
    }
    NSString *pwd = [defaults objectForKey:kPwd];
    
//    NSString *domain = [defaults objectForKey:kDomain];
#ifdef kUserLoginInputDomain
    NSString *userLoginInputDomain = [defaults objectForKey:kUserLoginInputDomain];
    if (account.length && pwd.length && userLoginInputDomain.length)
#else
    NSString *userLoginInputDomain = @"";
    if (account.length && pwd.length)
#endif
//    if (account.length && pwd.length && domain.length)
    {
        ITLog(@"直接登录");
        if(nDelayS<0){
            //AppLaunch登录,检查是否不需要登录
            NSDictionary* pDictForTcp = [defaults objectForKey:kAcuComWssInfo];
            if(pDictForTcp.count>1){
                _acucomServer = [defaults objectForKey:kAcuComServer];
                
                if(_acucomServer.length>5){
                    ITLogEX(@"不登录，直接访问 %@",_acucomServer);
                    NSString* pHost = [NSURL URLWithString:_acucomServer].host;
                    
                    
                    //设置Cookie
                    NSHTTPCookieStorage* pCookiStore = [NSHTTPCookieStorage sharedHTTPCookieStorage];
                    
                    [pCookiStore setCookie:[NSHTTPCookie cookieWithProperties:@{NSHTTPCookieDomain:pHost,NSHTTPCookiePath:@"/",NSHTTPCookieName:kAclSid,NSHTTPCookieValue:[defaults objectForKey:kAclSid]}]];
                    
                    [pCookiStore setCookie:[NSHTTPCookie cookieWithProperties:@{NSHTTPCookieDomain:pHost,NSHTTPCookiePath:@"/",NSHTTPCookieName:kS,NSHTTPCookieValue:[defaults objectForKey:kS]}]];
                    
                    [pCookiStore setCookie:[NSHTTPCookie cookieWithProperties:@{NSHTTPCookieDomain:pHost,NSHTTPCookiePath:@"/",NSHTTPCookieName:kAclDomain,NSHTTPCookieValue:[defaults objectForKey:kAclDomain]}]];
                    [pCookiStore setCookie:[NSHTTPCookie cookieWithProperties:@{NSHTTPCookieDomain:pHost,NSHTTPCookiePath:@"/",NSHTTPCookieName:@"aclaccount",NSHTTPCookieValue:[defaults objectForKey:kUserID]}]];
                    [pCookiStore setCookie:[NSHTTPCookie cookieWithProperties:@{NSHTTPCookieDomain:pHost,NSHTTPCookiePath:@"/",NSHTTPCookieName:kAclTerminal,NSHTTPCookieValue:@"ios"}]];
                    
//                    [NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:<#(nonnull NSHTTPCookie *)#>
                    
                    
//                    [ASIHTTPRequest setSessionCookies:[[NSMutableArray alloc] initWithArray:pCookie]];
                    [self _setTcpInfoForFirstLogin:pDictForTcp saveToDefault:nil];
                    [self _doSecondLogin];
                    
                    //设置Cooki
//                    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:<#(nonnull NSHTTPCookie *)#>
                    
                    return;
                }
            }
        }
        [[ACNetCenter shareNetCenter] loginAcucomServerWithAccount:account
                                                               pwd:pwd
                                                            userLoginInputDomain:userLoginInputDomain];
    }
    else
    {
        ITLog(@"显示LoginUI");
        [[ACConfigs shareConfigs] presentLoginVC:NO];
    }
}

-(void)autoLoginForAppLaunch{ //程序启动登录
    [self autoLoginDelay:-1];
}



//登录服务器
-(void)loginAcucomServerWithAccount:(NSString *)account pwd:(NSString *)pwd
               userLoginInputDomain:(NSString *)userLoginInputDomain{
    
    if (![ASIHTTPRequest isValidNetWork]|| //没有网络或没有deviceToken
        0==[ACConfigs shareConfigs].deviceToken.length){
        
        [ACConfigs shareConfigs].loginState = LoginState_waiting;
        if(_isFromUILogin){
#ifdef ACUtility_Need_Log
            ITLog(@"没有网络,通知LoginUI,登录失败");
            NSDictionary* pDict = nil;
            if(0==[ACConfigs shareConfigs].deviceToken.length){
                pDict = @{@"description":@"还没有取到deviceToken"};
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterLoginFailRSNotifation object:pDict ];
#else
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterLoginFailRSNotifation object:nil];
#endif
            return;
        }
        ITLog(@"没有网络,没有LoginUI,调用 delayAfterLoopInquire");
        [self delayAfterLoopInquire];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self GCDLoginAcucomServerWithAccount:account
                                          pwd:pwd
                         userLoginInputDomain:userLoginInputDomain];
    });
    
}

-(void)GCDLoginAcucomServerWithAccount:(NSString *)account
                                   pwd:(NSString *)pwd
                  userLoginInputDomain:(NSString *)userLoginInputDomain{
    
    /*
    userLoginInputDomain 内部使用
     */
    
//    NSString * domainStr = userLoginInputDomain;
    
    NSString*   account_debug = @"";
    @synchronized(self){
        ACConfigs* pACConfig = [ACConfigs shareConfigs];
        if((!_isFromUILogin)&&
           LoginState_logining==pACConfig.loginState){
            ITLog(@"没有LoginUI,重复调用");
            return;
        }
        
//        pACConfig.isSynced      =   NO;
        pACConfig.loginState    =   LoginState_logining;
        NSArray *  domanArray = [userLoginInputDomain componentsSeparatedByString:@"."];
        if(domanArray.count > 1) {
            [self setLocalDebug:0];
            userLoginInputDomain = [domanArray objectAtIndex:0];
            NSString * hostStr = [userLoginInputDomain substringFromIndex: [userLoginInputDomain length] + 1];
//            NSString * acuServerStr = [@"http://acucom." stringByAppendingString:hostStr];
//            [self setAcuServer: acuServerStr];
//            NSString * accountsServerStr = [@"http://accounts." stringByAppendingString:hostStr];
//            [self setAccountsServer:accountsServerStr];
//            NSString * loginServerStr = [[self accountsServer] stringByAppendingString:@"/rest/oauth/login"];
            NSString * loginServerStr = [NSString stringWithFormat:@"http://accounts.%@/rest/oauth/login",hostStr];
            [self setLoginServer:loginServerStr];
        }
        else {
            int nDebugType = 0;
            
            
            if(account.length>6){
                account_debug = account;
                if([[account substringToIndex:6] isEqualToString:@"debug_"]){
                    nDebugType = 1;
                    account = [account substringFromIndex:6];
                }
                else if([[account substringToIndex:7] isEqualToString:@"debug1_"]){
                    nDebugType = 1;
                    account = [account substringFromIndex:7];
                }
                else if([[account substringToIndex:7] isEqualToString:@"debug2_"]){
                    nDebugType = 2;
                    account = [account substringFromIndex:7];
                }
                else if([[account substringToIndex:6] isEqualToString:@"gchat_"]){
                    nDebugType = 3;
                    account = [account substringFromIndex:6];
                }
                else{
                    account_debug = @"";
                }
            }
            [self setLocalDebug:nDebugType];
        }
    } //@synchronized(self)
    
    //10秒后清除
 /*   dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        @synchronized(self){
            if(LoginState_logining==self.loginState){
                self.loginState = LoginState_notConnected;
            }
        }
    });
    
   */
    NSString * const acLoginUrl = [[ACNetCenter shareNetCenter] loginServer];
    
#ifdef  USE_DEBUG_SERVER_USERNAME
    account =   USE_DEBUG_SERVER_USERNAME;
    pwd     =   [ASIHTTPRequest base64forData:[USE_DEBUG_SERVER_PWD dataUsingEncoding:NSUTF8StringEncoding]];
#endif
    
    NSMutableDictionary *postDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:account,kAccount,
                                    @"ios",@"terminal",
                                    pwd,kPwd,
                                    [OpenUDID value],@"devicetoken",
                                    userLoginInputDomain,kDomain,
                                    [NSLocale preferredLanguages].firstObject,@"locale",
                                    account_debug,kAccount_debug,
                                    nil];
    
    NSString *fileName = @"login.json";
    NSString *saveAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_LoginJson isTemp:NO subDirName:nil];
    NSString *tempAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_LoginJson isTemp:YES subDirName:nil];
    ITLog(@"开始登录");
    [self startDownloadWithFileName:fileName
                           fileType:ACFile_Type_LoginJson
                          urlString:acLoginUrl
                        saveAddress:saveAddress
                        tempAddress:tempAddress
                   progressDelegate:nil
                     postDictionary:postDic
                      postPathArray:nil
                             object:nil
                      requestMethod:requestMethodType_Post];
}

//登录服务器
-(void)secondLoginAcucomServerWithCode:(NSString *)code withUserID:(NSString *)userID
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self GCDSecondLoginAcucomServerWithCode:code withUserID:userID];
    });
}

-(void)GCDSecondLoginAcucomServerWithCode:(NSString *)code withUserID:(NSString *)userID
{
 /*
  Conf.getAcuChatServer()
  + "/rest/oauth/client/authorized?code="
  + Runtime.getInstance().getRedirectCode()
  + "&u=" + Runtime.getInstance().getUserId()
  + "&t="
  + Runtime.getInstance().getTerminal()
  + "&d="
  + Runtime.getInstance().getDeviceToken()
  + "&p="
  + !isFromUILogin         true:被动登陆   //true:不是 用户自己登录
  + "&m=true"
  */
    
    NSString * const acSecondLoginUrl = [NSString stringWithFormat:@"%@/rest/oauth/client/authorized?code=%@&u=%@&t=ios&d=%@&p=%@&m=true",[[ACNetCenter shareNetCenter] acucomServer],code,userID,[[ACConfigs shareConfigs].deviceToken URL_Encode],_isFromUILogin?@"false":@"true"];
    
    NSString *fileName = @"secondLogin.json";
    NSString *saveAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_SecondLoginJson isTemp:NO subDirName:nil];
    NSString *tempAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_SecondLoginJson isTemp:YES subDirName:nil];
    [self startDownloadWithFileName:fileName fileType:ACFile_Type_SecondLoginJson urlString:acSecondLoginUrl saveAddress:saveAddress tempAddress:tempAddress progressDelegate:nil postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Get];
}

-(void)_nowUsedASIHTTPRequests:(ASIHTTPRequest*) pRequest forAdd:(BOOL)bAdd{
    @synchronized(_nowUsedASIHTTPRequests) {
        if([_nowUsedASIHTTPRequests containsObject:pRequest]){
            if(bAdd){
                return;
            }
            [_nowUsedASIHTTPRequests removeObject:pRequest];
        }
    };
}


-(void)cancelNowNetCall{
    [_chatCenter cancelNowSendingMessages];
    @synchronized(_nowUsedASIHTTPRequests){
        for(ASIHTTPRequest* pRequest  in _nowUsedASIHTTPRequests){
            [pRequest clearDelegatesAndCancel];
        }
        [_nowUsedASIHTTPRequests removeAllObjects];
        [_nowDownloadingWithProgress removeAllObjects];
    }
}

//登出
-(void)logOut:(BOOL)bFromUI  withBlock:(callURL_block) pFunc{
   //主动退出,清除用户密码,避免自动登录
    NSString * const acLogoutUrl = [NSString stringWithFormat:@"%@/rest/apis/user/logout?p=%@",[[ACNetCenter shareNetCenter] acucomServer],bFromUI?@"false":@"true"]; //p表示 被动

    wself_define();
    [ACNetCenter callURL:acLogoutUrl forMethodDelete:YES withBlock:^(ASIHTTPRequest *request, BOOL bIsFail) {
        BOOL bCallOk =  !bFromUI;
        
        if(!bIsFail){
            NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
            ITLog(responseDic);
            if(ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]){
                bCallOk = YES;
            }
        }
        
        if(bCallOk){
            [wself loopInquireTcp_closeWithDelayConnect:NO withWhy:@"logOut"];
            [self loopInquireTcp_closeWithDelayConnect:NO withWhy:@"logOut"];
            [ACConfigs clearUserPWDForDisableAutoLogin];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //更新App Icon Number
                [[ACConfigs shareConfigs] updateApplicationUnreadCount];
                [ACConfigs shareConfigs].loginState = LoginState_waiting;
            });
        }
        if(pFunc){
            pFunc(request,!bCallOk);
        }
    }];
    
    
}

//loopInquire失败后延迟重连
-(void)delayAfterLoopInquire
{
    static  BOOL    bDelayAfterLoopInquireIsRuning = NO; //避免重复
    @synchronized(self){
        if(bDelayAfterLoopInquireIsRuning){
            ITLog(@"delayAfterLoopInquire 重复");
            return;
        }
        bDelayAfterLoopInquireIsRuning = YES;
        self.loopInquireState = LoopInquireState_notConnected;
    }
    
    int nDelayTime = 50;
    NSTimeInterval currentTI = [[NSDate date] timeIntervalSince1970]-_lastLoopInquireTI;
    if (currentTI< 5){
        nDelayTime = 2;
    }
    else if (currentTI < 15){
        nDelayTime = 2;
    }
    else if (currentTI< 35){
        nDelayTime = 4;
    }
    else if (currentTI < 60){
        nDelayTime = 8;
    }
    else if (currentTI < 60*5){
        nDelayTime = 20 ;
    }
    else if (currentTI < 60*10){
        nDelayTime = 40;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(nDelayTime * NSEC_PER_SEC)), _loopInquireGCD, ^{
        bDelayAfterLoopInquireIsRuning = NO;
        [self loopInquire];
    });
    
    /*
    if (currentTI-_lastLoopInquireTI < 5)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), _loopInquireGCD, ^{
            [self loopInquire];
        });
    }
    else if (currentTI-_lastLoopInquireTI < 15)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), _loopInquireGCD, ^{
            [self loopInquire];
        });
    }
    else if (currentTI-_lastLoopInquireTI < 35)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), _loopInquireGCD, ^{
            [self loopInquire];
        });
    }
    else if (currentTI-_lastLoopInquireTI < 60)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), _loopInquireGCD, ^{
            [self loopInquire];
        });
    }
    else if (currentTI-_lastLoopInquireTI < 60*5)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), _loopInquireGCD, ^{
            [self loopInquire];
        });
    }
    else if (currentTI-_lastLoopInquireTI < 60*10)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(40 * NSEC_PER_SEC)), _loopInquireGCD, ^{
            [self loopInquire];
        });
    }
    else //if (currentTI-_lastLoopInquireTI < 60*20)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(50 * NSEC_PER_SEC)), _loopInquireGCD, ^{
            [self loopInquire];
        });
    }*/
}

-(BOOL)checkServerResponseCode:(enum ResponseCodeType) responseCode withResponseDic:(NSDictionary *)responseDic{

    if (responseCode >= ResponseCodeType_SessionInvalidStart &&
        responseCode < ResponseCodeType_SessionInvalidStop){
        ITLog(@"SessionInvalid 重新登录");
        [self autoLoginDelay:3];
        return YES;
    }
    
    if(ResponseCodeType_ERROR_USERID_NOT_EXIST==responseCode){
        ITLog(@"USERID NOT EXIST");
        [self autoLoginDelay:3];
        return YES;
    }
    
    if (responseCode == ResponseCodeType_LoginServerBusy){
        [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterLoginFailRSNotifation object:nil ];//responseDic];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:@"Server is busy now, please login later" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        [alert show];
        return YES;
    }
    
    if(responseCode == ResponseCodeType_SERVER_NOUSERINSERVER_CODE
       || responseCode == ResponseCodeType_ERROR_FIRM_SUSPENDED
       || responseCode == ResponseCodeType_ERROR_FIRM_USER_NOT_EXIST
       || responseCode == ResponseCodeType_ERROR_USER_NOT_EXIST
       || responseCode == ResponseCodeType_ERROR_USERLOGIN_CLIENT_NOT_AUTHORISED
       || responseCode == ResponseCodeType_ERROR_CLIENT_NOT_AUTHORISED) {
        
        //显示LoginVC 或显示 错误提示
        [[ACConfigs shareConfigs] presentLoginVCWithErrTip:nil orErrResponse:responseDic];
        
         return YES;

//        DataUtil.errorAppearNeedTurn2Login(context.getString(R.string.server_nouser_error));
//        ((HailStormService)context).terminate();
    }
    
    
    if ((responseCode == ResponseCodeType_SERVER_LOGINFROMOTHERDEVICE_CODE ||
         responseCode == ResponseCodeType_SERVER_PASSWORDCHANGED_CODE))
        
//    &&[ACConfigs shareConfigs].isLogined)
    {
        NSString *message = nil;
        if (responseCode == ResponseCodeType_SERVER_LOGINFROMOTHERDEVICE_CODE){
            message = NSLocalizedString(@"You_Account_Logined_At_Other", nil);
        }
        else{
            message = NSLocalizedString(@"Your password has been changed, please login again.", nil);
        }
        
        [self logOut:NO withBlock:nil]; //强行登出一下
        [[ACConfigs shareConfigs] presentLoginVCWithErrTip:message orErrResponse:nil];
            
        return YES;
    }
 
    return NO;
}

#pragma mark -

//将网络返回的信息转换为JOSN对象
+(NSDictionary*)getJOSNFromHttpData:(NSData*) pData{
    NSString *responseString = [[pData objectFromJSONData] JSONString];
    responseString = [responseString stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    responseString = [responseString stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    return [responseString objectFromJSONString];
}


/*
-(void)GCDSyncData
{
    @synchronized(self){
        self.loginState = LoginState_synchronizing;
    }
    [ACReadSeqDB updateReadSeqDBToSeqMax];
    NSString * const acSyncDataUrl = [NSString stringWithFormat:@"%@/%@",[[ACNetCenter shareNetCenter] acucomServer],@"rest/events"];
    
    NSArray *entityDicArray = [[ACDataCenter shareDataCenter] getDicArray];
    NSDictionary *tokenDic = [NSDictionary dictionaryWithObject:[ACConfigs shareConfigs].deviceToken forKey:@"ios"];
    NSDictionary *postDic = [NSDictionary dictionaryWithObjectsAndKeys:entityDicArray,@"entities",tokenDic,@"token", nil];
    
    NSString *fileName = kSyncDataJsonName;
    [self startDownloadWithFileName:fileName fileType:ACFile_Type_SyncData urlString:acSyncDataUrl saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:postDic postPathArray:nil object:nil requestMethod:requestMethodType_Post];
}*/

//获取联系人根列表
-(void)getContactPersonRootList
{
    ITLog(@"");
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self GCDGetContactPersonRootList];
    });
}

-(void)GCDGetContactPersonRootList
{
    NSString *Request_UserGroupRoot = REQUEST_USERGROUP_ROOT;
    NSString * const urlString = [NSString stringWithFormat:@"%@%@",Request_UserGroupRoot,@"type/adminchat"];
    
    NSString *fileName = @"getContactPersonRootList.json";
    NSString *saveAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_GetContactPersonRootList isTemp:NO subDirName:nil];
    NSString *tempAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_GetContactPersonRootList isTemp:YES subDirName:nil];
    [self startDownloadWithFileName:fileName fileType:ACFile_Type_GetContactPersonRootList urlString:urlString saveAddress:saveAddress tempAddress:tempAddress progressDelegate:nil postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Get];
}

//获取联系人组子列表
-(void)getContactPersonSubGroupListWithGroupID:(NSString *)groupID withOffset:(int)offset withLimit:(int)limit
{
    ITLog(@"");
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self GCDGetContactPersonSubGroupListWithGroupID:groupID withOffset:offset withLimit:limit];
    });
}

//获取联系人组子列表包括CR
-(void)getContactPersonSubGroupListWithGroupID:(NSString *)groupID withOffset:(int)offset withLimit:(int)limit withCR:(NSString*)pCR{
    NSString *Request_UserGroupRoot = REQUEST_USERGROUP_ROOT;
    NSString* pURLInfoForCR = pCR?([NSString stringWithFormat:@"&cr=%@",pCR]):@"";
    NSString * const urlString = [NSString stringWithFormat:@"%@%@/subgroups?o=%d&l=%d%@",Request_UserGroupRoot,groupID,offset,limit,pURLInfoForCR];
    
    [self startDownloadWithFileName:groupID fileType:ACFile_Type_GetContactPersonSubGroupList urlString:urlString saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Get];
}


-(void)GCDGetContactPersonSubGroupListWithGroupID:(NSString *)groupID withOffset:(int)offset withLimit:(int)limit
{
    [self getContactPersonSubGroupListWithGroupID:groupID withOffset:offset withLimit:limit withCR:nil];
}

//获取联系人单个用户列表 ,不再使用，代替为 withCR
//-(void)getContactPersonSinglePersonListWithGroupID:(NSString *)groupID withOffset:(int)offset withLimit:(int)limit
//{
//    ITLog(@"");
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        [self GCDGetContactPersonSinglePersonListWithGroupID:groupID withOffset:offset withLimit:limit];
//    });
//}

//-(void)GCDGetContactPersonSinglePersonListWithGroupID:(NSString *)groupID withOffset:(int)offset withLimit:(int)limit
//{
//    [self GCDGetContactPersonSinglePersonListWithGroupID:groupID withOffset:offset withLimit:limit withCR:nil];
//}


-(void)getContactPersonSinglePersonListWithGroupID:(NSString *)groupID withOffset:(int)offset withLimit:(int)limit withCR:(NSString*)pCR{
    ITLog(@"");
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self GCDGetContactPersonSinglePersonListWithGroupID:groupID withOffset:offset withLimit:limit withCR:pCR];
    });
}

-(void)GCDGetContactPersonSinglePersonListWithGroupID:(NSString *)groupID withOffset:(int)offset withLimit:(int)limit  withCR:(NSString*)pCR{
    NSString* pURLInfoForCR = pCR?([NSString stringWithFormat:@"&cr=%@",pCR]):@"";

    NSString *Request_UserGroupRoot = REQUEST_USERGROUP_ROOT;
    NSString * const urlString = [NSString stringWithFormat:@"%@%@/subusers?o=%d&l=%d&i=0%@",Request_UserGroupRoot,groupID,offset,limit,pURLInfoForCR];
    
    NSString *fileName = @"getContactPersonSinglePersonList.json";
    NSString *saveAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_GetContactPersonSinglePersonList isTemp:NO subDirName:nil];
    NSString *tempAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_GetContactPersonSinglePersonList isTemp:YES subDirName:nil];
    [self startDownloadWithFileName:fileName fileType:ACFile_Type_GetContactPersonSinglePersonList urlString:urlString saveAddress:saveAddress tempAddress:tempAddress progressDelegate:nil postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Get];
}



//根据关键词获取联系人列表
-(void)searchContactListWithKey:(NSString *)key withOffset:(int)offset withLimit:(int)limit withGroupIDs:(NSString *)groupIDs withCRs:(NSString*)pCRs  withFunctype:(int)searchContactListWithKey_FuncType
{
    ITLog(@"");
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self GCDSearchContactListWithKey:key withOffset:offset withLimit:limit withGroupIDs:groupIDs withCRs:pCRs withFunctype:searchContactListWithKey_FuncType];
    });
}

-(void)GCDSearchContactListWithKey:(NSString *)key withOffset:(int)offset withLimit:(int)limit withGroupIDs:(NSString *)groupIDs  withCRs:(NSString*)pCRs  withFunctype:(int)searchContactListWithKey_FuncType
{
  /*
   为支持 Relation 的搜索功能,在SyncData的数据的"perm"字段中,
   通过变量"scr"控制客户端在Relation的列表中是否显示搜索,为其值为1时表示允许搜索.

   if(支持Relation搜索){
        if(根页面){
            URL: subusers/searchlist?q=&o=%d&l=%d&ugs=&crs=
        }
        else if(Relation页面){
            URL: subusers/searchlist?q=&o=%d&l=%d&crs=
        }
        else{
            URL: subusers/searchlist?q=&o=%d&l=%d&ugs=
        }
   }
   else{
        if(根页面){
            不传送Relation的分组信息
            URL: subusers/searchlist?q=&o=%d&l=%d&ugs=
        }
        else if(Relation页面){
            隐藏搜索功能
        }
        else{
            URL: subusers/searchlist?q=&o=%d&l=%d&ugs=
        }
   }
   
   其中:
    ugs 格式如下:
        1)根页面中,包含多个groupid,使用逗号隔开
        2)其它页面中,只有一个groupid
    crs 格式如下:
        1)根页面中,包含多个crs,使用逗号隔开
        2)其它页面中,只有一个crs
        3)单个crs的格式为: [分组信息的cr值]_[分组信息的id值]
          中间使用下划线连接.
  
  当 canSearchInCR 为 TRUE 时:
  
  pCRs:格式为 cr_groupid,cr_groupid
  
  
  1.root ChooseContactType_Root 状态,需要两个参数(groupIDs&&pCRs)(可能有多个值)
  
    1).正常的组的groupIDs
    2).关系组的CRs
  
    URL: subusers/searchlist?q=%@&o=%d&l=%d&ugs=%@&crs=%@
  
  2.其它状态(groupIDs||pCRs)(只有一个值)
    1).父的cr为空(nil==pCRs),则为普通分组,使用
        subusers/searchlist?q=%@&o=%d&l=%d&ugs=%@
    2).父分组cr有效(nil==groupIDs),则为关系组,使用
        subusers/searchlist?q=%@&o=%d&l=%d&crs=%@
  
  
    cr_groupid,cr_groupid
  */
    
    
    //withGroupIDs: 如果是多个groupIDs,则以逗号隔开
    NSString *Request_UserGroupRoot = REQUEST_USERGROUP_ROOT;
    NSString * urlString = nil;
    key = [key URL_Encode];
    if(groupIDs&&pCRs){
        urlString   =   [NSString stringWithFormat:@"%@subusers/searchlist?q=%@&o=%d&l=%d&ugs=%@&crs=%@&t=%d",Request_UserGroupRoot,key,offset,limit,groupIDs,[pCRs URL_Encode],searchContactListWithKey_FuncType];
    }
    else if(groupIDs){
        urlString   =   [NSString stringWithFormat:@"%@subusers/searchlist?q=%@&o=%d&l=%d&ugs=%@&t=%d",Request_UserGroupRoot,key,offset,limit,groupIDs,searchContactListWithKey_FuncType];
    }
    else{
        urlString   =   [NSString stringWithFormat:@"%@subusers/searchlist?q=%@&o=%d&l=%d&crs=%@&t=%d",Request_UserGroupRoot,key,offset,limit,pCRs,searchContactListWithKey_FuncType];
    }
    
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *fileName = @"SearchContactList.json";
    NSString *saveAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_GetContactPersonSearchList isTemp:NO subDirName:nil];
    NSString *tempAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_GetContactPersonSearchList isTemp:YES subDirName:nil];
    [self startDownloadWithFileName:fileName fileType:ACFile_Type_GetContactPersonSearchList urlString:urlString saveAddress:saveAddress tempAddress:tempAddress progressDelegate:nil postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Get];
}

//创建TopicEntity聊天组
-(void)createTopicEntityWithChatType:(NSString *)chatType withTitle:(NSString *)title withGroupIDArray:(NSArray *)groupIDArray withUserIDArray:(NSArray *)userIDArray exMap:(NSDictionary *)exMap
{
    ITLog(@"");
    NSString *Requst_Topic_Mapping_Root = REQUEST_TOPIC_MAPPING_ROOT;
    NSString * const urlString = [NSString stringWithFormat:@"%@new",Requst_Topic_Mapping_Root];
    
    NSMutableDictionary *postDic = nil;
    if ([chatType isEqualToString:cSingleChat])
    {
        postDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:chatType,@"type",userIDArray,@"uids", nil];
    }
    else
    {
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//        NSString *userID = [defaults objectForKey:kUserID];
        postDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:chatType,@"type",title,@"title",groupIDArray,@"ugids",userIDArray,@"uids",[NSArray arrayWithObject:[ACUser myselfUserID]],@"auids", nil];
        for (NSString *key in [exMap allKeys])
        {
            [postDic setObject:[exMap objectForKey:key] forKey:key];
        }
    }
    
    NSString *fileName = @"createGroupChat.json";
    NSString *saveAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_CreateGroupChat isTemp:NO subDirName:nil];
    NSString *tempAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_CreateGroupChat isTemp:YES subDirName:nil];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self startDownloadWithFileName:fileName
                               fileType:ACFile_Type_CreateGroupChat
                              urlString:urlString
                            saveAddress:saveAddress
                            tempAddress:tempAddress
                       progressDelegate:nil
                         postDictionary:postDic
                          postPathArray:nil
                                 object:nil
                          requestMethod:requestMethodType_Post];});
}



//获取聊天消息列表
-(void)getChatMessageListWithGroupID:(NSString *)groupID withOffset:(long)offset withLimit:(int)limit isLoadNew:(BOOL)isLoadNew isDeleted:(BOOL)isDeleted
{
    if (limit <=0){
        return;
    }

    
    NSString *Request_ChatMessageRoot = REQUEST_TOPIC_MAPPING_ROOT;
    NSString * const urlString = [NSString stringWithFormat:@"%@%@/topics?o=%ld&l=%d&d=%@",Request_ChatMessageRoot,groupID,offset,limit,[NSNumber numberWithBool:isDeleted]];
    
    NSString *fileName = @"getChatMessageList.json";
    NSString *saveAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_GetChatMessage isTemp:NO subDirName:nil];
    NSString *tempAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_GetChatMessage isTemp:YES subDirName:nil];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{

        [self startDownloadWithFileName:fileName
                               fileType:ACFile_Type_GetChatMessage
                              urlString:urlString
                            saveAddress:saveAddress
                            tempAddress:tempAddress
                       progressDelegate:nil
                         postDictionary:nil
                          postPathArray:nil
                                 object:[NSNumber numberWithBool:isLoadNew]
                          requestMethod:requestMethodType_Get];
    });
}



//发送已读回执
-(void)hasBeenReadTopicEntityWithEntityID:(NSString *)entityID withSequence:(long)sequence
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString * const urlString = [NSString stringWithFormat:@"%@/rest/apis/chat/%@/read?r=%ld",[[ACNetCenter shareNetCenter] acucomServer],entityID,sequence];
        
        [self startDownloadWithFileName:nil fileType:ACFile_Type_SendHasBeenReadTopic urlString:urlString saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Put];
    });
}

//获得fileMessage的资源url
-(NSString *)getUrlWithEntityID:(NSString *)entityID messageID:(NSString *)messageID resourceID:(NSString *)resourceID
{
    NSString *url = [NSString stringWithFormat:@"%@/rest/apis/chat/%@/topic/%@/upload/%@",[[ACNetCenter shareNetCenter] acucomServer],entityID,messageID,resourceID];
    return url;
}

+(NSString*)getdownloadURL:(NSString*)urlString withFileLength:(NSInteger)nLength{
    if(nLength>0){
        return [NSString stringWithFormat:@"%@?length=%ld",urlString,nLength];
    }
    return urlString;
}

//下载fileMessage中的文件
-(void)downloadFileWithEntityID:(NSString *)entityID messageID:(NSString *)messageID resourceID:(NSString *)resourceID progressDelegate:(NSObject*)progressDelegate fileName:(NSString *)fileName  withFileLength:(NSInteger)nLength
{
    NSString *const urlString = [self getUrlWithEntityID:entityID messageID:messageID resourceID:resourceID];
    NSString *extension = [[fileName componentsSeparatedByString:@"."] lastObject];
    NSString *saveAddress = [ACAddress getAddressWithFileName:resourceID fileType:ACFile_Type_File isTemp:NO subDirName:extension];
    NSString *tempAddress = [ACAddress getAddressWithFileName:resourceID fileType:ACFile_Type_File isTemp:YES subDirName:nil];

    [self startDownloadWithFileName:messageID fileType:ACFile_Type_File urlString:[ACNetCenter getdownloadURL:urlString withFileLength:nLength] saveAddress:saveAddress tempAddress:tempAddress progressDelegate:progressDelegate postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Get];
}

//下载fileMessage中得视频
-(void)downloadMoiveFileWithEntityID:(NSString *)entityID messageID:(NSString *)messageID resourceID:(NSString *)resourceID progressDelegate:(NSObject*)progressDelegate  withFileLength:(long)lLength
{
    NSString *const urlString = [self getUrlWithEntityID:entityID messageID:messageID resourceID:resourceID];
    NSString *saveAddress = [ACAddress getAddressWithFileName:resourceID fileType:ACFile_Type_VideoFile isTemp:NO subDirName:nil];
    NSString *tempAddress = [ACAddress getAddressWithFileName:resourceID fileType:ACFile_Type_VideoFile isTemp:YES subDirName:nil];
    [self startDownloadWithFileName:messageID fileType:ACFile_Type_VideoFile urlString:[ACNetCenter getdownloadURL:urlString withFileLength:lLength] saveAddress:saveAddress tempAddress:tempAddress progressDelegate:progressDelegate postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Get];
}

//下载fileMessage中得音频
-(void)downloadAudioFileWithEntityID:(NSString *)entityID messageID:(NSString *)messageID resourceID:(NSString *)resourceID progressDelegate:(NSObject*)progressDelegate  withFileLength:(long)lLength
{
    NSString *const urlString = [self getUrlWithEntityID:entityID messageID:messageID resourceID:resourceID];
    NSString *saveAddress = [ACAddress getAddressWithFileName:resourceID fileType:ACFile_Type_AudioFile isTemp:NO subDirName:nil];
    NSString *tempAddress = [ACAddress getAddressWithFileName:resourceID fileType:ACFile_Type_AudioFile isTemp:YES subDirName:nil];
    [self startDownloadWithFileName:messageID fileType:ACFile_Type_AudioFile urlString:[ACNetCenter getdownloadURL:urlString withFileLength:lLength] saveAddress:saveAddress tempAddress:tempAddress progressDelegate:progressDelegate postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Get];
}

//下载Note的视频
-(void)downloadNote:(ACNoteMessage*)noteMessage VideoContent:(ACNoteContentImageOrVideo*) pVideo{
    NSString *const urlString = [pVideo getResourceURLStringForThumb:NO withNoteMessage:noteMessage];
    NSString *saveAddress = pVideo.resourceFilePath;
    NSString *tempAddress = pVideo.videoDownloadTempFilePath;
    [self startDownloadWithFileName:pVideo.resourceID fileType:ACFile_Type_WallboardVideo urlString:
     urlString saveAddress:saveAddress tempAddress:tempAddress progressDelegate:pVideo postDictionary:nil postPathArray:nil object:pVideo requestMethod:requestMethodType_Get];
}

//检查当前下载信息
-(void)checkDownloadingWithFileMessage:(ACFileMessage*)pFileMsg{
    for(ACDownloadingWithProgressItem* item in _nowDownloadingWithProgress){
        if([item->progressDelegate isKindOfClass:[ACFileMessage class]]){
            ACFileMessage* pmsg = (ACFileMessage*)(item->progressDelegate);
            if([pmsg.messageID isEqualToString:pFileMsg.messageID]){
                pFileMsg.progress = pmsg.progress;
                pFileMsg.isDownloading = YES;
                item->progressDelegate = pFileMsg;
                [item->pRequest setDownloadProgressDelegate:pFileMsg];
                return;
            }
        }
    }
}


//放弃有进度的下载
/*-(void)cancelDownloadingWithProgress:(NSObject*)progressDelegate{
    for(ACDownloadingWithProgressItem* item in _nowDownloadingWithProgress){
        if(item->progressDelegate==progressDelegate){
            [item->pRequest clearDelegatesAndCancel];
            [_nowDownloadingWithProgress removeObject:item];
            return;
        }
    }
}*/

-(void)_delDownloadingWithProgressForRequest:(ASIHTTPRequest*)request{
    for(ACDownloadingWithProgressItem* item in _nowDownloadingWithProgress){
        if(item->pRequest==request){
            [request setDownloadProgressDelegate:nil];
            [_nowDownloadingWithProgress removeObject:item];
            return;
        }
    }
}

-(void)_addDownloadingWithProgress:(NSObject*)progressDelegate withRequest:(ASIHTTPRequest*)request{
    ACDownloadingWithProgressItem* item = [[ACDownloadingWithProgressItem alloc] init];
    item->pRequest = request;
    item->progressDelegate = progressDelegate;
    [_nowDownloadingWithProgress addObject:item];
}


//获取参与者列表
-(void)getParticipantInfoWithEntity:(ACBaseEntity*)entify
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        [NSString stringWithFormat:@"%@%@",EntityType_Topic==entify.entityType? REQUEST_TOPIC_MAPPING_ROOT:REQUEST_URL_MAPPING_ROOT,entify.entityID];
        NSString *fileName = [NSString stringWithFormat:@"ParticipantList_%@",entify.entityID];
        NSString *saveAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_GetParticipant_Json isTemp:NO subDirName:nil];
        NSString *tempAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_GetParticipant_Json isTemp:YES subDirName:nil];
        [self startDownloadWithFileName:fileName fileType:ACFile_Type_GetParticipant_Json urlString:entify.requestUrl saveAddress:saveAddress tempAddress:tempAddress progressDelegate:nil postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Get];
    });
}

//添加参与者到当前组
-(void)addParticipantToCurrentEntity:(ACBaseEntity*)entify withGroupIDArray:(NSArray *)groupIDArray withUserIDArray:(NSArray *)userIDArray
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSDictionary *postDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:entify.mpType,@"type", groupIDArray,@"aug",userIDArray,@"au", nil];
        [self startDownloadWithFileName:nil fileType:ACFile_Type_AddParticipant_Json urlString:entify.requestUrl saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:postDic postPathArray:nil object:nil requestMethod:entify.entityType==EntityType_Topic?requestMethodType_Put:requestMethodType_Post];
    });
}

//获取topicEntity指定seqs[]的readCount
-(void)getReadCountWithSeqsArray:(NSArray *)seqsArray topicEntityID:(NSString *)topicEntityID
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *const urlString = REQUEST_READCOUNT_URL(topicEntityID);
        NSDictionary *postDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"seqs",@"action",seqsArray,@"seqs", nil];
        ITLog(([NSString stringWithFormat:@"%@ %@",postDic,topicEntityID]));
        [self startDownloadWithFileName:topicEntityID fileType:ACFile_Type_GetReadCount_Json urlString:urlString saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:postDic postPathArray:nil object:seqsArray requestMethod:requestMethodType_Post];
    });
}

//一对一聊天获取对方读到的Seq
-(void)getReadSeqWithTopicEntityID:(NSString *)topicEntityID singleChatUid:(NSString *)singleChatUid
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *const urlString = REQUEST_READCOUNT_URL(topicEntityID);
        NSDictionary *postDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"uidseq",@"action",singleChatUid,@"uid", nil];
        [self startDownloadWithFileName:topicEntityID fileType:ACFile_Type_GetSingleReadSeq_Json urlString:urlString saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:postDic postPathArray:nil object:topicEntityID requestMethod:requestMethodType_Post];
    });
}

//获得对应seq的已读列表
-(void)getHadReadListWithTopicEntityID:(NSString *)topicEntityID seq:(long)seq
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *const urlString = REQUEST_READCOUNT_URL(topicEntityID);
        NSDictionary *postDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"readers",@"action",[NSNumber numberWithLong:seq],@"seq", nil];
        [self startDownloadWithFileName:topicEntityID fileType:ACFile_Type_GetHadReadList_Json urlString:urlString saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:postDic postPathArray:nil object:nil requestMethod:requestMethodType_Post];
    });
}

-(void)getStickerWithStickerPath:(NSString *)stickerPath stickerName:(NSString *)stickerName messageID:(NSString *)messageID
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *dirName = [stickerPath stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        NSString *url = [NSString stringWithFormat:@"%@/ujs/app/im/res/emoji/%@/%@",[[ACNetCenter shareNetCenter] acucomServer],dirName,stickerName];
        
        NSString *saveAddress = [ACAddress getAddressWithFileName:stickerName fileType:ACFile_Type_StickerFile isTemp:NO subDirName:dirName];
        NSString *tempAddress = [ACAddress getAddressWithFileName:stickerName fileType:ACFile_Type_StickerFile isTemp:YES subDirName:dirName];
        
        [self startDownloadWithFileName:messageID fileType:ACFile_Type_StickerFile urlString:url saveAddress:saveAddress tempAddress:tempAddress progressDelegate:nil postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Get];
    });
    
}




//得到sticker目录json
-(void)getStickerDirJson
{
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        NSString *url = [NSString stringWithFormat:@"%@/ujs/app/im/res/emoji/metadata.json",acuCom_Sticker_Host];
//        
//        NSString *saveAddress = [ACAddress getAddressWithFileName:kStickerDirFileName fileType:ACFile_Type_StickerDir_Json isTemp:NO subDirName:nil];
//        NSString *tempAddress = [ACAddress getAddressWithFileName:kStickerDirFileName fileType:ACFile_Type_StickerDir_Json isTemp:YES subDirName:nil];
//        
//        [self startDownloadWithFileName:kStickerDirFileName fileType:ACFile_Type_StickerDir_Json urlString:url saveAddress:saveAddress tempAddress:tempAddress progressDelegate:nil postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Get];
//    });
}

//得到thumbnail Sticker
-(void)getThumbnailStickerWithPath:(NSString *)path thumbnail:(NSString *)thumbnail title:(NSString *)title
{
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        NSString *name = [thumbnail substringFromIndex:1];
//        NSString *url = [NSString stringWithFormat:@"%@/ujs/app/im/res/emoji%@%@",acuCom_Sticker_Host,path,name];
//        
//        NSString *saveAddress = [ACAddress getAddressWithFileName:name fileType:ACFile_Type_StickerThumbnail isTemp:NO subDirName:title];
//        NSString *tempAddress = [ACAddress getAddressWithFileName:name fileType:ACFile_Type_StickerThumbnail isTemp:YES subDirName:title];
//        
//        if (![[NSFileManager defaultManager] fileExistsAtPath:saveAddress])
//        {
//            [self startDownloadWithFileName:nil fileType:ACFile_Type_StickerThumbnail urlString:url saveAddress:saveAddress tempAddress:tempAddress progressDelegate:nil postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Get];
//        }
//    });
}

//得到StickerZip
-(void)getStickerZipWithTitle:(NSString *)title withDelegate:(id)delegate
{
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        NSString *url = [NSString stringWithFormat:@"%@/ujs/app/im/res/emoji/%@/package.zip",acuCom_Sticker_Host,title];
//        
//        NSString *fileName = kPackage;
//        NSString *saveAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_StickerZip isTemp:NO subDirName:title];
//        NSString *tempAddress = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_StickerZip isTemp:YES subDirName:title];
//        
//        [self startDownloadWithFileName:title fileType:ACFile_Type_StickerZip urlString:url saveAddress:saveAddress tempAddress:tempAddress progressDelegate:delegate postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Get];
//    });
}


/*
//scan用，locationAlert创建之后
-(void)uploadLocationToScan:(CLLocationCoordinate2D)coordinate locationAlert:(ACLocationAlert *)locationAlert
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *urlString = [NSString stringWithFormat:@"%@/rest/apis/location",[[ACNetCenter shareNetCenter] acucomServer]];
        NSMutableDictionary *postDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithDouble:coordinate.latitude],kLa,
                                        [NSNumber numberWithDouble:coordinate.longitude],kLo,
                                        @"network",kType,
                                        locationAlert.eventUid,kUid,
                                        locationAlert.teid,@"id", nil];
        if (locationAlert.obj)
        {
            [postDic setObject:locationAlert.obj forKey:kObj];
        }
        [self startDownloadWithFileName:nil fileType:ACFile_Type_LocationScan urlString:urlString saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:postDic postPathArray:nil object:nil requestMethod:requestMethodType_Post];
    });
}

//上传经纬度，用于locationAlert
-(void)uploadLocationToLocationAlert:(ACLocationAlert *)locationAlert coordinate:(CLLocationCoordinate2D)coordinate
{
    ITLog(@"");
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *urlString = [NSString stringWithFormat:@"%@/rest/apis/location",[[ACNetCenter shareNetCenter] acucomServer]];
        NSMutableDictionary *postDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithDouble:coordinate.latitude],kLa,
                                        [NSNumber numberWithDouble:coordinate.longitude],kLo,
                                        @"network",kType,
                                        locationAlert.eventUid,kUid,
                                        locationAlert.teid,@"id",nil];
        if (locationAlert.obj)
        {
            [postDic setObject:locationAlert.obj forKey:kObj];
        }
        [self startDownloadWithFileName:nil fileType:ACFile_Type_LocationAlert urlString:urlString saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:postDic postPathArray:nil object:nil requestMethod:requestMethodType_Post];
    });
}
*/

-(void)uploadLocationToLocationAlert:(NSArray*)pAlertDatas{
//    ITLog(([NSString stringWithFormat:@"%@",pAlertDatas]));
    ITLog(@"uploadLocationToLocationAlert");
    
    NSString* strURL = [NSString stringWithFormat:@"%@/rest/apis/location",[[ACNetCenter shareNetCenter] acucomServer]];
    NSDictionary* pPostDict = @{@"locations":pAlertDatas};
    
    if(UIApplicationStateBackground==[UIApplication sharedApplication].applicationState){
        //如果在后台,则同步发送避免失败
        ASIHTTPRequest* request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:strURL]];
        [request setRequestHeaders:[self getRequestHeader]];
        [request setTimeOutSeconds:5];
        [request setValidatesSecureCertificate:NO];
        [request setRequestMethod:@"post"];
        
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:pPostDict options:NSJSONWritingPrettyPrinted error:&error];
        if (jsonData){
            [request setPostBody:[NSMutableData dataWithData:jsonData]];
        }
        
        [request startSynchronous];
        
    #ifdef DEBUG
//        NSLog(@"URL[%d]=%@ Res=%@",request.responseStatusCode,strURL,[[request.responseData objectFromJSONData] JSONString]);
    #endif
        return;
    }
    
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self startDownloadWithFileName:nil
                               fileType:ACFile_Type_LocationAlert
                              urlString:strURL
                            saveAddress:nil
                            tempAddress:nil
                       progressDelegate:nil
                         postDictionary:pPostDict
                          postPathArray:nil object:nil
                          requestMethod:requestMethodType_Post];
    });

}

//搜索消息
-(void)searchMessage_Note:(BOOL)forNote withKey:(NSString *)key offset:(int)offset limit:(int)limit{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        keyTmp = [NSString stringWithFormat:@"content:(%@) OR (content_name:(%@) AND contentType:file)",key,key];
        // /rest/apis/note/search/notes?q=content%3A(123)&l=300&o=0
        NSString * keyTmp = [NSString stringWithFormat:@"content:(%@)",key];
        NSString *urlString = nil;
        uint  fileType = 0;
        if(forNote){
            fileType    =   ACFile_Type_SearchNote;
            urlString   =   @"%@/rest/apis/note/search/notes?q=%@&l=%d&o=%d";
        }
        else{
            fileType    =   ACFile_Type_SearchMessage;
            urlString   =   @"%@/rest/apis/chat/search/topic?q=%@&l=%d&o=%d";
        }

        urlString = [NSString stringWithFormat:urlString,[[ACNetCenter shareNetCenter] acucomServer],[keyTmp URL_Encode],limit,offset];
//        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [self startDownloadWithFileName:nil
                               fileType:fileType
                              urlString:urlString
                            saveAddress:nil
                            tempAddress:nil
                       progressDelegate:nil
                         postDictionary:nil
                          postPathArray:nil
                                 object:key
                          requestMethod:requestMethodType_Get];
    });
}



//搜索用户
-(void)searchUserWithKey:(NSString *)key offset:(int)offset limit:(int)limit  forAccount:(BOOL)bForAccount
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *urlString = [NSString stringWithFormat:@"%@/rest/apis/usergroup/users/searchlist?q=%@&l=%d&o=%d&a=%d",[[ACNetCenter shareNetCenter] acucomServer],[key URL_Encode],limit,offset,bForAccount?1:0];
//        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [self startDownloadWithFileName:nil fileType:ACFile_Type_SearchUser urlString:urlString saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:nil postPathArray:nil object:key requestMethod:requestMethodType_Get];
    });
}

//搜索用户组
-(void)searchUserGroupWithKey:(NSString *)key offset:(int)offset limit:(int)limit
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *urlString = [NSString stringWithFormat:@"%@/rest/apis/usergroup/search?q=%@&l=%d&o=%d",[[ACNetCenter shareNetCenter] acucomServer],[key URL_Encode],limit,offset];
//        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [self startDownloadWithFileName:nil fileType:ACFile_Type_SearchUserGroup urlString:urlString saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:nil postPathArray:nil object:key requestMethod:requestMethodType_Get];
    });
}

//搜索高亮显示关键字
+(void)searchHighLightWithKey:(NSString *)key topicEntityID:(NSString *)topicEntityID  withBlock:(void (^)(NSArray *highlights)) pFunc
{
    NSString *keyTmp = [NSString stringWithFormat:@"content:(%@)",key];
    NSString *urlString = [NSString stringWithFormat:@"%@/rest/apis/chat/search/highlights?q=%@&t=%@",[[ACNetCenter shareNetCenter] acucomServer],[keyTmp URL_Encode],topicEntityID];
    
    [self callURL:urlString forMethodDelete:NO withBlock:^(ASIHTTPRequest *request, BOOL bIsFail) {
        if(!bIsFail){
            NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
//            ITLog(responseDic);
            if(ResponseCodeType_Nomal == [[responseDic objectForKey:kCode] intValue]){
                pFunc([responseDic objectForKey:kHighlights]);
                return;
            }
        }
        pFunc(nil);
    }];
    
/*
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *keyTmp = nil;
        keyTmp = [NSString stringWithFormat:@"content:(%@)",key];
        NSString *urlString = [NSString stringWithFormat:@"%@/rest/apis/chat/search/highlights?q=%@&t=%@",[[ACNetCenter shareNetCenter] acucomServer],[keyTmp URL_Encode],topicEntityID];
//        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [self startDownloadWithFileName:nil fileType:ACFile_Type_SearchHighLight urlString:urlString saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:nil postPathArray:nil object:key requestMethod:requestMethodType_Get];
    });*/
}

//获得搜索数量
-(void)getSearchCountWithKey:(NSString *)key
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        NSString *keyTmp = [NSString stringWithFormat:@"content:(%@) OR (content_name:(%@) AND contentType:file)",key,key];
        NSString *keyTmp = [NSString stringWithFormat:@"content:(%@)",key];
        NSString *urlString = [NSString stringWithFormat:@"%@/rest/apis/search/count?q=%@&qm=%@",[[ACNetCenter shareNetCenter] acucomServer],[key URL_Encode],[keyTmp URL_Encode]];
//        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [self startDownloadWithFileName:nil fileType:ACFile_Type_SearchCount urlString:urlString saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:nil postPathArray:nil object:key requestMethod:requestMethodType_Get];
    });
}

-(void)changePassword:(NSString *)password
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *urlString = [NSString stringWithFormat:@"%@/rest/apis/user",[[ACNetCenter shareNetCenter] acucomServer]];
        NSDictionary *postDic = [NSDictionary dictionaryWithObject:password forKey:kPwd];
        [self startDownloadWithFileName:nil fileType:ACFile_Type_ChangePassword urlString:urlString saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:postDic postPathArray:nil object:password requestMethod:requestMethodType_Put];
    });
}


#pragma mark -UIAlertView

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(UIAlertView_tag_for_ChangePassword==alertView.tag){
        MMDrawerController* deckC = (MMDrawerController *)[UIApplication sharedApplication].delegate.window.rootViewController;
        if(deckC.openSide!=MMDrawerSideNone){
            [deckC closeDrawerAnimated:NO completion:nil];
        }
        
        //取得最前面的VC
        UIViewController *topVC = ((UINavigationController *)(deckC.centerViewController)).visibleViewController;
        
        ACChangePasswordController* pChagePWD = [[ACChangePasswordController alloc] init];
        AC_MEM_Alloc(pChagePWD);
        pChagePWD.focusChangeDefaultPWD = YES;
        [topVC.navigationController pushViewController:pChagePWD animated:YES];
    }
}


#pragma mark -stickerShop
-(void)getCategories
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *urlString = [NSString stringWithFormat:@"%@/rest/apis/sticker/categories",[[ACNetCenter shareNetCenter] acucomServer]];
        [self startDownloadWithFileName:nil fileType:ACFile_Type_GetCategories urlString:urlString saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Get];
    });
}

-(void)getSuitsOfCategoryID:(NSString *)categoryID withOffset:(int)offset withLimit:(int)limit
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *urlString = [NSString stringWithFormat:@"%@/rest/apis/sticker/suits/%@?o=%d&l=%d",[[ACNetCenter shareNetCenter] acucomServer],categoryID,offset,limit];
        [self startDownloadWithFileName:nil fileType:ACFile_Type_GetSuitsOfCategory urlString:urlString saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Get];
    });
}

-(void)getAllSuitsWithOffset:(int)offset withLimit:(int)limit
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *urlString = [NSString stringWithFormat:@"%@/rest/apis/sticker/suits?o=%d&l=%d",[[ACNetCenter shareNetCenter] acucomServer],offset,limit];
        [self startDownloadWithFileName:nil fileType:ACFile_Type_GetAllSuits urlString:urlString saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Get];
    });
}

-(void)getUserOwnStickers
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *urlString = [NSString stringWithFormat:@"%@/rest/apis/sticker/mine",[[ACNetCenter shareNetCenter] acucomServer]];
        [self startDownloadWithFileName:nil fileType:ACFile_Type_GetUserOwnStickers urlString:urlString saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Get];
    });
}

-(void)removeUserOwnStickerWithSuitID:(NSString *)suitID
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *urlString = [NSString stringWithFormat:@"%@/rest/apis/sticker/mine/%@",[[ACNetCenter shareNetCenter] acucomServer],suitID];
        [self startDownloadWithFileName:nil fileType:ACFile_Type_RemoveUserOwnSticker urlString:urlString saveAddress:nil tempAddress:nil progressDelegate:nil postDictionary:nil postPathArray:nil object:suitID requestMethod:requestMethodType_Delete];
    });
}

-(void)addStickerSuitToMyStickersAndDownloadWithSuitID:(NSString *)suitID progressDelegate:(ACSuit *)delegate
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *urlString = [NSString stringWithFormat:@"%@/rest/apis/sticker/suit/obtain-and-download/%@",[[ACNetCenter shareNetCenter] acucomServer],suitID];
        NSString *saveAddress = [ACAddress getAddressWithFileName:[suitID stringByAppendingString:@".zip"] fileType:ACFile_Type_AddStickerSuitToMyStickersAndDownload isTemp:NO subDirName:suitID];
        NSString *tempAddress = [ACAddress getAddressWithFileName:[suitID stringByAppendingString:@".zip"] fileType:ACFile_Type_AddStickerSuitToMyStickersAndDownload isTemp:YES subDirName:suitID];
        
        [delegate addObserver:self forKeyPath:kProgress options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
        [_suitDownloadDic setObject:delegate forKey:delegate.suitID];
        [self startDownloadWithFileName:nil fileType:ACFile_Type_AddStickerSuitToMyStickersAndDownload urlString:urlString saveAddress:saveAddress tempAddress:tempAddress progressDelegate:delegate postDictionary:nil postPathArray:nil object:delegate requestMethod:requestMethodType_Get];
    });
}

-(void)downloadWithSuitID:(NSString *)suitID progressDelegate:(ACSuit *)delegate
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *urlString = [NSString stringWithFormat:@"%@/rest/apis/sticker/suit/download/%@",[[ACNetCenter shareNetCenter] acucomServer],suitID];
        NSString *saveAddress = [ACAddress getAddressWithFileName:[suitID stringByAppendingString:@".zip"] fileType:ACFile_Type_DownloadSuit isTemp:NO subDirName:suitID];
        NSString *tempAddress = [ACAddress getAddressWithFileName:[suitID stringByAppendingString:@".zip"] fileType:ACFile_Type_DownloadSuit isTemp:YES subDirName:suitID];
        
        [delegate addObserver:self forKeyPath:kProgress options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
        [_suitDownloadDic setObject:delegate forKey:delegate.suitID];
        [self startDownloadWithFileName:nil fileType:ACFile_Type_DownloadSuit urlString:urlString saveAddress:saveAddress tempAddress:tempAddress progressDelegate:delegate postDictionary:nil postPathArray:nil object:delegate requestMethod:requestMethodType_Get];
    });
}

-(void)downloadStickerWithResourceID:(NSString *)resourceID
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (!_stickerDownloadingArray)
        {
            _stickerDownloadingArray = [[NSMutableArray alloc] init];
        }
        if (![_stickerDownloadingArray containsObject:resourceID])
        {
            [_stickerDownloadingArray addObject:resourceID];
            
            NSString *urlString = [NSString stringWithFormat:@"%@/rest/apis/sticker/suitID/image/%@",[[ACNetCenter shareNetCenter] acucomServer],resourceID];
            NSString *saveAddress = [ACAddress getAddressWithFileName:resourceID fileType:ACFile_Type_DownloadSticker isTemp:NO subDirName:kSingleSticker];
            NSString *tempAddress = [ACAddress getAddressWithFileName:resourceID fileType:ACFile_Type_DownloadSticker isTemp:YES subDirName:nil];
            [self startDownloadWithFileName:nil fileType:ACFile_Type_DownloadSticker urlString:urlString saveAddress:saveAddress tempAddress:tempAddress progressDelegate:nil postDictionary:nil postPathArray:nil object:resourceID requestMethod:requestMethodType_Get];
        }
    });
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isKindOfClass:[ACSuit class]] && [keyPath isEqualToString:kProgress])
    {
        ACSuit *suit = object;
        [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterSuitProgressUpdateNotifition object:suit.suitID];
    }
}

-(void)getSuitWithSuitID:(NSString *)suitID
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *urlString = [NSString stringWithFormat:@"%@/rest/apis/sticker/suit/%@",[[ACNetCenter shareNetCenter] acucomServer],suitID];
        NSString *saveAddress = [ACAddress getAddressWithFileName:suitID fileType:ACFile_Type_GetSuitInfo isTemp:NO subDirName:suitID];
//        NSDictionary *suitDic = [NSDictionary dictionaryWithContentsOfFile:saveAddress];
//        if (suitDic)
//        {
//            [self renameSuitImageWithSuitDic:suitDic];
//        }
//        else
        {
            [self startDownloadWithFileName:nil fileType:ACFile_Type_GetSuitInfo urlString:urlString saveAddress:saveAddress tempAddress:nil progressDelegate:nil postDictionary:nil postPathArray:nil object:nil requestMethod:requestMethodType_Get];
        }
    });
}

-(void)renameSuitImageWithSuitDic:(NSDictionary *)suitDic
{
    if (suitDic)
    {
        ACSuit *suit = [[ACSuit alloc] initWithDic:suitDic];
        for (int i = 0; i < [suit.stickers count]; i++)
        {
            ACSticker *sticker = [suit.stickers objectAtIndex:i];
            NSString *fileName = sticker.title;
            NSString *fromPath = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_DownloadSticker isTemp:NO subDirName:suit.suitID];
            
            NSString *toPath = [ACAddress getAddressWithFileName:sticker.rid fileType:ACFile_Type_DownloadSticker isTemp:NO subDirName:suit.suitID];
            NSError *error = [[NSError alloc] init];
//            NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:[ACAddress getAddressWithFileName:nil fileType:ACFile_Type_DownloadSticker isTemp:NO subDirName:suit.suitID]];
//            NSString *path;
//            while ((path = [enumerator nextObject]) != nil)
//            {
//                NSLog(@"%@",path);
//            }
//            BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:fromPath isDirectory:nil];
//            BOOL readable = [[NSFileManager defaultManager] isReadableFileAtPath:fromPath];
//            BOOL writable = [[NSFileManager defaultManager] isWritableFileAtPath:toPath];
            
            [[NSFileManager defaultManager] moveItemAtPath:fromPath toPath:toPath error:&error];
            //$$
            if ([[NSFileManager defaultManager] fileExistsAtPath:toPath]) {
                NSLog(@"toPath is exist");
            }
            else {
                 NSLog(@"toPath not exist");
            }
            //
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterGetSuitInfoNotifition object:nil];
    }
}

+(void)callURL:(NSString*)pURLString  forMethodDelete:(BOOL)bForDelete  withBlock:(callURL_block) pFunc{
    if(nil==pFunc){
        pFunc = ^(ASIHTTPRequest *request, BOOL bIsFail) {};
    }
    
    if ([ASIHTTPRequest isValidNetWork]&&pURLString.length){
        ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:pURLString]];
        [request setValidatesSecureCertificate:NO];
        [request setRequestHeaders:[[ACNetCenter shareNetCenter] getRequestHeader]];
        [request setRequestMethod:bForDelete?@"delete":@"get"];
        [request setTimeOutSeconds:ACNetCenter_TimeOutSencods];
        __block ASIHTTPRequest *requestTemp = request;
        [request setCompletionBlock:^{
            
            ITLogEX(@"URL[%d]=%@ Res=%@",requestTemp.responseStatusCode,pURLString,[[requestTemp.responseData objectFromJSONData] JSONString]);

            pFunc(requestTemp,HttpCodeType_Success!=requestTemp.responseStatusCode);
        }];
        [request setFailedBlock:^{
            ITLogEX(@"URL[%d]=%@ err=%@ head=%@",requestTemp.responseStatusCode,pURLString,requestTemp.error, requestTemp.responseHeaders);
           pFunc(requestTemp,YES);
        }];
//        [request setShouldContinueWhenAppEntersBackground:YES];
        [request startAsynchronous];
    }
    else{
        pFunc(nil,YES);
    }
}


+(void)callURL:(NSString*)pURLString forPut:(BOOL)bForPut withPostData:(NSDictionary*)pPostData withBlock:(callURL_block) pFunc{

    if(nil==pFunc){
        pFunc = ^(ASIHTTPRequest *request, BOOL bIsFail) {};
    }
   
    
    if ([ASIHTTPRequest isValidNetWork]&&pURLString.length){
        
        ASIHTTPRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:pURLString]];
        [request setValidatesSecureCertificate:NO];
        [request setRequestHeaders:[[ACNetCenter shareNetCenter] getRequestHeader]];
        [request setRequestMethod:bForPut?@"put":@"post"];
        [request setTimeOutSeconds:ACNetCenter_TimeOutSencods];
     
        if(pPostData){
            NSError *error = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:pPostData options:NSJSONWritingPrettyPrinted error:&error];
            if (jsonData){
                [request setPostBody:[NSMutableData dataWithData:jsonData]];
            }
            else{
                pFunc(request,YES);
                return;
            }
        }
        
        __block ASIHTTPRequest *requestTemp = request;
        [request setCompletionBlock:^{
        #ifdef ACUtility_Need_Log
            if([pURLString hasSuffix:@"topics"]){
                ITLogEX(@"URL[%d]=%@ head=%@",requestTemp.responseStatusCode,pURLString,requestTemp.responseHeaders);
            }
            else{
                ITLogEX(@"URL[%d]=%@ Res=%@ head=%@",requestTemp.responseStatusCode,pURLString,[[requestTemp.responseData objectFromJSONData] JSONString],requestTemp.responseHeaders);
            }
        #endif
            pFunc(requestTemp,HttpCodeType_Success!=requestTemp.responseStatusCode);
        }];
        [request setFailedBlock:^{
            ITLogEX(@"URL[%d]=%@ err=%@ head=%@",requestTemp.responseStatusCode,pURLString,requestTemp.error, requestTemp.responseHeaders);
            pFunc(requestTemp,YES);
        }];
        //        [request setShouldContinueWhenAppEntersBackground:YES];
        [request startAsynchronous];
    }
    else{
        pFunc(nil,YES);
    }
}

+(void)ERROR_AUTHORITYCHANGED_FAILED_Error_Func:(NSDictionary*)responseDic{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterErrorAuthorityChangedFailed_1248 object:nil];
    NSString *desc = [responseDic objectForKey:kDescription];
    if ([desc length] > 0){
        dispatch_async(dispatch_get_main_queue(), ^{
            AC_ShowTip(desc);
        });
    }
}


//object 用于ACMessage对象，发送返回后修改messageID
-(void)startDownloadWithFileName:(NSString *)fileNameID fileType:(uint)fileType
                       urlString:(NSString *)urlString
                     saveAddress:(NSString *)saveAddress
                     tempAddress:(NSString *)tempAddress
                progressDelegate:(NSObject*)progressDelegate
                  postDictionary:(NSDictionary *)postDictionary
                   postPathArray:(NSArray *)postPathArray
                          object:(id)object
                   requestMethod:(int)requestMethod
{
    
#ifdef ACUtility_Need_Log
    NSString*   _DebugEndTitle = nil;
    {
        const char* __fileType_Name = ACFile_Type_Name(fileType);
        NSString*   startDownloadWithFileName_ID = [ACMessage getTempMsgID];
        ITLogEX_Simple(@"\nBeging_%@(%s): %@ %@",startDownloadWithFileName_ID,__fileType_Name,urlString,[postDictionary JSONString]);

        
        _DebugEndTitle = [NSString stringWithFormat:@"\nEnd_%@(%s)",startDownloadWithFileName_ID,__fileType_Name];
    }
#endif
    
    
    if (![ASIHTTPRequest isValidNetWork])
    {
        ITLogEX_Simple(@"%@ 没有网络",_DebugEndTitle);
        if (fileType == ACFile_Type_LoopInquire ||
            fileType == ACFile_Type_LoginJson ||
            fileType == ACFile_Type_SecondLoginJson)
        {
            [ACConfigs shareConfigs].loginState = LoginState_waiting;
            [self delayAfterLoopInquire];
        }
        else if (fileType == ACFile_Type_SendText ||
                 fileType == ACFile_Type_SendLocation ||
                 fileType == ACFile_Type_SendSticker ||
                 fileType == ACFile_Type_SendImage_Json ||
                 fileType == ACFile_Type_SendAudio_Json ||
                 fileType == ACFile_Type_SendVideo_Json ||
                 fileType == ACFile_Type_SendFile_Json||
                 fileType == ACFile_Type_TransmitMsg)
        {
            [_chatCenter resendMessage:object];
        }
        else if (fileType == ACFile_Type_SendNoteOrWallboard)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterNotes_Note_Upload_NoNetword_Notifition object:object];
        }
        else if (fileType == ACFile_Type_GetReadCount_Json)
        {
            NSString *topicEntityID = fileNameID;
            NSArray *array = object;
            
            NSArray *readCountArray = [ACReadCount getFailReadCountListWithArray:array withEntityID:topicEntityID];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterGetReadCountFailNotifation object:readCountArray];
        }
        return;
    }
//    if (![[NSUserDefaults standardUserDefaults] objectForKey:kAccount])
//    {
//        return;
//    }
    
/*  __weak NSString *fileNameIDTmp = fileNameID;
    __weak uint fileTypeTmp = fileType;
    __weak NSString *urlStringTmp = urlString;
    __weak NSString *saveAddressTmp = saveAddress;
    __weak NSString *tempAddressTmp = tempAddress;
    __weak id progressDelegateTmp = progressDelegate;
    __weak NSDictionary *postDictionaryTmp = postDictionary;
    __weak NSArray *postPathArrayTmp = postPathArray;
    __weak id objectTmp = object;
    __weak int requestMethodTmp = requestMethod;*/
    
    ASIHTTPRequest *request = nil;
    if (postDictionary || postPathArray || ACFile_Type_SendNoteOrWallboard==fileType)
    {
        request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
        if (fileType == ACFile_Type_SendNoteOrWallboard)
        {
            [(ASIFormDataRequest *)request setPostFormat:ASIMultipartFormDataPostFormat];
            if([object isKindOfClass:[ACWallBoard_Message class]]){
                [(ACWallBoard_Message *)object setForASIFormDataRequest:(ASIFormDataRequest *)request];
            }
            else{
                NSAssert([object isKindOfClass:[ACNoteMessage class]],@"ACFile_Type_SendNoteOrWallboard Error");
                [(ACNoteMessage *)object setForASIFormDataRequest:(ASIFormDataRequest *)request];
            }
            
            /*WB
            for (int i = 0; i < [postPathArray count]; i++)
            {
                NSDictionary *pathDic = [postPathArray objectAtIndex:i];
                NSArray *multiArray = [(ACWallBoard_Message *)object multiArray];
                if ([multiArray count] > i)
                {
                    ACWallBoardFilePage *page = [multiArray objectAtIndex:i];
                    
                    NSString *srcPath = [pathDic objectForKey:kSrc];
                    [(ASIFormDataRequest *)request setFile:srcPath forKey:page.resourceID];
                    
                    NSString *thumbPath = [pathDic objectForKey:kThumb];
                    [(ASIFormDataRequest *)request setFile:thumbPath forKey:[page.resourceID stringByAppendingString:@"_s"]];
                }
            }*/
            
            for (NSString *key in [postDictionary allKeys])
            {
               [(ASIFormDataRequest *)request setPostValue:[[postDictionary objectForKey:key] JSONString] forKey:key];
            }
        }
        else if (postDictionary && postPathArray)
        {
            switch (fileType)
            {
                case ACFile_Type_SendImage_Json:
                    if ([postPathArray count] == 2)
                    {
//                        NSError *error = nil;
//                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:postDictionary options:NSJSONWritingPrettyPrinted error:&error];
//                        if (jsonData)
//                        {
                            [(ASIFormDataRequest *)request setPostValue:[postDictionary JSONString] forKey:kTopic];
//                        }
//                        else
//                        {
//                            ITLog(error);
//                            throw 0;
//                        }
                        NSDictionary *contentDic = [postDictionary objectForKey:kContent];
                        NSString *bigKey = nil;
                        NSString *smallKey = nil;
                        if (contentDic)
                        {
                            bigKey = [contentDic objectForKey:kRid];
                            bigKey = [bigKey substringWithRange:NSMakeRange(1, [bigKey length]-2)];
                            
                            smallKey = [contentDic objectForKey:kTrid];
                            smallKey = [smallKey substringWithRange:NSMakeRange(1, [smallKey length]-2)];
                        }
                        [(ASIFormDataRequest *)request setFile:[postPathArray objectAtIndex:0] forKey:bigKey];
                        [(ASIFormDataRequest *)request setFile:[postPathArray objectAtIndex:1] forKey:smallKey];
                    }
                    break;
                case ACFile_Type_SendFile_Json:
                case ACFile_Type_SendAudio_Json:
                    if ([postPathArray count] == 1)
                    {
//                        NSError *error = nil;
//                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:postDictionary options:NSJSONWritingPrettyPrinted error:&error];
//                        if (jsonData)
//                        {
                            [(ASIFormDataRequest *)request setPostValue:[postDictionary JSONString] forKey:kTopic];
//                        }
//                        else
//                        {
//                            ITLog(error);
//                            throw 0;
//                        }
                        NSDictionary *contentDic = [postDictionary objectForKey:kContent];
                        NSString *bigKey = nil;
                        if (contentDic)
                        {
                            bigKey = [contentDic objectForKey:kRid];
                            bigKey = [bigKey substringWithRange:NSMakeRange(1, [bigKey length]-2)];
                        }
                        [(ASIFormDataRequest *)request setFile:[postPathArray objectAtIndex:0] forKey:bigKey];
                    }
                    break;
                case ACFile_Type_SendVideo_Json:
                    if ([postPathArray count] == 2)
                    {
//                        NSError *error = nil;
//                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:postDictionary options:NSJSONWritingPrettyPrinted error:&error];
//                        if (jsonData)
//                        {
                            [(ASIFormDataRequest *)request setPostValue:[postDictionary JSONString] forKey:kTopic];
//                        }
//                        else
//                        {
//                            ITLog(error);
//                            throw 0;
//                        }
                        NSDictionary *contentDic = [postDictionary objectForKey:kContent];
                        NSString *bigKey = nil;
                        NSString *smallKey = nil;
                        if (contentDic)
                        {
                            bigKey = [contentDic objectForKey:kRid];
                            bigKey = [bigKey substringWithRange:NSMakeRange(1, [bigKey length]-2)];
                            
                            smallKey = [contentDic objectForKey:kTrid];
                            smallKey = [smallKey substringWithRange:NSMakeRange(1, [smallKey length]-2)];
                        }
                        
                        [(ASIFormDataRequest *)request setFile:[postPathArray objectAtIndex:0] forKey:bigKey];
                        [(ASIFormDataRequest *)request setFile:[postPathArray objectAtIndex:1] forKey:smallKey];
                    }
                    break;
                default:
                    break;
            }
        }
        else if (postDictionary)
        {
            NSError *error = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:postDictionary options:NSJSONWritingPrettyPrinted error:&error];
            if (jsonData)
            {
                [request setPostBody:[NSMutableData dataWithData:jsonData]];
            }
            else
            {
                ITLogEX_Simple(@"%@ 失败:%@",_DebugEndTitle,error);
                return;
//                NSAssert(NO,error);
                
//TXB 避免使用.mm throw 0;
            }
        }
//        else
//        {
//            switch (fileType)
//            {
//                case ACFile_Type_SendImage_Json:
//                    if ([postPathArray count] == 2)
//                    {
//                        [(ASIFormDataRequest *)request setFile:[postPathArray objectAtIndex:0] forKey:@"tImage"];
//                        [(ASIFormDataRequest *)request setFile:[postPathArray objectAtIndex:1] forKey:@"tImage_T"];
//                    }
//                    break;
//                case ACFile_Type_SendAudio_Json:
//                    if ([postPathArray count] == 1)
//                    {
//                        [(ASIFormDataRequest *)request setFile:[postPathArray objectAtIndex:0] forKey:@"mAudio"];
//                    }
//                    break;
//                case ACFile_Type_SendVideo_Json:
//                    if ([postPathArray count] == 2)
//                    {
//                        [(ASIFormDataRequest *)request setFile:[postPathArray objectAtIndex:0] forKey:@"tVideo"];
//                        [(ASIFormDataRequest *)request setFile:[postPathArray objectAtIndex:1] forKey:@"tVideo_T"];
//                    }
//                    break;
//                default:
//                    break;
//            }
//        }
    }
    else
    {
        request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    }
    [request setValidatesSecureCertificate:NO];
    [request setRequestMethod:[self getRequestMethodWithType:requestMethod]];
    
    //header
    if ([urlString rangeOfString:@"login"].length == 0 && [urlString rangeOfString:@"authorized"].length == 0)
    {
        if (![[NSUserDefaults standardUserDefaults] objectForKey:kAclSid])
        {
            return;
        }
        
        [request setRequestHeaders:[self getRequestHeader]];
    }
    else
    {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:5];
//        [dic setObject:[NSString stringWithFormat:@"%@/ui/login.html?client_id=acucom&response_type=code&scope=*",[[ACNetCenter shareNetCenter] acucomServer]] forKey:@"Referer"];
        [dic setObject:@"http://host/ui/login.html?client_id=acucom&response_type=code&scope=*" forKey:@"Referer"];
        [dic setObject:@"ios" forKey:kAclTerminal];
        [request setRequestHeaders:dic];
        [ASIHTTPRequest setSessionCookies:nil];
    }
    
//    if ([fileNameID rangeOfString:@"loopInquire"].length == 0)
    {
        if (postPathArray){
            [request setTimeOutSeconds:960];
        }
        else{
            if (fileType == ACFile_Type_VideoFile || fileType ==ACFile_Type_File || fileType == ACFile_Type_SendNoteOrWallboard){
                [request setTimeOutSeconds:960];
            }
            else{
//                [request setTimeOutSeconds:50];
                [request setTimeOutSeconds:ACNetCenter_TimeOutSencods];
            }
        }
    }
//    else
//    {
//        [request setTimeOutSeconds:ACNetCenter_TimeOutSencods];
//    }
    request.useCookiePersistence = YES;

    __block ASIHTTPRequest *requestTemp = request;
    [request setCompletionBlock:^{
        
        [self _nowUsedASIHTTPRequests:requestTemp forAdd:NO];
        if(progressDelegate){
            [self _delDownloadingWithProgressForRequest:requestTemp];
        }
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSDictionary *headerDic = requestTemp.responseHeaders;
            ACConfigs *pAcConfigs = [ACConfigs shareConfigs];
            
            /*
            NSString *responseString = [[requestTemp.responseData objectFromJSONData] JSONString];
            responseString = [responseString stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
            responseString = [responseString stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
            NSDictionary *responseDic = [responseString objectFromJSONString];*/
            
            NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:requestTemp.responseData];
//            [responseDic writeToFile:saveAddress atomically:YES];

            if(nil==responseDic){
                ITLogEX_Simple(@"%@ responseError is : %s",_DebugEndTitle,(const char*)(requestTemp.responseData.bytes));
            }
            else{
                ITLogEX_Simple(@"%@ responseDic is : %@",_DebugEndTitle,[responseDic JSONString]);
            }

            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            
            //判断httpCode是否成功
            if (requestTemp.responseStatusCode == HttpCodeType_Success)
            {
                
            }
            else{
                if(ACFile_Type_LoginJson==fileType||
                   ACFile_Type_SecondLoginJson==fileType){
                    pAcConfigs.loginState = LoginState_waiting;
                }
                
                if (requestTemp.responseStatusCode == HttpCodeType_ServerUpdate)
                {
                    ITLogEX_Simple(@"%@ ServerUpdate 自动登录!",_DebugEndTitle);
                    [self autoLoginDelay:3];
                    return;
                }
                else
                {

                    ITLogEX_Simple(@"%@ 网络错误%d :: %@",_DebugEndTitle,requestTemp.responseStatusCode,requestTemp.responseStatusMessage);
#if DEBUG
                    if(ACFile_Type_LoginJson==fileType||ACFile_Type_SecondLoginJson==fileType){
                        AC_ShowTipFunc(@"调试",[NSString stringWithFormat:@"网络错误%d :: %@\n%@",requestTemp.responseStatusCode,requestTemp.responseStatusMessage,urlString]);
                    }
#endif

                    return;
                }
            }
            
            //判断responseCode是否成功
            int responseCode = [[responseDic objectForKey:kCode] intValue];
            if (responseCode == ResponseCodeType_Nomal){
                
            }
            else
            {
                if(ACFile_Type_LoginJson==fileType||
                   ACFile_Type_SecondLoginJson==fileType){
                    ITLogEX_Simple(@"%@ 登录失败",_DebugEndTitle);
                    pAcConfigs.loginState = LoginState_waiting;
                }

                if(ResponseCodeType_ERROR_AUTHORITYCHANGED_FAILED==responseCode){
                    //ResponseCodeType_ERROR_AUTHORITYCHANGED_FAILED = 1248, //服务器增加错误代码 1248，客户端收到此代码时，表明自己提交的admin权限的请求已经失败，原因是当前身份已经不是admin。客户端显示随1248一起返回的文字，并获取新的权限，并重新绘制界面。
                    [ACNetCenter ERROR_AUTHORITYCHANGED_FAILED_Error_Func:responseDic];
                    return;
                }
                else if([self checkServerResponseCode:(enum ResponseCodeType)responseCode  withResponseDic:responseDic]){
                    return;
                }
                else
                {
                    if (
                        fileType != ACFile_Type_StickerDir_Json
                        && fileType != ACFile_Type_StickerThumbnail
                        && fileType != ACFile_Type_StickerZip
                        && fileType != ACFile_Type_StickerFile
                        && fileType != ACFile_Type_AddStickerSuitToMyStickersAndDownload
                        && fileType != ACFile_Type_DownloadSuit
                        && fileType != ACFile_Type_DownloadSticker
                        )
                    {
                        
                        ITLogEX_Simple(@"%@ responseCode 判断失败 %d %@",_DebugEndTitle,responseCode,urlString);
                        if([object isKindOfClass:[ACMessage class]]){ //是发送消息失败
                            [_chatCenter resendMessageFail:object];
                            return;
                        }
                        
                        if((ACFile_Type_LoginJson==fileType||
                            ACFile_Type_SecondLoginJson==fileType)){
                            if(pAcConfigs.loginVCShowed){
                                [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterLoginFailRSNotifation object:responseDic];
                            }
                            else{
                                [self autoLoginDelay:3];
                            }
                        }
                        
                        NSString *desc = [responseDic objectForKey:kDescription];
                        if ([desc length] > 0)
                        {
                            
                        #if DEBUG
                            //不提示
                            if(ResponseCodeType_Reconnecting!=responseCode){
                                desc = [NSString stringWithFormat:@"[%d]%@",responseCode,desc];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    AC_ShowTipFunc(@"调试",desc);
                                });
                            }
                        #endif
                            
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterResponseCodeErrorNotifation object:[NSNumber numberWithInteger:fileType]];
                        }
                        return;
                    }
                }
            }
            
            switch (fileType)
            {
                case ACFile_Type_LoginJson:
                {
                    if(0==responseDic.count){
                        pAcConfigs.loginState = LoginState_waiting;
                        [pAcConfigs presentLoginVCWithNetError];
                        return;
                    }
                    
                    NSDictionary *sessionDic = [responseDic objectForKey:@"session"];
                    NSString *code = [sessionDic objectForKey:kCode];
                    NSString *userID = [sessionDic objectForKey:@"uid"];
                    
                    {
                        NSString *pURI = [sessionDic objectForKey:@"uri"];
//                    NSRange findEndRang =   [pURI rangeOfString:@"/" options:NSCaseInsensitiveSearch range:NSMakeRange(10, pURI.length-10)];
                    
                        _acucomServer   =   [pURI substringToIndex:[pURI rangeOfString:@"/" options:NSCaseInsensitiveSearch range:NSMakeRange(10, pURI.length-10)].location];
                        if(_acucomServer.length==0){
                            return;
                        }
                    }
                    [self loopInquireTcp_closeWithDelayConnect:NO withWhy:@"登录成功，断开旧的连接"];
//                    [self _setTcpInfoForFirstLogin:[responseDic objectForKey:@"tcp"] saveToDefault:defaults];
                    [self _setTcpInfoForFirstLogin:[responseDic objectForKey:kAcuComWssInfo] saveToDefault:defaults];
                    
                    //替换账号
                    NSString *account = postDictionary[kAccount];
                    NSString *account_debug =   postDictionary[kAccount_debug];
//                    NSString *pwd = [postDictionary objectForKey:kPwd];
//                    NSString *userLoginInputDomain = [postDictionary objectForKey:kUserLoginInputDomain];
//                    NSString *firmAndDomain = [postDictionary objectForKey:kFirmAndDomain];
                    
                    
//                    if (!([account isEqualToString:[defaults objectForKey:kAccount]]&&
//                          [account_debug isEqualToString:[defaults objectForKey:kAccount_debug]]))
//                        ![userLoginInputDomain isEqualToString:[defaults objectForKey:kUserLoginInputDomain]])
                    if(![userID isEqualToString:[defaults objectForKey:kUserID]])
                    {
//                        [defaults setObject:account forKey:kAccount];
//                        [defaults setObject:domain forKey:kDomain];
//                        [defaults setObject:firmAndDomain forKey:kFirmAndDomain];
                        [pAcConfigs clearUserData];
                    }
                    [defaults setObject:code forKey:kCode];
                    [defaults setObject:userID forKey:kUserID];
                    
                    [defaults setObject:account_debug forKey:kAccount_debug];
                    [defaults setObject:account forKey:kAccount];
                    
                    [defaults setObject:postDictionary[kPwd] forKey:kPwd];
//                    [defaults setObject:userLoginInputDomain forKey:kUserLoginInputDomain];
                    [defaults synchronize];
                    
                    g__pMySelfUserID = userID; //缓存我自己的UserID
//                    BOOL isFromUILogin = self.isFromUILogin;
                    [self secondLoginAcucomServerWithCode:code withUserID:userID];
                    
                    if([[responseDic objectForKey:@"changePwd"] boolValue]){
                        static time_t g__changePwdReason_time_t = 0; //保证 5分钟内不重复提示
                        time_t changePwdReason_time_t = time(NULL);
                        if((changePwdReason_time_t-g__changePwdReason_time_t)>5*60){
                            NSString* changePwdReason = [responseDic objectForKey:@"changePwdReason"];
                            if(changePwdReason.length){
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:changePwdReason delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
                                    alert.tag = UIAlertView_tag_for_ChangePassword;
                                    [alert show];
                                });
                            }
                        }
                        g__changePwdReason_time_t = changePwdReason_time_t;
                    }

                }
                    break;
                case ACFile_Type_SecondLoginJson:
                {
                    if(0==responseDic.count){
                        pAcConfigs.loginState = LoginState_waiting;
                        [pAcConfigs presentLoginVCWithNetError];
                        return;
                    }

//                    ITLog(([NSString stringWithFormat:@"%@",[ASIHTTPRequest sessionCookies]]));
//                    [ASIHTTPRequest setSessionCookies:nil];
                    
                    pAcConfigs.loginState = LoginState_logined;
                    [defaults setObject:[responseDic objectForKey:kS] forKey:kS];
                    [defaults setObject:[responseDic objectForKey:kAclSid] forKey:kAclSid];
                    
                    NSString *cookie = [headerDic objectForKey:@"Set-Cookie"];
                    [defaults setObject:cookie forKey:kCookie];
                    
                    NSString *acldomain = [[[[cookie componentsSeparatedByString:@"acldomain="] objectAtIndex:1] componentsSeparatedByString:@";"] objectAtIndex:0];
                    [defaults setObject:acldomain forKey:kAclDomain];
                    
                    
//                    [defaults setObject:requestTemp.responseCookies forKey:kCookieObject];
                    
                    
                    [pAcConfigs savePersonInfoWithUserDic:responseDic];
                    
                    //登录成功手动同步一下数据，暂时轮询完自动同步
//                    [self syncData];
                    [self _doSecondLogin];
                }
                    break;
                case ACFile_Type_Logout:
                {
//                    pAcConfigs.isLogouting = NO;
//                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterLogoutNotifation object:nil];
//好像没用                    [self monitorReachabilityStop];
//                    [pAcConfigs clearUserData];
                }
                    break;
                case ACFile_Type_DeleteLoopInquire:
                {
                    
                }
                    break;
                case ACFile_Type_LoopInquire:
                {
                    NSAssert(NO,@"ACFile_Type_LoopInquire");
                    /*
                    [self loopInquire];
                    //记录上一次轮询成功的时间戳
                    _lastLoopInquireTI = [[NSDate date] timeIntervalSince1970];
                    [self _Call_handleEventOperateWithEventDic:responseDic forSync:NO];*/

                }
                    break;
                case ACFile_Type_SyncData:
                {
                    /*
                    //"noteTime" : 145345435454, //这个是新增的字段， 用于返回当前最新的note或comment的updatetime。
                    {
                        NSNumber* pNoteTime =   [responseDic objectForKey:@"noteTime"];
                        if(pNoteTime){
//                            long long llTime =   pNoteTime.longLongValue;
//                            long lTime = pNoteTime.longValue;
//                            NSLog(@"%d,%d",sizeof(long long),sizeof(long));
                            [pAcConfigs chageNoteLastTime:[pNoteTime longLongValue] andCurTime:-1L];
                        }
                    }

                    NSArray *eventDicArray = [responseDic objectForKey:@"events"];
                    for (NSDictionary *eventDic in eventDicArray)
                    {
                        @synchronized(self)
                        {
                            [ACEntityEvent handleEventOperateWithEventDic:eventDic forSync:YES];
                        }
                    }

                    NSDictionary *permDic = [responseDic objectForKey:@"perm"];
                    if(permDic){
                        NSNumber* pcanSearchInCR = [permDic objectForKey:@"scr"];
                        pAcConfigs.canSearchInCR = 1==pcanSearchInCR.intValue;
                    }
                    
                    NSData *jsonData = [responseDic JSONData];
                    NSString *saveAddress = [ACAddress getAddressWithFileName:fileNameID fileType:ACFile_Type_SyncData isTemp:NO subDirName:nil];
                    BOOL success = [jsonData writeToFile:saveAddress atomically:YES];
                    pAcConfigs.isSynced = YES;
                    self.loginState = LoginState_synchronized;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterSyncFinishNotifation object:nil];
                    [pAcConfigs updateApplicationUnreadCount];*/
                    [self doSyncData:responseDic needCheck:NO];
                }
                    break;
                case ACFile_Type_GetContactPersonRootList:
                {
                    NSArray *userGroups = [responseDic objectForKey:kUserGroups];
                    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[userGroups count]];
                    for (NSDictionary *group in userGroups)
                    {
                        ACUserGroup *userGroup = [[ACUserGroup alloc] init];
                        [userGroup setUserGroupDic:group];
                        [array addObject:userGroup];
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterGetContactPersonRootListNotifation object:array];
                }
                    break;
                case ACFile_Type_GetContactPersonSubGroupList:
                {
                    NSArray *userGroups = [responseDic objectForKey:kUserGroups];
                    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[userGroups count]];
                    for (NSDictionary *group in userGroups)
                    {
                        ACUserGroup *userGroup = [[ACUserGroup alloc] init];
                        [userGroup setUserGroupDic:group];
                        [array addObject:userGroup];
                    }
                    
                    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:array,kUserGroups,fileNameID,kGroupID, nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterGetContactPersonGroupListNotifation object:dic];
                }
                    break;
                case ACFile_Type_GetContactPersonSinglePersonList:
                {
                    NSArray *users = [responseDic objectForKey:@"users"];
                    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[users count]];
                    for (NSDictionary *userDic in users)
                    {
                        ACUser *user = [[ACUser alloc] init];
                        [user setUserDic:userDic];
                        [array addObject:user];
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterGetContactPersonSingleListNotifation object:array];
                }
                    break;
                case ACFile_Type_CreateGroupChat:
                {
                    ACTopicEntity *entity = [ACTopicEntityEvent topicEntityEventAddEntityWithEventDic:responseDic];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterCreateGroupChatNotifation object:entity];
                }
                    break;
                case ACFile_Type_GetContactPersonSearchList:
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterGetContactPersonSearchListNotifation object:responseDic];
                    /*
                    NSArray *users = [responseDic objectForKey:kUsers];
                    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[users count]];
                    for (NSDictionary *userDic in users)
                    {
                        ACUser *user = [[ACUser alloc] init];
                        [user setUserDic:userDic];
                        [array addObject:user];
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterGetContactPersonSearchListNotifation object:array];*/
                    
                }
                    break;
                case ACFile_Type_GetChatMessage:
                {
                    NSArray *topicArray = [responseDic objectForKey:kTopics];
                    NSMutableArray *topicMessageArray = [NSMutableArray arrayWithCapacity:[topicArray count]];
                    for (NSDictionary *dic in topicArray)
                    {
                        ACMessage *message = [ACMessage messageWithDic:dic];
                        if(message){
                            [topicMessageArray addObject:message];
                            [ACMessageDB saveMessageToDBWithMessage:message];
                        }
                    }
                    NSNumber *isLoadNew = object;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterGetChatMessageNotifation object:[NSDictionary dictionaryWithObjectsAndKeys:topicMessageArray,kMsgList,isLoadNew,kIsLoadNew, nil]];
                }
                    break;
                case ACFile_Type_SendHasBeenReadTopic:
                {
                    
                }
                    break;
                case ACFile_Type_SendText:
                case ACFile_Type_SendSticker:
                case ACFile_Type_SendLocation:
                case ACFile_Type_TransmitMsg:
                {
                    ACMessage *message = object;
                    NSString *sourceMessageID = message.messageID;
                    [message updateWithDic:responseDic];
                    [ACMessageDB saveMessageToDBWithMessage:message];
                    [_chatCenter sendMessage:message SuccessWithSourceMsgID:sourceMessageID];
//                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterSendMessageSuccessNotifation object:@[message,sourceMessageID]];
                }
                    break;
                case ACFile_Type_SendImage_Json:
                {
                    ACFileMessage *message = object;
                    NSString *sourceMessageID = message.messageID;
                    NSString *firstPath = [ACAddress getAddressWithFileName:message.resourceID fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
                    NSString *secondPath = [ACAddress getAddressWithFileName:message.thumbResourceID fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
                    
                    NSDictionary *topicDic = [responseDic objectForKey:kTopic];
                    [message updateWithDic:topicDic];
                    
                    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[[message content] objectFromJSONString]];
                    for (NSString *key in [topicDic allKeys])
                    {
                        [dic setObject:[topicDic objectForKey:key] forKey:key];
                    }
                    message.content = [dic JSONString];
                    
                    [ACMessageDB saveMessageToDBWithMessage:message];
                    
                    NSString *forever1 = [ACAddress getAddressWithFileName:message.resourceID fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
                    [[NSFileManager defaultManager] moveItemAtPath:firstPath toPath:forever1 error:nil];
                    
                    NSString *forever2 = [ACAddress getAddressWithFileName:message.thumbResourceID fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
                    [[NSFileManager defaultManager] moveItemAtPath:secondPath toPath:forever2 error:nil];
                    
                    [_chatCenter sendMessage:message SuccessWithSourceMsgID:sourceMessageID];
//                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterSendMessageSuccessNotifation object:@[message,sourceMessageID]];
                }
                    break;
                case ACFile_Type_SendFile_Json:
                {
                    ACFileMessage* pFileMessage = (ACFileMessage*)object;
                    NSString *sourceMessageID = pFileMessage.messageID;

                    NSString *extension = [[[pFileMessage name] componentsSeparatedByString:@"."] lastObject];
                    NSString *firstPath = [ACAddress getAddressWithFileName:pFileMessage.resourceID fileType:ACFile_Type_File isTemp:NO subDirName:extension];
                    
                    NSDictionary *topicDic = [responseDic objectForKey:kTopic];
                    [pFileMessage updateWithDic:topicDic];
                    
                    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[[pFileMessage content] objectFromJSONString]];
                    for (NSString *key in [topicDic allKeys])
                    {
                        [dic setObject:[topicDic objectForKey:key] forKey:key];
                    }
                    pFileMessage.content = [dic JSONString];
                    
                    [ACMessageDB saveMessageToDBWithMessage:pFileMessage];
                    
                    NSString *forever = [ACAddress getAddressWithFileName:pFileMessage.resourceID fileType:ACFile_Type_File isTemp:NO subDirName:extension];
                    [[NSFileManager defaultManager] moveItemAtPath:firstPath toPath:forever error:nil];
                    [_chatCenter sendMessage:pFileMessage SuccessWithSourceMsgID:sourceMessageID];
//                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterSendMessageSuccessNotifation object:@[pFileMessage,sourceMessageID]];
                }
                    break;
                case ACFile_Type_SendAudio_Json:
                {
                    ACMessage *message = object;
                    NSString *sourceMessageID = message.messageID;
                    NSString *firstPath = [ACAddress getAddressWithFileName:((ACFileMessage *)message).resourceID fileType:ACFile_Type_AudioFile isTemp:NO subDirName:nil];
                    
                    NSDictionary *topicDic = [responseDic objectForKey:kTopic];
                    [message updateWithDic:topicDic];
                    
                    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[[message content] objectFromJSONString]];
                    for (NSString *key in [topicDic allKeys])
                    {
                        [dic setObject:[topicDic objectForKey:key] forKey:key];
                    }
                    message.content = [dic JSONString];
                    
                    [ACMessageDB saveMessageToDBWithMessage:message];
                    
                    NSString *forever = [ACAddress getAddressWithFileName:((ACFileMessage *)message).resourceID fileType:ACFile_Type_AudioFile isTemp:NO subDirName:nil];
                    [[NSFileManager defaultManager] moveItemAtPath:firstPath toPath:forever error:nil];
                    [_chatCenter sendMessage:message SuccessWithSourceMsgID:sourceMessageID];
//                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterSendMessageSuccessNotifation object:@[message,sourceMessageID]];
                }
                    break;
                case ACFile_Type_SendVideo_Json:
                {
                    ACFileMessage *message = object;
                    NSString *sourceMessageID = message.messageID;
                    NSString *firstPath = [ACAddress getAddressWithFileName:message.resourceID fileType:ACFile_Type_VideoFile isTemp:NO subDirName:nil];
                    NSString *secondPath = [ACAddress getAddressWithFileName:message.thumbResourceID fileType:ACFile_Type_VideoThumbFile isTemp:NO subDirName:nil];
                    
                    NSDictionary *topicDic = [responseDic objectForKey:kTopic];
                    [message updateWithDic:topicDic];
                    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[[message content] objectFromJSONString]];
                    for (NSString *key in [topicDic allKeys])
                    {
                        [dic setObject:[topicDic objectForKey:key] forKey:key];
                    }
                    message.content = [dic JSONString];
                    
                    [ACMessageDB saveMessageToDBWithMessage:message];
                    NSString *forever1 = [ACAddress getAddressWithFileName:message.resourceID fileType:ACFile_Type_VideoFile isTemp:NO subDirName:nil];
                    [[NSFileManager defaultManager] moveItemAtPath:firstPath toPath:forever1 error:nil];
                    
                    NSString *forever2 = [ACAddress getAddressWithFileName:message.thumbResourceID fileType:ACFile_Type_VideoThumbFile isTemp:NO subDirName:nil];
                    [[NSFileManager defaultManager] moveItemAtPath:secondPath toPath:forever2 error:nil];

                    [_chatCenter sendMessage:message SuccessWithSourceMsgID:sourceMessageID];
//                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterSendMessageSuccessNotifation object:@[message,sourceMessageID]];
                }
                    break;
                case ACFile_Type_StickerFile:
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterDownloadStickerSuccessNotifation object:fileNameID];
                }
                    break;
                case ACFile_Type_VideoFile:
                {
                    ACFileMessage *fileMsg = object;
                    fileMsg.isDownloading = NO;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterDownloadVideoSuccessNotifation object:nil];
                }
                    break;
                case ACFile_Type_File:
                {
                    ACFileMessage *fileMsg = object;
                    fileMsg.isDownloading = NO;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterDownloadFileSuccessNotifation object:nil];
                }
                    break;
                case ACFile_Type_AudioFile:
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterDownloadAudioSuccessNotifation object:nil];
                }
                    break;
                case ACFile_Type_WallboardVideo:
                {
//                    ACNoteContentImageOrVideo* pVideo = object;
                    
                }
                    break;
                case ACFile_Type_GetParticipant_Json:
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterGetParticipantsNotifation object:responseDic];
                }
                    break;
                case ACFile_Type_AddParticipant_Json:
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterAddParticipantNotifation object:nil];
                }
                    break;
                case ACFile_Type_GetReadCount_Json:
                {
                    NSString *topicEntityID = fileNameID;
                    NSArray *result = [responseDic objectForKey:kResult];
                    
                    //保存readCount
                    NSArray *readCountArray = [ACReadCount getReadCountListWithArray:result withEntityID:topicEntityID];
                    [ACReadCountDB saveReadCountListToDBWithArray:readCountArray];
                    
                    //保存readSeq
                    ACReadSeq *readSeq = [[ACReadSeq alloc] init];
                    readSeq.topicEntityID = topicEntityID;
                    
                    long seq = [(ACReadCount *)[readCountArray lastObject] seq];
                    for (ACReadCount *readCount in readCountArray){
                        if (readCount.seq&&readCount.seq < seq){
                            seq = readCount.seq;
                        }
                    }
                    readSeq.seq = seq-1;
                    [ACReadSeqDB saveReadSeqToDBWithReadSeq:readSeq needUpdate:YES];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterGetReadCountNotifation object:readCountArray];
                }
                    break;
                case ACFile_Type_GetSingleReadSeq_Json:
                {
                    //保存readSeq
                    NSString *topicEntityID = fileNameID;
                    ACReadSeq *readSeq = [[ACReadSeq alloc] init];
                    readSeq.topicEntityID = topicEntityID;
                    readSeq.seq = [[responseDic objectForKey:kSeq] longValue];
                    [ACReadSeqDB saveReadSeqToDBWithReadSeq:readSeq needUpdate:YES];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterGetSingleReadSeqNotifation object:readSeq];
                }
                    break;
                case ACFile_Type_GetHadReadList_Json:
                {
//                    NSString *topicEntityID = fileNameID;
                    NSArray *readers = [responseDic objectForKey:@"readers"];
                    NSMutableArray *array = [NSMutableArray array];
                    for (NSDictionary *dic in readers)
                    {
                        ACUser *user = [[ACUser alloc] init];
                        [user setUserDic:dic];
                        [ACUserDB saveUserToDBWithUser:user];
                        [array addObject:user];
                    }
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterGetHadReadListNotifation object:array];
                }
                    break;
                case ACFile_Type_StickerDir_Json:
                {
                    NSData *data = [NSData dataWithContentsOfFile:saveAddress];
                    NSArray *array = [data objectFromJSONData];
                    NSArray *stickerPackageArray = [ACStickerPackage getStickerPackageArrayWithDicArray:array];
                    [ACDataCenter shareDataCenter].stickerPackageArray = stickerPackageArray;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterStickerDirJsonRecvNotifation object:nil];
                    
                    for (ACStickerPackage *package in stickerPackageArray)
                    {
                        [self getThumbnailStickerWithPath:package.path thumbnail:package.thumbnail title:package.title];
//                        [self getStickerZipWithTitle:package.title];
                    }
                }
                    break;
                case ACFile_Type_StickerThumbnail:
                {
                    
                }
                    break;
                case ACFile_Type_StickerZip:
                {
                    for (ACStickerPackage *package in [ACDataCenter shareDataCenter].stickerPackageArray)
                    {
                        if ([package.title isEqualToString:fileNameID])
                        {
                            package.isDownloading = NO;
                            break;
                        }
                    }
                    NSString *toPath = [ACAddress getAddressWithFileName:nil fileType:ACFile_Type_StickerZip isTemp:NO subDirName:fileNameID];
                    BOOL isSuccess = [[ACDataCenter shareDataCenter] unZipFromPath:saveAddress toPath:toPath];
                    if (isSuccess)
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterStickerZipDownloadSuccNotifation object:fileNameID];
                    }
                    else
                    {
                        [[NSFileManager defaultManager] removeItemAtPath:saveAddress error:nil];
                    }
                }
                    break;
                case ACFile_Type_LocationAlert:
                {
                    
                }
                    break;
//                case ACFile_Type_LocationScan:
//                {
//                    
//                }
//                    break;
//                case ACFile_Type_Note_SendComment:
//                {
//                    if([object isKindOfClass:[ACNoteComment class]]){
//                        [(ACNoteComment *)object sendSuccessWithResponseDic:[responseDic objectForKey:@"comment"]];
//                    }
//                }
//                    break;
     
                case ACFile_Type_SendNoteOrWallboard:
                {
                    self.sendNoteOrWallboardRequest = nil;
                    
                    if([object isKindOfClass:[ACWallBoard_Message class]]){
                        [(ACWallBoard_Message *)object sendSuccessWithResponseDic:responseDic];
                    }
                    else{
                        NSAssert([object isKindOfClass:[ACNoteMessage class]],@"ACFile_Type_SendNoteOrWallboard Error");
                        [(ACNoteMessage *)object sendSuccessWithResponseDic:responseDic forWallBoard:NO];
                    }
                    
                    /*WB
                    ACWallBoardMessage *noteMsg = (ACWallBoardMessage *)object;
                    noteMsg.createTime = [[responseDic objectForKey:kCreateTime] doubleValue];
                    NSDictionary *idmapDic = [responseDic objectForKey:kIdmap];
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    for (NSString *key in [idmapDic allKeys])
                    {
                        for (ACWallBoardFilePage *page in noteMsg.multiArray)
                        {
                            if ([page.resourceID isEqualToString:key])
                            {
                                page.resourceID = [idmapDic objectForKey:key];
                                
                                NSString *sourcePath = [ACAddress getAddressWithFileName:[key stringByAppendingString:@"_m"] fileType: [page.type isEqualToString:image]?ACFile_Type_WallboardPhoto:ACFile_Type_WallboardVideo isTemp:NO subDirName:nil];
                                if ([fileManager fileExistsAtPath:sourcePath])
                                {
                                    //全屏图名字替换成大图名
                                    NSString *objectPath = [ACAddress getAddressWithFileName:page.resourceID fileType: [page.type isEqualToString:image]?ACFile_Type_WallboardPhoto:ACFile_Type_WallboardVideo isTemp:NO subDirName:nil];
                                    if ([fileManager fileExistsAtPath:sourcePath] && ![fileManager fileExistsAtPath:objectPath])
                                    {
                                        [fileManager moveItemAtPath:sourcePath toPath:objectPath error:nil];
                                    }
                                    
                                    //原图删除
                                    sourcePath = [ACAddress getAddressWithFileName:key fileType: [page.type isEqualToString:image]?ACFile_Type_WallboardPhoto:ACFile_Type_WallboardVideo isTemp:NO subDirName:nil];
                                    
                                    if ([fileManager fileExistsAtPath:sourcePath])
                                    {
                                        [fileManager removeItemAtPath:sourcePath error:nil];
                                    }
                                }
                                else
                                {
                                    sourcePath = [ACAddress getAddressWithFileName:key fileType: [page.type isEqualToString:image]?ACFile_Type_WallboardPhoto:ACFile_Type_WallboardVideo isTemp:NO subDirName:nil];
                                    
                                    NSString *objectPath = [ACAddress getAddressWithFileName:page.resourceID fileType: [page.type isEqualToString:image]?ACFile_Type_WallboardPhoto:ACFile_Type_WallboardVideo isTemp:NO subDirName:nil];
                                    if ([fileManager fileExistsAtPath:sourcePath] && ![fileManager fileExistsAtPath:objectPath])
                                    {
                                        [fileManager moveItemAtPath:sourcePath toPath:objectPath error:nil];
                                    }
                                }
                                break;
                            }
                            else if ([page.thumbResourceID isEqualToString:key])
                            {
                                page.thumbResourceID = [idmapDic objectForKey:key];
                                
                                NSString *sourcePath = [ACAddress getAddressWithFileName:key fileType: [page.type isEqualToString:image]?ACFile_Type_WallboardPhoto:ACFile_Type_WallboardVideo isTemp:NO subDirName:nil];
                                
                                NSString *objectPath = [ACAddress getAddressWithFileName:page.thumbResourceID fileType: [page.type isEqualToString:image]?ACFile_Type_WallboardPhoto:ACFile_Type_WallboardVideo isTemp:NO subDirName:nil];
                                NSFileManager *fileManager = [NSFileManager defaultManager];
                                if ([fileManager fileExistsAtPath:sourcePath] && ![fileManager fileExistsAtPath:objectPath])
                                {
                                    [fileManager moveItemAtPath:sourcePath toPath:objectPath error:nil];
                                }
                                break;
                            }
                        }
                    }
                    NSDictionary *postDic = [noteMsg getContentDicIsNeedHeight:YES];
                    noteMsg.content = [postDic JSONString];
                    
                    [ACMessageDB saveMessageToDBWithMessage:noteMsg];
                    
                    if ([ACDataCenter shareDataCenter].wallboardTopicEntity)
                    {
                        //保存noteMessage成功后修改wallboard的lastestMessageTime,保存数据库，allEntityArray重新排序
                        [ACDataCenter shareDataCenter].wallboardTopicEntity.lastestMessageTime = noteMsg.createTime;
                        [ACTopicEntityDB saveTopicEntityToDBWithTopicEntity:[ACDataCenter shareDataCenter].wallboardTopicEntity];
                        [ACTopicEntityEvent UpdateEntityToArray:[ACDataCenter shareDataCenter].allEntityArray entity:[ACDataCenter shareDataCenter].wallboardTopicEntity];
                    }
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterSendWallboardSuccNotifation object:noteMsg];
                    ITLog(@"ACFile_Type_SendWallboard 上传完成");*/
                }
                    break;
                case ACFile_Type_SearchNote:
                {
                    NSArray* pNotes = [responseDic objectForKey:@"notes"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterSearchNoteNotifation object:[[NSMutableArray alloc] initWithArray:pNotes]];
                }
                    
                    break;
                case ACFile_Type_SearchMessage:
                {
                    NSArray *topics = [responseDic objectForKey:kTopics];
                    NSMutableArray *topicArray = [[NSMutableArray alloc] initWithCapacity:[topics count]];
                    for (NSDictionary *topicDic in topics)
                    {
                        ACMessage *message = [ACMessage messageWithDic:topicDic];
                        [topicArray addObject:message];
                    }
                    
                    NSArray *tes = [responseDic objectForKey:kTes];
                    NSMutableArray *entityArray = [[NSMutableArray alloc] initWithCapacity:[tes count]];
                    for (NSDictionary *entityDic in tes)
                    {
                        ACTopicEntity *entity = [[ACTopicEntity alloc] initWithTopicDic:entityDic];
                        [entityArray addObject:entity];
                    }
                    NSDictionary *msgAndEntityDic = [NSDictionary dictionaryWithObjectsAndKeys:topicArray,kTopics,entityArray,kTes, nil];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterSearchMessageNotifation object:msgAndEntityDic];
                }
                    break;
                case ACFile_Type_SearchUser:
                {
                    NSArray *users = [responseDic objectForKey:kUsers];
                    NSMutableArray *userArray = [[NSMutableArray alloc] initWithCapacity:[users count]];
                    for (NSDictionary *userDic in users)
                    {
                        ACUser *user = [[ACUser alloc] init];
                        [user setUserDic:userDic];
                        [ACUserDB saveUserToDBWithUser:user];
                        [userArray addObject:user];
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterSearchUserNotifation object:userArray];
                }
                    break;
                case ACFile_Type_SearchUserGroup:
                {
                    NSArray *usergroups = [responseDic objectForKey:kUsergroups];
                    NSMutableArray *userGroupArray = [[NSMutableArray alloc] initWithCapacity:[usergroups count]];
                    for (NSDictionary *userGroupDic in usergroups)
                    {
                        ACUserGroup *userGroup = [[ACUserGroup alloc] init];
                        [userGroup setUserGroupDic:userGroupDic];
                        [userGroupArray addObject:userGroup];
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterSearchUserGroupNotifation object:userGroupArray];
                }
                    break;
//                case ACFile_Type_SearchHighLight:
//                {
//                    NSArray *highlights = [responseDic objectForKey:kHighlights];
//                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterSearchHighLightNotifation object:[NSDictionary dictionaryWithObject:highlights forKey:object]];
//                }
//                    break;
                case ACFile_Type_SearchCount:
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterSearchCountNotifation object:responseDic];
                }
                    break;
                case ACFile_Type_ChangePassword:
                {
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    [defaults setObject:object forKey:kPwd];
                    [defaults synchronize];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterChangePasswordNotifation object:nil];
                }
                    break;
                case ACFile_Type_GetCategories:
                {
                    NSArray *categories = [ACStickerCategory categoryArrayWithDicArray:[responseDic objectForKey:kCategories]];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterGetCategoriesNotifation object:categories];
                }
                    break;
                case ACFile_Type_GetSuitsOfCategory:
                {
                    NSArray *suits = [ACSuit suitArrayWithDicArray:[responseDic objectForKey:kSuits]];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterGetSuitsOfCategoryNotifation object:suits];
                }
                    break;
                case ACFile_Type_GetUserOwnStickers:
                {
                    NSArray *suits = [ACSuit suitArrayWithDicArray:[responseDic objectForKey:kSuits]];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterGetUserOwnStickersNotifation object:suits];
                }
                    break;
                case ACFile_Type_RemoveUserOwnSticker:
                {
                    NSString *suitID = object;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterRemoveUserOwnStickerNotifation object:suitID];
                }
                    break;
                case ACFile_Type_AddStickerSuitToMyStickersAndDownload:
                {
                    ACSuit *suit = object;
                    NSString *toPath = [ACAddress getAddressWithFileName:suit.suitID fileType:ACFile_Type_AddStickerSuitToMyStickersAndDownload isTemp:NO subDirName:suit.suitID];
                    BOOL isSuccess = [[ACDataCenter shareDataCenter] unZipFromPath:saveAddress toPath:toPath];
                    [[NSFileManager defaultManager] removeItemAtPath:saveAddress error:nil];
                    
                    [self getSuitWithSuitID:suit.suitID];
                    
                    [suit removeObserver:self forKeyPath:kProgress];
                    [_suitDownloadDic removeObjectForKey:suit.suitID];
                    
//                    NSData *data = [NSData dataWithContentsOfFile:saveAddress];
//                    data = [data gunzippedData];
//                    [data writeToFile:saveAddress atomically:YES];
                    if (isSuccess)
                    {
                        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                        NSArray *suits = [defaults objectForKey:kDownloadSuitList];
                        NSMutableArray *downloadSuits = [NSMutableArray arrayWithArray:suits];
                        if ([downloadSuits containsObject:suit.suitID])
                        {
                            [downloadSuits removeObject:suit.suitID];
                        }
                        [downloadSuits insertObject:suit.suitID atIndex:0];
                        [defaults setObject:downloadSuits forKey:kDownloadSuitList];
                        [defaults synchronize];
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterAddAndSuitDownloadNotifation object:suit];
                    }
                    else
                    {
                        ITLogEX(@"ACFile_Type_AddStickerSuitToMyStickersAndDownload unZip failed");
                    }
                }
                    break;
                case ACFile_Type_DownloadSuit:
                {
                    ACSuit *suit = object;
                    NSString *toPath = [ACAddress getAddressWithFileName:suit.suitID fileType:ACFile_Type_DownloadSuit isTemp:NO subDirName:suit.suitID];
                    BOOL isSuccess = [[ACDataCenter shareDataCenter] unZipFromPath:saveAddress toPath:toPath];
                    [[NSFileManager defaultManager] removeItemAtPath:saveAddress error:nil];
                    
                    [self getSuitWithSuitID:suit.suitID];
                    
                    [suit removeObserver:self forKeyPath:kProgress];
                    [_suitDownloadDic removeObjectForKey:suit.suitID];
//                    NSData *data = [NSData dataWithContentsOfFile:saveAddress];
//                    data = [data gunzippedData];
//                    [data writeToFile:saveAddress atomically:YES];
                    if (isSuccess)
                    {
                        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                        NSArray *suits = [defaults objectForKey:kDownloadSuitList];
                        NSMutableArray *downloadSuits = [NSMutableArray arrayWithArray:suits];
                        [downloadSuits insertObject:suit.suitID atIndex:0];
                        [defaults setObject:downloadSuits forKey:kDownloadSuitList];
                        [defaults synchronize];
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterSuitDownloadNotifation object:suit];
                    }
                    else
                    {
                        ITLogEX(@"ACFile_Type_DownloadSuit unZip failed");
                    }
                }
                    break;
                case ACFile_Type_DownloadSticker:
                {
                    NSString *resoureID = object;
//                    BOOL isNotNull = requestTemp.responseData.length!=0;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [_stickerDownloadingArray removeObject:resoureID];
//                        if(isNotNull)
                        {
                            [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterDownloadStickerNotifation object:nil];
                        }
                    });
                }
                    break;
                case ACFile_Type_GetAllSuits:
                {
                    NSArray *suits = [ACSuit suitArrayWithDicArray:[responseDic objectForKey:kSuits]];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterGetAllSuitsNotifation object:suits];
                }
                    break;
                case ACFile_Type_GetSuitInfo:
                {
                    NSDictionary *suitDic = [responseDic objectForKey:kSuit];
                    if (suitDic)
                    {
                        [suitDic writeToFile:saveAddress atomically:YES];
                        [self renameSuitImageWithSuitDic:suitDic];
                    }
                }
                    break;
//                case ACFile_Type_Note_List_Json:
//                {
//                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterNotes_Note_LoadList_Notifition object:[responseDic objectForKey:@"notes"]];
//                }
//                    break;
//                case ACFile_Type_NoteComment_List_Json:
//                {
//                    [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterNotes_Comment_LoadList_Notifition object:[responseDic objectForKey:@"comments"]];
//                }
//                    break;
                default:
                    break;
            }
        });
    }];
    [request setFailedBlock:^{
        [self _nowUsedASIHTTPRequests:requestTemp forAdd:NO];
        if(progressDelegate){
            [self _delDownloadingWithProgressForRequest:requestTemp];
        }
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            ITLogEX_Simple(@"%@ %@ \n%@ %@ netCenter失败",_DebugEndTitle,urlString,requestTemp,[requestTemp error].userInfo);
            if (fileType == ACFile_Type_LoopInquire ||
                fileType == ACFile_Type_LoginJson ||
                fileType == ACFile_Type_SecondLoginJson)
            {
                [ACConfigs shareConfigs].loginState = LoginState_waiting;
                [self delayAfterLoopInquire];
            }
            else if (fileType == ACFile_Type_VideoFile|| fileType==ACFile_Type_WallboardVideo)
            {
                if ([[NSFileManager defaultManager] fileExistsAtPath:saveAddress])
                {
                    [[NSFileManager defaultManager] removeItemAtPath:saveAddress error:nil];
//TXB 避免使用.mm                   throw 1;
                }
            }
            else if (fileType == ACFile_Type_SendText ||
                     fileType == ACFile_Type_SendLocation ||
                     fileType == ACFile_Type_SendSticker ||
                     fileType == ACFile_Type_SendImage_Json ||
                     fileType == ACFile_Type_SendAudio_Json ||
                     fileType == ACFile_Type_SendVideo_Json ||
                     fileType == ACFile_Type_TransmitMsg)
            {
                [_chatCenter resendMessage:(ACMessage*)object];
            }
            else if (fileType == ACFile_Type_StickerZip)
            {
                for (ACStickerPackage *package in [ACDataCenter shareDataCenter].stickerPackageArray)
                {
                    if ([package.title isEqualToString:fileNameID])
                    {
                        package.isDownloading = NO;
                        break;
                    }
                }
            }
            else if (fileType == ACFile_Type_SendNoteOrWallboard)
            {
                self.sendNoteOrWallboardRequest = nil;
                [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterNotes_Note_Upload_Fail_Notifition object:object];
                ITLogEX(@"ACFile_Type_SendWallboard 上传失败");
            }
            else if (fileType == ACFile_Type_Logout)
            {
//                pAcConfigs.isLogouting = NO;
            }
            else if (fileType == ACFile_Type_GetChatMessage){
                [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterGetChatMessageNotifation object:nil];
            }
            else if (fileType == ACFile_Type_SendHasBeenReadTopic)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterNetworkFailNotifation object:nil];
            }
            else if (fileType == ACFile_Type_GetReadCount_Json)
            {
                NSString *topicEntityID = fileNameID;
                NSArray *array = object;
                
                NSArray *readCountArray = [ACReadCount getFailReadCountListWithArray:array withEntityID:topicEntityID];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterGetReadCountFailNotifation object:readCountArray];
            }
            else if (fileType == ACFile_Type_GetSingleReadSeq_Json)
            {
                NSString *topicEntityID = fileNameID;
                ACReadSeq *readSeq = [[ACReadSeq alloc] init];
                readSeq.topicEntityID = topicEntityID;
                readSeq.seq = -1;
                [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterGetReadSeqFailNotifation object:readSeq];
            }
        });
    }];
    if (fileType == ACFile_Type_VideoFile
        || fileType == ACFile_Type_AudioFile
        || fileType == ACFile_Type_StickerFile
        || fileType == ACFile_Type_StickerThumbnail
        || fileType == ACFile_Type_StickerZip
        || fileType == ACFile_Type_File
        || fileType == ACFile_Type_StickerDir_Json
        || fileType == ACFile_Type_DownloadSuit
        || fileType == ACFile_Type_DownloadSticker
        || fileType == ACFile_Type_AddStickerSuitToMyStickersAndDownload
        || fileType == ACFile_Type_WallboardVideo
        )
    {
        [request setDownloadDestinationPath:saveAddress];
        [request setTemporaryFileDownloadPath:tempAddress];
        if (progressDelegate){
            [self _addDownloadingWithProgress:progressDelegate withRequest:requestTemp];
            [request setShowAccurateProgress:YES];
            [request setDownloadProgressDelegate:progressDelegate];
        }
    }
    else if (fileType == ACFile_Type_SendNoteOrWallboard)
    {
        self.sendNoteOrWallboardRequest = request;
        if (progressDelegate){
            [request setShowAccurateProgress:YES];
            [request setUploadProgressDelegate:progressDelegate];
        }
    }
    [request setShouldContinueWhenAppEntersBackground:YES];
    [self _nowUsedASIHTTPRequests:request forAdd:YES];
    [request startAsynchronous];
//    ITLogEX(([NSString stringWithFormat:@"startAsynchronous fileType = %d",fileType]));
}

//得到requestHeader
-(NSMutableDictionary *)getRequestHeader
{
    //aclaccount aclterminal  aclsid  acldomain  s
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:5];
    NSString *aclSid = [defaults objectForKey:kAclSid];
    if ([aclSid length]>0)
    {
        [dic setObject:aclSid forKey:kAclSid];
    }
    
    NSString *s = [defaults objectForKey:kS];
    if ([s length]>0)
    {
        [dic setObject:s forKey:kS];
    }
    
    NSString *aclDomain = [defaults objectForKey:kAclDomain];
    if ([aclDomain length]>0)
    {
        [dic setObject:aclDomain forKey:kAclDomain];
    }
    
    NSString *userID = [defaults objectForKey:kUserID];
    if ([userID length]>0)
    {
        [dic setObject:userID forKey:@"aclaccount"];
    }
    [dic setObject:@"ios" forKey:kAclTerminal];
    if (_cancelID)
    {
        [dic setObject:_cancelID forKey:kCid];
    }
    return dic;
}


//得到requestMethod
-(NSString *)getRequestMethodWithType:(int)type
{
    switch (type)
    {
        case requestMethodType_Get:
            return @"get";
            break;
        case requestMethodType_Post:
            return @"post";
            break;
        case requestMethodType_Put:
            return @"put";
            break;
        case requestMethodType_Delete:
            return @"delete";
            break;
        default:
            return @"";
            break;
    }
}


/*好像没用
#pragma mark -reachability

-(void)reachabilityChanged:(NSNotification *)noti
{
//    Reachability *reach = [noti object];
//    NetworkStatus status = [reach currentReachabilityStatus];
//    if (status != NotReachable && self.previousStatus == NotReachable)
//    {
//        [self loopInquire];
//    }
//    self.previousStatus = status;
}

-(void)radioAccessChanged
{
//    [self loopInquire];
}

#pragma mark -notification
-(void)monitorReachabilityStart
{
    //监听网络状态
    self.networkRech = [Reachability reachabilityWithHostName:[[ACConfigs acOem_ConfigInfo] objectForKey:@"loginServer"]];
    [_networkRech startNotifier];
    
}

-(void)monitorReachabilityStop
{
    //监听网络状态

    [_networkRech stopNotifier];
    self.networkRech = nil;
}
 
 好像没用*/

@end


