//
//  ACAboutViewController.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-25.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACAboutViewController : UIViewController
{
    __weak IBOutlet UILabel    *_urlLabel;
    
    __weak IBOutlet UIButton   *_backButton;
    __weak IBOutlet UILabel    *_websiteLabel;
    
    __weak IBOutlet UIView *_poweredBkView;
    __weak IBOutlet UILabel    *_poweredByLabel;
    __weak IBOutlet UIImageView    *_iconImageView;
    __weak IBOutlet UIView         *_iconBgView;
    __weak IBOutlet UILabel        *_appNameAndVersionLabel;
    
    __weak IBOutlet UILabel *_titleLable;
    __weak IBOutlet UIButton *_buttonForCheckUpdate;
    
    
    __weak IBOutlet UIView *_policyBkView;    
    __weak IBOutlet UIButton *_policyButton;
}

@property (nonatomic) BOOL                      isOpenHotspot;

@end
