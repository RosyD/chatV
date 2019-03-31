//
//  ACWallBoardViewController.m
//  chat
//
//  Created by 王方帅 on 14-6-1.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACWallBoardViewController.h"
#import "UIView+Additions.h"
#import "ACConfigs.h"
#import "ACNoteListVC_Cell.h"
#import "ACContributeViewController.h"
#import "UINavigationController+Additions.h"
#import "ACMessageDB.h"
#import "ACNetCenter.h"
#import "ACAddress.h"


@interface ACWallBoardViewController (){
    NSMutableArray* _pWallboardNotes;
}

@end

@implementation ACWallBoardViewController

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
    self.nListType  =   ACNoteListVC_Type_WallBoard_List; //必须放在这里
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //    _wallBoardSourceData    =   [[NSMutableArray alloc] init];
    
    if (![ACConfigs isPhone5])
    {
        [self.mainTableView setFrame_height:self.mainTableView.size.height-88];
        [_contributeView setFrame_y:[self.mainTableView getFrame_Bottom]];
        [self.contentView setFrame_height:[_contributeView getFrame_Bottom]];
    }
    
    [_contributeButton setBackgroundImage:[[UIImage imageNamed:@"linenote_write_btn01.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:17] forState:UIControlStateNormal];
    [_contributeButton setBackgroundImage:[[UIImage imageNamed:@"linenote_write_btn02.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:17] forState:UIControlStateHighlighted];
    [_contributeButton setTitle:@"Post" forState:UIControlStateNormal];
    
    _pWallboardNotes   =    [[NSMutableArray alloc] init];
    
    [self LoadDataFunc];
}


#pragma mark 加载信息

-(void)LoadDataFunc{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        double createTime = 0;
        if (ACTableViewVC_Base_RefreshType_Tail==self.nRefreshType&&
            _pWallboardNotes.count){
            createTime = ((ACWallBoard_Message *)_pWallboardNotes[_pWallboardNotes.count-1]).createTime;
        }
        
        NSMutableArray *array = [ACMessageDB getWallBoardMessageListFromDBWithLastCreateTime:createTime limit:20];
        
        if (array.count){
            [_pWallboardNotes addObjectsFromArray:array];
            [self getShowNoteMessage];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self LoadDataFuncEnd_WithCount:array.count];
        });
    });
}

-(void)getShowNoteMessage{
    //反向排列
//    NSInteger nPos =    _pWallboardNotes.count-1;
    [self.notesSourceArray  removeAllObjects];
    for (ACWallBoard_Message* pWB_Msg in  _pWallboardNotes){
        [self.notesSourceArray addObject:pWB_Msg.messageContent];
    }
//    while (nPos>=0) {
//        ACWallBoard_Message* pWB_Msg = _pWallboardNotes[nPos];
//        [self.notesSourceArray addObject:pWB_Msg.messageContent];
//        nPos --;
//    }
}

-(void)sendNoteMessageSuccess:(id)message
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        _pWallboardNotes = [ACMessageDB getWallBoardMessageListFromDBWithLastCreateTime:0 limit:kLoadMoreLimit];
        [self getShowNoteMessage];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.mainTableView reloadData];
            if (self.notesSourceArray.count){
                [self scrollToIndex:0 animated:NO];
            }
        });
    });
}

-(void)hotspotStateChange:(NSNotification *)noti
{
    if (self.isOpenHotspot)
    {
        [self.mainTableView setFrame_height:self.mainTableView.size.height-hotsoptHeight];
        [_contributeView setFrame_y:_contributeView.origin.y-hotsoptHeight];
        [self.contentView setFrame_height:self.contentView.size.height-hotsoptHeight];
    }
    else
    {
        [self.mainTableView setFrame_height:self.mainTableView.size.height+hotsoptHeight];
        [_contributeView setFrame_y:_contributeView.origin.y+hotsoptHeight];
        [self.contentView setFrame_height:self.contentView.size.height+hotsoptHeight];
    }
}


#pragma mark -IBAction
-(IBAction)contributeButtonTouchUp:(id)sender
{
    [self onNewNoteMessge];
}

-(IBAction)goback:(id)sender
{
    [self.navigationController ACpopViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
