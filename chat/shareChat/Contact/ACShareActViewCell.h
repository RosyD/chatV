//
//  ACShareActViewCell.h
//  chat
//
//  Created by 李朝霞 on 2017/2/10.
//  Copyright © 2017年 李朝霞. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACTopicEntity.h"

@class ShareActViewController;

@interface ACShareActViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconImage;

@property (weak, nonatomic) IBOutlet UILabel *title;

@property (weak, nonatomic) IBOutlet UIView *lineView;

//@property (strong,nonatomic) UIImageView* iconImage;
//
//@property (strong,nonatomic) UILabel* title;
//
//@property (strong,nonatomic) UIView* lineView;

@end
