//
//  ACEntityCell.h
//  AcuCom
//
//  Created by wfs-aculearn on 14-4-2.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACEntity.h"
//#import "AttributedLabel.h"

#define ACEntityCell_Hight  80  

@class ACChatViewController;
@interface ACEntityCell : UITableViewCell<UIActionSheetDelegate,UIAlertViewDelegate>
{
    __weak IBOutlet UIImageView    *_iconImageView;
    __weak IBOutlet UILabel        *_nameLabel;
    UILabel         *_searchNameLabel;
    __weak IBOutlet UILabel        *_contentLabel;
    __weak IBOutlet UIImageView    *_locationImageView;
    __weak IBOutlet UIImageView    *_destructImageView;
    __weak IBOutlet UIImageView    *_muteFlagImageView;

    __weak IBOutlet UILabel        *_timeLabel;
    __weak IBOutlet UIButton       *_unReadNumButton;
    __weak ACChatViewController    *_superVC;
    ACTopicEntity           *_topicEntity;
    ACUrlEntity             *_urlEntity;
    ACBaseEntity            *_entity;
    
    __weak IBOutlet UILabel        *_urlEntityTypeLabel;
    
    __weak IBOutlet UIView *_lineView;
    
    int                     _nLongPressFuncType;
}

-(void)setEntity:(ACBaseEntity *)entity superVC:(ACChatViewController *)superVC;
-(void)setEntityForTransmit:(ACBaseEntity *)entity; //被 ACTransmitViewController 使用
+(instancetype)cellForTableView:(UITableView*)tableView;

@end
