//
//  ACPersonInfoViewController.h
//  AcuCom
//
//  Created by 王方帅 on 14-5-4.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GCPlaceholderTextView.h"
#import "ACChangeIconVC_Base.h"

extern NSString *const kPersonInfoPutSuccessNotifation;

@interface ACPersonInfoViewController : ACChangeIconVC_Base<UITextFieldDelegate,UITextViewDelegate>
{
    __weak IBOutlet UIView         *_contentView;
    
    __weak IBOutlet UIButton       *_backButton;
    __weak IBOutlet UILabel        *_titleLabel;
    __weak IBOutlet UIButton       *_saveButton;
    
    __weak IBOutlet UILabel *_accountLable;
    float                   _descHeight;
}


@property (nonatomic) BOOL              isOpenHotspot;

@end
