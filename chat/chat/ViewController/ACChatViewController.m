//
//  ACChatViewController.m
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-27.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACChatViewController.h"
#import "ACDataCenter.h"
#import "ACEntityCell.h"
#import "ACNetCenter.h"
#import "ACChooseContactViewController.h"
#import "ACChatMessageViewController.h"
#import "ACMapViewController.h"
#import "ASIHTTPRequest.h"
#import "JSONKit.h"
#import "ACMessageEvent.h"
//#import "ACLoginViewController.h"
//#import "IIViewDeckController.h"
#import "MMDrawerController.h"
#import "UIViewController+MMDrawerController.h"
#import "ACRootTableViewCell.h"
#import "ACAcuLearnWebViewController.h"
#import "ACTopicEntityDB.h"
#import "ACUrlEntityDB.h"
#import "UIView+Additions.h"
#import "ACConfigs.h"
#import "ACLBSCenter.h"
#import "ACWallBoardViewController.h"
#import "UINavigationController+Additions.h"
#import "ACSearchController.h"
#import "ACReadEvent.h"
#import "ACReadSeq.h"
#import "ACUser.h"
#import "ACUserDB.h"
#import "ACNoteTimeLineVC.h"
#import "ACSetAdminViewController.h"
#import "AcuComDebugServerDef.h"
#import "ELCImagePickerController.h"
#import "ACChatViewPopMenuView.h"
#import "ACTransmitViewController.h"
#import "JHNotificationManager.h"
#import "ACEntityEvent.h"
#import "ACNoteDetailVC.h"
#import "ACVideoCall.h"


#if DEBUG
#import "ACMapShareLocalVC.h"
#import "ACVideoCallVC.h"
#endif

extern NSString * const kNetCenterSendMessageSuccessNotifation;
extern NSString * const kNetCenterSendMessageFailNotifation;


#ifdef ACUtility_Need_Log
#import "SDImageCache.h"
#endif

//在标题上是否显示连接状态
#if 1 //DEBUG
    #define kLoopInquireState @"loopInquireState"
#endif

//#define ACChatViewController_NeedShowLoadingHUD    //需要在界面上显示登录进度条

#define kCoverTag    12131
#define kUIAlertViewTagForLoginFail 11111

#ifdef BUILD_FOR_EGA
    #define ACChatViewController_Disable_Wallboard  //屏蔽
#endif

@interface ACChatViewController ()<ELCImagePickerControllerDelegate>{
    BOOL                        _bACConfigsAndACNetCenter_ObserverNeedRemove; //监听需要移除
#ifdef ACChatViewController_NeedShowLoadingHUD
    BOOL                        _bNeedShowLoginHUD; //是否在登录时显示Loading
    //    BOOL                        _bLoginHUDShowed; //View是否显示了
    NSTimer*                    _timerForLoginCheck;    //检查登录

#endif
}

@end

@implementation ACChatViewController

- (void)dealloc{
    AC_MEM_Dealloc();
    if(_bACConfigsAndACNetCenter_ObserverNeedRemove){
        _bACConfigsAndACNetCenter_ObserverNeedRemove = NO;
#ifdef kRootViewControllerShowing
        [[ACConfigs shareConfigs] removeObserver:self forKeyPath:kRootViewControllerShowing];
#endif
#ifdef kLoopInquireState
        [[ACNetCenter shareNetCenter] removeObserver:self forKeyPath:kLoopInquireState];
#endif
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isOpenHotspot = NO;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)removeNotification
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if(_bACConfigsAndACNetCenter_ObserverNeedRemove){
        _bACConfigsAndACNetCenter_ObserverNeedRemove = NO;
#ifdef kRootViewControllerShowing
        [[ACConfigs shareConfigs] removeObserver:self forKeyPath:kRootViewControllerShowing];
#endif
#ifdef kLoopInquireState
        [[ACNetCenter shareNetCenter] removeObserver:self forKeyPath:kLoopInquireState];
#endif
    }
}

#ifdef ACChatViewController_NeedShowLoadingHUD
-(void)showOrHideLoginHUD:(BOOL)bShow{
    

//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loginFail:) object:nil];
    [_timerForLoginCheck invalidate];
    _timerForLoginCheck = nil;
    [self.view hideProgressHUDWithAnimated:NO];

    if(bShow){
        [self.view showProgressHUDWithLabelText:nil // NSLocalizedString(@"Loading", nil)
                                      withAnimated:YES
                                withAfterDelayHide:0];
        //加载失败
//        [self performSelector:@selector(loginFail:) withObject:nil afterDelay:15];
        _timerForLoginCheck =   [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(loginCheckTimerFunc) userInfo:nil repeats:YES];
    }
//    _bLoginHUDShowed =  bShow;

}
#endif

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//TXB    [self.viewDeckController setPanningMode:IIViewDeckFullViewPanning];
//    self.mm_drawerController.openDrawerGestureModeMask = MMOpenDrawerGestureModeAll;
    [self initHotspot];
    [self refreshData];
    
   
    ACConfigs* pCfg = [ACConfigs shareConfigs];
    
    if(nil==[ACDataCenter shareDataCenter].entityForNotification&&
       nil==[ACDataCenter shareDataCenter].shareFilePaths){ //不是外部调用
        
        [pCfg newAppVersionCheckShowUpdateAlertView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(haveNewAppVersion) name:kHaveNewAppVerion object:nil];
 
        //TXB 显示
#ifdef ACUtility_Need_Log
        SDImageCache* pImageCache = [SDImageCache sharedImageCache];
        ITLogEX(@"SDImageCache file(%d,%dM) mem(%d,%dM)",
                [pImageCache getDiskCount],[pImageCache getSize]/(1024*1024),
                [pImageCache getMemoryCount],[pImageCache getMemorySize]/(1024*1024));
#endif
    }


    
#ifdef ACChatViewController_NeedShowLoadingHUD
    if(_bNeedShowLoginHUD){
        if(pCfg.isLogined){
            [self loginSuccess:nil];
        }
        else{
            [self showOrHideLoginHUD:YES];
        }
    }
#endif
    
#ifdef kLoopInquireState
    [self reloadLoginState:YES];
#endif
    
    [[ACNetCenter shareNetCenter] loopInquireCheckTCPConnect];
//    [self.view showProgressHUDNoActivityWithLabelText:@"发帖前先进行站内搜索，若存在同名漫画，禁止二次发布" withAfterDelayHide:5];

//    for(int i=0;i<10;i++){
//        NSTimeInterval tm = [[NSDate date] timeIntervalSince1970];
//        NSLog(@"%f,%ld,%.0f, %@",tm,(long)tm,tm*1000L,[ACMessage getTempMsgID]);
//        //1446716780.735676,1446716780,2147483647, 2147483647
//        [NSThread sleepForTimeInterval:0.1];
//    }
//    ACBaseEntity* pForNotify = [ACDataCenter shareDataCenter].entityForNotification;
//    [ACDataCenter shareDataCenter].entityForNotification = nil;
//    if(pForNotify){
//        [self.view showProgressHUD];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self openEntity:pForNotify animated:YES];
//        });
//    }
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_orientChange:) name:UIDeviceOrientationDidChangeNotification object:nil];

    AC_MEM_Check(ACCenterViewControllerType_All==_chatListType);
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self initHotspot];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kHaveNewAppVerion object:nil];
    
//TXB    [self.viewDeckController setPanningMode:IIViewDeckNoPanning];
#ifdef ACChatViewController_NeedShowLoadingHUD
    [self showOrHideLoginHUD:NO];
#endif
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(syncSuccess:) name:kNetCenterSyncFinishNotifation object:nil];
#ifdef ACChatViewController_NeedShowLoadingHUD
    if(![ACConfigs shareConfigs].isLogined){
        _bNeedShowLoginHUD  = YES;
        [nc addObserver:self selector:@selector(loginSuccess:) name:kNetCenterLoginSuccRSNotifation object:nil];
//        [nc addObserver:self selector:@selector(loginFail:) name:kNetCenterLoginFailRSNotifation object:nil];
    }
#endif
    
    if(LoginState_logined!=[ACConfigs shareConfigs].loginState){
        [nc addObserver:self selector:@selector(loginSuccess:) name:kNetCenterLoginSuccRSNotifation object:nil];
    }
    
    [nc addObserver:self selector:@selector(createGroupSucc) name:kNetCenterCreateGroupChatNotifation object:nil];
    [nc addObserver:self selector:@selector(newMessageAddSuccess) name:kMessageAddNotification object:nil];
    [nc addObserver:self selector:@selector(getChatMessageNotification:) name:kNetCenterGetChatMessageNotifation object:nil];
    [nc addObserver:self selector:@selector(UpdateTopicEntityInfo:) name:kNetCenterUpdateTopicEntityInfoNotifation object:nil];
    [nc addObserver:self selector:@selector(UpdateUrlEntityInfo:) name:kNetCenterUpdateUrlEntityInfoNotifation object:nil];
    [nc addObserver:self selector:@selector(refreshData) name:kDataCenterEntityDBLoadedNotifation object:nil];
//    [nc addObserver:self selector:@selector(refreshData) name:kUpdateUnReadCountNotification object:nil];
    [nc addObserver:self selector:@selector(sendMessageSuccessNotification:) name:kNetCenterSendMessageSuccessNotifation object:nil];
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
    [nc addObserver:self selector:@selector(readSeqUpdate:) name:kACReadSeqUpdateNotification object:nil];
    if (_chatListType == ACCenterViewControllerType_Services || _chatListType == ACCenterViewControllerType_All)
    {
        [nc addObserver:self selector:@selector(wallboardTopicEntityChange:) name:kDataCenterWallboardTopicEntityChangeNotifation object:nil];
    }
    
    [nc addObserver:self selector:@selector(noteOrCommentUpdataTimeChanged:) name:kNoteOrCommentUpdateTimeChanged object:nil];
    [nc addObserver:self selector:@selector(topicEntityTurnOffAlertsChangedNotify:) name:kACTopicEntityTurnOffAlertsNotifation object:nil];
    
    _bACConfigsAndACNetCenter_ObserverNeedRemove   =   YES;
    
#ifdef kRootViewControllerShowing
    [[ACConfigs shareConfigs] addObserver:self forKeyPath:kRootViewControllerShowing options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
#endif
    
#ifdef kLoopInquireState
    [[ACNetCenter shareNetCenter] addObserver:self forKeyPath:kLoopInquireState options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
#else
    _activityView.hidden = YES;
#endif
    
#ifdef ACUtility_Need_Log
    _chatListTitle = @"DEBUG";
#endif
    
    _mainTableView.tableHeaderView = _searchBar;
    _searchBar.placeholder = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Search", nil),[_chatListTitle lowercaseString]];
    [_mainTableView setContentOffset:CGPointMake(0, 44)];
    _chatType = ChatType_Define;
    _filterArray = [[NSMutableArray alloc] init];
//    [_mainTableView setContentInset:UIEdgeInsetsMake(-44, 0, 0, 0)];
    
    _titleLabel.text = _chatListTitle;

    
//    [_backButton setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateNormal];
    
    if (![ACConfigs isPhone5])
    {
        [_mainTableView setFrame_height:_mainTableView.size.height-88];
        [_contentView setFrame_height:_contentView.size.height-88];
    }
    
    
#ifdef acuCom_Debug_Login_Server
    {
        CGSize TheSize = _contentView.size;
        int nShowRectWH = 220;
        UIImageView* pDebugImageView = [[UIImageView alloc] initWithFrame:CGRectMake((TheSize.width-nShowRectWH)/2, (TheSize.height-nShowRectWH)/2, nShowRectWH, nShowRectWH)];
        pDebugImageView.image = [UIImage imageNamed:@"Bug"];
        pDebugImageView.alpha = 0.3;
        [_contentView addSubview:pDebugImageView];
        [_contentView sendSubviewToBack:pDebugImageView];
        _mainTableView.backgroundColor = [UIColor clearColor];
    }
#endif
    
    
#ifdef BUILD_FOR_EGA
    [_backButton setImage:[UIImage imageNamed:@"back_logo.png"] forState:UIControlStateNormal];
#endif
    
//    if (![ACConfigs shareConfigs].isSynced)
//    {
//        if ([ASIHTTPRequest isValidNetWork])
//        {
//            [_contentView showNetLoadingWithAnimated:NO];
//        }
//        else
//        {
//            [_contentView showProgressHUDNoActivityWithLabelText:NSLocalizedString(@"Network_Failed", nil) withAfterDelayHide:1.2];
//        }
//    }
    [self checkNotification];
}

-(void)checkNotification{
    
    ACDataCenter* pDataCenter = [ACDataCenter shareDataCenter];

    if(!(pDataCenter.entityForNotification||pDataCenter.shareFilePaths)){
        //没有需要处理的数据
        return;
    }
    
    if(LoopInquireState_synchronized!=[ACNetCenter shareNetCenter].loopInquireState){
        //没有同步完成
        [_contentView showProgressHUD];
        return;
    }
    
    [_contentView hideProgressHUDWithAnimated:NO];
    
    if(pDataCenter.entityForNotification){
        if(pDataCenter.noteIdForNotification){
            [ACNoteDetailVC showNoteMsgWithNoteID:pDataCenter.noteIdForNotification
                                         andTopic:(ACTopicEntity*)pDataCenter.entityForNotification
                                     andHighlight:nil
                                   inNomalSuperVC:self];
            /*
            ACNoteTimeLineVC* pTimeLineVC =  [[ACNoteTimeLineVC alloc] init];
            pTimeLineVC.topicEntity = (ACTopicEntity*)pDataCenter.entityForNotification;
            pTimeLineVC.noteIdForNotification = pDataCenter.noteIdForNotification;
            [self.navigationController pushViewController:pTimeLineVC animated:NO];*/
        }
        else{
            [self openEntity:pDataCenter.entityForNotification animated:YES];
        }
        
        pDataCenter.entityForNotification = nil;
        pDataCenter.noteIdForNotification = nil;
        return;
    }
    
    if(pDataCenter.shareFilePaths){
        [self.navigationController pushViewController:[ACTransmitViewController newForSendFiles:pDataCenter.shareFilePaths] animated:YES];
        pDataCenter.shareFilePaths = nil;
        return;
    }
    
    //处理用户强行跳转
    //        ACBaseEntity* pForNotify =
 }

#pragma mark -kvo
#if defined(kRootViewControllerShowing)||defined(kLoopInquireState)
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    dispatch_async(dispatch_get_main_queue(), ^{
#ifdef kRootViewControllerShowing
        
        if (object == [ACConfigs shareConfigs] && [keyPath isEqualToString:kRootViewControllerShowing])
        {
            if ([ACConfigs shareConfigs].rootViewControllerShowing)
            {
                UIView *view = [self.view viewWithTag:kCoverTag];
                if (!view)
                {
                    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];
                    view.backgroundColor = [UIColor clearColor];
                    [self.view addSubview:view];
                    view.tag = kCoverTag;
                    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
                    [view addGestureRecognizer:tap];
                }
                
                [_searchBar resignFirstResponder];
            }
            else
            {
                UIView *view = [self.view viewWithTag:kCoverTag];
                if (view)
                {
                    [view removeFromSuperview];
                }
            }
        }
        else
#endif
#ifdef kLoopInquireState
        if (object == [ACNetCenter shareNetCenter] && [keyPath isEqualToString:kLoopInquireState])
        {
            [self reloadLoginState:NO];
        }
#endif
    });
}
#endif

#ifdef kLoopInquireState
// 禁止状态提示，后台安静的童虎和登陆
-(void)reloadLoginState:(BOOL)bisFirstCheck
{
    BOOL bActivityViewHide =    YES;
    NSString* pTitle = nil;
    
    if (![ASIHTTPRequest isValidNetWork]){
        pTitle  =   NSLocalizedString(@"No Internet Connection", nil);
    }
    else{
        enum LoopInquireState loginState = [ACNetCenter shareNetCenter].loopInquireState;
        if(LoopInquireState_synchronized!=loginState){
            pTitle = NSLocalizedString(@"Loading...", nil);
            bActivityViewHide = NO;
        }
/*
        if (loginState == LoopInquireState_notConnected)
        {
    //        if([ACNetCenter shareNetCenter].bShowDisconnectStatInfo){
    //            pTitle = NSLocalizedString(@"Disconnected", nil);
    //        }
    //        else if(bisFirstCheck){
                pTitle = NSLocalizedString(@"Connecting...", nil);
                bActivityViewHide = NO;
    //        }
        }
        else if (loginState == LoopInquireState_Connecting)
        {
            pTitle = NSLocalizedString(@"Connecting...", nil);
            bActivityViewHide = NO;
        }
        else if (loginState == LoopInquireState_synchronizing)
        {
            pTitle = NSLocalizedString(@"Loading...", nil);
            bActivityViewHide = NO;
        }
    //    else if (loginState == LoginState_synchronized)
    //    {
    //        bActivityViewHide = NO;
    //    }*/
    }
    
#ifdef ACChatViewController_NeedShowLoadingHUD
    if(pTitle&&(!_bNeedShowLoginHUD))
#else
    if(pTitle)
#endif
    {
#if DEBUG
        if(LoginState_logined!=[ACConfigs shareConfigs].loginState){
            pTitle = [NSString stringWithFormat:@"%@(Debug:%@)",pTitle,LoginState_waiting==[ACConfigs shareConfigs].loginState?@"Wait Login":@"Logining"];
        }
#endif
        ITLogEX(@"loginState Show for %@",pTitle);
        _netStatLable.text  =   pTitle;
        _activityView.hidden = bActivityViewHide;
        if(bActivityViewHide){
            [_activityView stopAnimating];
        }
        else{
            [_activityView startAnimating];
        }
        _netStatView.hidden = NO;
    }
    else if(!_netStatView.hidden){
        ITLogEX(@"loginState hide");
        [UIView animateWithDuration:2 animations:^{
            [_activityView stopAnimating];
            _netStatView.hidden = YES;
            [self checkNotification];
        }];
    }
}
#endif

#pragma mark -tap
-(void)tap:(UITapGestureRecognizer *)tap
{
    [self catalogButtonTouchUp:nil];
}

#pragma mark -noti
-(void)readSeqUpdate:(NSNotification *)noti
{
    ACReadSeq *seq = noti.object;
    for (int i = 0; i < [[ACDataCenter shareDataCenter].topicEntityArray count]; i++)
    {
        ACTopicEntity *topicEntity = [[ACDataCenter shareDataCenter].topicEntityArray objectAtIndex:i];
        if ([topicEntity.entityID isEqualToString:seq.topicEntityID])
        {
            if ([ACUser isMySelf:seq.userID])
            {
                if (topicEntity.currentSequence < seq.seq)
                {
                    topicEntity.currentSequence = seq.seq;
                    if (topicEntity.lastestSequence < topicEntity.currentSequence)
                    {
                        topicEntity.currentSequence = topicEntity.lastestSequence;
                    }
                    [_mainTableView reloadData];
                    [[ACConfigs shareConfigs] updateApplicationUnreadCount];
                }
            }
        }
    }
}

#pragma mark -set method
-(void)setChatListType:(enum ACCenterViewControllerType)chatListType
{
    _chatListType = chatListType;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self refreshData];
    });
}

-(void)refreshData
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.dataSourceArray = [[ACDataCenter shareDataCenter] getChatListDataSourceArrayWithChatListType:_chatListType];
        
    #ifdef ACChatViewController_Disable_Wallboard
        //如果删除Wallbarb
        if(ACCenterViewControllerType_All==_chatListType){
            for(ACBaseEntity *entity in self.dataSourceArray){
                if ([entity.mpType isEqualToString:cWallboard]){
                    [self.dataSourceArray removeObject:entity];
                    break;
                }
            }
        }
    #endif

        dispatch_async(dispatch_get_main_queue(), ^{
            [_mainTableView reloadData];
        });
    });

    

}

#pragma mark -searchDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchBar.text length] == 0)
    {
        _chatType = ChatType_Define;
        self.searchKey = nil;
        [_mainTableView reloadData];
    }
    else
    {
        _chatType = ChatType_Search;
        self.searchKey = searchBar.text;
        [_filterArray removeAllObjects];
        for (ACTopicEntity *entity in _dataSourceArray)
        {
            NSString* pSearchedStr = entity.title;
            
            if ([entity isKindOfClass:[ACTopicEntity class]])
            {
                if([entity.mpType isEqualToString:cSingleChat]){
                    ACUser *user = [ACUserDB getUserFromDBWithUserID:entity.singleChatUserID];
                    pSearchedStr = user.name;
                }
                else if(entity.relateTeID.length > 0) // 特殊会话
                {
                    ACUser *user = [ACUserDB getUserFromDBWithUserID:entity.relateChatUserID];
                    pSearchedStr = user.name;
                }
            }

            if ([pSearchedStr rangeOfString:searchBar.text options:NSCaseInsensitiveSearch].length > 0)
            {
                [_filterArray addObject:entity];
            }
        }
        [_mainTableView reloadData];
    }
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = nil;
    [self searchBar:searchBar textDidChange:@""];
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

#pragma mark -notification

-(void)noteOrCommentUpdataTimeChanged:(NSNotification *)noti{
    [_notifyButton setImage:[UIImage imageNamed:[noti.object intValue]?@"header_icon_noti_new.png":@"header_icon_noti.png"] forState:UIControlStateNormal];
}

-(void)wallboardTopicEntityChange:(NSNotification *)noti
{
    [self refreshData];
}

-(void)syncSuccess:(NSNotification *)noti
{
    [_contentView hideProgressHUDWithAnimated:NO];
    [self checkNotification];
    [self refreshData];
}

/*
-(void)loginFail:(NSNotification *)noti
{
    if(!_bLoginHUDShowed){
        return;
    }
    
    [self showOrHideLoginHUD:NO];
    
    if([ACConfigs shareConfigs].isLogined){
        return;
    }
    
    UIAlertView* customAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil)
                                                          message:NSLocalizedString(@"Login failed, please retry", nil)
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                otherButtonTitles:NSLocalizedString(@"Retry", nil),nil];
    customAlert.tag = kUIAlertViewTagForLoginFail;
    [customAlert show];
}*/

-(void)loginSuccess:(NSNotification *)noti{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNetCenterLoginSuccRSNotifation object:nil];
    [_mainTableView reloadData];
}


#ifdef ACChatViewController_NeedShowLoadingHUD
-(void)loginSuccess:(NSNotification *)noti
{

    _bNeedShowLoginHUD = NO;
    [self showOrHideLoginHUD:NO];
}

-(void)loginCheckTimerFunc{
    //检查登录
//    ITLogEX(@"%@",_timerForLoginCheck.fireDate);
//    这里检查超时，如果超时则提示。
    if([ACConfigs shareConfigs].isLogined){
        [self loginSuccess:nil];
    }
}
#endif

-(void)sendMessageSuccessNotification:(NSNotification *)noti
{
    [_mainTableView reloadData];
}

-(void)hotspotStateChange:(NSNotification *)noti
{
    if (_isOpenHotspot)
    {
        [_mainTableView setFrame_height:_mainTableView.size.height-hotsoptHeight];
        [_contentView setFrame_height:_contentView.size.height-hotsoptHeight];
    }
    else
    {
        [_mainTableView setFrame_height:_mainTableView.size.height+hotsoptHeight];
        [_contentView setFrame_height:_contentView.size.height+hotsoptHeight];
    }
}

-(void)UpdateTopicEntityInfo:(NSNotification *)noti
{
    switch (_chatListType)
    {
        case ACCenterViewControllerType_All:
        case ACCenterViewControllerType_Chat:
        {
            if([noti.object integerValue]==EntityEventType_UpdateTopicEntity){
                [_mainTableView reloadData];
            }
            else{
                [self refreshData];
            }
//            [_mainTableView reloadData];
        }
            break;
            
        default:
            break;
    }
}

-(void)UpdateUrlEntityInfo:(NSNotification *)noti
{
    switch (_chatListType)
    {
        case ACCenterViewControllerType_All:
        {
            [_mainTableView reloadData];
        }
            break;
        case ACCenterViewControllerType_Event:
        case ACCenterViewControllerType_Survey:
        case ACCenterViewControllerType_Link:
        case ACCenterViewControllerType_Page:
        {
            [self refreshData];
        }
            break;
            
        default:
            break;
    }
}



-(void)getChatMessageNotification:(NSNotification *)noti
{
    [_mainTableView reloadData];
}

-(void)createGroupSucc
{
    [self refreshData];
}

-(void)newMessageAddSuccess
{
    [_mainTableView reloadData];
}

-(void)topicEntityTurnOffAlertsChangedNotify:(NSNotification *)noti{
    [_mainTableView reloadData];
}

-(void)haveNewAppVersion{
    [[ACConfigs shareConfigs] newAppVersionCheckShowUpdateAlertView];
}

#pragma mark -scrollViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [_searchBar resignFirstResponder];
}

#pragma mark -UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ACEntityCell_Hight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_chatType == ChatType_Search)
    {
        return [_filterArray count];
    }
    else
    {
        return [_dataSourceArray count];
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    ACEntityCell *cell =    [ACEntityCell cellForTableView:tableView];
//    ACEntityCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACEntityCell"];
//    if (!cell)
//    {
//        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACEntityCell" owner:nil options:nil];
//        cell = [nib objectAtIndex:0];
//    }
    
    NSArray *array = nil;
    if (_chatType == ChatType_Search)
    {
        array = _filterArray;
    }
    else
    {
        array = _dataSourceArray;
    }
    if (row < (int)[array count] && row >= 0)
    {
        [cell setEntity:[array objectAtIndex:row] superVC:self];
    }
    
    ///
    if (row == (_dataSourceArray.count - 1)) {
        
//        NSString *path = @"文件夹路径";
//        
//        NSFileManager *fm =  [NSFileManager defaultManager];
//        
//        NSArray *arr = [fm directoryContentsAtPath:path];
        
//        1、获取程序的Home目录
        NSString *homeDirectory = NSHomeDirectory();
        NSLog(@"path:%@", homeDirectory);
//        2、获取document目录
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [paths objectAtIndex:0];
        NSLog(@"path:%@", path);
//        3、获取Cache目录
        
        NSArray *Cachepaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *Cachepath = [Cachepaths objectAtIndex:0];
        NSLog(@"%@", Cachepath);
//        4、获取Library目录
        
        NSArray *Librarypaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *Librarypath = [Librarypaths objectAtIndex:0];
        NSLog(@"%@", Librarypath);
//        5、获取Tmp目录
        
        NSString *tmpDir = NSTemporaryDirectory(); 
        NSLog(@"%@", tmpDir);
    }
    
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
#ifdef kRootViewControllerShowing
    if ([ACConfigs shareConfigs].rootViewControllerShowing)
    {
        [self catalogButtonTouchUp:nil];
        return;
    }
#endif
    
//    NSInteger row = indexPath.row;
    
    NSArray *array = _chatType == ChatType_Search?_filterArray:_dataSourceArray;
//    if (_chatType == ChatType_Search)
//    {
//        array = _filterArray;
//    }
//    else
//    {
//        array = _dataSourceArray;
//    }
//    ACBaseEntity *entity = [array objectAtIndex:row];
    [self openEntity:[array objectAtIndex:indexPath.row] animated:YES];
}

-(void)openEntity:(ACBaseEntity*)entity animated:(BOOL)animated{
    [self.view hideProgressHUDWithAnimated:NO];
    enum EntityType entityType = [entity isKindOfClass:[ACTopicEntity class]]?EntityType_Topic:EntityType_URL;
    if (entityType == EntityType_Topic)
    {
        ACTopicEntity *topicEntity = (ACTopicEntity *)entity;
        if ([topicEntity.mpType isEqualToString:cWallboard])
        {
            ACWallBoardViewController *notesVC = [[ACWallBoardViewController alloc] init];
            notesVC.topicEntity = topicEntity;
            [self.navigationController pushViewController:notesVC animated:animated];
        }
        else
        {
            ACChatMessageViewController *chatMessageVC = [[ACChatMessageViewController alloc] initWithSuperVC:self withTopicEntity:topicEntity];
//            chatMessageVC.topicEntity = topicEntity;
//            [chatMessageVC preloadDB];
            AC_MEM_Alloc(chatMessageVC);
            [chatMessageVC setHidesBottomBarWhenPushed:animated];
            [self.navigationController pushViewController:chatMessageVC animated:animated];
        }
    }
    else
    {
        NSString *urlString = nil;
        ACUrlEntity *urlEntity = (ACUrlEntity *)entity;
        if ([urlEntity.url hasPrefix:@"page://"])
        {
            NSString *pageid = [[urlEntity.url componentsSeparatedByString:@"page://"] lastObject];
            if (ACPerm_URL_VIEWSURVEYREPORT_ALLOW==urlEntity.urlPerm.viewSurveyReport)
            {
                urlString = @"ujs/app/pageDesigner/ui/survey/report.html";
//                urlString = [NSString stringWithFormat:@"%@/ujs/app/pageDesigner/ui/survey/report.html?pageid=%@&eid=%@",[[ACNetCenter shareNetCenter] acucomServer],pageid,urlEntity.entityID];
            }
            else
            {
                urlString   =   @"ujs/app/pageDesigner/ui/survey/mobile.html";
//                urlString = [NSString stringWithFormat:@"%@/ujs/app/pageDesigner/ui/survey/mobile.html?pageid=%@&eid=%@",[[ACNetCenter shareNetCenter] acucomServer],pageid,urlEntity.entityID];
            }
            urlString = [NSString stringWithFormat:@"%@/%@?pageid=%@&eid=%@&terminal=mobile&locale=%@",[[ACNetCenter shareNetCenter] acucomServer],urlString,pageid,urlEntity.entityID,[NSLocale preferredLanguages].firstObject];
        }
        else
        {
//有大小写的问题            urlString = [urlEntity.url lowercaseString];
            urlString = urlEntity.url;
        }
        ACAcuLearnWebViewController *acuLearnWebVC = [[ACAcuLearnWebViewController alloc] initWithUrlString:urlString];
        acuLearnWebVC.titleString = urlEntity.title;
        acuLearnWebVC.urlEntity = urlEntity;
        if ([urlEntity.url hasPrefix:@"page://"])
        {
            [acuLearnWebVC setNeedAction:NO];
        }
        [self.navigationController pushViewController:acuLearnWebVC animated:animated];
    }
}

#pragma mark ELCImagePickerControllerDelegate

#if TARGET_IPHONE_SIMULATOR
- (void)elcImagePickerController:(ELCImagePickerController *)picker sendPreviewImgWithCaptions:(NSArray *)Images{
    //    [picker dismissViewControllerAnimated:YES completion:nil];
    [picker ACdismissViewControllerAnimated:YES completion:nil];
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker
{
    [picker ACdismissViewControllerAnimated:YES completion:nil];
    //    [picker dismissViewControllerAnimated:YES completion:nil];
}
#endif


#pragma mark -IBAction

-(IBAction)catalogButtonTouchUp:(id)sender
{
    [_searchBar resignFirstResponder];
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];

//    [self.viewDeckController toggleLeftView];
}

extern const CFStringRef kUTTypeImage;


//-(void)onActive{
//    ITLog(@"onActive");
//}

-(IBAction)searchButtonTouchUp:(id)sender
{
#if DEBUG
    
    #if TARGET_IPHONE_SIMULATOR
    #else
    
    #endif
#endif
    
    ACSearchController *searchC = [[ACSearchController alloc] init];
    searchC.chatVC = self;
    AC_MEM_Alloc(searchC);
    [self.navigationController pushViewController:searchC animated:YES];

}

- (IBAction)onHeadNotify:(id)sender {
    ACNoteTimeLineVC* pTimeLineVC =  [[ACNoteTimeLineVC alloc] init];
    AC_MEM_Alloc(pTimeLineVC);
    [self.navigationController pushViewController:pTimeLineVC animated:YES];
}

//-(IBAction)noteButtonTouchUp:(id)sender
//{
//    ACWallBoardViewController *notesVC = [[ACWallBoardViewController alloc] init];
//    notesVC.topicEntity = [ACDataCenter shareDataCenter].wallboardTopicEntity;
//    [self.navigationController pushViewController:notesVC animated:YES];
//}

-(IBAction)createNewChatGroup:(UIButton*)sender
{
    
#if 0
    ACChooseContactViewController *chooseContactVC = [[ACChooseContactViewController alloc] init];
    AC_MEM_Alloc(chooseContactVC);
    chooseContactVC.cancelToViewController = self;
    chooseContactVC.chooseContactType = ChooseContactType_Root;
    chooseContactVC.addParticipant = ACAddParticipantType_New;
    [chooseContactVC setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:chooseContactVC animated:YES];
#else
    CGPoint point = [_contentView convertPoint:CGPointMake(sender.bounds.size.width/2, 0) fromView:sender];
    point.y = _contentView.frame.origin.y;
    
 
    ACChatViewPopMenuView* pPopMenu = [[ACChatViewPopMenuView alloc] initWithPoint:point titles:@[NSLocalizedString(@"Chat", nil), NSLocalizedString(@"Video Call", nil), NSLocalizedString(@"Audio Call", nil)] images:@[@"menuNewChat.png",@"menuVideoCall.png",@"menuVoiceCall.png"]];

    
    AC_MEM_Alloc(pPopMenu);
    
    [pPopMenu showInSpuerView:self.view withBlock:^(NSInteger nSelectNo){
        if(0==nSelectNo){
            ACChooseContactViewController *chooseContactVC = [[ACChooseContactViewController alloc] init];
            AC_MEM_Alloc(chooseContactVC);
            chooseContactVC.cancelToViewController = self;
            chooseContactVC.chooseContactType = ChooseContactType_Root;
            chooseContactVC.addParticipant = ACAddParticipantType_New;
            [chooseContactVC setHidesBottomBarWhenPushed:YES];
            [self.navigationController pushViewController:chooseContactVC animated:YES];
            return;
        }
        
        if(1==nSelectNo||2==nSelectNo){
            if([ACVideoCall inVideoCallAndShowTip]){
                return;
            }
//            ACTransmitViewController *transmitVC = [[ACTransmitViewController alloc] init];
//            transmitVC.isForVideoCall = 1==nSelectNo;
//            transmitVC.superVCForVideoCall = self;
            [self.navigationController pushViewController:[ACTransmitViewController newForVideoCall:1==nSelectNo withSuperVC:self] animated:YES];
            return;
        }
    }];
#endif
}

#pragma mark -deleteEntity
-(void)_deleteEntity:(ACBaseEntity *)entity withTransferAdmin:(NSArray*)pAdminIDs  forTerminate:(BOOL)terminate{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        NSString *rootUrl = REQUEST_TOPIC_MAPPING_ROOT;
//        if (entity.entityType == EntityType_Topic)
//        {
//            rootUrl = REQUEST_TOPIC_MAPPING_ROOT;
//        }
//        else if(entity.entityType == EntityType_URL)
//        {
//            rootUrl = REQUEST_URL_MAPPING_ROOT;
//        }
        
        NSString *urlString = entity.requestUrl;
        
        if(pAdminIDs.count){
            /* transferAdminId
                /rest/apis/url/{entityID}?t=id1,id2
             */
            NSMutableString* pURLBuffer = [[NSMutableString alloc] init];
            [pURLBuffer setString:[NSString stringWithFormat:@"%@?t=",urlString]];
            for(NSString* pID in pAdminIDs){
                [pURLBuffer appendFormat:@"%@,",pID];
            }
            [pURLBuffer deleteCharactersInRange:NSMakeRange(pURLBuffer.length-1, 1)];
            urlString = pURLBuffer;
        }
        else if(terminate){
            //解散组
            urlString   =   [urlString stringByAppendingString:@"/terminate"];
        }
        
        ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
        request.validatesSecureCertificate = NO;
        [request setRequestMethod:@"DELETE"];
        [request setRequestHeaders:[[ACNetCenter shareNetCenter] getRequestHeader]];
        request.useCookiePersistence = YES;
        __weak ASIHTTPRequest *requestTmp = request;
        [request setCompletionBlock:^{
            NSDictionary *responseDic = [[requestTmp responseData] objectFromJSONData];
            ITLogEX(@"%@:%@",urlString,responseDic);
            
            //1为succ，1066为topicEntity没找到，直接删除
            int nCode = [[responseDic objectForKey:@"code"] intValue];
            if (nCode == 1 ||
                nCode == 1066 ||
                nCode == 1090)
            {
                [[ACDataCenter shareDataCenter] remvoeEntity:entity];
                [self refreshData];
            }
        }];
        [request setFailedBlock:^{
            ITLog(([NSString stringWithFormat:@"删除失败:%@",requestTmp.error.localizedDescription]));
        }];
        [request startAsynchronous];
    });
}


-(void)deleteEntity:(ACBaseEntity *)entity  forTerminate:(BOOL)terminate{
    [self _deleteEntity:entity withTransferAdmin:nil forTerminate:terminate];
}

-(void)transferAdmin:(ACBaseEntity *)entity{
    ACSetAdminViewController* pVC = [[ACSetAdminViewController alloc] init];
    pVC.entity = entity;
    pVC.transferAdminFinishFunc = ^(NSArray* pAdminIDs){
        [self _deleteEntity:entity withTransferAdmin:pAdminIDs forTerminate:NO];
    };
    [self.navigationController pushViewController:pVC animated:YES];
}

-(void)changeIsTurnOffAlertsAndSendToServerForEntity:(ACTopicEntity*)topicEntity{
    [topicEntity changeIsTurnOffAlertsAndSendToServer:!topicEntity.isTurnOffAlerts withView:self.view];
}

-(void)reloadEntity{ //设置置顶
    [_mainTableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UIAlertViewDelegate
#ifdef ACChatViewController_NeedShowLoadingHUD
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(kUIAlertViewTagForLoginFail==alertView.tag){
        if(alertView.cancelButtonIndex==buttonIndex){
            _bNeedShowLoginHUD = NO;
        }
        else{
            ACConfigs* pCFG =   [ACConfigs shareConfigs];
            if(pCFG.isLogined){
                return;
            }
            
            //Retry
//            if(pCFG.deviceToken.length){
//                [[ACNetCenter shareNetCenter] autoLogin];
//            }
            
            [self showOrHideLoginHUD:YES];
        }
    }
}
#endif

//- (void)_orientChange:(NSNotification *)noti
//{
//    
//    //    NSDictionary* ntfDict = [noti userInfo];
//    
//    UIDeviceOrientation  orient = [UIDevice currentDevice].orientation;
//    /*
//     UIDeviceOrientationUnknown,
//     UIDeviceOrientationPortrait,            // Device oriented vertically, home button on the bottom
//     UIDeviceOrientationPortraitUpsideDown,  // Device oriented vertically, home button on the top
//     UIDeviceOrientationLandscapeLeft,       // Device oriented horizontally, home button on the right
//     UIDeviceOrientationLandscapeRight,      // Device oriented horizontally, home button on the left
//     UIDeviceOrientationFaceUp,              // Device oriented flat, face up
//     UIDeviceOrientationFaceDown             // Device oriented flat, face down   */
//    
//    switch (orient)
//    {
//        case UIDeviceOrientationPortrait:
//            ITLog(@"Portrait");
//            break;
//        case UIDeviceOrientationLandscapeLeft:
//            ITLog(@"LandscapeLeft");
//            
//            break;
//        case UIDeviceOrientationPortraitUpsideDown:
//            ITLog(@"UpsideDown");
//            
//            break;
//        case UIDeviceOrientationLandscapeRight:
//            ITLog(@"LandscapeRight");
//            
//            break;
//            
//        default:
//            break;
//    }
//}

@end
