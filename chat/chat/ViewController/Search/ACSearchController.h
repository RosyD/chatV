//
//  ACSearchController.h
//  chat
//
//  Created by 王方帅 on 14-7-8.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kTopicTotal     @"topicTotal"
#define kUserGroupTotal @"userGroupTotal"
#define kUserTotal      @"userTotal"
#define kAccountTotal   @"accountTotal"
#define kNoteTotal      @"noteTotal"

enum SearchCountType //必须和ACSearchDetailType相等
{
    SearchCountType_Topic,
    SearchCountType_User,
    SearchCountType_UserGroup,
    SearchCountType_AccountUser,
    SearchCountType_Note,
};

enum SearchMode
{
    SearchMode_Search,
    SearchMode_History,
};

@class ACChatViewController;
@interface ACSearchController : UIViewController<UISearchBarDelegate,UIAlertViewDelegate>
{
    __weak IBOutlet UITableView    *_mainTableView;
    __weak IBOutlet UISearchBar    *_searchBar;
    __weak IBOutlet UIView         *_contentView;
    __weak IBOutlet UISwitch       *_privacyModeSwitch;
//    __weak IBOutlet UIButton *_privacyModeButton;
    
    __weak IBOutlet UIView         *_tableFooterView;
    __weak IBOutlet UIButton       *_clearHistoryButton;
    __weak IBOutlet UILabel *_titleLable;
    __weak IBOutlet UIButton *_privateBrowButton;
}

@property (nonatomic,strong) NSString       *searchKey;
@property (nonatomic,strong) NSDictionary   *searchCountDic;
@property (nonatomic,strong) NSMutableArray *dataSourceArray;
@property (nonatomic,strong) NSMutableArray *searchArray;
@property (nonatomic,weak) ACChatViewController  *chatVC;
@property (nonatomic,strong) NSMutableArray *historyList;
@property (nonatomic) enum SearchMode       searchMode;

@end
