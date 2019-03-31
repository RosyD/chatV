//
//  ACChangePasswordController.m
//  chat
//
//  Created by 王方帅 on 14-7-17.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACChangePasswordController.h"
#import "UINavigationController+Additions.h"
#import "ACNetCenter.h"
#import "UIView+Additions.h"
#import "ACConfigs.h"

@interface ACChangePasswordController ()

@end

@implementation ACChangePasswordController

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
    
    _title.text =   NSLocalizedString(@"Change password",nil);
    oldTextField.placeholder=   NSLocalizedString(@"Old password",nil);
    newTextField.placeholder=   NSLocalizedString(@"New password",nil);
    confirmTextField.placeholder=   NSLocalizedString(@"Confirm new password",nil);
    [_saveButton setNomalText:NSLocalizedString(@"Save",nil)];

    
    
    // Do any additional setup after loading the view from its nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(codeError:) name:kNetCenterResponseCodeErrorNotifation object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changePasswordSuccess:) name:kNetCenterChangePasswordNotifation object:nil];
//    if (![ACConfigs isPhone5])
    {
        [_scrollView setFrame_y:-20];
    }
    
    _backButton.hidden = _focusChangeDefaultPWD;
    
    if(_focusChangeDefaultPWD){
        newPWD_BkView2.frame =  newPWD_BkView1.frame;
        newPWD_BkView1.frame =  oldPWD_BkView.frame;
        oldPWD_BkView.hidden = YES;
        [newTextField becomeFirstResponder];
    }
}


#pragma mark -notification
-(void)codeError:(NSNotification *)noti
{
    [_contentView hideProgressHUDWithAnimated:NO];
}

-(void)changePasswordSuccess:(NSNotification *)noti
{
    [_contentView showProgressHUDSuccessWithLabelText:NSLocalizedString(@"Password updated successfully", nil) withAfterDelayHide:1.2];
//    _backButton.hidden = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.navigationController ACpopViewControllerAnimated:YES];
    });
}

#pragma mark textFieldDelegate
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (![ACConfigs isPhone5])
    {
        float y = textField.superview.origin.y;
        if (textField == oldTextField)
        {
            [_scrollView setFrame_y:-20];
        }
        else
        {
            [_scrollView setFrame_y:-y+38];
        }
    }
    return YES;
}

#pragma mark -IBAction
-(IBAction)goback:(id)sender
{
    [self.navigationController ACpopViewControllerAnimated:YES];
}

-(IBAction)changePassword:(id)sender
{
    [_scrollView setFrame_y:-20];
    [oldTextField resignFirstResponder];
    [newTextField resignFirstResponder];
    [confirmTextField resignFirstResponder];
    
    NSString *message = nil;
    
    if(!_focusChangeDefaultPWD){
    
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *pwd = [defaults objectForKey:kPwd];
        
        NSString *base64Pwd = [ASIHTTPRequest base64forData:[oldTextField.text dataUsingEncoding:NSUTF8StringEncoding]];
    

        if ([oldTextField.text length] == 0){
            message = NSLocalizedString(@"Please input old password", nil);
        }
        else if (![pwd isEqualToString:base64Pwd]){
            message = NSLocalizedString(@"The old password is wrong", nil);
        }
        if(message.length){
            AC_ShowTip(message);
            return;
        }
    }
    
    
    if ([newTextField.text length] == 0 || [newTextField.text length] < 6){
        message = NSLocalizedString(@"Please input new password at least 6 character", nil);
    }
    else if ([oldTextField.text isEqualToString:newTextField.text]){
        message = NSLocalizedString(@"The new password and the password cannot be the same", nil);
    }
    else if ([confirmTextField.text length] == 0){
        message = NSLocalizedString(@"Please again to confirm password", nil);
    }
    else if (![newTextField.text isEqualToString:confirmTextField.text]){
        message = NSLocalizedString(@"The two passwords do not match", nil);
    }
    else{
//        [_contentView showNetLoadingWithAnimated:NO];
        [_contentView showProgressHUD];
        [[ACNetCenter shareNetCenter] changePassword:[ASIHTTPRequest base64forData:[newTextField.text dataUsingEncoding:NSUTF8StringEncoding]]];
    }
    
    if (message.length > 0){
        AC_ShowTip(message);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
