//
//  ACNoteListVC_Base.m
//  chat
//
//  Created by Aculearn on 14/12/18.
//  Copyright (c) 2014年 Aculearn. All rights reserved.
//

#import "ACNoteListVC_Base.h"
#import "UIView+Additions.h"
#import "ACConfigs.h"
#import "ACNoteListVC_Cell.h"
#import "ACContributeViewController.h"
#import "UINavigationController+Additions.h"
#import "ACMessageDB.h"
#import "ACNetCenter.h"
#import "ACAddress.h"
#import "ACNoteDetailVC.h"

//#import "ACNoteCommentCell.h"


//NSString *const kScrollFinishedNotification = @"kScrollFinishedNotification";



@implementation ACNoteListVC_Base



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _notesSourceArray = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)viewDidLoad{
    

    self.bNotNeedRefreshHead = ACNoteListVC_Type_WallBoard_List==_nListType||
                                ACNoteListVC_Type_SearchResult==_nListType;
    
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self initHotspot];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initHotspot];
}


//-(void)setTopicEntity:(ACTopicEntity*)topicEntity{
//    _topicEntity    =   topicEntity;
//    _topicEntityTitle   =   _topicEntity.showTitle;
//}


/*
#pragma mark -scrollViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_isHadLoadMore)
    {
        [_refreshView egoRefreshScrollViewDidScroll:scrollView];
    }
    //    _isScrolling = YES;
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (_isHadLoadMore)
    {
        [_refreshView egoRefreshScrollViewDidEndDragging:scrollView];
    }
    //    if (decelerate == NO)
    //    {
    //        if (_isScrolling)
    //        {
    //            _isScrolling = NO;
    //            [[NSNotificationCenter defaultCenter] postNotificationName:kScrollFinishedNotification object:nil];
    //        }
    //    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //    if (_isScrolling)
    //    {
    //        _isScrolling = NO;
    //        [[NSNotificationCenter defaultCenter] postNotificationName:kScrollFinishedNotification object:nil];
    //    }
}


#pragma mark -loadMoreRefreshView
-(void)setRefreshViewFrame
{
    //如果contentsize的高度比表的高度小，那么就需要把刷新视图放在表的bounds的下面
    int height = MAX(self.mainTableView.bounds.size.height, self.mainTableView.contentSize.height);
    _refreshView.frame =CGRectMake(0.0f, height, _contentView.size.width, self.mainTableView.bounds.size.height);
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


-(void)loadNotesMessage{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSInteger count = [self loadNotesMessageFunc];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_refreshView egoRefreshScrollViewDataSourceDidFinishedLoading:self.mainTableView];
            [self.mainTableView reloadData];
            [self setRefreshViewFrame];
        });
        
        if (!_reloading)
        {
            [self.mainTableView setContentOffset:CGPointMake(0, 0)];
            _refreshView.delegate = self;
            //下拉刷新的控件添加在tableView上
            [self.mainTableView addSubview:_refreshView];
        }
        else
        {
            _reloading = NO;
        }
        if (count < kLoadMoreLimit)
        {
            _refreshView.delegate = nil;
            //下拉刷新的控件添加在tableView上
            [_refreshView removeFromSuperview];
            _isHadLoadMore = NO;
        }
        else
        {
            _isHadLoadMore = YES;
        }
    });
}

-(void)loadMore{
    _reloading = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self loadNotesMessage];
    });
}
 */

-(void)onNewNoteMessge{
    ACContributeViewController *contributeVC = [[ACContributeViewController alloc] initForWallBoard:ACNoteListVC_Type_WallBoard_List==_nListType withSuperVC:self];
    [self ACpresentViewController:contributeVC animated:YES completion:nil];
}

-(void)onDeleteNote:(NSIndexPath*)pIndexPath{
    NSAssert(ACNoteListVC_Type_Note_List==_nListType,@"onDeleteNote 只能用于 NoteList");
    if(ACNoteListVC_Type_Note_List==_nListType){
        [self.notesSourceArray removeObjectAtIndex:pIndexPath.row];
        [self.mainTableView deleteRowsAtIndexPaths:@[pIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

-(void)OnUpdateNote:(NSIndexPath*)pIndexPath{
    NSAssert(ACNoteListVC_Type_WallBoard_List!=_nListType,@"OnUpdateNote 不能用于 WallBoard");
    if(ACNoteListVC_Type_WallBoard_List!=_nListType){
        [self.mainTableView reloadRowsAtIndexPaths:@[pIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}




#pragma mark -UITableViewDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_notesSourceArray count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACNoteObject* pNoteObj =    _notesSourceArray[indexPath.row];
    ACNoteListVC_Cell* cell = [ACNoteListVC_Cell loadCellFromTable:tableView withSuperVC:self];
    if(pNoteObj.isNoteMessage){
        [cell setNoteMessage:(ACNoteMessage*)pNoteObj
                   forDetail:NO
             forTimeLineList:ACNoteListVC_Type_TimeLine_List==_nListType
                   withTopic:_topicEntity];
    }
    else{
        NSAssert([pNoteObj isKindOfClass:[ACNoteComment class]],@"pNoteObj Type");
        [cell setNoteComment:(ACNoteComment*)pNoteObj];
    }
    return cell;

//    ACNoteCommentCell* cell =   [ACNoteCommentCell loadCellFromTable:tableView];
//    cell.noteComment = (ACNoteComment*)pNoteObj;
//    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACNoteObject* pNoteObj =    _notesSourceArray[indexPath.row];
    if(pNoteObj.isNoteMessage){
         return [ACNoteListVC_Cell getCellHeightWithNoteMessage:(ACNoteMessage*)pNoteObj forDetail:NO];
    }
    return [ACNoteListVC_Cell getCellHeightWithNoteComment:(ACNoteComment*)pNoteObj];
    
//    return [ACNoteCommentCell getNoteCommentHight:(ACNoteComment*)pNoteObj];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ACNoteObject* pNoteObj =    _notesSourceArray[indexPath.row];
    NSAssert(pNoteObj.isNoteMessage,@"ACNoteListVC_Base didSelectRowAtIndexPath");
    [ACNoteDetailVC showNoteMsg:(ACNoteMessage*)pNoteObj
                  withIndexPath:indexPath
                   inNoteListVC:self];
    /*
    ACNoteDetailVC* noteDetailVC    =      [[ACNoteDetailVC alloc] init];
    noteDetailVC.noteMessage    =   (ACNoteMessage*)pNoteObj;
    noteDetailVC.noteIndexPath  =   indexPath;
    noteDetailVC.superVC    =   self;
    [self.navigationController pushViewController:noteDetailVC animated:YES];*/
}

@end
