//
//  ACConfigs.h
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-27.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TypeDef.h"
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>


#define ACChat_SendFile_MaxSize 50*1024*1024 //转发文件最大大小

#define kGoogleSearchKey @"AIzaSyB_lvk5o98V5eWZTgD0MfkfvbdwQwrq02k"
//@"AIzaSyC0h2H1mHu4UKpujG20GuZ_ow3XyAeQ3H8" old

//#define kVibarteOn  @"kVibarteOn"
//#define kSoundOn    @"kSoundOn"
//#define kBannerOn    @"kBannerOn"
//#define kCommentBannerOn    @"kCommentBannerOn"


#define NotificationCfg_ON                  0x8000
#define NotificationCfg_VibarteOn           0x0001
#define NotificationCfg_SoundOn             0x0002
#define NotificationCfg_BannerOn            0x0004
#define NotificationCfg_CommentBannerOn     0x0008


#define kFontSize   @"kFontSize"

#define hotsoptHeight   20

#define kLineColor  [UIColor colorWithWhite:0.9 alpha:1]

#define kRepeatDayList  @"kRepeatDayList"

#define kId             @"id"
#define kName           @"name"
#define kDesc           @"desc"
#define kCategoryId     @"categoryId"
#define kFirmId         @"firmId"
#define kExpiredDate    @"expiredDate"
#define kCreateTime     @"createTime"
#define kUpdateTime     @"updateTime"
#define kStickers       @"stickers"
#define kBackground     @"background"
#define kThumbnail      @"thumbnail"
#define kUploader       @"uploader"

#define kRid            @"rid"
#define kTrid           @"trid"
#define kTitle          @"title"
#define kStickerImgResourceId   @"stickerImgResourceId"

#define kSuits          @"suits"

#define kSingleSticker  @"singleSticker"

#define kHistoryList    @"kHistoryList"

#define kWallboardLastCategoryID    @"kWallboardLastCategoryID"

//#define kRootViewControllerShowing @"rootViewControllerShowing"
//处理RootController显示的通知,测试关闭一下,不知道功能是什么,经过测试,初步认为是为了处理左侧功能开关

extern NSString *const kHotspotOpenStateChangeNotification;
extern NSString* const kNoteOrCommentUpdateTimeChanged;
extern NSString* const kHaveNewAppVerion; //有新版本
extern NSString* const kNotificationLocationChanged;  //位置改变

enum LoginState //登录状态
{
    LoginState_waiting,         //没有登录，等待中
    LoginState_logining,        //登录中
    LoginState_logined,         //登录AcuCom服务器成功
//    LoginState_loginOuting,     //正在登出
};

@class ACChatViewController;
@class ACUser;
@interface ACConfigs : NSObject<AVAudioPlayerDelegate,UIAlertViewDelegate>

+(ACConfigs *)shareConfigs;

@property (nonatomic) CLLocationCoordinate2D    location;
@property (nonatomic) CLLocationCoordinate2D    location_old; //上次的位置
@property (nonatomic,strong) AVAudioPlayer      *player;
//@property (nonatomic,strong) NSString           *mySelfUserID;
@property (nonatomic) enum LoginState           loginState; //登录状态
//@property (nonatomic) BOOL                      isLogining;//是否在登录界面，用于判断登录失败时是否present出login界面来
//@property (nonatomic) BOOL                      isLogined;//已经登录
//@property (nonatomic) BOOL                      isLogouting;//正在登出
//@property (nonatomic) BOOL                      isSynced;//已经同步
//@property (nonatomic) BOOL                      isLogoutedNeedLogin;//登出结束需要登录
@property (nonatomic,strong) NSString           *deviceToken;//用于发pushNotification
@property (nonatomic) NSString                  *webUrlEntityType;
@property (nonatomic,strong) NSMutableArray     *currentPresentVCList;
@property (nonatomic) BOOL                      isInWebPage;
@property (nonatomic) BOOL                      canSearchInCR; //是否可以在CR中搜索
@property (nonatomic) NSUInteger                currentSuitIndex;
@property (nonatomic) long long                 latestNoteTime;     //最新的Note或Comment的updateTime
@property (nonatomic) long long                 currentNoteTime;    //存储用户自己已读的Note的updateTime
@property (nonatomic,strong) NSDictionary       *appNewVersionInfo;
@property (nonatomic) time_t                    appNewVersionCheckTime;
@property (nonatomic) int                       notificationCfg;   //通知配置 NotificationCfg_*

@property (nonatomic,setter=setchatTextFontSizeNo:)        NSInteger          chatTextFontSizeNo; //字体编号
@property (nonatomic,strong,readonly) UIFont*   chatTextFont; //字体

#ifdef kRootViewControllerShowing
    @property (nonatomic) BOOL                  rootViewControllerShowing;
#endif

+(BOOL)isPhone5;
//+(BOOL)isIOS8;
+(NSDictionary*)acOem_ConfigInfo; //加载ac_config.plist
+(NSString*) appVersionWithBuild:(BOOL)bNeedBuildVer;
//+(NSString*)appVer;
-(void) checkAppVersionChangeForDBChange;
+(NSString*) appBuildDate; //编译时间
+(void) clearUserPWDForDisableAutoLogin; //为了自动登录清除密码
+(UIViewController*)getTopViewController;
+(void)showLocalNotification:(NSString*)pTitle withUserInfo:(NSDictionary*)userInfo needSound:(BOOL)bNeedSound;

+(BOOL)notificationCfgIsOn:(int)nCfgType;
+(void)notificationCfgSave:(int)nCfgType forSave:(BOOL)forSave;
//+(BOOL)remoteNotification:(int)nFuncType; //远程notification功能,0:get sync:(1:true -1:false) change(2:true -2:false) 

-(void)updateApplicationUnreadCount;

#define newAppVersionCheck_Result_Type_Error        -1  //更新失败
#define newAppVersionCheck_Result_Type_No_Update    0   //不需要更新
#define newAppVersionCheck_Result_Type_Need_Update  1   //需要跟新

-(void)newAppVersionCheckWithBlock:(void (^)(ACConfigs* pConfig,int newAppVersionCheck_Result_Type)) pFunc;
-(void)newAppVersionCheckShowUpdateAlertView; //显示更新对话框

//修改时间,<0表示无效
-(void)chageNoteLastTimeForRefreshNoteOrComment:(long long)lastTime;
-(void)chageNoteLastTimeForTimeLine:(long long)lastTime;
-(BOOL)chageNoteLastTime:(long long)lastTime andCurTime:(long long)curTime;
-(void)chageNoteLastTimeForNewUpdateTime:(long long)updateTime; //当发送新的Note和Comment时更新

-(void)newMessageSoundPlay;

//得到当前ViewController
+(UIViewController *)getRootViewController;
+(void)dismissCurrentPresent;
+(ACChatViewController*)toAllChatViewController;


//推出登录页面
-(BOOL)loginVCShowed; //是否显示了
-(void)presentLoginVC:(BOOL)animated;
-(void)presentLoginVCWithErrTip:(NSString*)pErrorTip orErrResponse:(NSDictionary *)responseDic;
-(void)presentLoginVCWithNetError;

//登出的时候用
-(void)clearUserData;

-(void)savePersonInfoWithUserDic:(NSDictionary *)dic;


//根据date获得hour
-(NSInteger)getHourWithDate:(NSDate *)date;

-(NSInteger)getMinuteWithDate:(NSDate *)date;

//判断当前date时分是否在两个date之间
-(BOOL)getHourMinuteIsRangeWithCurrentDate:(NSDate *)currentDate betweenDate:(NSDate *)betweenDate andDate:(NSDate *)andDate;


//location setting中周几获得
-(NSString *)getWeekTitle;



@end
