//
//  ACChatMessageTableViewCell.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-10.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACChatMessageTableViewCell.h"
#import "ACMessage.h"
#import "UIView+Additions.h"
#import "UIImageView+WebCache.h"
#import "ACUser.h"
#import "ACUserDB.h"
#import "NSString+Additions.h"
#import "ACChatMessageViewController.h"
#import "ACAddress.h"
#import "ACNetCenter.h"
#import "ACMapBrowerViewController.h"
#import "ACParticipantInfoViewController.h"
#import "ACReadCount.h"
#import "ACReadSeq.h"
#import "ACWhoReadViewController.h"
#import "ACTransmitViewController.h"
#import "ACGifBrowserViewController.h"
#import "ACDataCenter.h"
#import "UINavigationController+Additions.h"
#import "AHHyperlinkScanner.h"
#import "AHMarkedHyperlink.h"
#import "ACChatMessageViewController+Board.h"
#import "ACChatMessageViewController+Input.h"
#import "ACChatMessageViewController+Tap.h"
#import "ACVideoCall.h"

//#define kScreen_Width     [[UIScreen mainScreen] bounds].size.width //屏幕的宽
///#define kSystemMsg_BK_Width     (kScreen_Width - 100)
#define kSystemMsg_BK_Width     (230*kScreen_Width/320)
///#define kSystemMsgLimitWidth    (kSystemMsg_BK_Width-40)     //系统消息限制宽度
#define kSystemMsgLimitWidth    ((230-40)*kScreen_Width/320)     //系统消息限制宽度

#define kAutoresizeLimitWidth   (kScreen_Width-180)//发送文字背景的限制的宽度
///#define kAutoresizeLimitWidth   (160*kScreen_Width/320)
#define kFileWidth              35
#define kFileHeight             50

#define kSendTextLabelBaseX     26
#define kReceiveTextLabelBaseX  74

//#define kSendChatContentImageViewBaseX      200
#define kSendChatContentImageViewBaseX      150 //200
#define kReceiveChatContentImageViewBaseX   74

#define kChatContentBgImageViewBaseY                11
#define kSendChatContentBgImageViewBaseHeight       34
#define kReceiveChatContentBgImageViewBaseHeight    31

#define kPlayImage      [UIImage imageNamed:@"videoPlay.png"]


#define NewMsgFlag_Hight    30 //_newMsgFlagView 高度

@implementation ACChatMessageTableViewCell


-(void)_clearRecognizer{
    for (UIGestureRecognizer *ges in _chatContentBgImageView.gestureRecognizers){
        [_chatContentBgImageView removeGestureRecognizer:ges];
    }
    for (UIGestureRecognizer *ges in _iconImageView.gestureRecognizers){
        [_iconImageView removeGestureRecognizer:ges];
    }
    for (UIGestureRecognizer *ges in _gifImageView.gestureRecognizers) {
        [_gifImageView removeGestureRecognizer:ges];
    }
    
    for (UIGestureRecognizer *ges in self.gestureRecognizers) {
        [self removeGestureRecognizer:ges];
    }
}

-(void)_addObserver_kProgress{
    if(ACMessageEnumType_Text!=_messageData.messageEnumType&&
       ACMessageEnumType_Image!=_messageData.messageEnumType&&
       [_messageData isKindOfClass:[ACFileMessage class]]){
        [_messageData addObserver:self
                       forKeyPath:kProgress
                          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
//        ACFileMessage* pfilemsg = (ACFileMessage*)_messageData;
//        [[ACNetCenter shareNetCenter] checkDownloadingWithFileMessage:pfilemsg];
//        _contentProgressView.hidden = !(pfilemsg.isDownloading);
    }
}

-(void)_removeObserver_kProgress{
    if(ACMessageEnumType_Text!=_messageData.messageEnumType&&
       ACMessageEnumType_Image!=_messageData.messageEnumType&&
       [_messageData isKindOfClass:[ACFileMessage class]]){
        [_messageData removeObserver:self forKeyPath:kProgress];
    }
}

- (void)dealloc
{
    [self _removeObserver_kProgress];
    
//    if (_messageData &&
//        (_messageData.messageEnumType == ACMessageEnumType_Video ||
//         _messageData.messageEnumType == ACMessageEnumType_File ||
//         _messageData.messageEnumType == ACMessageEnumType_Audio) && ((ACFileMessage *)_messageData).progress != 1)
//    {
//        [_messageData removeObserver:self forKeyPath:kProgress];
//    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self _clearRecognizer];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
//    [_iconImageView.layer setMasksToBounds:YES];
//    [_iconImageView.layer setCornerRadius:5.0];
    [_iconImageView setToCircle];
    
    [_isVideoImageView setHidden:YES];
    [_contentLengthLabel setHidden:YES];
    [_dateView setHidden:YES];
    [_contentView setFrame_y:0];
    [_contentView setFrame_width:kScreen_Width];
    [_contentProgressView setHidden:YES];
    UIImage* pBkImageTemp = [[UIImage imageNamed:@"it_msg_time_bg.png"] stretchableImageWithLeftCapWidth:35 topCapHeight:8];
    [_dateBgImageView setImage:pBkImageTemp];
    [_newMsgFlagBkView setImage:pBkImageTemp];
//    _gifView = [[SvGifView alloc] initWithFrame:CGRectZero];
//    [self.contentView addSubview:_gifView];
    _gifImageView = [[YLImageView alloc] init];
    [_gifImageView.layer setCornerRadius:5.0];
    [_gifImageView.layer setMasksToBounds:YES];
    [_contentView addSubview:_gifImageView];
//    _chatContentLabel.delegate = self;
    _activityView.hidden = YES;
    
//    _chatContentLabel.linkHighlightColor = [UIColor orangeColor];
    _chatContentLabel.userInteractionEnabled = NO;
    ///
//    [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.bottom.offset(0);
//    }];
}

+(CGSize)_getImageShowSize:(ACFileMessage*)msg{
    //取得突破实际显示的范围，最高或最宽为 kAutoresizeLimitWidth
    CGSize ret = CGSizeMake(kAutoresizeLimitWidth, kAutoresizeLimitWidth);
    
    if(2==msg.smallSizeArray.count){
        int     fSize_W =   [msg.smallSizeArray[0] intValue];
        int     fSize_H =   [msg.smallSizeArray[1] intValue];
        if(fSize_W>fSize_H){
            ret.height  =   kAutoresizeLimitWidth*fSize_H/fSize_W;
            if(ret.height<50){
                ret.height  =   50;
            }
        }
        else{
            ret.width   =   kAutoresizeLimitWidth*fSize_W/fSize_H;
            if(ret.width<50){
                ret.width = 50;
            }
        }
        if(msg.content.length&&ret.width<100){
            //如果有文字
            ret.width = 100;
        }
    }
    
    return ret;
}

#define img_video_Location_bk_img_hight 36

+(float)getCellHeightWithMessage:(ACMessage *)message  withNewMsgSeq:(long)lNewMsgSequence withNewMsgSeqFor99_Plus:(long)lNewMsgSequenceFor99_Plus;
{
    float height = 0;
    switch (message.messageEnumType)
    {
        case ACMessageEnumType_Text:
        case ACMessageEnumType_ShareLocation:
        case ACMessageEnumType_Videocall:
        case ACMessageEnumType_Audiocall:
        case ACMessageEnumType_Unknow:
        {
            NSString* pContent = @" ";
            if(ACMessageEnumType_Unknow==message.messageEnumType){
                pContent    =   ACMessageEnumType_Unknow_String;
            }
            else{
                ACTextMessage *msg = (ACTextMessage *)message;
                if(msg.content.length){
                    pContent =  msg.content;
                }
            }

            
            height = [pContent getHeightAutoresizeWithLimitWidth:(kAutoresizeLimitWidth) font:[ACConfigs shareConfigs].chatTextFont]+40;

//            height = [AttributedLabel getHeightWithLimitWidth:kAutoresizeLimitWidth string:msg.content font:[ACConfigs shareConfigs].chatTextFont]+30;
            
            height += 24;
            if (height < 74)
            {
                height = 74;
            }
//            if(height>12000){
//                ITLogEX(@"%f",height);
//                height = 13000;
//            }
//            ITLogEX(@"%f",height);
        }
            break;
        case ACMessageEnumType_Location:
        {

            height = kAutoresizeLimitWidth+img_video_Location_bk_img_hight;
//            height = kAutoresizeLimitWidth+46;
            
        }
            break;
        case ACMessageEnumType_Image:
        {
            ACFileMessage* msg = (ACFileMessage*)message;
            
            CGSize size =   [self _getImageShowSize:msg];
           height  =   size.height+46;

        ///height = size.height+img_video_Location_bk_img_hight;
            
            if(msg.caption.length){
                height += [msg.caption getHeightAutoresizeWithLimitWidth:(size.width) font:[ACConfigs shareConfigs].chatTextFont];
            }
        }
            break;
        case ACMessageEnumType_Video:
        {
           // height = kAutoresizeLimitWidth+img_video_Location_bk_img_hight+(170-144);
           height = kAutoresizeLimitWidth+46+(170-144);
        }
            break;
            
        case ACMessageEnumType_Sticker:
        {
            ACStickerMessage *msg = (ACStickerMessage *)message;
            height = [self selfAdaptionSize:CGSizeMake(msg.width, msg.height)].height + 28;
            if(height<74){
                height = 74;
            }
        }
            break;
        case ACMessageEnumType_File:
        {
            ACFileMessage *msg = (ACFileMessage *)message;
            
            NSString *extension = [[[((ACFileMessage *)msg) name] componentsSeparatedByString:@"."] lastObject];
            NSString *filePath = [ACAddress getAddressWithFileName:((ACFileMessage *)msg).resourceID fileType:ACFile_Type_File isTemp:NO subDirName:extension];
            
            height = [msg.name getHeightAutoresizeWithLimitWidth:(kAutoresizeLimitWidth-20) font:[ACConfigs shareConfigs].chatTextFont];
            
//            height = [AttributedLabel getHeightWithLimitWidth:kAutoresizeLimitWidth-20 string:msg.name font:[ACConfigs shareConfigs].chatTextFont];
            
            float heightTmp = 0;
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
            {
                if (height < 30)
                {
                    heightTmp = 25;
                }
                else if (height < 48)
                {
                    heightTmp = 6;
                }
            }
            else
            {
                heightTmp = 25;
            }
            height += heightTmp;
            
            height += 53;
            if (height < 74)
            {
                height = 74;
            }
        }
            break;
        case ACMessageEnumType_System:{
            height = [((ACTextMessage *)message).content getHeightAutoresizeWithLimitWidth:kSystemMsgLimitWidth
                                                                                          font:[UIFont systemFontOfSize:11]];
//            if(height<20){
//                height = 20;
//            }
            
            height += 24;
        }
            break;
        default:
        {
            height = 74;
        }
            break;
    }
    if (message.isNeedDateShow){
        height += 20;
    }
    
    if(message.seq==lNewMsgSequence||lNewMsgSequenceFor99_Plus==message.seq){
        height += NewMsgFlag_Hight;
    }
    return height;
}

#pragma mark -tap
-(void)iconImageViewTap:(UITapGestureRecognizer *)tap
{
    if (_superVC.topicEntity.topicPerm.profile == ACTopicPermission_ParticipantProfile_Allow ||
        _messageData.directionType != ACMessageDirectionType_Send)
    {
        ACParticipantInfoViewController *participantInfoVC = [[ACParticipantInfoViewController alloc] initWithUserID:_messageData.sendUserID];
        AC_MEM_Alloc(participantInfoVC);
        participantInfoVC.topicEntity = _superVC.topicEntity;
        [_superVC.navigationController pushViewController:participantInfoVC animated:YES];
    }
}

#define videoMsgOptionFunc_Play     0
#define videoMsgOptionFunc_Save     1
#define videoMsgOptionFunc_Check    2

-(BOOL)_videoMsgOptionFunc:(int)nFunc{
    NSString *filePath = [ACAddress getAddressWithFileName:((ACFileMessage *)_messageData).resourceID fileType:ACFile_Type_VideoFile isTemp:NO subDirName:nil];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        if(videoMsgOptionFunc_Check==nFunc){
            return YES;
        }
        
        if(videoMsgOptionFunc_Save==nFunc){
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)){
                UISaveVideoAtPathToSavedPhotosAlbum(filePath, nil, nil, NULL);
                [_superVC.view showNomalTipHUD:NSLocalizedString(@"Saved", nil)];
                return YES;
            }
            [_superVC.view showNomalTipHUD:NSLocalizedString(@"Save Failed", nil)];
            return NO;
        }
        
        [_superVC moviePlayWithFilePath:filePath];
    }
    else
    {
        if(videoMsgOptionFunc_Check==nFunc){
            return NO;
        }
        
        ACFileMessage *fileMsg = (ACFileMessage *)_messageData;
        if (!fileMsg.isDownloading)
        {
            fileMsg.isDownloading = YES;
            [_contentProgressView setHidden:NO];
            [_videoPlayImageView setHidden:YES];
            [[ACNetCenter shareNetCenter] downloadMoiveFileWithEntityID:_messageData.topicEntityID messageID:_messageData.messageID resourceID:((ACFileMessage *)_messageData).resourceID progressDelegate:_messageData withFileLength:fileMsg.length];
        }
    }
    return YES;
}

-(void)videoMsgOptionForSave{
    [self _videoMsgOptionFunc:videoMsgOptionFunc_Save];
}


-(void)contentLongPress:(UILongPressGestureRecognizer *)longPress
{
    if (longPress.state == UIGestureRecognizerStateBegan)
    {
        UIActionSheet *actionSheet = nil;
        NSMutableArray *otherButtonTitles = [NSMutableArray array];
        
        if(_messageData.canTransmit){
            [otherButtonTitles addObject:kMsgOpt_Transmit]; //转发
        }
        if (_messageData.messageEnumType ==ACMessageEnumType_Text)
        {
            [otherButtonTitles addObject:kMsgOpt_Copy]; //拷贝
        }
        
        if(_messageData.messageEnumType ==ACMessageEnumType_Video&&
           _messageData.directionType==ACMessageDirectionType_Receive){
            [otherButtonTitles addObject:[self _videoMsgOptionFunc:videoMsgOptionFunc_Check]?kMsgOpt_SaveToAblum:kMsgOpt_Download]; //kSaveToAblum
        }
        
        if (_messageData.directionType == ACMessageDirectionType_Receive &&
            _superVC.topicEntity.topicPerm.chatInChat == ACTopicPermission_ChatInChat_Allow)
        {
            [otherButtonTitles addObject:kMsgOpt_PrivateChat]; //私聊
        }
        if (_messageData.messageLocation.longitude != 0 && _messageData.messageLocation.latitude != 0 && _messageData.messageLocation.longitude != 20000 && _messageData.messageLocation.latitude != 20000)
        {
            [otherButtonTitles addObject:kMsgOpt_ShowLocation]; //查看地理位置
        }
        if (_messageData.directionType == ACMessageDirectionType_Send && !_superVC.topicEntity.isSigleChat)
        {
            [otherButtonTitles addObject:kMsgOpt_HadReadList]; //已读列表
        }
        
        _superVC.otherButtonTitles = otherButtonTitles;
        _superVC.actionSheetCell = self;
        if ([_superVC.otherButtonTitles count] > 0)
        {
            if (![_superVC isUnSendMsg:_messageData])
            {
                actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:_superVC cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:[otherButtonTitles count]>0?[otherButtonTitles objectAtIndex:0]:nil, [otherButtonTitles count]>1?[otherButtonTitles objectAtIndex:1]:nil, [otherButtonTitles count]>2?[otherButtonTitles objectAtIndex:2]:nil, [otherButtonTitles count]>3?[otherButtonTitles objectAtIndex:3]:nil, [otherButtonTitles count]>4?[otherButtonTitles objectAtIndex:4]:nil, nil];
                
                actionSheet.tag = kActionSheetTag_MsgOpt;
                [actionSheet showInView:_superVC.contentView];
            }
        }
    }
}

//-(void)contentBgImageViewTap2:(UITapGestureRecognizer *)tap
//{
//    switch (_messageData.messageEnumType)
//    {
//        case ACMessageEnumType_Text:
//        {
//            [_superVC previewTextWithTextMessage:(ACTextMessage *)_messageData];
//        }
//            break;
//        default:
//            break;
//    }
//}

-(void)contentBgImageViewTapForMulSelect:(UITapGestureRecognizer *)tap{
    _mulSelectButton.selected =   [_superVC mulSelectedMsg:_messageData forTap:YES];
}

-(void)_contentBgImageViewTapForContentLabel:(UITapGestureRecognizer *)tap{
    NSDictionary* link = [_chatContentLabel labelTap:tap];
    if(link){
        //                NSRange range = [[link objectForKey:@"range"] rangeValue];
        NSString *linkString = [link objectForKey:@"link"];
        KZLinkType linkType = (KZLinkType)[[link objectForKey:@"linkType"] intValue];
        
        if (linkType == KZLinkTypeURL) {
            if([linkString isValidEmail]){
                [_superVC openMail:linkString];
            }else{
                [_superVC openUrl:[NSURL URLWithString:linkString]];
            }
            return;
        }
        if (linkType == KZLinkTypePhoneNumber) {
            [_superVC openTel:linkString];
            return;
        }
        NSLog(@"Other Link %@",linkString);
    }
// [_superVC previewTextWithTextMessage:(ACTextMessage *)_messageData];
    [_superVC previewText:_chatContentLabel.text];
    
//            BOOL haveUrl = [_chatContentLabel labelTap:tap];
//            if (!haveUrl)
//            {
//                [_superVC previewTextWithTextMessage:(ACTextMessage *)_messageData];
//
//            }
}


-(void)contentBgImageViewTap:(UITapGestureRecognizer *)tap
{
    switch (_messageData.messageEnumType)
    {
        case ACMessageEnumType_Image:
        {
            ACFileMessage *msg = (ACFileMessage *)_messageData;
            if(msg.caption.length){
                CGPoint point = [tap locationInView:_chatContentLabel];
                if(point.y>0&&point.y<_chatContentLabel.bounds.size.height){
                    //点中了文本
                    [self _contentBgImageViewTapForContentLabel:tap];
                    return;
                }
            }
            
            [_superVC displayImageWithFileMessage:msg];
            
        }
            break;
        case ACMessageEnumType_Sticker:
        {
            ACGifBrowserViewController *gifBrowserVC = [[ACGifBrowserViewController alloc] init];
            AC_MEM_Alloc(gifBrowserVC);
            gifBrowserVC.stickerMessage = (ACStickerMessage *)_messageData;
            [_superVC.navigationController pushViewController:gifBrowserVC animated:YES];
        }
            break;
        case ACMessageEnumType_Location:
        {
            ACMapBrowerViewController *mapBrowserVC = [[ACMapBrowerViewController alloc] init];
            mapBrowserVC.coordinate = ((ACLocationMessage *)_messageData).location;
            [_superVC ACpresentViewController:mapBrowserVC animated:YES completion:nil];
        }
            break;
        case ACMessageEnumType_Audio:
        {
            if([ACVideoCall inVideoCallAndShowTip]){
                return;
            }
//            //正在播放的话停止
//            if (((ACFileMessage *)_messageData).isPlaying)
//            {
//                [self audioPlayFinished:nil];
//                [_superVC stopAudio];
//            }
//            //没有播放的话播放
//            else
//            {
                ((ACFileMessage *)_messageData).isPlaying = YES;
                NSString *filePath = [ACAddress getAddressWithFileName:((ACFileMessage *)_messageData).resourceID fileType:ACFile_Type_AudioFile isTemp:NO subDirName:nil];
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
                {
                    [_superVC playAudioWithFilePath:filePath audioMsg:(ACFileMessage *)_messageData];
                    [_audioPlayingTimer invalidate];
                    self.audioPlayingTimer = [NSTimer scheduledTimerWithTimeInterval:.2 target:self selector:@selector(audioPlayingImageShow:) userInfo:nil repeats:YES];
                    [[NSNotificationCenter defaultCenter] removeObserver:self];
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioPlayFinished:) name:kAudioPlayFinishedNotification object:nil];
                }
                else
                {
                    ACFileMessage *fileMsg = (ACFileMessage *)_messageData;
                    if (!fileMsg.isDownloading)
                    {
                        fileMsg.isDownloading = YES;
                        [_contentProgressView setHidden:NO];
                        [[ACNetCenter shareNetCenter] downloadAudioFileWithEntityID:_messageData.topicEntityID
                                                                          messageID:_messageData.messageID
                                                                         resourceID:((ACFileMessage *)_messageData).resourceID
                                                                   progressDelegate:_messageData
                         withFileLength:fileMsg.length];
                    }
                }
//            }
        }
            break;
        case ACMessageEnumType_Video:
        {
            if([ACVideoCall inVideoCallAndShowTip]){
                return;
            }

            [self _videoMsgOptionFunc:videoMsgOptionFunc_Play];
        }
            break;
        case ACMessageEnumType_File:
        {
            NSString *extension = [[[((ACFileMessage *)_messageData) name] componentsSeparatedByString:@"."] lastObject];
            NSString *filePath = [ACAddress getAddressWithFileName:((ACFileMessage *)_messageData).resourceID fileType:ACFile_Type_File isTemp:NO subDirName:extension];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
                if([ACUtility fileExtIsMedia:extension]&&[ACVideoCall inVideoCallAndShowTip]){
                    return;
                }
                
                [_superVC fileBrowserWithFileMsgData:(ACFileMessage *)_messageData];
            }
            else
            {
                ACFileMessage *fileMsg = (ACFileMessage *)_messageData;
                if (!fileMsg.isDownloading)
                {
                    fileMsg.isDownloading = YES;
                    [_contentProgressView setHidden:NO];
                    [[ACNetCenter shareNetCenter] downloadFileWithEntityID:_messageData.topicEntityID
                                                                 messageID:_messageData.messageID
                                                                resourceID:((ACFileMessage *)_messageData).resourceID
                                                          progressDelegate:_messageData
                                                                  fileName:fileMsg.name
                                                            withFileLength:fileMsg.length];
                }
            }
        }
            break;
        case ACMessageEnumType_Videocall:
        case ACMessageEnumType_Audiocall:
        {
            [_superVC callBack:_messageData];
        }
            break;
           
            case ACMessageEnumType_Text:
        {
            [self _contentBgImageViewTapForContentLabel:tap];
        }
            break;
        default:
            break;
    }
}

/*- (void)attributedLabel:(AttributedLabel *)attributedLabel openUrl:(NSURL *)url
{
    [_superVC openUrl:url];
}*/

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _messageData && [keyPath isEqualToString:kProgress])
    {
        ACFileMessage *fileMsg = (ACFileMessage *)_messageData;
        if (_messageData.messageEnumType == ACMessageEnumType_Video)
        {
            if (/*!_superVC.isScrolling &&*/ fileMsg.isDownloading)
            {
                _contentProgressView.progress = fileMsg.progress;
            }
            if (fileMsg.progress == 1)
            {
                _contentLengthLabel.text = [NSString stringWithFormat:@"%d%@",fileMsg.duration,NSLocalizedString(@"sec", nil)];
                [_contentProgressView setHidden:YES];
                fileMsg.isDownloading = NO;
//                [_messageData removeObserver:self forKeyPath:kProgress];
                [_videoPlayImageView setHidden:NO];
                [_videoPlayImageView setImage:kPlayImage];
            }
        }
        else if (_messageData.messageEnumType == ACMessageEnumType_File)
        {
            if (/*!_superVC.isScrolling &&*/ fileMsg.isDownloading)
            {
                _contentProgressView.progress = fileMsg.progress;
            }
            if (fileMsg.progress == 1)
            {
                [_contentProgressView setHidden:YES];
                fileMsg.isDownloading = NO;
//                [_messageData removeObserver:self forKeyPath:kProgress];
                [_contentLengthLabel setFrame_width:110];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    _contentLengthLabel.text = nil;
                    [_superVC tableViewReloadData];
                    [self contentBgImageViewTap:nil];
                });
            }
        }
        else if (_messageData.messageEnumType == ACMessageEnumType_Audio)
        {
            if (/*!_superVC.isScrolling &&*/ fileMsg.isDownloading)
            {
                _contentProgressView.progress = fileMsg.progress;
            }
            if (fileMsg.progress == 1)
            {
                _contentLengthLabel.text = [NSString stringWithFormat:@"%d%@",fileMsg.duration,NSLocalizedString(@"sec", nil)];
                [_contentProgressView setHidden:YES];
                fileMsg.isDownloading = NO;
//                [_messageData removeObserver:self forKeyPath:kProgress];

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self contentBgImageViewTap:nil];
                });
            }
        }
    }
}

-(void)audioPlayingImageShow:(NSTimer *)timer
{
    static int i = 0;
    if (_messageData.directionType == ACMessageDirectionType_Send)
    {
        switch (i%3)
        {
            case 0:
            {
                _audioPlayImageView.image = [UIImage imageNamed:@"SenderVoiceNodePlaying001.png"];
            }
                break;
            case 1:
            {
                _audioPlayImageView.image = [UIImage imageNamed:@"SenderVoiceNodePlaying002.png"];
            }
                break;
            case 2:
            {
                _audioPlayImageView.image = [UIImage imageNamed:@"SenderVoiceNodePlaying003.png"];
            }
                break;
                
            default:
                break;
        }
    }
    else
    {
        switch (i%3)
        {
            case 0:
            {
                _audioPlayImageView.image = [UIImage imageNamed:@"bottleReceiverVoiceNodePlaying001.png"];
            }
                break;
            case 1:
            {
                _audioPlayImageView.image = [UIImage imageNamed:@"bottleReceiverVoiceNodePlaying002.png"];
            }
                break;
            case 2:
            {
                _audioPlayImageView.image = [UIImage imageNamed:@"bottleReceiverVoiceNodePlaying003.png"];
            }
                break;
                
            default:
                break;
        }
    }
    i += 1;
}

-(void)setHighLight
{
    if (_superVC.messageVCType != ACMessageVCType_Search){
        return;
    }
    
    NSString *content = nil;
    
    if(ACMessageEnumType_Image==_messageData.messageEnumType){
        content =   ((ACFileMessage *)_messageData).caption;
    }
    else if(ACMessageEnumType_Text==_messageData.messageEnumType){
        content = _messageData.content;
    }
    else if(ACMessageEnumType_File==_messageData.messageEnumType){
        content =   ((ACFileMessage *)_messageData).name;
    }
    if(0==content.length){
        return;
    }
    
    [_chatContentLabel setHighlight:_superVC.highLightArray withText:content];
    
//    NSMutableAttributedString* pStr = [[NSMutableAttributedString alloc] initWithString:content];
//    [pStr addAttributes:@{NSFontAttributeName:_chatContentLabel.font,NSForegroundColorAttributeName:[UIColor blackColor]} range:NSMakeRange(0, content.length)];
//    
//    for (NSString *highLightString in _superVC.highLightArray){
//        NSUInteger len = [highLightString length];
//        NSArray *array = [content componentsSeparatedByString:highLightString];
//        if ([array count] > 1)
//        {
//            UIColor* redColor = [UIColor redColor];
//            NSUInteger loc = [[array objectAtIndex:0] length];
//            [pStr addAttribute:NSForegroundColorAttributeName value:redColor range:NSMakeRange(loc, len)];
//            loc += len;
//            for (int i = 2; i < [array count]; i++)
//            {
//                loc += [[array objectAtIndex:i-1] length];
//                [pStr addAttribute:NSForegroundColorAttributeName value:redColor range:NSMakeRange(loc, len)];
//                loc += len;
//            }
//        }
//    }
//    
//    _chatContentLabel.attributedText = pStr;

        
/*
        
        [_chatContentLabel setColor:[UIColor blackColor] fromIndex:0 length:[_messageData.content length]];
        NSString *content = _messageData.content;
        
        for (NSString *highLightString in _superVC.highLightArray)
        {
            NSUInteger len = [highLightString length];
            NSArray *array = [content componentsSeparatedByString:highLightString];
            if ([array count] > 0)
            {
                NSUInteger loc = [[array objectAtIndex:0] length];
                [_chatContentLabel setColor:[UIColor redColor] fromIndex:loc length:len];
                loc += len;
                for (int i = 2; i < [array count]; i++)
                {
                    loc += [[array objectAtIndex:i-1] length];
                    [_chatContentLabel setColor:[UIColor redColor] fromIndex:loc length:len];
                    loc += len;
                }
            }
        }
        [_chatContentLabel setNeedsDisplay];*/
}

//- (void)detectLinks
//{
//	AHHyperlinkScanner *scanner = [AHHyperlinkScanner hyperlinkScannerWithString:_chatContentLabel.text];
//	_links = [[scanner allURIs] copy];
//    for (AHMarkedHyperlink *link in _links)
//    {
//        [_chatContentLabel setUnderlineFromIndex:link.range.location length:link.range.length];
//    }
//}

//-(void)setUrlCanTouch
//{
//    long length = _chatContentLabel.text.length;
//    NSString *content = _chatContentLabel.text;
//    int loc = -1;
//    int len = 0;
//    for (int i = 0; i < length; i++)
//    {
//        char c = [content characterAtIndex:i];
//        if ((c >= 48 && c <= 57)||(c >= 65 && c <= 90)||(c >= 97 && c <= 122))
//        {
//            if (loc == -1)
//            {
//                loc = i;
//                len = 1;
//            }
//            else
//            {
//                len++;
//                if (loc+len == length)
//                {
//                    [self isUrlStringWithLoc:loc len:len];
//                }
//            }
//        }
//        else if (loc != -1 && c == '.')
//        {
//            if (i > 0)
//            {
//                char p = [content characterAtIndex:i-1];
//                if (p == c)
//                {
//                    len--;
//                    [self isUrlStringWithLoc:loc len:len];
//                    loc = -1;
//                }
//                else
//                {
//                    len++;
//                }
//            }
//        }
//        else
//        {
//            if (loc != -1)
//            {
//                [self isUrlStringWithLoc:loc len:len];
//                loc = -1;
//            }
//        }
//    }
//}
//
//-(void)isUrlStringWithLoc:(int)loc len:(int)len
//{
//    if (len > 0)
//    {
//        NSString *subString = [_chatContentLabel.text substringWithRange:NSMakeRange(loc, len)];
//        NSArray *array = [subString componentsSeparatedByString:@"."];
//        if ([array count]>1)
//        {
//            NSURL *url = [NSURL URLWithString:subString];
//            if (url)
//            {
//                [_chatContentLabel setUnderlineFromIndex:loc length:len];
//            }
//        }
//    }
//    
////    NSArray *array = [_contentLengthLabel.text componentsSeparatedByString:@"."];
////    if ([array count] >= 2)
////    {
////        NSString *lastObj = [array lastObject];
////        lastObj = [lastObj lowercaseString];
////        NSArray *array = @[@"cn",@"com",@"gov",@"net",@"org",@"edu",@"int",@"mil",@"net",@"org",];
////        if ([lastObj isEqualToString:@"cn"])
////        {
////            <#statements#>
////        }
////    }
//}

-(void)audioPlayFinished:(NSNotification *)noti
{
    NSObject *object = noti.object;
    if (object == _messageData || !noti)
    {
        ((ACFileMessage *)_messageData).isPlaying = NO;
        [_audioPlayingTimer invalidate];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        if (_messageData.directionType == ACMessageDirectionType_Send)
        {
            [_audioPlayImageView setImage:[UIImage imageNamed:@"SenderVoiceNodePlaying.png"]];
        }
        else
        {
            [_audioPlayImageView setImage:[UIImage imageNamed:@"bottleReceiverVoiceNodePlaying.png"]];
        }
    }
}

//-(void)stickerStartGif
//{
//    [_gifImageView continueAnimating];
////    [_gifView resumeLayer];
////    [_gifView startGif];
//}
//
//-(void)stickerStopGif
//{
//    [_gifImageView pauseAnimating];
////    [_gifView pauseLayer];
////    [_gifView stopGif];
//}

//-(void)beginDragNoti:(NSNotification *)noti
//{
////    [_gifView pauseLayer];
//}
//
//-(void)stopDecelerateNoti:(NSNotification *)noti
//{
////    [_gifView resumeLayer];
//}


-(void)_setImageBkViewRectWithContentView:(UIView*)contentView
                          andCaptionHight:(NSUInteger)captionHight isSend:(BOOL)isSend{
    //用于设置Image Video Location 设置背景图片，使用瘦边
    [_chatContentBgImageView setFrame:CGRectMake(contentView.origin.x - (isSend?8:13), contentView.origin.y - 4,
                                                 contentView.size.width + 21,
                                                 contentView.size.height + 17 +captionHight)];
}

-(void)_setMessageFunc:(ACMessage *)message superVC:(ACChatMessageViewController *)superVC
{
//    self.contentView.backgroundColor = [UIColor redColor];
    if (message != _messageData || message.messageEnumType == ACMessageEnumType_File/* ||  message.messageEnumType == ACMessageEnumType_Sticker*/) {
        
        
//        if (_messageData && (_messageData.messageEnumType == ACMessageEnumType_Video || _messageData.messageEnumType == ACMessageEnumType_File || _messageData.messageEnumType == ACMessageEnumType_Audio)) {
//            [_messageData removeObserver:self forKeyPath:kProgress];
//        }
        self.messageData = message;
        _superVC = superVC;

//        NSDictionary *hadReadDic = [_superVC readCountMutableDic];
//        ACReadCount *readCount = [hadReadDic objectForKey:[NSNumber numberWithLong:_messageData.seq]];
//        ACReadCount *readCount = [superVC getReadCountWithSeq:_messageData.seq];
//        if ([_superVC.topicEntity.mpType isEqualToString:cSingleChat] || _messageData.directionType == ACMessageDirectionType_Receive || !readCount.readCount)
//        {
//            [_hadReadButton setHidden:YES];
//        }
//        else
//        {
//            [_hadReadButton setHidden:NO];
        [_hadReadButton setBackgroundImage:[[UIImage imageNamed:@"readby.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:5] forState:UIControlStateNormal];
        [_hadReadButton setBackgroundImage:[[UIImage imageNamed:@"readby_pressed.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:5] forState:UIControlStateHighlighted];
//        }

        UIView *contentView = nil;
        _chatContentLabel.hidden = YES; //文本label
        _audioPlayImageView.hidden = YES;//语音播放图片
        _audioPlayImageView.image = nil;
        _videoPlayImageView.hidden=  YES;//视频播放图片
        _videoPlayImageView.image = nil;
        _contentProgressView.hidden = YES;//视频下载进度条
        _chatContentImageView.hidden = YES;//视频，图片缩略图
        _chatContentImageView.image = nil;
        _chatContentImageView.contentMode =  UIViewContentModeScaleToFill;
        [_chatContentImageView.layer setMasksToBounds:YES];
        [_chatContentImageView.layer setCornerRadius:5.0];

        _isVideoImageView.hidden = YES;
        _contentLengthLabel.hidden = YES;

        _chatContentImageView.size = CGSizeMake(kAutoresizeLimitWidth, kAutoresizeLimitWidth);

        _chatContentBgImageView.hidden = NO;

        _gifImageView.image = nil;
        if (message.messageEnumType != ACMessageEnumType_Sticker) {
            [_gifImageView setHidden:YES];
            _activityView.hidden = YES;
        }
        
        _systemMsg_Lable.hidden =   YES;
        _timeLabel.hidden = NO;
        _nameLabel.hidden = NO;
        _timeLabel.hidden = NO;
        _uploadStateButton.hidden = NO;
        _hadReadButton.hidden = NO;
        _hadReadLabel.hidden = NO;
        _iconImageView.hidden = NO;

        [_contentLengthLabel setFrame_width:55];

        NSUInteger _contentViewY = 0;
        NSUInteger _imgWithCaptionHight = 0;
//        if(message.isNeedDateShow){
//            NSString* pText = [[ACDataCenter shareDataCenter] getDateStringWithTimeInterval:message.createTime/1000];
//            if([pText isEqualToString:@"2015-03-01 Sunday"]){
//                message.isNeedShowNewMsgFlag = YES;
//            }
//        }


        if (message.seq == _superVC.lNewMsgSequence||message.seq==_superVC.lNewMsgSequenceFor99_Plus) {
            _newMsgFlagView.hidden = NO;
            [_newMsgFlagView setFrame_y:(NewMsgFlag_Hight - 20) / 2];
            ///
            [_newMsgFlagView setFrame_width:kScreen_Width];
            _newMsgFlagLable.text = message.seq == _superVC.lNewMsgSequence ? NSLocalizedString(@"Unread messages below", nil) : [NSString stringWithFormat:NSLocalizedString(@"The latest %d unread messages below", nil),Load_Unread_Msg_Max_Count];
            [_newMsgFlagBkView setRectRound:4];
            ///
            [_newMsgFlagBkView setFrame_width:(kScreen_Width-40)];
            [_newMsgFlagLable mas_makeConstraints:^(MASConstraintMaker *make) {
                make.center.equalTo(_newMsgFlagBkView);
            }];
            /*[_newMsgFlagLable setSingleRowAutosizeLimitWidth:200];
            [_newMsgFlagLable setFrame_x:(_contentView.frame.size.width-_newMsgFlagLable.frame.size.width)/2];
            [_newMsgFlagView setFrame_height:NewMsgFlag_Hight];
            
            CGRect lableRect =  _newMsgFlagLable.frame;
            CGRect rightLineRect = _newMsgFlagRightLine.frame;
            
            [_newMsgFlagLeftLine setFrame_width:(lableRect.origin.x-_newMsgFlagLeftLine.frame.origin.x-8)];
            
            CGFloat rightLineEndX = rightLineRect.origin.x+rightLineRect.size.width;
            rightLineRect.origin.x =    lableRect.origin.x+lableRect.size.width+8;
            rightLineRect.size.width    = rightLineEndX-rightLineRect.origin.x;
            _newMsgFlagRightLine.frame =    rightLineRect;*/


            _contentViewY = NewMsgFlag_Hight;
            _superVC.theNewMsgCountView.hidden = YES;
        }
        else {
            _newMsgFlagView.hidden = YES;
        }

        //设置是否显示日期view
        if (message.isNeedDateShow) {
            
           
            ///zzzzzzz
            [_dateView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.offset(kScreen_Width);
                make.height.offset(20);
            }];
            [_dateBgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.center.equalTo(_dateView);
            }];
            [_dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.edges.equalTo(_dateBgImageView).with.insets(UIEdgeInsetsMake(2, 5, 2, 5));
            }];
            
            ///[_dateView setFrame_y:_contentViewY];
            [_dateView mas_makeConstraints:^(MASConstraintMaker *make) {
               // make.top.equalTo(_newMsgFlagView.mas_bottom);
                make.top.offset(_contentViewY);
            }];
            ///NSLog(@"dateView%@",NSStringFromCGSize(_dateView.frame.size));
            
            [_dateView setHidden:NO];
            [_contentView setFrame_y:_contentViewY + 20];

            _dateLabel.text = [[ACDataCenter shareDataCenter] getDateStringWithTimeInterval:message.createTime / 1000];
//            [_dateLabel setAutoresizeWithLimitWidth:200];
//            [_dateLabel setCenter_x:_dateView.size.width / 2];
//            [_dateBgImageView setFrame_width:_dateLabel.size.width + 20];
//            [_dateBgImageView setCenter_x:_dateView.size.width / 2];
//            [_dateLabel setCenter_y:_dateBgImageView.center.y];
        }
        else {
            [_dateView setHidden:YES];
            [_contentView setFrame_y:_contentViewY + 0];
        }

        //设置time
        [_timeLabel setText:[[ACDataCenter shareDataCenter] getTimeStringWithTimeInterval:message.createTime / 1000]];

        switch (message.messageEnumType) {
            case ACMessageEnumType_Text:
            case ACMessageEnumType_ShareLocation:
            case ACMessageEnumType_Videocall:
            case ACMessageEnumType_Audiocall:
            case ACMessageEnumType_Unknow:
            {
                
                NSString* pContent = @" ";
                if(ACMessageEnumType_Unknow==message.messageEnumType){
                    pContent    =   ACMessageEnumType_Unknow_String;
                }
                else{
                    ACTextMessage *msg = (ACTextMessage *) message;
                    if(msg.content.length){
                        pContent    =   msg.content;
                    }
                }

                
#if 0 //TARGET_IPHONE_SIMULATOR
                [_chatContentLabel setText:[NSString stringWithFormat:@"%ld",msg.seq]];
#else

                _chatContentLabel.font = [ACConfigs shareConfigs].chatTextFont;
                
                if(ACMessageEnumType_Text==message.messageEnumType){
                    [_chatContentLabel setText:pContent];
                }
                else{
//                    [_chatContentLabel setAutomaticLinkDetectionEnabledWithNoUpdateText:NO];
                    [_chatContentLabel setNomalText:pContent];
//                    [_chatContentLabel setAutomaticLinkDetectionEnabledWithNoUpdateText:YES];
                }
//                [self setUrlCanTouch];
//                [self detectLinks];
#endif
                [self setHighLight];

                [_chatContentLabel setHidden:NO];
                contentView = _chatContentLabel;
            }
                break;
            case ACMessageEnumType_Location: {
                ACLocationMessage *msg = (ACLocationMessage *) message;
                [_chatContentImageView setHidden:NO];
                [_chatContentImageView setImageWithLatitude:msg.location.latitude withLongitude:msg.location.longitude placeholderImage:[UIImage imageNamed:@"map_placeHolder.png"]];
                contentView = _chatContentImageView;
            }
                break;
            case ACMessageEnumType_Image: {
                ACFileMessage *msg = (ACFileMessage *) message;
                [_chatContentImageView setHidden:NO];
                
                CGFloat fWidth = kAutoresizeLimitWidth;
                if(2==msg.smallSizeArray.count){
                    CGRect frame = _chatContentImageView.frame;
//                    CGSize showSize =   [ACChatMessageTableViewCell _getImageShowSize:msg];
//                    frame.origin.x  =   CGRectGetMaxX(frame)-showSize.width;
                    frame.size =    [ACChatMessageTableViewCell _getImageShowSize:msg];
                    fWidth = frame.size.width;
                    _chatContentImageView.frame  =   frame;
                    _chatContentImageView.contentMode =  UIViewContentModeScaleAspectFit;
                }
                
                NSString *filePath = [ACAddress getAddressWithFileName:msg.thumbResourceID fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
                UIImage *image = [UIImage imageWithContentsOfFile:filePath];
                if (image) {
                    [_chatContentImageView setImage:image];
                }
                else {
                    [_chatContentImageView setImageWithEntityID:msg.topicEntityID
                                                    withMsgID:msg.messageID
                                                       thumbRid:msg.thumbResourceID
                                               placeholderImage:[UIImage imageNamed:@"image_placeHolder.png"]];
                }
                
                if(msg.caption.length){
                    _chatContentLabel.font = [ACConfigs shareConfigs].chatTextFont;
                    [_chatContentLabel setText:msg.caption];
                    [_chatContentLabel setAutoresizeWithLimitWidth:fWidth];
                    _imgWithCaptionHight =  _chatContentLabel.size.height;
                }
                
                contentView = _chatContentImageView;
            }
                break;
            case ACMessageEnumType_Sticker: {
                [_gifImageView setHidden:NO];
                ACStickerMessage *msg = (ACStickerMessage *) message;
//                [_chatContentImageView setHidden:NO];
//                [_chatContentImageView setStickerWithStickerPath:msg.stickerPath stickerName:msg.stickerName placeholderImage:[UIImage imageNamed:@"image_placeHolder.png"]];

                //            [nc addObserver:self selector:@selector(beginDragNoti:) name:kBeginDragNotification object:nil];
                //            [nc addObserver:self selector:@selector(stopDecelerateNoti:) name:kStopDecelerateNotification object:nil];


                [self reloadStickerWithMsg:msg];

                contentView = _chatContentImageView;
            }
                break;
            case ACMessageEnumType_Audio: {
                ACFileMessage *msg = (ACFileMessage *) message;
                [_audioPlayImageView setHidden:NO];
                _contentLengthLabel.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:14];
                [_contentLengthLabel setTextAlignment:NSTextAlignmentCenter];

                contentView = _audioPlayImageView;

                //视频下载显示进度条
//                [msg addObserver:self forKeyPath:kProgress options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];

                if (msg.isDownloading) {
                    _contentProgressView.progress = msg.progress;
                    [_contentProgressView setHidden:NO];
                }
                else {
                    [_contentProgressView setHidden:YES];
                }

                if (msg.isPlaying) {
                    [_audioPlayingTimer invalidate];
                    self.audioPlayingTimer = [NSTimer scheduledTimerWithTimeInterval:.2 target:self selector:@selector(audioPlayingImageShow:) userInfo:nil repeats:YES];
                    [[NSNotificationCenter defaultCenter] removeObserver:self];
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioPlayFinished:) name:kAudioPlayFinishedNotification object:nil];
                }
                else {
                    [_audioPlayingTimer invalidate];
                    self.audioPlayingTimer = nil;
                    if (msg.directionType == ACMessageDirectionType_Send) {
                        [_audioPlayImageView setImage:[UIImage imageNamed:@"SenderVoiceNodePlaying.png"]];
                    }
                    else {
                        [_audioPlayImageView setImage:[UIImage imageNamed:@"bottleReceiverVoiceNodePlaying.png"]];
                    }
                }
            }
                break;
            case ACMessageEnumType_File: {
                ACFileMessage *msg = (ACFileMessage *) message;
                [_chatContentLabel setHidden:NO];
                [_chatContentImageView setHidden:NO];
                [_contentLengthLabel setHidden:NO];
                _contentLengthLabel.font =  [UIFont systemFontOfSize:16];
                _chatContentLabel.font  =   [ACConfigs shareConfigs].chatTextFont;
                [_contentLengthLabel setFrame_width:55];
                _chatContentImageView.size = CGSizeMake(35, 50);
                _chatContentLabel.text = msg.name;
                [_chatContentLabel setAutoresizeWithLimitWidth:kAutoresizeLimitWidth - 20];

                NSString *extension = [[[((ACFileMessage *) _messageData) name] componentsSeparatedByString:@"."] lastObject];

                _chatContentImageView.contentMode = UIViewContentModeTop;
                _chatContentImageView.image = [ACUtility loadFileExtIcon:extension];
                
//                if ([[extension lowercaseString] isEqualToString:@"vcf"]) {
//                    _chatContentImageView.image = [UIImage imageNamed:@"file_icon_vcf.png"];
//                }
//                else {
//                    _chatContentImageView.image = [UIImage imageNamed:@"file.png"];
//                }


                NSString *filePath = [ACAddress getAddressWithFileName:((ACFileMessage *) _messageData).resourceID fileType:ACFile_Type_File isTemp:NO subDirName:extension];
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
//                    _contentLengthLabel.text = NSLocalizedString(@"Downloaded", nil);
//                    [_contentLengthLabel setFrame_width:110];
                    _contentLengthLabel.text = nil;
                }
                else {
                    _contentLengthLabel.text = [self getTextWithLength:msg.length];
                }
                [_contentLengthLabel setTextAlignment:NSTextAlignmentLeft];
                contentView = _chatContentLabel;
//                [self setHighLight];

                //视频下载显示进度条
//                [msg addObserver:self forKeyPath:kProgress options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];

                if (msg.isDownloading && msg.progress != 1) {
                    _contentProgressView.progress = msg.progress;
                    [_contentProgressView setHidden:NO];
                }
                else {
                    [_contentProgressView setHidden:YES];
                }
                [self setHighLight];
            }
                break;
            case ACMessageEnumType_Video: {
                ACFileMessage *msg = (ACFileMessage *) message;
                [_chatContentLabel setHidden:YES];
                [_chatContentImageView setHidden:NO];
                [_isVideoImageView setHidden:NO];
                [_contentLengthLabel setHidden:NO];
                _contentLengthLabel.font = [UIFont systemFontOfSize:16];
                [_contentLengthLabel setTextAlignment:NSTextAlignmentRight];

                //视频下载显示进度条

//                [msg addObserver:self forKeyPath:kProgress options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];

                if (msg.isDownloading) {
                    _contentProgressView.progress = msg.progress;
                    [_contentProgressView setHidden:NO];
                    [_videoPlayImageView setHidden:YES];
                }
                else {
                    [_contentProgressView setHidden:YES];
                    [_videoPlayImageView setHidden:NO];
                }

                NSString *filePathT = [ACAddress getAddressWithFileName:msg.thumbResourceID fileType:ACFile_Type_VideoThumbFile isTemp:NO subDirName:nil];;
                UIImage *image = [UIImage imageWithContentsOfFile:filePathT];
                if (image) {
                    [_chatContentImageView setImage:image];
                }
                else {
                    [_chatContentImageView setImageWithEntityID:msg.topicEntityID withMsgID:msg.messageID thumbRid:msg.thumbResourceID placeholderImage:[UIImage imageNamed:@"video_placeHolder.png"]];
                }
                contentView = _chatContentImageView;

                NSString *filePath = [ACAddress getAddressWithFileName:((ACFileMessage *) msg).resourceID fileType:ACFile_Type_VideoFile isTemp:NO subDirName:nil];
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                    [_videoPlayImageView setImage:kPlayImage];

                    _contentLengthLabel.text = [NSString stringWithFormat:@"%d%@", msg.duration, NSLocalizedString(@"sec", nil)];
                }
                else {
                    [_videoPlayImageView setImage:[UIImage imageNamed:@"download.png"]];
                    _contentLengthLabel.text = [self getTextWithLength:msg.length];
                }
            }
                break;
            case ACMessageEnumType_System:
            {
//                _chatContentBgImageView.hidden = YES;
                _nameLabel.hidden = YES;
                _timeLabel.hidden = YES;
                _uploadStateButton.hidden = YES;
                _hadReadButton.hidden = YES;
                _hadReadLabel.hidden = YES;
                _iconImageView.hidden = YES;
                _chatContentLabel.hidden = YES;
                
                //设置自动调整button大小,设置x
                
                _systemMsg_Lable.text  =   ((ACTextMessage *) message).content;
                [_systemMsg_Lable setAutoresizeWithLimitWidth:kSystemMsgLimitWidth];
                float fHight = _systemMsg_Lable.size.height+20;
                
                _systemMsg_Lable.frame = CGRectMake((kScreen_Width-_systemMsg_Lable.size.width)/2, 8, _systemMsg_Lable.frame.size.width, fHight-4);

                ///_systemMsg_Lable.frame = CGRectMake((320 -_systemMsg_Lable.size.width)/2, 8, _systemMsg_Lable.frame.size.width, fHight-4);
               
//                [_systemMsg_Lable setFrame_height:fHight-6];
//                [_systemMsg_Lable setFrame_x:(320-_systemMsg_Lable.size.width)/2];
//                [_systemMsg_Lable setFrame_y:3];
                contentView =   _systemMsg_Lable;
                
                [_chatContentBgImageView setImage:[[UIImage imageNamed:@"it_msg_time_bg"] stretchableImageWithLeftCapWidth:20 topCapHeight:7]];
                [_chatContentBgImageView setFrame:CGRectMake((kScreen_Width-kSystemMsg_BK_Width)/2, _systemMsg_Lable.origin.y, kSystemMsg_BK_Width, _systemMsg_Lable.size.height)];
                [_contentView setFrame_height:fHight];

                _systemMsg_Lable.hidden = NO;
//                _contentView.backgroundColor = [UIColor redColor];
                
                return;
            }
                break;
            default: {
                [_chatContentLabel setHidden:NO];
                [_chatContentLabel setText:message.messageType];
                contentView = _chatContentLabel;
            }
                break;
        }

        //调整y坐标
        float y = 0;
        if (message.directionType == ACMessageDirectionType_Send) {
            y = 10;
            [_chatContentLabel setFrame_y:y];
        }
        else {
            y = 28;
            [_chatContentLabel setFrame_y:y - 2];
        }

        [_chatContentImageView setFrame_y:y + 6];
        [_audioPlayImageView setFrame_y:y + 10];

        if (message.directionType == ACMessageDirectionType_Send) {
            [_timeLabel setTextAlignment:NSTextAlignmentRight];
            [_hadReadLabel setTextAlignment:NSTextAlignmentRight];
            [_uploadStateButton setHidden:NO];
            [_iconImageView setHidden:YES];
            [self reloadUploadState];
            [self uploadStateAndReadCountReload];

            [_chatContentBgImageView setImage:[[UIImage imageNamed:@"SenderVoiceNodeBkg_ios7.png"] stretchableImageWithLeftCapWidth:45 topCapHeight:30]];
            [_chatContentBgImageView setHighlightedImage:[[UIImage imageNamed:@"SenderVoiceNodeBack_ios7.png"] stretchableImageWithLeftCapWidth:45 topCapHeight:30]];

            ///自己发送信息的位置
            [_iconImageView setFrame_x:(kScreen_Width - 10)];
            if (message.messageEnumType == ACMessageEnumType_Image ||
                message.messageEnumType == ACMessageEnumType_Location) {
                
                if(message.messageEnumType == ACMessageEnumType_Image&&
                   _chatContentImageView.frame.size.width<kAutoresizeLimitWidth){
                    [_chatContentImageView setFrame_x:kSendChatContentImageViewBaseX+(kAutoresizeLimitWidth-_chatContentImageView.frame.size.width)];
                }
                else{
                    [_chatContentImageView setFrame_x:kSendChatContentImageViewBaseX];
                }
                [self _setImageBkViewRectWithContentView:contentView andCaptionHight:_imgWithCaptionHight isSend:YES];
//                [_chatContentBgImageView setFrame:CGRectMake(contentView.origin.x - 13, contentView.origin.y - kChatContentBgImageViewBaseY, contentView.size.width + 31, contentView.size.height + kSendChatContentBgImageViewBaseHeight+_imgWithCaptionHight)];
            }
            else if (message.messageEnumType == ACMessageEnumType_Sticker) {
                ACStickerMessage *msg = (ACStickerMessage *) message;
                CGSize size = [ACChatMessageTableViewCell selfAdaptionSize:CGSizeMake(msg.width, msg.height)];
                [_chatContentImageView setFrame_x:kSendChatContentImageViewBaseX + (kAutoresizeLimitWidth - size.width)];
                
                [_chatContentImageView setFrame_y:8];

                [_chatContentImageView setSize:CGSizeMake(size.width + 16, size.height + 16)];
                _activityView.center = _chatContentImageView.center;
                [_chatContentBgImageView setFrame:CGRectMake(contentView.origin.x - 13, contentView.origin.y - kChatContentBgImageViewBaseY, contentView.size.width + 31, contentView.size.height + kSendChatContentBgImageViewBaseHeight)];
//                [_gifImageView setFrame:_chatContentImageView.frame];
                [_gifImageView setCenter:CGPointMake(_chatContentImageView.center.x, _chatContentImageView.center.y - 8)];
//                [_gifImageView setFrame_x:_gifImageView.origin.x+6];
//                [_gifImageView setFrame_y:_gifImageView.origin.y-8];
                [_chatContentImageView setHidden:YES];
                [_gifImageView setHidden:NO];
                [_chatContentBgImageView setHidden:YES];
            }
            else if (message.messageEnumType == ACMessageEnumType_Video) {
                [_chatContentImageView setFrame_x:kSendChatContentImageViewBaseX];
                [_isVideoImageView setFrame_x:200];
               /// [_contentLengthLabel setFrame_x:250];
                [_contentLengthLabel setFrame_x:_isVideoImageView.getFrame_right];
                [_contentLengthLabel setTextAlignment:NSTextAlignmentRight];
                [_contentLengthLabel setFrame_width:55];
                ///[_contentLengthLabel setFrame_width:50];
                [self _setImageBkViewRectWithContentView:contentView andCaptionHight:img_video_Location_bk_img_hight+6-17  isSend:YES];
//                [_chatContentBgImageView setFrame:CGRectMake(contentView.origin.x - 13, contentView.origin.y - kChatContentBgImageViewBaseY, contentView.size.width + 31, contentView.size.height + 46 + 6)];
                [_contentLengthLabel setFrame_y:[_chatContentImageView getFrame_Bottom] + 3];
            }
            else if (message.messageEnumType == ACMessageEnumType_File) {
                //设置自动调整button大小,设置x
                [_chatContentLabel setAutoresizeWithLimitWidth:kAutoresizeLimitWidth - 20];
                [_chatContentLabel setFrame_height:_chatContentLabel.size.height + 20];
                if (_chatContentLabel.size.width < 80) {
                    [_chatContentLabel setFrame_width:80];
                }
                [_chatContentLabel setFrame_x:_iconImageView.origin.x - kSendTextLabelBaseX - _chatContentLabel.size.width];

                NSString *extension = [[[((ACFileMessage *) _messageData) name] componentsSeparatedByString:@"."] lastObject];
                NSString *filePath = [ACAddress getAddressWithFileName:((ACFileMessage *) _messageData).resourceID fileType:ACFile_Type_File isTemp:NO subDirName:extension];

                
                float heightTmp = [((ACFileMessage *) _messageData).name getHeightAutoresizeWithLimitWidth:(kAutoresizeLimitWidth-20) font:_chatContentLabel.font];
                
//                float heightTmp = [AttributedLabel getHeightWithLimitWidth:kAutoresizeLimitWidth - 20 string:((ACFileMessage *) _messageData).name font:_chatContentLabel.font];

                float height = 0;
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                    if (heightTmp < 30) {
                        height = 25;
                    }
                    else if (heightTmp < 48) {
                        height = 6;
                    }
                }
                else {
                    height = 25;
                }

                [_chatContentBgImageView setFrame:CGRectMake(contentView.origin.x - 16 - kFileWidth, contentView.origin.y - 3, contentView.size.width + 38 + kFileWidth, contentView.size.height + 10 + height + 6)];
                [_contentView setFrame_height:_chatContentBgImageView.size.height + 10];

                [_chatContentImageView setFrame_x:_chatContentLabel.origin.x - _chatContentImageView.size.width - 5];
                [_contentLengthLabel setTextAlignment:NSTextAlignmentLeft];
                [_contentLengthLabel setFrame_x:_chatContentLabel.origin.x];
                [_contentLengthLabel setFrame_y:[_chatContentLabel getFrame_Bottom]];

                [_contentProgressView setFrame_x:_chatContentLabel.origin.x];
                [_contentProgressView setFrame_y:_contentLengthLabel.origin.y - 3];
                [_contentProgressView setFrame_width:_chatContentLabel.size.width];
            }
            else if (message.isTextEnumType){//(message.messageEnumType == ACMessageEnumType_Text) {
                //设置自动调整button大小,设置x
                [_chatContentLabel setAutoresizeWithLimitWidth:kAutoresizeLimitWidth];
                [_chatContentLabel setFrame_height:_chatContentLabel.size.height + 20];
                if (_chatContentLabel.size.width < 28) {
                    [_chatContentLabel setFrame_width:28];
                }
                
                float fLableX =  _iconImageView.origin.x - kSendTextLabelBaseX;
                float fBkW    =  contentView.size.width;
                if(ACMessageEnumType_Videocall==message.messageEnumType||
                   ACMessageEnumType_Audiocall==message.messageEnumType||
                   ACMessageEnumType_ShareLocation==message.messageEnumType){
                    //
                    CGRect rect = _chatContentLabel.frame;
                    [_chatContentImageView.layer setMasksToBounds:NO];

                    if(ACMessageEnumType_Videocall==message.messageEnumType){
                        rect.size.width = 43/2;
                        _chatContentImageView.image = [UIImage imageNamed:@"VoipVideoCall_Send"];
                    }
                    else if(ACMessageEnumType_ShareLocation==message.messageEnumType){
                        rect.size.width = 30/2;
                        _chatContentImageView.image = [UIImage imageNamed:@"locationSharing_Icon_Location_Main"];
                    }
                    else{
                        rect.size.width = 47/2;
                        _chatContentImageView.image = [UIImage imageNamed:@"VoipVoiceCall"];
                    }
                    
                    rect.origin.x = fLableX-rect.size.width+5;
                    rect.origin.y = rect.origin.y+((rect.size.height-23/2)/2);
                    
                    if(ACMessageEnumType_ShareLocation==message.messageEnumType){
                        rect.size.height = 30/2;
                    }
                    else{
                        rect.size.height = 23/2;
                    }
                    
                    fLableX -= rect.size.width-2;
                    fBkW += rect.size.width+2;
                    
                    _chatContentImageView.hidden = NO;
                    _chatContentImageView.frame = rect;
                }
                
                [_chatContentLabel setFrame_x:fLableX - _chatContentLabel.size.width];

                [_chatContentBgImageView setFrame:CGRectMake(contentView.origin.x - 16, contentView.origin.y - 3, fBkW + 38, contentView.size.height + 10 + 6)];
                [_contentView setFrame_height:_chatContentBgImageView.size.height + 10];
            }
            else if (message.messageEnumType == ACMessageEnumType_Audio) {
                ///[_audioPlayImageView setFrame_x:231];
                ///发送语音信息
                [_audioPlayImageView setFrame_x:(kScreen_Width - 100)];
                
                [_chatContentBgImageView setFrame_height:54 + 6];
                [_chatContentBgImageView setFrame_width:100];
                [_chatContentBgImageView setCenter:CGPointMake(_audioPlayImageView.center.x + 25, _audioPlayImageView.center.y + 5)];

                [_contentProgressView setFrame_width:_chatContentBgImageView.size.width - 30];
                [_contentProgressView setCenter_x:_chatContentBgImageView.center.x - 2];
                [_contentProgressView setFrame_y:[_audioPlayImageView getFrame_Bottom] + 3];

                _contentLengthLabel.hidden = NO;

                NSString *filePath = [ACAddress getAddressWithFileName:((ACFileMessage *) _messageData).resourceID fileType:ACFile_Type_AudioFile isTemp:NO subDirName:nil];
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                    _contentLengthLabel.text = [NSString stringWithFormat:@"%d%@", ((ACFileMessage *) message).duration, NSLocalizedString(@"sec", nil)];
                }
                else {
                    ACFileMessage *msg = (ACFileMessage *) message;
                    _contentLengthLabel.text = [self getTextWithLength:msg.length];
                }

                [_contentLengthLabel setFrame_x:[_audioPlayImageView getFrame_right] - 3];

                
                [_contentLengthLabel setFrame_width:55];
                [_contentLengthLabel setTextAlignment:NSTextAlignmentCenter];
                [_contentLengthLabel setCenter_y:_audioPlayImageView.center.y + 1];
            }
            else {
                [_chatContentLabel setFrame_width:70];

                [_chatContentBgImageView setFrame:CGRectMake(contentView.origin.x - 16, contentView.origin.y - 3, contentView.size.width + 38, contentView.size.height + 10 + 6)];
            }
            if (message.messageEnumType != ACMessageEnumType_Sticker) {
                [_timeLabel setFrame_x:_chatContentBgImageView.origin.x - _timeLabel.size.width];
                [_timeLabel setFrame_y:[_chatContentBgImageView getFrame_Bottom] - _timeLabel.size.height - 7];
            }
            else {
                [_timeLabel setFrame_x:_chatContentBgImageView.origin.x - _timeLabel.size.width + 12];
                [_timeLabel setFrame_y:[_chatContentBgImageView getFrame_Bottom] - _timeLabel.size.height - 7 - 20 - 8];
            }

            [_uploadStateButton setFrame_x:[_timeLabel getFrame_right] - _uploadStateButton.size.width];
        }
        else {
            [_timeLabel setTextAlignment:NSTextAlignmentLeft];
//            _hadReadLabel.text = @"...";
            [_hadReadLabel setHidden:YES];
            [_hadReadButton setHidden:YES];
            [_uploadStateButton setHidden:YES];
            [_chatContentBgImageView setImage:[[UIImage imageNamed:@"ReceiverVoiceNodeBkg_ios7.png"] stretchableImageWithLeftCapWidth:45 topCapHeight:30]];
            [_chatContentBgImageView setHighlightedImage:[[UIImage imageNamed:@"ReceiverVoiceNodeBkgHL_ios7.png"] stretchableImageWithLeftCapWidth:45 topCapHeight:30]];

            [_iconImageView setFrame_x:6];
            [_iconImageView setHidden:NO];
            [_nameLabel setFrame_x:[_iconImageView getFrame_right] + 4];
            if (message.messageEnumType == ACMessageEnumType_Image
                || message.messageEnumType == ACMessageEnumType_Location) {
                [_chatContentImageView setFrame_x:kReceiveChatContentImageViewBaseX];
                [self _setImageBkViewRectWithContentView:contentView andCaptionHight:_imgWithCaptionHight isSend:NO];
//                [_chatContentBgImageView setFrame:CGRectMake(contentView.origin.x - 18, contentView.origin.y - kChatContentBgImageViewBaseY, contentView.size.width + 31, contentView.size.height + kReceiveChatContentBgImageViewBaseHeight+_imgWithCaptionHight)];
            }
            else if (message.messageEnumType == ACMessageEnumType_Sticker) {
                [_chatContentImageView setFrame_x:kReceiveChatContentImageViewBaseX];
                ACStickerMessage *msg = (ACStickerMessage *) message;
                CGSize size = [ACChatMessageTableViewCell selfAdaptionSize:CGSizeMake(msg.width, msg.height)];
                [_chatContentImageView setSize:CGSizeMake(size.width, size.height)];
                _activityView.center = _chatContentImageView.center;
                [_chatContentBgImageView setFrame:CGRectMake(contentView.origin.x - 18, contentView.origin.y - kChatContentBgImageViewBaseY, contentView.size.width + 31, contentView.size.height + kReceiveChatContentBgImageViewBaseHeight)];
//                [_gifImageView setFrame:_chatContentImageView.frame];
                [_gifImageView setFrame_x:_chatContentImageView.origin.x - 8];
                [_gifImageView setFrame_y:_chatContentImageView.origin.y - 8];
//                [_gifImageView setFrame_x:_gifImageView.origin.x-8];
//                [_gifImageView setFrame_y:_gifImageView.origin.y-8];
                [_chatContentImageView setHidden:YES];
                [_gifImageView setHidden:NO];
                [_chatContentBgImageView setHidden:YES];
            }
            else if (message.messageEnumType == ACMessageEnumType_Video) {
                [_chatContentImageView setFrame_x:kReceiveChatContentImageViewBaseX];
                [_isVideoImageView setFrame_x:75];
                [_contentLengthLabel setFrame_x:122];

                [self _setImageBkViewRectWithContentView:contentView andCaptionHight:img_video_Location_bk_img_hight+6-17 isSend:NO];
//                [_chatContentBgImageView setFrame:CGRectMake(contentView.origin.x - 18, contentView.origin.y - kChatContentBgImageViewBaseY, contentView.size.width + 31, contentView.size.height + 45 + 6)];
                
                [_contentLengthLabel setTextAlignment:NSTextAlignmentRight];
                [_contentLengthLabel setFrame_width:55];
                [_contentLengthLabel setFrame_y:[_chatContentImageView getFrame_Bottom] + 3];
            }
            else if (message.messageEnumType == ACMessageEnumType_File) {
                [_chatContentLabel setFrame_x:kReceiveTextLabelBaseX + kFileWidth + 5];
                [_chatContentLabel setAutoresizeWithLimitWidth:kAutoresizeLimitWidth - 20];
                [_chatContentLabel setFrame_height:_chatContentLabel.size.height + 20];
                if (_chatContentLabel.size.width < 80) {
                    [_chatContentLabel setFrame_width:80];
                }

                NSString *extension = [[[((ACFileMessage *) _messageData) name] componentsSeparatedByString:@"."] lastObject];
                NSString *filePath = [ACAddress getAddressWithFileName:((ACFileMessage *) _messageData).resourceID fileType:ACFile_Type_File isTemp:NO subDirName:extension];

                float height = 0;
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                    
                    float heightTmp = [((ACFileMessage *) _messageData).name getHeightAutoresizeWithLimitWidth:(kAutoresizeLimitWidth-20) font:_chatContentLabel.font];
//                    float heightTmp = [AttributedLabel getHeightWithLimitWidth:kAutoresizeLimitWidth - 20 string:((ACFileMessage *) _messageData).name font:_chatContentLabel.font];
//                    if(heightTmp<50){
//                        height = 25;
//                    }
                    if (heightTmp < 30) {
                        height = 25;
                    }
                    else if (heightTmp < 48) {
                        height = 6;
                    }
                }
                else {
                    height = 25;
                }

//                [_chatContentBgImageView setFrame:CGRectMake(contentView.origin.x-16-kFileWidth, contentView.origin.y - 3, contentView.size.width+38+kFileWidth, contentView.size.height+10+height+6)];

                [_chatContentBgImageView setFrame:CGRectMake(contentView.origin.x - 19 - kFileWidth - 5, contentView.origin.y - 3, contentView.size.width + 38 + kFileWidth + 5, contentView.size.height + 10 + height + 6)];
                [_contentView setFrame_height:_chatContentBgImageView.size.height + 10];

                [_chatContentImageView setFrame_x:_chatContentLabel.origin.x - _chatContentImageView.size.width - 5];
                [_chatContentImageView setFrame_y:_chatContentLabel.origin.y + 7];

                [_contentLengthLabel setTextAlignment:NSTextAlignmentLeft];
                [_contentLengthLabel setFrame_x:_chatContentLabel.origin.x];
                [_contentLengthLabel setFrame_y:[_chatContentLabel getFrame_Bottom]];

                [_contentProgressView setFrame_x:_chatContentLabel.origin.x];
                [_contentProgressView setFrame_y:_contentLengthLabel.origin.y - 3];
                [_contentProgressView setFrame_width:_chatContentLabel.size.width];
            }
            else if (message.isTextEnumType){//message.messageEnumType == ACMessageEnumType_Text) {
                //test
                [_chatContentLabel setLineBreakMode:NSLineBreakByWordWrapping];
                [_chatContentLabel setAutoresizeWithLimitWidth:kAutoresizeLimitWidth];
                [_chatContentLabel setFrame_height:_chatContentLabel.size.height + 20];
                if (_chatContentLabel.size.width < 28) {
                    [_chatContentLabel setFrame_width:28];
                }
                
                float fLableX =  kReceiveTextLabelBaseX;
                float fBkW    =  contentView.size.width;
                if(ACMessageEnumType_Videocall==message.messageEnumType||
                   ACMessageEnumType_Audiocall==message.messageEnumType||
                   ACMessageEnumType_ShareLocation==message.messageEnumType){
                    //
                    CGRect rect = _chatContentLabel.frame;
                    [_chatContentImageView.layer setMasksToBounds:NO];
                    
                    if(ACMessageEnumType_Videocall==message.messageEnumType){
                        rect.size.width = 43/2;
                        _chatContentImageView.image = [UIImage imageNamed:@"VoipVideoCall"];
                    }
                    else if(ACMessageEnumType_ShareLocation==message.messageEnumType){
                        rect.size.width = 30/2;
                        _chatContentImageView.image = [UIImage imageNamed:@"locationSharing_Icon_Location_Main"];
                    }
                    else {
                        rect.size.width = 47/2;
                        _chatContentImageView.image = [UIImage imageNamed:@"VoipVoiceCall"];
                    }
                    rect.origin.x = kReceiveTextLabelBaseX;
                    rect.origin.y = rect.origin.y+((rect.size.height-23/2)/2);
                    
                    if(ACMessageEnumType_ShareLocation==message.messageEnumType){
                        rect.size.height = 30/2;
                    }
                    else{
                        rect.size.height = 23/2;
                    }
                    
                    fLableX += rect.size.width+5;
                    fBkW += rect.size.width+5;
                    
                    _chatContentImageView.hidden = NO;
                    _chatContentImageView.frame = rect;
                }
                [_chatContentLabel setFrame_x:fLableX];
                
                [_chatContentBgImageView setFrame:CGRectMake(kReceiveTextLabelBaseX - 19, contentView.origin.y - 3, fBkW + 38, contentView.size.height + 10 + 6)];
                [_contentView setFrame_height:_chatContentBgImageView.size.height + 10];
            }
            else if (message.messageEnumType == ACMessageEnumType_Audio) {
                
                [_audioPlayImageView setFrame_x:120];///对方发送的语音x
                [_chatContentBgImageView setFrame_height:54 + 6];
                [_chatContentBgImageView setFrame_width:100];
                [_chatContentBgImageView setCenter:CGPointMake(_audioPlayImageView.center.x - 23, _audioPlayImageView.center.y + 5)];

                [_contentProgressView setFrame_width:_chatContentBgImageView.size.width - 30];
                [_contentProgressView setCenter_x:_chatContentBgImageView.center.x + 3];
                [_contentProgressView setFrame_y:[_audioPlayImageView getFrame_Bottom] + 3];

                _contentLengthLabel.hidden = NO;
                NSString *filePath = [ACAddress getAddressWithFileName:((ACFileMessage *) _messageData).resourceID fileType:ACFile_Type_AudioFile isTemp:NO subDirName:nil];
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                    _contentLengthLabel.text = [NSString stringWithFormat:@"%d%@", ((ACFileMessage *) message).duration, NSLocalizedString(@"sec", nil)];
                }
                else {
                    ACFileMessage *msg = (ACFileMessage *) message;
                    _contentLengthLabel.text = [self getTextWithLength:msg.length];
                }

                [_contentLengthLabel setFrame_width:55];
                [_contentLengthLabel setFrame_x:_audioPlayImageView.frame.origin.x - _contentLengthLabel.size.width + 4];
                [_contentLengthLabel setTextAlignment:NSTextAlignmentCenter];
                [_contentLengthLabel setCenter_y:_audioPlayImageView.center.y + 1];
            }
            else {
                [_chatContentLabel setFrame_width:70];
                [_chatContentBgImageView setFrame:CGRectMake(contentView.origin.x - 19, contentView.origin.y - 3, contentView.size.width + 38, contentView.size.height + 10 + 6)];
            }
            if (message.messageEnumType != ACMessageEnumType_Sticker) {
                [_timeLabel setFrame_x:[_chatContentBgImageView getFrame_right]];
                [_timeLabel setFrame_y:[_chatContentBgImageView getFrame_Bottom] - 30];
            }
            else {
                [_timeLabel setFrame_x:[_chatContentBgImageView getFrame_right] - 15];
                [_timeLabel setFrame_y:[_chatContentBgImageView getFrame_Bottom] - 30 - 17];
            }
        }
        [_isVideoImageView setFrame_y:[_chatContentImageView getFrame_Bottom] + 3];

        if (message.messageEnumType == ACMessageEnumType_Video) {
            [_contentProgressView setFrame_width:_chatContentImageView.size.width - 10];
            [_contentProgressView setCenter_x:_chatContentImageView.center.x];
            [_contentProgressView setFrame_y:[_chatContentImageView getFrame_Bottom] - 6];
        }

        [_uploadStateButton setFrame_y:_timeLabel.origin.y - _uploadStateButton.size.height + 3];
        if (!_hadReadLabel.hidden) {
            [_hadReadLabel setAutoresizeWithLimitWidth:200];
            _hadReadLabel.center = CGPointMake(_uploadStateButton.center.x - 3, _uploadStateButton.center.y + 3);
            [_hadReadLabel setFrame_x:[_uploadStateButton getFrame_right] - _hadReadLabel.size.width];
            [_uploadStateButton setHidden:YES];
        }

        if (message.messageEnumType == ACMessageEnumType_Image || message.messageEnumType == ACMessageEnumType_Video || message.messageEnumType == ACMessageEnumType_Location) {
            //        [_chatContentBgImageView setFrame_y:_chatContentImageView.origin.y-5];
            //        [_chatContentBgImageView setFrame_height:_chatContentImageView.size.height+25];
            if (message.messageEnumType == ACMessageEnumType_Video) {
                [_videoPlayImageView setCenter:_chatContentImageView.center];
            }
        }
        else if (message.messageEnumType == ACMessageEnumType_Audio) {
            //        [_chatContentBgImageView setFrame_height:50];
            //        [_chatContentBgImageView setFrame_width:80];
            //        _chatContentBgImageView.center = CGPointMake(_audioPlayImageView.center.x+8, _audioPlayImageView.center.y+5);
        }


        ACUser *user = [ACUserDB getUserFromDBWithUserID:message.sendUserID];

        //组icon
        NSString *imageName = @"personIcon100.png";

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([ACUser isMySelf:message.sendUserID]) {
            [_iconImageView setImageWithIconString:[defaults objectForKey:kIcon] placeholderImage:[UIImage imageNamed:@"personIcon100.png"] ImageType:ImageType_UserIcon100];
        }
        else if (user.icon&&!superVC.isSystemChat) {
            [_iconImageView setImageWithIconString:user.icon placeholderImage:[UIImage imageNamed:imageName] ImageType:ImageType_UserIcon100];
        }
        else {
            _iconImageView.image = [UIImage imageNamed:imageName];
        }
        if (message.directionType == ACMessageDirectionType_Receive) {
            if(superVC.isSystemChat){
                _nameLabel.text =    NSLocalizedString(@"System", nil);
            }
            else {
//#if 0 //def ACUtility_Need_Log
//                _nameLabel.text = [NSString stringWithFormat:@"%@(%ld)",user.name,message.seq];
//#else
                _nameLabel.text = user.name;
//#endif
            }
            [_nameLabel setHidden:NO];
        }
        else {
            [_nameLabel setHidden:YES];
        }

        [self reloadReadButton];
        
        if(_imgWithCaptionHight){
            CGRect frame = _chatContentLabel.frame;
            frame.origin.x = _chatContentImageView.frame.origin.x;
            frame.origin.y = CGRectGetMaxY(_chatContentImageView.frame)+1;
            _chatContentLabel.frame =   frame;
            [self setHighLight];
            [_chatContentLabel setHidden:NO];
        }
    }
    else
    {
        if (message.messageEnumType == ACMessageEnumType_Sticker)
        {
            if (message.directionType == ACMessageDirectionType_Send)
            {
                [self reloadStickerWithMsg:(ACStickerMessage *)message];
                [_chatContentImageView setFrame_x:kSendChatContentImageViewBaseX+(kAutoresizeLimitWidth -  _gifImageView.size.width)];
                [_chatContentImageView setFrame_y:8];
                ACStickerMessage *msg = (ACStickerMessage *)message;
                CGSize size = [ACChatMessageTableViewCell selfAdaptionSize:CGSizeMake(msg.width, msg.height)];
                [_chatContentImageView setSize:CGSizeMake(size.width+16, size.height+16)];
                [_chatContentBgImageView setFrame:CGRectMake(_chatContentImageView.origin.x-13, _chatContentImageView.origin.y-kChatContentBgImageViewBaseY, _chatContentImageView.size.width+31, _chatContentImageView.size.height+kSendChatContentBgImageViewBaseHeight)];
                //                [_gifImageView setFrame:_chatContentImageView.frame];
                [_gifImageView setCenter:CGPointMake(_chatContentImageView.center.x, _chatContentImageView.center.y-8)];
            }
            else
            {
                [self reloadStickerWithMsg:(ACStickerMessage *)message];
                [_chatContentImageView setFrame_x:kReceiveChatContentImageViewBaseX];
                ACStickerMessage *msg = (ACStickerMessage *)message;
                CGSize size = [ACChatMessageTableViewCell selfAdaptionSize:CGSizeMake(msg.width, msg.height)];
                [_chatContentImageView setSize:CGSizeMake(size.width, size.height)];
                [_chatContentBgImageView setFrame:CGRectMake(_chatContentImageView.origin.x-18, _chatContentImageView.origin.y-kChatContentBgImageViewBaseY, _chatContentImageView.size.width+31, _chatContentImageView.size.height+kReceiveChatContentBgImageViewBaseHeight)];
                //                [_gifImageView setFrame:_chatContentImageView.frame];
                [_gifImageView setFrame_x:_chatContentImageView.origin.x-8];
                [_gifImageView setFrame_y:_chatContentImageView.origin.y-8];
            }
        }
        [self uploadStateAndReadCountReload];
    }
    
}

-(void)setMessage:(ACMessage *)message superVC:(ACChatMessageViewController *)superVC{
   
    [self _removeObserver_kProgress];
    [self _setMessageFunc:message superVC:superVC];
    [self _addObserver_kProgress];
    [self _clearRecognizer];
    
    BOOL bCanMulSelect = NO;
    
    if(ACMessageEnumType_System!=_messageData.messageEnumType){
        if(!_superVC.isMulSelect){
            UILongPressGestureRecognizer * longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(contentLongPress:)];
            [_chatContentBgImageView addGestureRecognizer:longPress];
            
            if (ACTopicPermission_ParticipantProfile_Allow == superVC.topicEntity.topicPerm.profile) {
                UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(iconImageViewTap:)];
                [_iconImageView addGestureRecognizer:tap2];
            }
            
            //加手势
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentBgImageViewTap:)];
            [_chatContentBgImageView addGestureRecognizer:tap];
            
            //加手势
            //        UITapGestureRecognizer *tap3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentBgImageViewTap2:)];
            //        tap3.numberOfTapsRequired = 2;
            //        [_chatContentBgImageView addGestureRecognizer:tap3];
            
            if (_messageData.messageEnumType == ACMessageEnumType_Sticker) {
                [_gifImageView addGestureRecognizer:longPress];
                _gifImageView.userInteractionEnabled = YES;
            }
            
            _uploadStateButton.userInteractionEnabled = YES;
            _hadReadButton.userInteractionEnabled = YES;
        }
        else{
            _uploadStateButton.userInteractionEnabled = NO;
            _hadReadButton.userInteractionEnabled = NO;
            
            if(_messageData.seq<=_superVC.topicEntity.lastestSequence&&
               _messageData.canTransmit) {
                //数据有效
                bCanMulSelect = YES;
                [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentBgImageViewTapForMulSelect:)]];
            }
        }
    }

    
//    BOOL bSubViewsFrameNeedRestore =    _bSubViewsFrameChangedForMulSelect;
#define mulSelectButton_WH  30
#define mulSelectButton_X   3
    
    
    CGFloat contentViewX = 0;
    
    if(_superVC.isMulSelect){
        if(bCanMulSelect){
            CGFloat fY = 0;
            if (message.directionType == ACMessageDirectionType_Send){
                fY  = _chatContentBgImageView.frame.origin.y+
                (_chatContentBgImageView.size.height-mulSelectButton_WH)/2;
            }
            else{
                fY  = _iconImageView.frame.origin.y+
                (_iconImageView.size.height-mulSelectButton_WH)/2;
                contentViewX    =   mulSelectButton_X+mulSelectButton_WH;
            }
            
            if(nil==_mulSelectButton){
                _mulSelectButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, mulSelectButton_WH, mulSelectButton_WH)];
                [_mulSelectButton setImage:[UIImage imageNamed:@"FriendsSendsPicturesSelectBigNIcon_ios7"] forState:UIControlStateNormal];
                [_mulSelectButton setImage:[UIImage imageNamed:@"FriendsSendsPicturesSelectBigYIcon_ios7"] forState:UIControlStateSelected];
                _mulSelectButton.userInteractionEnabled = NO;
                [self addSubview:_mulSelectButton];
            }
            
            _mulSelectButton.frame = CGRectMake(mulSelectButton_X,
                                                _contentView.frame.origin.y+fY, mulSelectButton_WH, mulSelectButton_WH);
            _mulSelectButton.selected   =   [_superVC mulSelectedMsg:_messageData forTap:NO];
            
            _mulSelectButton.hidden =   _messageData.seq>_superVC.topicEntity.lastestSequence;
        }
        else{
            _mulSelectButton.hidden = YES;
        }
    }
    else if(_mulSelectButton){
        [_mulSelectButton removeFromSuperview];
        _mulSelectButton = nil;
    }
    
    CGRect frame =  _contentView.frame;
    if(contentViewX!=frame.origin.x){
        frame.origin.x =    contentViewX;
        _contentView.frame = frame;
    }
}

-(void)reloadStickerWithMsg:(ACStickerMessage *)msg
{
    if (!_gifImageView.image)
    {
        NSString *suitID = nil;
        NSString *rid = nil;
        NSArray *array = [msg.stickerPath componentsSeparatedByString:@"/rest/apis/sticker/"];
        if ([array count] == 2)
        {
            NSString *string = [array objectAtIndex:1];
            array = [string componentsSeparatedByString:@"/image/"];
            if ([array count] == 2)
            {
                suitID = [array objectAtIndex:0];
                rid = [array objectAtIndex:1];
            }
        }
        NSString *filePath = [ACAddress getAddressWithFileName:rid fileType:ACFile_Type_DownloadSticker isTemp:NO subDirName:suitID];
        NSString *filePath2 = [ACAddress getAddressWithFileName:rid fileType:ACFile_Type_DownloadSticker isTemp:NO subDirName:kSingleSticker];
        UIImage *gif = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:filePath])
        {
            gif = [YLGIFImage imageWithContentsOfFile:filePath];
//            ITLog(gif);
        }
        else if ([fileManager fileExistsAtPath:filePath2])
        {
            gif = [YLGIFImage imageWithContentsOfFile:filePath2];
            if (gif == nil)
            {
                [fileManager removeItemAtPath:filePath2 error:nil];
            }
        }
        
        if (gif)
        {
            _activityView.hidden = YES;
            [_activityView stopAnimating];
            [_gifImageView setImage:gif];
            [_gifImageView setSize:[ACChatMessageTableViewCell selfAdaptionSize:CGSizeMake(msg.width, msg.height)]];
        }
        else
        {
            _activityView.hidden = NO;
            [_activityView startAnimating];
            [_chatContentImageView setImage:[UIImage imageNamed:@"image_placeHolder.png"]];
            //                    [[ACNetCenter shareNetCenter] getStickerWithStickerPath:msg.stickerPath stickerName:msg.stickerName messageID:msg.messageID];
            if (rid)
            {
                [[ACNetCenter shareNetCenter] downloadStickerWithResourceID:rid];
            }
        }
    }
    else
    {
        _activityView.hidden = YES;
        [_activityView stopAnimating];
        [_gifImageView setSize:[ACChatMessageTableViewCell selfAdaptionSize:CGSizeMake(msg.width, msg.height)]];
    }
}

#define Sticker_Max_WH  130
+(CGSize)selfAdaptionSize:(CGSize)size
{
    if(size.width<=Sticker_Max_WH){
        return size;
    }
    return CGSizeMake(Sticker_Max_WH, size.height * (Sticker_Max_WH / size.width));
    
    /*
    CGSize newSize = CGSizeZero;
    if (size.width > Sticker_Max_WH && size.height > Sticker_Max_WH)
    {
        if (size.width > size.height)
        {
            newSize.width = Sticker_Max_WH;
            newSize.height = (newSize.width / size.width) * size.height;
        }
        else
        {
            newSize.height = Sticker_Max_WH;
            newSize.width = (newSize.height / size.height) * size.width;
        }
    }
    else if (size.width > Sticker_Max_WH)
    {
        newSize.width = Sticker_Max_WH;
        newSize.height = size.height * (newSize.width / size.width);
    }
    else if (size.height > Sticker_Max_WH)
    {
        newSize.height = Sticker_Max_WH;
        newSize.width = size.width * (newSize.height / size.height);
    }
    else
    {
        newSize = size;
    }
    return newSize;*/
}

-(void)reloadReadButton
{
    if (![_superVC.topicEntity.mpType isEqualToString:cSingleChat])
    {
        CGRect rect = _hadReadLabel.frame;
        rect.origin.x -= 2;
        rect.size.width += 4;
        rect.origin.y -= 2;
        rect.size.height += 4;
        [_hadReadButton setFrame:rect];
    }
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [_contentView setFrame_height:self.size.height];
    ///
    [_contentView setFrame_width:kScreen_Width];
}

-(void)uploadStateAndReadCountReload
{
    if(ACMessageEnumType_System==_messageData.messageEnumType){
        return;
    }
    
    if (_messageData.directionType == ACMessageDirectionType_Send)
    {
        _uploadStateButton.hidden = NO;
        [self reloadUploadState];
        //设置已读数
        if ([[_superVC topicEntity].mpType isEqualToString:cSingleChat])
        {
//            ITLog(([NSString stringWithFormat:@"%ld %ld",_messageData.seq,[_superVC readSeq].seq]));
            if (_messageData.seq <= [_superVC readSeq].seq)
            {
                [_hadReadLabel setHidden:NO];
                _hadReadLabel.text = NSLocalizedString(@"had_read", nil);
            }
            else
            {
//                _hadReadLabel.text = @"...";
                [_hadReadLabel setHidden:YES];
            }
            [_hadReadButton setHidden:YES];
        }
        else
        {
//            NSMutableDictionary *hadReadDic = [_superVC readCountMutableDic];
//            __block ACReadCount *readCount = [hadReadDic objectForKey:[NSNumber numberWithLong:_messageData.seq]];
            ACReadCount *readCount = [_superVC getReadCountWithSeq:_messageData.seq];
            if (readCount.readCount > 0)
            {
                [_hadReadLabel setHidden:NO];
                [_hadReadButton setHidden:NO];
                _hadReadLabel.text = [NSString stringWithFormat:@"%@%ld",NSLocalizedString(@"Read by ", nil),readCount.readCount];
            }
            else
            {
                [_hadReadButton setHidden:YES];
                if (readCount && readCount.readCount == 0)
                {
                    [_hadReadLabel setHidden:YES];
                }
                else if (readCount && !readCount.succ)
                {
                    [_hadReadButton setHidden:NO];
                    [_hadReadLabel setHidden:NO];
                    _hadReadLabel.text = [NSString stringWithFormat:@"%@ ?",NSLocalizedString(@"Read by ", nil)];
                }
                else
                {
                    [_hadReadLabel setHidden:NO];
                    _hadReadLabel.text = @".....";
                    readCount.readCount = -1;
//                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                        if (!readCount)
//                        {
//                            readCount = [[ACReadCount alloc] init];
//                            readCount.topicEntityID = _superVC.topicEntity.entityID;
//                            readCount.seq = _messageData.seq;
//                            readCount.readCount = -1;
//                            [hadReadDic setObject:readCount forKey:[NSNumber numberWithLong:_messageData.seq]];
//                        }
//                        readCount.succ = NO;
//                        [self uploadStateAndReadCountReload];
//                    });
                }
            }
        }
    }
    [self setHighLight];
    if (!_hadReadLabel.hidden)
    {
        [_hadReadLabel setAutoresizeWithLimitWidth:200];
        _hadReadLabel.center = CGPointMake(_uploadStateButton.center.x-3, _uploadStateButton.center.y+3);
        [_hadReadLabel setFrame_x:[_uploadStateButton getFrame_right]-_hadReadLabel.size.width];
        [_uploadStateButton setHidden:YES];
    }
    [self reloadReadButton];
}

-(NSString *)getTextWithLength:(long)length
{
    NSString *text = nil;
    if (length/1024/1024>1024)
    {
        text = [NSString stringWithFormat:@"%3.1fg",length/1024.0/1024.0/1024.0];
    }
    else if (length/1024>1024)
    {
        text = [NSString stringWithFormat:@"%3.1fm",length/1024.0/1024.0];
    }
    else
    {
        text = [NSString stringWithFormat:@"%ldk",length/1024];
    }
    return text;
}

-(void)reloadUploadState
{
    switch (_messageData.messageUploadState)
    {
        case ACMessageUploadState_Uploading:
        case ACMessageUploadState_Transmiting:
        {
            [_uploadStateButton setUserInteractionEnabled:NO];
            [_uploadStateButton setImage:[UIImage imageNamed:@"uploading.png"] forState:UIControlStateNormal];
        }
            break;
        case ACMessageUploadState_Uploaded:
        {
            [_uploadStateButton setImage:nil forState:UIControlStateNormal];
            [_uploadStateButton setUserInteractionEnabled:NO];
        }
            break;
        case ACMessageUploadState_UploadFailed:
        case ACMessageUploadState_TransmitFailed:
        {
            [_uploadStateButton setImage:[UIImage imageNamed:@"resend.png"] forState:UIControlStateNormal];
            [_uploadStateButton setImage:[UIImage imageNamed:@"resendHighlight.png"] forState:UIControlStateHighlighted];
            [_uploadStateButton setUserInteractionEnabled:YES];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark -IBAction
-(IBAction)uploadStateButtonTouchUp:(id)sender
{
    if (_messageData.messageUploadState == ACMessageUploadState_UploadFailed ||
        _messageData.messageUploadState == ACMessageUploadState_TransmitFailed)
    {
        [_superVC resendMessage:_messageData];
    }
}

-(IBAction)hadReadButtonTouchUp:(id)sender
{
//    NSMutableDictionary *hadReadDic = [_superVC readCountMutableDic];
//    ACReadCount *readCount = [hadReadDic objectForKey:[NSNumber numberWithLong:_messageData.seq]];
    ACReadCount *readCount = [_superVC getReadCountWithSeq:_messageData.seq];
    if (readCount.readCount > 0)
    {
        [_superVC showWhoReadVCWithMsg:_messageData];
    }
    else if (!readCount.succ)
    {
        readCount.succ = YES;
        [self uploadStateAndReadCountReload];
        [_superVC getReadSeqOrReadCount];
    }
}

@end
