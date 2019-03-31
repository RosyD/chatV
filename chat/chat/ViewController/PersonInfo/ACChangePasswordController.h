//
//  ACChangePasswordController.h
//  chat
//
//  Created by 王方帅 on 14-7-17.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACChangePasswordController : UIViewController<UITextFieldDelegate>
{
    __weak IBOutlet UITextField    *oldTextField;
    __weak IBOutlet UITextField    *newTextField;
    __weak IBOutlet UITextField    *confirmTextField;
    __weak IBOutlet UIView         *_contentView;
    __weak IBOutlet UIScrollView   *_scrollView;
    __weak IBOutlet UIButton       *_backButton;
    __weak IBOutlet UILabel *_title;
    __weak IBOutlet UIButton *_saveButton;
    
    
    __weak IBOutlet UIView *oldPWD_BkView;
    __weak IBOutlet UIView *newPWD_BkView1;
    __weak IBOutlet UIView *newPWD_BkView2;
    
}

@property (nonatomic) BOOL    focusChangeDefaultPWD; //强制修改密码

@end
