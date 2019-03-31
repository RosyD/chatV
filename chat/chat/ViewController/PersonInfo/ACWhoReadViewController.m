//
//  ACWhoReadViewController.m
//  AcuCom
//
//  Created by 王方帅 on 14-5-18.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACWhoReadViewController.h"
#import "ACWhoReadTableViewCell.h"
#import "UIView+Additions.h"
#import "ACNetCenter.h"
#import "UINavigationController+Additions.h"
#import "ACParticipantInfoViewController.h"
#import "ACEntity.h"

@interface ACWhoReadViewController ()

@end

@implementation ACWhoReadViewController

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
    _titleLabel.text = NSLocalizedString(@"Who_Read", nil);
//    [_backButton setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateNormal];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hadReadListNoti:) name:kNetCenterGetHadReadListNotifation object:nil];
    [_contentView showNetLoadingWithAnimated:NO];
    [[ACNetCenter shareNetCenter] getHadReadListWithTopicEntityID:_topicEntityID seq:_seq];
    if (![ACConfigs isPhone5])
    {
        [_mainTableView setFrame_height:_mainTableView.size.height-88];
        [_contentView setFrame_height:_contentView.size.height-88];
    }
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
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

#pragma mark -notification
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
        [_contentView setFrame_height:_contentView.size.height-hotsoptHeight];
    }
}

-(void)hadReadListNoti:(NSNotification *)noti
{
    [_contentView hideProgressHUDWithAnimated:NO];
    NSMutableArray *array = noti.object;
    self.dataSourceArray = array;
    [_mainTableView reloadData];
}

#pragma mark -IBAction
-(IBAction)goback:(id)sender
{
    [self.navigationController ACpopViewControllerAnimated:YES];
}

#pragma mark -UITableViewDelegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACWhoReadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACWhoReadTableViewCell" owner:nil options:nil];
        cell = [nib objectAtIndex:0];
    }
    if (indexPath.row < [_dataSourceArray count])
    {
        [cell setUser:[_dataSourceArray objectAtIndex:indexPath.row]];
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_dataSourceArray count];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    ACParticipantInfoViewController *participantInfoVC = [[ACParticipantInfoViewController alloc] initWithUser:(ACUser *)[_dataSourceArray objectAtIndex:indexPath.row]];
    AC_MEM_Alloc(participantInfoVC);
    participantInfoVC.topicEntity = self.topicEntity;
    [self.navigationController pushViewController:participantInfoVC animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
