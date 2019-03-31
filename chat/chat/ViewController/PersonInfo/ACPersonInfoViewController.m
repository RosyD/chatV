//
//  ACPersonInfoViewController.m
//  AcuCom
//
//  Created by 王方帅 on 14-5-4.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACPersonInfoViewController.h"
#import "UINavigationController+Additions.h"
#import "ACNetCenter.h"
#import "ASIFormDataRequest.h"
#import "JSONKit.h"
#import "UIImageView+WebCache.h"
#import "UIImage+Additions.h"
#import "UIView+Additions.h"
#import "ACAddress.h"
#import "UIView+Additions.h"
#import "ACUserDB.h"
#import "ACChangePasswordController.h"
#import "NSString+Additions.h"
#import "ACParticipantInfoViewController.h"


/*
 account:"mark@aculearn.com.cn"
 account2:"mark.dong@aculearn"
 department:""
 domain:"aculearn"
 fname:"mark"
 icon:"/rest/apis/user/icon/user/56e620e1659ebbea61ee6cb1?t=1466406951885"
 id:"56e620e1659ebbea61ee6cb1"
 lastAccessTime:1467717819566
 lastLogin:1467717819566
 lname:"dong"
 name:"mark dong"
 updateTime:1468555184151
 */

NSString *const kPersonInfoPutSuccessNotifation = @"kPersonInfoPutSuccessNotifation";


#define    TitleLable_Tag_Icon       100
#define    TitleLable_Tag_fname      200
#define    TitleLable_Tag_lname      205
#define    TitleLable_Tag_account    300
#define    TitleLable_Tag_comment    400
#define    TitleLable_Tag_password   500
#define    TitleLable_Tag_jobTitle   600
#define    TitleLable_Tag_department 700
#define    TitleLable_Tag_phone      800
//#define    TitleLable_Tag_email      900
#define    TitleLable_Tag_address    1000

//输入框的Tag：InputView_Tag = TitleLable_Tag+1


#define LogInID_FieldName   @"account2"



#define    InputView_FieldName_Icon       @"icon"
#define    InputView_FieldName_fname      @"fname"
#define    InputView_FieldName_lname      @"lname"
#define    InputView_FieldName_account    @"account"
#define    InputView_FieldName_comment    @"description"
#define    InputView_FieldName_jobTitle   @"jobTitle"
#define    InputView_FieldName_department @"department"
#define    InputView_FieldName_phone      @"phone"
//#define    InputView_FieldName_email      @"email"
#define    InputView_FieldName_address    @"address"


@interface ACPersonInfoViewController (){
    UIView*         _pNowFocusEditView;
    CGFloat         _fKeyboardHight;
    CGFloat         _fScrollHight;
    NSArray*        _sorted_item_inputViews;
    NSString*       _pIconID;
    BOOL            _bIconDeleted; //删除了IconID
    NSDictionary*   _pUserProfileOld;
    NSMutableDictionary*    _pUserProfileNew;
}

@property (weak, nonatomic) IBOutlet UIView         *userInfoView;
@property (weak, nonatomic) IBOutlet UIScrollView   *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *loginIDLable;
@property (weak, nonatomic) IBOutlet UILabel *loginIDTitleLable;


@property (weak, nonatomic) IBOutlet UIButton *icon_BkButton;
@property (weak, nonatomic) IBOutlet  UIImageView    *icon_ImageView;

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *item_lables;

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *item_inputViews;

@property (weak, nonatomic) IBOutlet UIButton *endInfo_BkButton;
@property (weak, nonatomic) IBOutlet GCPlaceholderTextView *comment_textView;
@property (weak, nonatomic) IBOutlet GCPlaceholderTextView *address_textView;


@end

@implementation ACPersonInfoViewController

AC_MEM_Dealloc_implementation


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
//        _isNeedDismiss = NO;
    }
    return self;
}

-(NSString*)_getFieldNameFromViewTag:(NSInteger)nViewTag{
    switch (nViewTag) {
        case TitleLable_Tag_Icon:
            return InputView_FieldName_Icon;
            
        case TitleLable_Tag_fname:
            return InputView_FieldName_fname;
            
        case TitleLable_Tag_lname:
            return InputView_FieldName_lname;
            
        case TitleLable_Tag_account:
            return InputView_FieldName_account;
            
        case TitleLable_Tag_comment:
            return InputView_FieldName_comment;
            
        case TitleLable_Tag_jobTitle:
            return InputView_FieldName_jobTitle;
            
        case TitleLable_Tag_department:
            return InputView_FieldName_department;
            
        case TitleLable_Tag_phone:
            return InputView_FieldName_phone;
            
//        case TitleLable_Tag_email:
//            return InputView_FieldName_email;
            
        case TitleLable_Tag_address:
            return InputView_FieldName_address;
            
        default:
            break;
    }
    return nil;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    ///
    [self.userInfoView setFrame_width:kScreen_Width];
    
    _titleLabel.text = NSLocalizedString(@"Personal info", nil);
    [_saveButton setNomalText:NSLocalizedString(@"Save",nil)];
    
    _sorted_item_inputViews = [_item_inputViews sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if(((UIView*)obj1).tag>((UIView*)obj2).tag){
            return NSOrderedDescending;
        }
        return NSOrderedAscending;
    }];
    //初始化界面
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [_icon_ImageView setToCircle];
//    [_icon_ImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onUesrIconClicked)]];
    [_icon_ImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(iconButtonTouchUp:)]];
    
    if (![ACConfigs isPhone5])
    {
        [_contentView setFrame_height:_contentView.size.height-88];
        [_scrollView setFrame_height:_contentView.size.height];
    }
    [_scrollView setFrame_y:-20];
    [_scrollView setFrame_height:_scrollView.size.height+20];
    
//    [_backButton setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateNormal];
    
    
//    [_comment_textView setTextAlignment:NSTextAlignmentLeft];
    
    [_icon_BkButton setBackgroundImage:[[UIImage imageNamed:@"it_contact_detail_up.png"] stretchableImageWithLeftCapWidth:152 topCapHeight:22] forState:UIControlStateNormal];
    [_icon_BkButton setBackgroundImage:[[UIImage imageNamed:@"it_contact_detail_up_pressed.png"] stretchableImageWithLeftCapWidth:152 topCapHeight:22] forState:UIControlStateHighlighted];
    
    [_scrollView addSubview:_userInfoView];
    _scrollView.contentSize = _userInfoView.frame.size;
    _fScrollHight = _scrollView.frame.size.height;
    _loginIDTitleLable.text = [ACParticipantInfoViewController userProfileTitleWithItem:LogInID_FieldName];
    
    for(UILabel* pLable in _item_lables){
        
        NSString* pLableName = [self _getFieldNameFromViewTag:pLable.tag];
        if(pLableName){
            pLable.text = [ACParticipantInfoViewController userProfileTitleWithItem:pLableName];
        }
        else if(TitleLable_Tag_password==pLable.tag) {
            pLable.text =   NSLocalizedString(@"Change password", nil);
        }
//        else if((TitleLable_Tag_account+1)==pLable.tag){
//            pLable.text = [defaults objectForKey:kAccount];
//        }
#if DEBUG
        else{
            NSAssert(NO,@"hh");
            NSLog(@"%@",pLable);
        }
#endif
    }
    
    //创建信息
    
   [_endInfo_BkButton setBackgroundImage:[[UIImage imageNamed:@"it_contact_detail_down.png"] stretchableImageWithLeftCapWidth:152 topCapHeight:22] forState:UIControlStateNormal];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
  
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentViewTap)];
    [_contentView addGestureRecognizer:tap];
    
    [self _setUserProfile:nil];
    
    [ACParticipantInfoViewController loadUser:[ACUser myselfUserID] ProfileFromView:self withBlock:^void(NSDictionary *pUserProInfo) {
        [self _setUserProfile:pUserProInfo];
    }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(void)_setIconImage{
    UIImage* placeholderImage =   [UIImage imageNamed:@"personIcon100.png"];
    
    if(_pIconID){
        [_icon_ImageView setImageWithIconString:_pIconID
                               placeholderImage:placeholderImage
                                      ImageType:ImageType_UserIcon100];
    }
    else{
        _icon_ImageView.image = placeholderImage;
    }
}

-(void)_setUserProfile:(NSDictionary*)pDictUser{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if(nil==pDictUser){
        
        //读取一个旧的
        pDictUser   =   (NSDictionary*)[defaults objectForKey:kUserProfileInfo];
        if(pDictUser.count<4){
            //创建一个缺省的
            NSMutableDictionary* pDictDef = [[NSMutableDictionary alloc] init];
            [pDictDef setValue:[defaults  objectForKey:kUserID] forKey:@"id"];
            [pDictDef setValue:[defaults  objectForKey:kDescription] forKey:InputView_FieldName_comment];
            [pDictDef setValue:[defaults  objectForKey:kAccount] forKey:InputView_FieldName_account];
            [pDictDef setValue:[defaults  objectForKey:kName] forKey:InputView_FieldName_fname];
            [pDictDef setValue:[defaults  objectForKey:kName] forKey:InputView_FieldName_lname];
            [pDictDef setValue:[defaults  objectForKey:kIcon] forKey:InputView_FieldName_Icon];
            pDictUser = pDictDef;
        }
    }
    
    //设置Icon
    _pIconID    =   [pDictUser objectForKey:kIcon];
    if(_pIconID.length<5){
        _pIconID = nil;
    }
    [self _setIconImage];

    _pUserProfileOld    =   pDictUser;
    _accountLable.text  =   pDictUser[InputView_FieldName_account];
    _loginIDLable.text  =   pDictUser[LogInID_FieldName];
    
    //设置信息
    for(UIView* pView in _sorted_item_inputViews){
        NSInteger nLableTag =    pView.tag-1;
        NSString* pFileldName = [self _getFieldNameFromViewTag:nLableTag];
        NSString* pText =   [pDictUser objectForKey:pFileldName];
        
        NSString* ph_Title =    [NSString stringWithFormat:@"user_profile_ph_%@",pFileldName];
        NSString* placeholder = NSLocalizedString(ph_Title,nil);
        
        if(TitleLable_Tag_comment==nLableTag||TitleLable_Tag_address==nLableTag){
            ((UITextView*)pView).text = pText;
            ((GCPlaceholderTextView*)pView).placeholder =   placeholder;
        }
        else{
            ((UITextField*)pView).text = pText;
            ((UITextField*)pView).placeholder = placeholder;
        }
    }
}

-(void)contentViewTap
{
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
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


-(void)_setScrollViewOffsetForInput{
    CGRect editViewRect = _pNowFocusEditView.frame;
    editViewRect.origin.y -= _scrollView.contentOffset.y;
    if(!CGRectContainsRect(_scrollView.frame, editViewRect)){
        _scrollView.contentOffset = CGPointMake(0, _pNowFocusEditView.frame.origin.y-(_scrollView.frame.size.height-_pNowFocusEditView.frame.size.height)/2);
    }
}
-(void)_changeFirstResponder:(UIView*)pView{
    for(NSInteger nNo=0;nNo<_sorted_item_inputViews.count;nNo++){
        if(_sorted_item_inputViews[nNo]==pView){
            nNo ++;
            if(nNo<_sorted_item_inputViews.count){
                _pNowFocusEditView = _sorted_item_inputViews[nNo];
                [_pNowFocusEditView becomeFirstResponder];
                [self _setScrollViewOffsetForInput];
                return;
            }
        }
    }
    [self contentViewTap];
}

#pragma mark -textFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self _changeFirstResponder:textField];
    return YES;
}


#pragma mark -keyboardNotification
-(void)keyboardWillShow:(NSNotification *)noti
{

    NSDictionary *info = [noti userInfo];
    CGSize size = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    _fKeyboardHight = size.height;
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    int curve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
        
//        float currentY = _contentView.size.height-size.height;
    for(UIView* pView in _sorted_item_inputViews){
        if(pView.isFirstResponder){
            _pNowFocusEditView = pView;
            break;
        }
    }
    
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    
    [_scrollView setFrame_height:_fScrollHight-_fKeyboardHight];
    [self _setScrollViewOffsetForInput];
    
    [UIView commitAnimations];
        
}

-(void)keyboardWillHide:(NSNotification *)noti
{
    [_scrollView setFrame_height:_fScrollHight];
}

#pragma mark -textViewDelegate

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString*)text
{
    if ([text isEqualToString:@"\n"]) {
        [self _changeFirstResponder:textView];
        return NO;
    }
    return YES;
}


#pragma mark -IBAction
-(IBAction)iconButtonTouchUp:(id)sender
{
    [self contentViewTap];
    [self selectIconFunc:_pIconID.length||self.iconPathArray.count];
}


-(IBAction)changePassword:(id)sender
{
    [self contentViewTap];
    ACChangePasswordController *changePasswordC = [[ACChangePasswordController alloc] init];
    AC_MEM_Alloc(changePasswordC);
    [self.navigationController pushViewController:changePasswordC animated:YES];
}

-(IBAction)cancalBack:(id)sender{
    [self contentViewTap];
    [self onCallGoback];
}


-(IBAction)saveButtonTouchUp:(id)sender
{
    [self contentViewTap];
    [self onCallSave];
}

//-(void)onUesrIconClicked{
//    [self contentViewTap];
//    
//    if(self.iconPathArray.count){
//        [self  MWPhotoBrowser_ShowPhotoFile:self.iconPathArray[0] withURL:nil];
//        return;
//    }
//    
//    if(_pIconID.length){
//        [self MWPhotoBrowser_ShowUserIcon1000:_pIconID];
//        return;
//    }
//    
//    [self selectIconFunc:_pIconID||self.iconPathArray];
// }

#pragma mark -ACChangeIconVC_Base

-(void)onSaveFunc{
    
    NSDictionary* dictFile = nil;
    if (3==self.iconPathArray.count){
        dictFile = @{@"icon_1000_1000":self.iconPathArray[0],
                     @"icon_200_200":self.iconPathArray[1],
                     @"icon_100_100":self.iconPathArray[2]};
    }
    else if(_bIconDeleted){
        [_pUserProfileNew setValue:@"" forKey:InputView_FieldName_Icon];
    }
    
    if(_pUserProfileNew.count||dictFile){
        [self uploadIconInfo:@{@"user":_pUserProfileNew}
                iconFileInfo:dictFile
                     withURL:[NSString stringWithFormat:@"%@/rest/apis/user",[[ACNetCenter shareNetCenter] acucomServer]]
                     forPost:NO];
    }
}


-(BOOL)isNeedSave{
    //取得变化
    /*
     URI: rest/apis/user
     Method: PUT
     Request:
     
     Json path "name" is string
     Json path "description" is string
     Json path "gender" is integer, 2 is female, 1 is male
     Json path "icon" is string.
     Json path "jobTitle" is string, job title.
     Json path "department" is string, department.
     Json path "email" is string, email.
     Json path "phone" is string, phone number.
     Json path "address" is string, address.
     
     Response:
     
     Json path "code" is operation result, 1 means okay.
     Json path "time" is update time.
     
     */
    
    
    _pUserProfileNew = [[NSMutableDictionary alloc] init];
    
    //修改了Icon
    BOOL bNeedSaved = _bIconDeleted||self.iconPathArray.count;
    
    //设置信息
    for(UIView* pView in _sorted_item_inputViews){
        NSInteger nTag  =   pView.tag-1;
        NSString* pText =   nil;
        NSString* pKey  =   [self _getFieldNameFromViewTag:nTag];
        if(TitleLable_Tag_comment==nTag||TitleLable_Tag_address==nTag){
            pText = ((UITextView*)pView).text;
        }
        else{
            pText = ((UITextField*)pView).text;
        }
        
        [_pUserProfileNew setValue:pText  forKey:pKey];
        NSString* pOldText = [_pUserProfileOld objectForKey:pKey];
        if((pOldText.length||pText.length)&& //数据有效
           (![pText isEqualToString:pOldText])){ //文本变化
            bNeedSaved = YES;
        }
     }

    return bNeedSaved;
 }

-(void)onSelectedImage:(UIImage*)originalImage{
    
     UIImage *icon100Image = [originalImage imageScaledInterceptToSize:CGSizeMake(100, 100)];
     NSString *icon100ImagePath = [ACAddress getAddressWithFileName:kIcon_100_100 fileType:ACFile_Type_ImageFile isTemp:YES subDirName:nil];
     [UIImageJPEGRepresentation(icon100Image, 0.75) writeToFile:icon100ImagePath atomically:YES];
     
     UIImage *icon200Image = [originalImage imageScaledInterceptToSize:CGSizeMake(200, 200)];
     NSString *icon200ImagePath = [ACAddress getAddressWithFileName:kIcon_200_200 fileType:ACFile_Type_ImageFile isTemp:YES subDirName:nil];
     [UIImageJPEGRepresentation(icon200Image, 0.75) writeToFile:icon200ImagePath atomically:YES];

    UIImage *icon1000Image = [originalImage imageScaledInterceptToSize:CGSizeMake(1000, 1000)];
    NSString *icon1000ImagePath = [ACAddress getAddressWithFileName:kIcon_1000_1000 fileType:ACFile_Type_ImageFile isTemp:YES subDirName:nil];
    [UIImageJPEGRepresentation(icon1000Image, 0.75) writeToFile:icon1000ImagePath atomically:YES];
    
     self.iconPathArray = [NSArray arrayWithObjects:icon1000ImagePath,icon200ImagePath,icon100ImagePath, nil];
     dispatch_async(dispatch_get_main_queue(), ^{
         _icon_ImageView.image = icon100Image;
     });
}


-(void)onUploadIconSuccess:(NSDictionary*)responseDic{
    
    ITLog(@"修改个人信息及头像成功");
    //有内容说明保存过头像,移动临时icon到永久路径
    NSArray* pIcon_Names = @[kIcon_1000_1000,kIcon_200_200,kIcon_100_100];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    //成功后保存
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    
    if (self.iconPathArray)
    {
        _pIconID = [@"/rest/apis/user/icon/user/" stringByAppendingFormat:@"%@?t=%@",
                [responseDic objectForKey:@"rid"],
                [responseDic objectForKey:@"time"]];
        
        //moveTmpIconToForever 保存临时图像到永久
        int nIcon_Names_No = 0;
        for(NSString* pIconFilePathName in self.iconPathArray){
            NSString *iconDestImagePath = [ACAddress getAddressWithFileName:pIcon_Names[nIcon_Names_No] fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
            [fileManager removeItemAtPath:iconDestImagePath error:nil];
            [fileManager moveItemAtPath:pIconFilePathName toPath:iconDestImagePath error:nil];
            nIcon_Names_No ++;
        }
        
        self.iconPathArray = nil;
        
    }
    else if(_bIconDeleted){
        //删除旧的Icon
        for(NSString* icon_name in pIcon_Names){
            [fileManager removeItemAtPath:[ACAddress getAddressWithFileName:icon_name fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil] error:nil];
        }
        //删除Icon
        
        _pIconID = nil;
    }
    
    if(_pIconID.length){
        [defaults setObject:_pIconID forKey:kIcon];
        ITLogEX(@"Icon 2=%@",_pIconID);
        [_pUserProfileNew setValue:_pIconID forKey:InputView_FieldName_Icon];
    }
    else{
        _pIconID = nil;
        [defaults removeObjectForKey:kIcon];
        [_pUserProfileNew removeObjectForKey:InputView_FieldName_Icon];
    }
    
    //保存成功后,保存旧的,避免cancalBack
    _pUserProfileOld    =   _pUserProfileNew;
    _bIconDeleted       =   NO;
    
    NSString* pName = responseDic[@"name"];
    if(pName){
        [defaults setObject:pName forKey:kName];
        [_pUserProfileNew setObject:pName forKey:kName];
    }
    
    [defaults setObject:[_pUserProfileNew objectForKey:InputView_FieldName_comment] forKey:kDescription];
    [defaults setObject:_pUserProfileNew forKey:kUserProfileInfo];
    
    [defaults synchronize];
    
    [ACUtility postNotificationName:kPersonInfoPutSuccessNotifation object:nil];
 }

-(void)onCallDelOrPreViewFunc:(BOOL)bCallDel{
    //删除当前
    if(bCallDel){
        if(self.iconPathArray.count){
            self.iconPathArray = nil;
            [self _setIconImage];
            return;
        }
        
        if(_pIconID){
            _bIconDeleted = YES;
            _pIconID = nil;
            [self _setIconImage];
        }
        return;
    }
    
    if(self.iconPathArray.count){
        [self  MWPhotoBrowser_ShowPhotoFile:self.iconPathArray[0] withURL:nil];
        return;
    }
    
    if(_pIconID.length){
        [self MWPhotoBrowser_ShowUserIcon1000:_pIconID];
        return;
    }
}

#pragma mark -actionSheetDelegate
/*
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if(kSelectIconActionSheetTag==actionSheet.tag&&
       buttonIndex == actionSheet.firstOtherButtonIndex+2){

        //删除当前
        if(self.iconPathArray){
            self.iconPathArray = nil;
            [self _setIconImage];
            return;
        }
        
        if(_pIconID){
             _bIconDeleted = YES;
            _pIconID = nil;
            [self _setIconImage];
            return;
        }
        
        return;
    }
    [super actionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
 }*/

@end
