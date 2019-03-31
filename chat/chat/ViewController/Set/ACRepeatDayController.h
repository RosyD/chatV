//
//  ACRepeatDayController.h
//  chat
//
//  Created by 王方帅 on 14-8-5.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACConfigs.h"


@class ACLocationSettingViewController;
@interface ACRepeatDayController : UIViewController

@property (nonatomic,strong) NSMutableArray             *dataSourceArray;
@property (nonatomic,weak) ACLocationSettingViewController   *superVC;

@end
