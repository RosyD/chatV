//
//  ACWhoReadTableViewCell.m
//  AcuCom
//
//  Created by 王方帅 on 14-5-18.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACWhoReadTableViewCell.h"
#import "ACUser.h"
#import "UIImageView+WebCache.h"

@implementation ACWhoReadTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    [_iconImageView.layer setCornerRadius:5.0];
    [_iconImageView.layer setMasksToBounds:YES];
}

-(void)setUser:(ACUser *)user
{
    //组icon
    NSString *imageName = @"personIcon100.png";
    if (user.icon)
    {
        [_iconImageView setImageWithIconString:user.icon placeholderImage:[UIImage imageNamed:imageName] ImageType:ImageType_UserIcon100];
    }
    else
    {
        _iconImageView.image = [UIImage imageNamed:imageName];
    }
    _nameLabel.text = user.name;
}

@end
