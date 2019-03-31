//
//  ACSetViewController.m
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-28.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACSetViewController.h"
#import "ACConfigs.h"
#import "ACAboutViewController.h"
#import "ACNetCenter.h"
#import "ACAcuLearnWebViewController.h"
#import "UIViewController+MMDrawerController.h"
#import "UIView+Additions.h"
#import "ACRootTableViewCell.h"
#import "ACLocationSettingViewController.h"
#import "ACAddress.h"
#import "JSONKit.h"
#import "UINavigationController+Additions.h"
#import "ACSimpleSelectViewController.h"
#import "GZIP.h"
#import "ACSetNotifyViewController.h"


#define kLogoutTag  32423

@interface ACSetViewController (){
    NSArray*    _pFontNames; //字体名信息
    NSInteger   _nFontNo;
    
    __weak IBOutlet UILabel *_notifyLable;
    __weak IBOutlet UILabel *_locationSettingsLable;
}
@property (weak, nonatomic) IBOutlet UIButton *LogButtonShow;
@property (weak, nonatomic) IBOutlet UIButton *LogButtonClear;
@property (weak, nonatomic) IBOutlet UIButton *LogButtonMail;


@property (weak, nonatomic) IBOutlet UILabel *lableForFontTitle;
@property (weak, nonatomic) IBOutlet UILabel *lableForFont;



@end

@implementation ACSetViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)dealloc
{
    AC_MEM_Dealloc();
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    self.mm_drawerController.p
//TXB    [self.viewDeckController setPanningMode:IIViewDeckFullViewPanning];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//TXB    [self.viewDeckController setPanningMode:IIViewDeckNoPanning];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //@"Samll",@"Medium",@"Large"
    _pFontNames = @[NSLocalizedString(@"FontSize_Small", nil),
                    NSLocalizedString(@"FontSize_Medium", nil),
                    NSLocalizedString(@"FontSize_Large", nil)];
    
    // Do any additional setup after loading the view from its nib.
    /*
    NSNumber *soundOn = [[NSUserDefaults standardUserDefaults] objectForKey:kSoundOn];
    if (!soundOn)
    {
        soundOn = [NSNumber numberWithBool:YES];
        [[NSUserDefaults standardUserDefaults] setObject:soundOn forKey:kSoundOn];
    }
    _soundSwitch.on = soundOn.boolValue;
    
    NSNumber *vibarteOn = [[NSUserDefaults standardUserDefaults] objectForKey:kVibarteOn];
    if (!vibarteOn)
    {
        vibarteOn = [NSNumber numberWithBool:YES];
        [[NSUserDefaults standardUserDefaults] setObject:vibarteOn forKey:kVibarteOn];
    }
    _vibarteSwitch.on = vibarteOn.boolValue;
     */
    
    //Font
    _nFontNo    =  [ACConfigs shareConfigs].chatTextFontSizeNo;
    _lableForFontTitle.text  = NSLocalizedString(@"FontSize_Title", nil);
    _lableForFont.text  =   _pFontNames[_nFontNo];
    
//    [_backButton setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateNormal];

//    _vibarteLabel.text = NSLocalized String(@"Vibrate", nil);
//    _soundLabel.text = NSLocalized String(@"Sound", nil);
    _feedbackLabel.text = NSLocalizedString(@"Feedback", nil);
    _aboutLabel.text = NSLocalizedString(@"About", nil);
    [_logoutButton setTitle:NSLocalizedString(@"Logout", nil) forState:UIControlStateNormal];
    _titleLabel.text = kSetting;
    _notifyLable.text = NSLocalizedString(@"Notification", nil);
    _locationSettingsLable.text = NSLocalizedString(@"Location Settings", nil);

    
    _mainScrollView.contentSize = CGSizeMake(0, _mainScrollView.frame.size.height+10);
    
    if (![ACConfigs isPhone5])
    {
        [_contentView setFrame_height:_contentView.size.height-88];
    }
    
    /*
    NSString *fileName = kSyncDataJsonName;
    NSString *syncJsonPath = [ACAddress getAddressWithFileName:fileName fileType:ACFile_Type_SyncData isTemp:NO subDirName:nil];
    if ([[NSFileManager defaultManager] fileExistsAtPath:syncJsonPath])
    {
        NSData *data = [NSData dataWithContentsOfFile:syncJsonPath];
        NSDictionary *dic = [data objectFromJSONData];
        NSDictionary *perm = [dic objectForKey:kPerm];
        NSNumber *defla = [perm objectForKey:kDefla];
//        if ([defla intValue] == locationAlertUserDefine_deny)
//        {
//            [_locationSettingView setHidden:YES];
//            [_aboutButton setBackgroundImage:[UIImage imageNamed:@"it_contact_detail_down.png"] forState:UIControlStateNormal];
//            [_aboutButton setBackgroundImage:[UIImage imageNamed:@"it_contact_detail_down_pressed.png"] forState:UIControlStateHighlighted];
//            [_logoutButton setFrame_y:_logoutButton.origin.y-_locationSettingView.size.height+10];
//        }
    }*/
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logoutSuccessNotification:) name:kNetCenterLogoutNotifation object:nil];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
    
#if defined(ACUtility_Log_UseStringBuffers)||defined(ACUtility_Log_UseFile)
    _LogButtonShow.hidden = NO;
    _LogButtonClear.hidden = NO;
#endif
    
#ifdef ACUtility_Log_UseFile
    _LogButtonMail.hidden = NO;
#endif
}

#pragma mark -Notification
-(void)logoutSuccessNotification:(NSNotification *)noti
{
    [_contentView hideProgressHUDWithAnimated:NO];
    [[ACConfigs shareConfigs] presentLoginVC:YES];
}

-(void)hotspotStateChange:(NSNotification *)noti
{
    if (_isOpenHotspot)
    {
        [_contentView setFrame_height:_contentView.size.height-hotsoptHeight];
    }
    else
    {
        [_contentView setFrame_height:_contentView.size.height+hotsoptHeight];
    }
}

#pragma mark -IBAction
-(IBAction)catalogButtonTouchUp:(id)sender
{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
//    [self.viewDeckController toggleLeftView];
}

/*
-(IBAction)vibarteButtonTouchUp:(id)sender
{
#ifdef kRootViewControllerShowing
    
    if ([ACConfigs shareConfigs].rootViewControllerShowing)
    {
        [self catalogButtonTouchUp:nil];
        return;
    }
#endif
    
    [_vibarteSwitch setOn:!_vibarteSwitch.on animated:YES];
}

-(IBAction)vibarteSwitchValueChange:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:_vibarteSwitch.on forKey:kVibarteOn];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(IBAction)soundButtonTouchUp:(id)sender
{
#ifdef kRootViewControllerShowing
    if ([ACConfigs shareConfigs].rootViewControllerShowing)
    {
        [self catalogButtonTouchUp:nil];
        return;
    }
#endif
    [_soundSwitch setOn:!_soundSwitch.on animated:YES];
}

-(IBAction)soundSwitchValueChange:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:_soundSwitch.on forKey:kSoundOn];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
 */

-(IBAction)notificationButtonTouchUp:(id)sender{
#ifdef kRootViewControllerShowing
    if ([ACConfigs shareConfigs].rootViewControllerShowing)
    {
        [self catalogButtonTouchUp:nil];
        return;
    }
#endif
    ACSetNotifyViewController *setNotifyVC = [[ACSetNotifyViewController alloc] init];
    AC_MEM_Alloc(setNotifyVC);
    [setNotifyVC setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:setNotifyVC animated:YES];

}


- (IBAction)onSetFont:(id)sender {
    
    [ACSimpleSelectViewController showSelects:_pFontNames
                                withDefaultNo:_nFontNo
                                 fromParentVC:self
                                    withTitle:_lableForFontTitle.text
                                withExitBlock:^(NSArray *selectedNos, NSInteger nSelectedNo) {
                                    if(nSelectedNo!=_nFontNo){
                                        _nFontNo =  nSelectedNo;
                                        [ACConfigs shareConfigs].chatTextFontSizeNo = nSelectedNo;
                                        _lableForFont.text  =   _pFontNames[_nFontNo];
                                    }
                                }];
}


-(IBAction)feedbackButtonTouchUp:(id)sender
{
#ifdef kRootViewControllerShowing
    if ([ACConfigs shareConfigs].rootViewControllerShowing)
    {
        [self catalogButtonTouchUp:nil];
        return;
    }
#endif
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
        mailVC.mailComposeDelegate = self;        
        [mailVC setSubject:[ACUtility getOEMStringFromAbout:@"Feedback"]];
        [mailVC setToRecipients:@[[[ACConfigs acOem_ConfigInfo] objectForKey:@"FeedbackToRecipient"]]];
        [mailVC setMessageBody:NSLocalizedString(@"Suggestions:", nil) isHTML:NO];
        [self ACpresentViewController:mailVC animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"Can\'t send mail", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        [alert show];
    }
}

-(IBAction)aboutButtonTouchUp:(id)sender
{
#ifdef kRootViewControllerShowing
    if ([ACConfigs shareConfigs].rootViewControllerShowing)
    {
        [self catalogButtonTouchUp:nil];
        return;
    }
#endif
    ACAboutViewController *aboutVC = [[ACAboutViewController alloc] init];
    AC_MEM_Alloc(aboutVC);
    [aboutVC setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:aboutVC animated:YES];
}

-(IBAction)locationSettingButtonTouchUp:(id)sender
{
#ifdef kRootViewControllerShowing
    if ([ACConfigs shareConfigs].rootViewControllerShowing)
    {
        [self catalogButtonTouchUp:nil];
        return;
    }
#endif
    ACLocationSettingViewController *locSettingVC = [[ACLocationSettingViewController alloc] init];
    AC_MEM_Alloc(locSettingVC);
    [self.navigationController pushViewController:locSettingVC animated:YES];
}
- (IBAction)logOut:(id)sender {

#ifdef kRootViewControllerShowing
    if ([ACConfigs shareConfigs].rootViewControllerShowing)
    {
        [self catalogButtonTouchUp:nil];
        return;
    }
#endif
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"Do you want to logout?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    alert.tag = kLogoutTag;
    [alert show];
    
}

#pragma mark -alert
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kLogoutTag)
    {
        if (buttonIndex == alertView.firstOtherButtonIndex)
        {
            [_contentView showProgressHUD];
            [[ACNetCenter shareNetCenter] logOut:YES withBlock:^(ASIHTTPRequest *request, BOOL bIsFail) {
                if(bIsFail){
                    [_contentView showNetErrorHUD];
                    return;
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self logoutSuccessNotification:nil];
                });
            }];
        }
    }
}

#pragma mark -mailComposeDelegate
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    NSString *msg = nil;
    switch (result)
    {
        case MFMailComposeResultCancelled:
//            msg = NSLocalized String(@"Mail cancelled", nil);
            break;
        case MFMailComposeResultSaved:
//            msg = NSLocalized String(@"Mail saved", nil);
            break;
        case MFMailComposeResultSent:
            msg = NSLocalizedString(@"Thank you for your feedback", nil);
            break;
        case MFMailComposeResultFailed:
            msg = NSLocalizedString(@"Mail failed", nil);
            break;
        default:
            msg = @"";
            break;
    }
    if ([msg length] != 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:msg delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        [alert show];
    }
    [self ACdismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)onLogButtonShow:(id)sender {
#if defined(ACUtility_Log_UseStringBuffers)||defined(ACUtility_Log_UseFile)
    [ACUtility MemDebug_Check:NO];
    ACAcuLearnWebViewController *acuLearnWebVC = [[ACAcuLearnWebViewController alloc] initWithUrlString:nil];
    AC_MEM_Alloc(acuLearnWebVC);
    [self.navigationController pushViewController:acuLearnWebVC animated:YES];
#endif
}
- (IBAction)onLogButtonClear:(id)sender {
#ifdef ACUtility_Log_UseStringBuffers
    ITLogUserStringBuffers_Clear();
#else
    [ACUtility LogFile_Load:YES];
//    [ACUtility ShowTip:[ACUtility MemDebug_AllocInfo] withTitle:nil];
#endif
}
- (IBAction)onLogButtonMail:(id)sender {
#ifdef ACUtility_Log_UseFile
    if ([MFMailComposeViewController canSendMail])
    {
        [ACUtility MemDebug_Check:NO];
        
        MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
        mailVC.mailComposeDelegate = self;
        [mailVC setSubject:@"debug log"];
        [mailVC setToRecipients:@[@"xiaobing@aculearn.com.cn"]];
        [mailVC setMessageBody:[NSString stringWithFormat:@"debug log at %@\n%@\n版本:%@",[ACUtility nowLocalDate],[ACConfigs appVersionWithBuild:YES],[ACConfigs appBuildDate]] isHTML:NO];
        NSData* pLogData = [ACUtility LogFile_Load:YES];
        if(pLogData){
             [mailVC addAttachmentData: [pLogData gzippedData] mimeType: @"" fileName: @"AcuCom_log.z"];
        }
        NSData* pSqlite = [NSData dataWithContentsOfFile:[ACAddress getAddressWithFileName:@"AcuCom.db" fileType:ACFile_Type_Database isTemp:NO subDirName:nil]];
        if(pSqlite){
            [mailVC addAttachmentData: [pSqlite gzippedData] mimeType: @"" fileName: @"AcuCom_db.z"];
        }
        
        [self ACpresentViewController:mailVC animated:YES completion:nil];
    }
    else
    {
        AC_ShowTipFunc(nil, NSLocalizedString(@"Can\'t send mail", nil));
    }
#endif
}


@end
