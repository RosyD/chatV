#import "ACChatMessageViewController.h"
#import "UINavigationController+Additions.h"
#import "ACMapViewController.h"
#import "ACDataCenter.h"
#import "ACNetCenter.h"
#import "ACVideoCall.h"
#import "ACAddress.h"
#import "ACUtility.h"
#import "UIImage+Additions.h"
#import "ACReadCount.h"
#import "ACTopicEntityDB.h"
#import "lame.h"
#import "ACTopicEntityEvent.h"
#import "ACStickerGalleryController.h"
#import "ACChatMessageViewController+Input.h"
#import "ACChatMessageViewController+Board.h"

@implementation ACChatMessageViewController(Input)
-(void)chatInputSetting
{
    self.chatInput.inputBackgroundView.image = [[UIImage imageNamed:@"Chat_Footer_BG.png"] stretchableImageWithLeftCapWidth:50 topCapHeight:22];
    
    [self.chatInput.addButton setBackgroundImage:[UIImage imageNamed:@"TypeSelectorBtn_Black_ios7.png"] forState:UIControlStateNormal];
    [self.chatInput.addButton setBackgroundImage:[UIImage imageNamed:@"TypeSelectorBtnHL_Black_ios7.png"] forState:UIControlStateHighlighted];
    
    [self.chatInput.emojiButton setBackgroundImage:[UIImage imageNamed:@"ToolViewEmotion_ios7.png"] forState:UIControlStateNormal];
    [self.chatInput.emojiButton setBackgroundImage:[UIImage imageNamed:@"ToolViewEmotionHL_ios7.png"] forState:UIControlStateHighlighted];
    
    [self.chatInput.audioButton setBackgroundImage:[UIImage imageNamed:@"ToolViewInputVoice_ios7.png"] forState:UIControlStateNormal];
    [self.chatInput.audioButton setBackgroundImage:[UIImage imageNamed:@"ToolViewInputVoiceHL_ios7.png"] forState:UIControlStateHighlighted];
    
    [self.chatInput.pressSayButton setBackgroundImage:[[UIImage imageNamed:@"OpBigBtn.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:12] forState:UIControlStateNormal];
    [self.chatInput.pressSayButton setBackgroundImage:[[UIImage imageNamed:@"OpBigBtnHighlight.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:12] forState:UIControlStateHighlighted];
    
    [self.contentView addSubview:_recordShowView];
    [_recordShowView setHidden:YES];
    [_recordShowView setCenter:_mainTableView.center];
    
    [_emojiPageC setCurrentPage:0];
    ///[_emojiScrollView setContentSize:CGSizeMake(320*4, 0)];
    NSLog(@"self.contentView.frame%@",NSStringFromCGRect(self.contentView.frame));
    [_emojiScrollView setContentSize:CGSizeMake(kScreen_Width*4, 0)];
    ///
    [_emojiScrollView setFrame_width:kScreen_Width];
    ///
    [_emojiInputView setFrame_width:kScreen_Width];
    [_emojiInputView setFrame_y:self.contentView.size.height];
    
    ///
    [self.addSelectView setFrame_width:kScreen_Width];
    [self.addSelectView setFrame_y:self.contentView.size.height];
    [self.contentView addSubview:_emojiInputView];
    [_emojiInputView setHidden:NO];
    [self.contentView addSubview:self.addSelectView];
    [self.addSelectView setHidden:NO];
}

-(void)sendMessageSuccessNotification:(NSNotification *)notification
{
    NSArray *array = notification.object;
    if (2!=[array count]){
        return;
    }
    ACMessage *message = [array objectAtIndex:0];
    NSString *sourceMessageID = [array objectAtIndex:1];
    if (![message.topicEntityID isEqualToString:_topicEntity.entityID])
    {
        ITLogEX(@"topicEntityID:%@ != msgEntityID:%@",_topicEntity.entityID,message.topicEntityID);
        return;
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (int i = (int)[_unSendMsgArray count]-1;i >= 0; i--)
        {
            ACMessage *msg = [_unSendMsgArray objectAtIndex:i];
            if (msg.seq != ACMessage_seq_DEF || [msg.messageID isEqualToString:sourceMessageID])
            {
                //避免转发Msg重复显示
                if(![_dataSourceArray containsObject:message]){
                    [_dataSourceArray addObject:message];
                    ITLogEX(@"_dataSourceArray addObject:message:\ns%@",_dataSourceArray);
                }
                
                [_unSendMsgArray removeObject:msg];
                break;
            }
        }
        [self setSendReadCountWithMessage:message];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mainTableView reloadData];
            ITLog(@"-->>_mainTableView reloadData");
        });
    });
}

-(void)sendMessageFailNotification:(NSNotification *)notification
{
    NSArray *array = notification.object;
    if (2!=[array count]){
        return;
    }
    ACMessage *message = [array objectAtIndex:0];
    NSString *sourceMessageID = [array objectAtIndex:1];
    if (![message.topicEntityID isEqualToString:_topicEntity.entityID]){
        ITLogEX(@"topicEntityID:%@ != msgEntityID:%@",_topicEntity.entityID,message.topicEntityID);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        BOOL isFind = NO;
        for (ACMessage *msg in _unSendMsgArray){
            if ([msg.messageID isEqualToString:sourceMessageID]){
                [_unSendMsgArray removeObject:msg];
                [_unSendMsgArray addObject:message];
                isFind = YES;
                break;
            }
        }
        
        if (!isFind){
            for (ACMessage *msg in _dataSourceArray){
                if ([msg.messageID isEqualToString:sourceMessageID]){
                    [_dataSourceArray removeObject:msg];
                    [_unSendMsgArray addObject:message];
                    isFind = YES;
                    break;
                }
            }
        }
        
        if (isFind){
            dispatch_async(dispatch_get_main_queue(), ^{
                [_mainTableView reloadData];
            });
            ITLog(@"-->>_mainTableView reloadData");
        }
    });
}

-(void)ACTopicEntityDB_TopicEntityDraft_save:(NSString*) pStr{
    //数据不同才保存
    if(0==_pDraft.length&&0==pStr.length){
        //都为空
        return;
    }
    
    if([_pDraft isEqualToString:pStr]){
        //相同
        return;
    }
    _pDraft = pStr;
    ACTopicEntityDB_TopicEntityDraft_save(_topicEntity,pStr);
}


#pragma mark -send
-(void)setSendReadCountWithMessage:(ACMessage *)message
{
    ACReadCount *readCount = [[ACReadCount alloc] init];
    readCount.readCount = 0;
    readCount.seq = message.seq;
    readCount.topicEntityID = message.topicEntityID;
    [_readCountMutableDic setObject:readCount forKey:[NSNumber numberWithLong:readCount.seq]];
}

- (IBAction)sendButtonPressed:(id)sender
//发送消息
{
    //发送后键盘不消失，点击和拖拽tableView键盘消失
    //    [self resignKeyBoard:nil];
    NSString *textTmp = [self.chatInput.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    //清除草稿
    [self ACTopicEntityDB_TopicEntityDraft_save:nil];
    
    if ([textTmp length] > 0)
    {
        ACTextMessage *message = (ACTextMessage *)[ACMessage createMessageWithMessageType:ACMessageType_text
                                                                             topicEnitity:_topicEntity
                                                                           messageContent:textTmp
                                                                                sendMsgID:nil
                                                                                 location:nil];
        [_dataSourceArray addObject:message];
//        ITLog(_dataSourceArray);
        //        [_mainTableView reloadData];
        //        ITLog(@"-->>_mainTableView reloadData");
        [self tableViewScrollToBottomWithAnimated:YES];
        if ([message.content length]!=0)
        {
            [[ACNetCenter shareNetCenter].chatCenter sendMessage:message];
        }
        
        self.chatInput.textView.text = @"";
        [self.chatInput fitText];
    }
}

-(void)showAudioInput:(id)sender
{
    if (self.chatInput.inputType != inputType_Text)
    {
        [self resignKeyBoard:nil];
    }
}

-(void)resignKeyBoard:(id)sender
{
    if (self.chatInput.inputState)
    {
        [self.chatInput.textView resignFirstResponder];
        self.chatInput.inputType = inputType_Text;
        self.chatInput.inputState = NO;
        _currentHeight = 0;
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.25];
        [UIView setAnimationCurve:7];
        
        [self emojiSelectHide];
        
        float y = self.contentView.size.height-self.chatInput.size.height;
        [self.chatInput setFrame_y:y];
        if (!_emojiInputView.hidden)
        {
            [_emojiInputView setFrame_y:self.contentView.size.height];
        }
        if (!self.addSelectView.hidden)
        {
            [self.addSelectView setFrame_y:self.contentView.size.height];
        }
        
        [UIView commitAnimations];
        
        [self tableViewFitInput];
    }
}

- (void) showEmojiInput:(id)sender {
    
    if ([_suitArray count] == 0)
    {
        [self showStickerShop:sender];
    }
    else
    {
        if (self.chatInput.inputType != inputType_Emoji)
        {
            self.chatInput.inputType = inputType_Emoji;
            if ([self.chatInput.textView isFirstResponder] == YES) [self.chatInput.textView resignFirstResponder];
        }
        
        [self emojiSelectHide];
        
        [_emojiInputView setHidden:NO];
        [_emojiInputView setFrame_x:0];
        [_emojiInputView setFrame_y:self.contentView.size.height];
        
        if (self.chatInput.inputState)
        {
            //self.addSelectView做背景
            [self.addSelectView setFrame_y:self.contentView.size.height-_currentHeight];
            [self.addSelectView setHidden:NO];
        }
        _currentHeight = kEmojiBoardHeight;
        
        [self.contentView bringSubviewToFront:_emojiInputView];
        float y = (self.contentView.size.height-kEmojiBoardHeight)-self.chatInput.size.height;
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.25];
        [UIView setAnimationCurve:7];
        
        float frame_y = self.contentView.size.height-kEmojiBoardHeight;
        [self.addSelectView setFrame_y:frame_y];
        [_emojiInputView setFrame_y:frame_y];
        self.chatInput.inputState = YES;
        [self.chatInput setFrame_y:y];
        
        [UIView commitAnimations];
        
        [self tableViewFitInput];
    }
}

-(void)showStickerShop:(id)sender
{
    ACStickerGalleryController *stickerGalleryC = [[ACStickerGalleryController alloc] initWithSuperVC:self];
    [self.navigationController pushViewController:stickerGalleryC animated:YES];
}

-(void)showAddInput:(id)sender
{
    [self.addSelectView setHidden:NO];
    [self emojiSelectHide];
    [_emojiInputView setHidden:YES];
    
    [self.addSelectView setFrame_x:0];
    [self.addSelectView setFrame_y:self.contentView.size.height];
    float y = (self.contentView.size.height-kEmojiBoardHeight)-self.chatInput.size.height;
    
    //在输入状态下直接设置self.addSelectView的y,动态设置self.chatInput的y
    if (self.chatInput.inputState)
    {
        [self.addSelectView setFrame_y:self.contentView.size.height-_currentHeight];
        self.chatInput.inputState = YES;
    }
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.25];
    [UIView setAnimationCurve:7];
    
    //非输入状态下动画设置self.addSelectView和self.chatInput的y
    if (!self.chatInput.inputState)
    {
        [self.addSelectView setFrame_y:self.contentView.size.height-kEmojiBoardHeight];
        self.chatInput.inputState = YES;
    }
    else
    {
        if (_currentHeight != kEmojiBoardHeight)
        {
            [self.addSelectView setFrame_y:self.contentView.size.height-kEmojiBoardHeight];
        }
    }
    _currentHeight = kEmojiBoardHeight;
    [self.chatInput setFrame_y:y];
    
    [UIView commitAnimations];
    
    [self tableViewFitInput];
}

-(BOOL)sendFile:(NSString*) strFileName withFileDataBlock:(void (^)(NSString*))pFileDataBlock{
    
    ACFileMessage *message = (ACFileMessage *)[ACMessage createMessageWithMessageType:ACMessageType_file
                                                                         topicEnitity:_topicEntity
                                                                       messageContent:nil
                                                                            sendMsgID:nil
                                                                             location:nil];
    
    NSString *extension = [[strFileName componentsSeparatedByString:@"."] lastObject];
    
    NSString *contact_file_PathName = [ACAddress getAddressWithFileName:message.resourceID fileType:ACFile_Type_File isTemp:NO subDirName:extension];
    
    //写文件
    pFileDataBlock(contact_file_PathName);
    
    //    [pVC saveVcfFile:contact_file_PathName];
    
    long length = [ACUtility getFileSizeWithPath:contact_file_PathName];
    NSAssert(length>0,@"%@写失败",strFileName);
    if(length<=0){
        return NO;
    }
    NSMutableDictionary *postDic1 = [NSMutableDictionary dictionaryWithDictionary:[message.content objectFromJSONString]];
    [postDic1 setObject:[NSNumber numberWithLong:length] forKey:kLength];
    [postDic1 setObject:strFileName forKey:kName];
    message.content = [postDic1 JSONString];
    
    [_dataSourceArray addObject:message];
    ITLog(_dataSourceArray);
    dispatch_async(dispatch_get_main_queue(), ^{
        //        [_mainTableView reloadData];
        //        ITLog(@"-->>_mainTableView reloadData");
        [self tableViewScrollToBottomWithAnimated:YES];
    });
    
    [[ACNetCenter shareNetCenter].chatCenter sendMessage:message];
    return YES;
}

#pragma mark -keyboardNotification

BOOL bNeedAnimation = YES;
-(void)keyboardInputModeChanged:(NSNotification *)noti{
    NSString *inputMethod = [[UIApplication sharedApplication]textInputMode].primaryLanguage;
//[[UITextInputMode currentInputMode] primaryLanguage];
    bNeedAnimation = YES;
    if([inputMethod hasPrefix:@"en-"]&&
       UITextAutocorrectionTypeNo!=self.chatInput.textView.autocorrectionType){
        UITextAutocorrectionType old = self.chatInput.textView.autocorrectionType;
//        _isAppear = NO;
//        bNeedAnimation = NO;
        self.chatInput.textView.autocorrectionType = UITextAutocorrectionTypeNo;
//        [self.chatInput.textView resignFirstResponder];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            _isAppear = YES;
            self.chatInput.textView.autocorrectionType = old;
//            [self.chatInput.textView becomeFirstResponder];
            [self.chatInput.textView insertText:@" "];
            [self.chatInput.textView deleteBackward];
            ITLog(@"");
        });
    }
}

-(void)keyboardWillShow:(NSNotification *)noti
{
    
    if (_isAppear)
    {
        NSDictionary *info      = [noti userInfo];
        CGSize size             = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
        _currentHeight          = size.height;
        
        NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        int curve               = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];

        float currentY          = self.contentView.size.height-size.height;
        
        if(bNeedAnimation){
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:duration];
            [UIView setAnimationCurve:curve];
            //设置y跟踪键盘显示,做动画
            [self.chatInput setFrame_y:currentY-self.chatInput.size.height];
            //        [_haveNewMsgButton setFrame_y:self.chatInput.frame.origin.y-_haveNewMsgButton.frame.size.height];
            
            [UIView commitAnimations];
        }
        else{
            [self.chatInput setFrame_y:currentY-self.chatInput.size.height];
            bNeedAnimation = YES;
        }
        
        
        
        self.chatInput.inputState = YES;
        [self tableViewFitInput];
    }
}

-(void)keyboardWillHide:(NSNotification *)noti
{
    if (_isAppear)
    {
        if (self.chatInput.inputType == inputType_Text /*&& !_isActionSheetKeyboardHide*/)
        {
            NSDictionary *info = [noti userInfo];
            NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
            int curve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
            
            _currentHeight = 0;
            
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:duration];
            [UIView setAnimationCurve:curve];
            
            //设置y跟踪键盘隐藏,做动画
            [self.chatInput setFrame_y:self.contentView.size.height-self.chatInput.size.height];
            //            [_haveNewMsgButton setFrame_y:self.chatInput.frame.origin.y-_haveNewMsgButton.frame.size.height];
            
            [UIView commitAnimations];
            
            self.chatInput.inputState = NO;
            [self tableViewFitInput];
        }
        else
        {
//            _isActionSheetKeyboardHide = NO;
        }
    }
}

#pragma mark -tableViewFitInput
//传过来键盘高度，让tableView适应高度调整
-(void)tableViewFitInput
{
    if (_mainTableView.contentOffset.y+10 >= _mainTableView.contentSize.height - _mainTableView.size.height)
    {
    }
    else
    {
        _mainTableView.contentOffset = CGPointMake(0, _mainTableView.contentSize.height - _mainTableView.size.height);
    }
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.25];
    [UIView setAnimationCurve:7];
    
    
    [_mainTableView setFrame_height:self.contentView.size.height-50-_currentHeight];
    if (self.chatInput.inputState)
    {
        [_tableViewShadeView setFrame:_mainTableView.frame];
        [_tableViewShadeView setHidden:NO];
    }
    else
    {
        [_tableViewShadeView setHidden:YES];
    }
    [_haveNewMsgButton setFrame_y:self.chatInput.frame.origin.y-_haveNewMsgButton.frame.size.height];
    
    
    [UIView commitAnimations];
    
    [_mainTableView reloadData];
    ITLog(@"-->>_mainTableView reloadData");
    
    float y = _mainTableView.contentSize.height-_mainTableView.size.height;
    if (y < 0)
    {
        y = 0;
    }
    [_mainTableView setContentOffset:CGPointMake(0, y)];
}

#pragma mark - resendMsg
-(void)resendMessage:(ACMessage *)message
{
    _resendMessage = message;
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Do you want to resend?", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                         destructiveButtonTitle:NSLocalizedString(@"Delete", nil)
                                              otherButtonTitles:NSLocalizedString(@"Resend", nil), nil];
    sheet.tag = kActionSheetTag_Resend;
    [sheet showInView:self.contentView];
}


-(void)sendMessageReadedToServer:(long)sendSequence{
    
    if(_isAppear&&LoginState_logined==[ACConfigs shareConfigs].loginState){
        
        [ACTopicEntityEvent updateDidReadWithTopicEntity:_topicEntity];
        [[ACNetCenter shareNetCenter] hasBeenReadTopicEntityWithEntityID:_topicEntity.entityID
                                                            withSequence:sendSequence];
        
        _lNeedSendToMessageReadedSequence = 0;
        
        return;
    }
    _lNeedSendToMessageReadedSequence =   sendSequence;
}


#pragma mark -pressSayButton
-(void)pressSayButtonDown:(id)sender
{
    [_audioPlayer stop];
    [self audioPlayerDidFinishPlaying:nil successfully:NO];
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            [_recordShowView setHidden:NO];
            [_recordShowView.layer setCornerRadius:5.0];
            [_recordShowView.layer setMasksToBounds:YES];
            _recordShowLabel.text = NSLocalizedString(@"Take_Off_Cancel", nil);
            [self recordAudio];
        } else {
            // 可以显示一个提示框告诉用户这个app没有得到允许？
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Please open microphone support", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
            [alert show];
        }
    }];
}

-(void)pressSayButtonUpInside:(id)sender
{
    [_recordShowView setHidden:YES];
    _recordAudioNeedSend = YES;
    [_audioRecorder stop];
    _audioRecorder = nil;
}

-(void)pressSayButtonUpOutside:(id)sender
{
    [_recordShowView setHidden:YES];
    _recordAudioNeedSend = NO;
    [_audioRecorder stop];
    _audioRecorder = nil;
}

-(void)pressSayButtonDragInside:(id)sender
{
    _recordShowLabel.text = NSLocalizedString(@"Take_Off_Cancel", nil);
}

-(void)pressSayButtonDragOutside:(id)sender
{
    _recordShowLabel.text = NSLocalizedString(@"Release_Off_Cancel", nil);
}

#pragma mark recordAudio
#define kSampleRate             ([ACConfigs isPhone5]?44100:44100)

-(void)recordAudio
{
    //录音设置
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc]init];
    //设置录音格式  AVFormatIDKey==kAudioFormatLinearPCM
    if (![ACConfigs isPhone5])
    {
        [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    }
    else
    {
        [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    }
    
    //设置录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）
    [recordSetting setValue:[NSNumber numberWithFloat:kSampleRate] forKey:AVSampleRateKey];
    //录音通道数  1 或 2
    int channels = 2;
    if (![ACConfigs isPhone5])
    {
        channels = 1;
    }
    [recordSetting setValue:[NSNumber numberWithInt:channels] forKey:AVNumberOfChannelsKey];
    //线性采样位数  8、16、24、32
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    //录音的质量
    if (![ACConfigs isPhone5])
    {
        [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityLow] forKey:AVEncoderAudioQualityKey];
    }
    else
    {
        [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityLow] forKey:AVEncoderAudioQualityKey];
    }
    
    _sendAudioMsgID = [ACMessage getTempMsgID];
    NSString *recordAudioPath = [ACAddress getAddressWithFileName:_sendAudioMsgID
                                                         fileType:ACFile_Type_AudioFile
                                                           isTemp:YES
                                                       subDirName:nil];
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:recordAudioPath] settings:recordSetting error:&error];
    ITLog(error);
    _audioRecorder.meteringEnabled = YES;
    _audioRecorder.delegate = self;
    
    if ([_audioRecorder prepareToRecord])
    {
        [_audioRecorder record];
        _recordStartTI = [[NSDate date] timeIntervalSince1970];
    }
    
    [_recordShowTimer invalidate];
    _recordShowTimer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(levelTimerCallback:) userInfo:nil repeats:YES];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    [_recordShowTimer invalidate];
    _recordShowTimer = nil;
    if([ACVideoCall inVideoCall]){
        return;
    }
    
    int duration = [[NSDate date] timeIntervalSince1970]-_recordStartTI;
    _recordAudioDuration = duration;
    ITLog(([NSString stringWithFormat:@"%d",duration]));
    if (duration > 1)
    {
        if (flag && _recordAudioNeedSend)
        {
            NSString *recordAudioPath = [ACAddress getAddressWithFileName:_sendAudioMsgID fileType:ACFile_Type_AudioFile isTemp:YES subDirName:nil];
            NSString *mp3Path = [ACAddress getAddressWithFileName:_sendAudioMsgID fileType:ACFile_Type_AudioFile isTemp:NO subDirName:nil];
            [self toMp3FromSourcePath:recordAudioPath mp3Path:mp3Path];
        }
    }
    else
    {
        if (_recordAudioNeedSend)
        {
            [self.contentView showProgressHUDNoActivityWithLabelText:NSLocalizedString(@"Record time is too short", nil) withAfterDelayHide:1];
        }
    }
}


-(void)AACAudioConverterDidFinishConversion:(TPAACAudioConverter *)converter {
    [self performSelectorOnMainThread:@selector(convertMp3Finish:)
                           withObject:converter.destination
                        waitUntilDone:YES];
    _audioConverter = nil;
}

-(void)AACAudioConverter:(TPAACAudioConverter *)converter didFailWithError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Converting audio", @"")
                                message:[NSString stringWithFormat:NSLocalizedString(@"Couldn't convert audio: %@", @""), [error localizedDescription]]
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:NSLocalizedString(@"OK", @""), nil] show];
    _audioConverter = nil;
}

- (void) toMp3FromSourcePath:(NSString *)sourcePath mp3Path:(NSString *)mp3Path
{
    if (![ACConfigs isPhone5])
    {
        if ( ![TPAACAudioConverter AACConverterAvailable] ) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Converting audio", @"")
                                        message:NSLocalizedString(@"Couldn't convert audio: Not supported on this device", @"")
                                       delegate:nil
                              cancelButtonTitle:nil
                              otherButtonTitles:NSLocalizedString(@"OK", @""), nil] show];
            return;
        }
        
        _audioConverter = [[TPAACAudioConverter alloc] initWithDelegate:self
                                                                 source:sourcePath
                                                            destination:mp3Path];
        
        [_audioConverter start];
        return;
    }
    @try {
        int read, write;
        
        FILE *pcm = fopen([sourcePath cStringUsingEncoding:1], "rb");  //source
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([mp3Path cStringUsingEncoding:1], "wb");  //output
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, kSampleRate);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        do {
            read = (int)fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
        [self performSelectorOnMainThread:@selector(convertMp3Finish:)
                               withObject:mp3Path
                            waitUntilDone:YES];
    }
}

-(void)convertMp3Finish:(NSString *)mp3Path
{
    long length = [ACUtility getFileSizeWithPath:mp3Path];
    NSDictionary *postDic = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d",_recordAudioDuration],kDuration,[NSNumber numberWithLong:length],kLength, nil];
    ACFileMessage *message = (ACFileMessage *)[ACMessage createMessageWithMessageType:ACMessageType_audio topicEnitity:_topicEntity messageContent:[postDic JSONString] sendMsgID:_sendAudioMsgID location:nil];
    [_dataSourceArray addObject:message];
    ITLog(_dataSourceArray);
    //    [_mainTableView reloadData];
    //    ITLog(@"-->>_mainTableView reloadData");
    [self tableViewScrollToBottomWithAnimated:YES];
    [[ACNetCenter shareNetCenter].chatCenter sendMessage:message];
    
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    ITLog(error);
}

- (void)levelTimerCallback:(NSTimer *)timer {
    [_audioRecorder updateMeters];
    
    float level; // The linear 0.0 .. 1.0 value we need.
    float minDecibels = -80.0f; // Or use -60dB, which I measured in a silent room.
    float decibels = [_audioRecorder peakPowerForChannel:0];
    if (decibels < minDecibels)
    {
        level = 0.0f;
    }
    else if (decibels >= 0.0f)
    {
        level = 1.0f;
    }
    else
    {
        float root = 2.0f;
        float minAmp = powf(10.0f, 0.05f * minDecibels);
        float inverseAmpRange = 1.0f / (1.0f - minAmp);
        float amp = powf(10.0f, 0.05f * decibels);
        float adjAmp = (amp - minAmp) * inverseAmpRange;
        
        level = powf(adjAmp, 1.0f / root);
    }
    
    int index = level*12+1;
    //    NSLog(@"平均值 %d", index);
    if (index < 1)
    {
        index = 1;
    }
    if (index > 10)
    {
        index = 10;
    }
    [_recordShowImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"VoiceSearchFeedback00%d_ios7.png",index]]];
}




@end
