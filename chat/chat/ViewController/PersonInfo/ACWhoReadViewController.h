//
//  ACWhoReadViewController.h
//  AcuCom
//
//  Created by 王方帅 on 14-5-18.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACTopicEntity;
@interface ACWhoReadViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>
{
    IBOutlet UILabel    *_titleLabel;
    IBOutlet UIButton   *_backButton;
    IBOutlet UITableView    *_mainTableView;
    IBOutlet UIView         *_contentView;
}

@property (nonatomic,strong) NSMutableArray     *dataSourceArray;
@property (nonatomic,strong) NSString           *topicEntityID;
@property (nonatomic,strong) ACTopicEntity      *topicEntity;
@property (nonatomic) long                      seq;
@property (nonatomic) BOOL                      isOpenHotspot;

@end
