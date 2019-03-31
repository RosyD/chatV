//
//  ACRootTableViewCell.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-27.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>

enum ACCenterViewControllerType
{
    ACCenterViewControllerType_All = 0,
    ACCenterViewControllerType_Chat,
    ACCenterViewControllerType_Event,
    ACCenterViewControllerType_Survey,
    ACCenterViewControllerType_Link,
    ACCenterViewControllerType_Page,
    ACCenterViewControllerType_Services,
    ACCenterViewControllerType_Setting,
};

#define kAll NSLocalizedString(@"All", nil)
#define kSetting NSLocalizedString(@"Settings", nil)

@interface ACRootTableViewCell : UITableViewCell

@property (nonatomic) IBOutlet UIImageView      *iconImageView;
@property (nonatomic) IBOutlet UILabel          *titleLabel;

-(void)setRow:(int)row;

-(void)setSelect:(BOOL)selected;

@end
