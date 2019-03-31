//
//  ACAboutViewController.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-25.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACAboutViewController.h"
#import "UINavigationController+Additions.h"
#import "ACAcuLearnWebViewController.h"
#import "ACConfigs.h"
#import "ACNetCenter.h"

@interface ACAboutViewController (){
    BOOL    _bShowVerWithBuild;
}

@end

@implementation ACAboutViewController

AC_MEM_Dealloc_implementation


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
//    [_backButton setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateNormal];
    _websiteLabel.text = NSLocalizedString(@"Website:", @"ACAboutViewController");
    _poweredByLabel.text = NSLocalizedStringFromTable(@"About_Powered_By_AcuLearn",@"about",nil);
    _urlLabel.text  = [[ACConfigs acOem_ConfigInfo] objectForKey:@"About_Website_link"];
    
    _titleLable.text = NSLocalizedString(@"About", @"ACAboutViewController");
    
#if 0//def ACUtility_Need_Log
//    [_buttonForCheckUpdate setTitle:[NSString stringWithFormat:@"编译时间:%@",[ACConfigs appBuildDate]] forState:UIControlStateNormal];
    [_buttonForCheckUpdate setTitle:[ACConfigs appBuildDate] forState:UIControlStateNormal];
#else
    [_buttonForCheckUpdate setTitle:NSLocalizedString(@"Check For Updates", @"ACAboutViewController") forState:UIControlStateNormal];
#endif
    
    [_iconImageView.layer setCornerRadius:5.0];
    [_iconImageView.layer setMasksToBounds:YES];
    [_iconBgView.layer setCornerRadius:5.0];
    [_iconBgView.layer setMasksToBounds:YES];
    
    _iconImageView.image = [UIImage imageNamed:@"icon_about.png"];
//    [_iconImageView setImage:[UIImage imageNamed:@"icon.png"]];
    [self setVersionLable];
    _iconImageView.userInteractionEnabled = YES;
    [_iconImageView  addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(setVersionLable)]];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
    
    if([ACConfigs acOem_ConfigInfo][@"PolicyURL"]){
        [_policyButton setTitle:NSLocalizedString(@"Terms & Condition and Privacy Policy", nil) forState:UIControlStateNormal];
    }
    else{
       
        /// [_poweredBkView setFrame_y:_policyBkView.frame.origin.y];
        [_poweredBkView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_policyBkView.mas_top);
        }];
        _policyBkView.hidden = YES;
    }
    
//
    
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

#pragma mark -IBAction

-(void)setVersionLable{
    _appNameAndVersionLabel.text = [NSString stringWithFormat:@"%@ %@",NSLocalizedStringFromTable(@"About_AcuCom", @"about",nil),[ACConfigs appVersionWithBuild:_bShowVerWithBuild]];
    _bShowVerWithBuild = !_bShowVerWithBuild;
}

-(IBAction)goback:(id)sender
{
    [self.navigationController ACpopViewControllerAnimated:YES];
}

-(IBAction)gotoWebsite:(id)sender
{
    ACAcuLearnWebViewController *acuLearnWebVC = [[ACAcuLearnWebViewController alloc] initWithUrlString:_urlLabel.text];
    [self.navigationController pushViewController:acuLearnWebVC animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #define newAppVersionCheck_Result_Type_Error        -1  //更新失败
 #define newAppVersionCheck_Result_Type_No_Update    0   //不需要更新
 #define newAppVersionCheck_Result_Type_Need_Update  1   //需要跟新
 */
- (IBAction)checkUpdate:(id)sender {
    [self.view showProgressHUDWithLabelText:NSLocalizedString(@"Checking For Updates", @"ACAboutViewController") withAnimated:YES];
    [[ACConfigs shareConfigs] newAppVersionCheckWithBlock:^(ACConfigs *pConfig, int newAppVersionCheck_Result_Type) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
                
            if(newAppVersionCheck_Result_Type_Error==newAppVersionCheck_Result_Type){
                //展示ProgressHUD
                [self.view showProgressHUDNoActivityWithLabelText:NSLocalizedString(@"Check Updates Failed",@"ACAboutViewController") withAfterDelayHide:1];
                return;
            }
                
            if(newAppVersionCheck_Result_Type_Need_Update==newAppVersionCheck_Result_Type){
                [self.view hideProgressHUDWithAnimated:NO];
                [pConfig newAppVersionCheckShowUpdateAlertView];
                return;
            }
            
            //newAppVersionCheck_Result_Type_No_Update
            [self.view showProgressHUDSuccessWithLabelText:NSLocalizedString(@"No Update Available",@"ACAboutViewController") withAfterDelayHide:2];
        });
    }];
}
- (IBAction)onPolicy:(id)sender {
    ACAcuLearnWebViewController *acuLearnWebVC = [[ACAcuLearnWebViewController alloc] initWithUrlString:[ACConfigs acOem_ConfigInfo][@"PolicyURL"]];
    [self.navigationController pushViewController:acuLearnWebVC animated:YES];
}

@end
