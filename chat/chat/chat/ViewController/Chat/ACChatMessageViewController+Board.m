#import "ACChatMessageViewController.h"
#import "UINavigationController+Additions.h"
#import "ACMapViewController.h"
#import "ACDataCenter.h"
#import "ACNetCenter.h"
#import "ACVideoCall.h"
#import "ACAddress.h"
#import "ACUtility.h"
#import "ACMyStickerController.h"
#import "ACChatMessageTableViewCell.h"
#import "UIImage+Additions.h"
#import "ACChatMessageViewController+Board.h"
#import "ACChatMessageViewController+Input.h"
#import "ACChatMessageViewController+Tap.h"
#import "ACUserDB.h"

#import "AC_PreViewImagesWithCaption.h"

#define kAddBoardFixedSpaceWidth    20
#define kAddBoardIconWidth          54
///
#define kFaceButtonWidth            70
#define kAddBoardFixedSpaceWidth    ((kScreen_Width - kAddBoardIconWidth*4)/5)
#define kAddBoardEmojiSpaceWidth    ((kScreen_Width - kFaceButtonWidth*4)/5)
#define kAddBoardIconY              10
#define kAddBoardItemHeight         95



#define kSingleScreenFaceCount      21
#define kSingleScreenStickerCount   8
#define kEmojiButtonTag             1090

#define kGrayColor [UIColor colorWithRed:236/255.0 green:236/255.0 blue:236/255.0 alpha:1]

extern const CFStringRef kUTTypeImage;
extern const CFStringRef kUTTypeMovie;


@implementation ACChatMessageViewController(Borad)

-(void)addBoardSetting
{
    
    float line,row;
    
    //    int nBoardCount = ([_topicEntity.mpType isEqualToString:cSingleChat]&&0==_topicEntity.relateType.length)?addBoardItemType_Chat_With_Location:addBoardItemType_Chat_RadioCall;
    //只有单独对话时才有addBoardItemType_Chat_With_*
    
    int nBoardCount = 0;
    if([_topicEntity.mpType isEqualToString:cSingleChat]&&0==_topicEntity.relateType.length){
        //单独对话
        nBoardCount =   addBoardItemType_Chat_With_Location;
       /// [_addScrollView setContentSize:CGSizeMake(320, _addScrollView.frame.size.height+kAddBoardItemHeight)];
        [_addScrollView setContentSize:CGSizeMake(kScreen_Width, _addScrollView.frame.size.height+kAddBoardItemHeight)];
    }
    else{
        nBoardCount =   addBoardItemType_Chat_With_Destrct-1;
       /// [_addScrollView setContentSize:CGSizeMake(320, 0)];
        [_addScrollView setContentSize:CGSizeMake(kScreen_Width, 0)];
    }
    
    for (int i = addBoardItemType_Photo; i <= nBoardCount; i++){
        row = i%4;
        line = i/4;
        
        ///UIButton *iconButton = [[UIButton alloc] initWithFrame:CGRectMake((row+1)*kAddBoardFixedSpaceWidth+row*kAddBoardIconWidth, kAddBoardIconY+line*kAddBoardItemHeight, 54, 54)];
         UIButton *iconButton = [[UIButton alloc] initWithFrame:CGRectMake((row+1)*kAddBoardFixedSpaceWidth+row*kAddBoardIconWidth, kAddBoardFixedSpaceWidth/2+line*(kAddBoardItemHeight +5), kAddBoardIconWidth, kAddBoardIconWidth)];
        
        [_addScrollView addSubview:iconButton];
        iconButton.tag = line*100+row*10;
        [iconButton.layer setMasksToBounds:YES];
        [iconButton.layer setCornerRadius:5.0];
        
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(iconButton.origin.x-(70-54)/2, [iconButton getFrame_Bottom]+5, 70, 20)];
        [_addScrollView addSubview:nameLabel];
        nameLabel.tag = line*100+row*10+1;
        [nameLabel setFont:[UIFont systemFontOfSize:12]];
        [nameLabel setTextAlignment:NSTextAlignmentCenter];
        
        switch (i)
        {
            case addBoardItemType_Photo:
            {
                [iconButton setBackgroundImage:[UIImage imageNamed:@"sharemore_pic_ios7.png"] forState:UIControlStateNormal];
                nameLabel.text = NSLocalizedString(@"Photo", nil);
                [iconButton addTarget:self action:@selector(photoButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
            }
                break;
            case addBoardItemType_Camera:
            {
                [iconButton setBackgroundImage:[UIImage imageNamed:@"sharemore_video_ios7.png"] forState:UIControlStateNormal];
                nameLabel.text = NSLocalizedString(@"Camera", nil);
                [iconButton addTarget:self action:@selector(cameraButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
            }
                break;
            case addBoardItemType_Video:
            {
                [iconButton setBackgroundImage:[UIImage imageNamed:@"sharemore_voiceinput_ios7.png"] forState:UIControlStateNormal];
                nameLabel.text = NSLocalizedString(@"Video_Library", nil);
                [iconButton addTarget:self action:@selector(videoButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
            }
                break;
            case addBoardItemType_VCamera:
            {
                [iconButton setBackgroundImage:[UIImage imageNamed:@"sharemore_videovoip_ios7.png"] forState:UIControlStateNormal];
                nameLabel.text = NSLocalizedString(@"Video_Camera", nil);
                [iconButton addTarget:self action:@selector(videoRecordButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
            }
                break;
            case addBoardItemType_Location:
            {
                [iconButton setBackgroundImage:[UIImage imageNamed:@"sharemore_location_ios7.png"] forState:UIControlStateNormal];
                nameLabel.text = NSLocalizedString(@"Location", nil);
                [iconButton addTarget:self action:@selector(locationButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
            }
                break;
            case addBoardItemType_Contact:
            {
                [iconButton setBackgroundImage:[UIImage imageNamed:@"v2_ic_option_contact.png"] forState:UIControlStateNormal];
                nameLabel.text = NSLocalizedString(@"chat_msgtype_contact", nil);
                [iconButton addTarget:self action:@selector(chat_msgtype_contact_ButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
            }
                break;
#ifdef addBoardItemType_Video_Call_Allow
            case addBoardItemType_Chat_VideoCall:
            {
                [iconButton setBackgroundImage:[UIImage imageNamed:@"videocall_video"] forState:UIControlStateNormal];
                nameLabel.text = NSLocalizedString(@"VideoCall_msgType_Video", nil);
                iconButton.tag  =   addBoardItemType_Chat_VideoCall;
                [iconButton addTarget:self action:@selector(chat_msgtype_videocall_ButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
                
            }
                break;
            case addBoardItemType_Chat_RadioCall:
            {
                [iconButton setBackgroundImage:[UIImage imageNamed:@"videocall_radio"] forState:UIControlStateNormal];
                iconButton.tag  =   addBoardItemType_Chat_RadioCall;
                nameLabel.text = NSLocalizedString(@"VideoCall_msgType_Radio", nil);
                [iconButton addTarget:self action:@selector(chat_msgtype_videocall_ButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
            }
                break;
#endif
            case addBoardItemType_Chat_With_Destrct:
            {
                [iconButton setBackgroundImage:[UIImage imageNamed:@"v2_ic_option_attach_desruct.png"] forState:UIControlStateNormal];
                nameLabel.text = NSLocalizedString(@"chat_option_destrct", nil);
                [iconButton addTarget:self action:@selector(chat_option_destrct_ButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
            }
                break;
            case addBoardItemType_Chat_With_Location:
            {
                [iconButton setBackgroundImage:[UIImage imageNamed:@"v2_ic_option_attach_locaton.png"] forState:UIControlStateNormal];
                nameLabel.text = NSLocalizedString(@"chat_option_location", nil);
                [iconButton addTarget:self action:@selector(chat_option_location_ButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
            }
                break;
                
            default:
                break;
        }
    }
}

-(void)faceBoardSetting
{
    if (0 < [_suitArray count])
    {
        ACSuit *suit = nil;
        if ([_suitArray count] > [ACConfigs shareConfigs].currentSuitIndex)
        {
            suit = [_suitArray objectAtIndex:[ACConfigs shareConfigs].currentSuitIndex];
        }
        else
        {
            suit = [_suitArray lastObject];
        }
        
        _currentSuitID = suit.suitID;
        
        [self stickerSettingWithSuit:suit];
        
        ///[_emojiButtonScrollView setFrame_width:270];
        [_emojiButtonScrollView setFrame_width:kScreen_Width - 50];
        _sendButton.hidden = YES;
    }
    [_emojiButtonLineView setFrame_width:_emojiButtonScrollView.size.width];
    //    NSArray *array = [ACDataCenter shareDataCenter].stickerPackageArray;
    //    if (0 < [array count])
    //    {
    //        ACStickerPackage *package = [array objectAtIndex:0];
    //        [self.currentPackage removeObserver:self forKeyPath:kProgress];
    //
    //        self.currentPackage = package;
    //        [self.currentPackage addObserver:self forKeyPath:kProgress options:NSKeyValueObservingOptionNew context:nil];
    //
    //        [self stickerSettingWithStickerPackage:package];
    //        [_emojiButtonScrollView setFrame_width:310];
    //        _sendButton.hidden = YES;
    //    }
    //     [_emojiButtonLineView setFrame_width:_emojiButtonScrollView.size.width];
    
    //    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    //
    //        self.faceMap = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"faceMap_ch" ofType:@"plist"]];
    //        int faceCount = (int)[_faceMap count];
    //        dispatch_async(dispatch_get_main_queue(), ^{
    //            [_stickerDownloadView setHidden:YES];
    //            for (UIView *view in [_emojiScrollView subviews])
    //            {
    //                [view removeFromSuperview];
    //            }
    //            for (int i = 1; i <= faceCount; i++)
    //            {
    //                FaceButton *faceButton = [FaceButton buttonWithType:UIButtonTypeCustom];
    //                faceButton.buttonIndex = i;
    //
    //                [faceButton addTarget:self
    //                               action:@selector(faceButtonTouchUp:)
    //                     forControlEvents:UIControlEventTouchUpInside];
    //
    //                //计算每一个表情按钮的坐标和在哪一屏
    //                faceButton.frame = CGRectMake((((i-1)%kSingleScreenFaceCount)%7)*44+6+((i-1)/kSingleScreenFaceCount*320), (((i-1)%kSingleScreenFaceCount)/7)*44+8, 44, 44);
    //
    //                NSString *imageName = [_faceMap objectForKey:[NSString stringWithFormat:@"%03d",i]];
    //                imageName = [imageName stringByAppendingString:@".png"];
    //
    //                [faceButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    //                [_emojiScrollView addSubview:faceButton];
    //
    //                if (i%kSingleScreenFaceCount == 0)
    //                {
    //                    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    //                    [deleteButton addTarget:self action:@selector(deleteButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    //                    deleteButton.frame = CGRectMake(275+320*(i/kSingleScreenFaceCount-1), 140, 40, 30);
    //                    [deleteButton setImage:[UIImage imageNamed:@"backFace.png"] forState:UIControlStateNormal];
    //                    [_emojiScrollView addSubview:deleteButton];
    //                }
    //            }
    //            _currentPageCount = faceCount/21+(faceCount%21!=0);
    //            [_emojiScrollView setContentSize:CGSizeMake(320*_currentPageCount, 0)];
    //            [_emojiScrollView setContentOffset:CGPointMake(0, 0)];
    //            [_emojiPageC setNumberOfPages:_currentPageCount];
    //            [_emojiPageC setCurrentPage:0];
    //            [_emojiPageC setFrame_y:145];
    //        });
    //    });
}

#pragma mark -发送图片、视频、位置等
-(void)photoButtonTouchUp:(id)sender //发送图片
{
#ifdef ACChatMessageVC_SendOneImgWithPrew
    [self selectImageWithUIImagePickerController_Delegate:self forCamera:NO];
#else
    [self selectImagesWithELC_Delegate:self withCount:10];
#endif
    
    /*
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
#ifdef ACChatMessageVC_SendOneImgWithPrew
        UIImagePickerController *imagePC = [[UIImagePickerController alloc] init];
        imagePC.delegate = self;
        //        imagePC.allowsEditing = YES;
        imagePC.videoQuality = UIImagePickerControllerQualityType640x480;
        imagePC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self ACpresentViewController:imagePC animated:YES completion:nil];
#else
        ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] initImagePicker];
        
        elcPicker.returnsOriginalImage = YES; //Only return the fullScreenImage, not the fullResolutionImage
        elcPicker.returnsImage = YES; //Return UIimage if YES. If NO, only return asset location information
        //        elcPicker.onOrder = NO; //For multiple image selection, display and return order of selected images
        //        elcPicker.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie]; //Supports image and movie types
        //        [ELCConsole mainConsole]
        elcPicker.maximumImagesCount  = 10;//Set the maximum number of images to select to 100
//        elcPicker.mediaTypes          = @[(__bridge NSString *)kUTTypeImage];
        elcPicker.imagePickerDelegate = self;
        
        [self ACpresentViewController:elcPicker animated:YES completion:nil];
#endif
    }*/
}

-(void)cameraButtonTouchUp:(id)sender
{
     [self selectImageWithUIImagePickerController_Delegate:self forCamera:YES];
    /*
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        UIImagePickerController *imagePC = [[UIImagePickerController alloc] init];
        imagePC.delegate = self;
        imagePC.videoQuality = UIImagePickerControllerQualityType640x480;
        imagePC.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePC.mediaTypes = @[(__bridge NSString *)kUTTypeImage];
        [self ACpresentViewController:imagePC animated:YES completion:nil];
    }*/
}

-(void)locationButtonTouchUp:(id)sender
{
    //    ACSendLocationViewController *sendLocationVC = [[ACSendLocationViewController alloc] initWithSuperVC:self];
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"Send Location", nil),NSLocalizedString(@"Real-time Location", nil), nil];
    
    actionSheet.tag = kActionSheetTag_Location;
    [actionSheet showInView:self.contentView];
}

-(void)videoRecordButtonTouchUp:(id)sender
{
    [self videoWithUIImagePickerController_Delegate:self fromRecord:YES];
    /*
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        UIImagePickerController *imagePC = [[UIImagePickerController alloc] init];
        imagePC.delegate = self;
        imagePC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        imagePC.mediaTypes = @[(__bridge NSString *)kUTTypeMovie];
        imagePC.videoQuality = UIImagePickerControllerQualityTypeMedium;
        imagePC.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePC.videoMaximumDuration = Send_Video_Maximum_Duration;
        [self ACpresentViewController:imagePC animated:YES completion:nil];
    }*/
}

-(void)videoButtonTouchUp:(id)sender
{
    [self videoWithUIImagePickerController_Delegate:self fromRecord:NO];
/*
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.mediaTypes =  @[(__bridge NSString *) kUTTypeMovie];
    [self ACpresentViewController:imagePicker animated:YES completion:nil];*/
}

extern NSString *const cSingleChat;

-(void)_ButtonTouchUpWithaddBoardItemType:(enum addBoardItemType)nType{
    
//    NSString*   userID = [ACConfigs mySelfUserID];
    
    //    NSLog(@"%@ %@",userID,_topicEntity.entityID);
    NSString*   relateType =    addBoardItemType_Chat_With_Destrct==nType?@"destruct":@"location";
    
    
    //查询已经有了会话
    for(ACTopicEntity* pEntity in [ACDataCenter shareDataCenter].topicEntityArray){
        if([_topicEntity.entityID isEqualToString:pEntity.relateTeID]&&
           [pEntity.relateType isEqualToString:relateType]){
            //找到了已经存在的会话,直接调用
            [ACNetCenter shareNetCenter].createTopicEntityVC = self;
            [self.contentView showNetLoadingWithAnimated:YES];
            [self createGroupChatSuccess:[[NSNotification alloc] initWithName:@"" object:pEntity userInfo:nil]];
            return;
        }
    }
    
    
    BOOL allowBroadcast = false, allowDelete = false, allowDestruct = false, allowLocation = false, allowChat = false, allowParticipant = false, allowDismiss = false,allowUserInfo=false;
    
    if(addBoardItemType_Chat_With_Destrct==nType) {
        allowParticipant = true;
        allowChat = true;
        allowLocation = false;
        allowDestruct = true;
        allowBroadcast = false;
    }
    else{
        allowParticipant = true;
        allowChat = true;
        allowLocation = true;
        allowDestruct = false;
        allowBroadcast = false;
    }
    
    NSDictionary *exMap = [NSDictionary dictionaryWithObjectsAndKeys:
                           _topicEntity.entityID,@"relate",
                           relateType,@"rtype",
                           [NSNumber numberWithBool:allowBroadcast],@"allowBroadcast",
                           [NSNumber numberWithBool:allowDelete],@"allowDelete",
                           [NSNumber numberWithBool:allowLocation],@"allowLocation",
                           [NSNumber numberWithBool:allowUserInfo],@"allowUserInfo",
                           [NSNumber numberWithBool:allowParticipant],@"allowParticipant",
                           [NSNumber numberWithBool:allowChat],@"allowChat",
                           [NSNumber numberWithBool:allowDismiss],@"allowDismiss",
                           [NSNumber numberWithBool:allowDestruct],@"allowDestruct",
                           nil];
    
    [ACNetCenter shareNetCenter].createTopicEntityVC = self;
    [[ACNetCenter shareNetCenter] createTopicEntityWithChatType:cAdminChat
                                                      withTitle:@""
                                               withGroupIDArray:[[NSArray alloc] init] withUserIDArray:[NSArray arrayWithObjects:[ACUser myselfUserID],_topicEntity.singleChatUserID,nil] exMap:exMap];
    [self.contentView showNetLoadingWithAnimated:YES];
}

-(void)chat_option_destrct_ButtonTouchUp:(id)sender{
    [self _ButtonTouchUpWithaddBoardItemType:addBoardItemType_Chat_With_Destrct];
}


-(void)chat_option_location_ButtonTouchUp:(id)sender{
    [self _ButtonTouchUpWithaddBoardItemType:addBoardItemType_Chat_With_Location];
}


-(void)_show_Select_contact{
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

-(void)chat_msgtype_contact_ButtonTouchUp:(id)sender{
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAuthorizationStatus authStatus = ABAddressBookGetAuthorizationStatus();
    
    if (authStatus == kABAuthorizationStatusNotDetermined){
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ((!error)&&granted){
                    [self _show_Select_contact];
                }
            });
        });
    }else if (authStatus == kABAuthorizationStatusAuthorized){
        [self _show_Select_contact];
    }

    //    [self ACpresentViewController:picker animated:YES completion:nil];
}

#ifdef addBoardItemType_Video_Call_Allow

+(void) callTopic:(ACTopicEntity*)topic forVideoCall:(BOOL)forVideoCall withParentController:(UIViewController*)parent{
    ACUser* pSigleUser = nil;
    if(topic.singleChatUserID.length){
        pSigleUser = [ACUserDB getUserFromDBWithUserID:topic.singleChatUserID];
    }
    
    [ACVideoCall startCallForVideo:forVideoCall
                 withTopicEntity:topic
              withParentController:parent
                      withUser:pSigleUser];

}

-(void)_callForVideo:(BOOL)bForVideo{
    if([ACVideoCall inVideoCallAndShowTip]){
        return;
    }

    [self resignKeyBoard:nil];
    [ACChatMessageViewController callTopic:_topicEntity
                              forVideoCall:bForVideo
                      withParentController:self];
}

-(void)chat_msgtype_videocall_ButtonTouchUp:(UIButton*)sender{
    [self _callForVideo:sender.tag==addBoardItemType_Chat_VideoCall];
}


-(void) callBack:(ACMessage*)message{
    
    if([ACVideoCall inVideoCallAndShowTip]){
        return;
    }

    
    if(ACMessageDirectionType_Send==message.directionType||_topicEntity.isSigleChat){
        //自己发送的
        [self _callForVideo:ACMessageEnumType_Videocall==message.messageEnumType];
        return;
    }
    
    //回拨
    [[ACVideoCall shareVideoCall] joinCall:ACMessageEnumType_Videocall==message.messageEnumType?0:1
                                 withTopicEntity:_topicEntity
                              withSenderID:message.sendUserID
                            withErrTipView:self.view
                                 forWebRTC:_topicEntity.isSigleChat];
}


#endif

-(void)emojiButtonScrollSetting:(BOOL)isFirst
{
    for (UIView *view in _emojiButtonScrollView.subviews)
    {
        [view removeFromSuperview];
    }
    NSInteger buttonWidth = 50;
    //emoji图标
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonWidth, 35)];
    [button setImage:[UIImage imageNamed:@"[微笑].png"] forState:UIControlStateNormal];
    //    [_emojiButtonScrollView addSubview:button];
    button.imageEdgeInsets = UIEdgeInsetsMake(0, 7, 0, 8);
    button.tag = kEmojiButtonTag;
    //    [button addTarget:self action:@selector(emojiButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundColor:kGrayColor];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake([button getFrame_right], 0, 1, _emojiButtonScrollView.size.height)];
    [view setBackgroundColor:kGrayColor];
    [_emojiButtonScrollView addSubview:view];
    
    _currentSelectedStickerPackage = [ACConfigs shareConfigs].currentSuitIndex+1;
    
    //sticker图标
    for (int i = 0;i < [_suitArray count]; i++)
    {
        ACSuit *suit = [_suitArray objectAtIndex:i];
        
        //        NSString *thumbnailPath = [ACAddress getAddressWithFileName:name fileType:ACFile_Type_StickerThumbnail isTemp:NO subDirName:package.title];
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake((i/*+1*/)*buttonWidth, 0, buttonWidth, 35)];
        CGRect rect = button.frame;
        rect.origin.x += 10;
        rect.origin.y += 3;
        rect.size.width -= 20;
        rect.size.height -= 6;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:rect];
        
        if(i){
            [imageView setStickerWithResourceId:suit.thumbnail placeholderImage:nil];
        }
        else{
            //            rect.size.width = rect.size.height;
            //            imageView.frame = rect;
            imageView.center = button.center;
            imageView.image = [UIImage imageNamed:@"icon_stickerbar_select_clock"];
        }
        
        [button setImage:nil forState:UIControlStateNormal];
        NSUInteger index = [ACConfigs shareConfigs].currentSuitIndex < [_suitArray count]?[ACConfigs shareConfigs].currentSuitIndex:[_suitArray count]-1;
        if (i == index)
        {
            [button setBackgroundColor:kGrayColor];
        }
        [_emojiButtonScrollView addSubview:button];
        [_emojiButtonScrollView addSubview:imageView];
        
        
        button.imageEdgeInsets = UIEdgeInsetsMake(0, 7, 0, 8);
        button.tag = kEmojiButtonTag+i+1;
        [button addTarget:self action:@selector(emojiButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake([button getFrame_right], 0, 1, _emojiButtonScrollView.size.height)];
        [view setBackgroundColor:kGrayColor];
        [_emojiButtonScrollView addSubview:view];
    }
    
    //+图标
    if (isFirst)
    {
        ///button = [[UIButton alloc] initWithFrame:CGRectMake(_emojiButtonScrollView.size.width+3, _emojiButtonScrollView.origin.y, buttonWidth-3, 35)];
        button = [[UIButton alloc] initWithFrame:CGRectMake(kScreen_Width - buttonWidth + 3, _emojiButtonScrollView.origin.y, buttonWidth-3, 35)];
               [_emojiInputView addSubview:button];
        //    [_emojiButtonScrollView addSubview:button];
        [button setImage:[UIImage imageNamed:@"EmotionsBagAdd.png"] forState:UIControlStateNormal];
        button.imageEdgeInsets = UIEdgeInsetsMake(0, 7, 0, 8);
        [button addTarget:self action:@selector(addButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
        [button setBackgroundColor:kGrayColor];
    }
    
    
    //    NSInteger count  = [[ACDataCenter shareDataCenter].stickerPackageArray count];
    //    for (int i = 0;i < count; i++)
    //    {
    //        ACStickerPackage *package = [[ACDataCenter shareDataCenter].stickerPackageArray objectAtIndex:i];
    //        NSString *name = [package.thumbnail substringFromIndex:1];
    //
    //        NSString *thumbnailPath = [ACAddress getAddressWithFileName:name fileType:ACFile_Type_StickerThumbnail isTemp:NO subDirName:package.title];
    //
    //        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake((i/*+1*/)*buttonWidth, 0, buttonWidth, 35)];
    //        [button setImage:[UIImage imageWithContentsOfFile:thumbnailPath] forState:UIControlStateNormal];
    //        if (i == 0)
    //        {
    //            [button setBackgroundColor:kGrayColor];
    //        }
    //        [_emojiButtonScrollView addSubview:button];
    //        button.imageEdgeInsets = UIEdgeInsetsMake(0, 7, 0, 8);
    //        button.tag = kEmojiButtonTag+i+1;
    //        [button addTarget:self action:@selector(emojiButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    //
    //        UIView *view = [[UIView alloc] initWithFrame:CGRectMake([button getFrame_right], 0, 1, _emojiButtonScrollView.size.height)];
    //        [view setBackgroundColor:kGrayColor];
    //        [_emojiButtonScrollView addSubview:view];
    //    }
    [_emojiButtonScrollView setContentSize:CGSizeMake(([_suitArray count]/*+1*/)*buttonWidth, 0)];
}


-(NSMutableArray *)getStickerNameArrayWithSuitID:(NSString *)suitID
{
    NSString *suitPath = [ACAddress getAddressWithFileName:suitID fileType:ACFile_Type_DownloadSuit isTemp:NO subDirName:nil];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *imageNameArray = [NSMutableArray arrayWithArray:[fileManager contentsOfDirectoryAtPath:suitPath error:nil]];
    [imageNameArray sortUsingComparator:^NSComparisonResult(NSString *name1,NSString *name2) {
        NSString *name11 = nil;
        NSString *name22 = nil;
        NSUInteger location = 0;
        NSRange range = [name1 rangeOfString:@"_"];
        if (range.length != 0)
        {
            location = range.location;
            name11 = [name1 substringToIndex:location];
        }
        
        range = [name2 rangeOfString:@"_"];
        if (range.length != 0)
        {
            location = range.location;
            name22 = [name2 substringToIndex:location];
        }
        
        if ([name11 intValue] > [name22 intValue])
        {
            return (NSComparisonResult)NSOrderedDescending;
        }
        if ([name11 intValue] > [name22 intValue])
        {
            return (NSComparisonResult)NSOrderedAscending;
        }
        return (NSComparisonResult)NSOrderedSame;
    }];
    return imageNameArray;
}

#pragma mark ---Suit

-(void)reloadSuit
{
    /*
     NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
     NSArray *downloadSuitIDArray = [defaults objectForKey:kDownloadSuitList];
     _suitArray = [NSMutableArray arrayWithCapacity:[downloadSuitIDArray count]];
     for (NSString *suitID in downloadSuitIDArray)
     {
     NSString *filePath = [ACAddress getAddressWithFileName:suitID
     fileType:ACFile_Type_GetSuitInfo
     isTemp:NO
     subDirName:suitID];
     if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
     {
     NSDictionary *suitDic = [NSDictionary dictionaryWithContentsOfFile:filePath];
     ACSuit *suit = [[ACSuit alloc] initWithDic:suitDic];
     [_suitArray addObject:suit];
     }
     }*/
    _suitArray = [ACMyStickerController loadMySuits];
    
    if(_suitArray.count){
        if(nil==_pSuit_Recent){
            _pSuit_Recent =    [ACSuit_Recent loadFromUserDefaults];
        }
        [_pSuit_Recent checkDeleteFromSuits:_suitArray];
        [_suitArray insertObject:_pSuit_Recent atIndex:0];
    }
}

-(void)suitChange:(NSNotification *)noti
{
    [self reloadSuit];
    if ([_suitArray count] == 0 && !_isAppear)
    {
        [self resignKeyBoard:nil];
    }
    [self emojiButtonScrollSetting:NO];
    [self faceBoardSetting];
}



-(void)stickerSettingWithSuit:(ACSuit *)suit
{
    //显示 全部的Sticker
    if (suit)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (UIView *view in [_emojiScrollView subviews])
            {
                [view removeFromSuperview];
            }
            NSInteger faceButtonWidth = 80;
            
            //            NSMutableArray *imageNameArray = [self getStickerNameArrayWithSuitID:suitID];
            
            for (int i = 0; i < [suit.stickers count]; i++)
            {
                ACSticker *sticker = [suit.stickers objectAtIndex:i];
                
                NSString* suitID = suit.suitID;
                if(_pSuit_Recent==suit){
                    suitID = [_pSuit_Recent suitIDForSticker:sticker];
                }
                
                //                NSString *fileName = [NSString stringWithFormat:@"%d_%@",i,sticker.title];
                
                NSString *filePath = [ACAddress getAddressWithFileName:sticker.rid fileType:ACFile_Type_DownloadSticker isTemp:NO subDirName:suitID];
                
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
                {
                    FaceButton *faceButton = [FaceButton buttonWithType:UIButtonTypeCustom];
                    faceButton.buttonIndex = i;
                    //                    faceButton.backgroundColor = [UIColor redColor];
                    
                    [faceButton addTarget:self
                                   action:@selector(stickerButtonTouchUp:)
                         forControlEvents:UIControlEventTouchUpInside];
                    
                    //计算每一个表情按钮的坐标和在哪一屏
                    ///faceButton.frame = CGRectMake((((i)%kSingleScreenStickerCount)%4)*faceButtonWidth+((i)/kSingleScreenStickerCount*320), (((i)%kSingleScreenStickerCount)/4)*faceButtonWidth+8, faceButtonWidth-1, faceButtonWidth-1);
                    
                    //UIButton *iconButton = [[UIButton alloc] initWithFrame:CGRectMake((row+1)*kAddBoardFixedSpaceWidth+row*kAddBoardIconWidth, kAddBoardFixedSpaceWidth*2/3+line*kAddBoardItemHeight, kAddBoardIconWidth, kAddBoardIconWidth)];
                    
                    faceButton.frame = CGRectMake((((i)%kSingleScreenStickerCount)%4)*kFaceButtonWidth+((i)/kSingleScreenStickerCount*kScreen_Width) + (((i)%kSingleScreenStickerCount)%4+1)*kAddBoardEmojiSpaceWidth, (((i)%kSingleScreenStickerCount)/4)*kFaceButtonWidth+8*(((i)%kSingleScreenStickerCount)/4 + 1), kFaceButtonWidth, kFaceButtonWidth);
                    
                    if(nil==_emojiSelectImageView){
                        
                        _emojiSelectImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,faceButton.frame.size.width*1.5,faceButton.frame.size.height*1.5)];
                        _emojiSelectImageView.hidden = YES;
                        _emojiSelectImageView.userInteractionEnabled = YES;
                        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(emojiSelectSticker)];
                        [_emojiSelectImageView addGestureRecognizer:tap];
                        [_emojiInputView addSubview:_emojiSelectImageView];
                        
                    }
                    
                    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
                    
                    [faceButton setImage:image forState:UIControlStateNormal];
                    [_emojiScrollView addSubview:faceButton];
                }
#if DEBUG
                else{
                    NSLog(@"Sticker %@(%@) not exist",sticker.title,sticker.rid);
                }
#endif
            }
            
            [_stickerDownloadView setHidden:YES];
            _currentPageCount = [suit.stickers count]/8+([suit.stickers count]%8!=0);
           /// [_emojiScrollView setContentSize:CGSizeMake(320*_currentPageCount, 0)];
            [_emojiScrollView setContentSize:CGSizeMake(kScreen_Width*_currentPageCount, 0)];
            
            [_emojiScrollView setContentOffset:CGPointMake(0, 0)];
            if (_currentPageCount > 5)
            {
                [_emojiPageC setNumberOfPages:5];
            }
            else
            {
                [_emojiPageC setNumberOfPages:_currentPageCount];
            }
            [_emojiPageC setCurrentPage:0];
            [_emojiPageC setFrame_y:155];
            ///
            [_emojiPageC setCenter_x:kScreen_Width * 0.5];
        });
    }
}


-(void)stickerDownloadSuccess:(NSNotification *)noti
{
    if (!_isAppear)
    {
        return;
    }
    NSArray *visiblePaths = [_mainTableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths)
    {
        ACChatMessageTableViewCell *cell = (ACChatMessageTableViewCell *)[_mainTableView cellForRowAtIndexPath:indexPath];
        if ([noti.object isEqualToString:cell.messageData.messageID])
        {
            NSString *filePath = [UIImageView getStickerSaveAddressWithPath:((ACStickerMessage *)(cell.messageData)).stickerPath withName:((ACStickerMessage *)(cell.messageData)).stickerName];
            [cell.gifImageView setImage:[YLGIFImage imageWithContentsOfFile:filePath]];
        }
    }
}


//-(void)stickerSettingWithStickerPackage:(ACStickerPackage *)stickerPackage
//{
//    if (stickerPackage)
//    {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            for (UIView *view in [_emojiScrollView subviews])
//            {
//                [view removeFromSuperview];
//            }
//            NSInteger faceButtonWidth = 80;
//
//            BOOL    isNeedDownload = NO;
//            for (int i = 0; i < [stickerPackage.imageNameArray count]; i++)
//            {
//                NSString *imageName = [stickerPackage.imageNameArray objectAtIndex:i];
//                NSString *filePath = [ACAddress getAddressWithFileName:imageName fileType:ACFile_Type_StickerZip isTemp:NO subDirName:stickerPackage.title];
//
//                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
//                {
//                    FaceButton *faceButton = [FaceButton buttonWithType:UIButtonTypeCustom];
//                    faceButton.buttonIndex = i;
//
//                    [faceButton addTarget:self
//                                   action:@selector(stickerButtonTouchUp:)
//                         forControlEvents:UIControlEventTouchUpInside];
//
//                    //计算每一个表情按钮的坐标和在哪一屏
//                    faceButton.frame = CGRectMake((((i)%kSingleScreenStickerCount)%4)*faceButtonWidth+((i)/kSingleScreenStickerCount*320), (((i)%kSingleScreenStickerCount)/4)*faceButtonWidth+8, faceButtonWidth, faceButtonWidth);
//
//                    [faceButton setImage:[UIImage imageWithContentsOfFile:filePath] forState:UIControlStateNormal];
//                    [_emojiScrollView addSubview:faceButton];
//                }
//                else
//                {
//                    isNeedDownload = YES;
//                    break;
//                }
//            }
//
//            if (isNeedDownload)
//            {
//                [_stickerDownloadView setHidden:NO];
//
//                if (stickerPackage.isDownloading)
//                {
//                    [_stickerDownloadProgressView setHidden:NO];
//                    _stickerDownloadProgressView.progress = stickerPackage.progress;
//                    [_stickerDownloadButton setHidden:YES];
//                    [_stickerDownloadingLabel setHidden:NO];
//                    //                    [_stickerDownloadButton setUserInteractionEnabled:NO];
//                    //                    [_stickerDownloadButton setFrame_y:stickerDownloadingButtonY];
//                }
//                else
//                {
//                    [_stickerDownloadProgressView setHidden:YES];
//                    [_stickerDownloadButton setHidden:NO];
//                    [_stickerDownloadingLabel setHidden:YES];
//                    //                    [_stickerDownloadButton setUserInteractionEnabled:YES];
//                    //                    [_stickerDownloadButton setFrame_y:stickerUnDownloadButtonY];
//                }
//            }
//            else
//            {
//                [_stickerDownloadView setHidden:YES];
//                _currentPageCount = [stickerPackage.imageNameArray count]/8+([stickerPackage.imageNameArray count]%8!=0);
//                [_emojiScrollView setContentSize:CGSizeMake(320*_currentPageCount, 0)];
//                [_emojiScrollView setContentOffset:CGPointMake(0, 0)];
//                if (_currentPageCount > 5)
//                {
//                    [_emojiPageC setNumberOfPages:5];
//                }
//                else
//                {
//                    [_emojiPageC setNumberOfPages:_currentPageCount];
//                }
//                [_emojiPageC setCurrentPage:0];
//                [_emojiPageC setFrame_y:155];
//            }
//        });
//    }
//}

-(IBAction)stickerDownButtonTouchUp:(UIButton *)button
{
    //    [_stickerDownloadButton setHidden:YES];
    //    [_stickerDownloadingLabel setHidden:NO];
    //    [_stickerDownloadProgressView setHidden:NO];
    ////    [_stickerDownloadButton setFrame_y:stickerDownloadingButtonY];
    //    _currentPackage.isDownloading = YES;
    //    [[ACNetCenter shareNetCenter] getStickerZipWithTitle:_currentPackage.title withDelegate:_currentPackage];
}

-(void)faceButtonTouchUp:(id)sender
{
    int i = (int)((FaceButton*)sender).buttonIndex;
    if (self.chatInput.textView)
    {
        NSMutableString *faceString = [[NSMutableString alloc]initWithString:self.chatInput.textView.text];
        
        NSString *imageName = [_faceMap objectForKey:[NSString stringWithFormat:@"%03d",i]];
        if (imageName)
        {
            if ([faceString length] < kChatMessageMaxLength)
            {
                [faceString appendString:imageName];
                self.chatInput.text = faceString;
            }
            else
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil)
                                                                    message:NSLocalizedString(@"Has_Not_Entered", nil)
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles: nil];
                [alertView show];
            }
        }
    }
}


-(void)stickerButtonTouchUp:(FaceButton *)button
{
    _emojiSelectButtonTemp  =   button;
    
    CGRect frame =  _emojiSelectImageView.frame;
    frame.origin.x =    (button.center.x-_emojiScrollView.contentOffset.x)-frame.size.width/2;
    frame.origin.y =    button.center.y-frame.size.height/2;
    
    if(frame.origin.x<0){
        frame.origin.x = 0;
    }
//    else if((frame.origin.x+frame.size.width)>320){
//        frame.origin.x = 320-frame.size.width;
//    }
    ///
    else if((frame.origin.x+frame.size.width)>kScreen_Width){
        frame.origin.x = kScreen_Width-frame.size.width;
    }
    
    if(frame.origin.y<0){
        frame.origin.y = 0;
    }
    else if((frame.origin.y+frame.size.height)>_emojiInputView.frame.size.height){
        frame.origin.y = _emojiInputView.frame.size.height-frame.size.height;
    }
    
    _emojiSelectImageView.image =   [button imageForState:UIControlStateNormal];
#if 1
    //需要动画
    if(_emojiSelectBkView.isHidden){
        _emojiSelectImageView.frame = frame;
        _emojiSelectBkView.hidden = NO;
        _emojiSelectImageView.hidden = NO;
    }
    else{
        [UIView animateWithDuration:0.3 animations:^{
            _emojiSelectImageView.frame = frame;
        }];
    }
#else
    _emojiSelectImageView.frame = frame;
    _emojiSelectBkView.hidden = NO;
    _emojiSelectImageView.hidden = NO;
#endif
}

-(void)emojiSelectSticker{
    
    //    NSMutableArray *imageNameArray = [self getStickerNameArrayWithSuitID:_currentSuitID];
    [UIView animateWithDuration:0.3 animations:^{
        _emojiSelectBkView.hidden = YES;
        _emojiSelectImageView.hidden = YES;
    } completion:^(BOOL finished) {
    
        ACSuit *suit = nil;
        if(_currentSuitID){
            for (ACSuit *suitTmp in _suitArray)
            {
                if ([suitTmp.suitID isEqualToString:_currentSuitID])
                {
                    suit = suitTmp;
                    break;
                }
            }
        }
        else{
            suit    =   _pSuit_Recent;
        }
        
        if (_emojiSelectButtonTemp.buttonIndex < [suit.stickers count])
        {
            ACSticker *stickerT = [suit.stickers objectAtIndex:_emojiSelectButtonTemp.buttonIndex];
            
            CGSize size = _emojiSelectButtonTemp.imageView.image.size;
            NSString* suitID = suit.suitID;
            if(_pSuit_Recent==suit){
                suitID = [_pSuit_Recent suitIDForSticker:stickerT];
            }
            
            //添加最近使用
            [_pSuit_Recent addSticker:stickerT fromSuit:suit];
            
            NSDictionary *contentDic = [NSDictionary dictionaryWithObjectsAndKeys:[ACStickerMessage getStickerPathWithSuitID:suitID withRid:stickerT.rid],kPath,stickerT.title,kName,[NSNumber numberWithInt:size.width],KWidth,[NSNumber numberWithInt:size.height],KHeight,suitID,kSuitID,stickerT.rid,kRid, nil];
            ACStickerMessage *message = (ACStickerMessage *)[ACMessage createMessageWithMessageType:ACMessageType_sticker
                                                                                       topicEnitity:_topicEntity
                                                                                     messageContent:[contentDic JSONString]
                                                                                          sendMsgID:nil
                                                                                           location:nil];
            
            [_dataSourceArray addObject:message];
            ITLog(_dataSourceArray);
            dispatch_async(dispatch_get_main_queue(), ^{
                //            [_mainTableView reloadData];
                //            ITLog(@"-->>_mainTableView reloadData");
                [self tableViewScrollToBottomWithAnimated:YES];
            });
            
            [[ACNetCenter shareNetCenter].chatCenter sendMessage:message];
        }
    }];
}

/*可能没用
-(void)deleteButtonTouchUp:(UIButton *)deleteButton
{
    BOOL bo = [self.chatInput textView:self.chatInput.textView
               shouldChangeTextInRange:NSMakeRange(self.chatInput.textView.text.length-1, 1) replacementText:@""];
    if (bo)
    {
        if ([self.chatInput.textView.text length] > 0)
        {
            [self.chatInput setText:[self.chatInput.textView.text substringToIndex:self.chatInput.textView.text.length-1]];
        }
    }
}*/

#pragma mark -ButtonTouchUp

-(void)emojiSelectHide{
    //隐藏emoji选择
    _emojiSelectButtonTemp = nil;
    _emojiSelectImageView.image = nil;
    _emojiSelectImageView.hidden = YES;
    _emojiSelectBkView.hidden = YES;
}

-(void)emojiButtonTouchUp:(UIButton *)button
{
    [self emojiSelectHide];
    NSInteger selectButtonIndex = button.tag - kEmojiButtonTag;
    if (_currentSelectedStickerPackage != selectButtonIndex)
    {
        UIButton *preButton = (UIButton *)[_emojiButtonScrollView viewWithTag:_currentSelectedStickerPackage + kEmojiButtonTag];
        [preButton setBackgroundColor:[UIColor clearColor]];
        [button setBackgroundColor:kGrayColor];
        _currentSelectedStickerPackage = selectButtonIndex;
        [ACConfigs shareConfigs].currentSuitIndex = selectButtonIndex-1;
        if (selectButtonIndex == 0)
        {
            [self faceBoardSetting];
            _sendButton.hidden = NO;
           /// [_emojiButtonScrollView setFrame_width:270];
            [_emojiButtonScrollView setFrame_width:kScreen_Width - 50];
            _currentSuitID = nil;
        }
        else
        {
            selectButtonIndex -= 1;
            if (selectButtonIndex < [_suitArray count])
            {
                ACSuit *suit = [_suitArray objectAtIndex:selectButtonIndex];
                
                _currentSuitID = suit.suitID;
                
                [self stickerSettingWithSuit:suit];
               /// [_emojiButtonScrollView setFrame_width:270];
                [_emojiButtonScrollView setFrame_width:kScreen_Width - 50];
                _sendButton.hidden = YES;
            }
        }
        [_emojiButtonLineView setFrame_width:_emojiButtonScrollView.size.width];
    }
}

-(void)addButtonTouchUp:(UIButton *)button
{
    [self showStickerShop:nil];
}


#pragma mark ELCImagePickerControllerDelegate Methods

-(void)_sendImageWithCaptions:(NSArray*)imgWithCaption{
    
    [self.view showProgressHUDWithLabelText:NSLocalizedString(@"Preparing", nil) withAnimated:YES];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        NSMutableArray* pSendImageArray = [[NSMutableArray alloc] initWithCapacity:imgWithCaption.count];
        for(ELCSelectedImageInfo* imgInfo in imgWithCaption){
            
            UIImage *scaledBigImage = [imgInfo.image imageScaledToBigFixedSize:CGSizeMake(2000, 2000)];
            ///UIImage *scaledSmallImage = [imgInfo.image imageScaledInterceptToSize:CGSizeMake(320, 320)];
            UIImage *scaledSmallImage = [imgInfo.image imageScaledInterceptToSize:CGSizeMake(kScreen_Width, kScreen_Width)];
            
            NSDictionary *postDic = [NSDictionary dictionaryWithObjectsAndKeys:@[[NSNumber numberWithInt:scaledSmallImage.size.width],[NSNumber numberWithInt:scaledSmallImage.size.height]],kSmall,@[[NSNumber numberWithInt:scaledBigImage.size.width],[NSNumber numberWithInt:scaledBigImage.size.height]],kBig, imgInfo.caption,kCaption, nil];
            NSString *content = [postDic JSONString];
            ACFileMessage *message = (ACFileMessage *)[ACMessage createMessageWithMessageType:ACMessageType_image
                                                                                 topicEnitity:_topicEntity
                                                                               messageContent:content
                                                                                    sendMsgID:nil
                                                                                     location:nil];
//            ITLogEX(@"%@",message.messageID);
            @autoreleasepool {
                NSString *bigImagePath = [ACAddress getAddressWithFileName:message.resourceID fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
                [UIImageJPEGRepresentation(scaledBigImage, 0.75) writeToFile:bigImagePath atomically:YES];
                long length = [ACUtility getFileSizeWithPath:bigImagePath];
                NSMutableDictionary *postDic1 = [NSMutableDictionary dictionaryWithDictionary:[message.content objectFromJSONString]];
                [postDic1 setObject:[NSNumber numberWithLong:length] forKey:kLength];
                message.content = [postDic1 JSONString];
                
                NSString *smallImagePath = [ACAddress getAddressWithFileName:message.thumbResourceID fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
                [UIImageJPEGRepresentation(scaledSmallImage, 0.75) writeToFile:smallImagePath atomically:YES];
            }
            
            [_dataSourceArray addObject:message];
            [pSendImageArray addObject:message];
            if(imgWithCaption.count>1){
                [NSThread sleepForTimeInterval:0.2];
            }
        }
        
//        ITLog(_dataSourceArray);
        dispatch_async(dispatch_get_main_queue(), ^{
            //            [_mainTableView reloadData];
            //            ITLog(@"-->>_mainTableView reloadData");
            [self.view hideProgressHUDWithAnimated:YES];
            [self tableViewScrollToBottomWithAnimated:YES];
        });
        
        for(ACMessage* pImgMsg in pSendImageArray){
            [[ACNetCenter shareNetCenter].chatCenter sendMessage:pImgMsg];
        }
    });
    
}


- (void)elcImagePickerController:(ELCImagePickerController *)picker sendPreviewImgWithCaptions:(NSArray *)ImageWithCaptions{
//    [picker dismissViewControllerAnimated:YES completion:nil];
    if(picker){
        [picker ACdismissViewControllerAnimated:YES completion:^{
            [self _sendImageWithCaptions:ImageWithCaptions];
        }];
    }
    else{
        [self _sendImageWithCaptions:ImageWithCaptions];
    }
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker
{
    [picker ACdismissViewControllerAnimated:YES completion:nil];
//    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark -UIImagePickerControllerDelegate

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
#ifdef ACChatMessageVC_SendOneImgWithPrew
    _pImagePickerForReview = nil;
    _pImagePickerSelectInfoForReview = nil;
#endif
    [picker ACdismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //预览并发送
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
#ifdef ACChatMessageVC_SendOneImgWithPrew
    _pImagePickerForReview = nil;
    _pImagePickerSelectInfoForReview = nil;
    if([mediaType isEqualToString:(__bridge NSString *)kUTTypeImage]){
        _pImagePickerForReview = picker;
        _pImagePickerSelectInfoForReview = info;
        _needViewImageCollections = nil;
        MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self browserType:BrowserType_SendImageBrowser];
        //        browser.displayActionButton = YES;
        UINavigationController *navC = [[UINavigationController alloc] initWithRootViewController:browser];
        [picker ACpresentViewController:navC animated:YES completion:nil];
        return;
    }
#endif
    
    [picker ACdismissViewControllerAnimated:YES completion:nil];
    if ([mediaType isEqualToString:(__bridge NSString *)kUTTypeMovie])
    {
        NSURL *movieUrl = [info objectForKey:UIImagePickerControllerMediaURL];
        if([ACUtility checkVideo:movieUrl Deuration:Send_Video_Maximum_Duration]){
            return;
        }
        
        {
            //保存录像
            NSString* pPath = [movieUrl path];
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(pPath)){
                UISaveVideoAtPathToSavedPhotosAlbum(pPath, nil, nil, NULL);
            }
        }
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self movieToMp4:movieUrl];
        });
    }
    else if ([mediaType isEqualToString:(__bridge NSString *)kUTTypeImage]){
        
        [self.view showProgressHUD];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UIImage* pImg = [info objectForKey:UIImagePickerControllerOriginalImage];
            UIImageWriteToSavedPhotosAlbum(pImg, self, nil, nil); //保存图片
            [AC_PreViewImagesWithCaption showPreviewWithCaptionForCameraWithDelegate:self
                                                                             withImg:pImg
                                                                            fromView:self];
            
            [self.view hideProgressHUDWithAnimated:NO];
        });

        
//         UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
//        ELCSelectedImageInfo* item = [[ELCSelectedImageInfo alloc] init];
//        item.image =    pImg;
//        [self _sendImageWithCaptions:@[item]];
    }
}

-(void)sendLocationMessageWithCoordinate:(CLLocationCoordinate2D)coordinate
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        CLLocation *locationT = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
        ACLocationMessage *message = (ACLocationMessage *)[ACMessage createMessageWithMessageType:ACMessageType_location topicEnitity:_topicEntity messageContent:nil sendMsgID:nil location:locationT];
        [_dataSourceArray addObject:message];
        ITLog(_dataSourceArray);
        dispatch_async(dispatch_get_main_queue(), ^{
            //            [_mainTableView reloadData];
            //            ITLog(@"-->>_mainTableView reloadData");
            [self tableViewScrollToBottomWithAnimated:YES];
        });
        
        [[ACNetCenter shareNetCenter].chatCenter sendMessage:message];
    });
}

-(NSString *)movieToMp4:(NSURL *)movieURL
{
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:movieURL options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality])
    {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
        _sendVideoMsgID = [ACMessage getTempMsgID];
        __block NSString *mp4Path = [ACAddress getAddressWithFileName:_sendVideoMsgID
                                                             fileType:ACFile_Type_VideoFile
                                                               isTemp:NO
                                                           subDirName:nil];
        exportSession.outputURL = [NSURL fileURLWithPath: mp4Path];
        exportSession.outputFileType = AVFileTypeMPEG4;
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusFailed:
                {
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                    message:[[exportSession error] localizedDescription]
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles: nil];
                    [alert show];
                    break;
                }
                    
                case AVAssetExportSessionStatusCancelled:
                    ITLog(@"Export canceled");
                    break;
                case AVAssetExportSessionStatusCompleted:
                {
                    ITLog(@"Successful!");
                    
                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
                        
                        /*
                         MPMoviePlayerController *playC = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];
                         playC.shouldAutoplay = NO;
                         UIImage *image = [playC thumbnailImageAtTime:1 timeOption:MPMovieTimeOptionNearestKeyFrame];*/
                        UIImage* thumbImageTemp =   [ACUtility thumbFromMovieURL:movieURL];
                        
                        CGSize coverSize = CGSizeMake(240,320);
                        
                        if(thumbImageTemp.size.width>thumbImageTemp.size.height){
                            coverSize   =   CGSizeMake(320,240);
                        }
                        
                        UIImage *thumbImage = [[ACUtility thumbFromMovieURL:movieURL] imageScaledToBigFixedSize:coverSize];
                        
                        //                        UIImage *thumbImage = [ACUtility thumbFromMovieURL:movieURL];
                        
                        long length = [ACUtility getFileSizeWithPath:mp4Path];
                        NSDictionary *postDic = [NSDictionary dictionaryWithObjectsAndKeys:@[[NSNumber numberWithInt:thumbImage.size.width],[NSNumber numberWithInt:thumbImage.size.height]],kSmall,[NSNumber numberWithLong:length],kLength, nil];
                        NSString *content = [postDic JSONString];
                        ACFileMessage *message = (ACFileMessage *)[ACMessage createMessageWithMessageType:ACMessageType_video
                                                                                             topicEnitity:_topicEntity
                                                                                           messageContent:content
                                                                                                sendMsgID:_sendVideoMsgID
                                                                                                 location:nil];
                        
                        //获取缩略图，写本地
                        @autoreleasepool {
                            NSString *thumbPath = [ACAddress getAddressWithFileName:message.thumbResourceID fileType:ACFile_Type_VideoThumbFile isTemp:NO subDirName:nil];
                            
                            [UIImageJPEGRepresentation(thumbImage, 0.75) writeToFile:thumbPath atomically:YES];
                        }
                        
                        [_dataSourceArray addObject:message];
                        ITLog(_dataSourceArray);
                        dispatch_async(dispatch_get_main_queue(),^{
                            //                            [_mainTableView reloadData];
                            //                            ITLog(@"-->>_mainTableView reloadData");
                            [self tableViewScrollToBottomWithAnimated:YES];
                        });
                        
                        [[ACNetCenter shareNetCenter].chatCenter sendMessage:message];
                    });
                }
                    break;
                default:
                    break;
            }
        }];
        return mp4Path;
    }
    else
    {
        return @"";
    }
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    if(_needViewImageCollections.count){
        return _needViewImageCollections.count;
    }
    return 1;
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    
    if(_needViewImageCollections.count){
        
        ACFileMessageCache *pMsgCache =   _needViewImageCollections[index];
        
        MWPhoto *photo = nil;
        NSString* pFilePathName = [pMsgCache getCachedFilePathNameWithTopicEntityID:_topicEntity.entityID forThumb:NO];
        if(pFilePathName){
            photo = [MWPhoto photoWithFilePath:pFilePathName]; //已经 autorelease
        }
        else if(photoBrowser.NET_Images_load_state&MWPhotoBrowser_NET_Images_load_state_allow) {
            photo = [MWPhoto photoWithURL:[NSURL URLWithString:[pMsgCache getURLWithTopicEntityID:_topicEntity.entityID forThumb:NO]]];//已经 autorelease
        }
        else{
            photo = [MWPhoto photoWithImage:[UIImage imageNamed:@"image_placeHolder.png"]];
        }
        
        /*         NSString* pURL = [ACNetCenter getdownloadURL:[[ACNetCenter shareNetCenter] getUrlWithEntityID:fileMessage.topicEntityID messageID:fileMessage.messageID resourceID:fileMessage.resourceID] withFileLength:fileMessage.length];
         
         if (fileMessage.directionType == ACMessageDirectionType_Send)
         {
         pFilePathName = [ACAddress getAddressWithFileName:fileMessage.resourceID fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
         }
         
         MWPhoto *photo = nil;
         
         if (pFilePathName.length&&[[NSFileManager defaultManager] fileExistsAtPath:pFilePathName]){
         photo = [MWPhoto photoWithFilePath:pFilePathName]; //已经 autorelease
         }
         
         if (nil==photo&&pURL.length){
         photo = [MWPhoto photoWithURL:[NSURL URLWithString:pURL]]; //已经 autorelease
         }*/
        
        return photo;
    }
#ifdef ACChatMessageVC_SendOneImgWithPrew
    return [MWPhoto photoWithImage:[_pImagePickerSelectInfoForReview objectForKey:UIImagePickerControllerOriginalImage]];
#else
    return nil;
#endif
    
}

#ifdef ACChatMessageVC_SendOneImgWithPrew
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser sendAtIndex:(NSUInteger)index{
    UIImage *originalImage = [_pImagePickerSelectInfoForReview objectForKey:UIImagePickerControllerOriginalImage];
    if(originalImage){
        [self _sendImages:@[originalImage]];
    }
    [photoBrowser dismissModalViewControllerAnimated:NO];
    [_pImagePickerForReview dismissViewControllerAnimated:YES completion:nil];
    _pImagePickerForReview = nil;
    _pImagePickerSelectInfoForReview = nil;
}
#endif

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser NetPreLoad:(int)loadDir{ ///<调用网络预加载
    ACFileMessageCache *pMsgCache =   loadDir>0?_needViewImageCollections.lastObject:_needViewImageCollections.firstObject;
   [self _displayImageWithFileMessageLoadFromServer:loadDir withMsgCache:pMsgCache];
}


- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser NetLoadAtCurIndex:(int*) pcurrentPageIndex{ ///<加载预加载的数据,返回新的当前IndexNo
    @synchronized(self){
        if(nil==_netPreLoadImageCollections){
            return NO;
        }
        
        if(0==_netPreLoadImageCollections.count){
            //没有变化
            photoBrowser.NET_Images_load_state  |= [self _displayImageWithFileMessageGetData];
            return NO;
        }
        
        if(NULL==pcurrentPageIndex){
            //只是检测，其实不加载
            return YES;
        }
        
        ACFileMessageCache* pPreCache = _needViewImageCollections[*pcurrentPageIndex];
        photoBrowser.NET_Images_load_state  |=  [self _displayImageWithFileMessageGetData];
        NSInteger nIndex = [self _displayImageWithFileMessageFindItem:pPreCache forInsert:NO];
        *pcurrentPageIndex = (int)(nIndex<_needViewImageCollections.count?nIndex:0);
    }
    return YES;
}




#pragma mark -ACPersonContactVC_Delegate
-(void)ACPersonContactOnDone:(ACPersonContactVC*)pVC{
    [pVC.navigationController popViewControllerAnimated:YES];
    
    [self sendFile:[NSString stringWithFormat:@"%@.vcf",pVC.PersonName] withFileDataBlock:^(NSString* pFilePathName){
        [pVC saveVcfFile:pFilePathName];
    }];
    
    
    /*
     //    NSString* pPersonName = pVC.PersonName;
     ACFileMessage *message = (ACFileMessage *)[ACMessage createMessageWithMessageType:file topicEnitity:_topicEntity messageContent:nil sendMsgID:[ACMessage getTempMsgID] location:nil];
     
     NSString *contact_file_PathName = [ACAddress getAddressWithFileName:message.resourceID fileType:ACFile_Type_File isTemp:NO subDirName:@"vcf"];
     
     //写文件
     [pVC saveVcfFile:contact_file_PathName];
     
     long length = [ACUtility getFileSizeWithPath:contact_file_PathName];
     NSMutableDictionary *postDic1 = [NSMutableDictionary dictionaryWithDictionary:[message.content objectFromJSONString]];
     [postDic1 setObject:[NSNumber numberWithLong:length] forKey:kLength];
     [postDic1 setObject:[NSString stringWithFormat:@"%@.vcf",pVC.PersonName] forKey:kName];
     message.content = [postDic1 JSONString];
     
     [_dataSourceArray addObject:message];
     ITLog(_dataSourceArray);
     dispatch_async(dispatch_get_main_queue(), ^{
     [_mainTableView reloadData];
     ITLog(@"-->>_mainTableView reloadData");
     [self tableViewScrollToBottomWithAnimated:YES];
     });
     
     [[ACNetCenter shareNetCenter].chatCenter sendFileMessage:message];*/
}

#pragma mark -ABPeoplePickerNavigationControllerDelegate

- (void)didSelectPerson:(ABRecordRef)person
{
    ACPersonContactVC* pPersonVC = [ACPersonContactVC ACPersonContactVCWithPersonRecord:person andDelegate:self];
    if(pPersonVC){
        [self.navigationController pushViewController:pPersonVC animated:YES];
    }
    else{
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                        message:NSLocalizedString(@"PersonContace_empty", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }
}


// On iOS 8.0, a selected person is returned with this method.
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person
{
    [self didSelectPerson:person];
}


// On iOS 7.x or earlier, a selected person is returned with this method. This method may be deprecated in a future iOS 8.0 seed.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
#pragma clang diagnostic pop
{
    [peoplePicker dismissViewControllerAnimated:YES completion:nil];
    [self didSelectPerson:person];
    return NO;
}


// On iOS 7.x or earlier, this method is required but never used by this sample. This method may be deprecated in a future iOS 8.0 seed.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
#pragma clang diagnostic pop
{
    return NO;
}


// On iOS 7.x or earlier, this method is required and it must dismiss the picker. This method may be optional in a future iOS 8.0 seed.
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    // Perform any additional work when the picker is cancelled by the user.
    
    [peoplePicker dismissViewControllerAnimated:YES completion:nil];
}





@end

@implementation FaceButton
@end
