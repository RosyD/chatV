//
//  ACNoteDetailViewController.m
//  chat
//
//  Created by 王方帅 on 14-6-3.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACNoteDetailViewController.h"
#import "ACNoteDetail_ImgOrVideo_Cell.h"
#import "UINavigationController+Additions.h"
#import "ACMapBrowerViewController.h"
#import "ACDataCenter.h"
#import "ACAddress.h"
#import "ACNoteListVC_Base.h"
#import "ACWallBoardViewController.h"

@interface ACNoteDetailViewController ()

@end

@implementation ACNoteDetailViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    
    
    NSString *dateString = [[ACDataCenter shareDataCenter] getDateStringWithTimeInterval:_noteMessage.createTime/1000];
    NSString *timeString = [[ACDataCenter shareDataCenter] getTimeStringWithTimeInterval:_noteMessage.createTime/1000];
    _createTimeLabel.text = [dateString stringByAppendingFormat:@" %@",timeString];
    
    [_contentLabel setFrame_y:[_createTimeLabel getFrame_Bottom]+8];
    _contentLabel.text = _noteMessage.content;
    [_contentLabel setAutoresizeWithLimitWidth:294];
    
    UIView *currentView = _contentLabel;
    if (_noteMessage.location)
    {
        [_locationView setHidden:NO];
        [_locationView setFrame_y:[_contentLabel getFrame_Bottom]+8];
        _locationLabel.text = _noteMessage.location.address;
        [_locationLabel setAutoresizeWithLimitWidth:266];
        currentView = _locationView;
    }
    else
    {
        [_locationView setHidden:YES];
    }
    
    if(_noteMessage.categoryIDForWallBoard){
/*TXB 暂时不适用
        NSArray *categoryArray = g__pAcNoteListVC.topicEntity.categoriesArray;
        _categoryLabel.text = nil;
        for (ACCategory *category in categoryArray)
        {
            if ([category.cid isEqualToString:_noteMessage.categoryIDForWallBoard])
            {
                _categoryLabel.text = [NSString stringWithFormat:@"%@ : %@",NSLocalizedString(@"Category", nil),category.name];
                break;
            }
        }
        if (_categoryLabel.text != nil)
        {
            [_categoryLabel setFrame_y:[currentView getFrame_Bottom]+8];
            [_categoryLabel setAutoresizeWithLimitWidth:_categoryLabel.size.width];
            currentView = _categoryLabel;
        }
        else
        {
            [_categoryLabel setHidden:YES];
        }*/
    }
    else{
        [_categoryLabel setHidden:YES];
    }
    
    [_tableHeaderView setFrame_height:[currentView getFrame_Bottom]+8];
    _mainTableView.tableHeaderView = _tableHeaderView;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(videoHasFinishedPlaying:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
    
/*TXB    if ([g__pAcNoteListVC isKindOfClass:[ACWallBoardViewController class]])
    {
        [_noteButton setHidden:YES];
    }
*/ 
    
    if (![ACConfigs isPhone5])
    {
        [_mainTableView setFrame_height:_mainTableView.size.height-88];
        [_contentView setFrame_height:[_mainTableView getFrame_Bottom]];
    }
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


#pragma mark --hotspotStateChange:hotspotStateChange:

-(void)hotspotStateChange:(NSNotification *)noti
{
    if (_isOpenHotspot)
    {
        [_mainTableView setFrame_height:_mainTableView.size.height-hotsoptHeight];
        [_contentView setFrame_height:_contentView.size.height-hotsoptHeight];
    }
    else
    {
        [_mainTableView setFrame_height:_mainTableView.size.height+hotsoptHeight];
        [_contentView setFrame_height:_contentView.size.height+hotsoptHeight];
    }
}

#pragma mark -IBAction
-(IBAction)goback:(id)sender
{
    [self.navigationController ACpopViewControllerAnimated:YES];
}

-(IBAction)noteButtonTouchUp:(id)sender
{
    [self.navigationController ACpopViewControllerAnimated:NO];
/*TXB
    不知道是做什么的
    ACWallBoardViewController *notesVC = [[ACWallBoardViewController alloc] init];
    notesVC.topicEntity = ((ACWallBoardViewController *)_superVC).topicEntity;
    notesVC.dataSourceArray = ((ACWallBoardViewController *)_superVC).dataSourceArray;
    [((ACWallBoardViewController *)_superVC).navigationController pushViewController:notesVC animated:YES];
 */
}

-(IBAction)locationButtonTouchUp:(id)sender
{
    ACMapBrowerViewController *mapBrowserVC = [[ACMapBrowerViewController alloc] init];
    mapBrowserVC.coordinate = _noteMessage.location.Location;
    [self ACpresentViewController:mapBrowserVC animated:YES completion:nil];
}

#pragma mark UITableViewDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_noteMessage.imgs_Videos_List count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACNoteDetail_ImgOrVideo_Cell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACNoteDetail_ImgOrVideo_Cell"];
    if (!cell)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACNoteDetail_ImgOrVideo_Cell" owner:nil options:nil];
        cell = [nib objectAtIndex:0];
    }
    [cell setPage:_noteMessage index:(int)indexPath.row withSuperVC:_];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACNoteContentImageOrVideo *page = [_noteMessage.imgs_Videos_List objectAtIndex:indexPath.row];
    
    if (page.bIsImage)
    {
        return page.height/2+10;
    }
    else
    {
        return page.height+10;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
