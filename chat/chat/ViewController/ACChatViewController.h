//
//  ACChatViewController.h
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-27.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACEntity.h"

enum ChatType
{
    ChatType_Define,
    ChatType_Search,
};

@interface ACChatViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate,UIAlertViewDelegate>
{
    __weak IBOutlet UITableView        *_mainTableView;
    __weak IBOutlet UILabel            *_titleLabel;
    __weak IBOutlet UIView             *_contentView;
    
    __weak IBOutlet UIButton    *_notifyButton;
    __weak IBOutlet UIButton           *_backButton;
    __weak IBOutlet UISearchBar        *_searchBar;
    __weak IBOutlet UIView             *_navView;
    
    __weak IBOutlet UIView *_netStatView;
    __weak IBOutlet UILabel *_netStatLable;
    __weak IBOutlet UIActivityIndicatorView    *_activityView;
    
}

//移除通知
-(void)removeNotification;

-(void)deleteEntity:(ACBaseEntity *)entity forTerminate:(BOOL)terminate;
-(void)transferAdmin:(ACBaseEntity *)entity;
-(void)reloadEntity; 
-(void)changeIsTurnOffAlertsAndSendToServerForEntity:(ACTopicEntity*)topicEntity;

-(void)checkNotification;
-(void)openEntity:(ACBaseEntity*)entity animated:(BOOL)animated;

@property (nonatomic) enum ACCenterViewControllerType   chatListType;
@property (nonatomic) enum ChatType             chatType;
@property (nonatomic,strong) NSString           *chatListTitle;
@property (nonatomic,strong) NSMutableArray     *dataSourceArray;
@property (nonatomic) BOOL                      isOpenHotspot;
@property (nonatomic,strong) NSMutableArray     *filterArray;
@property (nonatomic,strong) NSString           *searchKey;

@end
