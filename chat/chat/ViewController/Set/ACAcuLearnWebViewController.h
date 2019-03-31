//
//  ACAcuLearnWebViewController.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-25.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACEntity.h"

@interface ACAcuLearnWebViewController : UIViewController<UIWebViewDelegate>
{
    IBOutlet UIWebView      *_mainWebView;
    IBOutlet UIView         *_webSuperView;
    IBOutlet UIToolbar      *_toolbar;
    IBOutlet UIView         *_contentView;
    
    IBOutlet UIButton       *_backButton;
    IBOutlet UILabel        *_titleLabel;
    IBOutlet UIBarButtonItem       *_gobackButton;
    __weak IBOutlet UIButton *_onOptionButton;
    
}

@property (nonatomic,strong) NSString   *urlString;
@property (nonatomic,strong) NSString   *titleString;
@property (nonatomic,strong) ACUrlEntity    *urlEntity;
@property (nonatomic) BOOL              needAction;//前进后退按钮，网页使用
@property (nonatomic) BOOL              isOpenHotspot;

- (instancetype)initWithUrlString:(NSString *)urlString;

@end
