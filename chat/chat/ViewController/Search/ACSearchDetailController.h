//
//  ACSearchDetailController.h
//  chat
//
//  Created by 王方帅 on 14-7-8.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACChatViewController.h"
#import "EGORefreshTableFooterView.h"

enum ACSearchDetailType  //必须和 SearchCountType 相等
{
    ACSearchDetailType_Chat,
    ACSearchDetailType_User,
    ACSearchDetailType_UserGroup,
    ACSearchDetailType_AccountUser,
    ACSearchDetailType_Note,
};

#define kHighlights @"highlights"

@interface ACSearchDetailController : UIViewController<UITableViewDataSource,UITableViewDelegate,EGORefreshTableFooterDelegate>
{
    IBOutlet UITableView    *_mainTableView;
    IBOutlet UILabel        *_titleLabel;
    IBOutlet UIView         *_contentView;
    EGORefreshTableFooterView   *_refreshView;
    BOOL                    _isCanLoadMore;
    BOOL                    _reloading;
    BOOL                    _isFirstLoad;
}

@property (nonatomic,strong) NSMutableArray     *dataSourceArray;
@property (nonatomic) enum ACSearchDetailType   searchDetailType;
@property (nonatomic,strong) NSString           *searchKey;
//@property (nonatomic,strong) NSMutableArray     *selectedUserGroupArray;
//@property (nonatomic,strong) NSMutableArray     *selectedUserArray;
@property (nonatomic,weak)  ACChatViewController      *chatVC;
@property (nonatomic,strong) NSMutableArray     *searchTopicEntityArray;

@end
