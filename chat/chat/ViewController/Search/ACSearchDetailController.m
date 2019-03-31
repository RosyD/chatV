//
//  ACSearchDetailController.m
//  chat
//
//  Created by 王方帅 on 14-7-8.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACSearchDetailController.h"
#import "ACSearchDetailCell.h"
#import "UINavigationController+Additions.h"
#import "ACNetCenter.h"
#import "ACParticipantInfoViewController.h"
#import "ACCreateChatGroupViewController.h"
#import "ACChooseContactViewController.h"
#import "ACChatMessageViewController.h"
#import "ACDataCenter.h"
#import "ACMessage.h"
#import "ACNoteSearchResultVC.h"

#define kLimit  20

@interface ACSearchDetailController (){
    NSArray     *_selectedUserGroupArray;
}

@end

@implementation ACSearchDetailController

AC_MEM_Dealloc_implementation


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    if (![ACConfigs isPhone5])
    {
        [_mainTableView setFrame_height:_mainTableView.size.height-88];
        [_contentView setFrame_height:_contentView.size.height-88];
    }
    
    _reloading = NO;
    _isCanLoadMore = YES;
    _isFirstLoad = YES;
    if (_searchDetailType == ACSearchDetailType_Chat||_searchDetailType == ACSearchDetailType_Note)
    {
        [[ACNetCenter shareNetCenter] searchMessage_Note:_searchDetailType == ACSearchDetailType_Note withKey:_searchKey offset:0 limit:kLimit];
        if(_searchDetailType == ACSearchDetailType_Chat){
            [nc addObserver:self selector:@selector(searchMessage:) name:kNetCenterSearchMessageNotifation object:nil];
            _titleLabel.text = NSLocalizedString(@"Search message result", nil);
        }
        else{
            [nc addObserver:self selector:@selector(searchNote:) name:kNetCenterSearchNoteNotifation object:nil];
            _titleLabel.text = NSLocalizedString(@"Search note result", nil);
        }
    }
    else if (_searchDetailType == ACSearchDetailType_User||_searchDetailType == ACSearchDetailType_AccountUser)
    {
        [[ACNetCenter shareNetCenter] searchUserWithKey:_searchKey offset:0 limit:kLimit forAccount:ACSearchDetailType_AccountUser==_searchDetailType];
        [nc addObserver:self selector:@selector(searchUser:) name:kNetCenterSearchUserNotifation object:nil];
        _titleLabel.text = NSLocalizedString(@"Search user result", nil);
    }
    else if (_searchDetailType == ACSearchDetailType_UserGroup)
    {
        [[ACNetCenter shareNetCenter] searchUserGroupWithKey:_searchKey offset:0 limit:kLimit];
        [nc addObserver:self selector:@selector(searchUserGroup:) name:kNetCenterSearchUserGroupNotifation object:nil];
//        _selectedUserArray = [[NSMutableArray alloc] init];
//        _selectedUserGroupArray = [[NSMutableArray alloc] init];
        _titleLabel.text = NSLocalizedString(@"Search user group result", nil);
    }
    else if (_searchDetailType == ACSearchDetailType_Note)
    {
        [[ACNetCenter shareNetCenter] searchUserGroupWithKey:_searchKey offset:0 limit:kLimit];
        [nc addObserver:self selector:@selector(searchUserGroup:) name:kNetCenterSearchUserGroupNotifation object:nil];
        //        _selectedUserArray = [[NSMutableArray alloc] init];
        //        _selectedUserGroupArray = [[NSMutableArray alloc] init];
        _titleLabel.text = NSLocalizedString(@"Search note result", nil);
    }

    //refreshView
    _refreshView = [[EGORefreshTableFooterView alloc]  initWithFrame:CGRectZero];
    
    [_contentView showNetLoadingWithAnimated:NO];
}

#pragma mark ---loadMore
-(void)loadMoreReload
{
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
    
    if (!_reloading)
    {
        [_mainTableView setContentOffset:CGPointMake(0, 0)];
        if (_isCanLoadMore)
        {
            _refreshView.delegate = self;
            //下拉刷新的控件添加在tableView上
            [_mainTableView addSubview:_refreshView];
        }
    }
    else
    {
        _reloading = NO;
        [_refreshView egoRefreshScrollViewDataSourceDidFinishedLoading:_mainTableView];
    }
    if (_isCanLoadMore)
    {
        [self setRefreshViewFrame];
    }
}

#pragma mark -NSNotification
-(void)_loadDataWithData:(NSMutableArray*)array{
    if (_isFirstLoad){
        _isFirstLoad = NO;
        self.dataSourceArray = array;
    }
    else{
        [self.dataSourceArray addObjectsFromArray:array];
    }

    if ([array count] < kLimit){
        _isCanLoadMore = NO;
    }
    [_mainTableView reloadData];
    [self loadMoreReload];
    
    [_contentView hideProgressHUDWithAnimated:NO];
}

-(void)searchMessage:(NSNotification *)noti
{
    NSDictionary *msgAndEntityDic = noti.object;
    if (_isFirstLoad){
        self.searchTopicEntityArray = [msgAndEntityDic objectForKey:kTes];
    }
    else{
        [self.searchTopicEntityArray addObjectsFromArray:[msgAndEntityDic objectForKey:kTes]];
    }
    [self _loadDataWithData:[msgAndEntityDic objectForKey:kTopics]];
 }

-(void)searchNote:(NSNotification *)noti{
    [self _loadDataWithData:noti.object];
}

-(void)searchUser:(NSNotification *)noti{
    [self _loadDataWithData:noti.object];
}

-(void)searchUserGroup:(NSNotification *)noti{
    [self _loadDataWithData:noti.object];
}

#pragma mark -tableViewDelegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACSearchDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACSearchDetailCell"];
    if (!cell)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACSearchDetailCell" owner:nil options:nil];
        cell = [nib objectAtIndex:0];
    }
    [cell setDataObject:[_dataSourceArray objectAtIndex:indexPath.row] superVC:self];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_dataSourceArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [ACSearchDetailCell getCellHeightWithDataObject:[_dataSourceArray objectAtIndex:indexPath.row]];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSObject *obj = [_dataSourceArray objectAtIndex:indexPath.row];
    if (_searchDetailType == ACSearchDetailType_Chat){
        ACMessage *message = (ACMessage *)obj;
        BOOL isDelete = YES;
        ACTopicEntity *entity = nil;
        
        @synchronized([ACDataCenter shareDataCenter].topicEntityArray){
            for (int i = 0; i < [[ACDataCenter shareDataCenter].topicEntityArray count]; i++){
                ACTopicEntity *topicEntity = [[ACDataCenter shareDataCenter].topicEntityArray objectAtIndex:i];
                if ([topicEntity.entityID isEqualToString:message.topicEntityID]){
                    entity = topicEntity;
                    isDelete = NO;
                    break;
                }
            }
        }
        if (entity == nil){
            entity = [[ACTopicEntity alloc] init];
            entity.entityID = message.topicEntityID;
            entity.title = message.topicEntityTitle;
            entity.entityType = EntityType_Topic;
            entity.lastestSequence = message.seq+4;
            entity.isDeleted = message.isDeleted;
        }
//        if (entity == nil)
//        {
//            @synchronized(self.searchTopicEntityArray)
//            {
//                for (ACTopicEntity *topicEntity in self.searchTopicEntityArray)
//                {
//                    if ([topicEntity.entityID isEqualToString:message.topicEntityID])
//                    {
//                        entity = topicEntity;
//                        break;
//                    }
//                }
//            }
//        }
        
        if (entity){
            ACChatMessageViewController *chatMessageVC = [[ACChatMessageViewController alloc] initWithSuperVC:self withTopicEntity:entity andSearchSequence:message.seq];
//            chatMessageVC.topicEntity = entity;
            AC_MEM_Alloc(chatMessageVC);
            NSAssert(ACMessageVCType_Search==chatMessageVC.messageVCType,@"ACMessageVCType_Search==chatMessageVC.messageVCType");
//            chatMessageVC.messageVCType = ACMessageVCType_Search;
//            chatMessageVC.searchSequence = message.seq;
            chatMessageVC.searchKey = _searchKey;
            chatMessageVC.isSearchDelete = isDelete;
//            [chatMessageVC preloadDB];
            [self.navigationController pushViewController:chatMessageVC animated:YES];
        }
        else{
            AC_ShowTip(NSLocalizedString(@"Can't find this group", nil));
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Can't find this group", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
//            [alert show];
        }
    }
    else if (_searchDetailType == ACSearchDetailType_User||
             _searchDetailType == ACSearchDetailType_AccountUser)
    {
        ACParticipantInfoViewController *participantInfoVC = [[ACParticipantInfoViewController alloc] initWithUser:(ACUser *)obj];
        AC_MEM_Alloc(participantInfoVC);
        [self.navigationController pushViewController:participantInfoVC animated:YES];
    }
    else if (_searchDetailType == ACSearchDetailType_UserGroup)
    {
//        ACUserGroup *userGroup = (ACUserGroup *)obj;
//        [_selectedUserGroupArray removeAllObjects];
//        [_selectedUserGroupArray addObject:userGroup];
        
        _selectedUserGroupArray =   @[obj]; //在ACCreateChatGroupViewController中暂用__weak
        ACCreateChatGroupViewController *createChatGroupVC = [[ACCreateChatGroupViewController alloc] init];
        AC_MEM_Alloc(createChatGroupVC);
        [createChatGroupVC prepareSelectedUsers:nil
                                  andUserGroups:_selectedUserGroupArray
                             withAddParticipant:ACAddParticipantType_New];
//        [createChatGroupVC setSuperVC:self];
//        createChatGroupVC.addParticipant = ACAddParticipantType_New;
        [self.navigationController pushViewController:createChatGroupVC animated:YES];
    }
    else if(_searchDetailType==ACSearchDetailType_Note){
        [ACNoteSearchResultVC showSearchResult:(NSDictionary*)obj
                                withSearchText:_searchKey
                                     inSuperVC:self];
    }
}

#pragma mark -scrollViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_isCanLoadMore)
    {
        [_refreshView egoRefreshScrollViewDidScroll:scrollView];
    }
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
            int count = (int)[_dataSourceArray count];
            if (_searchDetailType == ACSearchDetailType_Chat||_searchDetailType == ACSearchDetailType_Note){
                [[ACNetCenter shareNetCenter] searchMessage_Note:_searchDetailType == ACSearchDetailType_Note withKey:_searchKey offset:count limit:kLimit];
            }
            else if (_searchDetailType == ACSearchDetailType_User||_searchDetailType == ACSearchDetailType_AccountUser)
            {
                [[ACNetCenter shareNetCenter] searchUserWithKey:_searchKey offset:count limit:kLimit forAccount:_searchDetailType == ACSearchDetailType_AccountUser];
            }
            else if (_searchDetailType == ACSearchDetailType_UserGroup)
            {
                [[ACNetCenter shareNetCenter] searchUserGroupWithKey:_searchKey offset:count limit:kLimit];
            }
        });
    }
}

#pragma mark -IBAction
-(IBAction)returnViewController:(id)sender
{
    [self.navigationController ACpopViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
