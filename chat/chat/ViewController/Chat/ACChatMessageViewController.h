//
//  ACChatMessageViewController.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-8.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THChatInput.h"
#import "ACEntity.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MWPhotoBrowser.h"
#import <CoreLocation/CoreLocation.h>
#import <QuickLook/QuickLook.h>
#import "ACMessage.h"
#import "TPAACAudioConverter.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "ACPersonContactVC.h"


#define Load_Unread_Msg_Max_Count  500
//加载最多未读信息个数，避免加载时间过长,不能修改只能是100


#define kChatMessageMaxLength   10000


#define kActionSheetTag_MsgOpt       7760
#define kActionSheetTag_Location        7761

#define kActionSheetTag_Resend          7766
#define kPreviewViewTag                 32423
#define kShareLocationJoinTag           32425
#define kShareLocationBackSessionTag    32427

//#if !TARGET_IPHONE_SIMULATOR
//    #ifndef ACUtility_Need_Log
//        #define ACChatMessageVC_SendOneImgWithPrew   //发送单个预览图片
//    #endif
//#endif


//extern NSString *const kUpdateUnReadCountNotification;

//extern NSString *const kBeginDragNotification;
//extern NSString *const kStopDecelerateNotification;


enum ACMessageVCType
{
    ACMessageVCType_Define,
    ACMessageVCType_Search,
};

enum ACCurrentLoadStatus
{
    ACCurrentLoadStatus_LoadEarly,
    ACCurrentLoadStatus_LoadMore,
};

@interface FaceButton : UIButton
@property NSInteger buttonIndex;
@end

@class ACFileMessage;
@class ACGoogleHotspot;
@class ACMessage;
@class ACReadSeq;
@class ACStickerPackage;
@class ACChatViewController;
@class ACSuit_Recent;
@class ACReadCount;
@class ACChatMessageTableViewCell;
@class ACSharingLocalMapUserInfo;
@interface ACChatMessageViewController : UIViewController
<UIScrollViewDelegate,
UITableViewDataSource,
UITableViewDelegate,
UIImagePickerControllerDelegate,
AVAudioRecorderDelegate,
AVAudioPlayerDelegate,
UIActionSheetDelegate,
UIAlertViewDelegate,
UINavigationControllerDelegate>
{
    
    //----------------for Board--------
    __weak IBOutlet UIView          *_emojiInputView;
    __weak IBOutlet UIScrollView    *_emojiButtonScrollView;
    __weak IBOutlet UIView          *_emojiButtonLineView;
    __weak IBOutlet UIPageControl   *_emojiPageC;
    __weak IBOutlet UIScrollView    *_emojiScrollView;
    __weak IBOutlet UIView          *_emojiSelectBkView;
    FaceButton                      *_emojiSelectButtonTemp;
    UIImageView                     *_emojiSelectImageView;
    NSInteger                       _currentPageCount;
    NSInteger                       _currentSelectedStickerPackage;
    
    NSDictionary                    *_faceMap;
    
    NSString                        *_sendVideoMsgID;
    NSString                        *_currentVideoPath;
    
    __weak IBOutlet UIScrollView    *_addScrollView;
    __weak IBOutlet UIPageControl   *_addPageC;

    
    //--------------for Sticker---------
    __weak IBOutlet UIView          *_stickerDownloadView;
    //    IBOutlet UIProgressView   *_stickerDownloadProgressView;
    __weak IBOutlet UIButton        *_stickerDownloadButton;
    __weak IBOutlet UILabel         *_stickerDownloadLabel;
    __weak IBOutlet UILabel         *_stickerDownloadingLabel;
    ACSuit_Recent                   *_pSuit_Recent;
    NSMutableArray                  *_suitArray;
    NSString                        *_currentSuitID;

    
    //--------------for Input---------
    BOOL                            _recordAudioNeedSend;
    BOOL                            _isAppear;
    float                           _currentHeight;
    long                            _lNeedSendToMessageReadedSequence; //需要发送已读消息到服务器的Sequence编号
    NSString                        *_pDraft; //草稿信息
    ACMessage                       *_resendMessage;
    NSMutableDictionary             *_readCountMutableDic;

    
    TPAACAudioConverter             *_audioConverter;
    NSTimer                         *_recordShowTimer;
    AVAudioRecorder                 *_audioRecorder;
    NSString                        *_sendAudioMsgID;
    NSTimeInterval                  _recordStartTI;
    int                             _recordAudioDuration;
    
    __weak IBOutlet UIView          *_recordShowView;
    __weak IBOutlet UIImageView     *_recordShowImageView;
    __weak IBOutlet UILabel         *_recordShowLabel;
    
    __weak IBOutlet UIButton        *_sendButton;

    //--------------for Tap---------
    long                            _currentSeq;//阅后即焚用于暂时保存当前seq，来加载更早数据
    MPMoviePlayerViewController     *_moviePlayerVC;
#ifdef ACChatMessageVC_SendOneImgWithPrew
    UIImagePickerController         *_pImagePickerForReview; //为了预览
    NSDictionary                    *_pImagePickerSelectInfoForReview;
#endif
    NSMutableArray                  *_needViewImageCollections; //类似相册的图片信息[ACFileMessageCache]
    NSArray                         *_netPreLoadImageCollections; //网络预加载的信息[NSDict]
    int                             _netPreLoadImageCollectionsLoadDir; //加载的方向
    ACFileMessage                   *_currentPlayingAudioMsg;
    AVAudioPlayer                   *_audioPlayer;
    
    //-------------for Transmit----------
    UIButton                        *_buttonForTransmit;
    UIView                          *_mulSelectToolBkView; //多选功能按钮背景
    NSMutableArray                  *_mulSelectMsgs; //ACMessage
   
   
    //--------------for msgList----------
    
    NSMutableArray                  *_preloadArray;
    NSMutableArray                  *_dataSourceArray;
    NSMutableArray                  *_unSendMsgArray;
    ACTopicEntity                   *_topicEntity;
    
    
    __weak IBOutlet UIView          *_tableViewShadeView;
    __weak IBOutlet UIImageView     *_chatBgImageView;
    __weak IBOutlet UITableView     *_mainTableView;
    __weak IBOutlet UILabel         *_chatTitleLabel;
    
    //tableHeaderView
    __weak IBOutlet UIView                      *_activityIndicatorView;
    __weak IBOutlet UIActivityIndicatorView     *_activityView;
    //tableFooterView search用
    __weak IBOutlet UIView                      *_activityFooterIndicatorView;
    __weak IBOutlet UIActivityIndicatorView     *_activityFooterView;
    
    __weak IBOutlet UIButton        *_backButton;
//    long                            _readCountBaseSeq;//用于保存本次请求readCount基准seq，请求过程中重复不重新请求
//    BOOL                            _isScrolling;

//    BOOL                            _viewDidLoad;
    __weak IBOutlet UIButton        *_groupInfoButton;
    __weak IBOutlet UIButton        *_jumpinButton;
    
    __weak IBOutlet UIView          *_replyToBoardcastView;
    __weak IBOutlet UIButton        *_replyToBoardcastButton;
//    BOOL                            _isShowHud;
//    BOOL                            _isNeedLoadData;
//    BOOL                            _isLoadingData;ƒ
    
    //--------------for newMsg------
    __weak IBOutlet UIImageView     *_newMsgCountBkView;
    __weak IBOutlet UILabel         *_newMsgCountLable;
    __weak IBOutlet UIButton        *_haveNewMsgButton;
    
}

//@property (nonatomic) long                          searchSequence;//用于search message


@property (weak, nonatomic) IBOutlet UIView         *contentView;
@property (weak, nonatomic) IBOutlet THChatInput    *chatInput;
@property (weak, nonatomic) IBOutlet UIView         *addSelectView;
@property (weak, nonatomic) IBOutlet UIView         *theNewMsgCountView;



//@property (nonatomic,strong) NSDictionary           *faceMap;
//@property (nonatomic,strong) NSMutableArray         *dataSourceArray;//消息
//@property (nonatomic,strong) NSMutableArray         *unSendMsgArray;//未发送的消息
@property (nonatomic,readonly) ACTopicEntity          *topicEntity;
//@property (nonatomic,strong) NSTimer                *recordShowTimer;

//@property (nonatomic,strong) AVAudioRecorder        *audioRecorder;

//@property (nonatomic,strong) NSString               *sendAudioMsgID;

//@property (nonatomic) NSTimeInterval                recordStartTI;
//@property (nonatomic,strong) NSMutableArray         *photoArray;
//@property (nonatomic,strong) NSString               *currentVideoPath;

//@property (nonatomic,strong) NSMutableDictionary    *readCountMutableDic;
//@property (nonatomic,strong) NSArray              *transmitMessages; //ACMessage
@property (nonatomic,strong) NSArray              *transmitMessages_Or_sendFilePaths; //ACMessage or NSString


//@property (nonatomic,strong) NSString               *currentSuitID;
//@property (nonatomic) BOOL                          isActionSheetKeyboardHide;
//@property (nonatomic,strong) ACMessage              *resendMessage;
@property (nonatomic) BOOL                          isOpenHotspot;
//@property (nonatomic,strong) ACFileMessage          *fileMessage;
//@property (nonatomic,strong) UIViewController       *quickLookView;
//@property (nonatomic,weak) ACChatViewController     *searchUserChatVC;  //????

//--------------search------------
@property (nonatomic,strong) NSString               *searchKey;
@property (nonatomic) BOOL                          isSearchDelete;
//@property (nonatomic) BOOL                          isNeedNetworkRequest;
//@property (nonatomic) BOOL                          isSearchTableCanShow;
//@property (nonatomic) int                           recordAudioDuration;
//@property (nonatomic,strong) NSMutableArray         *preloadArray;
//@property (nonatomic,strong) NSMutableArray         *suitArray;
//@property (nonatomic) BOOL                          isNeedReloadSuit;//是否需要重载suit


- (instancetype)initWithSuperVC:(UIViewController *)superVC withTopicEntity:(ACTopicEntity *)topicEntity;
- (instancetype)initWithSuperVC:(UIViewController *)superVC withTopicEntity:(ACTopicEntity *)topicEntity andSearchSequence:(long)SearchSequence;


//for board
-(void)createGroupChatSuccess:(NSNotification *)noti;
-(void)tableViewScrollToBottomWithAnimated:(BOOL)animated;


//------------------------for ACMapShareLocalVC ------------
@property (nonatomic,strong) NSMutableArray<ACSharingLocalMapUserInfo*> *sharingLocalUsersInfo;
@property (nonatomic,strong) UIView                                     *sharingLocalTipView;
@property (nonatomic)        float                                      sharingLocalTickTimeS; //心跳秒

-(void)sharingLocalTipCheck; //检查位置共享标志
-(void)sharingLocal_LBS_ChangeNotifyEnable:(BOOL)bEnable;

//------------------------for ACChatMessageTableViewCell ------------
@property (nonatomic) enum ACMessageVCType          messageVCType;
@property (nonatomic,strong) ACReadSeq              *readSeq;
@property (nonatomic,strong) NSMutableArray         *otherButtonTitles;//actionSheet用
@property (nonatomic,strong) ACChatMessageTableViewCell    *actionSheetCell;//长按cell用得msgData
@property (nonatomic) long                          lNewMsgSequence; //新信息的Sequence,<0表示没有
@property (nonatomic) long                          lNewMsgSequenceFor99_Plus; //用于显示 “The latest 100 unread messages below”
@property (nonatomic) BOOL                          isSystemChat; //是否是
@property (nonatomic) BOOL                          isScrolling;
@property (nonatomic,readonly) BOOL                 isMulSelect;
@property (nonatomic,strong) NSArray                *highLightArray;

-(void)tableViewReloadData;
-(void)getReadSeqOrReadCount;
-(ACReadCount*)getReadCountWithSeq:(long)seq;
-(BOOL)isUnSendMsg:(ACMessage*)pMsg;
-(BOOL)mulSelectedMsg:(ACMessage*)pMsg forTap:(BOOL)bForTap;
//-(void)mulSelect_Begin;
//-(void)mulSelect_End;


@end
