//
//  ACPicSendController.h
//  chat
//
//  Created by 李朝霞 on 2017/5/16.
//  Copyright © 2017年 李朝霞. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShareViewController.h"

@interface ACPicSendController : UIViewController

@property(strong,nonatomic)NSString* picnum;

@property(weak,nonatomic)ShareViewController* shareVc;

//进度条
@property(nonatomic,strong)UIProgressView* progressView;

//按钮
@property(nonatomic,strong)UIButton* btn;

//分界线
@property(nonatomic,strong)UIView* lineView;

//名字
@property(nonatomic,strong)UILabel* nameLabel;

//图片数量名
@property(nonatomic,strong)UILabel* numLable;

//数量
@property(assign,nonatomic)int picn;

@end
