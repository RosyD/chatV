//
//  ACParticipantInfoViewController.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-22.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACParticipantInfoViewController.h"
#import "ACUserDB.h"
#import "UIImageView+WebCache.h"
#import "UINavigationController+Additions.h"
#import "ACNetCenter.h"
#import "ACEntity.h"
#import "ACChatMessageViewController.h"
#import "NSDate+Additions.h"


@interface ACParticipantInfoViewController (){
    UIView*     _pMoreProfileBkView;
    BOOL        _bMoreProfileShowed;
    CGFloat     _fSendMessageButtonShowY;
}

@end

@implementation ACParticipantInfoViewController

AC_MEM_Dealloc_implementation


- (instancetype)initWithUserID:(NSString *)userID
{
    self = [super init];
    if (self) {
        self.user = [ACUserDB getUserFromDBWithUserID:userID];
    }
    return self;
}

- (instancetype)initWithUser:(ACUser *)user{
    self = [super init];
    if (self) {
        self.user = user;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)_setIconNameViewShowInfo{
    if(_bMoreProfileShowed){
        [_iconNameButton setBackgroundImage:[[UIImage imageNamed:@"it_contact_detail_up.png"] stretchableImageWithLeftCapWidth:150 topCapHeight:24] forState:UIControlStateNormal];
//        [_iconNameButton setBackgroundImage:[[UIImage imageNamed:@"it_contact_detail_up_pressed.png"] stretchableImageWithLeftCapWidth:150 topCapHeight:24] forState:UIControlStateHighlighted];
        
        _moreProfileImageView.image = [UIImage imageNamed:@"User_profile_more_flag_up"];
    }
    else{
        [_iconNameButton setBackgroundImage:[[UIImage imageNamed:@"it_contact_detail_item.png"] stretchableImageWithLeftCapWidth:150 topCapHeight:24] forState:UIControlStateNormal];
//        [_iconNameButton setBackgroundImage:[[UIImage imageNamed:@"it_contact_detail_item_pressed.png"] stretchableImageWithLeftCapWidth:150 topCapHeight:24] forState:UIControlStateHighlighted];
        _moreProfileImageView.image = [UIImage imageNamed:@"User_profile_more_flag_down"];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (![ACConfigs isPhone5])
    {
        [_contentView setFrame_height:_contentView.size.height-88];
    }

    
    [_iconImageView setImageWithIconString:_user.icon
                          placeholderImage:[UIImage imageNamed:@"personIcon100.png"]
                                 ImageType:ImageType_UserIcon100];
    
    [_iconImageView setToCircle];
//    [_iconImageView.layer setCornerRadius:5.0];
//    [_iconImageView.layer setMasksToBounds:YES];
    
    if(_user.icon.length){
        _iconImageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(uesrIconClicked)];
        [_iconImageView addGestureRecognizer:singleTap];
    }
    
    _nameLabel.text = _user.name;
    [_nameLabel setAutoresizeWithLimitWidth:_nameLabel.size.width];
    
    [_accountLabel setFrame_y:[_nameLabel getFrame_Bottom]+5];
    _accountLabel.text = [NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"Account", nil),_user.account];
    
    
    _titleLable.text    =   NSLocalizedString(@"Personal Info",nil);
    [_sendMessageButton setNomalText:NSLocalizedString(@"Begin Message",nil)];
    
    float height = [_accountLabel getFrame_Bottom]+10;
    if (height > _iconNameView.size.height)
    {
        [_iconNameButton setFrame_height:[_accountLabel getFrame_Bottom]+10];
        [_iconNameView setFrame_height:_iconNameButton.size.height];
    }
    
//    [_backButton setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateNormal];
    
    if ([ACUser isMySelf:_user.userid]||
         (_topicEntity&&(_topicEntity.topicPerm.chatInChat == ACTopicPermission_ChatInChat_Deny ||
         [_topicEntity.mpType isEqualToString:cSingleChat])))
    {
        [_sendMessageButton setHidden:YES];
    }
    
    [self _setIconNameViewShowInfo];
    _fSendMessageButtonShowY =  _sendMessageButton.frame.origin.y;

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createGroupChatSuccess:) name:kNetCenterCreateGroupChatNotifation object:nil];
    
    
    /*
    [_descButton setBackgroundImage:[[UIImage imageNamed:@"it_contact_detail_down.png"] stretchableImageWithLeftCapWidth:150 topCapHeight:24] forState:UIControlStateNormal];
    [_descButton setBackgroundImage:[[UIImage imageNamed:@"it_contact_detail_down_pressed.png"] stretchableImageWithLeftCapWidth:150 topCapHeight:24] forState:UIControlStateHighlighted];
    
    [_descView setFrame_y:[_iconNameView getFrame_Bottom]];
    if ([_user.desp length] > 0)
    {
        _descLabel.text = _user.desp;
    }
    else
    {
        _descLabel.text = @"";
    }
    
    [_descLabel setAutoresizeWithLimitWidth:_descLabel.size.width];
    
    if (_descLabel.size.height > 160)
    {
        [_descLabel setFrame_height:160];
    }
    
//    height = [_descLabel getFrame_Bottom]+10;
//    if (height > _descView.size.height)
    {
        [_descButton setFrame_height:[_descLabel getFrame_Bottom]+10];
        [_descView setFrame_height:_descButton.size.height];
    }
//    else
//    {
//        [_descButton setFrame_height:[_descLabel getFrame_Bottom]+20];
//        [_descView setFrame_height:_descButton.size.height];
//    }
    
    [_sendMessageButton setFrame_y:[_descView getFrame_Bottom]+20];
    */
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
    
    if(nil==_user){
        _moreProfileImageView.hidden = YES;
        _sendMessageButton.hidden = YES;
        _iconNameButton.userInteractionEnabled = NO;
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

#pragma mark -Notification
-(void)createGroupChatSuccess:(NSNotification *)noti
{
    if ([ACNetCenter shareNetCenter].createTopicEntityVC == self){

        ACChatMessageViewController *chatMessageVC = [[ACChatMessageViewController alloc] initWithSuperVC:self withTopicEntity: noti.object];
//        ACTopicEntity *topicEntity = noti.object;
//        chatMessageVC.topicEntity = topicEntity;
//        [chatMessageVC preloadDB];
        AC_MEM_Alloc(chatMessageVC);
        [self.navigationController pushViewController:chatMessageVC animated:YES];
    }
}

#pragma mark -IBAction
-(IBAction)sendMessageButtonTouchUp:(id)sender
{
    [ACNetCenter shareNetCenter].createTopicEntityVC = self;
    [[ACNetCenter shareNetCenter] createTopicEntityWithChatType:cSingleChat
                                                      withTitle:nil
                                               withGroupIDArray:nil
                                                withUserIDArray:[NSArray arrayWithObject:_user.userid]
                                                          exMap:nil];
    [_contentView showNetLoadingWithAnimated:YES];
}

-(void)uesrIconClicked{
    [self MWPhotoBrowser_ShowUserIcon1000:_user.icon];
}

-(IBAction)goback:(id)sender
{
    [self.navigationController ACpopViewControllerAnimated:YES];
}


//取得用户信息的标题
+(NSString*)userProfileTitleWithItem:(NSString*)pItemName{
    
    NSString*   pLabelNameStringName =  [NSString stringWithFormat:@"user_profile_%@",pItemName];
    NSString*   pRet = NSLocalizedString(pLabelNameStringName,nil);
    
    if([pItemName isEqual:@"company"]){
        //对company的名称特殊处理
        NSString* pAboutString = NSLocalizedStringFromTable(pLabelNameStringName,@"about",nil);
        if(![pAboutString isEqual:pLabelNameStringName]){
            pRet =   pAboutString;
        }
    }
    return pRet;
}


+(void)loadUser:(NSString*)pUsrID ProfileFromView:(UIViewController*)pVC withBlock:(void (^)(NSDictionary* pUserProInfo)) pFunc{ //加载用户信息
    //需要创建
    [pVC.view showNetLoadingWithAnimated:YES];
    [ACNetCenter callURL:[NSString stringWithFormat:@"%@/rest/apis/user/%@",[[ACNetCenter shareNetCenter] acucomServer],pUsrID]
         forMethodDelete:NO
               withBlock:^(ASIHTTPRequest *request, BOOL bIsFail) {
                   NSString *errInfo =  nil;
                   if(!bIsFail){
                       NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
                       ITLog(responseDic);
                       if(ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]){
                           NSDictionary* pUserInfo =    [responseDic objectForKey:@"user"];
                           if(pUserInfo){
                               [pVC.view hideProgressHUDWithAnimated:YES];
                               pFunc(pUserInfo);
                               return;
                           }
                       }
                       errInfo = [responseDic objectForKey:kDescription];
                   }
                   
                   if(errInfo.length==0){
                       errInfo =    NSLocalizedString(@"Network_Failed", nil);
                   }
                   [pVC.view showProgressHUDNoActivityWithLabelText:errInfo
                                                 withAfterDelayHide:0.8];
                   pFunc(nil);
               }];

}


-(CGFloat)_createMoreProfile_Item:(NSString*)pItemName withY:(CGFloat)fShowInfoY fromDict:(NSDictionary*)pDictUser{
    
    NSString* pProfileItem =  nil;
    if([pItemName isEqual:@"lastLogin"]){
        long long lLastLogin = [[pDictUser objectForKey:pItemName] longLongValue];
        if(lLastLogin>0){
            NSDate* pLastLoginDate = [NSDate dateWithTimeIntervalSince1970:lLastLogin/1000];
            pProfileItem = [NSDateFormatter localizedStringFromDate:pLastLoginDate dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterMediumStyle];
        }
        else{
            pProfileItem = @"";
        }
        
//       pProfileItem =  [NSDate dateAndTimeStringForRecentDate:[NSDate dateWithTimeIntervalSince1970:[[pDictUser objectForKey:pItemName] longLongValue] /1000]];
    }
    else{
        pProfileItem    =   [pDictUser objectForKey:pItemName];
    }
    
    if(pProfileItem){
        UILabel* pLabelName =   [[UILabel alloc] initWithFrame:CGRectMake(User_MoreProfile_Name_X, fShowInfoY, User_MoreProfile_Name_Width, 20)];
        pLabelName.text =   [ACParticipantInfoViewController userProfileTitleWithItem:pItemName];
        pLabelName.font = [UIFont systemFontOfSize:11];
        pLabelName.textColor = [UIColor grayColor];
        [_pMoreProfileBkView addSubview:pLabelName];
        
        CGFloat fWith = _pMoreProfileBkView.frame.size.width-User_MoreProfile_Item_X-User_MoreProfile_Name_X;
        UILabel* pLableItem =   [[UILabel alloc] initWithFrame:CGRectMake(User_MoreProfile_Item_X, fShowInfoY, fWith,20)];
        pLableItem.numberOfLines = 0;
        pLableItem.text     =   pProfileItem;
        pLableItem.font = [UIFont systemFontOfSize:16];
        [pLableItem setAutoresizeWithLimitWidth:fWith];
        [_pMoreProfileBkView addSubview:pLableItem];
                                          
        fShowInfoY  +=  pLableItem.frame.size.height+User_MoreProfile_Y_Delta;
    }
    
    return fShowInfoY;
}

-(void)_createMoreProfileBkViewAndShowWithDict:(NSDictionary*)pDictUser{
    if(nil==pDictUser){
        return;
    }
/*
 "user" : {
     "id" : "5458852c3004d589430c3b9a",
     "description" : "yes very well",
     "jobTitle" : "software tester.",
     "phone" : "+66827933",
     "email" : "john.chen@aculearn.com;john.chen_yeo@aculearn.com.cn",
     "lastLogin" : 1426746324600,
     "domain" : "john",
     "company" : "john",
     "address" : "haidian district zhichun road building 1510",
     "icon" : "\/rest\/apis\/user\/icon\/user\/5458852c3004d589430c3b9a?t=1425984273134",
     "account" : "john",
     "department" : "test department",
     "name" : "john's ",
     "updateTime" : 1426820072333
 },
 
 */
    //创建View
    CGRect iconNameFram = _iconNameView.frame;
    _pMoreProfileBkView = [[UIView alloc] initWithFrame:CGRectMake(iconNameFram.origin.x, (iconNameFram.origin.y+iconNameFram.size.height), iconNameFram.size.width, 500)];
    
    UIButton* pBkButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, iconNameFram.size.width, _pMoreProfileBkView.frame.size.height)];
    pBkButton.userInteractionEnabled = NO;
    [pBkButton setBackgroundImage:[[UIImage imageNamed:@"it_contact_detail_down"] stretchableImageWithLeftCapWidth:150 topCapHeight:24] forState:UIControlStateNormal];
    [_pMoreProfileBkView addSubview:pBkButton];
    
//    user.company
    CGFloat fShowInfoY = [self _createMoreProfile_Item:@"company" withY:User_MoreProfile_Y_Delta fromDict:pDictUser];
    
//    user.gender,暂不显示
//    fShowInfoY = [self _createMoreProfile_Item:@"gender" withY:fShowInfoY fromDict:pDictUser];
    
//    user.jobTitle
    fShowInfoY = [self _createMoreProfile_Item:@"jobTitle" withY:fShowInfoY fromDict:pDictUser];
    
//    user.department
    fShowInfoY = [self _createMoreProfile_Item:@"department" withY:fShowInfoY fromDict:pDictUser];
    
//    user.phone
    fShowInfoY = [self _createMoreProfile_Item:@"phone" withY:fShowInfoY fromDict:pDictUser];
    
//    user.email
    fShowInfoY = [self _createMoreProfile_Item:@"email" withY:fShowInfoY fromDict:pDictUser];
    
//    user.address
    fShowInfoY = [self _createMoreProfile_Item:@"address" withY:fShowInfoY fromDict:pDictUser];
    
//    user.lastLogin
    fShowInfoY = [self _createMoreProfile_Item:@"lastLogin" withY:fShowInfoY fromDict:pDictUser];
    
//    user.description
    fShowInfoY  =   [self _createMoreProfile_Item:@"description" withY:fShowInfoY fromDict:pDictUser];

    fShowInfoY += 10;
    [pBkButton setFrame_height:fShowInfoY];
    [_pMoreProfileBkView setFrame_height:fShowInfoY];
    
    [self onShowOrHideMoreProfileInfo:nil];
}

- (IBAction)onShowOrHideMoreProfileInfo:(id)sender {
    
    if(nil==_pMoreProfileBkView){
        //需要创建
        [ACParticipantInfoViewController loadUser:_user.userid ProfileFromView:self withBlock:^void(NSDictionary *pUserProInfo) {
            [self _createMoreProfileBkViewAndShowWithDict:pUserProInfo];
        }];
        
        return;
    }
    
    
    CGFloat sendMessageButtonShowY =    _fSendMessageButtonShowY;
    _bMoreProfileShowed  =! _bMoreProfileShowed;
    
    if(_bMoreProfileShowed){
        [_contentView addSubview:_pMoreProfileBkView];
        sendMessageButtonShowY  =   _pMoreProfileBkView.frame.origin.y+_pMoreProfileBkView.frame.size.height+10;
    }
    else{
        [_pMoreProfileBkView removeFromSuperview];
    }
    
    [self _setIconNameViewShowInfo];
    
    if(!_sendMessageButton.isHidden){
 //       [_sendMessageButton setFrame_y:sendMessageButtonShowY];
        ///sendMessageButton
        [_sendMessageButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.offset(sendMessageButtonShowY);
            make.height.offset(48);
            make.right.left.equalTo(_iconNameView);
        }];

        sendMessageButtonShowY  =   _sendMessageButton.origin.y+_sendMessageButton.frame.size.height;
    }
    _contentView.contentSize = CGSizeMake(_contentView.frame.size.width, sendMessageButtonShowY+20);
    [_contentView flashScrollIndicators];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
