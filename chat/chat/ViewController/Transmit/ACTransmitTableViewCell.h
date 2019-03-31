//
//  ACTransmitTableViewCell.h
//  AcuCom
//
//  Created by 王方帅 on 14-5-20.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACTopicEntity;
@interface ACTransmitTableViewCell : UITableViewCell
{
    IBOutlet UIImageView        *_iconImageView;
    IBOutlet UILabel            *_titleLabel;
}

-(void)setTopicEntity:(ACTopicEntity *)topicEntity;

@end
