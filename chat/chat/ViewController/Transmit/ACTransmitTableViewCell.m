//
//  ACTransmitTableViewCell.m
//  AcuCom
//
//  Created by 王方帅 on 14-5-20.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACTransmitTableViewCell.h"
#import "ACEntity.h"
#import "ACUser.h"
#import "ACUserDB.h"
#import "UIImageView+WebCache.h"

@implementation ACTransmitTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    [_iconImageView.layer setMasksToBounds:YES];
    [_iconImageView.layer setCornerRadius:5.0];
}

-(void)setTopicEntity:(ACTopicEntity *)topicEntity
{
    if ([topicEntity.mpType isEqualToString:cSingleChat])
    {
        ACUser *user = [ACUserDB getUserFromDBWithUserID:topicEntity.singleChatUserID];
        
        //组icon
        NSString *imageName = @"icon_singlechat.png";
        if (user.icon)
        {
            [_iconImageView setImageWithIconString:user.icon placeholderImage:[UIImage imageNamed:imageName] ImageType:ImageType_TopicEntity];
        }
        else
        {
            _iconImageView.image = [UIImage imageNamed:imageName];
        }
        _titleLabel.text = user.name;
    }
    else
    {
        //组icon
        NSString *imageName = @"icon_groupchat.png";
        if (topicEntity.icon)
        {
            if ([topicEntity.mpType isEqualToString:cLocationAlert])
            {
                [_iconImageView setImage:[UIImage imageNamed:@"LocationAlert.png"]];
            }
            else
            {
                [_iconImageView setImageWithIconString:topicEntity.icon placeholderImage:[UIImage imageNamed:imageName] ImageType:ImageType_TopicEntity];
            }
        }
        else
        {
            _iconImageView.image = [UIImage imageNamed:imageName];
        }
        
        //组名
        _titleLabel.text = topicEntity.title;
        
        //$$
        if([topicEntity.relateTeID length] > 0)
        {
            ACUser *user = [ACUserDB getUserFromDBWithUserID:topicEntity.relateChatUserID];
            
            //组icon
            if (user.icon)
            {
                [_iconImageView setImageWithIconString:user.icon placeholderImage:[UIImage imageNamed:imageName] ImageType:ImageType_TopicEntity];
            }
           
            _titleLabel.text = user.name;
        }
    }
}

@end
