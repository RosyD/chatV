//
//  ACChooseContactViewController.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-4.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACChooseContactViewController.h"
#import "ACNetCenter.h"
#import "ACContactTableViewCell.h"
#import "ACEntity.h"
#import "ACUser.h"
#import "ACCreateChatGroupViewController.h"
#import "UINavigationController+Additions.h"
#import "UIView+Additions.h"
#import "ACChatMessageViewController.h"

#import "ACChatViewController.h"
#import "MBProgressHUD.h"
#import "ACTransmitViewController.h"
#import "ACAddress.h"
#import "ACUserDB.h"
#import "ACNotesMsgVC_Main.h"
#import "ACUrlEditViewController.h"
#import "ACSearchController.h"
#import "ACSearchCell.h"

#define kLimit  20

@interface ACChooseContactViewController ()

@end

@implementation ACChooseContactViewController

- (void)dealloc
{
    AC_MEM_Dealloc();
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _primeArray = [[NSMutableArray alloc] init];
        _dataSourceArray = _primeArray;
        _searchArray = [[NSMutableArray alloc] init];
        _selectedUserArray = [[NSMutableArray alloc] init];
        _selectedUserGroupArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (![ACConfigs isPhone5])
    {
        [_mainTableView setFrame_height:_mainTableView.size.height-88];
        [_selectView setFrame_y:_selectView.origin.y-88];
        [_contentView setFrame_height:_contentView.size.height-88];
    }
    
    _reloading = NO;
    
    if (_chooseContactType != ChooseContactType_Root)
    {
        _isHaveMore = YES;
    }
    else
    {
        _isHaveMore = NO;
    }
    _selfIsHadDelete = NO;
    
    [_selectButton setBackgroundImage:[[UIImage imageNamed:@"OpBigBtn.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:12] forState:UIControlStateNormal];
    [_selectButton setBackgroundImage:[[UIImage imageNamed:@"OpBigBtnHighlight.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:12] forState:UIControlStateHighlighted];
    [_cancelButton setBackgroundImage:[[UIImage imageNamed:@"OpBigBtn.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:12] forState:UIControlStateNormal];
    [_cancelButton setBackgroundImage:[[UIImage imageNamed:@"OpBigBtnHighlight.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:12] forState:UIControlStateHighlighted];
    
    //refreshView
    _refreshView = [[EGORefreshTableFooterView alloc]  initWithFrame:CGRectZero];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    if (_chooseContactType == ChooseContactType_Root)
    {
        [nc addObserver:self selector:@selector(recvRootList:) name:kNetCenterGetContactPersonRootListNotifation object:nil];
        _isCanLoadMore = NO;
    }
    else
    {
        _isCanLoadMore = YES;
        [nc addObserver:self selector:@selector(recvGroupList:) name:kNetCenterGetContactPersonGroupListNotifation object:nil];
        [nc addObserver:self selector:@selector(recvSingleList:) name:kNetCenterGetContactPersonSingleListNotifation object:nil];
    }
    [nc addObserver:self selector:@selector(recvCreateGroupSucc:) name:kNetCenterCreateGroupChatNotifation object:nil];
    //搜索通知
    [nc addObserver:self selector:@selector(recvSearchList:) name:kNetCenterGetContactPersonSearchListNotifation object:nil];
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
    [nc addObserver:self selector:@selector(responseCodeError:) name:kNetCenterResponseCodeErrorNotifation object:nil];
//    [nc addObserver:self selector:@selector(errorAuthorityChangedFailed_1248:) name:kNetCenterErrorAuthorityChangedFailed_1248 object:nil];

    
    [_contentView showNetLoadingWithAnimated:NO];
    
    
#if 0 //DEBUG
    if(_groupCr){
        _titleLabel.text  =   _groupCr;
    }
    else
#endif
    {
        _titleLabel.text = NSLocalizedString(@"Select Contact", nil);
    }
    
    
    [_cancelButton setTitle:NSLocalizedString(@"Abort", nil) forState:UIControlStateNormal];
    [_selectAllButton setTitle:NSLocalizedString(@"Select All", nil) forState:UIControlStateNormal];
//    [_backButton setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateNormal];

    if((_groupCr&&![ACConfigs shareConfigs].canSearchInCR)||
            _searchContactListWithKey_FuncType!= searchContactListWithKey_FuncType_Nouse){
        //需要隐藏搜索框
        _searchBar.hidden = YES;
        _cancelSearchButton.hidden = YES;
        
        CGRect TheFrame = _mainTableView.frame;
        TheFrame.origin.y = _searchBar.frame.origin.y;
        TheFrame.size.height += _searchBar.frame.size.height;
       /// _mainTableView.frame =  TheFrame;
        [_mainTableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.offset(0);
        }];
        
    }
    else{
    
        if ([_name length] == 0)
        {
            _searchBar.placeholder = NSLocalizedString(@"Search",nil);
        }
        else
        {
            _searchBar.placeholder = [NSString stringWithFormat:@"%@%@",NSLocalizedString(@"Search in ",nil),_name];
        }
        
        [_cancelSearchButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    }
    
    if ([ASIHTTPRequest isValidNetWork])
    {
        if(_searchContactListWithKey_FuncType!= searchContactListWithKey_FuncType_Nouse){
            //取得搜索信息
            _dataSourceArray = _searchArray;
            [self searchContactListWithKeyOnSearchButtonClicked:NO];
            return;
        }

        switch (_chooseContactType)
        {
            case ChooseContactType_Root:
            {
                [[ACNetCenter shareNetCenter] getContactPersonRootList];
            }
                break;
            case ChooseContactType_Group:
            {
                [[ACNetCenter shareNetCenter] getContactPersonSubGroupListWithGroupID:_groupID withOffset:0 withLimit:kLimit withCR:_groupCr];

            }
                break;
            case ChooseContactType_ParticipantGroup:
            {
                [[ACNetCenter shareNetCenter] getContactPersonSubGroupListWithGroupID:_groupID withOffset:0 withLimit:kLimit];
                [_selectView setHidden:YES];
                [_mainTableView setFrame_height:_mainTableView.size.height+_selectView.size.height];
                _titleLabel.text = _name;
            }
                break;
            case ChooseContactType_SinglePerson:
            {
                [[ACNetCenter shareNetCenter] getContactPersonSinglePersonListWithGroupID:_groupID withOffset:0 withLimit:kLimit withCR:_groupCr];
            }
                break;
            default:
                break;
        }
    }
    else
    {
        [_contentView showProgressHUDNoActivityWithLabelText:NSLocalizedString(@"Network_Failed", nil) withAfterDelayHide:0.8];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (_chooseContactType != ChooseContactType_ParticipantGroup)
    {
        [_mainTableView reloadData];
        [self selectedCountUpdate];
    }
    [self initHotspot];
    _isAppear = YES;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    _isAppear = NO;
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self initHotspot];
}

#pragma mark -NSNotification
-(void)responseCodeError:(NSNotification *)noti
{
    NSNumber *fileType = noti.object;
    if ([fileType integerValue] == ACFile_Type_CreateGroupChat)
    {
        [_contentView hideProgressHUDWithAnimated:NO];
    }
}

-(void)hotspotStateChange:(NSNotification *)noti
{
    if (_isOpenHotspot)
    {
        [_mainTableView setFrame_height:_mainTableView.size.height-hotsoptHeight];
        [_selectView setFrame_y:_selectView.origin.y-hotsoptHeight];
    }
    else
    {
        [_mainTableView setFrame_height:_mainTableView.size.height+hotsoptHeight];
        [_selectView setFrame_y:_selectView.origin.y+hotsoptHeight];
    }
}

-(void)recvRootList:(NSNotification *)noti
{
    if (!_isAppear)
    {
        return;
    }
    if (_chooseContactType == ChooseContactType_Root)
    {
        [_contentView hideProgressHUDWithAnimated:YES];
        NSMutableArray *array = noti.object;
        [_primeArray addObjectsFromArray:array];
        [_mainTableView reloadData];
    }
}

-(void)recvGroupList:(NSNotification *)noti
{
    if (!_isAppear)
    {
        return;
    }
    if (_chooseContactType != ChooseContactType_Root)
    {
        NSDictionary *dic = noti.object;
        NSMutableArray *array = [dic objectForKey:kUserGroups];
        NSString *groupID = [dic objectForKey:kGroupID];
        if (groupID == _groupID)
        {
            if ([array count] < kLimit)
            {
                [[ACNetCenter shareNetCenter] getContactPersonSinglePersonListWithGroupID:_groupID withOffset:0 withLimit:kLimit  withCR:_groupCr];
                [_primeArray addObjectsFromArray:array];
                [_mainTableView reloadData];
            }
            else
            {
                _loadMoreType = LoadMoreType_SubGroup;
                [_contentView hideProgressHUDWithAnimated:NO];
                
                if (!_reloading)
                {
                    [_mainTableView setContentOffset:CGPointMake(0, 0)];
                    _refreshView.delegate = self;
                    //下拉刷新的控件添加在tableView上
                    [_mainTableView addSubview:_refreshView];
                }
                else
                {
                    _reloading = NO;
                    [_refreshView egoRefreshScrollViewDataSourceDidFinishedLoading:_mainTableView];
                }
                [_primeArray addObjectsFromArray:array];
                [_mainTableView reloadData];
                if (_isCanLoadMore)
                {
                    [self setRefreshViewFrame];
                }
            }
        }
    }
}

-(void)recvSingleList:(NSNotification *)noti
{
    if (!_isAppear)
    {
        return;
    }
    if (_chooseContactType != ChooseContactType_Root)
    {
        [_contentView hideProgressHUDWithAnimated:NO];
        NSMutableArray *array = noti.object;
        
        if ([array count] < kLimit)
        {
            _isCanLoadMore = NO;
            _isHaveMore = NO;
            if ([_refreshView superview] != nil)
            {
                _refreshView.delegate = nil;
                //下拉刷新的控件添加在tableView上
                [_refreshView removeFromSuperview];
            }
        }
        else
        {
            if ([_refreshView superview] == nil)
            {
                _refreshView.delegate = self;
                [_mainTableView addSubview:_refreshView];
            }
            _loadMoreType = LoadMoreType_Single;
        }
        
        if (!_reloading && _isCanLoadMore)
        {
            [_mainTableView setContentOffset:CGPointMake(0, 0)];
            _refreshView.delegate = self;
            //下拉刷新的控件添加在tableView上
            [_mainTableView addSubview:_refreshView];
        }
        else
        {
            _reloading = NO;
            [_refreshView egoRefreshScrollViewDataSourceDidFinishedLoading:_mainTableView];
        }
        
        for (int i = 0; i < [array count]; i++)
        {
            ACUser *user = [array objectAtIndex:i];
            if ([ACUser isMySelf:user.userid])
            {
                [array removeObject:user];
                break;
            }
        }
        [_primeArray addObjectsFromArray:array];
        [_mainTableView reloadData];
        if (_isCanLoadMore)
        {
            [self setRefreshViewFrame];
        }
    }
}

-(void)recvCreateGroupSucc:(NSNotification *)noti
{
    if ([ACNetCenter shareNetCenter].createTopicEntityVC == self)
    {
        if (_transmitVC != nil){
            [self.navigationController ACpopToViewController:_transmitVC animated:YES];
        }
        else{
            ACChatMessageViewController *chatMessageVC = [[ACChatMessageViewController alloc] initWithSuperVC:self withTopicEntity:noti.object];
//            chatMessageVC.topicEntity = noti.object;
//            [chatMessageVC preloadDB];
            AC_MEM_Alloc(chatMessageVC);
            [self.navigationController pushViewController:chatMessageVC animated:YES];
        }
    }
}

-(void)recvSearchList:(NSNotification *)noti
{
    if (!_isAppear)
    {
        return;
    }

    NSDictionary *responseDic = noti.object;

    NSArray *users = [responseDic objectForKey:kUsers];
    if(nil==users){
        int nUserTotal = [[responseDic objectForKey:kUserTotal] intValue];
        int nAccountTotal=   [[responseDic objectForKey:kAccountTotal] intValue];

        if(nUserTotal){

            if(nAccountTotal){
                //两个数据都有，则显示一个列表
                [_searchArray addObject:@(nUserTotal)];
                [_searchArray addObject:@(nAccountTotal)];
                [_contentView hideProgressHUDWithAnimated:YES];
                [_mainTableView reloadData];
                return;
            }
            _searchContactListWithKey_FuncType  = searchContactListWithKey_FuncType_GetUserForName;
        }
        else if(nAccountTotal){
            _searchContactListWithKey_FuncType  = searchContactListWithKey_FuncType_GetUserForAccount;
        }
        else{
            //都没有
            [_contentView hideProgressHUDWithAnimated:YES];
            [_mainTableView reloadData];
            return;
        }

        //只显示一个
        //继续加载
        [self searchContactListWithKeyOnSearchButtonClicked:NO];
        return;
    }

    [_contentView hideProgressHUDWithAnimated:YES];
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:[users count]];
    for (NSDictionary *userDic in users) {
        ACUser *user = [[ACUser alloc] init];
        [user setUserDic:userDic];
        [array addObject:user];
    }


    if (!_reloading)
    {
        [_searchArray removeAllObjects];
    }
    else
    {
        [_refreshView egoRefreshScrollViewDataSourceDidFinishedLoading:_mainTableView];
    }
    
    if ([array count] < kLimit)
    {
        _isCanLoadMore = NO;
        if ([_refreshView superview] != nil)
        {
            _refreshView.delegate = nil;
            //下拉刷新的控件添加在tableView上
            [_refreshView removeFromSuperview];
            [_mainTableView setContentInset:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
        }
    }
    else
    {
        if ([_refreshView superview] == nil)
        {
            _refreshView.delegate = self;
            [_mainTableView addSubview:_refreshView];
        }
        _loadMoreType = LoadMoreType_Search;
    }

    /*不删除自己
    for (int i = 0; i < [array count]; i++)
    {
        ACUser *user = [array objectAtIndex:i];
        NSString *selfUserID = [[NSUserDefaults standardUserDefaults] objectForKey:kUserID];
        if ([user.userid isEqualToString:selfUserID])
        {
            _selfIsHadDelete = YES;
            [array removeObject:user];
            break;
        }
    }*/
    
    [_searchArray addObjectsFromArray:array];
    [_mainTableView reloadData];
    if (!_reloading && _isAppear)
    {
        [_mainTableView setContentOffset:CGPointMake(0, 0)];
    }
    else
    {
        _reloading = NO;
    }
    
    if (_isCanLoadMore)
    {
        [self setRefreshViewFrame];
    }
}

#pragma mark -tableViewDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_dataSourceArray count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSObject *obj = [_dataSourceArray objectAtIndex:indexPath.row];
    if([obj isKindOfClass:[NSNumber class]]){

        NSNumber *Value = (NSNumber *)obj;
        ACSearchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACSearchCell"];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACSearchCell" owner:nil options:nil];
            cell = [nib objectAtIndex:0];
        }
        [cell setSearchCountType:indexPath.row?SearchCountType_AccountUser:SearchCountType_User withCount:Value.intValue];
        return cell;
    }

    ACContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACContactTableViewCell"];
    if (!cell)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACContactTableViewCell" owner:nil options:nil];
        cell = [nib objectAtIndex:0];
        if (_chooseContactType == ChooseContactType_ParticipantGroup)
        {
            [cell setPreview];
        }
    }
    [cell setSuperVC_forChooseContact:self];
    if ([obj isKindOfClass:[ACUser class]])
    {
        [cell setUser:(ACUser *)obj For_ParticipantGroup:ChooseContactType_ParticipantGroup==_chooseContactType];
    }
    else
    {
        [cell setUserGroup:(ACUserGroup *)obj  For_ParticipantGroup:ChooseContactType_ParticipantGroup==_chooseContactType];
    }
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 69;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSObject *obj = [_dataSourceArray objectAtIndex:indexPath.row];
    if([obj isKindOfClass:[NSNumber class]]) {
        ACChooseContactViewController *chooseContactVC = [[ACChooseContactViewController alloc] init];
        AC_MEM_Alloc(chooseContactVC);
        chooseContactVC.cancelToViewController = self.cancelToViewController;
        chooseContactVC.addParticipant = self.addParticipant;
        chooseContactVC->_searchContactListWithKey_FuncType = indexPath.row? searchContactListWithKey_FuncType_GetUserForAccount:searchContactListWithKey_FuncType_GetUserForName;
        chooseContactVC->_groupCr   =   _groupCr;
        chooseContactVC->_groupID   =   _groupID;
        chooseContactVC->_primeArray=   _primeArray;
        chooseContactVC->_searchText = _searchText;
        chooseContactVC.chooseContactType = self.chooseContactType;
        chooseContactVC.selectedUserArray = self.selectedUserArray;
        chooseContactVC.selectedUserGroupArray = self.selectedUserGroupArray;
        chooseContactVC.addPaticipantEntity = self.addPaticipantEntity;
        chooseContactVC.singleChatCurrentUserID = self.singleChatCurrentUserID;
        chooseContactVC.transmitVC = self.transmitVC;
        [self.navigationController pushViewController:chooseContactVC animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        return;
    }

    ACContactTableViewCell *cell = (ACContactTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    //是user得话选中,是userGroup的话弹出下一级
    if (cell.user1)
    {
        if (_chooseContactType != ChooseContactType_ParticipantGroup)
        {
            [cell setContactSelected];
            [self selectedCountUpdate];
        }
    }
    else if (cell.userGroup1)
    {
        ACChooseContactViewController *chooseContactVC = [[ACChooseContactViewController alloc] init];
        AC_MEM_Alloc(chooseContactVC);
        chooseContactVC.cancelToViewController = self.cancelToViewController;
        chooseContactVC.addParticipant = self.addParticipant;
        if (self.chooseContactType == ChooseContactType_Root)
        {
            chooseContactVC.chooseContactType = ChooseContactType_Group;
        }
        else if (self.chooseContactType == ChooseContactType_ParticipantGroup)
        {
            chooseContactVC.chooseContactType = ChooseContactType_ParticipantGroup;
        }
        else
        {
            chooseContactVC.chooseContactType = ChooseContactType_Group;
        }
        if (_chooseContactType != ChooseContactType_ParticipantGroup)
        {
            chooseContactVC.selectedUserArray = self.selectedUserArray;
            chooseContactVC.selectedUserGroupArray = self.selectedUserGroupArray;
        }
        chooseContactVC.groupID = cell.userGroup1.groupID;
        chooseContactVC.name = cell.userGroup1.name;
        chooseContactVC.groupCr = cell.userGroup1.cr;
//        chooseContactVC.addPaticipantGroupID = self.addPaticipantGroupID;
        chooseContactVC.addPaticipantEntity = self.addPaticipantEntity;
        chooseContactVC.singleChatCurrentUserID = self.singleChatCurrentUserID;
        chooseContactVC.transmitVC = self.transmitVC;
        [self.navigationController pushViewController:chooseContactVC animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


#pragma mark -tableViewDelegate for Delete

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(!_isForJoinedUsersGroup){
        return;
    }
    
    NSObject *obj = [_dataSourceArray objectAtIndex:indexPath.row];
    if(![obj isKindOfClass:[ACUser class]]){
        return;
    }

    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.view showNetLoadingWithAnimated:YES];
        
        NSString* strURL = [NSString stringWithFormat:@"%@/rest/apis/usergroup/%@/user/%@",[ACNetCenter shareNetCenter].acucomServer,_groupID,((ACUser*)obj).userid];
        
        wself_define();
        [ACNetCenter callURL:strURL forMethodDelete:YES withBlock:^(ASIHTTPRequest *request, BOOL bIsFail) {
            [wself.view hideProgressHUDWithAnimated:YES];
            if(!bIsFail){
                NSDictionary *responseDic = [[[request.responseData objectFromJSONData] JSONString] objectFromJSONString];
                
                if (ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]){
                    sself_define();
                    [sself->_dataSourceArray removeObjectAtIndex:indexPath.row];
                    [sself->_mainTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                     withRowAnimation:UITableViewRowAnimationFade];
                    return;
                }
            }
            [wself.view showNetErrorHUD];
        }];
        
        /*删除
         type : 'delete',
         url : '/rest/apis/usergroup/{userGroupId}/user/{userId}'
         userGroupId : teid,
         userId : user['id']
         */
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}
-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return _isForJoinedUsersGroup;//YES;
}

#pragma mark -selectedCountUpdate
-(void)selectedCountUpdate
{
    [_selectButton setTitle:[NSString stringWithFormat:@"%@ (%lu)",NSLocalizedString(@"Select", nil),[_selectedUserArray count]+[_selectedUserGroupArray count]] forState:UIControlStateNormal];
}

#pragma mark -scrollViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_isCanLoadMore)
    {
        [_refreshView egoRefreshScrollViewDidScroll:scrollView];
    }
    
    [_searchBar resignFirstResponder];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (_isCanLoadMore)
    {
        [_refreshView egoRefreshScrollViewDidEndDragging:scrollView];
    }
    else
    {
        [_mainTableView reloadData];
    }
}

#pragma mark -loadMoreRefreshView
-(void)setRefreshViewFrame
{
    //如果contentsize的高度比表的高度小，那么就需要把刷新视图放在表的bounds的下面
    int height = MAX(_mainTableView.bounds.size.height, _mainTableView.contentSize.height);
    _refreshView.frame =CGRectMake(0.0f, height, _contentView.size.width, _mainTableView.bounds.size.height);
}

//出发下拉刷新动作，开始拉取数据
- (void)egoRefreshTableFooterDidTriggerRefresh:(EGORefreshTableFooterView*)view
{
    [self loadMore];
}
//返回当前刷新状态：是否在刷新
- (BOOL)egoRefreshTableFooterDataSourceIsLoading:(EGORefreshTableFooterView*)view
{
    return _reloading;
}
//返回刷新时间
-(NSDate *)egoRefreshTableFooterDataSourceLastUpdated:(EGORefreshTableFooterView *)view
{
    return [NSDate date];
}

-(void)loadMore
{
    _reloading = YES;
    
    if (_isCanLoadMore)
    {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            if (_loadMoreType == LoadMoreType_Search)
            {
                [self searchContactListWithKeyOnSearchButtonClicked:NO];
                return;
            }
            
            NSString *groupID = _groupID;
            if ([groupID length] == 0)
            {
                ACUserGroup *userGroup = [_primeArray lastObject];
                groupID = userGroup.groupID;
            }
            
            if (_loadMoreType == LoadMoreType_SubGroup)
            {
                [[ACNetCenter shareNetCenter] getContactPersonSubGroupListWithGroupID:groupID withOffset:(int)[_primeArray count] withLimit:kLimit];
            }
            else if (_loadMoreType == LoadMoreType_Single)
            {
                int offset = 0;
                for (int  i = (int)[_primeArray count]-1; i >= 0; i--)
                {
                    if ([[_primeArray objectAtIndex:i] isKindOfClass:[ACUser class]])
                    {
                        offset ++;
                    }
                    else
                    {
                        break;
                    }
                }
                [[ACNetCenter shareNetCenter] getContactPersonSinglePersonListWithGroupID:groupID withOffset:offset withLimit:kLimit  withCR:_groupCr];
            }
        });
    }
}

#pragma mark -searchBar

-(void)searchContactListWithKeyOnSearchButtonClicked:(BOOL)bOnSearchButtonClicked{
    NSString*   groupIDs = nil;
    NSString*   pCRs    =   nil;
    
    BOOL    canSearchInCR   =   [ACConfigs shareConfigs].canSearchInCR; //允许搜索 Releation
    if(ChooseContactType_Root==_chooseContactType){
        NSMutableString* pGroupIDsBuffer = [[NSMutableString alloc] init];
        NSMutableString* pCRsBuffer = [[NSMutableString alloc] init];
        
        for(ACUserGroup *userGroup in _primeArray){
            if(userGroup.cr){
                [pCRsBuffer appendFormat:@"%@_%@,",userGroup.cr,userGroup.groupID];
            }
            else{
                [pGroupIDsBuffer appendFormat:@"%@,",userGroup.groupID];
            }
        }
        
        if(pGroupIDsBuffer.length){
            [pGroupIDsBuffer deleteCharactersInRange:NSMakeRange(pGroupIDsBuffer.length-1, 1)];
        }
        
        groupIDs    =   pGroupIDsBuffer;
        
        if(canSearchInCR){
            if(pCRsBuffer.length>0){
                [pCRsBuffer deleteCharactersInRange:NSMakeRange(pCRsBuffer.length-1, 1)];
            }
            pCRs    =   pCRsBuffer;
        }
    }
    else{
        groupIDs    =   _groupID;
        if(nil==groupIDs){
            ACUserGroup *userGroup = [_primeArray lastObject];
            groupIDs = userGroup.groupID;
        }
        
        if(_groupCr&&canSearchInCR){
            pCRs    =   [NSString stringWithFormat:@"%@_%@",_groupCr,groupIDs];
            groupIDs = nil;
        }
    }
    
    if(bOnSearchButtonClicked){
        [_searchArray removeAllObjects];
        _searchContactListWithKey_FuncType = searchContactListWithKey_FuncType_Nouse;
        _searchText = _searchBar.text;
        [[ACNetCenter shareNetCenter] searchContactListWithKey:_searchText
                                                    withOffset:0
                                                     withLimit:kLimit
                                                  withGroupIDs:groupIDs
                                                       withCRs:pCRs
                                                  withFunctype:searchContactListWithKey_FuncType_GetCount];
    }
    else{
        [[ACNetCenter shareNetCenter] searchContactListWithKey:_searchText
                                                    withOffset:(int)([_searchArray count] +(_selfIsHadDelete?1:0))
                                                     withLimit:kLimit
                                                  withGroupIDs:groupIDs
                                                       withCRs:pCRs
                                                  withFunctype:_searchContactListWithKey_FuncType];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    if (![ASIHTTPRequest isValidNetWork])
    {
        [_contentView showProgressHUDNoActivityWithLabelText:NSLocalizedString(@"Network_Failed", nil) withAfterDelayHide:0.8];
        return;
    }
    _isCanLoadMore = YES;
//    NSString *groupID = _groupID;
//    if ([groupID length] == 0)
//    {
//        ACUserGroup *userGroup = [_primeArray lastObject];
//        groupID = userGroup.groupID;
//    }
    [_contentView showProgressHUDWithLabelText:NSLocalizedString(@"Searching", nil) withAnimated:YES];
    [self searchContactListWithKeyOnSearchButtonClicked:YES];
    _dataSourceArray = _searchArray;
    [_mainTableView reloadData];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    _isCanLoadMore = _isHaveMore;
    if (!_isCanLoadMore)
    {
        if ([_refreshView superview] != nil)
        {
            _refreshView.delegate = nil;
            //下拉刷新的控件添加在tableView上
            [_refreshView removeFromSuperview];
        }
    }
    else
    {
        if ([_refreshView superview] == nil)
        {
            _refreshView.delegate = self;
            [_mainTableView addSubview:_refreshView];
        }
    }
    
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    [_searchArray removeAllObjects];
    _dataSourceArray = _primeArray;
    [_mainTableView reloadData];
    [_mainTableView setContentOffset:CGPointMake(0, 0)];
    
    NSObject *obj = [_primeArray lastObject];
    if ([obj isKindOfClass:[ACUser class]])
    {
        _loadMoreType = LoadMoreType_Single;
    }
    else
    {
        _loadMoreType = LoadMoreType_SubGroup;
    }
    
    if (_isCanLoadMore)
    {
        [self setRefreshViewFrame];
    }
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length] == 0)
    {
        [self searchBarCancelButtonClicked:searchBar];
    }
}

#pragma mark -IBAction
-(IBAction)enterButtonTouchUp:(id)sender
{
    if (_addParticipant == ACAddParticipantType_New)
    {
        if ([_selectedUserGroupArray count] == 0 && [_selectedUserArray count] == 1)
        {
            [ACNetCenter shareNetCenter].createTopicEntityVC = self;
            NSMutableArray *selectedUserArray = [NSMutableArray arrayWithCapacity:[_selectedUserArray count]];
            for (ACUser *user in _selectedUserArray)
            {
                [selectedUserArray addObject:user.userid];
            }
            [[ACNetCenter shareNetCenter] createTopicEntityWithChatType:cSingleChat withTitle:nil withGroupIDArray:nil withUserIDArray:selectedUserArray exMap:nil];
            [_contentView showNetLoadingWithAnimated:NO];
//            [_contentView showProgressHUDWithLabelText:nil withAnimated:NO];
        }
        else if ([_selectedUserGroupArray count]+[_selectedUserArray count] != 0)
        {
            [self createChatGroupVC];
        }
    }
    else if (_addParticipant == ACAddParticipantType_AddToCurrent)
    {
        if ([_selectedUserGroupArray count] > 0|| [_selectedUserArray count] > 0)
        {
            NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
            [nc removeObserver:self name:kNetCenterAddParticipantNotifation object:nil];
            [nc removeObserver:self name:kNetCenterErrorAuthorityChangedFailed_1248 object:nil];
            
            [nc addObserver:self selector:@selector(addParticipant:) name:kNetCenterAddParticipantNotifation object:nil];            
            [nc addObserver:self selector:@selector(errorAuthorityChangedFailed_1248_For_addParticipant:) name:kNetCenterErrorAuthorityChangedFailed_1248 object:nil];

            
            NSMutableArray *selectedUserArray = [NSMutableArray arrayWithCapacity:[_selectedUserArray count]];
            for (ACUser *user in _selectedUserArray)
            {
                [selectedUserArray addObject:user.userid];
            }
            
            NSMutableArray *selectedUserGroupArray = [NSMutableArray arrayWithCapacity:[_selectedUserGroupArray count]];
            for (ACUserGroup *usergroup in _selectedUserGroupArray)
            {
                [selectedUserGroupArray addObject:usergroup.groupID];
            }
            [[ACNetCenter shareNetCenter] addParticipantToCurrentEntity:_addPaticipantEntity withGroupIDArray:selectedUserGroupArray withUserIDArray:selectedUserArray];
            [_contentView showNetLoadingWithAnimated:NO];
//            [_contentView showProgressHUDWithLabelText:nil withAnimated:NO];
        }
    }
    else if (_addParticipant == ACAddParticipantType_SingleChatAddToNew)
    {
        if ([_selectedUserGroupArray count] > 0|| [_selectedUserArray count] > 0)
        {
            if ([_singleChatCurrentUserID length] > 0)
            {
                ACUser *user = [ACUserDB getUserFromDBWithUserID:_singleChatCurrentUserID];
                [self.selectedUserArray addObject:user];
                [self createChatGroupVC];
            }
        }
    }
}

-(IBAction)cancelButtonTouchUp:(id)sender
{
    [self searchBarCancelButtonClicked:_searchBar];
}

- (IBAction)selectAll:(id)sender {
    
}

#pragma mark -addParticipant


-(void)errorAuthorityChangedFailed_1248_For_addParticipant:(NSNotification *)noti{
    [self cancelButton:nil];
}

-(void)addParticipant:(NSNotification *)noti
{
    Class ACNotesMsgVC_Main_Class = [ACNotesMsgVC_Main class];
    Class ACUrlEditViewController_Class = [ACUrlEditViewController class];
    
    NSArray *viewControllers = [self.navigationController viewControllers];
    for (int i = (int)[viewControllers count]-1;i > 0; i--)
    {
        UIViewController *vc = [viewControllers objectAtIndex:i];
        if([vc isKindOfClass:ACNotesMsgVC_Main_Class]||[vc isKindOfClass:ACUrlEditViewController_Class])
        {
            [self.navigationController ACpopToViewController:vc animated:YES];
            break;
        }
    }
}

-(void)createChatGroupVC
{
    ACCreateChatGroupViewController *createChatGroupVC = [[ACCreateChatGroupViewController alloc] init];
//    createChatGroupVC.superVC = self;
    AC_MEM_Alloc(createChatGroupVC);
    [createChatGroupVC prepareSelectedUsers:self.selectedUserArray
                              andUserGroups:self.selectedUserGroupArray
                         withAddParticipant:_addParticipant];
    createChatGroupVC.transmitVC = self.transmitVC;
    if(_transmitVC&&_transmitVC.isForVideoAudioCall){
        //直接创建分组，使用缺省设置
        [createChatGroupVC createTopicEntityWithNoShowVC];
        return;
    }
    [self.navigationController pushViewController:createChatGroupVC animated:YES];
}

-(IBAction)cancelButton:(id)sender
{
    if(_cancelToViewController){
        [self.navigationController ACpopToViewController:_cancelToViewController animated:YES];
    }
    else{
        [self.navigationController ACpopViewControllerAnimated:YES];
    }
}

-(IBAction)returnViewController:(id)sender
{
    [self.navigationController ACpopViewControllerAnimated:YES];
//    if (_chooseContactType == ChooseContactType_Root)
//    {
//        [self.navigationController ACpopViewControllerAnimated:YES];
//    }
//    else if (_chooseContactType == ChooseContactType_ParticipantGroup)
//    {
//        [self.navigationController ACpopViewControllerAnimated:YES];
//    }
//    else
//    {
//        NSArray *viewControllers = [self.navigationController viewControllers];
//        for (int i = (int)[viewControllers count]-1; i > 0; i--)
//        {
//            UIViewController *vc = [viewControllers objectAtIndex:i];
//            if ([vc isKindOfClass:[ACGroupInfoViewController class]])
//            {
//                [self.navigationController ACpopToViewController:vc animated:YES];
//                break;
//            }
//            else if ([vc isKindOfClass:[ACChatViewController class]])
//            {
//                [self.navigationController ACpopToViewController:vc animated:YES];
//                break;
//            }
//        }
//    }
}

/*
-(NSString*)getDefaultGroupTitle{ //取得缺省创建聊天的标题
    int count = 0;
    int currentCount = (int)([_selectedUserGroupArray count]+[_selectedUserArray count]);
    int maxCount = currentCount>2?2:currentCount;
    NSString *placeholder = @"";
    for (ACUserGroup *userGroup in _selectedUserGroupArray)
    {
        placeholder = [placeholder stringByAppendingString:userGroup.name];
        count++;
        if (count == maxCount)
        {
            if (currentCount > 2)
            {
                placeholder = [placeholder stringByAppendingString:@"..."];
            }
            break;
        }
        else
        {
            placeholder = [placeholder stringByAppendingString:@","];
        }
    }
    if (count < maxCount)
    {
        for (ACUser *user in _selectedUserArray)
        {
            placeholder = [placeholder stringByAppendingFormat:@"%@",user.name];
            count++;
            if (count == maxCount)
            {
                if (currentCount > 2)
                {
                    placeholder = [placeholder stringByAppendingString:@"..."];
                }
                break;
            }
            else
            {
                placeholder = [placeholder stringByAppendingString:@","];
            }
        }
    }
    return placeholder;
}
*/
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
