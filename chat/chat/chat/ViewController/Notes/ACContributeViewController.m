//
//  ACContributeViewController.m
//  chat
//
//  Created by 王方帅 on 14-6-3.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACContributeViewController.h"
#import "UIImage+Additions.h"
#import "UIView+Additions.h"
#import "ACAddress.h"
#import "ACMessage.h"
//#import "ELCAlbumPickerController.h"
#import "ELCImagePickerController.h"
//#import "ELCAssetTablePicker.h"
#import "ACContributeVC_ThumbCell.h"
//#import "ACSendLocationViewController.h"
#import "ACNetCenter.h"
#import "UINavigationController+Additions.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ACNoteListVC_Base.h"
#import "ACNetCenter+Notes.h"
#import "ACNoteListVC_Cell.h"
#import <AddressBookUI/AddressBookUI.h>
#import "ACMapViewController.h"

#define isCompressing NSLocalizedString(@"Video compressing", nil)

#define kActionSheetTag 2123
#define kGobackAlertTag 3245
#define kWeblinkInputTag   3246

@interface ACContributeViewController (){
    ACNoteMessage*  _noteMessage;
    ACWallBoard_Message*    _wallBoardMessage;
    ACCategory*     _category;
    NSArray*        _detailDataSourceArray;
}

@end

@implementation ACContributeViewController

- (void)dealloc
{
    AC_MEM_Dealloc();
    [_noteMessage removeObserver:self forKeyPath:kProgress];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(instancetype)initForWallBoard:(BOOL)bForWallBoard  withSuperVC:(ACNoteListVC_Base*)superVC{
    self = [super init];
    if(self){
        _superVC    =   superVC;
        _noteMessage    =   [[ACNoteMessage alloc] init];
        if(bForWallBoard){
            _noteMessage.categoryIDForWallBoard  =  @"";
            _wallBoardMessage   = [ACWallBoard_Message createWallBoardMessageFormNoteMessage:_noteMessage topicEnitity:_superVC.topicEntity];
        }
         _barDic         = [NSMutableDictionary dictionary];
        _movieToMp4FinishedCount = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _textView.placeholder = NSLocalizedString(@"Content", nil);
    _buttonType = ACButtonType_photo;
    _compresseFailCount = 0;
    
    _buttonBarBgImageView.image = [[UIImage imageNamed:@"write_bg_top.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:20];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIImage *image = [[UIImage imageNamed:@"write_bg_board.png"] imageFillToSize:_detailBgImageView.size];
        dispatch_async(dispatch_get_main_queue(), ^{
            _detailBgImageView.image = image;
        });
    });
    [_cameraButton setBackgroundImage:[[UIImage imageNamed:@"write_btn_02.png"] stretchableImageWithLeftCapWidth:11 topCapHeight:21] forState:UIControlStateNormal];
    [_cameraButton setBackgroundImage:[[UIImage imageNamed:@"write_btn_02_press.png"] stretchableImageWithLeftCapWidth:11 topCapHeight:21] forState:UIControlStateHighlighted];
    [_cameraButton setTitle:NSLocalizedString( @"Camera", nil) forState:UIControlStateNormal];
    
    [_photoButton setBackgroundImage:[[UIImage imageNamed:@"write_btn_02.png"] stretchableImageWithLeftCapWidth:11 topCapHeight:21] forState:UIControlStateNormal];
    [_photoButton setBackgroundImage:[[UIImage imageNamed:@"write_btn_02_press.png"] stretchableImageWithLeftCapWidth:11 topCapHeight:21] forState:UIControlStateHighlighted];
    [_photoButton setTitle:NSLocalizedString( @"Gallery", nil) forState:UIControlStateNormal];

    [_webLinkButton setBackgroundImage:[[UIImage imageNamed:@"write_btn_02.png"] stretchableImageWithLeftCapWidth:11 topCapHeight:21] forState:UIControlStateNormal];
    [_webLinkButton setBackgroundImage:[[UIImage imageNamed:@"write_btn_02_press.png"] stretchableImageWithLeftCapWidth:11 topCapHeight:21] forState:UIControlStateHighlighted];
    [_webLinkButton setTitle:NSLocalizedString( @"WebLink", nil) forState:UIControlStateNormal];
    
    
    [_postButton setNomalText:NSLocalizedString( @"Post", nil)];
    
    
    [_detailTableView setFrame:CGRectMake(0, 500, kScreen_Width, kScreen_Width)];
    [_detailTableView.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
   /// [_detailTableView.layer setAnchorPoint:CGPointMake(0.8, 0.5)];
    _detailTableView.transform = CGAffineTransformMakeRotation(M_PI/-2);
    _detailTableView.showsVerticalScrollIndicator = NO;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(sendWallboardSucc:) name:kNetCenterNotes_Note_Upload_Success_Notifition object:nil];
    [nc addObserver:self selector:@selector(sendWallboardFail:) name:kNetCenterNotes_Note_Upload_Fail_Notifition object:nil];
    [nc addObserver:self selector:@selector(sendWallboardNotNetwork:) name:kNetCenterNotes_Note_Upload_NoNetword_Notifition object:nil];
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
    
    
    [_noteMessage addObserver:self forKeyPath:kProgress options:NSKeyValueObservingOptionNew context:nil];
    
    [_uploadView.layer setCornerRadius:5.0];
    [_uploadView.layer setMasksToBounds:YES];
    
    [_categoryView.layer setCornerRadius:5.0];
    [_categoryView.layer setMasksToBounds:YES];
 
    _webLinkButton.hidden = YES;
    _webLinkDelButton.hidden = YES;
    _webInfoBk.hidden = YES;
    
    //如果上一次有记录categoryID，则使用上一次的，否则使用第一个
    if(_wallBoardMessage){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *categoryID = [defaults objectForKey:kWallboardLastCategoryID];
        if ([categoryID length] > 0)
        {
            for (ACCategory *category in _superVC.topicEntity.categoriesArray)
            {
                if ([category.cid isEqualToString:categoryID])
                {
                    _category = category;
                    break;
                }
            }
        }
        
        if (!_category)
        {
            if ([_superVC.topicEntity.categoriesArray count] > 0)
            {
                _category = [_superVC.topicEntity.categoriesArray objectAtIndex:0];
            }
        }
        _webLinkBarButton.hidden    =   YES;
        _wallBoardLable.text = NSLocalizedString(@"Wallboard",nil);
    }
    else{
        _wallBoardLable.text = NSLocalizedString(@"Note",nil);
        _categoryTitle.text = NSLocalizedString(@"Send", nil);
        _dropDownButton.hidden = YES;
    }
    
    _uploadLabel.text = NSLocalizedString(@"Uploading", nil);
    [self.view addSubview:_promptView];
    
    ///_propptView  size
    [_promptView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.offset(kScreen_Width);
        make.height.offset(kScreen_Height);
    }];
    
    [_promptView setHidden:YES];
    
    [self setUploadButtonBackground];
    
    if (![ACConfigs isPhone5])
    {
        [_textView setFrame_height:_textView.size.height-88];
        [_buttonBarView setFrame_y:[_textView getFrame_Bottom]];
        [_detailView setFrame_y:[_buttonBarView getFrame_Bottom]];
        [_contentView setFrame_height:[_detailView getFrame_Bottom]];
    }
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self initHotspot];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initHotspot];
}

-(void)setUploadButtonBackground
{
    [_dropDownButton setTitle:_category.name forState:UIControlStateNormal];
    
    [_dropDownButton setBackgroundImage:[[UIImage imageNamed:@"downlist.png"] stretchableImageWithLeftCapWidth:40 topCapHeight:5] forState:UIControlStateNormal];
    
    [_enterButton setBackgroundImage:[[UIImage imageNamed:@"OpBigBtn.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:12] forState:UIControlStateNormal];
    [_enterButton setBackgroundImage:[[UIImage imageNamed:@"OpBigBtnHighlight.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:12] forState:UIControlStateHighlighted];
    [_enterButton setTitle:NSLocalizedString(@"OK", nil) forState:UIControlStateNormal];
    
    [_cancelButton setBackgroundImage:[[UIImage imageNamed:@"OpBigBtn.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:12] forState:UIControlStateNormal];
    [_cancelButton setBackgroundImage:[[UIImage imageNamed:@"OpBigBtnHighlight.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:12] forState:UIControlStateHighlighted];
    [_cancelButton setTitle:NSLocalizedString( @"Cancel", nil) forState:UIControlStateNormal];
    
    [_cancelUploadButton setBackgroundImage:[[UIImage imageNamed:@"OpBigBtn.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:12] forState:UIControlStateNormal];
    [_cancelUploadButton setBackgroundImage:[[UIImage imageNamed:@"OpBigBtnHighlight.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:12] forState:UIControlStateHighlighted];
    [_cancelUploadButton setTitle:NSLocalizedString( @"Cancel", nil) forState:UIControlStateNormal];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _isAppear = YES;
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    _isAppear = NO;
}

-(void)sendMessage{
    if(_wallBoardMessage){
        NSLog(@"%@",_noteMessage.categoryIDForWallBoard);
        [ACNetCenter Notes_sendWallBoardMessage:_wallBoardMessage];
    }
    else{
        [ACNetCenter Notes_sendNoteMessage:_noteMessage withTopicEntityID:_superVC.topicEntity.entityID];
    }
}

#pragma mark -keyboardNotification
-(void)keyboardWillShow:(NSNotification *)noti
{
    if (_isAppear)
    {
        NSDictionary *info = [noti userInfo];
        CGSize size = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
        _currentHeight = size.height;
//        NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
//        int curve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
        
        float currentY = _contentView.size.height-size.height;
        
        _buttonType = ACButtonType_none;
        [_directImageView setHidden:YES];
        
//        [UIView beginAnimations:nil context:nil];
//        [UIView setAnimationDuration:duration];
//        [UIView setAnimationCurve:curve];
        
        //设置y跟踪键盘显示,做动画
        [_buttonBarView setFrame_y:currentY-_buttonBarView.size.height];
        [_textView setFrame_height:_buttonBarView.origin.y];
        
//        [UIView commitAnimations];
    }
}

-(void)keyboardWillHide:(NSNotification *)noti
{
    if (_isAppear)
    {
//        NSDictionary *info = [noti userInfo];
//        NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
//        int curve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
        
        _currentHeight = 0;
        if(_webLinkButton.hidden){
            if ([_cameraButton.titleLabel.text isEqualToString:NSLocalizedString( @"Camera", nil)])
            {
                [self photoButtonTouchUp:nil];
            }
            else if ([_cameraButton.titleLabel.text isEqualToString:NSLocalizedString(@"Video", nil)])
            {
                [self VideoButtonTouchUp:nil];
            }
        }
        else{
            [self webLinkBarButtonTouchUp:nil];
        }
        
        //设置y跟踪键盘隐藏,做动画
        [_buttonBarView setFrame_y:(kScreen_Height - 64-50-250)];
        ///[_buttonBarView setFrame_y:239-([ACConfigs isPhone5]?0:88)-(_isOpenHotspot?hotsoptHeight:0)];
       /// [_buttonBarView mas_makeConstraints:^(MASConstraintMaker *make) {
           /// make.bottom.equalTo(_detailView.mas_top);
//            make.top.offset(kScreen_Height - 64-50-250);
//        }];
        NSLog(@"_detailView.size_detailView.size    %@",NSStringFromCGSize(_detailView.size));
        [_textView setFrame_height:_buttonBarView.origin.y];
    }
}

#pragma mark -kvo
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _noteMessage && [keyPath isEqualToString:kProgress])
    {
        _uploadProgressView.progress = _noteMessage.progress;
        _uploadProgressLabel.text = [NSString stringWithFormat:@"%.0f%%",_noteMessage.progress*100];
        [_uploadProgressLabel setHidden:NO];
    }
}


#pragma mark -notification
-(void)sendWallboardSucc:(NSNotification *)noti
{
    if (noti.object == _noteMessage || noti.object == _wallBoardMessage)
    {
        ITLog(@"TXB");
        [_contentView showProgressHUDSuccessWithLabelText:NSLocalizedString(@"Uploaded successfully", nil) withAfterDelayHide:1.0];
        [_promptView setHidden:YES];
        [_superVC sendNoteMessageSuccess:_wallBoardMessage?_wallBoardMessage:_noteMessage];
        [self ACdismissViewControllerAnimated:YES completion:nil];
    }
}

-(void)sendWallboardFail:(NSNotification *)noti
{
    if (noti.object == _noteMessage || noti.object == _wallBoardMessage)
    {
        [_contentView showProgressHUDNoActivityWithLabelText:NSLocalizedString(@"Failed to upload", nil) withAfterDelayHide:1.0];
        [_promptView setHidden:YES];
    }
}

-(void)sendWallboardNotNetwork:(NSNotification *)noti
{
    if (noti.object == _noteMessage || noti == nil || noti.object == _wallBoardMessage)
    {
        [_contentView showProgressHUDNoActivityWithLabelText:NSLocalizedString(@"Network_Failed", nil) withAfterDelayHide:1.0];
        [_promptView setHidden:YES];
    }
}

-(void)hotspotStateChange:(NSNotification *)noti
{
    if (_isOpenHotspot)
    {
        [_textView setFrame_height:_textView.size.height-hotsoptHeight];
        [_buttonBarView setFrame_y:_buttonBarView.origin.y-hotsoptHeight];
        [_detailView setFrame_y:_detailView.origin.y-hotsoptHeight];
        [_contentView setFrame_height:_contentView.size.height-hotsoptHeight];
    }
    else
    {
        [_textView setFrame_height:_textView.size.height+hotsoptHeight];
        [_buttonBarView setFrame_y:_buttonBarView.origin.y+hotsoptHeight];
        [_detailView setFrame_y:_detailView.origin.y+hotsoptHeight];
        [_contentView setFrame_height:_contentView.size.height+hotsoptHeight];
    }
}

#pragma mark -reloadImage
-(void)reloadBarButtonImage
{
    if ([[_barDic objectForKey:kHasLocation] boolValue])
    {
        [_locationBarButton setImage:[UIImage imageNamed:@"write-icon_03_location_02.png"] forState:UIControlStateNormal];
    }
    else
    {
        [_locationBarButton setImage:[UIImage imageNamed:@"write-icon_03_location_01.png"] forState:UIControlStateNormal];
    }
    
    if ([[_barDic objectForKey:kHasVideo] boolValue])
    {
        [_videoBarButton setImage:[UIImage imageNamed:@"write-icon_02_video_02.png"] forState:UIControlStateNormal];
    }
    else
    {
        [_videoBarButton setImage:[UIImage imageNamed:@"write-icon_02_video_01.png"] forState:UIControlStateNormal];
    }
    
    if ([[_barDic objectForKey:kHasPhoto] boolValue])
    {
        [_photoBarButton setImage:[UIImage imageNamed:@"write-icon_01_camera_02.png"] forState:UIControlStateNormal];
    }
    else
    {
        [_photoBarButton setImage:[UIImage imageNamed:@"write-icon_01_camera_01.png"] forState:UIControlStateNormal];
    }
}

-(void)detailDataSourceArrayForImage{
    BOOL bIsImage = ACButtonType_photo==_buttonType;
    _detailDataSourceArray =  bIsImage?_noteMessage.imageList:_noteMessage.videoList;
    dispatch_async(dispatch_get_main_queue(), ^{
        if(!(ACButtonType_photo==_buttonType||ACButtonType_video==_buttonType)){
            //不是photo或video
            return ;
        }
        
        if ([_detailDataSourceArray count] == 0)
        {
            [_detailTableView setHidden:YES];
            [_detailHolderImageView setHidden:NO];
            [_barDic setObject:[NSNumber numberWithBool:NO] forKey:bIsImage?kHasPhoto:kHasVideo];
        }
        else
        {
            [_detailTableView setHidden:NO];
            [_detailHolderImageView setHidden:YES];
            [_detailTableView reloadData];
            [_barDic setObject:[NSNumber numberWithBool:YES] forKey:bIsImage?kHasPhoto:kHasVideo];
        }
        [self reloadBarButtonImage];
    });
}

-(void)removeContent:(ACNoteContentImageOrVideo*)pFile{
    [_noteMessage delImageOrVideo:pFile];
    [self detailDataSourceArrayForImage];
}


-(void)setLocaltion:(ACNoteContentLocation*)localInfo{
    _noteMessage.location   =   localInfo;
    [_barDic setObject:[NSNumber numberWithBool:YES] forKey:kHasLocation];
    [self reloadBarButtonImage];
}

//-(void)setLocationCoordinate:(CLLocationCoordinate2D) coordinate withAddress:(NSString*)locationAddress{
//    _noteMessage.location = [[ACNoteContentLocation alloc] init];
//    _noteMessage.location.Location =    coordinate;
//    _noteMessage.location.address   =   locationAddress;
//    [_barDic setObject:[NSNumber numberWithBool:YES] forKey:kHasLocation];
//    [self reloadBarButtonImage];
//}


#pragma mark -dropDownDelegate
- (void) niDropDownDelegateMethod: (NIDropDown *) sender index:(int)index
{
    self.dropDown = nil;
    _category = [_superVC.topicEntity.categoriesArray objectAtIndex:index];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_category.cid forKey:kWallboardLastCategoryID];
    [defaults synchronize];
}

#pragma mark -IBAction
-(IBAction)goback:(id)sender
{
    if ([_textView.text length] > 0 ||
        [_noteMessage.imgs_Videos_List count] > 0 ||
        _noteMessage.location)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"Do you want to discard?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Discard", nil), nil];
        alert.tag = kGobackAlertTag;
        [alert show];
    }
    else
    {
        ITLog(@"TXB");
        [self ACdismissViewControllerAnimated:YES completion:nil];
    }
}

-(IBAction)dropDownButtonTouchUp:(id)sender //WallBoard 类型
{
    if(_dropDown == nil) {
        CGFloat f = 130;
        if ([_superVC.topicEntity.categoriesArray count] > 5)
        {
            f = 205;
        }
        else if ([_superVC.topicEntity.categoriesArray count] > 4)
        {
            f = 185;
        }
        else if ([_superVC.topicEntity.categoriesArray count] > 3)
        {
            f = 160;
        }
        
        _dropDown = [[NIDropDown alloc]showDropDown:sender :&f :_superVC.topicEntity.categoriesArray];
        _dropDown.delegate = self;
    }
    else
    {
        [_dropDown hideDropDown:sender];
        self.dropDown = nil;
    }
}

-(IBAction)cancelUploadButtonTouchUp:(id)sender
{
    [_uploadProgressView setProgress:0];
    [_uploadProgressLabel setText:@""];
    [_promptView setHidden:YES];
    _isCancelSend = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNetCenterNotes_Note_Upload_Fail_Notifition object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNetCenterNotes_Note_Upload_NoNetword_Notifition object:nil];
    [[ACNetCenter shareNetCenter].sendNoteOrWallboardRequest cancel];
    [ACNetCenter shareNetCenter].sendNoteOrWallboardRequest = nil;
}

-(IBAction)finishButtonTouchUp:(id)sender
{
    [self photoButtonTouchUp:nil];
    [_textView resignFirstResponder];
    _noteMessage.content = [_textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([_noteMessage.content length] > 0)
    {
        [_promptView setHidden:NO];
        [_uploadView setHidden:YES];
        if(_wallBoardMessage){
            _enterButton.hidden = NO;
            [_categoryView setHidden:NO];
            [_dropDownButton setHidden:_categoryView.hidden];
        }
        else{
            _enterButton.hidden = YES;
            [self categoryEnterButtonTouchUp:nil];
        }
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"Please input content", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        [alert show];
    }
}

-(IBAction)categoryEnterButtonTouchUp:(id)sender
{
    if(_wallBoardMessage){
        _noteMessage.categoryIDForWallBoard =   _category.cid;
    }

    if ([ASIHTTPRequest isValidNetWork])
    {
        [_promptView setHidden:NO];
        [_categoryView setHidden:YES];
        [_dropDownButton setHidden:_categoryView.hidden];
        [_uploadView setHidden:NO];
        
        _isCancelSend = NO;
        [self noteMoviesToMp4];
    }
    else
    {
        [self sendWallboardNotNetwork:nil];
    }
}

-(IBAction)categoryCancelButtonTouchUp:(id)sender
{
    [_promptView setHidden:YES];
}

-(IBAction)photoButtonTouchUp:(id)sender
{
    [_textView resignFirstResponder];
    if (_buttonType != ACButtonType_photo)
    {
        _buttonType = ACButtonType_photo;
 
        _cameraButton.hidden = NO;
        _photoButton.hidden = NO;
        [self webInfoHide];
        
        [_directImageView setHidden:NO];
        [_directImageView setFrame_x:_photoBarButton.origin.x];
        [_cameraButton setTitle:NSLocalizedString(@"Camera", nil) forState:UIControlStateNormal];
        _detailHolderImageView.image = [UIImage imageNamed:@"write_noimage_01.png"];
        [_detailHolderImageView setFrame_width:93];
        [_detailHolderImageView setCenter_x:_detailView.size.width/2];
        
        [self detailDataSourceArrayForImage];
    }
}

-(IBAction)VideoButtonTouchUp:(id)sender
{
    [_textView resignFirstResponder];
    if (_buttonType != ACButtonType_video)
    {
        _buttonType = ACButtonType_video;
        _cameraButton.hidden = NO;
        _photoButton.hidden = NO;
        
        [self webInfoHide];
        
        [_directImageView setHidden:NO];
        [_directImageView setFrame_x:_videoBarButton.origin.x];
        [_cameraButton setTitle:NSLocalizedString(@"Video", nil) forState:UIControlStateNormal];
        _detailHolderImageView.image = [UIImage imageNamed:@"write_novideo_02.png"];
        [_detailHolderImageView setFrame_width:122];
        [_detailHolderImageView setCenter_x:_detailView.size.width/2];
        
        [self detailDataSourceArrayForImage];
    }
}

#pragma mark -----按钮功能

-(IBAction)locationButtonTouchUp:(id)sender
{
    if (_noteMessage.location)
    {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete", nil) otherButtonTitles:NSLocalizedString(@"New location", nil), nil];
        sheet.tag = kActionSheetTag;
        [sheet showInView:_contentView];
    }
    else
    {
        [_textView resignFirstResponder];
        ACMapViewController* sendLocationVC =  [[ACMapViewController alloc] initWithSuperVC:self];
        [self ACpresentViewController:sendLocationVC animated:YES completion:nil];

//        ACSendLocationViewController *sendLocationVC = [[ACSendLocationViewController alloc] initWithSuperVC:self];
//        [self ACpresentViewController:sendLocationVC animated:YES completion:nil];
    }
}
- (IBAction)webLinkBarButtonTouchUp:(id)sender {
    
    [_textView resignFirstResponder];
    if (_buttonType != ACButtonType_webLink)
    {
        _buttonType = ACButtonType_webLink;
      
        _cameraButton.hidden = YES;
        _photoButton.hidden = YES;
        _webLinkButton.hidden = NO;
        _detailTableView.hidden = YES;
        
        _directImageView.hidden = NO;
        [_directImageView setFrame_x:_webLinkBarButton.origin.x];

        if(_noteMessage.link){
            _webLinkDelButton.hidden = NO;
            _webInfoBk.hidden = NO;
            _detailHolderImageView.hidden = YES;
        }
        else{
            _webLinkDelButton.hidden = YES;
            _webInfoBk.hidden = YES;
            _detailHolderImageView.hidden = NO;
        }
        
        _detailHolderImageView.image = [UIImage imageNamed:@"write_noweblink_01.png"];
        [_detailHolderImageView setFrame_width:93];
        [_detailHolderImageView setCenter_x:_detailView.size.width/2];
    }
}

- (IBAction)webLinkButtonTouchUp:(id)sender {
    
    if (_noteMessage.link){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"Only one link is supported.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    else{
        _isAppear = NO;
        [_textView resignFirstResponder];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"Input the link you want to share", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        alert.alertViewStyle  = UIAlertViewStylePlainTextInput;
        UITextField *tf = [alert textFieldAtIndex:0];
        tf.text =   @"http://www.";
        tf.keyboardType = UIKeyboardTypeURL;
        alert.tag   =   kWeblinkInputTag;
        [alert show];
    }
}

- (IBAction)webLinkDelButtonTouchUp:(id)sender {
    _noteMessage.link = nil;
    _webLinkDelButton.hidden = YES;
    _webInfoBk.hidden   =   YES;
    _detailHolderImageView.hidden = NO;
    [_webLinkBarButton setImage:[UIImage imageNamed:@"write_01_link_icon_normal.png"] forState:UIControlStateNormal];
}

-(IBAction)cameraButtonTouchUp:(id)sender
{
    if ([_noteMessage.imgs_Videos_List count] >= kMultiCount)
    {
        NSString *message = [NSString stringWithFormat:@"%@%d",NSLocalizedString(@"accessory max count is ", nil),kMultiCount];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    if (_buttonType == ACButtonType_photo){
        [self selectImageWithUIImagePickerController_Delegate:self forCamera:YES];
        return;
    }
    
    if (_buttonType == ACButtonType_video){
        [self videoWithUIImagePickerController_Delegate:self fromRecord:YES];
        return;
    }
    
    /*
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        UIImagePickerController *imagePC = [[UIImagePickerController alloc] init];
        imagePC.delegate = self;
        imagePC.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        if (_buttonType == ACButtonType_photo)
        {
            imagePC.videoQuality = UIImagePickerControllerQualityTypeHigh;
        }
        else if (_buttonType == ACButtonType_video)
        {
            imagePC.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeMovie, nil];
            imagePC.videoQuality = UIImagePickerControllerQualityTypeMedium;
            imagePC.videoMaximumDuration = 60;
            imagePC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        }
        [self ACpresentViewController:imagePC animated:YES completion:nil];
    }*/
}

-(IBAction)albumButtonTouchUp:(id)sender
{
    if (_noteMessage.imgs_Videos_List.count>= kMultiCount)
    {
        NSString *message = [NSString stringWithFormat:@"%@%d",NSLocalizedString(@"accessory max count is ", nil),kMultiCount];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    if(ACButtonType_photo==_buttonType){
        [self selectImagesWithELC_Delegate:self withCount:(int)(kMultiCount-_noteMessage.imgs_Videos_List.count)];
        return;
    }
    [self videoWithUIImagePickerController_Delegate:self fromRecord:NO];
    
    
/*
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] initImagePicker];
        
        elcPicker.returnsOriginalImage = YES; //Only return the fullScreenImage, not the fullResolutionImage
        elcPicker.returnsImage = YES; //Return UIimage if YES. If NO, only return asset location information
//        elcPicker.onOrder = NO; //For multiple image selection, display and return order of selected images
//        elcPicker.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie]; //Supports image and movie types
//        [ELCConsole mainConsole]
        if(ACButtonType_photo==_buttonType){
            elcPicker.maximumImagesCount = kMultiCount-_noteMessage.imgs_Videos_List.count; //Set the maximum number of images to select to 100
            elcPicker.mediaTypes = @[(NSString *)kUTTypeImage];
        }
        else{
            elcPicker.maximumImagesCount = 1; //Set the maximum number of images to select to 100
            elcPicker.mediaTypes = @[(NSString *)kUTTypeMovie];
        }
        
        elcPicker.imagePickerDelegate = self;
        
        [self ACpresentViewController:elcPicker animated:YES completion:nil];
    }*/
}

#pragma mark ----UIAlertView

-(void)webInfoHide{
    _webLinkButton.hidden = YES;
    _webLinkDelButton.hidden = YES;
    _webInfoBk.hidden   =   YES;
}

-(void)webInfoShow{
    [_webInfoIcon setImageWithURL:[NSURL URLWithString:_noteMessage.link.linkIcon] placeholderImage:[UIImage imageNamed:@"image_placeHolder.png"] imageName:@"" imageType:ImageType_ImageMessage];
    _webInfoURL.text    =   _noteMessage.link.linkURL;
    _webInfoTitle.text   =   _noteMessage.link.linkTitle;
    _webInfoDesc.text   =   _noteMessage.link.linkDesc;
    
    float fWebInfoHight = [ACNoteListVC_Cell getWebLinkInfoViewHight:_webInfoTitle lableURL:_webInfoURL descLable:_webInfoDesc iconView:_webInfoIcon andMaxW:_webInfoURL.frame.size.width];
    
    [_webInfoBk setFrame_height:fWebInfoHight];
    
    _webInfoBk.center   =   _detailHolderImageView.center;
    [_webLinkDelButton setFrame_y:_webInfoBk.frame.origin.y-(106-88)];
    
    _detailTableView.hidden = YES;
    _webInfoBk.hidden   =   NO;
    _webLinkDelButton.hidden = NO;
    _detailHolderImageView.hidden = YES;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kGobackAlertTag)
    {
        if (buttonIndex == alertView.cancelButtonIndex)
        {
            
        }
        else if (buttonIndex == alertView.firstOtherButtonIndex)
        {
            ITLog(@"TXB");
            [self ACdismissViewControllerAnimated:YES completion:nil];
        }
    }
    else if(kWeblinkInputTag==alertView.tag){
        _isAppear   =   YES; //避免处理键盘
        if(buttonIndex == alertView.firstOtherButtonIndex){
            
            NSString* pUrlStr = ((UITextField*)[alertView textFieldAtIndex:0]).text;
            
            /*
             /apis/url/website/info?u=http://www.aculearn.com
             GET
             Response
             {
             "code" : 1,
             "img" : "http://host/1.png",
             "description" : "Aculearn website",
             "title" : "AcuLearn"
             }
             */
            if(0==pUrlStr.length){
                return;
            }
            
            ACNoteContentWebsite* pLinkInfo = [[ACNoteContentWebsite alloc] init];
            pLinkInfo.linkURL   =   pUrlStr;
            pLinkInfo.linkTitle =   pUrlStr;
            _noteMessage.link   =   pLinkInfo;
            [self webInfoShow];
            [_webLinkBarButton setImage:[UIImage imageNamed:@"write_01_link_icon_selected.png"] forState:UIControlStateNormal];    
            
            NSString * const acGetWebInfoUrl = [NSString stringWithFormat:@"%@/rest/apis/url/website/info?u=%@",[[ACNetCenter shareNetCenter] acucomServer],[pUrlStr URL_Encode]];
            [self.view showNetLoadingWithAnimated:NO];
            
            wself_define();
            [ACNetCenter callURL:acGetWebInfoUrl forMethodDelete:NO withBlock:^(ASIHTTPRequest *request, BOOL bIsFail) {
                
                [wself.view hideProgressHUDWithAnimated:NO];
                
                if(!bIsFail){
                    NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
                    ITLog(responseDic);
                    if(ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]){
                        pLinkInfo.linkTitle =   [responseDic objectForKey:@"title"];
                        pLinkInfo.linkDesc  =   [responseDic objectForKey:@"description"];
                        pLinkInfo.linkIcon  =   [responseDic objectForKey:@"img"];
                        if(pLinkInfo.linkTitle.length==0){
                            pLinkInfo.linkTitle =   pUrlStr;
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
//#if TARGET_IPHONE_SIMULATOR
//                             pLinkInfo.linkTitle    =   @"这是测试标题,这是测试标题这是测试标题这是测试标题这是测试标题这是测试标题这是测试标题这是测试标题这是测试标题";
//                            pLinkInfo.linkDesc  =   @"这是描述,这是描述这是描述这是描述这是描述这是描述这是描述这是描述这是描述这是描述这是描述这是描述这是描述这是描述";
//#endif
                            [wself webInfoShow];
                        });
                    }
                 }
            }];
        }
    }
}

#pragma mark -UIActionSheet
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == kActionSheetTag)
    {
        if (buttonIndex == actionSheet.firstOtherButtonIndex)
        {
            _noteMessage.location = nil;
            [self locationButtonTouchUp:nil];
            
//            [_textView resignFirstResponder];
//            ACSendLocationViewController *sendLocationVC = [[ACSendLocationViewController alloc] initWithSuperVC:self];
//            [self ACpresentViewController:sendLocationVC animated:YES completion:nil];
        }
        else if (buttonIndex == actionSheet.destructiveButtonIndex)
        {
            _noteMessage.location = nil;
            [_barDic setObject:[NSNumber numberWithBool:NO] forKey:kHasLocation];
            [self reloadBarButtonImage];
        }
    }
}

#pragma mark -movieToMp4
-(void)noteMoviesToMp4
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
       
        _movieCount = (int)_noteMessage.videoList.count;
        _movieToMp4FinishedCount = 0;
        
        //展示当前压缩/总数
        if (_movieCount)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![_uploadLabel.text hasPrefix:isCompressing])
                {
                    _uploadLabel.text = [isCompressing stringByAppendingFormat:@"(%d/%d)",_movieToMp4FinishedCount,_movieCount];;
                }
            });
        }
        
        //压缩
        for (ACNoteContentImageOrVideo *page in _noteMessage.videoList)
        {
            [self movieToMp4:page.video_referenceURL withResourceID:page.resourceID];
        }
        
        if (0==_movieCount && !_isCancelSend)
        {
            _uploadLabel.text = NSLocalizedString(@"Uploading", nil);
            [self sendMessage];
        }
    });
}

-(BOOL)movieToMp4:(NSURL *)movieURL withResourceID:(NSString *)resourceID
{
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:movieURL options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality])
    {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
        __block NSString *mp4Path = [ACAddress getAddressWithFileName:resourceID fileType:ACFile_Type_WallboardVideo isTemp:NO subDirName:nil];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:mp4Path])
        {
            [self compesseFinished];
        }
        
        exportSession.outputURL = [NSURL fileURLWithPath:mp4Path];
        exportSession.outputFileType = AVFileTypeMPEG4;
        
        __block BOOL success = NO;
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusFailed:
                {
                    ITLog(([NSString stringWithFormat:@"Export Failed%@",exportSession.error]));
                    _compresseFailCount += 1;
                }
                    break;
                case AVAssetExportSessionStatusCancelled:
                    ITLog(@"Export canceled");
                    break;
                case AVAssetExportSessionStatusCompleted:
                {
                    ITLog(@"Successful!");
                    success = YES;
                    
                    [self compesseFinished];
                }
                    break;
                default:
                    break;
            }
            if (_compresseFailCount != 0 && _compresseFailCount + _movieToMp4FinishedCount == _movieCount)
            {
                NSString *message = [NSString stringWithFormat:@"%@%d",NSLocalizedString(@"compress fail,fail count is ", nil),_compresseFailCount];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
                [alert show];
            }
        }];
        return success;
    }
    else
    {
        return NO;
    }
}

-(void)compesseFinished
{
    _movieToMp4FinishedCount += 1;
    
    if (_movieToMp4FinishedCount == _movieCount && !_isCancelSend)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            _uploadLabel.text = NSLocalizedString(@"Uploading", nil);
        });
        [self sendMessage];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            _uploadLabel.text = [isCompressing stringByAppendingFormat:@"(%d/%d)",_movieToMp4FinishedCount,_movieCount];
        });
    }
}

#pragma mark -UITableViewDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_detailDataSourceArray count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACContributeVC_ThumbCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACContributeVC_ThumbCell"];
    if (!cell)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACContributeVC_ThumbCell" owner:nil options:nil];
        cell = [nib objectAtIndex:0];
        cell.transform = CGAffineTransformMakeRotation(M_PI/2);
    }
    [cell setFilePage:[_detailDataSourceArray objectAtIndex:indexPath.row] superVC:self];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 120;
}

#pragma mark -imagePickerController
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info //这是为了处理直接拍照或录像
{
    [picker ACdismissViewControllerAnimated:YES completion:nil];
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeMovie])
    {
        NSURL *movieUrl = [info objectForKey:UIImagePickerControllerMediaURL];
        if([ACUtility checkVideo:movieUrl Deuration:Send_Video_Maximum_Duration]){
            return;
        }

        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            NSString *resourceID = [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]];
            
            ACNoteContentImageOrVideo *page = [[ACNoteContentImageOrVideo alloc] initForImage:NO];
            page.video_referenceURL = movieUrl;
            
            page.resourceID = resourceID;
            page.thumbResourceID = [resourceID stringByAppendingString:@"_s"];
            page.height = 200;
            
            //获取缩略图，写本地
            @autoreleasepool {
                /*
                MPMoviePlayerController *playC = [[MPMoviePlayerController alloc] initWithContentURL:movieUrl];
                playC.shouldAutoplay = NO;
                UIImage *image = [playC thumbnailImageAtTime:1 timeOption:MPMovieTimeOptionNearestKeyFrame];*/
                
                UIImage *thumbImage = [[ACUtility thumbFromMovieURL:movieUrl] imageScaledToBigFixedSize:CGSizeMake(200, 200)];
                [UIImageJPEGRepresentation(thumbImage, 0.75) writeToFile:page.thumbFilePath atomically:YES];
            }
            
            
            [_noteMessage addImageOrVideo:page];
            
            
            [_barDic setObject:[NSNumber numberWithBool:YES] forKey:kHasVideo];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self reloadBarButtonImage];
                [self detailDataSourceArrayForImage];
            });
        });
    }
    else if ([mediaType isEqualToString:(NSString *)kUTTypeImage])
    {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            NSString *resourceID = [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]];
            ACNoteContentImageOrVideo *page = [[ACNoteContentImageOrVideo alloc] initForImage:YES];
            page.resourceID = resourceID;
            page.thumbResourceID = [resourceID stringByAppendingString:@"_s"];
            page.height = 960;
            
            @autoreleasepool {
                UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
                originalImage = [originalImage imageScaledToBigFixedSize:CGSizeMake(2000, 2000)];

                [UIImageJPEGRepresentation(originalImage, 1) writeToFile:page.resourceFilePath atomically:YES];
                
                UIImage *scaledSmallImage = [originalImage imageScaledInterceptToSize:CGSizeMake(200, 200)];
                [UIImageJPEGRepresentation(scaledSmallImage, 0.75) writeToFile:page.thumbFilePath atomically:YES];
            }
            
            [_noteMessage addImageOrVideo:page];
            [self detailDataSourceArrayForImage];
            
            [_barDic setObject:[NSNumber numberWithBool:YES] forKey:kHasPhoto];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self reloadBarButtonImage];
            });
        });
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker ACdismissViewControllerAnimated:YES completion:nil];
}


#pragma mark ELCImagePickerControllerDelegate Methods
- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info {
    
    [picker ACdismissViewControllerAnimated:YES completion:nil];
    for (NSDictionary *dic in info)
    {
        NSString *resourceID = [dic objectForKey:ELCImagePickerControllerResourceID];
        
        ACNoteContentImageOrVideo *page = [[ACNoteContentImageOrVideo alloc] initForImage:YES];
        /*
         不再使用ELCImagePickerController选择Video
        ACNoteContentImageOrVideo *page = [[ACNoteContentImageOrVideo alloc] initForImage:[[dic objectForKey:UIImagePickerControllerMediaType] isEqualToString:ALAssetTypePhoto]];

        if(!page.bIsImage){
            page.video_referenceURL = [dic objectForKey:UIImagePickerControllerReferenceURL];
            if([ACUtility checkVideo:page.video_referenceURL Deuration:60]){
                continue;
            }
        }*/
    
        page.height = [[dic objectForKey:ELCImagePickerControllerImageHeight] floatValue];
        
        page.resourceID = resourceID;
        page.thumbResourceID = [resourceID stringByAppendingString:@"_s"];
        
        [_noteMessage addImageOrVideo:page];
    }
    [self detailDataSourceArrayForImage];
//    [_barDic setObject:[NSNumber numberWithBool:YES] forKey:bIsImage?kHasPhoto:kHasVideo];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadBarButtonImage];
    });
 }

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker
{
	[picker ACdismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
