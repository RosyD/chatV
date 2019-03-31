//
//  ACAppDelegate.m
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-27.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACAppDelegate.h"
#import "ACChatViewController.h"
//#import "IIViewDeckController.h"
#import "MMDrawerController.h"
#import "ACNetCenter.h"
#import "ACRootViewController.h"
#import "ACDBManager.h"
#import "ACDataCenter.h"
#import "ACLBSCenter.h"
#import "JSONKit.h"
#import "IPAddress.h"
#import "Reachability.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "ACUtility.h"
#import "ACVideoCall.h"
#import "ACEntityEvent.h"
#import "UncaughtExceptionHandler.h"
#import "JHNotificationManager.h"
#import "ACNoteDetailVC.h"
#import "ACMessageEvent.h"
#import "ACTransmitViewController.h"
#import "RTCPeerConnectionFactory.h"


@implementation ACAppDelegate

- (void)radioAccessChanged {
//    Test
    ITLogEX(@"Now you're connected via %@", _networkInfo.currentRadioAccessTechnology);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    InstallUncaughtExceptionHandler();
    [RTCPeerConnectionFactory initializeSSL];
    
    ITLogEX(@"\n\nAPP(%@)启动:%@,LONG_MAX=%ld,MAXFLOAT=%f SysVer=%f name=%@",[ACConfigs appVersionWithBuild:YES],launchOptions,LONG_MAX,MAXFLOAT,NSFoundationVersionNumber,[[UIDevice currentDevice] name]);
    
//    NSLog(@"%@",[NSDate date].description);
    /*
    NSString* userPhoneName = [[UIDevice currentDevice] name];
    NSLog(@"手机别名: %@", userPhoneName);
    //设备名称
    NSString* deviceName = [[UIDevice currentDevice] systemName];
    NSLog(@"设备名称: %@",deviceName );*/
    
    _networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(radioAccessChanged) name:
     CTRadioAccessTechnologyDidChangeNotification object:nil];
    
    CGRect screenBounds =   [[UIScreen mainScreen] bounds];
    self.window = [[UIWindow alloc] initWithFrame:screenBounds];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    ACChatViewController *chatVC = [[ACChatViewController alloc] init];
    [chatVC setChatListType:ACCenterViewControllerType_All];
    [chatVC setChatListTitle:kAll];
    UINavigationController *navC1 = [[UINavigationController alloc] initWithRootViewController:chatVC];
    [navC1 setNavigationBarHidden:YES];
    
    ACRootViewController *rootVC = [[ACRootViewController alloc] init];
    UINavigationController *navC2 = [[UINavigationController alloc] initWithRootViewController:rootVC];
    [navC2 setNavigationBarHidden:YES];
    
    
    
    MMDrawerController * rootViewController = [[MMDrawerController alloc]
                                             initWithCenterViewController:navC1
                                             leftDrawerViewController:navC2
                                             rightDrawerViewController:nil];
    rootViewController.showsShadow = YES;
    rootViewController.closeDrawerGestureModeMask = MMCloseDrawerGestureModeTapCenterView;
//    rootViewController.maximumLeftDrawerWidth = screenBounds.size.width/2;
    rootViewController.maximumLeftDrawerWidth = 180;
    
//    IIViewDeckController *rootViewController = [[IIViewDeckController alloc] initWithCenterViewController:navC1 leftViewController:navC2];
//    rootViewController.leftSize = 140;
//    [[ACLBSCenter shareLBSCenter] startUpdatingLocation];
    [ACLBSCenter initACLBSCenter];
    
    [self.window setRootViewController:rootViewController];
    
    //初始化
#if TARGET_IPHONE_SIMULATOR //模拟器
    [ACConfigs shareConfigs].deviceToken = @"empty_deviceToken";
//    [ACConfigs shareConfigs].deviceToken = @"";
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        //延时3秒设置deviceToken
//        [ACConfigs shareConfigs].deviceToken = @"empty_deviceToken";
//    });
#endif

    [self _registerForRemoteNotification];
    
    [ACNetCenter shareNetCenter].isForeground = YES;

    //检查数据库是否需要升级
    [[ACConfigs shareConfigs] checkAppVersionChangeForDBChange];
    
    //创建数据库表
    [[ACDBManager defaultDBManager] createTableIfNotExist];
    
    //载入数据库中的数据（如果有的话）
    [[ACDataCenter shareDataCenter] loadEntityListFromDB];
    
    
    
    //这里处理应用程序如果没有启动,但是是通过通知消息打开的,此时可以获取到消息.
//    if (launchOptions != nil)
//    {
//        NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
//        ITLog(([NSString stringWithFormat:@"远程通知(Launch):%@",userInfo]));
////        [[UIApplication sharedApplication ] setApplicationIconBadgeNumber:0];
////        AC_ShowTipFunc(nil,[NSString stringWithFormat:@"远程通知(Launch):%@",userInfo]);
//
//    }
//    ITLog(([NSString stringWithFormat:@"%f",chatVC.view.bounds.size.height]));
    
    [self.window makeKeyAndVisible];
    NSLog(@"self.window.frame%@",NSStringFromCGRect(self.window.frame));
    
    NSString *imageName = [ACConfigs isPhone5]?@"Default-568h.png":@"Default.png";
    UIImageView *splashScreen = [[UIImageView alloc] initWithFrame:self.window.bounds];
    splashScreen.image = [UIImage imageNamed:imageName];
    [self.window addSubview:splashScreen];
    
    [UIView animateWithDuration:.1 animations:^{
        CATransform3D transform = CATransform3DMakeScale(1.5, 1.5, 1.0);
        splashScreen.layer.transform = transform;
        splashScreen.alpha = 0.0;
    } completion:^(BOOL finished) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
        [splashScreen removeFromSuperview];
        
        //登录,不在这里登录，取得
        [[ACNetCenter shareNetCenter] autoLoginForAppLaunch];
        
//        [ACUtility showTip:@"这里处理应用程序如果没有启动"];
        
//不再使用        if(launchOptions){
//            //这里处理应用程序如果没有启动,但是是通过通知消息打开的,此时可以获取到消息.
//            //会调用 didReceiveRemoteNotification
//            
//            //延迟调用
//            ITLog(@"调用 launchOptions");
//            [self performSelector:@selector()
//                       withObject:[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]
//                       afterDelay:1];
//        }
    }];
    
//    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    _locationManager.distanceFilter = 10;
    _locationManager.delegate = self;
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    //清除
//    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
//    ITLogEX(@"%@ %@",[ACUtility nowLocalDate],[]);
    return YES;
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{

    ITLogEX(@"%@  %@",sourceApplication,url);
    //com.apple.mobilemail  file:///private/var/mobile/Containers/Data/Application/1BC1E0D8-B8CF-4F14-9CBF-C66C532721D0/Documents/Inbox/%E6%B7%B1%E5%85%A5%E6%B5%85%E5%87%BACocoa%E6%95%99%E7%A8%8B.pdf
    
    if(LoginState_logined != [ACConfigs shareConfigs].loginState){
        ITLog(@"还没有登录");
        return YES;
    }
    
    if(url.isFileURL){
        NSString* pFilePath = url.path;
        
        long nFileSize = [ACUtility getFileSizeWithPath:pFilePath];
        if(nFileSize<=0||nFileSize>ACChat_SendFile_MaxSize){
            return YES;
        }
    
        [ACDataCenter shareDataCenter].shareFilePaths = @[pFilePath];
        [ACVideoCall cancelVidelCallInMain_queue];
        [ACConfigs dismissCurrentPresent];
        ACChatViewController* chatVC = [ACConfigs toAllChatViewController];
        if(chatVC){
            [chatVC checkNotification];
        }
    }
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    ITLog(@"------ APP进入后台 -------");
//    [ACVideoCall cancelVidelCallInMain_queue];
    [ACNetCenter shareNetCenter].bShowDisconnectStatInfo = NO;
    [ACNetCenter shareNetCenter].isForeground = NO;
    [ACNetCenter shareNetCenter].backgrounLoopInquireClose = NO;

    UIApplication* app = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    // Start the long-running task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        // Do the work associated with the task.
//        int i = 0;
//        while (1)
//        {
//            ITLog(([NSString stringWithFormat:@"%d",i++]));
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [_locationManager startUpdatingLocation];
//            });
//            sleep(5);
//        }
        [[ACNetCenter shareNetCenter] deleteLoopInquireForLoginUI:NO];
        [app endBackgroundTask:bgTask];    
        bgTask = UIBackgroundTaskInvalid;    
    });
}

#pragma mark -app实现的Notification

+(BOOL)canShowNotification{
    
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        return NO;
    }
    
    if([ACVideoCall inVideoCall]){
        return NO;
    }
    
    
    return YES;
}

+(void)activeNotification:(NSDictionary*)pCallUserInfo{
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state == UIApplicationStateBackground) {
        return;
    }
    ACDataCenter* pDataCenter = [ACDataCenter shareDataCenter];
    
    NSString* pNoteID = pCallUserInfo[JHNotification_UserInfo_noteID];
    pDataCenter.entityForNotification   =   [[ACDataCenter shareDataCenter] findEntify:pCallUserInfo[JHNotification_UserInfo_topicID]];
    
    if(nil==pDataCenter.entityForNotification){
        //        if(pNoteID){
        //            AC_ShowTip(NSLocalized String(@"This note has been removed!",nil));
        //        }
        //        else{
        //            AC_ShowTip(NSLocalized String(@"Topic has been removed!",nil));
        //        }
        return;
    }
    
    if(pNoteID){
        UIViewController* topView = [ACConfigs getTopViewController];
        if([topView isKindOfClass:[ACNoteDetailVC class]]){
            ACNoteDetailVC* noteDetailVC = (ACNoteDetailVC*)topView;
            if([pNoteID isEqualToString:noteDetailVC.noteMessage.id]){
                pDataCenter.entityForNotification = nil;
                [noteDetailVC refreshFocus];
                return;
            }
        }
    }
    pDataCenter.noteIdForNotification   =   pNoteID;
    
    [ACVideoCall cancelVidelCallInMain_queue];
    [ACConfigs dismissCurrentPresent];
    ACChatViewController* chatVC = [ACConfigs toAllChatViewController];
    if(chatVC){
        [chatVC checkNotification];
    }
}



#pragma mark -RemoteNotification
+(void)registerForRemoteNotification{
    [(ACAppDelegate*)[UIApplication sharedApplication].delegate _registerForRemoteNotification];
}

-(void)_registerForRemoteNotification{
    //#if DEBUG
    //    static  int nDebugCount = 4;
    //    nDebugCount --;
    //    if(nDebugCount>=0){
    //        return;
    //    }
    //#endif
    //    if([ACConfigs isIOS8]){
    
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
    if ([UNUserNotificationCenter class]) {
        //iOS10特有
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        // 必须写代理，不然无法监听通知的接收与点击
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted) {
                [[UIApplication sharedApplication] registerForRemoteNotifications];
                [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
                    ITLogEX(@"IOS10 注册成功:%@", settings);
                }];
            } else {
                ITLogEX(@"IOS10 注册失败:%@",error.localizedDescription);
            }
        }];
    }else
#endif
    if ([UIUserNotificationSettings class])
    {
        //原因是因为在ios8中，设置应用的application badge value需要得到用户的许可。使用如下方法咨询用户是否许可应用设置application badge value
        
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else{
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
}



-(void)application:(UIApplication *)application performFetchWithCompletionHandler: (void (^)(UIBackgroundFetchResult result))completionHandler
{
    //    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://www.baidu.com"]];
    //    NSLog(@"%@",data);
    completionHandler(UIBackgroundFetchResultNewData);
}

//远程通知注册成功委托
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *tokenStr = [deviceToken description];
    ITLogEX(@"deviceToken:%@",tokenStr);
    if(tokenStr.length){
        [ACConfigs shareConfigs].deviceToken = tokenStr;
    }
}

//远程通知注册失败委托
-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
#if !TARGET_IPHONE_SIMULATOR
    ITLog(([NSString stringWithFormat:@"%@",[error description]]));
#ifdef ACUtility_Need_Log
    [ACUtility ShowTip:error.localizedDescription withTitle:@"DeviceToken"];
#endif
#endif
}

-(BOOL)_callRemoteNotification:(NSDictionary *)userInfo appIsInActive:(BOOL)appIsInActive{
    
    //返回是否处理了
//先放着，等登录后处理    if(LoginState_logined != [ACConfigs shareConfigs].loginState){
//        ITLog(@"还没有登录");
//        return YES;
//    }
    
    int nEventTyep = [[userInfo objectForKey:@"eventType"] intValue];
    if(0==nEventTyep){
        ITLog(@"App 已经激活了,不是用户点击的");
        return NO;
    }
    
    BOOL bIsLogined =   LoginState_logined == [ACConfigs shareConfigs].loginState;
    
    if(appIsInActive){
        //只有程序在后台被激活，才调用，否则不处理
        NSString* pTopicID =    userInfo[@"topicId"];
        if(EntityEventType_Note_Comment==nEventTyep||
           EntityEventType_Note_New==nEventTyep){
            NSString* noteID = userInfo[@"noteId"];
            if(pTopicID.length&&noteID.length&&bIsLogined){
                [ACAppDelegate activeNotification:@{JHNotification_UserInfo_topicID:pTopicID,JHNotification_UserInfo_noteID:noteID}];
            }
            return YES;
        }
        
        if(EntityEventType_AddTopic==nEventTyep){
            if(pTopicID.length&&bIsLogined){
                [ACAppDelegate activeNotification:@{JHNotification_UserInfo_topicID:pTopicID}];
            }
            return YES;
        }
        
        if(![[ACVideoCall shareVideoCall] onAppNotificationUserInfo:userInfo]){
            return YES;
        }
        
        return NO;
    }
    
    return YES;
}


//点击某条远程通知时调用的委托 如果界面处于打开状态,那么此委托会直接响应
-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    ITLog(@"iOS6及以下系统");
    //    [self _callRemoteNotification:userInfo appIsInActive:YES];
    //    [[ACVideoCall shareVideoCall] onAppNotificationUserInfo:userInfo];
    
    //    ITLog(([NSString stringWithFormat:@"远程通知:%@",userInfo]));
    
    //    AC_ShowTipFunc(nil,[NSString stringWithFormat:@"远程通知:%@",userInfo]);
    //    [[UIApplication sharedApplication ] setApplicationIconBadgeNumber:0];
}


-(void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void(^)(UIBackgroundFetchResult)) completionHandler
{
    //如果实现了这个 didReceiveRemoteNotification:fetchCompletionHandler 函数,则不会调用didReceiveRemoteNotification
    // 下面的代码好像不行
    //    if (application.applicationState != UIApplicationStateActive&&
    //        EntityEventType_Video_Call==[[userInfo objectForKey:@"eventType"] intValue]){
    //        return;
    //    }
    
    ITLogEX(@"[app State=%ld]%@",application.applicationState,userInfo);
    
    if([self _callRemoteNotification:userInfo appIsInActive:application.applicationState != UIApplicationStateActive]){
        completionHandler(UIBackgroundFetchResultNewData);
        return;
    }
    
    [ACLBSCenter remoteAlertWithDic:userInfo fetchCompletionHandler:completionHandler];
    
    /*
     NSLog(@"Remote Notification userInfo is %@", userInfo);
     
     #if 0
     dispatch_async(dispatch_get_global_queue(0, 0), ^{
     for(int i=0;i<100;i++){
     NSLog(@"%d",i);
     sleep(1);
     }
     });
     #else
     for(int i=0;i<25;i++){
     NSLog(@"%d",i);
     sleep(1);
     }
     #endif
     
     // Do something with the content ID
     completionHandler(UIBackgroundFetchResultNewData);*/
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
}


#ifdef NSFoundationVersionNumber_iOS_9_x_Max

#pragma mark -UNUserNotificationCenterDelegate

// iOS 10收到通知
#if 0
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{
    //程序在前台时，才调用
    NSDictionary * userInfo = notification.request.content.userInfo;
    UNNotificationRequest *request = notification.request; // 收到推送的请求
    UNNotificationContent *content = request.content; // 收到推送的消息内容
    NSNumber *badge = content.badge;  // 推送消息的角标
    NSString *body = content.body;    // 推送消息体
    UNNotificationSound *sound = content.sound;  // 推送消息的声音
    NSString *subtitle = content.subtitle;  // 推送消息的副标题
    NSString *title = content.title;  // 推送消息的标题
    
    if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        NSLog(@"iOS10 前台收到远程通知:%@", [self logDic:userInfo]);
        
    }
    else {
        // 判断为本地通知
        NSLog(@"iOS10 前台收到本地通知:{\\\\nbody:%@，\\\\ntitle:%@,\\\\nsubtitle:%@,\\\\nbadge：%@，\\\\nsound：%@，\\\\nuserInfo：%@\\\\n}",body,title,subtitle,badge,sound,userInfo);
    }
    completionHandler(UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionSound|UNNotificationPresentationOptionAlert); // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以设置
}
#endif

// 通知的点击事件
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler{
    
//    NSDictionary * userInfo = response.notification.request.content.userInfo;
//    UNNotificationRequest *request = response.notification.request; // 收到推送的请求
//    UNNotificationContent *content = request.content; // 收到推送的消息内容
//    NSNumber *badge = content.badge;  // 推送消息的角标
//    NSString *body = content.body;    // 推送消息体
//    UNNotificationSound *sound = content.sound;  // 推送消息的声音
//    NSString *subtitle = content.subtitle;  // 推送消息的副标题
//    NSString *title = content.title;  // 推送消息的标题
//    
    if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        //0==UIApplicationStateActive
        ITLogEX(@"iOS10 收到远程通知,AppState=%d",(int)[UIApplication sharedApplication].applicationState);

        [self _callRemoteNotification:response.notification.request.content.userInfo
                        appIsInActive:[UIApplication sharedApplication].applicationState != UIApplicationStateActive];
    }
    else {
        // 判断为本地通知
//        NSLog(@"iOS10 收到本地通知:{\\\\nbody:%@，\\\\ntitle:%@,\\\\nsubtitle:%@,\\\\nbadge：%@，\\\\nsound：%@，\\\\nuserInfo：%@\\\\n}",body,title,subtitle,badge,sound,userInfo);
    }
    
    // Warning: UNUserNotificationCenter delegate received call to -userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler: but the completion handler was never called.
    completionHandler();  // 系统要求执行这个方法
}

#endif

#pragma mark -定位Delegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
//    NSLog(@"%@",locations);
    [_locationManager stopUpdatingLocation];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    ITLogEX(@"------ 唤醒APP(%@) -------",application.applicationState == UIApplicationStateBackground?@"后台":@"前台");
//    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [ACNetCenter shareNetCenter].bShowDisconnectStatInfo = NO;
    [ACNetCenter shareNetCenter].isForeground = YES;
//    [ACNetCenter shareNetCenter].lastLoopInquireTI = [[NSDate date] timeIntervalSince1970];
//    if ([ACNetCenter shareNetCenter].backgrounLoopInquireClose) //不再判断了,函数内部有判断
    {
        
        [[ACNetCenter shareNetCenter] loopInquire];
    }
    [[ACConfigs shareConfigs] newAppVersionCheckWithBlock:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [RTCPeerConnectionFactory deinitializeSSL];
}

- (NSUInteger)supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
#if 0
    return UIInterfaceOrientationMaskPortrait;
#else
    return UIInterfaceOrientationMaskAll;
#endif
}


@end

/*
 2016-07-05 15:30:54.585 chat[6810:3229398] <ACAppDelegate: 0x12ff0d1d0>(application:didFinishLaunchingWithOptions:): APP(1.7.204)启动:{
 UIApplicationLaunchOptionsRemoteNotificationKey =     {
 aps =         {
 alert = "john: hiicon";
 badge = 8;
 sound = default;
 };
 eventType = 11;
 topicId = 577b2202e4b00ba838b0de14;
 };
 },LONG_MAX=9223372036854775807
 2016-07-05 15:30:54.619 chat[6810:3229398] <ACDBManager: 0x12ff6a5d0>(init): DB /var/mobile/Containers/Data/Application/3EFF3D96-0AB0-480B-A211-67C17A3ABC88/Library/AcuCom.db
 2016-07-05 15:30:54.625 chat[6810:3229398] ACReadCountDB(createTable:): readCount表已经创建
 2016-07-05 15:30:54.641 chat[6810:3229398] <ACAppDelegate: 0x12ff0d1d0>(application:didReceiveRemoteNotification:fetchCompletionHandler:): [app State=1]{
 aps =     {
 alert = "john: hiicon";
 badge = 8;
 sound = default;
 };
 eventType = 11;
 topicId = 577b2202e4b00ba838b0de14;
 }
 2016-07-05 15:30:54.641 chat[6810:3229398] <ACAppDelegate: 0x12ff0d1d0>(application:didReceiveRemoteNotification:fetchCompletionHandler:): 还没有登录
 2016-07-05 15:30:54.689 chat[6810:3229398] <ACConfigs: 0x12ff6ec70>(newAppVersionCheckShowUpdateAlertView): 检查 Cache file(0M)
 2016-07-05 15:30:54.692 chat[6810:3229398] <ACChatViewController: 0x12fe3ef40>(viewWillAppear:): SDImageCache file(6,0M) mem(0,0M)
 2016-07-05 15:30:54.693 chat[6810:3229398] <ACChatViewController: 0x12fe3ef40>(reloadLoginState:): loginState Show for Loading...
 2016-07-05 15:30:54.875 chat[6810:3229398] <ACLBSCenter: 0x12ff672b0>(locationManager:didChangeAuthorizationStatus:): didChangeAuthorizationStatus
 2016-07-05 15:30:54.876 chat[6810:3229398] <ACAppDelegate: 0x12ff0d1d0>(application:didRegisterForRemoteNotificationsWithDeviceToken:): <7c92755a 9753b636 d50d787f 2e59597e 025fb4f0 32bd82a5 33775d0b b5ce7064>
 2016-07-05 15:30:54.967 chat[6810:3229398] <ACNetCenter: 0x12fd8a320>(autoLoginDelay:): 直接登录
 2016-07-05 15:30:54.967 chat[6810:3229398] <ACNetCenter: 0x12fd8a320>(autoLoginDelay:): 不登录，直接访问 https://acucom2.aculearn.com
 2016-07-05 15:30:54.970 chat[6810:3229446] <ACNetCenter: 0x12fd8a320>(GCDLoopInquire): TCP轮询: 连接Host tcpacucom2.aculearn.com:443
 2016-07-05 15:30:54.970 chat[6810:3229398] <ACVideoCall: 0x12ff2a950>(onAppNotificationUserInfo:): eventType(11)!=91
 2016-07-05 15:30:54.980 chat[6810:3229398] <ACChatViewController: 0x12fe3ef40>(reloadLoginState:): loginState Show for Loading...
 2016-07-05 15:30:55.315 chat[6810:3229455] <ACNetCenter: 0x12fd8a320>(socket:didConnectToHost:port:): TCP轮询:连接成功
 2016-07-05 15:30:55.316 chat[6810:3229455] <ACNetCenter: 0x12fd8a320>(_loopInquireTcp_SendDict:): TCP Send:{
 d = aculearn;
 k = "<7c92755a 9753b636 d50d787f 2e59597e 025fb4f0 32bd82a5 33775d0b b5ce7064>";
 s = 57750f7fe4b00ba838b0ce1c;
 t = ios;
 u = 55d69622e4b0bbf08ba351b2;
 v = 204;
 }
 2016-07-05 15:30:55.622 chat[6810:3229404] <ACNetCenter: 0x12fd8a320>(_GCDLoopInquireTcp_CheckRecvData:): TCP轮询:{
 code = 1;
 events =     (
 {
 commandType = sync;
 eventTime = 1467703855479;
 eventType = 61;
 eventUid = 55d69622e4b0bbf08ba351b2;
 }
 );
 }
 2016-07-05 15:30:55.624 chat[6810:3229398] <ACChatViewController: 0x12fe3ef40>(reloadLoginState:): loginState Show for Loading...
 2016-07-05 15:30:55.647 chat[6810:3229404] <ACNetCenter: 0x12fd8a320>(_loopInquireTcp_SendDict:): TCP Send:{
 entities =     (
 {
 cseq = 7745;
 eid = 55d5998fe4b0ad3fb44df86b;
 seq = 7749;
 type = 20;
 utime = 1467703790131;
 },
 {
 cseq = 28;
 eid = 577b2202e4b00ba838b0de14;
 seq = 31;
 type = 20;
 utime = 1467687459964;
 },
 {
 cseq = 4228;
 eid = 42a67375b13c1e75ae32c2399d5b6607;

 
 */

