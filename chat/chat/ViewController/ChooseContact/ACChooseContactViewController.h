//
//  ACChooseContactViewController.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-4.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACEntity.h"
#import "EGORefreshTableFooterView.h"

enum ChooseContactType
{
    ChooseContactType_Root,
    ChooseContactType_Group,
    ChooseContactType_ParticipantGroup,
    ChooseContactType_SinglePerson,
};

enum ACAddParticipantType
{
    ACAddParticipantType_New,
    ACAddParticipantType_AddToCurrent,
    ACAddParticipantType_SingleChatAddToNew,
};

enum LoadMoreType
{
    LoadMoreType_SubGroup,
    LoadMoreType_Single,
    LoadMoreType_Search,
};

@class ACTransmitViewController;
@interface ACChooseContactViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate,EGORefreshTableFooterDelegate>
{
    __weak IBOutlet UITableView        *_mainTableView;
    __weak IBOutlet UIButton           *_selectButton;
    __weak IBOutlet UIButton           *_cancelButton;
    
    __weak IBOutlet UIView             *_selectView;
    __weak IBOutlet UILabel            *_titleLabel;
    __weak IBOutlet UISearchBar        *_searchBar;
    NSMutableArray              *_dataSourceArray;//指针
    __weak IBOutlet UIView             *_contentView;
    
    __weak IBOutlet UIButton           *_backButton;
    __weak IBOutlet UIButton           *_cancelSearchButton;
    
    __weak IBOutlet UIButton *_selectAllButton;
    EGORefreshTableFooterView   *_refreshView;
    BOOL                        _reloading;
    BOOL                        _isCanLoadMore;
    BOOL                        _isHaveMore;
    enum LoadMoreType           _loadMoreType;
    BOOL                        _isAppear;
    BOOL                        _selfIsHadDelete;

    int                         _searchContactListWithKey_FuncType;
    NSString *                  _searchText;
}

@property (nonatomic) enum ChooseContactType    chooseContactType;
@property (nonatomic) enum ACAddParticipantType   addParticipant;
@property (nonatomic,strong) NSString           *groupID;//当前请求列表所属组
@property (nonatomic,strong) ACBaseEntity       *addPaticipantEntity; //添加参与者的entity
//@property (nonatomic,strong) NSString           *addPaticipantGroupID;//添加参与者基于groupID

@property (nonatomic,strong) NSString           *singleChatCurrentUserID;
@property (nonatomic,strong) NSMutableArray     *primeArray;//初始数据
@property (nonatomic,strong) NSMutableArray     *searchArray;//搜索数据
@property (nonatomic,strong) NSMutableArray     *selectedUserGroupArray;
@property (nonatomic,strong) NSMutableArray     *selectedUserArray;
@property (nonatomic,weak)  UIViewController          *cancelToViewController;

@property (nonatomic,strong) NSString           *name;//当前组名
@property (nonatomic,strong) NSString           *groupCr;//当前组的cr参数
@property (nonatomic,weak) ACTransmitViewController  *transmitVC;
@property (nonatomic) BOOL                      isOpenHotspot;
@property (nonatomic) BOOL                      isForJoinedUsersGroup;

-(void)selectedCountUpdate;
//-(NSString*)getDefaultGroupTitle; //取得缺省创建聊天的标题

@end
