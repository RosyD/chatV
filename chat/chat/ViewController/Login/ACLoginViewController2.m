//
//  ACLoginViewController2.m
//  chat
//
//  Created by Aculearn on 15/2/4.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#import "ACLoginViewController2.h"
#import "ACConfigs.h"
#import "ACNetCenter.h"
#import "UIView+Additions.h"
#import "UINavigationController+Additions.h"
#import "ACChangePasswordController.h"
#import "MMDrawerController.h"
#import "AcuComDebugServerDef.h"

#define USE_ForgetPWD_Button

@interface ACLoginViewController2 () <UITextFieldDelegate>{
    NSString* _pAutoLoginPWD_Base64;   //自动登录的Pwd
}
@property (weak, nonatomic) IBOutlet UIView *accountBkView;
@property (weak, nonatomic) IBOutlet UIView *passwordBkView;
//@property (weak, nonatomic) IBOutlet UIView *companyBkView;
@property (weak, nonatomic) IBOutlet UIScrollView *contentView;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;

//@property (weak, nonatomic) IBOutlet UITextField *companyTextField;
@property (weak, nonatomic) IBOutlet UITextField *accountTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@property (weak, nonatomic) IBOutlet UIButton *forgetPWDButton;

@end

@implementation ACLoginViewController2


AC_MEM_Dealloc_implementation


/*
-(void) setViewRoundAndShadow:(UIView*)pView{
    // Rounded corners.
    pView.layer.cornerRadius = pView.size.height/2;
    
    // A thin border.
    pView.layer.borderColor = [UIColor blackColor].CGColor;
    pView.layer.borderWidth = 0.3;
    
    // Drop shadow.
    pView.layer.shadowColor = [UIColor blackColor].CGColor;
    pView.layer.shadowOpacity = 1.0;
    pView.layer.shadowRadius = 7.0;
    pView.layer.shadowOffset = CGSizeMake(4, 0);
}*/


- (void)viewDidLoad {
    [super viewDidLoad];

  /*
   self.contentView.layer.borderWidth  =1;
   self.contentView.layer.cornerRadius = 10;
   self.contentView.layer.borderColor= [[UIColor colorWithRed:0.52 green:0.09 blue:0.07 alpha:1] CGColor];
   [self.contentView.layer setShadowOffset:CGSizeMake(5, 5)];
   [self.contentView.layer setShadowOpacity:0.6];
   [self.contentView.layer setShadowColor:[UIColor blackColor].CGColor];
   
   
   
   
   
   UIView *imgView = [[[UIView alloc] initWithFrame:imgFrame] autorelease];
   imgView.backgroundColor = [UIColor clearColor];
   UIImage *image = [UIImage imageNamed:@"mandel.png"];
   imgView.layer.backgroundColor = [UIColor colorWithPatternImage:image].CGColor;
   
   // Rounded corners.
   imgView.layer.cornerRadius = 10;
   
   // A thin border.
   imgView.layer.borderColor = [UIColor blackColor].CGColor;
   imgView.layer.borderWidth = 0.3;
   
   // Drop shadow.
   imgView.layer.shadowColor = [UIColor blackColor].CGColor;
   imgView.layer.shadowOpacity = 1.0;
   imgView.layer.shadowRadius = 7.0;
   imgView.layer.shadowOffset = CGSizeMake(0, 4);
   
   
   */
    
//    [self setViewRoundAndShadow:_accountBkView];
    
//    _accountBkView.layer.shadowColor = [UIColor blackColor].CGColor;
//    _accountBkView.layer.shadowOffset = CGSizeMake(4, 4);
//    _accountBkView.layer.shadowOpacity = 0.80;
//    _accountBkView.layer.shadowRadius =  _accountBkView.size.height/2;
    
    // Do any additional setup after loading the view from its nib.
//    [_companyBkView setToCircle];
    [_accountBkView setToCircle];
    [_passwordBkView setToCircle];
    
   
 
//    _companyTextField.returnKeyType = UIReturnKeyNext;
//    _accountTextField.returnKeyType = UIReturnKeyNext;
//    _passwordTextField.returnKeyType = UIReturnKeyJoin;
    
//    _companyTextField.delegate = self;
    _accountTextField.delegate = self;
    _passwordTextField.delegate = self;
    
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    // 键盘高度变化通知
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    
    [nc addObserver:self selector:@selector(dismissLogin) name:kNetCenterLoginSuccRSNotifation object:nil];
    [nc addObserver:self selector:@selector(loginFailed:) name:kNetCenterLoginFailRSNotifation object:nil];
    if (![ACConfigs isPhone5]){
        [_contentView setFrame_height:_contentView.size.height-88];
        [_loginButton setFrame_y:_loginButton.origin.y-88];
        
//        [_companyBkView setFrame_y:_companyBkView.origin.y-30];
        [_accountBkView setFrame_y:_accountBkView.origin.y-30];
        [_passwordBkView setFrame_y:_passwordBkView.origin.y-30];
        
#ifdef USE_ForgetPWD_Button
        [_forgetPWDButton setFrame_y:_forgetPWDButton.origin.y-30];
#endif
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(nil==[ACConfigs shareConfigs].appNewVersionInfo){
        //新版本提示，强行升级ClearnUserData
        NSString* pAutoPWD_64 = [defaults objectForKey:kPwd_Auto_login];
        if(pAutoPWD_64.length){
            NSNumber* pPwd_Auto_login_Ver = [defaults objectForKey:kPwd_Auto_login_Ver];
            if(pPwd_Auto_login_Ver&&[[[[NSBundle mainBundle] infoDictionary] objectForKey:kCFBundleVersion] integerValue]>[pPwd_Auto_login_Ver integerValue]){
                NSData* decodeData = [[NSData alloc] initWithBase64EncodedString:pAutoPWD_64 options:0];
                pAutoPWD_64 = [[NSString alloc] initWithData:decodeData encoding:NSASCIIStringEncoding];
                if(pAutoPWD_64.length>0){
                    _passwordTextField.text = _pAutoLoginPWD_Base64 = pAutoPWD_64;
                }
            }
        }
     }
    
//#ifdef BUILD_FOR_EGA
//    _companyTextField.placeholder = @"Please input organization";
//#endif
//    _companyTextField.text = [defaults objectForKey:kUserLoginInputDomain];
    NSString* account = [defaults objectForKey:kAccount_debug];
    if(account.length<6){
        account =   [defaults objectForKey:kAccount];
    }
#ifdef ACUtility_Need_Log
    if(0==account.length
       
    #if !TARGET_IPHONE_SIMULATOR
       &&([[[UIDevice currentDevice] name] isEqualToString:@"iPhoneCE"]||
       [[[UIDevice currentDevice] name] isEqualToString:@"“Aculearn”的 iPhone7"])
    #endif
       
       ){
//        account =   @"debug_xiaobing@aculearn.com.cn";
        account =   @"jessica.li@aculearn.com.cn";
    }
#endif
    _accountTextField.text =    account;
    
    
#ifdef USE_ForgetPWD_Button
    [_forgetPWDButton setTitle:NSLocalizedString(@"Forget Password?", nil) forState:UIControlStateNormal];
#else
    _forgetPWDButton.hidden = YES;
#endif
    
    
    /*
    if([_companyTextField.text length]){
        if ([_accountTextField.text length] == 0){
            [_accountTextField becomeFirstResponder];
        }
        else{
            [_passwordTextField becomeFirstResponder];
        }
    }*/
    
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc ]initWithTarget:self action:@selector(touchBkView:)];
    [_contentView addGestureRecognizer:tapGesture];
#if DEBUG
    if(LoginState_waiting!=[ACConfigs shareConfigs].loginState){
        ITLogEX(@"..............loginState=%d",(int)[ACConfigs shareConfigs].loginState);
    }
#endif
    [ACConfigs shareConfigs].loginState = LoginState_waiting;
    [[ACNetCenter shareNetCenter] deleteLoopInquireForLoginUI:YES]; //关闭后台循环，等登录成功后再循环
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if(_pAutoLoginPWD_Base64){
        //登录
        [self serverLogin:nil];
    }
}
//-(void)viewWillDisappear:(BOOL)animated{
//    [super viewWillDisappear:animated];
//}
//
//- (void)dismissViewControllerAnimated: (BOOL)flag completion: (void (^)(void))completion{
//    [super dismissViewControllerAnimated:false completion:completion];
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Responders, events

-(void)touchBkView:(id)sender{
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
//    if(textField==_companyTextField){
//        [_accountTextField becomeFirstResponder];
//        return YES;
//    }
    
    if(textField==_accountTextField){
        [_passwordTextField becomeFirstResponder];
        return YES;
    }
    
//    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    [self serverLogin:nil];
    return YES;
}


-(BOOL)_serverLoginBeginForLogin:(BOOL)bLogIn{
    if (_accountTextField.text.length > 0 &&
        (bLogIn?(_passwordTextField.text.length > 0):YES))
//        (bLogIn?(_companyTextField.text.length > 0&&_passwordTextField.text.length > 0):YES))
    {
//        [_companyTextField resignFirstResponder];
        [_accountTextField resignFirstResponder];
        [_passwordTextField resignFirstResponder];
        //
        
        if(![ASIHTTPRequest isValidNetWork]){
            AC_ShowTip(NSLocalizedString(@"Not connected to network", nil));
            return NO;
        }
        return YES;
    }
    
    if(bLogIn)
    {
        static NSString* strKeyForLoginFailed = @"Login_Failed";
        NSString* pTipForLoginFailed = NSLocalizedStringFromTable(strKeyForLoginFailed,@"about",nil);
        if([pTipForLoginFailed isEqualToString:strKeyForLoginFailed]){
            pTipForLoginFailed = NSLocalizedString(strKeyForLoginFailed, nil);
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil)
                                                        message:pTipForLoginFailed
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }

    return NO;
}

/*
 Forget Password?
 https://{accounts server}/rest/sys/user/forgetpwd
 
 equest URL:http://accounts.acucom.net/rest/sys/user/forgetpwd
 Request Method:POST
 内容：
 {
	domain: "aculearn",
	account: "63112302@qq.com"
 }
 
 返回：
 {
	"code" : 1 ,
	"description" : "Request has been posted, please check your email then step to the next."
 }
 
 */
- (IBAction)onForgetPWD:(id)sender {
    //_companyTextField.text;
    //_accountTextField.text
    
    if (![self _serverLoginBeginForLogin:NO]){
        return;
    }
    [self.view showProgressHUD];
    
#ifdef acuCom_Debug_Login_Server
    NSString* pLoginServer =    acuCom_Debug_Login_Server;
#else
    NSString* pLoginServer  =   [[ACConfigs acOem_ConfigInfo] objectForKey:@"loginServer"];
#endif
    
//    pLoginServer = @"https://accounts.gchat.apps.go.th";//用于直接修改密码功能
    
    [ACNetCenter callURL:[NSString stringWithFormat:@"%@/rest/sys/user/forgetpwd",pLoginServer]
                  forPut:NO
            withPostData:@{@"account":_accountTextField.text}
               withBlock:^(ASIHTTPRequest *request, BOOL bIsFail) {
                   [self.view hideProgressHUDWithAnimated:NO];
                   NSString* pTip = nil;
                   if(!bIsFail){
                       NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
                       ITLog(responseDic);
                       pTip = responseDic[@"description"];
                   }
                   AC_ShowTip(pTip.length?pTip:NSLocalizedString(@"Network_Failed", nil));
    }];
}

-(IBAction)serverLogin:(id)sender
{
    if ([self _serverLoginBeginForLogin:YES]){
        
//        NSString* userLoginInputDomain = _companyTextField.text;
#if 0
        NSString * firmAndDomain = _companyTextField.text;
        NSString * firmStr;
        NSArray * domanArray = [domainStr componentsSeparatedByString:@"."];
        if(domanArray != nil && domanArray.count > 1) {
            firmStr = [domanArray objectAtIndex:0];
            NSString * hostStr = [domainStr substringFromIndex: [firmStr length] + 1];
            NSString * acuServerStr = [@"http://acucom." stringByAppendingString:hostStr];
            [[ACNetCenter shareNetCenter] setAcuServer: acuServerStr];
            NSString * accountsServerStr = [@"http://accounts." stringByAppendingString:hostStr];
            [[ACNetCenter shareNetCenter] setAccountsServer:accountsServerStr];
            NSString * loginServerStr = [[[ACNetCenter shareNetCenter] accountsServer] stringByAppendingString:@"/rest/oauth/login"];
            [[ACNetCenter shareNetCenter] setLoginServer:loginServerStr];
            
        }
        else {
#if DEBUG
            if([domainStr isEqualToString:@"john"]){
                [[ACNetCenter shareNetCenter] setLocalDebug:YES];
            }
            else
#endif
            {
                if(domainStr.length>6&&[[domainStr substringToIndex:6] isEqualToString:@"debug "]){
                    domainStr = [domainStr substringFromIndex:6];
                    [[ACNetCenter shareNetCenter] setLocalDebug:YES];
                }
                else{
                    [[ACNetCenter shareNetCenter] setLocalDebug:NO];
                }
            }
            
            firmStr = domainStr;
        }
#endif
        
        {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults removeObjectForKey:kPwd];
            [defaults removeObjectForKey:kPwd_Auto_login];
            [defaults synchronize];
        }

        
//      [@"http://acucom1.aculearn.com" stringByAppendingString:@"/rest/oauth/login"];
//
        NSString *base64Pwd = [ASIHTTPRequest base64forData:[_passwordTextField.text dataUsingEncoding:NSUTF8StringEncoding]];
        [ACNetCenter shareNetCenter].isFromUILogin = YES;
        [[ACNetCenter shareNetCenter] loginAcucomServerWithAccount:_accountTextField.text
                                                               pwd:base64Pwd
                                                            userLoginInputDomain:@""];
        [_contentView showProgressHUDWithLabelText:NSLocalizedString(@"Loading", nil) withAnimated:NO withAfterDelayHide:0];
        [self performSelector:@selector(loginFailed:) withObject:nil afterDelay:20];
    }
}

-(void)loginFailed:(NSNotification *)noti
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loginFailed:) object:nil];
    
    NSString* pTip = NSLocalizedString(@"Network_Failed", nil);
    if([noti.object isKindOfClass:[NSDictionary class]]){
        NSDictionary* pRes = (NSDictionary*)noti.object;
        NSString* pErrorDescription = [pRes objectForKey:@"description"];
        if(pErrorDescription.length){
            pTip =  pErrorDescription;
        }
    }

    [_contentView hideProgressHUDWithAnimated:NO];
    AC_ShowTip(pTip);
//    [_contentView showProgressHUDNoActivityWithLabelText:pTip withAfterDelayHide:1];
}

-(void)dismissLogin
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loginFailed:) object:nil];

    [_contentView hideProgressHUDWithAnimated:NO];
    [ACNetCenter shareNetCenter].isFromUILogin = NO;
    [self ACdismissViewControllerAnimated:YES completion:^{
//        ACConfigs* pConfig = [ACConfigs shareConfigs];
        [ACConfigs toAllChatViewController];
#ifdef NEED_CHAGE_Default_PWD_In_LogInView
        if(pConfig.changeDefaultPWD_Reason){
            MMDrawerController* deckC = (MMDrawerController *)[UIApplication sharedApplication].delegate.window.rootViewController;
            //取得最前面的VC
            UIViewController *topVC = ((UINavigationController *)(deckC.centerViewController)).visibleViewController;
            [topVC.navigationController pushViewController:[[ACChangePasswordController alloc] init] animated:YES];
        }
#endif
    }];
}

#pragma mark -
#pragma mark Responding to keyboard events

-(void)keyboardShowOrHide:(NSNotification *)notification forShow:(BOOL)bShow{
    
    CGPoint point = CGPointZero;
    NSDictionary *userInfo = [notification userInfo];
 
    
    if(bShow){
        
        // Get the origin of the keyboard when it's displayed.
        NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
        
        // Get the top of the keyboard as the y coordinate of its origin in self's view's coordinate system. The bottom of the text view's frame should align with the top of the keyboard's final position.
        CGRect keyboardRect = [aValue CGRectValue];
        
#ifdef USE_ForgetPWD_Button
        CGRect TheRect = _forgetPWDButton.frame;
#else
        CGRect TheRect = _passwordBkView.frame;
#endif
        
        point   = CGPointMake(0,TheRect.origin.y+TheRect.size.height+10-keyboardRect.origin.y);
    }
    
    // Shrink view's inset by the keyboard's height, and scroll to show the text field/view being edited
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];
    
    [_contentView setContentOffset:point animated:NO];
    
    [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    
    [self keyboardShowOrHide:notification forShow:YES];
    
}


- (void)keyboardWillHide:(NSNotification *)notification {

     [_contentView setContentOffset:CGPointZero animated:NO];
//    [self keyboardShowOrHide:notification forShow:NO];

}


@end
