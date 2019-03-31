//
//  ACMapShareLocalVC.m
//  chat
//
//  Created by Aculearn on 16/5/6.
//  Copyright © 2016年 Aculearn. All rights reserved.
//

#import "ACMapShareLocalVC.h"
#import "LTInfiniteScrollView.h"
#import "UIImageView+WebCache.h"
#import "UINavigationController+Additions.h"
#import "ACNetCenter.h"
#import "ACUser.h"


#if DEBUG
//    #define DEBUG_For_LocalUsers //加载本地用户数据测试
#endif

#ifdef DEBUG_For_LocalUsers
    #import "ACUserDB.h"
#endif

#define kActionSheetTag_Location_End    10004

NSString* const  shareLocalNotifyForUserInfoChangeEvent = @"_shareLocalNotifyForUserInfoChangeEvent";
NSString* const  _shareLocalUsersUpdate =   @"_shareLocalUsersUpdate"; //用户信息有更新
NSString* const  _shareLocalExit = @"_shareLocalExit";

#define User_Act_Type_Init      0
//act:0|1|2|3, 0发起, 1,加入，2，更新 3.删除
#define User_Act_Type_Start     1   //发起
#define User_Act_Type_Add       2   //加入
#define User_Act_Type_Update    3   //更新
#define User_Act_Type_Delete    4   //删除


#define ICONS_SCROLL_MAX_NUM    4
#define ICONS_SCROLL_WH         50

@interface ACSharingLocalMapUserInfo : NSObject <MKAnnotation>{
    @public
    
    int         nActType;
    NSString*   userID;
    NSString*   iconID;
    NSString*   userName;
}
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, weak)   MKAnnotationView* annotationView;
#ifdef DEBUG_For_LocalUsers
+(instancetype)initFromUser:(ACUser*)user;
#endif
+(NSMutableArray<ACSharingLocalMapUserInfo*>*)usersFromDicts:(NSArray*)dicts;
-(void) bringViewTopAndCenterMap:(MKMapView*)pMap;
@end


#define VC_STAT_need_init   0
#define VC_STAT_init_begin  1
#define VC_STAT_inited      2
#define VC_STAT_hide        3
#define VC_STAT_exit        4


@interface ACMapShareLocalVC ()<LTInfiniteScrollViewDataSource>{
    
    __weak IBOutlet UIButton *_buttonLocal;
    __weak IBOutlet UIButton *_buttonRecord;
    __weak IBOutlet LTInfiniteScrollView *_scrollIcons;
    __weak IBOutlet UILabel *_lableStatus;
    __weak IBOutlet MKMapView *_mapView;
    __weak IBOutlet UIView *_titleBkView;
    
#ifdef DEBUG_For_LocalUsers
    NSArray<ACUser*>*   _testUserInfo;
#endif
    int                             _nVCStat;   //状态
    ACSharingLocalMapUserInfo*      _myself;
    
    NSTimer*                        _timerForTick;
}

@property (nonatomic, weak)   ACChatMessageViewController* superVC;

@end

@implementation ACMapShareLocalVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _titleBkView.backgroundColor =  [UIColor colorWithRed:70.0 / 255.0 green:70.0 / 255.0 blue:70.0 / 255.0 alpha:0.7];
    
    _mapView.delegate = self;

    ACUser* pMySelf = [ACUser myself];
    if(0==_superVC.sharingLocalUsersInfo.count){
        _myself =   [[ACSharingLocalMapUserInfo alloc] init];
        _myself->userID     =   pMySelf.userid;
        _myself->userName   =   pMySelf.name;
        _myself->iconID     =   pMySelf.icon;
        [_superVC.sharingLocalUsersInfo addObject:_myself];
    }
    else{
        _myself =   _superVC.sharingLocalUsersInfo[0];
        NSAssert([_myself->userID isEqualToString:[ACUser myselfUserID]],@"MySelf Error");
    }
    
    _scrollIcons.dataSource = self;
    _scrollIcons.verticalScroll = NO;
//    _scrollIcons.maxScrollDistance = 5;
//    _scrollIcons.pagingEnabled = YES;
#ifdef DEBUG_For_LocalUsers
    _testUserInfo   =   [ACUserDB allUser];
#endif
    
    [self.view showProgressHUD];
}

#if DEBUG
-(void)dealloc{
    ITLog(@"dealloc");
}
#endif

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [_superVC sharingLocal_LBS_ChangeNotifyEnable:NO]; //关闭LBS改变
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_sharingLocalUserChangeNotify:) name:_shareLocalUsersUpdate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_sharingLocalExit:) name:_shareLocalExit object:nil];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [_timerForTick invalidate];
    _timerForTick = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(VC_STAT_inited==_nVCStat){ //没有正常退出
        [ACMapShareLocalVC exitShareLocalwithVC:_superVC];
    }
    [_superVC sharingLocal_LBS_ChangeNotifyEnable:YES];
}

+(void) showForSuperVC:(nonnull ACChatMessageViewController*)superVC{
    ACMapShareLocalVC* pVC = [[ACMapShareLocalVC alloc] init];
    pVC.superVC = superVC;
    [superVC ACpresentViewController:pVC animated:YES completion:nil];
}

+(void)checkChangeUsers:(NSArray<NSDictionary*>*) usrsDict withVC:(nonnull ACChatMessageViewController*)pVC{
/*
 
	{
 eventType:101,
 userCount: 10,
 users:[
 {
 act:0|1|2|3, 0发起, 1,加入，2，更新 3.删除
 id:"", userId
 lo:"",经度
 la:""，纬度
 name:"", userDispalyName
 icon:"", 头像
 }，
 ......
 {
 act:0|1|2, 0,加入，1，更新 2.删除
 id:"", userId
 lo:"",经度
 la:""，纬度
 name:"", userDispalyName
 icon:"", 头像
 }
 ]
 
 eventTime:1465977817256,
 eventUid:"555d58d5247b4c4a3232c0fd",
 teid:"574c15daaa8fa20cce7f7e13",
 terminal:"web"
	}
 */
    if(usrsDict.count){
        [ACUtility postNotificationName:_shareLocalUsersUpdate
                                                            object:[ACSharingLocalMapUserInfo usersFromDicts:usrsDict]];
    }
}

#define callShareLocaltionFuncType_Exit     0

#define callShareLocaltionFuncType_Start    1
#define callShareLocaltionFuncType_Join     2
#define callShareLocaltionFuncType_Update   3

#define callShareLocaltionFuncType_Start_or_Join    100

static const char*  _callShareLocaltionFuncTypeName[]={"exit","start","join","update"};

+(void)_callShareLocaltionFunc:(int)nFuncType
                       withLoc:(CLLocationCoordinate2D)loc
                        withVC:(nonnull ACChatMessageViewController*)_pVC
                      withSLVC:(ACMapShareLocalVC*)_pSelfVC{
    
    int nFuncTemp = nFuncType;
    __weak ACMapShareLocalVC* pSelfVC = _pSelfVC;
    __weak ACChatMessageViewController* pVC = _pVC;
    
    if(pSelfVC){
        nFuncTemp   =   pVC.topicEntity.nSharingLocalUserCount?callShareLocaltionFuncType_Join:callShareLocaltionFuncType_Start;
//        [pSelfVC.view showProgressHUD];
    }
    
    NSString* pURL = [NSString stringWithFormat:@"%@/rest/apis/location/%@/share?action=%s",[ACNetCenter shareNetCenter].acucomServer,pVC.topicEntity.entityID,_callShareLocaltionFuncTypeName[nFuncTemp]];

    [ACNetCenter callURL:pURL forPut:NO withPostData:@{@"lo":@(loc.longitude),@"la":@(loc.latitude)} withBlock:^(ASIHTTPRequest *request, BOOL bIsFail) {
        
        if(pSelfVC){
            [pSelfVC.view hideProgressHUDWithAnimated:NO];
        }
        
        if(!bIsFail){
            NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
            ITLog(responseDic);
            int nCode = [[responseDic objectForKey:kCode] intValue];
            
            //sharelocation?update, { "code" : 1400 , "description" : "位置共享结束。"}
            if(ResponseCodeType_ShareLocation_End==nCode){
                [ACUtility postNotificationName:_shareLocalExit
                                                                    object:nil];

                [pVC.sharingLocalUsersInfo removeAllObjects];
                pVC.topicEntity.nSharingLocalUserCount = 0;
                [pVC sharingLocalTipCheck];
                [pVC.view showNomalTipHUD:responseDic[kDescription]];
                return;
            }
            
            if(ResponseCodeType_Nomal==nCode){
/*取得全部用户信息

 1. Start,Join,Update:
 
 /apis/location/{topicEntityId}/share?action=start|join|update|exit
 METHOD:POST
 request data:{
	lo:0,
	la:0
 }
 
 response{
 code:1,
 
 -------------------------when action=join;
 hb:15000毫秒
 users:[
 {
 id:"", userId
 lo:"",经度
 la:""，纬度
 name:"", userDispalyName
 icon:"", 头像
 }，
 ......
 {
 id:"", userId
 lo:"",经度
 la:""，纬度
 name:"", userDispalyName
 icon:"", 头像
 }
 ]
 ---------------------------------------------
 }
 */
                if(pSelfVC){
                    NSMutableArray<ACSharingLocalMapUserInfo*>* pUsers = [ACSharingLocalMapUserInfo usersFromDicts:responseDic[@"users"]];
                    
                    if(pUsers.count){
                        //启动定时器
                        float fTimer =  [responseDic[@"hb"] integerValue]/1000.0;
                        __strong ACMapShareLocalVC* pSelfVC2 = pSelfVC;
                        if(fTimer>1){
                            pVC.sharingLocalTickTimeS = fTimer;
                            if(pSelfVC2){
                                [pSelfVC2->_timerForTick invalidate];
                                pSelfVC2->_timerForTick = nil;
                                pSelfVC2->_timerForTick = [NSTimer scheduledTimerWithTimeInterval:fTimer target:pSelfVC2 selector:@selector(_updataForTimer) userInfo:nil repeats:YES];
                            }
                        }

                        if(pSelfVC2){
                            pSelfVC2->_nVCStat = VC_STAT_inited;
                        }
                        
                        [pVC.topicEntity setSharingLocalUserCountAndSaveToDB:(int)pUsers.count];
                        [pSelfVC updateUsers:pUsers];
                    }
                    else{
                        [pSelfVC.view showNetErrorHUD];
                    }
                    return;
                }
                
                return;
            }
        }
        
        if(pSelfVC){
            //失败
            [pSelfVC.view showNetErrorHUD];
        }
    }];
}

+(BOOL) _canUpdataLocation:(CLLocation*)current withOld:(CLLocationCoordinate2D)locOld{ //是否可以发送
    return [current distanceFromLocation:[[CLLocation alloc] initWithLatitude:locOld.latitude longitude:locOld.longitude]]>=15;
}

+(BOOL) canUpdataLocation:(CLLocationCoordinate2D)loc withOldLoc:(CLLocationCoordinate2D)locOld{ //是否可以发送
    return [self _canUpdataLocation:[[CLLocation alloc] initWithLatitude:loc.latitude longitude:loc.longitude] withOld:locOld];
}

+(void)updataLocation:(CLLocationCoordinate2D)loc withVC:(nonnull ACChatMessageViewController*)pVC{
    if(pVC.sharingLocalUsersInfo.count){
        [self _callShareLocaltionFunc:callShareLocaltionFuncType_Update withLoc:loc withVC:pVC withSLVC:nil];
    }
}

+(void) exitShareLocalwithVC:(nonnull ACChatMessageViewController*)pVC{
    [pVC.sharingLocalUsersInfo removeAllObjects];
    [self _callShareLocaltionFunc:callShareLocaltionFuncType_Exit
                          withLoc:CLLocationCoordinate2DMake(0,0)
                           withVC:pVC
                         withSLVC:nil];
}

-(void)_updataForTimer{
    ITLogEX(@"......userCount=%d _nVCStat=%d.....",(int)_superVC.sharingLocalUsersInfo.count,_nVCStat);
    
    if(VC_STAT_inited==_nVCStat){
        if(_superVC.sharingLocalUsersInfo.count){
            [ACMapShareLocalVC _callShareLocaltionFunc:callShareLocaltionFuncType_Update
                                               withLoc:_myself.coordinate
                                                withVC:_superVC
                                              withSLVC:nil];
        }
        else {
            [ACMapShareLocalVC _callShareLocaltionFunc:callShareLocaltionFuncType_Start_or_Join
                                               withLoc:_myself.coordinate
                                                withVC:_superVC
                                              withSLVC:self];

        }
    }
}

-(void)_clearMySelf:(NSMutableArray<ACSharingLocalMapUserInfo*>*) pUsers{
    //清除自己
    for(NSInteger n=0;n<pUsers.count;n++){
        if([_myself->userID isEqualToString:pUsers[n]->userID]){
            [pUsers removeObjectAtIndex:n];
            return;
        }
    }
}

-(void)_sharingLocalUserChangeNotify:(NSNotification *)noti{
    //本地使用的，用户更新
    
    if(VC_STAT_need_init==_nVCStat){
        return;
    }

    NSMutableArray<ACSharingLocalMapUserInfo*>* pUsers = noti.object;
    [self _clearMySelf:pUsers];
    
    
    //更新局部
    NSArray<ACSharingLocalMapUserInfo*>* oldUsers = [NSArray arrayWithArray:_superVC.sharingLocalUsersInfo];

    NSMutableArray<ACSharingLocalMapUserInfo*>* pRemove = [[NSMutableArray alloc] initWithCapacity:pUsers.count];
    NSMutableArray<ACSharingLocalMapUserInfo*>* pNews = [[NSMutableArray alloc] initWithCapacity:pUsers.count];

    for(ACSharingLocalMapUserInfo* pNewUser in pUsers){
        ACSharingLocalMapUserInfo* pFindUser = nil;
        for(ACSharingLocalMapUserInfo* pOld in oldUsers){
            if([pOld->userID isEqualToString:pNewUser->userID]){
                pFindUser = pOld;
                break;
            }
        }

        if(User_Act_Type_Delete==pNewUser->nActType){
            if(pFindUser){
                [pRemove addObject:pFindUser];
            }
            continue;
        }
        
        if(pFindUser){
            pFindUser.coordinate =  pNewUser.coordinate;
        }
        else{
            [pNews addObject:pNewUser];
        }
    }
    [self _checkNewUsers:pNews andRemoveUsers:pRemove andOldUsers:oldUsers];
}

-(void)_checkAndReloadIcons:(NSInteger) nIconBeginNo{
    
    NSMutableArray<ACSharingLocalMapUserInfo*> *_usersInfo = _superVC.sharingLocalUsersInfo;
    if(0==_usersInfo.count){
        return;
    }
    
    CGRect rect = _scrollIcons.frame;
    CGRect lableRect = _lableStatus.frame;
    if(_usersInfo.count<ICONS_SCROLL_MAX_NUM){
        //缩小，居中
        rect.size.width =   (lableRect.size.width/ICONS_SCROLL_MAX_NUM)*_usersInfo.count;
        rect.origin.x   =   _lableStatus.center.x-rect.size.width/2;
    }
    else{
        rect.origin.x = lableRect.origin.x;
        rect.size.width = lableRect.size.width;
    }
    _scrollIcons.frame = rect;
    //        [_scrollIcons setNeedsLayout];

    [_scrollIcons reloadDataWithInitialIndex:nIconBeginNo];
}

-(void)_checkNewUsers:(NSMutableArray<ACSharingLocalMapUserInfo*>*)new_users andRemoveUsers:(NSMutableArray<ACSharingLocalMapUserInfo*>*) pRemove andOldUsers:(NSArray<ACSharingLocalMapUserInfo*>*)old{
    if(0==_superVC.sharingLocalUsersInfo.count){
        [_superVC sharingLocalTipCheck];
    }
    
    NSMutableArray<ACSharingLocalMapUserInfo*> *_usersInfo = _superVC.sharingLocalUsersInfo;
    
    NSString* pTipStat = nil;
    if(pRemove.count){
        [_usersInfo removeObjectsInArray:pRemove];
        [_mapView removeAnnotations:pRemove];
        //        pTipStat = [NSString stringWithFormat:NSLocalized String(@" ", nil),pRemove.lastObject->userName];
    }
    
    if(new_users.count){
        [_usersInfo addObjectsFromArray:new_users];
        [_mapView addAnnotations:new_users];
        //        pTipStat = [NSString stringWithFormat:NSLocalized String(@" ", nil),new_users.lastObject->userName];
    }
    
    if(_myself!=_usersInfo.firstObject){
        //第一个必须是自己
        [_usersInfo insertObject:_myself atIndex:0];
    }
    
    if(nil==pTipStat){
        pTipStat = [NSString stringWithFormat:NSLocalizedString(@"Real-time Location(%d)", nil),(int)_usersInfo.count];
    }
    _lableStatus.text   =   pTipStat;
    
    NSInteger nIconBeginNo = 0;
    if(_scrollIcons.currentIndex>0){
        for(NSInteger index=_scrollIcons.currentIndex;index<old.count;index++){
            NSString* pCurIndexUserID =   old[index]->userID;
            for(NSInteger n=0;n<_usersInfo.count;n++){
                if([pCurIndexUserID isEqualToString:_usersInfo[n]->userID]){
                    nIconBeginNo=   n;
                    index       =   old.count;
                    break;
                }
            }
        }
    }
    
    [self _checkAndReloadIcons:nIconBeginNo];
}


-(void)updateUsers:(NSMutableArray<ACSharingLocalMapUserInfo*>*)new_users{
    
    [self _clearMySelf:new_users];
    
    NSMutableArray<ACSharingLocalMapUserInfo*> *_usersInfo = _superVC.sharingLocalUsersInfo;
    if(_usersInfo.count){
        [_usersInfo removeObjectAtIndex:0];
    }
//    else{
//        [_usersInfo addObject:_myself];
//        [self _checkAndReloadIcons:0];
//        return;
//    }
    
    NSArray<ACSharingLocalMapUserInfo*>* old = [NSArray arrayWithArray:_usersInfo];

    NSMutableArray<ACSharingLocalMapUserInfo*>* pRemove = [[NSMutableArray alloc] initWithArray:_usersInfo];
    
    for(NSInteger n=0;n<new_users.count;n++){
        
        ACSharingLocalMapUserInfo* pNew =  new_users[n];
        
        for(NSInteger k=0;k<pRemove.count;k++){
            
            ACSharingLocalMapUserInfo* pOld =   pRemove[k];
            if([pOld->userID isEqualToString:pNew->userID]){
                //保留
                pOld.coordinate =   pNew.coordinate;
                
                
                [pRemove removeObjectAtIndex:k];
                k--;
                
                [new_users removeObjectAtIndex:n];
                n--;
                
                break;
            }
        }
    }
    [self _checkNewUsers:new_users andRemoveUsers:pRemove andOldUsers:old];
}

#ifdef DEBUG_For_LocalUsers
-(void)_testUser:(NSInteger)nCout{
    
    if(nCout<=0){
        return;
    }
    
    if(nCout>_testUserInfo.count){
        nCout = _testUserInfo.count/2;
    }
    
    NSMutableArray* pUsers = [[NSMutableArray alloc] initWithCapacity:10];
    NSMutableArray<ACUser*>* pRemove = [[NSMutableArray alloc] initWithArray:_testUserInfo];
    
    CLLocationCoordinate2D temp = _mapView.userLocation.coordinate;
    
    for(NSInteger n=0;n<nCout;n++){
        NSInteger index = (rand()%pRemove.count);
        ACSharingLocalMapUserInfo* user =   [ACSharingLocalMapUserInfo initFromUser:pRemove[index]];
        user.coordinate = CLLocationCoordinate2DMake(temp.latitude + (rand()%8)*0.01, temp.longitude + (rand()%10)*0.01);
        [pUsers addObject:user];
        [pRemove removeObjectAtIndex:index];
    }
    [self updateUsers:pUsers];
}
#endif

#pragma mark -mapViewDelegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    CLLocationCoordinate2D temp =   userLocation.location.coordinate;
    CLLocationCoordinate2D old =    _myself.coordinate;
    _myself.coordinate  =   temp;

    if(VC_STAT_need_init==_nVCStat){
        
        _nVCStat    =   VC_STAT_init_begin;
        [_mapView addAnnotations:_superVC.sharingLocalUsersInfo];
        
        _mapView.centerCoordinate = temp;
        _mapView.region = MKCoordinateRegionMake(temp, MKCoordinateSpanMake(0.01, 0.01));
        
        [self _checkAndReloadIcons:0];
        
        //调用加入,刷新一下数据
        [ACMapShareLocalVC _callShareLocaltionFunc:callShareLocaltionFuncType_Start_or_Join
                                           withLoc:temp
                                            withVC:_superVC
                                          withSLVC:self];
    }
    else if([ACMapShareLocalVC _canUpdataLocation:userLocation.location withOld:old]){
        //调用更新
        ITLog(@"");
        [ACMapShareLocalVC updataLocation:temp withVC:_superVC];
    }
}

-(void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error{
    ITLog(error.localizedDescription);
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    ACSharingLocalMapUserInfo* pUserInfo = [annotation isKindOfClass:[ACSharingLocalMapUserInfo class]]?(ACSharingLocalMapUserInfo*)annotation:_myself;
    
    {
        static NSString* pIdentifier =  @"LocalShare_Annotation_Location";
        
        MKAnnotationView *annotationView =[mapView dequeueReusableAnnotationViewWithIdentifier:pIdentifier];
        if(!annotationView){
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:pIdentifier];
            annotationView.canShowCallout = NO;
        }
        pUserInfo.annotationView = annotationView;
        [annotationView setImageForUsr:pUserInfo->userID withIcon:pUserInfo->iconID];
//        annotationView.image = [UIImage imageNamed:@"locationSharing_Member_def"];
        return annotationView;
    }
//    return _myself;
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
}

//- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
//    ITLog(@"");
//}

#pragma mark -actionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(kActionSheetTag_Location_End==actionSheet.tag){
        if(buttonIndex==actionSheet.destructiveButtonIndex){
            [self _onExitFunc:YES];
        }
        return;
    }
}

#pragma mark action
-(void)onSelectMember:(UITapGestureRecognizer *)recognizer{
//    [_mapView showAnnotations:@[_superVC.sharingLocalUsersInfo[recognizer.view.tag]] animated:YES];
    NSInteger nIndex = recognizer.view.tag;
    if(nIndex<_superVC.sharingLocalUsersInfo.count){
        [_superVC.sharingLocalUsersInfo[nIndex] bringViewTopAndCenterMap:_mapView];
    }
    else{
        [_scrollIcons reloadDataWithInitialIndex:0];
    }
}

-(void)_onExitFunc:(BOOL)forExit{
    [_timerForTick invalidate];
    _timerForTick = nil;
    ITLogEX(@"%@",forExit?@"call for exit":@"call for hide");
    if(forExit){
        _nVCStat = VC_STAT_exit;
        [ACMapShareLocalVC exitShareLocalwithVC:_superVC];
//        [_superVC sharingLocalTipCheck];
    }
    else{
        _nVCStat = VC_STAT_hide;
    }
    
    [self ACdismissViewControllerAnimated:YES completion:nil];
}

-(void)_sharingLocalExit:(NSNotification *)noti{
    [_timerForTick invalidate];
    _timerForTick = nil;
    _nVCStat = VC_STAT_exit;
    [self ACdismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)onExit:(id)sender {
    if(VC_STAT_inited!=_nVCStat){
        //没有初始化成功，直接退出不提示
        [self _onExitFunc:YES];
        return;
    }
    
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"End Real-time Location now?", nil)
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                               destructiveButtonTitle:NSLocalizedString(@"RLoc End", nil)
                                                    otherButtonTitles:nil];
    
    actionSheet.tag = kActionSheetTag_Location_End;
    [actionSheet showInView:self.view];

//    [self _onExitFunc:YES];
}
- (IBAction)onHide:(id)sender {
//    [self _testUser:rand()%10];
    [self _onExitFunc:NO];
}

- (IBAction)onUserCenter:(id)sender {
    [_mapView setCenterCoordinate:_mapView.userLocation.coordinate animated:YES];
}

- (IBAction)onSondBegin:(id)sender {
}
- (IBAction)onSondEnd:(id)sender {
}

#pragma mark LTInfiniteScrollViewDataSource
- (UIView *)viewAtIndex:(NSInteger)index reusingView:(UIView *)view{
    
    UIImageView *aView = (UIImageView*)view;
    if (nil==view) {
        aView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, ICONS_SCROLL_WH, ICONS_SCROLL_WH)];
        aView.layer.masksToBounds = YES;
        aView.layer.cornerRadius = aView.size.width*0.5;
        aView.layer.borderWidth =   2;
        aView.layer.borderColor = [UIColor whiteColor].CGColor;
        aView.backgroundColor = [UIColor whiteColor];
        aView.userInteractionEnabled = YES;

        [aView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSelectMember:)]];
    }
    
    [aView setImageWithIconString:_superVC.sharingLocalUsersInfo[index]->iconID
                 placeholderImage:[UIImage imageNamed:@"personIcon100"]
                        ImageType:ImageType_UserIcon100];
    
    aView.tag = index;
    return aView;
}

- (NSInteger)numberOfViews{
    //_scrollIcons
    return _superVC.sharingLocalUsersInfo.count;
}
- (NSInteger)numberOfVisibleViews{
    return ICONS_SCROLL_MAX_NUM;
}


@end

@implementation ACSharingLocalMapUserInfo

#ifdef DEBUG_For_LocalUsers
+(instancetype)initFromUser:(ACUser*)pUser{
    ACSharingLocalMapUserInfo* pMapUser = [[ACSharingLocalMapUserInfo alloc] init];
    pMapUser->userID    =   pUser.userid;
    pMapUser->iconID    =   pUser.icon;
    pMapUser->userName  =   pUser.name;
    return pMapUser;
}
#endif

-(void) bringViewTopAndCenterMap:(MKMapView*)pMap{
    [pMap setCenterCoordinate:_coordinate animated:YES];
    [_annotationView.superview bringSubviewToFront:_annotationView];
}

+(NSMutableArray<ACSharingLocalMapUserInfo*>*)usersFromDicts:(NSArray*)dicts{
    if(0==dicts.count){
        return nil;
    }
    
    NSMutableArray<ACSharingLocalMapUserInfo*>* pUsers = [[NSMutableArray alloc] initWithCapacity:dicts.count];
    for(NSDictionary* pDic in dicts){
        ACSharingLocalMapUserInfo* pUsr = [[ACSharingLocalMapUserInfo alloc] init];
        NSString* pAct =    pDic[@"act"];
        if(pAct){
            pUsr->nActType  =   [pAct intValue]+1;
        }
        pUsr->iconID    =   pDic[@"icon"];
        if([pUsr->iconID isEqual:[NSNull null]]){
            pUsr->iconID = nil;
        }
        pUsr->userID    =   pDic[@"id"];
        pUsr->userName  =   pDic[@"name"];
        pUsr.coordinate = CLLocationCoordinate2DMake([pDic[@"la"] doubleValue], [pDic[@"lo"] doubleValue]);

        [pUsers addObject:pUsr];
    }
    return pUsers;
}



@end
