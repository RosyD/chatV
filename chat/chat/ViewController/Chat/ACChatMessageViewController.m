//
//  ACChatMessageViewController.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-8.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACChatMessageViewController.h"
#import "UIView+Additions.h"
//#import "FaceButton.h"
#import "ACChatMessageTableViewCell.h"
#import "ACNetCenter.h"
#import "ACUserDB.h"
#import "ACUser.h"
#import "ACMessageEvent.h"
#import "ACMessage.h"
#import "ACConfigs.h"
#import "ACAddress.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "UIImage+Additions.h"
#import "ACMapViewController.h"
#import "ACGoogleHotspot.h"
#import "UIImage+Additions.h"

#import "UINavigationController+Additions.h"
#import "ACChooseContactViewController.h"
#import "ACParticipantInfoViewController.h"
#import "ACCreateChatGroupViewController.h"
#import "ACMessageDB.h"
#import "ACTopicEntityEvent.h"
//#import "IIViewDeckController.h"
#import "ACTopicEntityDB.h"
#import "ACReadCount.h"
#import "ACReadCountDB.h"
#import "ACReadSeqDB.h"
#import "ACReadSeq.h"
#import "ACReadEvent.h"
#import "ACLBSCenter.h"
#import "SvGifView.h"
#import "ACTransmitViewController.h"
#import "ACMapBrowerViewController.h"

#import "ACDataCenter.h"
#import "ACStickerPackage.h"
#import "ACMessage.h"
#import "JSONKit.h"
#import "ACChatMessageTableViewCell.h"
//#import "ACSendLocationViewController.h"
#import "ACMapViewController.h"
#import "UIImageView+WebCache.h"
#import "ACSearchDetailController.h"
#import "ACChatViewController.h"
#import "ACStickerGalleryController.h"
#import "ACNotesMsgVC_Main.h"
#import "ACVideoCall.h"
#import "NSString+PJR.h"
#import "ACMyStickerController.h"
#import "ACChatMessageViewController+Board.h"
#import "ACChatMessageViewController+Input.h"
#import "ACChatMessageViewController+Tap.h"

#import "JHNotificationManager.h"
#import "ACMapShareLocalVC.h"


extern NSString * const kNetCenterSendMessageSuccessNotifation;
extern NSString * const kNetCenterSendMessageFailNotifation;

#define ACMessage_loaded_Pre_Msg_Count    50 //加载旧消息数
#define loaded_Msg_Max_Count    800
//内存保存的信息最大个数，避免内存崩溃


#if TARGET_IPHONE_SIMULATOR
//    #define TARGET_IPHONE_SIMULATOR_Test_NewMsg_Button  //测试NewMsgButton
#endif

//#define stickerDownloadingButtonY   109
//#define stickerUnDownloadButtonY    80

#define checkResult(result,operation) (_checkResult((result),(operation),__FILE__,__LINE__))


//NSString *const kUpdateUnReadCountNotification =  @"kUpdateUnReadCountNotification";
//NSString *const kBeginDragNotification          =   @"kBeginDragNotification";
//NSString *const kStopDecelerateNotification     =   @"kStopDecelerateNotification";

@interface ACChatMessageViewController (){
    BOOL             _bForNewMsgCountViewTap;
    BOOL             _bIsBoardcast;
    
    BOOL             _bIsScrollTail; //已经滚动到底部了
    
//    int                      _nScrollDirection;   //滚动的方向 -1(向上),0,1
    NSInteger        _nNewUnreadMsgCount;   //还未阅读的消息数
    long             _searchSequence;       //用于search message
 
    
    long            _lNowLoadMsgOffset; //用于加载消息失败时的重试
    int             _nNowLoadMsgLimit; //=0 表示没有了
    BOOL            _bNowLoadMsgIsNew;
    BOOL            _isSearchTableCanShow;
    BOOL            _isNeedNetworkRequest;

    __weak UIViewController                *_superVC;

    
    BOOL                            _isCanLoadMore;//search load more使用，如果返回数据小于10条则将此值置为NO，下次上拉不加载更多
    BOOL                            _isFirstLoadMessage;
    BOOL                            _isDidLoadDBScrollEnter;
    BOOL                            _isDidLoadDBDragEnter;
    int                             _scrollToIndex;
    float                           _beforeContentSizeHeight;
    enum ACCurrentLoadStatus        _currentLoadStatus;
    
    NSTimer*                        _timerForShareLocation;
}

@end

@implementation ACChatMessageViewController


- (instancetype)initWithSuperVC:(UIViewController *)superVC withTopicEntity:(ACTopicEntity *)topicEntity andSearchSequence:(long)SearchSequence{
    self = [super init];
    if (self) {
        _superVC          = superVC;
        _topicEntity      = topicEntity;
        _searchSequence   = SearchSequence;
        long lastSequence = _topicEntity.lastestSequence;
        
        
        if(_searchSequence>=0){
            _messageVCType  =   ACMessageVCType_Search;
            if(lastSequence >(_searchSequence+4)){
                //将搜索的结果显示在屏幕中间
                lastSequence = _searchSequence+4;
            }
        }
        
        NSAssert(nil!=_dataSourceArray,@"nil!=_dataSourceArray");
# ifdef TARGET_IPHONE_SIMULATOR_Test_NewMsg_Button
        //为了测试 NewMsgFlagView
        if(_topicEntity.lastestSequence>load_new_Msg_Max_Count){
            _topicEntity.currentSequence = (_topicEntity.lastestSequence-load_new_Msg_Max_Count);
            [ACMessageDB deleteMessageFromDBWithTopicEntityID:_topicEntity.entityID];
        }
#endif
        _preloadArray = [ACMessageDB getMessageListFromDBWithTopicEntityID:_topicEntity.entityID
                                                                   lastSeq:lastSequence
                                                                 withLimit:ACMessage_loaded_Pre_Msg_Count];
//        ITLog(_preloadArray);
    }
    return self;
}


- (instancetype)initWithSuperVC:(UIViewController *)superVC  withTopicEntity:(ACTopicEntity *)topicEntity{
    return [self initWithSuperVC:superVC withTopicEntity:topicEntity andSearchSequence:-1L];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _dataSourceArray           = [[NSMutableArray alloc] init];
        _readCountMutableDic       = [[NSMutableDictionary alloc] init];
        _isFirstLoadMessage        = YES;
        _currentHeight             = kEmojiBoardHeight;
        _isDidLoadDBScrollEnter    = YES;
        _isDidLoadDBDragEnter      = YES;
//        _readCountBaseSeq          = 0;
//        _isActionSheetKeyboardHide = NO;
//        _viewDidLoad               = NO;
        _searchSequence            = -1L;
//        ITLog(self.view);
//        [self getDataSourceFromDBOrNet];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
     self.view.size = [[UIScreen mainScreen] bounds].size;
     NSLog(@"self.view.frame   ......     %@",NSStringFromCGRect(self.view.frame));
    
    self.contentView.size = CGSizeMake(self.view.size.width, self.view.size.height - 64);
     // NSLog(@"self.content.frame%@",NSStringFromCGRect(self.contentView.frame));
    // Do any additional setup after loading the view from its nib.
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

//    _viewDidLoad               = YES;
//    _mainTableView.hidden = YES;//test
    _isSearchTableCanShow      = NO;
//    _isShowHud                 = NO;
//    _isScrolling               = NO;
    _currentSeq                = _topicEntity.currentSequence;
    _lNewMsgSequence           = -1L;
    _lNewMsgSequenceFor99_Plus = -1L;

#if TARGET_IPHONE_SIMULATOR
//用于测试，更多消息
//    if(_currentSeq>200){
//        _currentSeq -= 120;
//    }
#endif

    [nc addObserver:self selector:@selector(getChatMessageNotification:) name:kNetCenterGetChatMessageNotifation object:nil];
    if (_messageVCType == ACMessageVCType_Define)
    {
        [nc addObserver:self selector:@selector(messageAddNotification:) name:kMessageAddNotification object:nil];
    }
    if(LoginState_logined!=[ACConfigs shareConfigs].loginState){
        [nc addObserver:self selector:@selector(loginSuccess:) name:kNetCenterLoginSuccRSNotifation object:nil];
    }
    [nc addObserver:self selector:@selector(sendMessageSuccessNotification:) name:kNetCenterSendMessageSuccessNotifation object:nil];
    [nc addObserver:self selector:@selector(sendMessageFailNotification:) name:kNetCenterSendMessageFailNotifation object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createGroupChatSuccess:) name:kNetCenterCreateGroupChatNotifation object:nil];
    [nc addObserver:self
           selector:@selector(videoHasFinishedPlaying:)
               name:MPMoviePlayerPlaybackDidFinishNotification
             object:nil];
    [nc addObserver:self selector:@selector(downloadMovieSuccess:) name:kNetCenterDownloadVideoSuccessNotifation object:nil];
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    //拍照使用照片输入文字取消，输入框的问题
     ///[nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    [nc addObserver:self selector:@selector(keyboardInputModeChanged:) name:UITextInputCurrentInputModeDidChangeNotification object:nil];

    [nc addObserver:self selector:@selector(sensorStateChange:) name:UIDeviceProximityStateDidChangeNotification object:nil];
    [nc addObserver:self selector:@selector(getReadCountSuccess:) name:kNetCenterGetReadCountNotifation object:nil];
    [nc addObserver:self selector:@selector(readSeqUpdate:) name:kACReadSeqUpdateNotification object:nil];
    [nc addObserver:self selector:@selector(readSeqUpdate:) name:kNetCenterGetSingleReadSeqNotifation object:nil];
//    [nc addObserver:self selector:@selector(emojiButtonScrollSetting) name:kNetCenterStickerDirJsonRecvNotifation object:nil];
//    [nc addObserver:self selector:@selector(stickerDownloadZipSucc:) name:kNetCenterStickerZipDownloadSuccNotifation object:nil];
    [nc addObserver:self selector:@selector(syncFinish:) name:kNetCenterSyncFinishNotifation object:nil];
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
    [nc addObserver:self selector:@selector(stickerDownloadSuccess:) name:kNetCenterDownloadStickerSuccessNotifation object:nil];
    [nc addObserver:self selector:@selector(topicEntityDelete:) name:kNetCenterTopicEntityDeleteNotifation object:nil];
    [nc addObserver:self selector:@selector(networkFail:) name:kNetCenterNetworkFailNotifation object:nil];
    [nc addObserver:self selector:@selector(getReadCountFail:) name:kNetCenterGetReadCountFailNotifation object:nil];
    [nc addObserver:self selector:@selector(getReadSeqFail:) name:kNetCenterGetReadSeqFailNotifation object:nil];
    [nc addObserver:self selector:@selector(suitChange:) name:kNetCenterSuitDeleteNotifation object:nil];
    [nc addObserver:self selector:@selector(suitChange:) name:kNetCenterGetSuitInfoNotifition object:nil];
    [nc addObserver:self selector:@selector(tableViewReloadData) name:kNetCenterDownloadStickerNotifation object:nil];
    [nc addObserver:self selector:@selector(suitChange:) name:kNetCenterStickerSortNotifition object:nil];
    [nc addObserver:self selector:@selector(topicInfoChange) name:kDataCenterTopicInfoChangedNotifation object:nil];
    
    [self reloadSuit];
   
    [_replyToBoardcastView setHidden:YES];
    if (_messageVCType == ACMessageVCType_Define){
        ITLogEX(@"ACChatMessageViewController(%@):entityID=%@",_topicEntity.showTitle,_topicEntity.entityID);
        //reply 答复
        if ([_topicEntity.topicPerm.featureArray count] > 0){
            for (NSString *feature in _topicEntity.topicPerm.featureArray){
                if ([feature isEqualToString:ChatFeatures_ReplyToLatestSender]){
                    [_replyToBoardcastView setHidden:NO];
                    _bIsBoardcast = YES;
                    [_mainTableView setFrame_height:_mainTableView.size.height-50];
                    break;
                }
            }
        }
    }
    
    if (![ACConfigs isPhone5]){
        [_mainTableView setFrame_height:_mainTableView.size.height-88];
        [_chatBgImageView setFrame_height:_chatBgImageView.size.height-88];
        [_chatInput setFrame_y:_chatInput.origin.y-88];
        [_replyToBoardcastView setFrame_y:_replyToBoardcastView.origin.y-88];
        [_contentView setFrame_height:_contentView.size.height-88];
    }
    
    if (_messageVCType == ACMessageVCType_Define){
        
        [nc addObserver:self selector:@selector(_sharingLocalEventNotify:) name:shareLocalNotifyForUserInfoChangeEvent object:nil];

        
        //    dispatch_async(dispatch_get_main_queue(), ^{
        [JHNotificationManager notificationRemoveMsgWithBlock:^BOOL(NSObject *userInfo) {
            if([userInfo isKindOfClass:[NSDictionary class]]){
                NSDictionary* pDict = (NSDictionary*)userInfo;
                if(nil==pDict[JHNotification_UserInfo_noteID]&&
                   [_topicEntity.entityID isEqualToString:pDict[JHNotification_UserInfo_topicID]]){
                    return YES;
                }
            }
            return NO;
        }];
        
        _unSendMsgArray = [ACMessageDB getUnSendMessageListWithTopicEntityID:_topicEntity.entityID];
        //        self.unSendMsgArray = unSendMsgList;
        //        dispatch_async(dispatch_get_main_queue(), ^{
        //            [_mainTableView reloadData];
        //            ITLog(@"-->>_mainTableView reloadData");
        [self getDataSourceFromDBOrNet]; //放在这个位置，避免加载 transmitMessage 到 _unSendMsgArray

        [self tableViewScrollToBottomWithAnimated:NO];
        //        });
        //    });
    }
    else
    {
        [self getDataSourceFromDBOrNet];

//        [_chatBgImageView showNetLoadingWithAnimated:YES];
    }
    
//#ifdef BUILD_FOR_EGA
//    _chatBgImageView.hidden = YES;
//    _contentView.backgroundColor =   UIColor_RGB(0xf3, 0xf2, 0xf7); //#f3f2f7
//#endif
    
    BOOL bReportLocation = _topicEntity.topicPerm.reportLocation == ACTopicPermission_ReportLocation_Allow;
    if (bReportLocation){
        [ACLBSCenter autoUpdatingLocation_Begin];
    }
    
    [self chatInputSetting];
    [self faceBoardSetting];
    [self addBoardSetting];
    
//    if ([_suitArray count] > 0)
    {
        [self emojiButtonScrollSetting:YES];
    }
    
    if (_topicEntity.isSigleChat){
        _readSeq = [ACReadSeqDB getReadSeqFromDBWithTopicEntityID:_topicEntity.entityID];
        [[ACNetCenter shareNetCenter] getReadSeqWithTopicEntityID:_topicEntity.entityID
                                                    singleChatUid:_topicEntity.singleChatUserID];
    }
    else{
        _isSystemChat = [_topicEntity.mpType isEqualToString:cSystemChat];
    }
    
    //语音会话 //静音状态下播放
    /* 关闭,避免进入页面会关闭别的应用的声音
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (!error)
    {
        [session setActive:YES error:nil];
    }
    else
    {
        ITLog(error);
    }
    */
    /*
    if ([_topicEntity.mpType isEqualToString:cSingleChat])
    {
        ACUser *user = [ACUserDB getUserFromDBWithUserID:_topicEntity.singleChatUserID];
        _chatTitleLabel.text = user.name;
    }
    else if([_topicEntity.relateTeID length] != 0)
    {
        ACUser *user = [ACUserDB getUserFromDBWithUserID:_topicEntity.relateChatUserID];
        _chatTitleLabel.text = user.name;

    }
    else
    {
        _chatTitleLabel.text = _topicEntity.title;
    }*/
    _chatTitleLabel.text = _topicEntity.showTitle;
    
    [_replyToBoardcastButton setBackgroundImage:[[UIImage imageNamed:@"linenote_write_btn01.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:17] forState:UIControlStateNormal];
    [_replyToBoardcastButton setBackgroundImage:[[UIImage imageNamed:@"linenote_write_btn02.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:17] forState:UIControlStateHighlighted];
    
    //用于下载使用
    [_emojiInputView addSubview:_stickerDownloadView];
    [_stickerDownloadView setHidden:YES];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignKeyBoard:)];
    [_mainTableView addGestureRecognizer:tap];
    
    UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignKeyBoard:)];
    [_tableViewShadeView addGestureRecognizer:tap1];
    
    UISwipeGestureRecognizer *swipeGes = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(resignKeyBoard:)];
    [swipeGes setDirection:UISwipeGestureRecognizerDirectionUp];
    [_tableViewShadeView addGestureRecognizer:swipeGes];
    
    UISwipeGestureRecognizer *swipeGes1 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(resignKeyBoard:)];
    [swipeGes1 setDirection:UISwipeGestureRecognizerDirectionDown];
    [_tableViewShadeView addGestureRecognizer:swipeGes1];
    
    
    if (_messageVCType == ACMessageVCType_Search){
        //开始搜索
//        [nc addObserver:self selector:@selector(searchHighLight:) name:kNetCenterSearchHighLightNotifation object:nil];
        wself_define();
        [ACNetCenter searchHighLightWithKey:_searchKey topicEntityID:_topicEntity.entityID withBlock:^(NSArray *highLightArray) {
            [wself _searchHighLightSet:highLightArray];
        }];
        
        _isCanLoadMore = YES;
        //    _mainTableView.hidden = YES;//test
 
        if(_isSearchDelete){
            _jumpinButton.hidden = YES;
            _groupInfoButton.hidden = YES;
        }
        else{
            _jumpinButton.hidden = NO;
            _groupInfoButton.hidden = YES;
        }
    }
    else
    {
        if([_superVC isKindOfClass:[ACNotesMsgVC_Main class]]){
            _jumpinButton.hidden = YES;
            _groupInfoButton.hidden = YES;
        }
        else{
            _jumpinButton.hidden = YES;
            _groupInfoButton.hidden = ACNotePermission_NOTE_ALLOW!=_topicEntity.topicPerm.note_allow;
        }
        
//        [self checkShowNewMsgFlagView];
    }
    
    //是否显示输入框
    if (_topicEntity.topicPerm.reply == ACTopicPermission_Reply_Deny ||
        _messageVCType == ACMessageVCType_Search)
    {
        [_chatInput setHidden:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
             [_mainTableView setFrame_height:_mainTableView.size.height+50];
        });
       
        
    }
    else{
        //加载草稿
        _chatInput.text = _pDraft = ACTopicEntityDB_TopicEntityDraft_load(_topicEntity);
    }
    
    NSString* pBackButtonImgName = @"arrow.png";
    
    if (_topicEntity.topicPerm.destruct == ACTopicPermission_DestructMessage_Allow){
        if (bReportLocation){
            pBackButtonImgName = @"chat_location_destruct.png";
        }
        else{
            pBackButtonImgName = @"chat_destruct.png";
        }
    }
    else if(bReportLocation){
        pBackButtonImgName = @"chat_location.png";
    }
    
    [_backButton setImage:[UIImage imageNamed:pBackButtonImgName] forState:UIControlStateNormal];
//    [_backButton setTitle:NSLocalized String(@"Back", nil) forState:UIControlStateNormal];
    [_sendButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    _stickerDownloadLabel.text = NSLocalizedString(@"Has can use sticker,to download", nil);
    [_stickerDownloadButton setTitle:NSLocalizedString(@"Download", nil) forState:UIControlStateNormal];
    [_stickerDownloadButton setBackgroundImage:[[UIImage imageNamed:@"OpBigBtn.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:12] forState:UIControlStateNormal];
    [_stickerDownloadButton setBackgroundImage:[[UIImage imageNamed:@"OpBigBtnHighlight.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:12] forState:UIControlStateHighlighted];

    [_haveNewMsgButton setTitle:@"" forState:UIControlStateNormal];
    [_haveNewMsgButton setFrame_y:_chatInput.frame.origin.y-_haveNewMsgButton.frame.size.height];
    
    ACReadCount *readCount  = [[ACReadCount alloc] init];
    readCount.readCount     = 0;
    readCount.seq           = ACMessage_seq_DEF;
    readCount.topicEntityID = _topicEntity.entityID;
    [_readCountMutableDic setObject:readCount forKey:[NSNumber numberWithLong:readCount.seq]];
    
    ///
    [self performSelector:@selector(tableViewScrollToBottomWithAnimated:) withObject:nil afterDelay:0.1];
    ///[self tableViewScrollToBottomWithAnimated:NO];
    
//    //ipad air 输入框被遮挡的问题
//    [_addSelectView setFrame_y:kScreen_Height];
//    [_emojiInputView setFrame_y:kScreen_Height];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initHotspot];
    NSLog(@"jhd   -----  ------  %@",NSStringFromCGSize(self.view.bounds.size));
    _isAppear = YES;
    if(_lNeedSendToMessageReadedSequence){
        [self sendMessageReadedToServer:_lNeedSendToMessageReadedSequence];
    }
    
    if (_messageVCType == ACMessageVCType_Define){
        [self sharingLocalTipCheck];
    }
    
 
}


- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self initHotspot];
//    self.view.size = CGSizeMake(kScreen_Width, kScreen_Height);
//     NSLog(@"jhd   -----   %@",NSStringFromCGSize(self.view.bounds.size));
    
    if (self.view.size.height>kScreen_Height) {
        [self.view setFrame_height:kScreen_Height];
    }
   
//    ITLog(([NSString stringWithFormat:@"%d",(self.view.bounds.size.height == ([ACConfigs isPhone5]?548:460))]));
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _isAppear = YES;
    [_mainTableView reloadData];
    
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    _isAppear = NO;
    if(!_chatInput.hidden){
        //保存草稿
        [self ACTopicEntityDB_TopicEntityDraft_save:_chatInput.textView.text];
    }
    [_audioPlayer stop];
}

-(void)dealloc{
    AC_MEM_Dealloc();
    if(_sharingLocalUsersInfo.count){
        [ACMapShareLocalVC exitShareLocalwithVC:self];
    }
}

-(void)tableViewScrollToBottomWithAnimated:(BOOL)animated
{
    //删除太多的信息
    @synchronized(_dataSourceArray){
        while (_dataSourceArray.count>loaded_Msg_Max_Count) {
            [_dataSourceArray removeObjectAtIndex:0];
            //需要删除阅后即焚
        }
    }

    NSInteger nCount =  _dataSourceArray.count+_unSendMsgArray.count;
    if (nCount){

        if(!_haveNewMsgButton.hidden) {
            _haveNewMsgButton.hidden = YES;
            [_haveNewMsgButton setTitle:@"" forState:UIControlStateNormal];
        }

        _nNewUnreadMsgCount =   0;
//        dispatch_async(dispatch_get_main_queue(), ^{
            ITLog(@"-->>_mainTableView reloadData");
            [_mainTableView reloadData];
//            [_mainTableView setContentOffset:CGPointMake(0, _mainTableView.contentSize.height-_mainTableView.size.height)];
       /// [_mainTableView setContentOffset:CGPointMake(0, _mainTableView.bounds.size.height) animated:YES];
            [_mainTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:nCount-1 inSection:0]
                                  atScrollPosition:UITableViewScrollPositionBottom
                                          animated:animated];
//        });
    }
    _bIsScrollTail = YES;
}

-(void)tableViewScrollToMiddleWithAnimated:(BOOL)animated
{
    if ([_dataSourceArray count]+[_unSendMsgArray count] > 0)
    {
        int row = 0;
        for (int i = 0; i < [_dataSourceArray count]; i++)
        {
            ACMessage *message = [_dataSourceArray objectAtIndex:i];
            if (message.seq == _searchSequence)
            {
                row = i;
                break;
            }
        }
//        dispatch_async(dispatch_get_main_queue(), ^{
            [_mainTableView reloadData];
            [_mainTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]
                                  atScrollPosition:UITableViewScrollPositionMiddle
                                          animated:animated];
//        });
    }
    _bIsScrollTail = [ACUtility scrollViewScrollStat:_mainTableView]&ScrollView_ScrollStat_Showed_Tail;
}


#pragma mark -loadDataSource
//-(void)preloadDB
//{
//    @synchronized(self)
//    {
//#ifdef TARGET_IPHONE_SIMULATOR_Test_NewMsg_Button
//        //为了测试 NewMsgFlagView
//        if(_topicEntity.lastestSequence>30){
//            _topicEntity.currentSequence = 12;
//            [ACMessageDB deleteMessageFromDBWithTopicEntityID:_topicEntity.entityID];
//        }
//#endif
//        long lastSequence = _topicEntity.lastestSequence;
//        if (_messageVCType == ACMessageVCType_Search)
//        {
//            if (lastSequence > _searchSequence+4)
//            {
//                lastSequence = _searchSequence+4;
//            }
//        }
//        self.preloadArray = [ACMessageDB getMessageListFromDBWithTopicEntityID:_topicEntity.entityID lastSeq:lastSequence];
//    }
//}

-(void)_waitTransmitLocalMessages{
    //等待取得位置信息结束
    [_contentView hideProgressHUDWithAnimated:YES];
    [self _checkTransmitMessages:NO]; //直接发送，不等待位置
    [self tableViewScrollToBottomWithAnimated:YES];
}

-(void)_checkTransmitMessages:(BOOL)checkLocal{
    if(0==_transmitMessages_Or_sendFilePaths.count){
        return;
    }
    if([_transmitMessages_Or_sendFilePaths[0] isKindOfClass:[ACMessage class]]){
        //看是否定位
        CLLocationCoordinate2D the_local = CLLocationCoordinate2DMake(0,0);
        if(_topicEntity.topicPerm.reportLocation == ACTopicPermission_ReportLocation_Allow &&
           [ACLBSCenter userAllowLocation]){
            the_local = [ACConfigs shareConfigs].location;
            if(checkLocal&&
               0==the_local.longitude&&
               0==the_local.latitude){
                //暂时还没有定位，等待定位成功
                [_contentView showProgressHUDWithLabelText:nil withAnimated:YES withAfterDelayHide:-1];
                [self performSelector:@selector(_waitTransmitLocalMessages) withObject:nil afterDelay:2.5];
                return;
            }
        }

        for(ACMessage* msg in _transmitMessages_Or_sendFilePaths){
            msg.messageLocation =   the_local;
            [_dataSourceArray addObject:msg];
            [[ACNetCenter shareNetCenter].chatCenter sendMessage:msg];
        }
    }
    else if([_transmitMessages_Or_sendFilePaths[0] isKindOfClass:[NSString class]]){
        //发送文件
        NSArray* pSendFiles =   _transmitMessages_Or_sendFilePaths;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            for(NSString* filePath in pSendFiles){
                if((![self sendFile:filePath.lastPathComponent withFileDataBlock:^(NSString *destFile) {
                    if(![[NSFileManager defaultManager] copyItemAtPath:filePath toPath:destFile error:nil]){
                        //拷贝失败
                        [[NSFileManager defaultManager] removeItemAtPath:destFile error:nil];
                    }
                }])&&1==pSendFiles.count){
                    dispatch_async(dispatch_get_main_queue(),^{
                        [self.view showNomalTipHUD:NSLocalizedString(@"Failed!",nil)];
                    });
                    break;
                }
                if(pSendFiles.count>1){
                    [NSThread sleepForTimeInterval:1];
                }
            }
        });
        
    }
    _transmitMessages_Or_sendFilePaths = nil;
}

//load early toSeq<0表示不做处理
-(void)getDataSourceFromDBOrNet
{
//    ITLogEX(@"load early %@",[NSThread callStackSymbols]);
    ITLog(@"load early");
    
//    _isLoadingData = YES;
    @synchronized(_dataSourceArray)
    {
//    _currentLoadStatus = ACCurrentLoadStatus_LoadEarly;
    //先从数据库读出messageList，如果数据库中读出的lastSeq跟entity标记的lastSeq相同，则不网络获取数据了，否则修改limit，获取数据
        long lastSequence = _topicEntity.lastestSequence;
        BOOL isFooterViewHidden = NO;
        if (_messageVCType == ACMessageVCType_Search){
            if (lastSequence > _searchSequence+4){
                lastSequence = _searchSequence+4;
            }
            else{
//            dispatch_sync(dispatch_get_main_queue(), ^{
                    isFooterViewHidden = YES;
                    _mainTableView.tableFooterView = nil;
                    [_activityFooterView setHidden:YES];
                    [_activityFooterView stopAnimating];
//            });
            }
        }
//    dispatch_sync(dispatch_get_main_queue(), ^{
    
        if ([_dataSourceArray count] > 0 && !_isFirstLoadMessage)
        {
            lastSequence = [(ACMessage *)[_dataSourceArray objectAtIndex:0] seq]-1;
        }
        
        //记录当前除去offset之后的height,获取数据后用contentsize减去当前height,得到offset
        _beforeContentSizeHeight = _mainTableView.contentSize.height-_mainTableView.contentOffset.y;
        
        //阅后即焚取未读的消息
        if (_topicEntity.topicPerm.destruct == ACTopicPermission_DestructMessage_Allow)
        {
            if (lastSequence != _currentSeq)
            {
                int limit = (int)(lastSequence-_currentSeq);
                if (limit > ACMessage_loaded_Pre_Msg_Count){
                    limit = ACMessage_loaded_Pre_Msg_Count;
                }
                
                _scrollToIndex = limit;//用于判断是否还有未读消息，去掉转圈
                
                [self _getChatMessageListWithOffset:lastSequence+1 withLimit:limit isLoadNew:NO];
//                [[ACNetCenter shareNetCenter] getChatMessageListWithGroupID:_topicEntity.entityID
//                                                                 withOffset:lastSequence+1
//                                                                  withLimit:limit
//                                                                  isLoadNew:NO
//                                                                  isDeleted:_topicEntity.isDeleted];
                
                if ([ASIHTTPRequest isValidNetWork])
                {
//                    dispatch_sync(dispatch_get_main_queue(), ^{
                        _mainTableView.tableHeaderView = _activityIndicatorView;
                        [_activityView setHidden:NO];
                        [_activityView startAnimating];
//                    });
                    
                }
                else
                {
//                    dispatch_sync(dispatch_get_main_queue(), ^{
                        _mainTableView.tableHeaderView = nil; //_activityIndicatorView;
                        [_activityView setHidden:YES];
                        [_contentView showProgressHUDNoActivityWithLabelText:NSLocalizedString(@"Network_Failed", nil) withAfterDelayHide:0.8];
//                    });
                }
            }
            else
            {
//                dispatch_sync(dispatch_get_main_queue(), ^{
                    _mainTableView.tableHeaderView = nil;
                    [_activityView stopAnimating];
//                });
            }
            [self _checkTransmitMessages:YES];
//            dispatch_sync(dispatch_get_main_queue(), ^{
            [_mainTableView reloadData];
//                ITLog(@"-->>_mainTableView reloadData");
//            });
        }
        //非"阅后即焚"取十条
        else
        {
            if ([ASIHTTPRequest isValidNetWork])
            {
//                dispatch_sync(dispatch_get_main_queue(), ^{
                    _mainTableView.tableHeaderView = _activityIndicatorView;
                    [_activityView setHidden:NO];
                    [_activityView startAnimating];
//                });
            }
            else
            {
//                dispatch_sync(dispatch_get_main_queue(), ^{
                    _mainTableView.tableHeaderView = nil;//_activityIndicatorView;
                    [_activityView setHidden:YES];
                    [_contentView showProgressHUDNoActivityWithLabelText:NSLocalizedString(@"Network_Failed", nil) withAfterDelayHide:0.8];
//                });
            }
            
            NSMutableArray *messageList = nil;
            if (_isFirstLoadMessage){
                messageList = _preloadArray;
            }
            else {
                messageList = [ACMessageDB getMessageListFromDBWithTopicEntityID:_topicEntity.entityID
                                                                         lastSeq:lastSequence
                                                                       withLimit:ACMessage_loaded_Pre_Msg_Count];
            }
            
            if (lastSequence < ACMessage_loaded_Pre_Msg_Count){
                _scrollToIndex = (int)lastSequence-1;
            }
            else{
                _scrollToIndex = ACMessage_loaded_Pre_Msg_Count-1;
            }
            
            //如果seq大于10，说明还有10条以上数据，messageList 数量小于10说明需要网络获取小的数据
            if ([messageList count] < ACMessage_loaded_Pre_Msg_Count && lastSequence > [messageList count])
            {
                _isNeedNetworkRequest = YES;
                [self _getChatMessageListWithOffset:lastSequence+1 withLimit:ACMessage_loaded_Pre_Msg_Count isLoadNew:NO];

//                [[ACNetCenter shareNetCenter] getChatMessageListWithGroupID:_topicEntity.entityID
//                                                                 withOffset:lastSequence+1
//                                                                  withLimit:10
//                                                                  isLoadNew:NO
//                                                                  isDeleted:_topicEntity.isDeleted];
            }
            else
            {
//                _isLoadingData = YES;
                _isNeedNetworkRequest = NO;
                if (_messageVCType == ACMessageVCType_Define)
                {
                    if (_isFirstLoadMessage && _topicEntity.currentSequence != _topicEntity.lastestSequence)
                    {
                        [self sendMessageReadedToServer:_topicEntity.lastestSequence];
//                        [ACTopicEntityEvent updateDidReadWithTopicEntity:_topicEntity];
//                        [[ACNetCenter shareNetCenter] hasBeenReadTopicEntityWithEntityID:_topicEntity.entityID withSequence:_topicEntity.lastestSequence];
                    }
                }
                else if (_messageVCType == ACMessageVCType_Search)
                {
                    if (!isFooterViewHidden)
                    {
                        _mainTableView.tableFooterView = _activityFooterIndicatorView;
                        ///
                        [_activityFooterIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
                            make.width.offset(kScreen_Width);
                        }];
                        [_activityFooterView setHidden:NO];
                        [_activityFooterView startAnimating];
                    }
                }
                
//                [[ACDataCenter shareDataCenter] addIsNeedDateShowWithArray:messageList];
                if ([_topicEntity.mpType isEqualToString:cSingleChat])
                {
                    
                }
                else
                {
                    [self getReadCountWithMessageList:messageList needSendRequest:YES];
                }
                
                [messageList addObjectsFromArray:_dataSourceArray];
//                ITLog(_dataSourceArray);
                _dataSourceArray = messageList;
//                ITLog(_dataSourceArray);
                [self _checkTransmitMessages:YES];
                [ACDataCenter checkACMessages:_dataSourceArray];
//                dispatch_sync(dispatch_get_main_queue(), ^{
                    if (lastSequence < ACMessage_loaded_Pre_Msg_Count)
                    {
                        _mainTableView.tableHeaderView = nil;
                        [_activityView stopAnimating];
                    }
                    [_mainTableView reloadData];
//                    ITLog(@"-->>_mainTableView reloadData");
                    if ([_dataSourceArray count] > 0 && _isFirstLoadMessage)
                    {
                        _isFirstLoadMessage = NO;
                        [self checkShowNewMsgFlagView];
                        
                        if (_messageVCType == ACMessageVCType_Search)
                        {
//                            if (_isSearchTableCanShow)
                            {
                                [self tableViewScrollToMiddleWithAnimated:NO];
                            }
                        }
                        else
                        {
                            [self tableViewScrollToBottomWithAnimated:NO];
                        }
                    }
                    else if([_dataSourceArray count] > ACMessage_loaded_Pre_Msg_Count)
                    {
                        [_mainTableView reloadData];
                        float offset = _mainTableView.contentSize.height-_beforeContentSizeHeight;
                        if (offset > 0)
                        {
                            [_mainTableView setContentOffset:CGPointMake(0, offset)];
                        }
                        _beforeContentSizeHeight = NSIntegerMax;
                    }
//                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.6*NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    _isDidLoadDBScrollEnter = NO;
                    _isDidLoadDBDragEnter = NO;
                });
            }
        }
        
        if (_isFirstLoadMessage)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if (_messageVCType == ACMessageVCType_Define)
                {
                    _mainTableView.hidden = NO;
                }
            });
        }
//    });
    }
}

//loadMore
-(void)getMoreFromDBOrNet
{
    @synchronized(_dataSourceArray)
    {
    //先从数据库读出messageList，如果数据库中读出的lastSeq跟entity标记的lastSeq相同，则不网络获取数据了，否则修改limit，获取数据
//    _currentLoadStatus = ACCurrentLoadStatus_LoadMore;
    __block long firstSequence = 0;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        if ([_dataSourceArray count] > 0)
        {
            firstSequence = [(ACMessage *)[_dataSourceArray lastObject] seq]+1;
            if (firstSequence > _topicEntity.lastestSequence)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _mainTableView.tableFooterView = nil;
                    [_activityFooterView setHidden:YES];
                    [_activityFooterView stopAnimating];
                });
            }
            else
            {
                NSMutableArray *messageList = [ACMessageDB getMessageListFromDBWithTopicEntityID:_topicEntity.entityID firstSeq:firstSequence limit:ACMessage_loaded_Pre_Msg_Count];
                
                //如果seq大于10，说明还有10条以上数据，messageList 数量小于10说明需要网络获取小的数据
                if ([messageList count] < ACMessage_loaded_Pre_Msg_Count && firstSequence > [messageList count])
                {
                    if ([ASIHTTPRequest isValidNetWork])
                    {
                        [self _getChatMessageListWithOffset:firstSequence+ACMessage_loaded_Pre_Msg_Count
                                                  withLimit:ACMessage_loaded_Pre_Msg_Count
                                                  isLoadNew:YES];

//                        [[ACNetCenter shareNetCenter] getChatMessageListWithGroupID:_topicEntity.entityID
//                                                                         withOffset:firstSequence+10
//                                                                          withLimit:10 isLoadNew:YES
//                                                                          isDeleted:_topicEntity.isDeleted];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            _mainTableView.tableFooterView = _activityFooterIndicatorView;
                            [_activityFooterView setHidden:NO];
                            [_activityFooterView startAnimating];
                        });
                    }
                    else
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            _mainTableView.tableFooterView = _activityFooterIndicatorView;
                            [_activityFooterView setHidden:YES];
                            [_contentView showProgressHUDNoActivityWithLabelText:NSLocalizedString(@"Network_Failed", nil) withAfterDelayHide:0.8];
                        });
                    }
                }
                else
                {
//                    [[ACDataCenter shareDataCenter] addIsNeedDateShowWithArray:messageList];
                    if ([_topicEntity.mpType isEqualToString:cSingleChat])
                    {
                        
                    }
                    else
                    {
                        [self getReadCountWithMessageList:messageList needSendRequest:YES];
                    }
//                    ITLog(_dataSourceArray);
                    [_dataSourceArray addObjectsFromArray:messageList];
                    [ACDataCenter checkACMessages:_dataSourceArray];
//                    ITLog(_dataSourceArray);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_mainTableView reloadData];
                        ITLog(@"-->>_mainTableView reloadData");
                    });
                }
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.6*NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                _isDidLoadDBScrollEnter = NO;
                _isDidLoadDBDragEnter = NO;
            });
        }
    });
    }
}

-(void)getReadCountWithMessageList:(NSMutableArray *)msgList needSendRequest:(BOOL)needSendRequest
{
    __block BOOL neenSend = needSendRequest;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *seqArray = [NSMutableArray array];
        
        long firstSeq = 0;
        @synchronized(msgList)
        {
            ACMessage *message = (ACMessage *)[msgList lastObject];
            if ([message isKindOfClass:[ACMessage class]])
            {
                firstSeq = ((ACMessage *)[msgList lastObject]).seq;
            }
            //获得seqList
            for (uint i = 0; i < [msgList count]; i++)
            {
                ACMessage *msg = [msgList objectAtIndex:i];
                if ([msg isKindOfClass:[ACMessage class]] &&
                    msg.messageEnumType!=ACMessageEnumType_System&&
                    msg.directionType == ACMessageDirectionType_Send){
                    
                    if(msg.seq<ACMessage_seq_DEF){
                        [seqArray addObject:[NSNumber numberWithLong:msg.seq]];
                    }
                    
                    if (firstSeq > msg.seq)
                    {
                        firstSeq = msg.seq;
                    }
                }
            }
        }
        
        if ([seqArray count] > 0)
        {
            //从数据库中读，如果全都有对应记录并且readCount为最新同步则直接用，否则网络获取
            NSArray *readCountArray = [ACReadCountDB getReadCountFromDBWithTopicEntityID:_topicEntity.entityID seqArray:seqArray];
            long count = 0;
            for (int i = (int)[readCountArray count]-1; i >= 0; i--)
            {
                ACReadCount *readCount = [readCountArray objectAtIndex:i];
                if (readCount.readCount > count)
                {
                    count = readCount.readCount;
                }
                else
                {
                    neenSend = YES;
                    break;
                }
            }
            
            ACReadSeq *readSeq = [ACReadSeqDB getReadSeqFromDBWithTopicEntityID:_topicEntity.entityID];
            
            if (neenSend)
            {
                [[ACNetCenter shareNetCenter] getReadCountWithSeqsArray:seqArray topicEntityID:_topicEntity.entityID];
            }
            else if (!readSeq || [readCountArray count] != [seqArray count] || readSeq.seq >= firstSeq)
            {
                [[ACNetCenter shareNetCenter] getReadCountWithSeqsArray:seqArray topicEntityID:_topicEntity.entityID];
            }
            if (readSeq.seq < firstSeq)
            {
                for (ACReadCount *readCount in readCountArray)
                {
                    [_readCountMutableDic setObject:readCount forKey:[NSNumber numberWithLong:readCount.seq]];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_mainTableView reloadData];
                    ITLog(@"-->>_mainTableView reloadData");
                });
            }
        }
    });
}

-(void)downloadMovieSuccess:(NSNotification *)notification
{
    [_mainTableView reloadData];
    ITLog(@"-->>_mainTableView reloadData");
}


#pragma mark -GroupInfo

-(IBAction)gotoGroupInfo:(id)sender
{
    [_chatInput.textView resignFirstResponder];

    ACNotesMsgVC_Main *notesVC = [[ACNotesMsgVC_Main alloc] init];
    AC_MEM_Alloc(notesVC);
    notesVC.topicEntity = _topicEntity;
    notesVC.isFromChatMessageVC = YES;
    [self.navigationController pushViewController:notesVC animated:YES];
}

-(IBAction)searchPageGotoChat:(id)sender
{
//    ACChatMessageViewController *chatMessageVC = [[ACChatMessageViewController alloc] initWithSuperVC:_searchUserChatVC withTopicEntity:_topicEntity];
    ACChatMessageViewController *chatMessageVC = [[ACChatMessageViewController alloc] initWithSuperVC:nil withTopicEntity:_topicEntity];
    AC_MEM_Alloc(chatMessageVC);
//    [chatMessageVC preloadDB];
//    chatMessageVC.topicEntity = _topicEntity;
    
    UINavigationController *navC = self.navigationController;
    [navC ACpopToRootViewControllerAnimated:NO];
    [self clearViewController];
    [navC pushViewController:chatMessageVC animated:YES];
}

#pragma mark -reloaddata
-(void)tableViewReloadData
{
    [_mainTableView reloadData];
}

#pragma mark mulSelect

#define MulSelect_Button_WH     40
#define MulSelect_BkView_H      44

-(void)_do_MulSelect_Button{
    //需要排序
    [_mulSelectMsgs sortUsingComparator:^NSComparisonResult(ACMessage* obj1, ACMessage* obj2) {
        return obj1.seq>obj2.seq?NSOrderedDescending:NSOrderedAscending;
    }];
    [self.navigationController pushViewController:[ACTransmitViewController newForTransimitMessages:_mulSelectMsgs] animated:YES];
    [self mulSelect_End];
}

-(void)mulSelect_BeginWithMsgData:(ACMessage*)pMsg{
    CGRect frame = _contentView.frame;
//    frame.origin.y  = CGRectGetMaxY(frame);
    _mulSelectMsgs = [[NSMutableArray alloc] initWithCapacity:10];
    _mulSelectToolBkView = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height-MulSelect_BkView_H, frame.size.width, MulSelect_BkView_H)];
    _mulSelectToolBkView.backgroundColor = UIColor_RGB(0xF5,0xF5,0xF5); //[UIColor whiteColor];
    _mulSelectToolBkView.alpha = 0.8;
    
    [_mulSelectMsgs addObject:pMsg];
    
//    frame = _mulSelectToolBkView.bounds;
    _buttonForTransmit = [[UIButton alloc] initWithFrame:CGRectMake((frame.size.width-MulSelect_Button_WH)/2, (MulSelect_BkView_H-MulSelect_Button_WH)/2, MulSelect_Button_WH, MulSelect_Button_WH)];
    
    [_buttonForTransmit setImage:[UIImage imageNamed:@"Transmit"] forState:UIControlStateNormal];
    
    [_buttonForTransmit addTarget:self action:@selector(_do_MulSelect_Button) forControlEvents:UIControlEventTouchUpInside];
//    _buttonForTransmit.backgroundColor = [UIColor greenColor];
    [_mulSelectToolBkView addSubview:_buttonForTransmit];
    
    [_contentView addSubview:_mulSelectToolBkView];
    [_backButton setImage:nil forState:UIControlStateNormal];
    [_backButton setTitle:@"Cancel" forState:UIControlStateNormal];
    
    CGFloat fTableViewH = 0;
    if(ACMessageVCType_Define==_messageVCType){
        
        if(_bIsBoardcast){
            _replyToBoardcastView.hidden = YES;
            
        }
        else{
            _chatInput.hidden = YES;
        }
        _groupInfoButton.hidden = YES;
        fTableViewH = frame.size.height-MulSelect_BkView_H;
    }
    else{
        fTableViewH = _mainTableView.frame.size.height-_mulSelectToolBkView.frame.size.height;
        _jumpinButton.hidden = YES;
    }
    [_mainTableView setFrame_height:fTableViewH];
    [_mainTableView reloadData];
//不适用    self.navigationController.toolbarHidden = NO;
}

-(void)mulSelect_End{
    //恢复旧的状态
    [_backButton setImage:[UIImage imageNamed:@"arrow"] forState:UIControlStateNormal];
    [_backButton setTitle:@"" forState:UIControlStateNormal];
    
    CGFloat fTableViewH = 0;
    if(ACMessageVCType_Define==_messageVCType){
        
        _groupInfoButton.hidden = NO;
        
        if(_bIsBoardcast){
            _replyToBoardcastView.hidden = NO;
            fTableViewH = _contentView.frame.size.height-_replyToBoardcastView.size.height;
        }
        else if(_topicEntity.topicPerm.reply != ACTopicPermission_Reply_Deny){
            _chatInput.hidden = NO;
            fTableViewH = _contentView.frame.size.height-_chatInput.size.height;
        }
        else{
            ///broadcast右上角笔记图标出现问题
            _groupInfoButton.hidden = YES;
            fTableViewH =   _contentView.frame.size.height;
        }
    }
    else{
        fTableViewH = _mainTableView.frame.size.height+_mulSelectToolBkView.frame.size.height;
        if(!_isSearchDelete){
            _jumpinButton.hidden = NO;
        }
    }
    
    [_mainTableView setFrame_height:fTableViewH];

    [_mulSelectToolBkView removeFromSuperview];
    _mulSelectToolBkView = nil;
    _buttonForTransmit = nil;
    _mulSelectMsgs = nil;
    [_mainTableView reloadData];
}

-(BOOL)isMulSelect{
    return _mulSelectToolBkView!=nil;
}

-(BOOL)mulSelectedMsg:(ACMessage*)pMsg forTap:(BOOL)bForTap{
    BOOL bIsSelected = [_mulSelectMsgs containsObject:pMsg];
    if(bForTap){
        if(bIsSelected){
            [_mulSelectMsgs removeObject:pMsg];
        }
        else{
            [_mulSelectMsgs addObject:pMsg];
        }
        bIsSelected = !bIsSelected;
        _buttonForTransmit.enabled =    _mulSelectMsgs.count>0;
    }
    return bIsSelected;
}

#pragma mark -Notification

- (void)topicInfoChange{
    //[nc addObserver:self selector:@selector(topicInfoChange) name:kDataCenterTopicInfoChangedNotifation object:nil];
    //[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _chatTitleLabel.text = _topicEntity.title;
}

-(void)networkFail:(NSNotification *)noti
{
    _mainTableView.tableFooterView = nil;
    [_activityFooterView setHidden:YES];
    [_activityFooterView stopAnimating];
    
    if (_isAppear)
    {
//        [_activityView setHidden:YES];
//        [_activityFooterView setHidden:YES];
        [_contentView showProgressHUDNoActivityWithLabelText:NSLocalizedString(@"Network_Failed", nil) withAfterDelayHide:0.8];
        
//        if (!_isShowHud)
//        {
//            _isShowHud = YES;
//            [_contentView showProgressHUDNoActivityWithLabelText:NSLocalizedString(@"Network_Failed", nil) withAfterDelayHide:0.8];
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                _isShowHud = NO;
//            });
//        }
    }
}

-(void)getReadCountFail:(NSNotification *)noti
{
    ITLog(@"");
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *readCountArray = noti.object;
        for (ACReadCount *readCount in readCountArray)
        {
            if (readCount.topicEntityID != _topicEntity.entityID)
            {
                return;
            }
//            ACReadCount *readCountTmp = [_readCountMutableDic objectForKey:[NSNumber numberWithLong:readCount.seq]];
//            if (!readCountTmp || readCountTmp.readCount == -1)
            {
                [_readCountMutableDic setObject:readCount forKey:[NSNumber numberWithLong:readCount.seq]];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
//            ITLog(@"-->>_mainTableView reloadData");
            
            [_mainTableView reloadData];
        });
    });
}

-(void)getReadSeqFail:(NSNotification *)noti
{
//    ACReadSeq *seq = noti.object;
//    if ([seq.topicEntityID isEqualToString:_topicEntity.entityID])
//    {
//        if ([_topicEntity.mpType isEqualToString:cSingleChat])
//        {
//            self.readSeq = seq;
//            ITLog(@"-->>_mainTableView reloadData");
//            if (!_isAppear)
//            {
//                return;
//            }
//            [_mainTableView reloadData];
//        }
//        else
//        {
//            [self getReadCountWithMessageList:_dataSourceArray needSendRequest:NO];
//        }
//    }
}

-(void)topicEntityDelete:(NSNotification *)noti
{
    NSString *teid = noti.object;
    if ([teid isEqualToString:_topicEntity.entityID] && _messageVCType == ACMessageVCType_Define)
    {
        [_contentView showProgressHUDNoActivityWithLabelText:NSLocalizedString(@"Chat room have been closed", nil) withAfterDelayHide:1.2];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController ACpopViewControllerAnimated:YES];
            [self clearViewController];
        });
    }
}


-(void)_searchHighLightSet:(NSArray *)highLightArray{
    if (highLightArray){
        self.highLightArray = highLightArray;
        [_mainTableView reloadData];
    }
    if (!_isNeedNetworkRequest || (_isNeedNetworkRequest && _isSearchTableCanShow)){
        if (_isNeedNetworkRequest){
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [_contentView hideProgressHUDWithAnimated:NO];
                _mainTableView.hidden = NO;
            });
        }
        else{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [_contentView hideProgressHUDWithAnimated:NO];
                _mainTableView.hidden = NO;
            });
        }
    }
    _isSearchTableCanShow = YES;
}


-(void)hotspotStateChange:(NSNotification *)noti
{
    if (_isOpenHotspot)
    {
        [_mainTableView setFrame_height:_mainTableView.size.height-hotsoptHeight];
        [_chatInput setFrame_y:_chatInput.origin.y-hotsoptHeight];
        [_tableViewShadeView setFrame_height:_tableViewShadeView.size.height-hotsoptHeight];
        [_contentView setFrame_height:_contentView.size.height-hotsoptHeight];
    }
    else
    {
        [_mainTableView setFrame_height:_mainTableView.size.height+hotsoptHeight];
        [_chatInput setFrame_y:_chatInput.origin.y+hotsoptHeight];
        [_tableViewShadeView setFrame_height:_tableViewShadeView.size.height+hotsoptHeight];
        [_contentView setFrame_height:_contentView.size.height+hotsoptHeight];
    }
}

-(void)syncFinish:(NSNotification *)noti
{

    long lastSeq = _topicEntity.lastestSequence;
    long currentSeq = _currentSeq;
    
    if(_dataSourceArray.count){
        currentSeq = ((ACMessage *)[_dataSourceArray lastObject]).seq;
    
        //防止中间丢消息，做补全逻辑
        for (int i = 1; i < [_dataSourceArray count]; i++)
        {
            ACMessage *prevMessage = [_dataSourceArray objectAtIndex:i-1];
            ACMessage *message = [_dataSourceArray objectAtIndex:i];
            if (prevMessage.seq+1 != message.seq)
            {
                currentSeq = prevMessage.seq;
                break;
            }
        }
    }
#ifdef ACUtility_Need_Log
    NSString* pSyncFinishStat = lastSeq != currentSeq?@"需要数据补全,":@"";
    NSString* pSyncRun = @"";
#endif
    if (lastSeq != currentSeq && [ACNetCenter shareNetCenter].backgrounLoopInquireClose)
    {
        [self _getChatMessageListWithOffset:lastSeq+1 withLimit:(int)(lastSeq-currentSeq) isLoadNew:YES];

//        [[ACNetCenter shareNetCenter] getChatMessageListWithGroupID:_topicEntity.entityID
//                                                         withOffset:lastSeq+1
//                                                          withLimit:(int)(lastSeq-currentSeq)
//                                                          isLoadNew:YES
//                                                          isDeleted:_topicEntity.isDeleted];
#ifdef ACUtility_Need_Log
        pSyncRun    =   @"直接读取!";
#endif
    }
    else
    {
        [self getReadSeqOrReadCount];
#ifdef ACUtility_Need_Log
        pSyncRun    =   @"运行getReadSeqOrReadCount!";
#endif
    }
#ifdef ACUtility_Need_Log
    ITLogEX(@"ACFile_Type_SyncData,%@%@",pSyncFinishStat,pSyncRun);
#endif
}

-(ACReadCount*)getReadCountWithSeq:(long)seq{
    return _readCountMutableDic[@(seq)];
}

-(BOOL)isUnSendMsg:(ACMessage*)pMsg{
    return [_unSendMsgArray containsObject:pMsg];
}

-(void)getReadSeqOrReadCount
{
    if ([_topicEntity.mpType isEqualToString:cSingleChat])
    {
        [[ACNetCenter shareNetCenter] getReadSeqWithTopicEntityID:_topicEntity.entityID
                                                    singleChatUid:_topicEntity.singleChatUserID];
    }
    else
    {
        [self getReadCountWithMessageList:_dataSourceArray needSendRequest:YES];
    }
}

//-(void)stickerDownloadZipSucc:(NSNotification *)noti
//{
//    if (!_isAppear)
//    {
//        return;
//    }
//    NSString *title = noti.object;
//    if ([title isEqualToString:_currentPackage.title])
//    {
//        [self stickerSettingWithStickerPackage:_currentPackage];
//    }
//}

-(void)readSeqUpdate:(NSNotification *)noti
{
    ACReadSeq *seq = noti.object;
    if ([seq.topicEntityID isEqualToString:_topicEntity.entityID]){
        _readSeq = seq;
        if ([_topicEntity.mpType isEqualToString:cSingleChat]){
            ITLog(@"-->>_mainTableView reloadData");
            [_mainTableView reloadData];
        }
        else{
            [self getReadCountWithMessageList:_dataSourceArray needSendRequest:NO];
        }
    }
}

-(void)getReadCountSuccess:(NSNotification *)noti
{
    NSLog(@"");
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *readCountArray = noti.object;
        for (ACReadCount *readCount in readCountArray)
        {
            if (readCount.topicEntityID != _topicEntity.entityID)
            {
                ITLogEX(@"readCount.topicEntityID(%@) != _topicEntity.entityID(%@)",readCount.topicEntityID,_topicEntity.entityID);
                return;
            }
            [_readCountMutableDic setObject:readCount forKey:[NSNumber numberWithLong:readCount.seq]];
        }
//        _readCountBaseSeq = 0;
        dispatch_async(dispatch_get_main_queue(), ^{
            ITLog(@"-->>_mainTableView reloadData");
            
            [_mainTableView reloadData];
        });
    });
}

-(void)loginSuccess:(NSNotification *)noif{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNetCenterLoginSuccRSNotifation object:nil];
    [self _reloadUngetMsgFromNet];
}

-(void)getChatMessageNotification:(NSNotification *)notification
{
   
    @synchronized(self)
    {
        if(nil==notification.object){
            ITLogEX(@"GetMsg Failed %d",_nNowLoadMsgLimit);
            [self _reloadUngetMsgFromNet];
            return;
        }
        
        _nNowLoadMsgLimit   =   0;
        @synchronized(_dataSourceArray)
        {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSDictionary *dic = notification.object;
            NSMutableArray *topicArrayM = [dic objectForKey:kMsgList];
            BOOL isLoadNew = [[dic objectForKey:kIsLoadNew] boolValue];
            
            ACMessage *msg = [topicArrayM lastObject];
            if (![msg.topicEntityID isEqualToString:_topicEntity.entityID]){
                ITLogEX(@"topicEntityID:%@ != msgEntityID:%@",_topicEntity.entityID,msg.topicEntityID);
                return;
            }
            
            ITLogEX(@"....... scrollToIndex = %d,count=%ld",_scrollToIndex,(long)_dataSourceArray.count);
            __block BOOL tableFooterHidden = NO;
            NSArray* topicArray = [NSArray arrayWithArray:topicArrayM];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_messageVCType == ACMessageVCType_Define)
                {
                    if (_scrollToIndex < ACMessage_loaded_Pre_Msg_Count-1)
                    {
                        _mainTableView.tableHeaderView = nil;
                        [_activityView stopAnimating];
                    }
//                        _activityView.hidden = YES;
                }
                else if (_messageVCType == ACMessageVCType_Search)
                {
                    if (!isLoadNew)
                    {
                        if ([topicArray count] < ACMessage_loaded_Pre_Msg_Count)
                        {
                            tableFooterHidden = YES;
                            _mainTableView.tableHeaderView = nil;
                            [_activityView stopAnimating];
                            _mainTableView.tableFooterView = nil;
                            [_activityFooterView stopAnimating];
                        }
                        else
                        {
                            ACMessage *message = [topicArray objectAtIndex:0];
                            if (message.seq == 0)
                            {
                                _mainTableView.tableHeaderView = nil;
                                [_activityView stopAnimating];
                            }
                            message = [topicArray lastObject];
                            if (message.seq == _topicEntity.lastestSequence)
                            {
                                tableFooterHidden = YES;
                                _mainTableView.tableFooterView = nil;
                                [_activityFooterView stopAnimating];
                            }
                        }
                    }
                    else
                    {
                        if ([topicArray count] < ACMessage_loaded_Pre_Msg_Count)
                        {
                            tableFooterHidden = YES;
                            _mainTableView.tableFooterView = nil;
                            [_activityFooterView stopAnimating];
                        }
                    }
                }
                
                [_mainTableView reloadData];
            });
/*            if ([_dataSourceArray count] > 0)
            {
                ACMessage *firstMsg = [_dataSourceArray objectAtIndex:0];
                ACMessage *lastMsg = [_dataSourceArray lastObject];
                
                if (lastMsg.seq - firstMsg.seq != [_dataSourceArray count])
                {
                    //防止中间丢消息，做补全逻辑
                    for (int i = 1; i < [_dataSourceArray count]; i++)
                    {
                        ACMessage *prevMessage = [_dataSourceArray objectAtIndex:i-1];
                        ACMessage *message = [_dataSourceArray objectAtIndex:i];
                        long preSeq = prevMessage.seq,seq = message.seq;
                        while (preSeq+1 != seq && preSeq < seq)
                        {
                            preSeq++;
                            for (int j = (int)[topicArray count]-1; j >= (int)0; j--)
                            {
                                ACMessage *msg = [topicArray objectAtIndex:j];
                                if (msg.seq == preSeq)
                                {
                                    [_dataSourceArray insertObject:msg atIndex:i];
                                    break;
                                }
                            }
                        }
                    }
                }
                for (int i = (int)[topicArray count]-1; i >= 0; i--)
                {
                    ACMessage *msg = [topicArray objectAtIndex:i];
                    if (msg.seq >= firstMsg.seq && msg.seq <= lastMsg.seq)
                    {
                        [topicArray removeObject:msg];
                    }
                }
                if ([topicArray count] == 0)
                {
                    [_mainTableView reloadData];
                    return ;
                }
            }
            
            //新来消息先排一下序，然后加入原有消息赋值给dataSourceArray

            if ([_topicEntity.mpType isEqualToString:cSingleChat])
            {
                
            }
            else
            {
                [self getReadCountWithMessageList:topicArray needSendRequest:NO];
            }
            if (isLoadNew)
            {
//                    ITLog(_dataSourceArray);
                [_dataSourceArray addObjectsFromArray:topicArray];
//                    ITLog(_dataSourceArray);
            }
            else
            {
//                    [[ACDataCenter shareDataCenter] addIsNeedDateShowWithArray:topicArray];
                [topicArray addObjectsFromArray:_dataSourceArray];
//                    ITLog(_dataSourceArray);
                self.dataSourceArray = topicArray;

//                    ITLog(_dataSourceArray);
            }
            */

            if(_dataSourceArray.count&&![_topicEntity.mpType isEqualToString:cSingleChat]){
                //检查是否调用 getReadCountWithMessageList
                ACMessage *firstMsg = [_dataSourceArray objectAtIndex:0];
                ACMessage *lastMsg = [_dataSourceArray lastObject];
                [_dataSourceArray addObjectsFromArray:topicArrayM];

                for (int i = (int)[topicArrayM count]-1; i >= 0; i--){
                    ACMessage *msg = [topicArrayM objectAtIndex:i];
                    if (msg.seq >= firstMsg.seq && msg.seq <= lastMsg.seq){
                        [topicArrayM removeObject:msg];
                    }
                }

                if(topicArrayM.count){
                    [self getReadCountWithMessageList:topicArrayM needSendRequest:NO];
                }
            }
            else {
                [_dataSourceArray addObjectsFromArray:topicArrayM];
            }

            [self _checkTransmitMessages:YES];

            [ACDataCenter checkACMessages:_dataSourceArray];

            dispatch_async(dispatch_get_main_queue(), ^{
                
                ITLogEX(@"-->>_mainTableView reloadData count=%ld",_dataSourceArray.count);
                if (_isFirstLoadMessage)
                {
                    [self checkShowNewMsgFlagView];
                    if ([_dataSourceArray count] > 0 && _messageVCType == ACMessageVCType_Define)
                    {
                        [self sendMessageReadedToServer:_topicEntity.lastestSequence];
//                            [ACTopicEntityEvent updateDidReadWithTopicEntity:_topicEntity];
//                            [[ACNetCenter shareNetCenter] hasBeenReadTopicEntityWithEntityID:_topicEntity.entityID withSequence:_topicEntity.lastestSequence];
                        [self tableViewScrollToBottomWithAnimated:NO];
                        
                    }
                    if (_messageVCType == ACMessageVCType_Search)
                    {
                        if (!tableFooterHidden)
                        {
                            _mainTableView.tableFooterView = _activityFooterIndicatorView;
                            [_activityFooterView setHidden:NO];
                            [_activityFooterView startAnimating];
                        }
                        
                        if (_isSearchTableCanShow)
                        {
//                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                [_contentView hideProgressHUDWithAnimated:NO];
                                _mainTableView.hidden = NO;
                                [_mainTableView reloadData];
                                [self tableViewScrollToMiddleWithAnimated:NO];
//                                });
                            
                        }
                        _isSearchTableCanShow = YES;
                    }
                    
                    _isFirstLoadMessage = NO;
                }
                else if (isLoadNew)
                {
                    if (_messageVCType == ACMessageVCType_Define)
                    {
                        [self getReadSeqOrReadCount];
                        [self sendMessageReadedToServer:_topicEntity.lastestSequence];
                        
//                            [ACTopicEntityEvent updateDidReadWithTopicEntity:_topicEntity];
//                            [[ACNetCenter shareNetCenter] hasBeenReadTopicEntityWithEntityID:_topicEntity.entityID withSequence:_topicEntity.lastestSequence];
                        [self tableViewScrollToBottomWithAnimated:NO];
                    }
                    else if (_messageVCType == ACMessageVCType_Search)
                    {
                        
                    }
                }
                else if(_bForNewMsgCountViewTap){
                    //寻找未知
                    NSInteger nItemNo = 0;
                    for(NSInteger nNo=0;nNo<_dataSourceArray.count;nNo++){
                        ACMessage* pMsgTemp =   _dataSourceArray[nNo];
                        if(pMsgTemp.seq==_lNewMsgSequence){
                            nItemNo = nNo;
                            break;
                        }
                    }
                    //强制关闭动画
                    [_activityView stopAnimating];
                    if(0==((ACMessage*)_dataSourceArray[0]).seq){
                        _mainTableView.tableHeaderView = nil;
                    }

                    [_mainTableView reloadData];

                    if(0==nItemNo&&_mainTableView.tableHeaderView){
                        //隐藏一下 tableHeaderView
                        _mainTableView.contentOffset = CGPointMake(0,_mainTableView.tableHeaderView.frame.size.height);
                    }
                    else {
                        [_mainTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:nItemNo inSection:0]
                                              atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                    }
                }
                else if([_dataSourceArray count] > ACMessage_loaded_Pre_Msg_Count)
                {
                    [_mainTableView reloadData];
                    //ACCurrentLoadStatus_LoadEarly时，不要滚动
                    //_beforeContentSizeHeight 在之前计算了
                    NSAssert(ACCurrentLoadStatus_LoadEarly==_currentLoadStatus,@"ACCurrentLoadStatus_LoadEarly==_currentLoadStatus");
                    float offset = _mainTableView.contentSize.height-_beforeContentSizeHeight;
                    if (offset > 0)
                    {
                        [_mainTableView setContentOffset:CGPointMake(0, offset)];
                    }
                    _beforeContentSizeHeight = NSIntegerMax; //避免乱跑
                }
                else
                {
                    [_mainTableView reloadData];
                }
                
                _bForNewMsgCountViewTap = NO;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.6*NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    _isDidLoadDBScrollEnter = NO;
                    _isDidLoadDBDragEnter = NO;
                });
            });
        });
        }
    }
}

//-(void)updateLastMessageToEntity
//{
//    //第一次网络获取修改topicEntity最后一条消息，更新未读数
//    ACMessage *msgTmp = nil;
//    for (int i = (int)[_dataSourceArray count]-1; i>0; i--)
//    {
//        msgTmp = [_dataSourceArray objectAtIndex:i];
//        if (msgTmp.seq != ACMessage_seq_DEF)
//        {
//            break;
//        }
//    }
//    if (msgTmp)
//    {
//        [ACMessageEvent updateTopicEntityHadReadWithMessage:msgTmp];
//        [[ACNetCenter shareNetCenter] hasBeenReadTopicEntityWithEntityID:_topicEntity.entityID withSequence:msgTmp.seq];
//    }
//}

-(void)messageAddNotification:(NSNotification *)notification
{
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        ACMessage *message = notification.object;
        if(![message.topicEntityID isEqualToString:_topicEntity.entityID]){
            ITLogEX(@"topicEntityID:%@ != msgEntityID:%@",_topicEntity.entityID,message.topicEntityID);
            return;
        }
        
        BOOL bNewMsgButtonHidden =  _haveNewMsgButton.hidden;

//        ITLog(_dataSourceArray);
        ITLogEX(@"新消息:%@",message);

//            [[ACDataCenter shareDataCenter] addIsNeedDateShowWithArray:_dataSourceArray];
        @synchronized(_dataSourceArray){
            
            if(bNewMsgButtonHidden&&(!_bIsScrollTail)
//               0==([ACUtility scrollViewScrollStat:_mainTableView]&ScrollView_ScrollStat_Showed_Tail)
               ){
                //不在底部,显示按钮
                bNewMsgButtonHidden = NO;
                [_haveNewMsgButton setTitle:@"" forState:UIControlStateNormal];
                [_haveNewMsgButton setFrame_y:_chatInput.frame.origin.y-_haveNewMsgButton.frame.size.height];
//                ///
                [ _haveNewMsgButton setFrame_x:kScreen_Width - _haveNewMsgButton.frame.size.width];
//                [_haveNewMsgButton mas_makeConstraints:^(MASConstraintMaker *make) {
//                    make.top.offset(kScreen_Height - 64-46);
//                }];
            }
            
            [ACDataCenter addACMessage:message toMessages:_dataSourceArray];
        }
        _nNewUnreadMsgCount ++;


        if(bNewMsgButtonHidden){
            [self tableViewScrollToBottomWithAnimated:YES];
        }
        else{
            NSString* pTitle = @"99+";
            if(_nNewUnreadMsgCount<100){
                pTitle = [NSString stringWithFormat:@"%ld",_nNewUnreadMsgCount];
            }
            [_haveNewMsgButton setTitle:pTitle forState:UIControlStateNormal];
            [_mainTableView reloadData];
            _haveNewMsgButton.hidden = bNewMsgButtonHidden;
        }
    
//        NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:kUserID];
        if ([ACUser isMySelf:message.sendUserID])
        {
            [self setSendReadCountWithMessage:message];
        }
        
        
        //        dispatch_async(dispatch_get_main_queue(), ^{
        //更新为已读
        [self sendMessageReadedToServer:message.seq];

            //            [ACTopicEntityEvent updateDidReadWithTopicEntity:_topicEntity];
            //            [[ACNetCenter shareNetCenter] hasBeenReadTopicEntityWithEntityID:_topicEntity.entityID withSequence:message.seq];

//            [_mainTableView reloadData];
//            ITLog(@"-->>_mainTableView reloadData");
//            [self tableViewScrollToBottomWithAnimated:YES];
//        });
//    });
}


-(void)sensorStateChange:(NSNotificationCenter *)notification;
{
    [_audioPlayer stop];
    [_audioPlayer play];
    if([ACVideoCall inVideoCall]){
        return;
    }
    
    //如果此时手机靠近面部放在耳朵旁，那么声音将通过听筒输出，并将屏幕变暗（省电啊）
    if ([[UIDevice currentDevice] proximityState] == YES)
    {
        NSLog(@"Device is close to user");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
    }
    else
    {
        NSLog(@"Device is not close to user");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
}

//-(void)sortChatMessageWithArray:(NSMutableArray *)array
//{
//    [array sortUsingComparator:^NSComparisonResult(ACMessage *msg1,ACMessage *msg2) {
//        if (msg1.seq > msg2.seq)
//        {
//            return (NSComparisonResult)NSOrderedDescending;
//        }
//        if (msg1.seq < msg2.seq)
//        {
//            return (NSComparisonResult)NSOrderedAscending;
//        }
//        return (NSComparisonResult)NSOrderedSame;
//    }];
//}

//#pragma mark -kvo
//-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
//{
//    if (object == _currentPackage && [keyPath isEqualToString:kProgress])
//    {
//        _stickerDownloadProgressView.progress = _currentPackage.progress;
//    }
//}


#pragma mark -actionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == kActionSheetTag_MsgOpt)
    {
//        _isActionSheetKeyboardHide = YES;
        ACChatMessageTableViewCell* pNowCell =  _actionSheetCell;
        _actionSheetCell = nil;
        
        NSInteger index = buttonIndex - actionSheet.firstOtherButtonIndex;
        if (index < [_otherButtonTitles count]){
            NSString *title = [_otherButtonTitles objectAtIndex:index];
            if ([title isEqualToString:kMsgOpt_Transmit]){//转发消息
                [self mulSelect_BeginWithMsgData:pNowCell.messageData];
            }
            else if ([title isEqualToString:kMsgOpt_Copy]){
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                [pasteboard setString:pNowCell.messageData.content];
            }
            else if ([title isEqualToString:kMsgOpt_PrivateChat]){
                [self createSingleChatWithUserID:pNowCell.messageData.sendUserID];
            }
            else if ([title isEqualToString:kMsgOpt_ShowLocation]){
                ACMapBrowerViewController *mapBrowserVC = [[ACMapBrowerViewController alloc] init];
                mapBrowserVC.coordinate = pNowCell.messageData.messageLocation;
                [self ACpresentViewController:mapBrowserVC animated:YES completion:nil];
            }
            else if ([title isEqualToString:kMsgOpt_HadReadList]){
                [self showWhoReadVCWithMsg:pNowCell.messageData];
            }
            else if(pNowCell.messageData.messageEnumType ==ACMessageEnumType_Video&&
                    ([title isEqualToString:kMsgOpt_SaveToAblum]||[title isEqualToString:kMsgOpt_Download])){
                [pNowCell videoMsgOptionForSave];
            }
        }
        return;
    }
    
    if (actionSheet.tag == kActionSheetTag_Resend)
    {
        if (buttonIndex == actionSheet.destructiveButtonIndex){
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [_unSendMsgArray removeObject:_resendMessage];
                [ACMessageDB deleteMessageFromDBWithMessageID:_resendMessage.messageID];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_mainTableView reloadData];
                });
            });
        }
        else if (buttonIndex == actionSheet.firstOtherButtonIndex){
            if (_resendMessage.messageUploadState == ACMessageUploadState_UploadFailed){
                _resendMessage.messageUploadState = ACMessageUploadState_Uploading;
                [[ACNetCenter shareNetCenter].chatCenter sendMessage:_resendMessage];
            }
            else if(ACMessageUploadState_TransmitFailed==_resendMessage.messageUploadState){
                _resendMessage.messageUploadState = ACMessageUploadState_Transmiting;
                [[ACNetCenter shareNetCenter].chatCenter sendMessage:_resendMessage];
            }
            
            [_mainTableView reloadData];
        }
        return;
    }
    
    if(kActionSheetTag_Location==actionSheet.tag){
        if(buttonIndex!=actionSheet.cancelButtonIndex){
            [self resignKeyBoard:nil];
            if(buttonIndex==actionSheet.firstOtherButtonIndex){
                
                //Send Location
                ACMapViewController* sendLocationVC =  [[ACMapViewController alloc] initWithSuperVC:self];
                [self ACpresentViewController:sendLocationVC animated:YES completion:nil];
            }
            else{
                //如果有发送语音功能，则在VideoCall最小化后提示错误
                //Real-tim Location
                [self _sharingLocalJoin];
            }
        }
        return;
    }
}


#pragma mark -tableViewDelegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACChatMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACChatMessageTableViewCell"];
    if (!cell){
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACChatMessageTableViewCell" owner:nil options:nil];
        cell = [nib objectAtIndex:0];
    }
    if (indexPath.row < [_dataSourceArray count]){
        [cell setMessage:[_dataSourceArray objectAtIndex:indexPath.row] superVC:self];
    }
    else{
        NSInteger row = indexPath.row - [_dataSourceArray count];
        if (row < [_unSendMsgArray count]){
            [cell setMessage:[_unSendMsgArray objectAtIndex:row] superVC:self];
        }
    }
    
//    if (cell.messageData.messageEnumType == ACMessageEnumType_Sticker){
//        if (tableView.dragging == NO && tableView.decelerating == NO)
//        {
//            [cell stickerStartGif];
//        }
//    }
    return cell;
}

//-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
//    if(!_haveNewMsgButton.hidden&&indexPath.row < [_dataSourceArray count]){
//        ACMessage* pMsg = _dataSourceArray[indexPath.row];
//    }
//}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    if (!_isSearchTableCanShow && _messageVCType == ACMessageVCType_Search)
//    {
//        return 0;
//    }
//    else
    {
        return [_dataSourceArray count]+[_unSendMsgArray count];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    float height = 0;
    ACMessage *pMsg = nil;
    if (indexPath.row < [_dataSourceArray count]){
        pMsg = _dataSourceArray[indexPath.row];
    }
    else{
        NSInteger row = indexPath.row - [_dataSourceArray count];
        if (row < [_unSendMsgArray count]){
            pMsg = _unSendMsgArray[row];
        }
    }

    if(pMsg){
        height = [ACChatMessageTableViewCell getCellHeightWithMessage:pMsg
                                                        withNewMsgSeq:_lNewMsgSequence
                                              withNewMsgSeqFor99_Plus:_lNewMsgSequenceFor99_Plus];
    }
    
    return height;
}


#pragma mark -emojiAndAdd
-(IBAction)emojiPageChange:(id)sender
{
    NSInteger index = _emojiPageC.currentPage;
    ///[_emojiScrollView setContentOffset:CGPointMake(320*index, 0)];
    [_emojiScrollView setContentOffset:CGPointMake(kScreen_Width*index, 0)];
}

-(IBAction)addPageChange:(id)sender
{
    NSInteger index = _addPageC.currentPage;
    ///[_addScrollView setContentOffset:CGPointMake(320*index, 0)];
    [_addScrollView setContentOffset:CGPointMake(kScreen_Width*index, 0)];
}

#pragma mark -scrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
//    if (!decelerate)
//    {
//        [self continueAllGif];
//        _isScrolling = NO;
//        [[NSNotificationCenter defaultCenter] postNotificationName:kStopDecelerateNotification object:nil];
//    }
    if (decelerate){
        return;
    }
    if (scrollView == _mainTableView){
        if (_isDidLoadDBScrollEnter && !_isDidLoadDBDragEnter){
            _isDidLoadDBDragEnter = YES;
            if (_currentLoadStatus == ACCurrentLoadStatus_LoadEarly){
                [self getDataSourceFromDBOrNet];
            }
            else if (_currentLoadStatus == ACCurrentLoadStatus_LoadMore){
                [self getMoreFromDBOrNet];
            }
        }
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
//    [self continueAllGif];
//    _isScrolling = NO;
//    [[NSNotificationCenter defaultCenter] postNotificationName:kStopDecelerateNotification object:nil];
    if (scrollView == _emojiScrollView){
        ///
        NSInteger index = _emojiScrollView.contentOffset.x/kScreen_Width;
        [_emojiPageC setCurrentPage:index];
        return;
    }
    
    if (scrollView == _addScrollView){
        ///ƒ
        NSInteger index = _addScrollView.contentOffset.x/kScreen_Width;
        [_addPageC setCurrentPage:index];
        return;
    }
    
    if (scrollView == _mainTableView){
        if (_isDidLoadDBScrollEnter && !_isDidLoadDBDragEnter){
            _isDidLoadDBDragEnter = YES;
            if (_currentLoadStatus == ACCurrentLoadStatus_LoadEarly){
                [self getDataSourceFromDBOrNet];
            }
            else if (_currentLoadStatus == ACCurrentLoadStatus_LoadMore){
                [self getMoreFromDBOrNet];
            }
        }
        else if(ACMessageVCType_Define==_messageVCType&&
                _dataSourceArray.count&&
                _bIsScrollTail
//                ([ACUtility scrollViewScrollStat:_mainTableView]&ScrollView_ScrollStat_Showed_Tail)
                ){
            
            ACMessage* pLastMsg =   ((ACMessage*)_dataSourceArray.lastObject);
            if((pLastMsg.messageUploadState==ACMessageUploadState_None||
               pLastMsg.messageUploadState==ACMessageUploadState_Uploaded)&&
               _topicEntity.lastestSequence<pLastMsg.seq){
                ITLog(@"重新加载没有从数据库加载的数据.lastestSequence<pLastMsg.seq");
                @synchronized(_dataSourceArray){
                    _dataSourceArray = [ACMessageDB getMessageListFromDBWithTopicEntityID:_topicEntity.entityID
                                                                                 firstSeq:((ACMessage*)_dataSourceArray[0]).seq
                                                                                    limit:0];
                }
                [self tableViewScrollToBottomWithAnimated:YES];
            }
        }
    }
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
//    _isScrolling = YES;
//    [[NSNotificationCenter defaultCenter] postNotificationName:kBeginDragNotification object:nil];
    if (scrollView == _mainTableView){
        if (_chatInput.inputState){
            [self resignKeyBoard:nil];
        }
        return;
    }
    
    if(_emojiScrollView==scrollView){
        [self emojiSelectHide];
    }
}


-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == _mainTableView){
        _bIsScrollTail = [ACUtility scrollViewScrollStat:_mainTableView]&ScrollView_ScrollStat_Showed_Tail;
        if(_bIsScrollTail){
            //滚动到了底部
            _haveNewMsgButton.hidden  = YES;
            _nNewUnreadMsgCount = 0;
        }
        
//        [self pauseAllGif];
        if (_mainTableView.tableHeaderView && scrollView.contentOffset.y <= 20){
            if (!_isDidLoadDBScrollEnter)
            {
                _currentLoadStatus = ACCurrentLoadStatus_LoadEarly;
                _isDidLoadDBScrollEnter = YES;
            }
        }
        
        if (_messageVCType == ACMessageVCType_Search){
            if (_mainTableView.tableFooterView && scrollView.contentOffset.y+scrollView.size.height+20 > scrollView.contentSize.height)
            {
                if (!_isDidLoadDBScrollEnter)
                {
                    _currentLoadStatus = ACCurrentLoadStatus_LoadMore;
                    _isDidLoadDBScrollEnter = YES;
                }
            }
        }
/*
 - (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
 CGPoint offset = aScrollView.contentOffset;
 CGRect bounds = aScrollView.bounds;
 CGSize size = aScrollView.contentSize;
 UIEdgeInsets inset = aScrollView.contentInset;
 float y = offset.y + bounds.size.height - inset.bottom;
 float h = size.height;
 // NSLog(@"offset: %f", offset.y);
 // NSLog(@"content.height: %f", size.height);
 // NSLog(@"bounds.height: %f", bounds.size.height);
 // NSLog(@"inset.top: %f", inset.top);
 // NSLog(@"inset.bottom: %f", inset.bottom);
 // NSLog(@"pos: %f of %f", y, h);
 
 float reload_distance = 10;
 if(y > h + reload_distance) {
 NSLog(@"load more rows");
 }
 }
 */
        
        
        
    }
}



#pragma mark -IBAction
-(IBAction)replyToBoardcaster:(id)sender
{
    [self createSingleChatWithUserID:_topicEntity.createUserID];
}

-(IBAction)returnViewController:(id)sender
{
    if(_mulSelectToolBkView){
        [self mulSelect_End];
        return;
    }
    if(_sharingLocalUsersInfo.count){
        UIAlertView *pAlertView = [[UIAlertView alloc] initWithTitle:nil
                                                             message:NSLocalizedString(@"Real-time Location will stop if you leave this session.Leave now?", nil)
                                                            delegate:self
                                                   cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                   otherButtonTitles:NSLocalizedString(@"OK",nil), nil];
        pAlertView.tag = kShareLocationBackSessionTag;
        [pAlertView show];
        return;
    }
    
    [self _onBackFunc];
}
-(void)_onBackFunc{
    @synchronized(self){
        _nNowLoadMsgLimit   =   0;
    }
    if (_topicEntity.topicPerm.destruct == ACTopicPermission_DestructMessage_Allow)
    {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *filePath = nil;
            for (ACMessage *message in _dataSourceArray)
            {
                if (message.messageEnumType == ACMessageEnumType_Audio)
                {
                    filePath = [ACAddress getAddressWithFileName:((ACFileMessage *)message).resourceID fileType:ACFile_Type_AudioFile isTemp:NO subDirName:nil];
                    [fileManager removeItemAtPath:filePath error:nil];
                }
                else if (message.messageEnumType == ACMessageEnumType_Video)
                {
                    filePath = [ACAddress getAddressWithFileName:((ACFileMessage *)message).resourceID fileType:ACFile_Type_VideoFile isTemp:NO subDirName:nil];
                    [fileManager removeItemAtPath:filePath error:nil];
                    filePath = [ACAddress getAddressWithFileName:((ACFileMessage *)message).thumbResourceID fileType:ACFile_Type_VideoThumbFile isTemp:NO subDirName:nil];
                    [fileManager removeItemAtPath:filePath error:nil];
                }
                else if (message.messageEnumType == ACMessageEnumType_Image)
                {
                    filePath = [ACAddress getAddressWithFileName:((ACFileMessage *)message).thumbResourceID fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
                    [fileManager removeItemAtPath:filePath error:nil];
                    filePath = [ACAddress getAddressWithFileName:((ACFileMessage *)message).resourceID fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
                    [fileManager removeItemAtPath:filePath error:nil];
                }
            }
        });
    }
    if ([_superVC isKindOfClass:[ACChooseContactViewController class]] ||
        [_superVC isKindOfClass:[ACCreateChatGroupViewController class]] ||
        [_superVC isKindOfClass:[ACTransmitViewController class]]||
        [_superVC isKindOfClass:[ACNotesMsgVC_Main class]]||
        _topicEntity.relateType.length>0) //特殊状态
    {
        [self.navigationController ACpopToRootViewControllerAnimated:YES];
    }
    else if ([_superVC isKindOfClass:[ACParticipantInfoViewController class]])
    {
        ITLog(self.navigationController.viewControllers);
        UIViewController* popTo = nil;
        for (UIViewController *vc in self.navigationController.viewControllers){
            if(self==vc){
                continue;
            }
            
            if ([vc isKindOfClass:[ACChatMessageViewController class]]||
                [vc isKindOfClass:[ACSearchDetailController class]])
            {
                popTo = vc;
                break;
            }
        }
        
        if(popTo){
            [self.navigationController ACpopToViewController:popTo animated:YES];
        }
        else{
            [self.navigationController ACpopToRootViewControllerAnimated:YES];
        }
    }
    else
    {
        [self.navigationController ACpopViewControllerAnimated:YES];
    }
    [self clearViewController];
}

-(void)clearViewController
{
    if(_sharingLocalUsersInfo.count){
        [ACMapShareLocalVC exitShareLocalwithVC:self];
    }
    
//    [[ACLBSCenter shareLBSCenter] cancelAutoUpdatingLocation];
    [ACLBSCenter autoUpdatingLocation_End];
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
}



#pragma mark -createSingleChat

-(void)createSingleChatWithUserID:(NSString *)userID
{
    if ([userID length] > 0)
    {
        [self.contentView showNetLoadingWithAnimated:NO];
        [ACNetCenter shareNetCenter].createTopicEntityVC = self;
        [[ACNetCenter shareNetCenter] createTopicEntityWithChatType:cSingleChat withTitle:nil withGroupIDArray:nil withUserIDArray:[NSArray arrayWithObject:userID] exMap:nil];
    }
}

-(void)createGroupChatSuccess:(NSNotification *)noti
{
    if ([ACNetCenter shareNetCenter].createTopicEntityVC == self)
    {
        [self.contentView hideProgressHUDWithAnimated:NO];
        ACTopicEntity* ptopicEntity =   noti.object;
        UIViewController* pVC_ForSuper =   self;
        UINavigationController* pNavigationController = self.navigationController;
//      继续沿用旧的Return方式,退出时才判断退到哪里
//        if(ptopicEntity.relateType.length){
//            //特殊类型,弹出前面的View
//            pVC_ForSuper   =   _superVC;
//            [self.navigationController ACpopViewControllerAnimated:NO];            
//        }
        ACChatMessageViewController *chatMessageVC = [[ACChatMessageViewController alloc] initWithSuperVC:pVC_ForSuper withTopicEntity:ptopicEntity];
//        chatMessageVC.topicEntity = ptopicEntity;
//        [chatMessageVC preloadDB];
        AC_MEM_Alloc(chatMessageVC);
        [pNavigationController pushViewController:chatMessageVC animated:YES];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark --New Message Count Flag View


-(void)checkShowNewMsgFlagView{
    if((ACMessageVCType_Define!=_messageVCType)||
       (!_theNewMsgCountView.isHidden)||
       (0==_dataSourceArray.count)){
        
        return;
    }
    
    long lNewMsgCount = _topicEntity.lastestSequence-_currentSeq;

    if(lNewMsgCount>0){
        
        //_currentSeq 为0 是新的,否则没有Seq为0的时候,Seq从1开始
        _lNewMsgSequence    =  _currentSeq+1;
        _lNewMsgSequenceFor99_Plus = -1L;
        
        if(lNewMsgCount>10){
            _theNewMsgCountView.hidden = NO;

            //设置显示信息
            if(lNewMsgCount<100) {
                _newMsgCountLable.text = [NSString stringWithFormat:NSLocalizedString(@"%ld unread messages", nil), lNewMsgCount];
            }
            else{
                _newMsgCountLable.text = NSLocalizedString(@"99+ unread messages", nil);
            }
            [_newMsgCountLable setSingleRowAutosizeLimitWidth:167];
            
            CGRect rect =   _newMsgCountLable.frame;
            rect.size.width =   rect.origin.x+rect.size.width+8;
            rect.origin.x   =   _contentView.frame.size.width-rect.size.width;
            rect.origin.y   =   _theNewMsgCountView.frame.origin.y;
            rect.size.height=   _theNewMsgCountView.frame.size.height;
            _theNewMsgCountView.frame  =   rect;

            [_theNewMsgCountView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapNewMsgFlagView)]];
        }
    }
//TEST    else{
//        _lNewMsgSequence    =  _currentSeq;
//    }
}

-(void)onTapNewMsgFlagView{
    if (![ASIHTTPRequest isValidNetWork])
    {
        _mainTableView.tableHeaderView = nil; //_activityIndicatorView;
        [_activityView setHidden:YES];
        [_contentView showProgressHUDNoActivityWithLabelText:NSLocalizedString(@"Network_Failed", nil) withAfterDelayHide:0.8];
        return;
    }
        
    _mainTableView.tableHeaderView = _activityIndicatorView;
    
    ///
    [_activityIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.offset(kScreen_Width);
    }];
    
    [_activityView setHidden:NO];
    [_activityView startAnimating];
    
    //滚动到头显示_activityView
    _theNewMsgCountView.hidden = YES;
    _mainTableView.contentOffset = CGPointZero;

    //取得100
    _lNewMsgSequenceFor99_Plus  = (_topicEntity.lastestSequence-_currentSeq)>Load_Unread_Msg_Max_Count?_topicEntity.lastestSequence-Load_Unread_Msg_Max_Count+1:-1L;

    _isNeedNetworkRequest = YES;
    _bForNewMsgCountViewTap = YES;

    long lastSequence = _lNewMsgSequenceFor99_Plus<0?_lNewMsgSequence:_lNewMsgSequenceFor99_Plus;
    NSAssert(lastSequence>0,@"lastSequence>0");
    
    if (_topicEntity.topicPerm.destruct != ACTopicPermission_DestructMessage_Allow){
        if(lastSequence<3){
            lastSequence = 0;
        }
        else{
            lastSequence -= 3;
        }
    }
    long lEndSeq = [(ACMessage *)[_dataSourceArray objectAtIndex:0] seq];

    int nLimit = (int)(lEndSeq-lastSequence);
    NSAssert(nLimit<Load_Unread_Msg_Max_Count,@"nLimit<Load_Unread_Msg_Max_Count");
    
    _scrollToIndex =    nLimit;
    ITLogEX(@"offset=%ld,limit=%d",lEndSeq,nLimit);

    [self _getChatMessageListWithOffset:lEndSeq withLimit:nLimit isLoadNew:NO];
    
//    [[ACNetCenter shareNetCenter] getChatMessageListWithGroupID:_topicEntity.entityID
//                                                     withOffset:lEndSeq
//                                                      withLimit:nLimit
//                                                      isLoadNew:NO
//                                                      isDeleted:_topicEntity.isDeleted];

    
    
/*
    long lastSequence = _lNewMsgSequence;
    
    if (_topicEntity.perm.destruct != ACTopicPermission_DestructMessage_Allow&&
        lastSequence>3){
        lastSequence -= 3;
    }

    [self getDataSourceFromDBOrNet:lastSequence];*/
}

- (IBAction)onHaveNewMsgButton:(id)sender {
    [self tableViewScrollToBottomWithAnimated:YES];
}


-(void)_getChatMessageListWithOffset:(long)offset withLimit:(int)limit isLoadNew:(BOOL)isLoadNew{
    
    if(limit<=0){
        limit = ACMessage_loaded_Pre_Msg_Count;
    }
    
    @synchronized(self){
        _lNowLoadMsgOffset  =   offset;
        _nNowLoadMsgLimit   =   limit; //=0 表示没有了
        _bNowLoadMsgIsNew   =   isLoadNew;
    }
    
    if(LoginState_logined==[ACConfigs shareConfigs].loginState){
        [[ACNetCenter shareNetCenter] getChatMessageListWithGroupID:_topicEntity.entityID
                                                         withOffset:offset
                                                          withLimit:limit
                                                          isLoadNew:isLoadNew
                                                          isDeleted:_topicEntity.isDeleted];
    }
}

-(void)_reloadUngetMsgFromNet{
    //再一次从网络加载上次没有成功的消息
    if(_nNowLoadMsgLimit){
        [self _getChatMessageListWithOffset:_lNowLoadMsgOffset
                                  withLimit:_nNowLoadMsgLimit
                                  isLoadNew:_bNowLoadMsgIsNew];
    }
}


#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView.cancelButtonIndex==buttonIndex){
        return;
    }
    
    if(kShareLocationJoinTag==alertView.tag){
        [self _sharingLocalJoin];
        return;
    }
    
    if(kShareLocationBackSessionTag==alertView.tag){
        [self _onBackFunc];
        return;
    }
}

#pragma mark sharingLocal

-(void)_sharingLocalTipViewTap:(UITapGestureRecognizer *)recognizer{
    if(_sharingLocalUsersInfo.count){
        //直接进入
        [self _sharingLocalJoin];
        return;
    }
    
    UIAlertView *pAlertView = [[UIAlertView alloc] initWithTitle:nil
                                                         message:NSLocalizedString(@"Your location will be shared with other users in the group. Join now?", nil)
                                                        delegate:self
                                               cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                               otherButtonTitles:NSLocalizedString(@"Join",nil), nil];
    pAlertView.tag = kShareLocationJoinTag;
    [pAlertView show];
}

-(void)_sharingLocalEventNotify:(NSNotification *)noti{
    if([_topicEntity.entityID isEqualToString:noti.object[kTeid]]){
        [self sharingLocalTipCheck];
        if(_sharingLocalUsersInfo.count){
            //处理
            [ACMapShareLocalVC checkChangeUsers:noti.object[@"users"] withVC:self];
        }
    }
}


-(void)_sharingLocal_update_for_Timer{
    
    if(_sharingLocalUsersInfo.count){
        ITLog(@".....后台位置共享心跳.....");
        [ACMapShareLocalVC updataLocation:[ACConfigs shareConfigs].location withVC:self];
    }
}


-(void)_sharingLocal_LBS_ChangeNotify:(NSNotification *)noti{
    ITLog(@"");
    ACConfigs* pACCfg = [ACConfigs shareConfigs];
    if([ACMapShareLocalVC canUpdataLocation:pACCfg.location withOldLoc:pACCfg.location_old]){
        [ACMapShareLocalVC updataLocation:pACCfg.location withVC:self];
    }
}

-(void)_sharingLocalJoin{
    //不管其他，等定位成功，再加入刷新数据
    [_timerForShareLocation invalidate];
    _timerForShareLocation = nil;
    [ACMapShareLocalVC showForSuperVC:self]; //定位成功后再刷新数据
}

-(void)sharingLocal_LBS_ChangeNotifyEnable:(BOOL)bEnable {
    NSNotificationCenter* nc= [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:kNotificationLocationChanged object:nil];
    
    [_timerForShareLocation invalidate];
    _timerForShareLocation = nil;
    
    BOOL bReportLocation = _topicEntity.topicPerm.reportLocation == ACTopicPermission_ReportLocation_Allow;
    
    if(bEnable&&_sharingLocalUsersInfo.count){
        [nc addObserver:self selector:@selector(_sharingLocal_LBS_ChangeNotify:) name:kNotificationLocationChanged object:nil];
        
        if (!bReportLocation){
            [ACLBSCenter autoUpdatingLocation_Begin];
        }
        
        //需要心跳
        if(_sharingLocalTickTimeS>1){
            _timerForShareLocation = [NSTimer scheduledTimerWithTimeInterval:_sharingLocalTickTimeS target:self selector:@selector(_sharingLocal_update_for_Timer) userInfo:nil repeats:YES];
        }
        
        return;
    }
    
    if (!bReportLocation){
        [ACLBSCenter autoUpdatingLocation_End];
    }
}

-(void)sharingLocalTipCheck{

    if(!_topicEntity.nSharingLocalUserCount){
        
        [_timerForShareLocation invalidate];
        _timerForShareLocation = nil;
        
        if(_sharingLocalTipView){
            ITLog(@"位置共享结束.....");
            [_sharingLocalTipView removeFromSuperview];
            _sharingLocalTipView = nil;
            
            [_sharingLocalUsersInfo removeAllObjects];
            _sharingLocalUsersInfo = nil;
            [self sharingLocal_LBS_ChangeNotifyEnable:NO];
        }
        return;
    }
    
    if(nil==_sharingLocalTipView){
        ITLog(@"位置共享开始!!!");

        _sharingLocalUsersInfo  =   [[NSMutableArray alloc] initWithCapacity:10];

        _sharingLocalTipView    =   [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.size.width, 44)];
        [_sharingLocalTipView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_sharingLocalTipViewTap:)]];
        
        UIImageView* pImg1 = [[UIImageView alloc] initWithFrame:CGRectMake(self.contentView.size.width-10-8, (44-17)/2, 10, 17)];
        pImg1.image = [UIImage imageNamed:@"Connectkeyboad_banner_guid_ios7"];
        [_sharingLocalTipView addSubview:pImg1];
        
        pImg1 = [[UIImageView alloc] initWithFrame:CGRectMake(4, (44-30)/2, 30, 30)];
        pImg1.image = [UIImage imageNamed:@"locationSharing_Icon_Location_HL2"];
        [_sharingLocalTipView addSubview:pImg1];
        
        UILabel* pLable = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.contentView.size.width, 44)];
        pLable.tag  = 1001;
        pLable.textAlignment    =   NSTextAlignmentCenter;
        [_sharingLocalTipView addSubview:pLable];

        [self.contentView addSubview:_sharingLocalTipView];
    }
    
    UILabel* pLable =   (UILabel*)[_sharingLocalTipView viewWithTag:1001];
    if(_sharingLocalUsersInfo.count){
        //已经加入
        _sharingLocalTipView.backgroundColor = UIColor_RGBA(0x8d,0xc5,0x56,0.9);
        pLable.text =   NSLocalizedString(@"You\'re sharing your location now.", nil);
        /*
         Real-time Location will stop if you leave this session.Leave now?
         */
    }
    else{
        if(_topicEntity.isSigleChat){
            pLable.text =   NSLocalizedString(@"Click to join Real-time Location", nil);
        }
        else{
            pLable.text =  [NSString stringWithFormat:NSLocalizedString(@"%d person(s) sharing their location", nil),_topicEntity.nSharingLocalUserCount];
        }
        
        //还没有加入 单对单:@"Click to join Real-time Location"
        // %d person(s) sharing their location
        _sharingLocalTipView.backgroundColor = UIColor_RGBA(0x79,0x8d,0x94,0.9);;
        
//        pLable.text =   NSLocalized String(@"xxxx sharing location now.", nil);
    }
}

@end
