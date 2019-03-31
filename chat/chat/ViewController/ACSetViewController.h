//
//  ACSetViewController.h
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-28.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

#define kPerm   @"perm"
#define kDefla  @"defla"

enum locationAlertUserDefine
{
    locationAlertUserDefine_deny,
    locationAlertUserDefine_allow,
};

@interface ACSetViewController : UIViewController<MFMailComposeViewControllerDelegate,UIAlertViewDelegate>
{
    IBOutlet UIButton       *_feedbackButton;//回复
    IBOutlet UIButton       *_aboutButton;//关于
    IBOutlet UIButton       *_locationSettingButton;
    
    IBOutlet UIView         *_contentView;
    IBOutlet UIScrollView   *_mainScrollView;
    
    IBOutlet UIButton       *_backButton;
    IBOutlet UIButton       *_logoutButton;
    IBOutlet UILabel        *_feedbackLabel;
    IBOutlet UILabel        *_aboutLabel;
    
    IBOutlet UILabel        *_titleLabel;
    IBOutlet UIView         *_locationSettingView;
}

@property (nonatomic) BOOL                      isOpenHotspot;

@end
