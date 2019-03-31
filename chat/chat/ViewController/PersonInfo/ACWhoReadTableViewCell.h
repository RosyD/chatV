//
//  ACWhoReadTableViewCell.h
//  AcuCom
//
//  Created by 王方帅 on 14-5-18.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACUser.h"

@interface ACWhoReadTableViewCell : UITableViewCell
{
    IBOutlet UIImageView    *_iconImageView;
    IBOutlet UILabel        *_nameLabel;
}

-(void)setUser:(ACUser *)user;

@end
