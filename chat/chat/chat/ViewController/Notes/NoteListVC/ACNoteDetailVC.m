//
//  ACNoteDetailVC.m
//  chat
//
//  Created by Aculearn on 14/12/24.
//  Copyright (c) 2014年 Aculearn. All rights reserved.
//

#import "ACNoteDetailVC.h"
#import "ACNoteListVC_Cell.h"
#import "UINavigationController+Additions.h"
#import "ACNetCenter+Notes.h"
#import "ACNoteUpdateVC.h"
#import "ACNoteListVC_Base.h"
#import "ACNoteCommentCell.h"
#import "ACDataCenter.h"

#define kNote_DeleteTag     14358
#define kComemnt_DeleteTag  14367

@interface ACNoteDetailVC ()<UIActionSheetDelegate>{
    __weak IBOutlet THChatInput *_chatInput;
    __weak IBOutlet UIView *_contentView;
    
    __weak IBOutlet UIButton *_noteDeleteButton;
    __weak IBOutlet UIButton *_noteUpdateButton;
    
    __weak IBOutlet UILabel *_titleLable;
    
    UIView   *_tableViewShadeView;
    NSMutableArray* _commentList;
//    ACNoteComment*  _nowSendingComment;
//    NSIndexPath*    _pNeedDelCommentIndexPath;
    
    BOOL    _bCommentChanged;   //曾经修改了Comment,删除或发送
    BOOL    _bUpdateNoteContent; //更新了Note
    
    BOOL    _bAllowComment;
    enum    ACNotePermission_DELETECOMMENT  _nCommentDelPer; //删除权限
    
    __weak  ACNoteCommentCell*  _nowOprateCommentCell;   //当前回复的对象Cell
    __weak  ACNoteCommentBase*  _nowReplyCommentBase;
    
    
    __weak  ACNoteListVC_Base*   _superNoteListVC;
    NSIndexPath*                _noteIndexPath;

    NSArray<NSString*>*         _noteHightLights; //高亮文本
    

//    __weak  NSString*       _needCheckNoteID; //需要检查的NoteID
//    @property (nonatomic,strong) NSObject           *objForCheck;
    //NSString* noteId fromNotification 或者 ACNoteObject

}

@end

@implementation ACNoteDetailVC

AC_MEM_Dealloc_implementation

+(void)showNoteMsg:(ACNoteMessage *)noteMessage withIndexPath:(NSIndexPath*)noteIndexPath inNoteListVC:(ACNoteListVC_Base *)noteListVC{
    ACNoteDetailVC* pVC = [[ACNoteDetailVC alloc] init];
    AC_MEM_Alloc(pVC);
    pVC->_topicEntity   =   noteListVC.topicEntity;
    pVC->_noteMessage   =   noteMessage;
    pVC->_superNoteListVC=  noteListVC;
    pVC->_noteIndexPath =   noteIndexPath;
    [noteListVC.navigationController pushViewController:pVC animated:YES];
}




+(void)_showWithNoteID:(NSString*)pNoteID
             orNoteObj:(ACNoteObject*)pNoteObj
                  andTopic:(ACBaseEntity*)pTopic
          andHighlight:(NSArray<NSString*>*)highlights
              inNomalSuperVC:(UIViewController*)_pSuperVC{
    
    __weak UIViewController*    pSuperVC = _pSuperVC;
    
    [pSuperVC.view showProgressHUD];
    
    if(pNoteObj){
        pNoteID     =   pNoteObj.isNoteMessage?(pNoteObj.id):(((ACNoteComment*)pNoteObj).noteId);
    }

    //检查状态
    NSString* acChechNoteUrl = nil;
    
    if(highlights){
        acChechNoteUrl  =   [NSString stringWithFormat:@"%@/rest/apis/note/getSearchNoteDetail/%@",
                              [[ACNetCenter shareNetCenter] acucomServer],
                              pNoteID];
    }
    else{
        acChechNoteUrl = [NSString stringWithFormat:@"%@/rest/apis/note/%@?u=%lld",
                                           [[ACNetCenter shareNetCenter] acucomServer],
                                           pNoteID,
                                           (pNoteObj&&pNoteObj.isNoteMessage)?pNoteObj.updateTime:0];
    }
    ///rest/apis/note/getSearchNoteDetail/{nodeid}
    
    [ACNetCenter callURL:acChechNoteUrl forMethodDelete:NO withBlock:^(ASIHTTPRequest *request, BOOL bIsFail){
        NSString* pError  = NSLocalizedString(@"Network_Failed", nil);
        [pSuperVC.view hideProgressHUDWithAnimated:NO];
        
        if(!bIsFail){
            NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
            ITLog(responseDic);
            int nCode = [[responseDic objectForKey:kCode] intValue];
            if(ResponseCodeType_Nomal==nCode){
                ACNoteMessage      *noteMessage = nil;
                NSDictionary* pNoteDict =   [responseDic objectForKey:@"note"];
                if(pNoteObj&&pNoteObj.isNoteMessage){
                    noteMessage    =   (ACNoteMessage*)pNoteObj;
                    if(pNoteDict.count){
                        [noteMessage updateMessageFromDict:pNoteDict];
                    }
                }
                else if(pNoteDict.count){
                    noteMessage    =   [[ACNoteMessage alloc] initWithDict:pNoteDict];
                }
                
                if(noteMessage){
                    ACNoteDetailVC* pVC = [[ACNoteDetailVC alloc] init];
                    AC_MEM_Alloc(pVC);
                    pVC->_topicEntity   =   (ACTopicEntity*)pTopic;
                    pVC->_noteMessage   =   noteMessage;
                    pVC->_noteHightLights= highlights;
                    [pSuperVC.navigationController pushViewController:pVC animated:YES];
                    return ;
                }
            }
            else if(ResponseCodeType_Note_Deleted==nCode){
                pError  =   NSLocalizedString(@"This note has been removed!",nil);
            }
        }
        
        AC_ShowTip(pError);
    }];
}

+(void)showNote:(ACNoteObject*)pNoteObj
      withTopic:(ACTopicEntity*)pTopic
   inTimeLineVC:(ACNoteListVC_Base*)timeLineVC{
    
    [self _showWithNoteID:nil
                orNoteObj:pNoteObj
                 andTopic:pTopic
             andHighlight:nil
           inNomalSuperVC:timeLineVC];
}


+(void)showNoteMsgWithNoteID:(NSString*)pNoteID
                    andTopic:(ACTopicEntity*)pTopic
                andHighlight:(NSArray<NSString*>*)highlights
              inNomalSuperVC:(UIViewController*)pSuperVC{
    [self _showWithNoteID:pNoteID
                orNoteObj:nil
                 andTopic:pTopic
             andHighlight:highlights
           inNomalSuperVC:pSuperVC];
}

/*
+(BOOL)showWithSearchText:(NSString*)searchText
        andSearchNoteInfo:(NSDictionary*)pSearchResult
           inNomalSuperVC:(UIViewController*)pSuperVC{
    //用在搜索中
    ACTopicEntity* pTopic = [[ACDataCenter shareDataCenter] findTopicEntity:pSearchResult[@"teid"]];
    if(nil==pTopic){
        return NO;
    }
    ACNoteDetailVC* pVC = [[ACNoteDetailVC alloc] init];
    pVC->_topicEntity   =   pTopic;
    pVC->_searchNoteResultInfo =    pSearchResult;
    pVC->_searchText    =   searchText;
    [pSuperVC.navigationController pushViewController:pVC animated:YES];
    return YES;
}*/



- (void)viewDidLoad {
    
//    self.bNotNeedRefreshHead = YES;
    [super viewDidLoad];

// /
    [_navBarView setFrame:CGRectMake(0, 0, kScreen_Width, 64)];
    [_navBackView setFrame:CGRectMake(0, 0, kScreen_Width, 64)];
    [_navBackImage setFrame:CGRectMake(0, 0, kScreen_Width, 64)];
    [_navView setFrame:CGRectMake(0, 20, kScreen_Width, 44)];
    
    [_noteDeleteButton setFrame_x:kScreen_Width-49];
    [_noteUpdateButton setFrame_x:kScreen_Width - 49-40];
    _titleLable.center = CGPointMake(kScreen_Width/2, 22);
    [_contentView setFrame:CGRectMake(0, 64,kScreen_Width, kScreen_Height-64)];
    ///[self.mainTableView setFrame:CGRectMake(0, 64, kScreen_Width, kScreen_Height-64)];
    [self.mainTableView setSize:CGSizeMake(kScreen_Width, kScreen_Height-64)];
    [_chatInput setFrame_y:self.mainTableView.size.height - 55];
    
    [self.view bringSubviewToFront:_navBarView];
    
    NSAssert(_topicEntity,@"必须有topicEntity");
    
    if (![ACConfigs isPhone5]){
        [self.mainTableView setFrame_height:self.mainTableView.size.height-88];
        [_contentView setFrame_height:_contentView.size.height-88];
        [_chatInput setFrame_y:_contentView.size.height-_chatInput.frame.size.height];
    }
    
    _titleLable.text    =   _topicEntity.showTitle;
    _tableViewShadeView = [[UIView alloc] initWithFrame:self.mainTableView.frame];
    _tableViewShadeView.backgroundColor =   [UIColor clearColor];
    [_contentView addSubview:_tableViewShadeView];
    
//    BOOL  chatInput_hidden = NO;
//    BOOL noteDeleteButton_hidden = NO;
//    BOOL noteUpdateButton_hidden = NO;

    
    {
        enum ACNotePermission_ADDCOMMENT  note_addComment = _topicEntity.topicPerm.note_addComment;
        _bAllowComment = (note_addComment==ACNotePermission_ADDCOMMENT_EVERYONE||
                          (ACNotePermission_ADDCOMMENT_OWN==note_addComment&&_noteMessage.creator.isMyself));
        if(_bAllowComment){
            [_chatInput setForSimpleInput];
//            _chatInput.audioButton.hidden = YES;
//            _chatInput.addButton.hidden = YES;
//            _chatInput.emojiButton.hidden = YES;
//            _chatInput.pressSayButton.hidden = YES;
//            _chatInput.inputBackgroundView.image = [[UIImage imageNamed:@"NoteCommentInputBK.png"] stretchableImageWithLeftCapWidth:35 topCapHeight:22];
//            _chatInput.textView.frame = CGRectMake(25.0f, 25, _chatInput.inputBackgroundView.frame.size.width-45, _chatInput.textView.frame.size.height);
//            [_chatInput.lblPlaceholder setFrame_x:26];
            _chatInput.delegate =   self;
            [_contentView bringSubviewToFront:_chatInput];
            
            //+5 是 chatInput的背景图片上面有空白
            [self.mainTableView setFrame_height:_contentView.frame.size.height-_chatInput.frame.size.height+5];
        }
        else{
            _chatInput.hidden = YES;
        }
        
        _nCommentDelPer =   _topicEntity.topicPerm.note_delComment;
    }
    

    _commentList    =   [[NSMutableArray alloc] init];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//    [nc addObserver:self selector:@selector(Notification_Comment_LoadList:) name:kNetCenterNotes_Comment_LoadList_Notifition object:nil];
//    [nc addObserver:self selector:@selector(Notification_Comment_Upload:) name:kNetCenterNotes_Comment_Upload_Notifition object:nil];
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
    
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [nc addObserver:self selector:@selector(topicInfoChange) name:kDataCenterTopicInfoChangedNotifation object:nil];
    
    
    UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignKeyBoard:)];
    [_tableViewShadeView addGestureRecognizer:tap1];
    
    UISwipeGestureRecognizer *swipeGes = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(resignKeyBoard:)];
    [swipeGes setDirection:UISwipeGestureRecognizerDirectionUp];
    [_tableViewShadeView addGestureRecognizer:swipeGes];
    
    UISwipeGestureRecognizer *swipeGes1 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(resignKeyBoard:)];
    [swipeGes1 setDirection:UISwipeGestureRecognizerDirectionDown];
    [_tableViewShadeView addGestureRecognizer:swipeGes1];
    
    _tableViewShadeView.hidden = YES;
    
    if(_noteMessage){
        [self _checkNoteDelOrUpdateButton];
    }
   
    if(_noteMessage.commentNum){
        [self LoadDataFunc];
    }
    else{
        [self LoadDataFuncEnd_WithCount:0];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)_checkNoteDelOrUpdateButton{
    {
        enum ACNotePermission_DELETENOTE      note_del = _topicEntity.topicPerm.note_del;
        if(!(note_del==ACNotePermission_DELETENOTE_EVERYONE||
             (ACNotePermission_DELETENOTE_OWN==note_del&&_noteMessage.creator.isMyself))){
            //不允许删除
            _noteDeleteButton.hidden = YES;
            _noteUpdateButton.frame =   _noteDeleteButton.frame;
        }
    }
    
    {
        enum ACNotePermission_UPDATENOTE      note_update = _topicEntity.topicPerm.note_update;
        if(!(note_update==ACNotePermission_UPDATENOTE_EVERYONE||
             (ACNotePermission_UPDATENOTE_OWN==note_update&&_noteMessage.creator.isMyself))){
            //不允许更新
            _noteUpdateButton.hidden = YES;
        }
    }
}


#pragma mark -keyboardNotification
-(void)resignKeyBoard:(id)sender{
    if(sender){
        //是用户点击的
        [self _setNowReplyCommentBase:nil];
    }
    _tableViewShadeView.hidden = YES;
    [_chatInput.textView resignFirstResponder];
    _chatInput.inputState = NO;
}


-(void)keyboardWillShowFunc:(NSNotification *)noti isShow:(BOOL)bShow{
    NSDictionary *info = [noti userInfo];
    CGSize size = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    int curve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    
    //设置y跟踪键盘显示,做动画
    //直接移动 contentView
    NSInteger nShowY = 64;
    if(bShow){
        _chatInput.inputType = inputType_Text;
        nShowY -=    size.height;
    }
    [_contentView setFrame_y:nShowY];
    /*
    
    NSInteger nShowY = 0,currentHeight=0;
    if(bShow){
        currentHeight = size.height;
        _chatInput.inputType = inputType_Text;
        nShowY =    _contentView.size.height-size.height-_chatInput.size.height;
    }
    else{
        nShowY = _contentView.size.height-_chatInput.size.height;
    }
//    [_mainTableView setFrame_height:_contentView.size.height-50-_currentHeight];
    [_chatInput setFrame_y:nShowY];*/
    [UIView commitAnimations];
    
    _tableViewShadeView.hidden = !bShow;
    _chatInput.inputState = bShow;
    
//    NSLog(@"frame=\'%@\',contentSize=\'%@\',contentOffset=\'%@\'",
//          NSStringFromCGRect(self.mainTableView.frame),
//          NSStringFromCGSize(self.mainTableView.contentSize),
//          NSStringFromCGPoint(self.mainTableView.contentOffset));
    
//    
//    if (self.mainTableView.contentOffset.y+10 >= self.mainTableView.contentSize.height - self.mainTableView.size.height)
//    {
//    }
//    else
//    {
//        self.mainTableView.contentOffset = CGPointMake(0, self.mainTableView.contentSize.height - self.mainTableView.size.height);
//    }
    
//    [UIView beginAnimations:nil context:nil];
//    [UIView setAnimationDuration:0.25];
//    [UIView setAnimationCurve:7];
//    
////    [self.mainTableView setFrame_height:_contentView.size.height-50-currentHeight];
//    
//    [UIView commitAnimations];
    
//    [_mainTableView reloadData];
//    ITLog(@"\n-->>_mainTableView reloadData");
    
/*TXB    float y = self.mainTableView.contentSize.height-nShowY;
    if (y < 0)
    {
        y = 0;
    }
    [self.mainTableView setContentOffset:CGPointMake(0, y)];*/
}

-(void)keyboardWillShow:(NSNotification *)noti{
    [self keyboardWillShowFunc:noti isShow:YES];
}

-(void)keyboardWillHide:(NSNotification *)noti{
    [self keyboardWillShowFunc:noti isShow:NO];
}

#pragma mark - ACTableViewVC_Base

#if 0
//不再使用了，在显示VC前就处理了
-(void)_checkNoteObj{
    
    NSString* pNoteID = nil;
    ACNoteObject* pNoteObj = nil;
//TXB    if([_objForCheck isKindOfClass:[ACNoteObject class]]){
//        pNoteObj    =   (ACNoteObject*)_objForCheck;
//        pNoteID     =   pNoteObj.isNoteMessage?(pNoteObj.id):(((ACNoteComment*)pNoteObj).noteId);
//    }
//    else{
//        pNoteID =   (NSString*)_objForCheck;
//    }
    
    //检查状态
    NSString * const acChechNoteUrl = [NSString stringWithFormat:@"%@/rest/apis/note/%@?u=%lld",
                                       [[ACNetCenter shareNetCenter] acucomServer],
                                       pNoteID,
                                       (pNoteObj&&pNoteObj.isNoteMessage)?pNoteObj.updateTime:0];
    
//    [self.view showProgressHUD];
    
    _chatInput.hidden = YES;
    _noteDeleteButton.enabled = NO;
    _noteUpdateButton.enabled = NO;
    [ACNetCenter callURL:acChechNoteUrl forMethodDelete:NO withBlock:^(ASIHTTPRequest *request, BOOL bIsFail){
        NSString* pError  = NSLocalizedString(@"Network_Failed", nil);
        if(!bIsFail){
            NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
            ITLog(responseDic);
            int nCode = [[responseDic objectForKey:kCode] intValue];
            if(ResponseCodeType_Nomal==nCode){
                NSDictionary* pNoteDict =   [responseDic objectForKey:@"note"];
                if(pNoteObj&&pNoteObj.isNoteMessage){
                    _noteMessage    =   (ACNoteMessage*)pNoteObj;
                    if(pNoteDict.count){
                        [_noteMessage updateMessageFromDict:pNoteDict];
                    }
                }
                else if(pNoteDict.count){
                    _noteMessage    =   [[ACNoteMessage alloc] initWithDict:pNoteDict];
                }
            }
            else if(ResponseCodeType_Note_Deleted==nCode){
                pError  =   NSLocalizedString(@"This note has been removed!",nil);
            }
        }
        
        if(_noteMessage){
            [self _checkNoteDelOrUpdateButton];
            _chatInput.hidden = !_bAllowComment;
            _noteDeleteButton.enabled = YES;
            _noteUpdateButton.enabled = YES;
            
            if(_noteMessage.commentNum){
                [self LoadDataFunc];
            }
            else{
                [self LoadDataFuncEnd_WithCount:0];
            }
            return;
        }
//        [self.view hideProgressHUDWithAnimated:NO];
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
//                                                        message:pError
//                                                       delegate:self
//                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
//                                              otherButtonTitles:nil, nil];
//        alert.tag = kNote_RemovedTag;
//        [alert show];

        AC_ShowTip(pError);
    }];
}
#endif

-(void)_loadDataResponse:(ASIHTTPRequest *)request failed:(BOOL) bIsFail{
    NSInteger nCount = 0;
    if(!bIsFail){
        NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
        ITLog(responseDic);
        if(ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]){
            
            BOOL    bForHeadRefresh = ACTableViewVC_Base_RefreshType_Head==self.nRefreshType;
            if(bForHeadRefresh||ACTableViewVC_Base_RefreshType_Focus==self.nRefreshType){
                [_commentList removeAllObjects];
            }
            
            NSArray* pComments =   [responseDic objectForKey:@"comments"];
            for(NSDictionary* pDict in pComments){
                ACNoteComment *pComment = [[ACNoteComment alloc] initWithDict:pDict];
                if(pComment){
                    [_commentList addObject:pComment];
                    nCount  ++;
                }
            }
            if(bForHeadRefresh&&nCount){
                ACNoteObject* pObj = _commentList[0];
                [[ACConfigs shareConfigs] chageNoteLastTimeForRefreshNoteOrComment:pObj.updateTime];
            }
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self LoadDataFuncEnd_WithCount:nCount];
    });
}
-(void)LoadDataFunc{
    
//    if(nil==_noteMessage){
//        NSAssert(_needCheckNoteID,@"_objForCheck");
//        [self _checkNoteObj];
//        return;
//    }
    
    NSString* pStartTime =  @"";
    NSString* pEndTime =  @"";
    
    if(_commentList.count){
//        if(ACTableViewVC_Base_RefreshType_Head==self.nRefreshType){
//                pEndTime = [@(((ACNoteComment*)_commentList[0]).createTime) stringValue];
//        }
//        else
        
        if(ACTableViewVC_Base_RefreshType_Tail==self.nRefreshType){
            pStartTime = [@(((ACNoteComment*)_commentList[_commentList.count-1]).createTime) stringValue];
        }
    }
    
    
    NSString * const urlString =    [[[ACNetCenter shareNetCenter] acucomServer] stringByAppendingFormat:@"/rest/apis/note/%@/comments?s=%@&e=%@&l=%d",_noteMessage.id,pStartTime,pEndTime,20];
    
    wself_define();
    [ACNetCenter callURL:urlString forMethodDelete:NO withBlock:^(ASIHTTPRequest *request, BOOL bIsFail){
        [wself _loadDataResponse:request failed:bIsFail];
    }];

    
    
/*    NSInteger endTime = 0;
    NSInteger startTime = 0;
    
    if(ACTableViewVC_Base_RefreshType_Head==self.nRefreshType){
        if(_commentList.count){
            endTime = ((ACNoteComment*)_commentList[0]).createTime;
        }
    }
    else  if(ACTableViewVC_Base_RefreshType_Tail==self.nRefreshType&&
             _commentList.count){
        startTime = ((ACNoteComment*)_commentList[_commentList.count-1]).createTime;
    }
    
    [[ACNetCenter shareNetCenter] Notes_LoadCommentList:_noteMessage withStartTime:startTime withEndTime:endTime withLimit:20];*/
    
    
    
}

#pragma mark -notification

- (void)topicInfoChange{
    _titleLable.text = _topicEntity.showTitle;
}

-(void)Notification_Comment_Upload:(NSNotification*) noti{
//    if(noti.object==_nowSendingComment){
//        [_commentList insertObject:_nowSendingComment atIndex:0];
//        _nowSendingComment = nil;
//        [self.mainTableView reloadData];
//        [self scrollToIndex:2 animated:YES];
//        _chatInput.textView.text = @"";
//        [_chatInput fitText];
//    }
}


-(void)Notification_Comment_LoadList:(NSNotification*) noti{
    
/*    int nCount = 0;
    
    BOOL    bForHeadRefresh = ACTableViewVC_Base_RefreshType_Head==self.nRefreshType;
    NSArray* pNotes =   (NSArray*)noti.object;
    for(NSDictionary* pDict in pNotes){
        ACNoteComment *pComment = [[ACNoteComment alloc] initWithDict:pDict];
        if(pComment){
            if(bForHeadRefresh){
                [_commentList insertObject:pComment atIndex:nCount];
            }
            else{
                [_commentList addObject:pComment];
            }
            nCount  ++;
        }
    }
    
    [self LoadDataFuncEnd_WithCount:nCount];*/
}


#pragma mark --hotspotStateChange:hotspotStateChange:

-(void)hotspotStateChange:(NSNotification *)noti
{
    if (self.isOpenHotspot){
        [self.mainTableView setFrame_height:self.mainTableView.size.height-hotsoptHeight];
    }
    else{
        [self.mainTableView setFrame_height:self.mainTableView.size.height+hotsoptHeight];
    }
}

#pragma mark -IBAction
-(IBAction)goback:(id)sender{

//    if(_bUpdateNoteContent){
//        //更新Note
//        [ACNetCenter Notes_UpdateNote:_noteMessage];
//    }
//    
    if(_noteIndexPath&&(_bUpdateNoteContent||_bCommentChanged)){
        _noteMessage.hightInList = 0;
        [_superNoteListVC OnUpdateNote:_noteIndexPath];
    }
    
    [self.navigationController ACpopViewControllerAnimated:YES];
}

#pragma mark -THChatInputDelegate

-(void)_sendButtonPressedResponse:(ASIHTTPRequest *)request failed:(BOOL) bIsFail with:(ACNoteComment*) nowUseComent{
    [self.view hideProgressHUDWithAnimated:NO];
    NSString* Tip = nil;
    if(!bIsFail){
        NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
        ITLog(responseDic);
        if(ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]){
            //                           12. 评论后，键盘收起，页面不动，评论的话，就放顶部，评论回复的话，就放回复列表的末尾，页面也不动。都弹出提示：Comment added
            
            if(_nowOprateCommentCell){
                [nowUseComent sendReplySuccessWithResponseDic:responseDic];
                [self.mainTableView reloadData];
                [self.view showNomalTipHUD:NSLocalizedString(@"Comment added",nil)];
            }
            else{
                [nowUseComent sendCommentSuccessWithResponseDic:responseDic];
                _noteMessage.commentNum ++;
                [_commentList insertObject:nowUseComent atIndex:0];
                [self.mainTableView reloadData];
                [self scrollToIndex:2 animated:YES];
            }
            
            
            //更新时间
            [[ACConfigs shareConfigs] chageNoteLastTimeForNewUpdateTime:nowUseComent.updateTime];
            
            //                           dispatch_async(dispatch_get_main_queue(), ^{
            _bCommentChanged = YES;
            [self _setNowReplyCommentBase:nil];
            return;
            //                           });
        }
        else{
            Tip = responseDic[@"description"];
        }
    }
    [self.view showNomalTipHUD:Tip?Tip:NSLocalizedString(@"Check_Network", nil)];
}

- (void) sendButtonPressed:(id)sender{
   
    
    NSString *textTmp = [_chatInput.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    [self resignKeyBoard:nil];
   
    if ([textTmp length] ==0){
        return;
    }
    
    NSDictionary* pPostInfo = nil;
    ACNoteComment* nowUseComent = nil;
    {
        if(_nowOprateCommentCell){
            nowUseComent =  _nowOprateCommentCell.noteComment;
            NSString* pOld =    nowUseComent.content; //内部需要新的content，避免大修改，临时使用
            nowUseComent.content  =   textTmp;
            pPostInfo = [nowUseComent getPostDictWithReply:_nowOprateCommentCell.noteCommentBase];
            nowUseComent.content  = pOld;
        }
        else{
            nowUseComent    =   [[ACNoteComment alloc] init];
            nowUseComent.content  =   textTmp;
            pPostInfo = [nowUseComent getPostDictWithReply:nil];
        }
    }
    
    [self.view showProgressHUD];
    ITLog(pPostInfo);

    wself_define();
    [ACNetCenter callURL:[NSString stringWithFormat:@"%@/rest/apis/note/%@/comment/upload",[[ACNetCenter shareNetCenter] acucomServer],_noteMessage.id]
                  forPut:NO
            withPostData:pPostInfo
               withBlock:^(ASIHTTPRequest *request, BOOL bIsFail){
                   [wself _sendButtonPressedResponse:request failed:bIsFail with:nowUseComent];
            }];
        
}

- (void) textViewDidChange:(UITextView*)textView{
    if(textView.text.length==0){
        [self _setNowReplyCommentBase:nil];
    }
}

#pragma mark UITableViewDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(ACTableViewVC_Base_RefreshType_Init==self.nRefreshType||nil==_noteMessage){
        //还没有加载
        return 0;
    }
    
    return 1+1+_commentList.count;
//    return [_noteMessage.imgs_Videos_List count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(0==indexPath.row){
        ACNoteListVC_Cell *cell =   [ACNoteListVC_Cell loadCellFromTable:tableView withSuperVC:self];
        cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
        cell.selectedBackgroundView.backgroundColor = [UIColor clearColor];
        [cell setNoteMessage:_noteMessage forDetail:YES forTimeLineList:NO withTopic:_topicEntity];
        [cell setHighlight:_noteHightLights];
        return cell;
    }
    
    if(1==indexPath.row){
        
        static NSString* pCommentCell_Tip_ID =   @"ACNoteComment_Cell_Comment";
        UITableViewCell* pCell = [tableView dequeueReusableCellWithIdentifier:pCommentCell_Tip_ID];
        if(nil==pCell){
            pCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:pCommentCell_Tip_ID];
            pCell.backgroundColor   =   UIColor_RGB(0xf6,0xf7,0xf7);
            //#f6f7f7
            pCell.selectedBackgroundView = [[UIView alloc] initWithFrame:pCell.bounds];
            pCell.selectedBackgroundView.backgroundColor = [UIColor clearColor];
        }
        pCell.textLabel.text = NSLocalizedString(@"Comment",nil);
        return pCell;

    }

    return  [ACNoteCommentCell loadCellFromTable:tableView
                                 withCommentBase:_commentList[indexPath.row-2]
                                      andSuperVC:self
                                       withIndex:indexPath.row];

//    ACNoteCommentCell* pCell =  [ACNoteCommentCell loadCellFromTable:tableView];
//    pCell.noteComment =  _commentList[indexPath.row-2];
//    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(0==indexPath.row){
        _noteMessage.hightInList = 0;
        CGFloat nRet = [ACNoteListVC_Cell getCellHeightWithNoteMessage:_noteMessage forDetail:YES];
        _noteMessage.hightInList = 0;
         return nRet+2;
    }
    
    if(1==indexPath.row){
        return tableView.rowHeight;
    }
    
    return [ACNoteCommentCell getNoteCommentHight:_commentList[indexPath.row-2]];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.row>1){
        [self selectedCommentCell:[tableView cellForRowAtIndexPath:indexPath]
                     forLongPress:NO];
    }
}

/*

-(void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle==UITableViewCellEditingStyleDelete) {
        _pNeedDelCommentIndexPath   =   indexPath;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil)
                                                        message:NSLocalizedString(@"Delete this comment?", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"Confirm",nil), nil];
        alert.tag = kComemnt_DeleteTag;
        [alert show];
    }
}

-(UITableViewCellEditingStyle )tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.row<2||_nCommentDelPer==ACNotePermission_DELETECOMMENT_NONE){
        return UITableViewCellEditingStyleNone;
    }
    
    if(ACNotePermission_DELETECOMMENT_EVERYONE==_nCommentDelPer||
       (((ACNoteComment*)_commentList[indexPath.row-2]).creator.isMyself)){
        return UITableViewCellEditingStyleDelete;
    }
    
    return UITableViewCellEditingStyleNone;
}
*/

#pragma mark operation

-(void)_setNowReplyCommentBase:(ACNoteCommentBase*)commentBase{
    
    if(_chatInput.textView.text.length){
        [_chatInput setText:@""];
    }

    if(commentBase==_nowReplyCommentBase){
        //没有变化
        return;
    }
    _nowReplyCommentBase =  commentBase;
    if(commentBase){
        [_chatInput setPlaceholderText:[NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Reply to", nil), commentBase.creator.name]];
    }
    else{
        _nowOprateCommentCell = nil;
        [_chatInput setPlaceholderText:nil];
    }
}

-(void)moreReplies:(ACNoteComment*)comment{
    [self.view showNetLoadingWithAnimated:YES];
    
    NSString* pStart = @"";
    if(comment.loadedCommentReplys.count){
        pStart =    [@(comment.loadedCommentReplys.firstObject.createTime) stringValue];
    }
    NSString * const urlString =    [[[ACNetCenter shareNetCenter] acucomServer] stringByAppendingFormat:@"/rest/apis/note/%@/comments?s=%@&e=%@&l=%d",comment.id,pStart,@"",ACNoteCommentReply_LoadMore_MaxCount];
    
    wself_define();
    [ACNetCenter callURL:urlString forMethodDelete:NO withBlock:^(ASIHTTPRequest *request, BOOL bIsFail){
        [wself.view hideProgressHUDWithAnimated:YES];
        if(!bIsFail){
            NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
            ITLog(responseDic);
            if(ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]){
                [comment moreRepliesLoaded:[ACNoteCommentReply loadReplysWithDict:responseDic]];
                [wself.mainTableView reloadData];
            }
        }
    }];

}

#define comment_LongPress_ActionSheet_ButtonIndex_Copy      1


-(void)selectedCommentCell:(ACNoteCommentCell*)commentCell
              forLongPress:(BOOL)forLongPress{ //选择
    
    _nowOprateCommentCell   =   commentCell;
    ACNoteCommentBase* commentBase =    commentCell.noteCommentBase;
    
//    BOOL isNoteComment = [commentBase isKindOfClass:[ACNoteComment class]];
    if(forLongPress||commentBase.creator.isMyself){
        
//        3.C长按B的评论，弹出菜单项： 复制 回复 取消
//        4. C单击或长按C自己的评论，或者评论回复，弹出菜单： 复制  删除 回复 取消

        _nowReplyCommentBase =  commentBase;
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:nil];
        [sheet addButtonWithTitle:NSLocalizedString(@"Copy", nil)];
        
        if(_bAllowComment){
            [sheet addButtonWithTitle:NSLocalizedString(@"Reply", nil)];
        }
        
        if(_nCommentDelPer!=ACNotePermission_DELETECOMMENT_NONE&&(
           ACNotePermission_DELETECOMMENT_EVERYONE==_nCommentDelPer||
           commentBase.creator.isMyself)){
            [sheet addButtonWithTitle:NSLocalizedString(@"Delete", nil)];
        }
        
        [sheet showInView:self.view];
        return;
    }
    
    if(_bAllowComment){
        [self _setNowReplyCommentBase:commentBase];
        [_chatInput.textView becomeFirstResponder];
    }
    
    
    /*
     
     
     note 评论回复功能要点：
     
     9. 点击note评论或者评论回复的通知时，打开此note的详情，如果当前正打开着这个note，就重新刷一遍
     
     10. 手机在通知设置里，加一项是Note Comment, 默认打开，可以关闭（iphone的服务器需要来弄一下）

     */
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(actionSheet.cancelButtonIndex==buttonIndex){
        return;
    }
    
    if(comment_LongPress_ActionSheet_ButtonIndex_Copy==buttonIndex){
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = _nowReplyCommentBase.contentForCopy;
//        [self.view showNomalTipHUD:NSLocalizedString(@"Copied", nil)];
        _nowReplyCommentBase = nil;
        return;
    }
    
    NSString* pButtonTitle =    [actionSheet buttonTitleAtIndex:buttonIndex];
    if([pButtonTitle isEqualToString:NSLocalizedString(@"Reply", nil)]){
        ACNoteCommentBase*  commentBase =   _nowReplyCommentBase;
        _nowReplyCommentBase = nil;
        
        [self _setNowReplyCommentBase:commentBase];
        [_chatInput.textView becomeFirstResponder];
        return;
    }
    
    if([pButtonTitle isEqualToString:NSLocalizedString(@"Delete", nil)]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil)
                                                        message:NSLocalizedString(@"Delete this comment?", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"Confirm",nil), nil];
        alert.tag = kComemnt_DeleteTag;
        [alert show];
    }
    _nowReplyCommentBase = nil;
}

#pragma mark -UIAlertView

-(void)_deleteCommentResponse:(ASIHTTPRequest *)request failed:(BOOL) bIsFail{
    
    NSString* Tip = nil;
    [self.view hideProgressHUDWithAnimated:YES];
    if(!bIsFail){
        NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
        ITLog(responseDic);
        if(ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]){
            
            if(_nowOprateCommentCell.noteComment==_nowOprateCommentCell.noteCommentBase){
                //删除Commnet
                [_commentList removeObject:_nowOprateCommentCell.noteComment];
                //                                       [_commentList removeObjectAtIndex:_nowOprateCommentCell.commentBaseIndex-2];
                if(_noteMessage.commentNum){
                    //                _noteMessage.commentNum = _noteMessage.commentNum-1;
                    _noteMessage.commentNum --;
                }
                //不能使用这个方法删除                                       [self.mainTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_nowOprateCommentCell.commentBaseIndex inSection:0]]
                //                                                                 withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            else{
                [_nowOprateCommentCell.noteComment removeReply:(ACNoteCommentReply*)_nowOprateCommentCell.noteCommentBase];
            }
            
            [self.mainTableView reloadData];
            _nowOprateCommentCell = nil;
            _bCommentChanged = YES;
            return;
        }
        else{
            Tip = responseDic[@"description"];
        }
    }
    [self.view showProgressHUDNoActivityWithLabelText:Tip?Tip:NSLocalizedString(@"Check_Network", nil) withAfterDelayHide:0.8];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if (buttonIndex == alertView.firstOtherButtonIndex){
        
        if (alertView.tag == kNote_DeleteTag){
            //删除Note
            if(_noteIndexPath){
                [_superNoteListVC onDeleteNote:_noteIndexPath];
            }
            [ACNetCenter Notes_DeleteNote:_noteMessage];
            [self.navigationController ACpopViewControllerAnimated:YES];
            return;
        }
        
        if(kComemnt_DeleteTag==alertView.tag){

            [self.view showProgressHUD];
            wself_define();
            [ACNetCenter callURL:[NSString stringWithFormat:@"%@/rest/apis/note/%@/comment/%@",[[ACNetCenter shareNetCenter] acucomServer],_noteMessage.id,_nowOprateCommentCell.noteCommentBase.id]
                 forMethodDelete:YES
                       withBlock:^(ASIHTTPRequest *request, BOOL bIsFail) {
                           [wself _deleteCommentResponse:request failed:bIsFail];
                        }];
            }
    }

}

#pragma mark --update note

-(IBAction)onUpdateNote:(id)sender{
    ACNoteUpdateVC* noteUpdateVC    =      [[ACNoteUpdateVC alloc] init];
    noteUpdateVC.superVC = self;
    [self.navigationController pushViewController:noteUpdateVC animated:YES];
}

-(IBAction)onDeleteNote:(id)sender{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil)
                                                    message:NSLocalizedString(@"Delete this Note?", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                          otherButtonTitles:NSLocalizedString(@"Confirm",nil), nil];
    alert.tag = kNote_DeleteTag;
    [alert show];
}

-(void)noteContentUpdated{
    _noteMessage.hightInList = 0;
    _bUpdateNoteContent = YES;
    [ACNetCenter Notes_UpdateNote:_noteMessage];
    [self.mainTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
