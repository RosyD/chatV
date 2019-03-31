//
//  ACConfigs.m
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-27.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACConfigs.h"
#import "ACAppDelegate.h"
#import "ACLoginViewController2.h"
//#import "IIViewDeckController.h"
#import "MMDrawerController.h"
#import "UIViewController+MMDrawerController.h"
#import "ACDBManager.h"
#import "ACAddress.h"
#import "ACDataCenter.h"
#import "ACRootViewController.h"
#import "ACChatViewController.h"
#import "ACMessage.h"
#import "UINavigationController+Additions.h"
#import "ACLocationSettingViewController.h"
#import "ACNetCenter+Notes.h"
#import "ACUser.h"
#import "ACVideoCall.h"
#import "SDImageCache.h"
#import "ACVideoCall.h"

#define kNotificationCfg_Name   @"Notification"


#define SDImageCache_MAX_SIZE   300*1024*1024   //缓存最大


#define AlertView_ID_For_AppVersionCheck_Update         1367    //需要更新
#define AlertView_ID_For_AppVersionCheck_Update_Force   1368    //强制更新
//#define AlertView_ID_For_presentLoginVC                 1000    //显示登录界面

NSString *const kHotspotOpenStateChangeNotification = @"kHotspotOpenStateChangeNotification";
NSString* const kNoteOrCommentUpdateTimeChanged = @"Note或Comment的阅读时间更新"; //参数为NSNumber,0,1表示是否显示或隐藏铃铛提示标识
NSString* const kHaveNewAppVerion = @"HaveNewAppVerion";

NSString* const kNotificationLocationChanged =  @"LocationChanged";

static ACConfigs *_shareConfigs = nil;

@implementation ACConfigs

+(ACConfigs *)shareConfigs
{
    if (!_shareConfigs)
    {
        _shareConfigs = [[ACConfigs alloc] init];
    }
    return _shareConfigs;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _loginState =   LoginState_waiting;
//        _isLogined = NO;
//        _isSynced = NO;
//        _isLogouting = NO;
//        _isLogoutedNeedLogin = NO;
        _isInWebPage = NO;
        _currentSuitIndex = 1;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        NSNumber* pNotifyication =  [defaults objectForKey:kNotificationCfg_Name];
        if(pNotifyication){
            _notificationCfg =  pNotifyication.intValue;
        }
        else{
            //兼容旧的版本
            _notificationCfg    =   0xFFFF;

            pNotifyication =  [defaults objectForKey:@"kVibarteOn"];
            if(pNotifyication&&(!pNotifyication.boolValue)){
                _notificationCfg    ^=  NotificationCfg_VibarteOn;
            }
            pNotifyication =  [defaults objectForKey:@"kSoundOn"];
            if(pNotifyication&&(!pNotifyication.boolValue)){
                _notificationCfg    ^=  NotificationCfg_SoundOn;
            }
            pNotifyication =  [defaults objectForKey:@"notify"];
            [self _notificationCfgSave:NotificationCfg_ON forSave:pNotifyication&&pNotifyication.boolValue];
        }
        _deviceToken = [defaults objectForKey:kDeviceToken];
        if(nil==_deviceToken){
            _deviceToken = @"";
        }
        [self _setChatTextFont:self.chatTextFontSizeNo];
      }
    return self;
}

-(void)_setChatTextFont:(NSInteger)nFontNo{
    //14,18,25
    _chatTextFont   =   [UIFont systemFontOfSize:nFontNo>1?24:(nFontNo?16:12)];
}

-(NSInteger)chatTextFontSizeNo{
    NSNumber* fontNo = [[NSUserDefaults standardUserDefaults] objectForKey:kFontSize];
    if(fontNo){
        return fontNo.integerValue;
    }
    //缺省是1 中字体
    return 1;
//    return ((NSNumber*)[[NSUserDefaults standardUserDefaults] objectForKey:kFontSize]).integerValue;
}

-(void)setchatTextFontSizeNo:(NSInteger)nFontNo{
    [self _setChatTextFont:nFontNo];
    [[NSUserDefaults standardUserDefaults] setObject:@(nFontNo) forKey:kFontSize];
}

-(void)setDeviceToken:(NSString*)newValue{
    if(![newValue isEqualToString:_deviceToken]){
        _deviceToken =  newValue;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:_deviceToken forKey:kDeviceToken];
        [defaults synchronize];
    }
}


+(BOOL)isPhone5
{
    if([[UIDevice currentDevice].model hasPrefix:@"iPad"]){
        //特别处理iPad///
        
        return YES;
    }

    //对iphone4特殊处理，其实已经不必要了
    return [UIScreen mainScreen].currentMode.size.height>=1136;
    
//    return ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO);
}

//+(BOOL)isIOS8{
//    return ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0);
//}

-(void)chageNoteLastTimeForNewUpdateTime:(long long)updateTime{ //当发送新的Note和Comment时更新
    if(updateTime<=_latestNoteTime&&
       updateTime<=_currentNoteTime){
        return;
    }
    
    //并不通知服务器
    
    _latestNoteTime =   _currentNoteTime =  updateTime;
    [ACUtility postNotificationName:kNoteOrCommentUpdateTimeChanged object:@(NO)];
}

-(void)chageNoteLastTimeForTimeLine:(long long)lastTime{
    if(lastTime<_latestNoteTime){
        //Note被删除后的修补
        _latestNoteTime =   lastTime;
    }
    if(![self chageNoteLastTime:lastTime andCurTime:lastTime]){
        [ACUtility postNotificationName:kNoteOrCommentUpdateTimeChanged object:@(NO)];
    }
}


-(void)chageNoteLastTimeForRefreshNoteOrComment:(long long)lastTime{
    [self chageNoteLastTime:lastTime andCurTime:lastTime];
}

-(BOOL)chageNoteLastTime:(long long)lastTime andCurTime:(long long)curTime{
    
    BOOL bShowTip = NO;
    
    if(lastTime==curTime){
        //无论通过刷新Timeline或者是获取NoteList， CommentList列表得到的最大的updateTime， 如果大于latestNoteTime， 就赋值给latestNoteTime和currentNoteTime， 并同时发送已读请求（currentNoteTime）到服务器， 如果此时网络不好， 尽可能在网络恢复时从新发送有效的已读请求（这个重发一度请求的功能可以放到下个版本）。 此时两个数值相等， 取消小铃铛的红点显示。
        
        if(lastTime<=_latestNoteTime&&
           lastTime<=_currentNoteTime){
            return NO;
        }
        _latestNoteTime =   _currentNoteTime =  lastTime;
        
        [ACNetCenter callURL:[NSString stringWithFormat:@"%@/rest/apis/note/read?t=%lld",[[ACNetCenter shareNetCenter] acucomServer],lastTime]
                      forPut:YES
                withPostData:nil
                   withBlock:nil];
        
    }
    else if(lastTime<0){
        /*
         通过通道收到Note已读事件， 如果updateTime大于currentNoteTime， 则赋值给currentNoteTime。 如果lateNoteTime小于currentNoteTime， 就在小铃铛上取消掉红点
         */
        if(curTime<=_currentNoteTime){
            return NO;
        }
        _currentNoteTime    =   curTime;
        bShowTip    =   _latestNoteTime>_currentNoteTime;
    }
    else{
        /*
         通过每次通道sync会得到"noteTime"， 如果该"noteTime"大于latestNoteTime， latestNoteTime = "noteTime"。 如果lateNoteTime大于currentNoteTime， 就在小铃铛上显示红点。
         收到新增Note或新增Comment事件时， 判断如果updateTime大于latestNoteTime， 就赋值给latestNoteTime。 如果lateNoteTime大于currentNoteTime， 就在小铃铛上显示红点
         */
        if(lastTime<=_latestNoteTime){
            return NO;
        }
        
        _latestNoteTime =   lastTime;
        bShowTip    =   _latestNoteTime>_currentNoteTime;
    }
    
    [ACUtility postNotificationName:kNoteOrCommentUpdateTimeChanged object:@(bShowTip)];
    return YES;
}

-(void)setLocation:(CLLocationCoordinate2D)location{
    _location_old   =   _location;
    _location = location;
}

//新消息播放声音
-(void)newMessageSoundPlay
{
//#if 0
//#if !TARGET_IPHONE_SIMULATOR
//    if([ACVideoCall inVideoCall]){
//        return;
//    }
//    
//    if (!_player){
//        NSError *error = nil;
//        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"newMessageSound.mp3" ofType:nil]] error:&error];
//        _player.volume = 1.0;
//        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
//    }
//    [_player play];
//#endif
//#endif

}

#pragma mark -get set方法
-(NSMutableArray *)currentPresentVCList
{
    if (!_currentPresentVCList)
    {
        _currentPresentVCList = [[NSMutableArray alloc] init];
    }
    return _currentPresentVCList;
}

//得到RootViewController
+(UIViewController *)getRootViewController
{
//    ACAppDelegate *delegate = [UIApplication sharedApplication].delegate;
//    IIViewDeckController *deckC = (IIViewDeckController *)delegate.window.rootViewController;
//    UINavigationController *navC = (UINavigationController *)(deckC.leftController);
    
    MMDrawerController* deckC = (MMDrawerController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    UINavigationController *navC = (UINavigationController *)(deckC.leftDrawerViewController);
    
    UIViewController *vc = nil;
    if ([navC.viewControllers count] > 0)
    {
        vc = [navC.viewControllers objectAtIndex:0];
    }
    return vc;
}

+(ACChatViewController*)toAllChatViewController
{

    ACRootViewController *rootVC = (ACRootViewController *)[self getRootViewController];

    {
        NSArray *viewControllers = [(UINavigationController *)(rootVC.mm_drawerController.centerViewController) viewControllers];
        if (1==viewControllers.count&&
            [viewControllers[0] isKindOfClass:[ACChatViewController class]])
        {
            return viewControllers[0];
        }
    }
    
    //特别针对第一次登录处理,不用再创建ACChatViewController为CenterView
    [rootVC showChatViewController];
    
    return nil;
    
    /* txb ????,不知道这些工作是神马？
    UIViewController *viewController = [[ACChatViewController alloc] init];
    if ([viewController isKindOfClass:[ACChatViewController class]])
    {
        ACChatViewController *chatVC = (ACChatViewController *)viewController;
        [chatVC setChatListType:ACCenterViewControllerType_All];
        [chatVC setChatListTitle:kAll];
    }
    if (viewController)
    {
        UINavigationController *navC = [[UINavigationController alloc] initWithRootViewController:viewController];
        [navC setNavigationBarHidden:YES];
        
//        UINavigationController *navCTmp = (UINavigationController *)(rootVC.viewDeckController.centerController);
//        NSArray *viewControllers = [(UINavigationController *)(rootVC.viewDeckController.centerController) viewControllers];
        UINavigationController *navCTmp = (UINavigationController *)(rootVC.mm_drawerController.centerViewController);
        NSArray *viewControllers = [navCTmp viewControllers];
        if ([viewControllers count] > 1)
        {
            [navCTmp ACpopToRootViewControllerAnimated:NO];
        }
        UIViewController *vc = [viewControllers objectAtIndex:0];
        if ([vc respondsToSelector:@selector(removeNotification)])
        {
            [vc performSelector:@selector(removeNotification)];
        }
        rootVC.mm_drawerController.centerViewController =   navC;
//        [rootVC.viewDeckController setCenterController:navC];
    }*/
}

+(void)dismissCurrentPresent
{
    ITLog(@"TXB");
    NSMutableArray *currentPresentVC = [ACConfigs shareConfigs].currentPresentVCList;
    for (int i = (int)[currentPresentVC count]-1; i >= 0; i--)
    {
        UIViewController *vc = [currentPresentVC objectAtIndex:i];
        if (![vc isKindOfClass:[ACRootViewController class]])
        {
            [vc ACdismissViewControllerAnimated:NO completion:nil];
        }
    }
}

-(BOOL)loginVCShowed{ //是否显示了

    for(UIViewController* pVC  in _currentPresentVCList){
        if([pVC isKindOfClass:[ACLoginViewController2 class]]){
            NSAssert([_currentPresentVCList.lastObject isKindOfClass:[ACLoginViewController2 class]],@"[_currentPresentVCList.lastObject isKindOfClass:[ACLoginViewController2 class]]");
            return YES;
        }
    }
    return NO;
//    return [_currentPresentVCList.lastObject isKindOfClass:[ACLoginViewController2 class]];
}

+(void)clearUserPWDForDisableAutoLogin{
    //清除用户密码,避免自动登录
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"" forKey:kPwd];
    [defaults setObject:@"" forKey:kAcuComWssInfo];
    [defaults synchronize];
}

+(UIViewController*)getTopViewController{
    MMDrawerController* deckC = (MMDrawerController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    if(deckC.openSide!=MMDrawerSideNone){
        [deckC closeDrawerAnimated:NO completion:nil];
    }
    
    //取得最前面的VC
    UIViewController *topVC = ((UINavigationController *)(deckC.centerViewController)).visibleViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    
    return topVC;
}

+(BOOL)notificationCfgIsOn:(int)nCfgType{
    return nCfgType==(nCfgType&_shareConfigs.notificationCfg);
}

-(void)_notificationCfgSave:(int)nCfgType forSave:(BOOL)forSave{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(forSave){
        _notificationCfg    |=  nCfgType;
    }
    else{
        _notificationCfg    ^=  nCfgType;
    }
    [defaults setObject:@(_notificationCfg) forKey:kNotificationCfg_Name];
    [defaults synchronize];
}
+(void)notificationCfgSave:(int)nCfgType forSave:(BOOL)forSave{
    [_shareConfigs _notificationCfgSave:nCfgType forSave:forSave];
}

/*
#define kNotifyication  @"notify"
+(BOOL)remoteNotification:(int)nFuncType{ //远程notification功能,0:get sync:(1:true -1:false) change(2:true -2:false)
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber* pNotifyication =  [defaults objectForKey:kNotifyication];
    
    if(0==nFuncType){
        return pNotifyication?pNotifyication.boolValue:YES;
    }
    
    BOOL bOpen =    nFuncType>0;

    if(nFuncType==1||nFuncType==-1){
        //检查
        if(pNotifyication&&pNotifyication.boolValue==bOpen){
            return bOpen;
        }
    }

    不能在这里调用服务器功能，有可能失败,需要在别处调用
     if(nFuncType==2||nFuncType==-2){
        http:{amhost}/rest/apis/chat/notification  Post  关闭
        http:{amhost}/rest/apis/chat/notification  Delete  打开
     }
     
 

    [defaults setObject:@(bOpen) forKey:kNotifyication];
    [defaults synchronize];
    
    return bOpen;
}*/

//显示Login，并清除当前需要发送的信息
-(void)_showLoginVCAndCancelNetCall:(BOOL)animated{
    [[ACNetCenter shareNetCenter] cancelNowNetCall];
    ACLoginViewController2* pLoginVC = [ACLoginViewController2 new];
    AC_MEM_Alloc(pLoginVC);
    [[ACConfigs getRootViewController] ACpresentViewController:pLoginVC animated:YES completion:nil];
}


//推出登录页面
-(void)presentLoginVC:(BOOL)animated
{
//    self.isLogined = NO;
//    self.isLogouting = NO;
    
    ///AppG
    NSUserDefaults *defaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.lfglkh.shared--Test"];
    [defaults removeObjectForKey:@"userid"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [ACVideoCall cancelVidelCallInMain_queue]; //清除VideoCall,
        //TXB 有可能是异步关闭,导致关闭了我们的ACLoginViewController2
        if([self loginVCShowed]||LoginState_logining==self.loginState){
            //已经显示了登录界面
            return;
        }
        ITLog(@"TXB");
        
        [self updateApplicationUnreadCount];
        [ACConfigs dismissCurrentPresent];
        [self _showLoginVCAndCancelNetCall:animated];
//        UIViewController *vc = [self getRootViewController];
//        ACLoginViewController2 *loginVC = [[ACLoginViewController2 alloc] init];
//        [vc ACpresentViewController:loginVC animated:animated completion:nil];
//        vc = nil;
    });
}

-(void)presentLoginVCWithNetError{
    if([self loginVCShowed]){
        //显示了VC,则简单提示
        [ACUtility postNotificationName:kNetCenterLoginFailRSNotifation object:nil];
        return;
    }
    
    //显示VC
    [self presentLoginVCWithErrTip:nil orErrResponse:nil];
}

-(void)presentLoginVCWithErrTip:(NSString*)pErrorTip orErrResponse:(NSDictionary *)responseDic{
    
    //已经显示
    if(![self loginVCShowed]){
    
        //设置标志
//        self.isLogined = NO;
//        self.isLogouting = NO;
        [ACConfigs clearUserPWDForDisableAutoLogin];
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
        
//            ITLog(@"TXB");
            [ACVideoCall cancelVidelCallInMain_queue]; //清除VideoCall
            [self updateApplicationUnreadCount];
            [ACConfigs dismissCurrentPresent];
            
            [self _showLoginVCAndCancelNetCall:YES];

//            ACLoginViewController2 *loginVC = [[ACLoginViewController2 alloc] init];
//            [[self getRootViewController] ACpresentViewController:loginVC animated:YES completion:nil];
            
            if(pErrorTip){
                AC_ShowTip(pErrorTip);
            }
            else if(responseDic){
                [ACUtility postNotificationName:kNetCenterLoginFailRSNotifation object:responseDic];
                }
        });
        
    }else if(responseDic){
        [ACUtility postNotificationName:kNetCenterLoginFailRSNotifation object:responseDic];
    }
}


-(void)savePersonInfoWithUserDic:(NSDictionary *)dic
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[[dic objectForKey:kUser] objectForKey:kIcon] forKey:kIcon];
    [defaults setObject:[[dic objectForKey:kUser] objectForKey:kName] forKey:kName];
    [defaults setObject:[[dic objectForKey:kUser] objectForKey:kDescription] forKey:kDescription];
    [defaults synchronize];
//    ITLogEX(@"Icon 1=%@",[[dic objectForKey:kUser] objectForKey:kIcon]);
}


+(NSDictionary*)acOem_ConfigInfo{
#if DEBUG
    NSString *Plist=[[NSBundle mainBundle] pathForResource:@"ac_config" ofType:@"plist"];
    //通过文件名(资源)获取路径
    NSDictionary *dt= [[NSDictionary alloc]initWithContentsOfFile:Plist];
    
    return dt;
#else
    return [[NSDictionary alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ac_config" ofType:@"plist"]];
#endif
    
//    return [[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ac_config" ofType:@"plist"]];
}

//+(NSString*)appVer{
//    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
//    return [NSString stringWithFormat:@"%@.%@",[infoDic objectForKey:@"CFBundleShortVersionString"],[infoDic objectForKey:kCFBundleVersion]];
//}

//#define kAppShortVersion_old @"old_ver" //保存的上一个版本的CFBundleShortVersionString



+(NSString*)appVersionWithBuild:(BOOL)bNeedBuildVer{
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString* pVer =    infoDic[@"CFBundleShortVersionString"];
    if(bNeedBuildVer){
        return  [NSString stringWithFormat:@"%@.%@",pVer,[infoDic objectForKey:kCFBundleVersion]];
    }
    
//    #define kCFBundleShortVersionString @"CFBundleShortVersionString"  
    
//    kCFBundleShortVersionString
    
    return pVer;
}

-(void) checkAppVersionChangeForDBChange{
    //检查App版本改变，如果版本改变则检查是否需要数据库重新生成
    //读取旧的版本
    //1.5.141， build号（左边141）取模10等于0的时候，进行客户端数据库升级，之前的版本号前两位变动时升级数据库方案弃用
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* pVer_old =    [defaults objectForKey:kCFBundleVersion_Old];
    NSString* pVer_now =    [[[NSBundle mainBundle] infoDictionary] objectForKey:kCFBundleVersion];
    
    if([pVer_now isEqualToString:pVer_old]){
        return;
    }
    
    [defaults setObject:pVer_now forKey:kCFBundleVersion_Old];
    [defaults synchronize];
    
    int nNewBuildVer =  pVer_now.intValue;
    if(nNewBuildVer<=0||(nNewBuildVer%10)){
        return;
    }
    
    /*
    NSString* pVer_old =    [defaults objectForKey:kAppShortVersion_old];
    NSString* pVer_now =    [[[NSBundle mainBundle] infoDictionary] objectForKey:kCFBundleShortVersionString];
    
    if([pVer_now isEqualToString:pVer_old]){
        return;
    }
    
    [defaults setObject:pVer_now forKey:kAppShortVersion_old];
    [defaults synchronize];
    

    NSArray* pVers_old = [pVer_old componentsSeparatedByString:@"."];
    NSArray* pVers_now = [pVer_now componentsSeparatedByString:@"."];
    if(pVers_old.count==pVers_now.count){
        NSInteger i=0,nCount = pVers_now.count-1;
        for(;i<nCount;i++){
            if(![pVers_old[i] isEqualToString:pVers_now[i]]){
                break;
            }
        }
        if(i==nCount){
            //没有变化，
            return;
        }
    }*/
    ITLogEX(@"版本升级 %@ --> %@",pVer_old,pVer_now);
    [ACConfigs _clearUserDataFunc];
}

+(NSString*) appBuildDate{ //编译时间
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString* pBuldDateString = [infoDic objectForKey:@"BuildDateString"];
    return  [pBuldDateString substringFromIndex:7];
}



-(void)newAppVersionCheckWithBlock:(void (^)(ACConfigs* pConfig,int newAppVersionCheck_Result_Type)) pFunc{
    
    //检查新版本
    time_t timeNow = time(NULL);
    
    BOOL bNeedPostkHaveNewAppVerion = NO;
    if(nil==pFunc){
        if((timeNow-_appNewVersionCheckTime)<4*60*60){
            return;
        }
        bNeedPostkHaveNewAppVerion  = YES;
        pFunc = ^(ACConfigs* pConfig,int newAppVersionCheck_Result_Type) {};
     }
    wself_define();
    
    _appNewVersionCheckTime =   timeNow;
    NSString* pLoginServer =    [[ACNetCenter shareNetCenter] loginServer];
    const char* pcURL = [pLoginServer UTF8String];
    const char* pURLEnd =   strchr(pcURL+10,'/');
    if(NULL==pURLEnd){
        pFunc(wself,newAppVersionCheck_Result_Type_No_Update);
        return;
    }
    
    [ACNetCenter callURL:[NSString stringWithFormat:@"%@/rest/open/terminal/ios/version?v=%@",
                          [pLoginServer substringToIndex:pURLEnd-pcURL],
                          [[[NSBundle mainBundle] infoDictionary] objectForKey:kCFBundleVersion]]
         forMethodDelete:NO
               withBlock:^(ASIHTTPRequest *request, BOOL bIsFail) {
                   int newAppVersionCheck_Result_Type = newAppVersionCheck_Result_Type_Error;
                   if(!bIsFail){
                       newAppVersionCheck_Result_Type = newAppVersionCheck_Result_Type_No_Update;
                       NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
                       ITLog(responseDic);
                       if(ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]&&
                          ((NSString*)[responseDic objectForKey:@"download"]).length>5){
                           newAppVersionCheck_Result_Type = newAppVersionCheck_Result_Type_Need_Update;
                           wself.appNewVersionInfo = responseDic;
                           if(bNeedPostkHaveNewAppVerion){
                               [ACUtility postNotificationName:kHaveNewAppVerion object:nil];
                           }
                       }
                   }
                   pFunc(wself,newAppVersionCheck_Result_Type);
               }];
}

-(void)newAppVersionCheckShowUpdateAlertView{
#if 0
    _appNewVersionInfo = @{
                           @"code" : @(1),
                           @"download" : @"http://www.baidu.com",
                           @"latestVersion" : @"1.0.0.34",
                           @"minVersion" : @(100),
                           @"releaseNotes" : @"1， 修改了啥， \r\n2， 增加了啥",
                           @"cleanCache" : @(2)};
#endif
    
#if TARGET_IPHONE_SIMULATOR
    return;
#endif
//    NSDictionary* pnewAppVersionInfo = [ACConfigs shareConfigs].appNewVersionInfo;
    
    static time_t g_timeForCheckCache = 0;

    time_t timeNow = time(NULL);
    if((timeNow-g_timeForCheckCache)>30*60){ //30分钟检查一次
        g_timeForCheckCache =   timeNow;
        
        //清除 Documents/Inbox 这是外部程序调用 openURL
        [ACUtility dir_clear:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"Inbox"]];

        SDImageCache* pSDImagCache = [SDImageCache sharedImageCache];
        NSMutableArray<NSString*> *pCachesDir = [NSMutableArray arrayWithArray:@[kAudioPath_Name,
                                           kVideoPath_Name,
                                           kFilePath_Name,
                                           kWallboardVideoForeverPath_Name,
                                           kWallboardPhotoForeverPath_Name,
                                           kImageTempPath_Name,
                                           kImageForeverPath_Name,
                                           kStickerForeverPath_Name,
                                           kJsonTempPath_Name,
                                           kJsonForeverPath_Name]];
        
        NSString* pCacheRootDir = kCachesPath;
        
/*        NSMutableArray* pCachesDir = [[NSMutableArray alloc] initWithCapacity:20];
        
        //取得缓存下的全部目录
        {
 //enumeratorAtPath会取全部文件，包括目录下的文件
 
//            NSDirectoryEnumerator *cacheRootEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:pCacheRootDir];
            NSArray* cacheRootEnumerator = [[NSFileManager defaultManager] subpathsAtPath:pCacheRootDir];
            for(NSString* pName in cacheRootEnumerator){
                NSString* pDirName = [pCacheRootDir stringByAppendingPathComponent:pName];
                BOOL bIsDir = NO;
                if([[NSFileManager defaultManager] fileExistsAtPath:pDirName isDirectory:&bIsDir]&&bIsDir){
                    [pCachesDir addObject:pDirName];
                }
            }
        }*/
        
        for(NSInteger n=0;n<pCachesDir.count;n++){
            pCachesDir[n] = [pCacheRootDir stringByAppendingPathComponent:pCachesDir[n]];
        }
        
        
        int nDay = 6;
        for(;nDay>0;nDay--){
            //统计大小
            long lTotalSize = [pSDImagCache getSize];
            for(NSInteger n=0;n<pCachesDir.count;n++){
                long lSize =    [ACUtility dir_size:pCachesDir[n]];
                if(lSize<=0){
                    [pCachesDir removeObjectAtIndex:n];
                    n--;
                    continue;
                }
                lTotalSize +=   lSize;
            }
            
            if(lTotalSize<SDImageCache_MAX_SIZE){
                ITLogEX(@"检查 Cache file(%dM)",(int)(lTotalSize/(1024*1024)));
                break;
            }
            
            [pSDImagCache cleanDiskforDay:nDay];
            for(NSString* pDirName in   pCachesDir){
                [ACUtility dir_clear:pDirName forDay:nDay];
            }
        }
        
        if(nDay<0){
            //清除目录
            ITLog(@"Clear Cache");
            [[SDImageCache sharedImageCache] clearDisk];
            for(NSString* pDirName in   pCachesDir){
                [ACUtility dir_clear:pDirName];
            }
        }
    }
    
    if(_appNewVersionInfo){ //有新版本提示
        
        NSString* pTitle = [NSString stringWithFormat:NSLocalizedString(@"New version available (%@)", nil),[_appNewVersionInfo objectForKey:@"latestVersion"]];
        
        //“minVersion” : 25, //如果用户的编译号码， 小于这个值则需要强制升级，
        NSString* pCancelButton = nil;
        NSInteger alertTag      = AlertView_ID_For_AppVersionCheck_Update_Force;

        
        NSInteger nAppBuildVer = [[[[NSBundle mainBundle] infoDictionary] objectForKey:kCFBundleVersion] integerValue];
        NSInteger nNewBuildVer = [[_appNewVersionInfo objectForKey:@"minVersion"] integerValue];
        if(nAppBuildVer>=nNewBuildVer){
            pCancelButton = NSLocalizedString(@"Cancel", nil);
            alertTag      = AlertView_ID_For_AppVersionCheck_Update;
        }
        
        NSInteger nCleanCahe = [[_appNewVersionInfo objectForKey:@"cleanCache"] integerValue];
        if(1==nCleanCahe||2==nCleanCahe){
            //清除缓存,显示登录界面
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if(2==nCleanCahe){
                [defaults setObject:[defaults objectForKey:kPwd] forKey:kPwd_Auto_login];
                [defaults setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:kCFBundleVersion] forKey:kPwd_Auto_login_Ver];
            }
            else{
                [defaults removeObjectForKey:kPwd];
                [defaults removeObjectForKey:kPwd_Auto_login];
            }
            [defaults synchronize];
            [[ACNetCenter shareNetCenter] logOut:NO withBlock:nil]; //先LogOut
            [self clearUserData];
            [self presentLoginVC:YES];
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:pTitle
                                                        message:[_appNewVersionInfo objectForKey:@"releaseNotes"]
                                                       delegate:self
                                              cancelButtonTitle:pCancelButton
                                              otherButtonTitles:NSLocalizedString(@"Install", nil), nil];
        
        alert.tag = alertTag;
        [alert show];
    }
}



-(UIViewController *)getCurrentRootViewController {
    
    
    UIViewController *result;
    
    
    // Try to find the root view controller programmically
    
    
    // Find the top window (that is not an alert view or other window)
    
    
    UIWindow *topWindow = [[UIApplication sharedApplication] keyWindow];
    
    
    if (topWindow.windowLevel != UIWindowLevelNormal)
        
        
    {
        
        
        NSArray *windows = [[UIApplication sharedApplication] windows];
        
        
        for(topWindow in windows)
            
            
        {
            
            
            if (topWindow.windowLevel == UIWindowLevelNormal)
                
                
                break;
            
            
        }
        
        
    }
    
    
    UIView *rootView = [[topWindow subviews] objectAtIndex:0];
    
    
    id nextResponder = [rootView nextResponder];
    
    
    if ([nextResponder isKindOfClass:[UIViewController class]])
        
        
        result = nextResponder;
    
    
    else if ([topWindow respondsToSelector:@selector(rootViewController)] && topWindow.rootViewController != nil)
        
        
        result = topWindow.rootViewController;
    
    
    else
        
        
        NSAssert(NO, @"ShareKit: Could not find a root view controller.  You can assign one manually by calling [[SHK currentHelper] setRootViewController:YOURROOTVIEWCONTROLLER].");
    
    
    return result;    
    
    
}

-(NSInteger)getHourWithDate:(NSDate *)date
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps  = [calendar components:NSHourCalendarUnit fromDate:date];
    NSInteger hour = [comps hour];
    return hour;
}

-(NSInteger)getMinuteWithDate:(NSDate *)date
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps  = [calendar components:NSMinuteCalendarUnit fromDate:date];
    NSInteger minute = [comps minute];
    return minute;
}

//判断当前date时分是否在两个date之间
-(BOOL)getHourMinuteIsRangeWithCurrentDate:(NSDate *)currentDate betweenDate:(NSDate *)betweenDate andDate:(NSDate *)andDate
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps  = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:currentDate];
    NSInteger hour = [comps hour];
    NSInteger minute = [comps minute];
    
    comps  = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:betweenDate];
    NSInteger minHour = [comps hour];
    NSInteger minMinute = [comps minute];
    
    comps  = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:andDate];
    NSInteger maxHour = [comps hour];
    NSInteger maxMinute = [comps minute];
    
    if (hour >= minHour && minute >= minMinute && (hour < maxHour || (hour == maxHour && minute <= maxMinute)))
    {
        return YES;
    }
    return NO;
}


-(void)clearUserData{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [ACConfigs _clearUserDataFunc];
    });
}

+(void)_clearUserDataFunc{
    
    ITLog(@"清除用户数据");
    
    //删除数据库表
    [[ACDBManager defaultDBManager] dropTableIfExist];
    
    //创建数据库表
    [[ACDBManager defaultDBManager] createTableIfNotExist];
    
    //清空wallboard视频图片
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:kWallboardPhotoForeverPath])
    {
        [fileManager removeItemAtPath:kWallboardPhotoForeverPath error:nil];
    }
    if ([fileManager fileExistsAtPath:kWallboardVideoForeverPath])
    {
        [fileManager removeItemAtPath:kWallboardVideoForeverPath error:nil];
    }
    
    //删除头像icon
    {
        NSArray* pIconFileNames = @[kIcon_200_200,kIcon_100_100,kIcon_1000_1000];
        for(NSString* pIconFileName in pIconFileNames){
            NSString *iconImagePath = [ACAddress getAddressWithFileName:pIconFileName fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
            [fileManager removeItemAtPath:iconImagePath error:nil];
        }
    }

    /*
    NSString *imagePath = [ACAddress getAddressWithFileName:kIcon_200_200 fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
    if ([fileManager fileExistsAtPath:imagePath])
    {
        NSError *error = nil;
        [fileManager removeItemAtPath:imagePath error:&error];
        if (error)
        {
            ITLog(error.localizedDescription);
        }
    }

    imagePath = [ACAddress getAddressWithFileName:kIcon_100_100 fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
    if ([fileManager fileExistsAtPath:imagePath])
    {
        NSError *error = nil;
        [fileManager removeItemAtPath:imagePath error:&error];
        if (error)
        {
            ITLog(error.localizedDescription);
        }
    }*/
    
    //清空内存
    [ACDataCenter shareDataCenter].wallboardTopicEntity = nil;
    [ACDataCenter shareDataCenter].allEntityArray = [NSMutableArray array];
    [ACDataCenter shareDataCenter].topicEntityArray = [NSMutableArray array];
    [ACDataCenter shareDataCenter].urlEntityArray = [NSMutableArray array];
    
    //清除location
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:NO forKey:kLocationAllDayClose];
    [defaults setObject:nil forKey:kLocationStartTime];
    [defaults setObject:nil forKey:kLocationStopTime];
    [defaults setObject:nil forKey:kRepeatDayList];
    [defaults setObject:nil forKey:kUserProfileInfo];
//    [defaults synchronize];
    
    //清除sync-json数据
    /*NSString *syncJsonPath = [ACAddress getAddressWithFileName:kSyncDataJsonName fileType:ACFile_Type_SyncData isTemp:NO subDirName:nil];
    if ([[NSFileManager defaultManager] fileExistsAtPath:syncJsonPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:syncJsonPath error:nil];
    }*/
    
    [defaults setObject:nil forKey:kHistoryList];
//    [defaults synchronize];
    
    //清除下载的sticker信息
    NSArray *suits = [defaults objectForKey:kDownloadSuitList];
    for (NSString *suitID in suits)
    {
        NSString *suitPath = [ACAddress getAddressWithFileName:suitID fileType:ACFile_Type_AddStickerSuitToMyStickersAndDownload isTemp:NO subDirName:suitID];
        if ([fileManager fileExistsAtPath:suitPath])
        {
            [fileManager removeItemAtPath:suitPath error:nil];
        }
    }
    [defaults setObject:[NSArray array] forKey:kDownloadSuitList];
//    [defaults synchronize];
    
    //清除wallboard last categoryID
    [defaults setObject:nil forKey:kWallboardLastCategoryID];
    [defaults synchronize];
}


-(void)updateApplicationUnreadCount
{
    //更新app未读数
    int count = 0;
//    if(_isLogined){
    if(LoginState_logined==_loginState){
        for (ACTopicEntity *entityT in [ACDataCenter shareDataCenter].topicEntityArray){
            count += (entityT.lastestSequence - entityT.currentSequence);
        }
        if(count>99){
            count = 99;
        }
    }
    [UIApplication sharedApplication].applicationIconBadgeNumber = count;
}

-(NSString *)getWeekTitle
{
    NSString *title = @"";
    
    NSMutableArray *array = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:kRepeatDayList]];
    if ([array count] == 0)
    {
        array = [[NSMutableArray alloc] init];
        for (int i = 0; i < 7; i++)
        {
            [array addObject:[NSNumber numberWithBool:YES]];
        }
        [[NSUserDefaults standardUserDefaults] setObject:array forKey:kRepeatDayList];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if ([array count] == 7)
    {
        BOOL mon = [[array objectAtIndex:1] boolValue];
        BOOL tue = [[array objectAtIndex:2] boolValue];
        BOOL wed = [[array objectAtIndex:3] boolValue];
        BOOL thu = [[array objectAtIndex:4] boolValue];
        BOOL fri = [[array objectAtIndex:5] boolValue];
        BOOL sat = [[array objectAtIndex:6] boolValue];
        BOOL sun = [[array objectAtIndex:0] boolValue];
        if (sun && mon && tue && wed && thu && fri && sat)
        {
            title = NSLocalizedString(@"Every day", nil);
        }
        else if (mon && tue && wed && thu && fri && !sat && !sun)
        {
            title = NSLocalizedString(@"Weekdays", nil);
        }
        else
        {
            NSMutableArray *dayArray = [[NSMutableArray alloc] init];
            if (mon)
            {
                [dayArray addObject:@"Mon"];
            }
            if (tue)
            {
                [dayArray addObject:@"Tue"];
            }
            if (wed)
            {
                [dayArray addObject:@"Wed"];
            }
            if (thu)
            {
                [dayArray addObject:@"Thu"];
            }
            if (fri)
            {
                [dayArray addObject:@"Fri"];
            }
            if (sat)
            {
                [dayArray addObject:@"Sat"];
            }
            if (sun)
            {
                [dayArray addObject:@"Sun"];
            }
            for (int i = 0; i < [dayArray count]; i++)
            {
                NSString *string = [dayArray objectAtIndex:i];
                if (i == 0)
                {
                    title = [title stringByAppendingString:string];
                }
                else
                {
                    title = [title stringByAppendingString:[NSString stringWithFormat:@" %@",string]];
                }
            }
        }
    }
    return title;
}

+(void)showLocalNotification:(NSString*)pTitle withUserInfo:(NSDictionary*)userInfo needSound:(BOOL)bNeedSound{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    if(nil==notification) return;
    
    // 设置通知的提醒时间
//        NSDate *currentDate   = [NSDate date];
//        notification.timeZone = [NSTimeZone defaultTimeZone]; // 使用本地时区
//        notification.fireDate = [currentDate dateByAddingTimeInterval:5.0];

    // 设置重复间隔
//        notification.repeatInterval = kCFCalendarUnitDay;

    // 设置提醒的文字内容
    notification.alertBody   = pTitle;
    
    // 通知提示音 使用默认的
    if(bNeedSound){
        notification.soundName= UILocalNotificationDefaultSoundName;
    }
    
    // 设置应用程序右上角的提醒个数
//        notification.applicationIconBadgeNumber++;

    // 设定通知的userInfo，用来标识该通知
//    NSMutableDictionary *aUserInfo = [[NSMutableDictionary alloc] init];
//    aUserInfo[kLocalNotificationID] = @"LocalNotificationID";
    notification.userInfo = userInfo;
    
    // 将通知添加到系统中
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

#pragma mark UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    NSDictionary* pnewAppVersionInfo = _appNewVersionInfo;
    _appNewVersionInfo = nil;
    
    if(AlertView_ID_For_AppVersionCheck_Update_Force==alertView.tag||1==buttonIndex){
        //AlertView_ID_For_AppVersionCheck_Update_Force==alertView.tag表示强制安装
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[pnewAppVersionInfo objectForKey:@"download"]]];
    }
}


@end
