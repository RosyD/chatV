#import "ACChatMessageViewController.h"
#import "ACWhoReadViewController.h"
#import "ACMessageDB.h"
#import "ACNetCenter.h"
#import "ACFileBrowserViewController.h"
#import "ACAcuLearnWebViewController.h"
#import "UINavigationController+Additions.h"
#import "ACChatMessageViewController+Tap.h"

#if DEBUG
    #define displayImageWithFileMessage_LoadLimit 7
#else
    #define displayImageWithFileMessage_LoadLimit 15 //加载限制,不能<5
#endif


NSString *const kAudioPlayFinishedNotification  =   @"kAudioPlayFinishedNotification";


@implementation ACChatMessageViewController(Tap)

#pragma mark -previewText
-(void)previewText:(NSString*)pText
//-(void)previewTextWithTextMessage:(ACTextMessage *)textMessage
{
    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];
    view.alpha = 0;
    view.backgroundColor = [UIColor whiteColor];
    view.tag = kPreviewViewTag;
    [self.view addSubview:view];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(previewTextClose)];
    [view addGestureRecognizer:tap];
    
    CGRect rect = view.bounds;
    rect.origin.y += 20;
    rect.size.height -= 20;
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:rect];
    [view addSubview:scrollView];
    
    rect.origin.x += 15;
    rect.size.width -= 30;
    rect.size.height -= 10;
    UILabel *label = [[UILabel alloc] initWithFrame:rect];
    [scrollView addSubview:label];
    
    label.text = pText;//textMessage.content;
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:22];
    [label setAutoresizeWithLimitWidth:label.size.width];
    scrollView.contentSize = CGSizeMake(scrollView.size.width, label.size.height+10>scrollView.size.height?label.size.height+10:scrollView.size.height);
    label.center = CGPointMake(scrollView.contentSize.width/2, scrollView.contentSize.height/2);
    
    [UIView animateWithDuration:.3 animations:^{
        view.alpha = 1;
    }];
}

-(void)previewTextClose
{
    UIView *view = [self.view viewWithTag:kPreviewViewTag];
    [UIView animateWithDuration:.3 animations:^{
        view.alpha = 0;
    } completion:^(BOOL finished) {
        if (view && view.superview != nil)
        {
            [view removeFromSuperview];
        }
    }];
}

#pragma mark - display image

-(NSInteger)_displayImageWithFileMessageFindItem:(ACFileMessageCache*)pMsgCache forInsert:(BOOL)forInsert{
    
    return [_needViewImageCollections indexOfObject:pMsgCache
                                      inSortedRange:NSMakeRange(0,_needViewImageCollections.count)
                                            options:forInsert?(NSBinarySearchingFirstEqual|NSBinarySearchingInsertionIndex):NSBinarySearchingFirstEqual
                                    usingComparator:^(ACFileMessageCache* obj1, ACFileMessageCache* obj2) {
                                        
                                        if (obj1.seq > obj2.seq) {
                                            return (NSComparisonResult)NSOrderedDescending;
                                        }
                                        
                                        if (obj1.seq < obj2.seq) {
                                            return (NSComparisonResult)NSOrderedAscending;
                                        }
                                        return (NSComparisonResult)NSOrderedSame;
                                    }];
}

-(NSInteger)_displayImageWithFileMessageAddCache:(ACFileMessageCache*)pMsgCache{
    NSInteger nRet = [self _displayImageWithFileMessageFindItem:pMsgCache forInsert:NO];
    if(nRet>=_needViewImageCollections.count){
        nRet = [self _displayImageWithFileMessageFindItem:pMsgCache forInsert:YES];
        [_needViewImageCollections insertObject:pMsgCache atIndex:nRet];
        [ACMessageDB saveFileMessageCacheToDB:pMsgCache WithTopicEntityID:_topicEntity.entityID];
    }
    return nRet;
}


-(void)_displayImageWithFileMessageShowMWPhotoBrowserWithMsgCache:(ACFileMessageCache*)pMsgCache
                         withMWPhotoBrowser_NET_Images_load_state:(int)MWPhotoBrowser_NET_Images_load_state{
    
    if(0==_needViewImageCollections.count) {
        [self.view showNetErrorHUD];
        _needViewImageCollections = nil;
        return;
    }
    
    NSInteger nIndex = [self _displayImageWithFileMessageAddCache:pMsgCache];
    
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self browserType:BrowserType_DefineBrowser];
    if(nIndex<_needViewImageCollections.count){
        [browser setInitialPageIndex:nIndex];
    }
    browser.displayActionButton = YES;
    browser.NET_Images_load_state = MWPhotoBrowser_NET_Images_load_state;
    UINavigationController *navC = [[UINavigationController alloc] initWithRootViewController:browser];
    [self ACpresentViewController:navC animated:YES completion:nil];
    
    if(0==(MWPhotoBrowser_NET_Images_load_state&MWPhotoBrowser_NET_Images_load_state_allow)){
        AC_ShowTip(NSLocalizedString(@"Slide image to preview more cached images.", nil));
    }
}

-(int)_displayImageWithFileMessageGetData{
    
    int nRet = 0;
    
    if(_netPreLoadImageCollections.count<displayImageWithFileMessage_LoadLimit){
        //取得加载状态
        if(0==_netPreLoadImageCollectionsLoadDir){
            nRet = MWPhotoBrowser_NET_Images_load_state_Load_End_All;
        }
        else if(_netPreLoadImageCollectionsLoadDir>0){
            nRet    =   MWPhotoBrowser_NET_Images_load_state_Load_End_Tail;
        }
        else{
            nRet    =   MWPhotoBrowser_NET_Images_load_state_Load_End_Head;
        }
    }
    
    for (NSDictionary *dic in _netPreLoadImageCollections){
        [self _displayImageWithFileMessageAddCache:[ACFileMessageCache getFileMessageCacheWithDict:dic]];
    }
    
#if 0 //def ACUtility_Need_Log
    
    NSMutableString* pBuffer = [[NSMutableString alloc] init];
    [pBuffer appendFormat:@"[%ld] ",_needViewImageCollections.count];
    for(ACFileMessageCache *pMsgCache in _needViewImageCollections){
        [pBuffer appendFormat:@"%ld ",pMsgCache.seq];
    }
    NSLog(@"%@",pBuffer);
#endif
    
    if(_topicEntity.topicPerm.destruct == ACTopicPermission_DestructMessage_Allow){
        //处理阅后即焚
        for(NSInteger n=0;n<_needViewImageCollections.count;n++){
            ACFileMessageCache *pMsgCache = _needViewImageCollections[n];
            if(pMsgCache.seq>_currentSeq){
                break;
            }
            [_needViewImageCollections removeObjectAtIndex:n];
            nRet    |=  MWPhotoBrowser_NET_Images_load_state_Load_End_Head;
            n--;
        }
    }
    
    _netPreLoadImageCollections = nil;
    _netPreLoadImageCollectionsLoadDir = 0;
    
    return nRet;
}

-(void)_displayImageWithFileMessageLoadFromServer:(int)dir
                                     withMsgCache:(ACFileMessageCache*)pMsgCache{
    /*https://acucom.acucom.co/rest/apis/chat/ae2dc40c10e62be24b41f5750c684667/topics?o=24&l=5&r=2&t=image&w=i
     @PathVariable(value = "topicEntityId") String topicEntityId,
     @RequestParam(value = "o", required = false) Long start,
     @RequestParam(value = "l", required = false) Integer limit,
     @RequestParam(value = "r", required = false) Long readSequence,
     @RequestParam(value = "t", required = false) String type,
     @RequestParam(value = "w", required = false) String dir,
     
     b=back
     f=forward
     i=initial
     
     */
    
    
    if(0==dir){
        //第一次加载
        _needViewImageCollections =     [[NSMutableArray alloc] init];
        [self.view showNetLoadingWithAnimated:YES];
    }
    
    NSString *pURL = [NSString stringWithFormat:@"%@/topics?o=%ld&l=%d&t=image&w=%@",
                      [ACNetCenter urlHead_ChatWithTopic:_topicEntity],
                      pMsgCache.seq,displayImageWithFileMessage_LoadLimit,dir?(dir>0?@"f":@"b"):@"i"];
    
    wself_define();
    [ACNetCenter callURL:pURL forMethodDelete:NO  withBlock:^(ASIHTTPRequest *request, BOOL bIsFail){
        
        int MWPhotoBrowser_NET_Images_load_state = 0;
        
        if(!bIsFail){
            NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
            if(ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]){
                
                sself_define();
                if(sself){
                    @synchronized(self){
                        sself->_netPreLoadImageCollections =   [responseDic objectForKey:kTopics];
                        sself->_netPreLoadImageCollectionsLoadDir = dir;
                    }
                }
                
                if(0==dir){
                    MWPhotoBrowser_NET_Images_load_state = [wself _displayImageWithFileMessageGetData];
                }
            }
        }
        if(0==dir){
            [wself.view hideProgressHUDWithAnimated:NO];
            [wself _displayImageWithFileMessageShowMWPhotoBrowserWithMsgCache:pMsgCache
                                    withMWPhotoBrowser_NET_Images_load_state:MWPhotoBrowser_NET_Images_load_state|MWPhotoBrowser_NET_Images_load_state_allow];
        }
    }];
}


-(void)displayImageWithFileMessage:(ACFileMessage *)fileMessage
{
    _needViewImageCollections = nil;
    _netPreLoadImageCollections = nil;
    _netPreLoadImageCollectionsLoadDir = 0;
    
    if(fileMessage.seq==ACMessage_seq_DEF){
        ITLogEX(@"fileMessage.seq=%ld",fileMessage.seq);
        return;
    }
    
    ACFileMessageCache* pMsgCache = [ACFileMessageCache getFileMessageCacheWithFileMessage:fileMessage];
    
    if([ASIHTTPRequest isValidNetWork]){
        [self _displayImageWithFileMessageLoadFromServer:0 withMsgCache:pMsgCache];
    }
    else{
        long firstSeq = -1L;
        if(_topicEntity.topicPerm.destruct == ACTopicPermission_DestructMessage_Allow){
            firstSeq = _currentSeq;
        }
        
        _needViewImageCollections   =   [ACMessageDB getACFileMessageCacheFromDBWithTopicEntityID:_topicEntity.entityID
                                                                                         firstSeq:firstSeq];
        
        //        NSLog(@"%ld:%@ %@",pMsgCache.seq,pMsgCache.messageID,pMsgCache.resourceID);
        //
        //        for(ACFileMessageCache* pTemp in _needViewImageCollections){
        //            NSLog(@"%ld:%@ %@",pTemp.seq,pTemp.messageID,pTemp.resourceID);
        //        }
        [self _displayImageWithFileMessageShowMWPhotoBrowserWithMsgCache:pMsgCache
                                withMWPhotoBrowser_NET_Images_load_state:MWPhotoBrowser_NET_Images_load_state_Load_End_All];
    }
    
    /*
     _needViewImageCollections = nil;
     NSMutableArray* pImageMessages = [[NSMutableArray alloc] init];
     
     NSInteger nIndex = -1;
     //取得Image信息
     for(ACMessage* msg in _dataSourceArray){
     if(ACMessageEnumType_Image==msg.messageEnumType){
     if(nIndex<0&&fileMessage==msg){
     nIndex =    pImageMessages.count;
     }
     [pImageMessages addObject:msg];
     }
     }
     
     for(ACMessage* msg in _unSendMsgArray){
     if(ACMessageEnumType_Image==msg.messageEnumType){
     if(nIndex<0&&fileMessage==msg){
     nIndex =    pImageMessages.count;
     }
     [pImageMessages addObject:msg];
     }
     }
     
     if(pImageMessages.count>1){
     _needViewImageCollections   =   pImageMessages;
     MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self browserType:BrowserType_DefineBrowser];
     if(nIndex>0){
     [browser setInitialPageIndex:nIndex];
     }
     browser.displayActionButton = YES;
     UINavigationController *navC = [[UINavigationController alloc] initWithRootViewController:browser];
     [self ACpresentViewController:navC animated:YES completion:nil];
     return;
     }
     
     NSString* pFilePathName = nil;
     NSString* pURL = [ACNetCenter getdownloadURL:[[ACNetCenter shareNetCenter] getUrlWithEntityID:fileMessage.topicEntityID messageID:fileMessage.messageID resourceID:fileMessage.resourceID] withFileLength:fileMessage.length];
     
     if (fileMessage.directionType == ACMessageDirectionType_Send)
     {
     pFilePathName = [ACAddress getAddressWithFileName:fileMessage.resourceID fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
     }
     
     [self MWPhotoBrowser_ShowPhotoFile:pFilePathName withURL:pURL];*/
}




#pragma mark - play audio
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    //让后台的APP继续播放音乐
    [player stop];
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    _currentPlayingAudioMsg.isPlaying = NO;
    
    [ACUtility postNotificationName:kAudioPlayFinishedNotification object:_currentPlayingAudioMsg];
    _currentPlayingAudioMsg = nil;
}

-(void)playAudioWithFilePath:(NSString *)filePath audioMsg:(ACFileMessage *)audioMsg
{
    BOOL isStop = NO;
    if (_currentPlayingAudioMsg == audioMsg)
    {
        isStop = YES;
    }
    if (_currentPlayingAudioMsg != nil)
    {
        _currentPlayingAudioMsg.isPlaying = NO;
        
        [ACUtility postNotificationName:kAudioPlayFinishedNotification object:_currentPlayingAudioMsg];
        _currentPlayingAudioMsg = nil;
    }
    if (isStop)
    {
        [_audioPlayer stop];
        return;
    }
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    NSError *error = nil;
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:filePath] error:&error];
    if (error)
    {
        ITLog(error);
    }
    else
    {
        _currentPlayingAudioMsg = audioMsg;
        audioMsg.isPlaying = YES;
        
        _audioPlayer.volume = .8;
        _audioPlayer.delegate = self;
        [_audioPlayer play];
    }
}

#pragma mark -fileBrowser
-(void)fileBrowserWithFileMsgData:(ACFileMessage *)fileMsg
{
    ACFileBrowserViewController *fileBrowserVC = [[ACFileBrowserViewController alloc] init];
    fileBrowserVC.fileMsg = fileMsg;
    [self.navigationController pushViewController:fileBrowserVC animated:YES];
}

#pragma mark -moviePlay

-(void)moviePlayWithFilePath:(NSString *)filePath
{
    _currentVideoPath = filePath;
    _moviePlayerVC = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:filePath]];
    [_moviePlayerVC.moviePlayer shouldAutoplay];
    [self ACpresentMoviePlayerViewControllerAnimated:_moviePlayerVC];
}

- (void)videoHasFinishedPlaying:(NSNotification *)paramNotification{
    /* Find out what the reason was for the player to stop */
    NSNumber *reason =
    [paramNotification.userInfo
     valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    if (reason != nil){
        NSInteger reasonAsInteger = [reason integerValue];
        switch (reasonAsInteger){
            case MPMovieFinishReasonPlaybackEnded:{
                /* The movie ended normally */
                break; }
            case MPMovieFinishReasonPlaybackError:{
                /* An error happened and the movie ended */
                [[NSFileManager defaultManager] removeItemAtPath:_currentVideoPath error:nil];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"Movie_Play_Fail", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
                [alert show];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_mainTableView reloadData];
                    ITLog(@"-->>_mainTableView reloadData");
                });
                break;
            }
            case MPMovieFinishReasonUserExited:{
                /* The user exited the player */
                break;
            }
        }
        NSLog(@"Finish Reason = %ld", (long)reasonAsInteger);
    } /* if (reason != nil){ */
}

-(void)showWhoReadVCWithMsg:(ACMessage*)pMsg;{
    ACWhoReadViewController *whoReadVC = [[ACWhoReadViewController alloc] init];
    whoReadVC.topicEntity = _topicEntity;
    whoReadVC.topicEntityID = pMsg.topicEntityID;
    whoReadVC.seq = pMsg.seq;
    AC_MEM_Alloc(whoReadVC);
    [self.navigationController pushViewController:whoReadVC animated:YES];
}


-(void)openUrl:(NSURL *)url{
    ACAcuLearnWebViewController *acuLearnWebVC = [[ACAcuLearnWebViewController alloc] initWithUrlString:url.absoluteString];
    acuLearnWebVC.titleString = @"";
    [self.navigationController pushViewController:acuLearnWebVC animated:YES];
}


-(void)_openTelMailFunc:(NSString *)tel_mail forTel:(BOOL)bForTel{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:tel_mail
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* cancel=[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction*action){}];
    [alert addAction:cancel];
    
    UIAlertAction* CallAction = nil;
    if(bForTel){
        CallAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Call",nil)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           NSString *telString = [NSString stringWithFormat:@"tel://%@",tel_mail];
                                                           [[UIApplication sharedApplication] openURL:[NSURL URLWithString:telString]];
                                                           
                                                       }];
    }
    else{
        CallAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Mail",nil)
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
                                                mailVC.mailComposeDelegate = self;
                                                [mailVC setToRecipients:@[tel_mail]];
                                                [self ACpresentViewController:mailVC animated:YES completion:nil];
                                            }];
    }
    
    [alert addAction:CallAction];
    [self ACpresentViewController:alert animated:YES completion:nil];

}

-(void)openTel:(NSString *)tel{
    [self _openTelMailFunc:tel forTel:YES];
}

-(void)openMail:(NSString*)mail{
    
    if (![MFMailComposeViewController canSendMail]){
        AC_ShowTipFunc(nil, NSLocalizedString(@"Can\'t send mail", nil));
        return;
    }
    [self _openTelMailFunc:mail forTel:NO];
}

#pragma mark -mailComposeDelegate
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if(MFMailComposeResultFailed==result){
        AC_ShowTipFunc(nil, NSLocalizedString(@"Mail failed", nil));
    }
    [self ACdismissViewControllerAnimated:YES completion:nil];
}


@end
