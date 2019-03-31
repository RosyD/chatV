//
//  ACGroupInfoOptionVC.h
//  chat
//
//  Created by Aculearn on 15/2/11.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACChangeIconVC_Base.h"

@class ACBaseEntity;
@interface ACGroupInfoOptionVC : ACChangeIconVC_Base<UITextViewDelegate,UITextFieldDelegate>

@property (nonatomic,strong) ACBaseEntity      *entity;

@end
