//
//  ACStickerGalleryController.m
//  chat
//
//  Created by 王方帅 on 14-8-14.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACStickerGalleryController.h"
#import "ACStickerPackageCell.h"
#import "UINavigationController+Additions.h"
#import "ACNetCenter.h"
#import "ACStickerCategoryCell.h"
#import "ACMyStickerController.h"
#import "ACChatMessageViewController.h"

#define kAll    @"all"

@interface ACStickerGalleryController ()

@end

@implementation ACStickerGalleryController


AC_MEM_Dealloc_implementation


- (id)initWithSuperVC:(ACChatMessageViewController *)superVC
{
    self = [super init];
    if (self) {
        // Custom initialization
        _superVC = superVC;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _titleLable.text = NSLocalizedString(@"Sticker gallery", nil);
    
    _dataSourceArray = [[NSMutableArray alloc] init];
    _suitCategoryDic = [[NSMutableDictionary alloc] init];
    _selectedCategoryIndex = 0;
    
    if (![ACConfigs isPhone5])
    {
        [_mainTableView setFrame_height:_mainTableView.size.height-88];
    }
    
    CGRect rect = _categoryTableView.frame;
    _categoryTableView.transform = CGAffineTransformMakeRotation(M_PI/-2);
    _categoryTableView.showsVerticalScrollIndicator = NO;
    [_categoryTableView.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
    [_categoryTableView setFrame:rect];
    ///
    [_categoryTableView setFrame_width:kScreen_Width];
    
    [_contentView showNetLoadingWithAnimated:NO];
    _requestReturnCount = 0;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(getCategories:) name:kNetCenterGetCategoriesNotifation object:nil];
    [nc addObserver:self selector:@selector(getAllSuits:) name:kNetCenterGetAllSuitsNotifation object:nil];
    [nc addObserver:self selector:@selector(getSuitsOfCategory:) name:kNetCenterGetSuitsOfCategoryNotifation object:nil];
    [nc addObserver:self selector:@selector(suitDownload:) name:kNetCenterAddAndSuitDownloadNotifation object:nil];
    [nc addObserver:self selector:@selector(suitDownload:) name:kNetCenterSuitDownloadNotifation object:nil];
    [nc addObserver:self selector:@selector(suitProgressUpdate:) name:kNetCenterSuitProgressUpdateNotifition object:nil];
    
    [[ACNetCenter shareNetCenter] getCategories];
    [[ACNetCenter shareNetCenter] getAllSuitsWithOffset:0 withLimit:20];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_mainTableView reloadData];
}

#pragma mark -noti
-(void)getCategories:(NSNotification *)noti
{
    self.categoryArray = [NSMutableArray arrayWithArray:noti.object];
    ACStickerCategory *category = [[ACStickerCategory alloc] init];
    category.categoryID = kAll;
    category.categoryName = kAll;
    [_categoryArray insertObject:category atIndex:0];
    [_categoryTableView reloadData];
    
    _requestReturnCount ++;
    if (_requestReturnCount == 2)
    {
        [_contentView hideProgressHUDWithAnimated:NO];
    }
}

-(void)getAllSuits:(NSNotification *)noti
{
    self.dataSourceArray = noti.object;
    [_suitCategoryDic setObject:_dataSourceArray forKey:kAll];
    [_mainTableView reloadData];
    
    _requestReturnCount ++;
    if (_requestReturnCount == 2)
    {
        [_contentView hideProgressHUDWithAnimated:NO];
    }
}

-(void)getSuitsOfCategory:(NSNotification *)noti
{
    self.dataSourceArray = noti.object;
    ACSuit *suit = [_dataSourceArray lastObject];
    NSString *categoryID = suit.categoryID;
    if (categoryID)
    {
        [_suitCategoryDic setObject:_dataSourceArray forKey:categoryID];
    }
    [_mainTableView reloadData];
}

-(void)suitDownload:(NSNotification *)noti
{
    [_mainTableView reloadData];
}

-(void)suitProgressUpdate:(NSNotification *)noti
{
    NSString *suitID = noti.object;
    ACSuit *downloadSuit = [[ACNetCenter shareNetCenter].suitDownloadDic objectForKey:suitID];
    for (int i = 0; i < [_dataSourceArray count]; i++)
    {
        ACSuit *suit = [_dataSourceArray objectAtIndex:i];
        if ([suit.suitID isEqualToString:suitID])
        {
            ACStickerPackageCell *cell = (ACStickerPackageCell *)[_mainTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            [cell progressUpdate:downloadSuit.progress];
            break;
        }
    }
}

#pragma mark -tableViewDelegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_mainTableView == tableView)
    {
        ACStickerPackageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACStickerPackageCell"];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACStickerPackageCell" owner:nil options:nil];
            cell = [nib objectAtIndex:0];
        }
        [cell setSuit:[_dataSourceArray objectAtIndex:indexPath.row] superVC:self];
        return cell;
    }
    else
    {
        ACStickerCategoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACStickerCategoryCell"];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACStickerCategoryCell" owner:nil options:nil];
            cell = [nib objectAtIndex:0];
            cell.transform = CGAffineTransformMakeRotation(M_PI/2);
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
        [cell setCategory:[_categoryArray objectAtIndex:indexPath.row] superVC:self];
        
        [cell selectViewHidden:!(indexPath.row == _selectedCategoryIndex)];
        return cell;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_mainTableView == tableView)
    {
        return [_dataSourceArray count];
    }
    else
    {
        return [_categoryArray count];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_mainTableView == tableView)
    {
        return 80;
    }
    else
    {
        return 70;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (_mainTableView == tableView)
    {
        
    }
    else
    {
        _selectedCategoryIndex = (int)indexPath.row;
        [_categoryTableView reloadData];
        ACStickerCategory *category = [_categoryArray objectAtIndex:indexPath.row];
        NSString *categoryID = category.categoryID;
        NSMutableArray *suits = [_suitCategoryDic objectForKey:categoryID];
        if ([suits count] > 0)
        {
            _dataSourceArray = suits;
            [_mainTableView reloadData];
        }
        else
        {
            if ([categoryID isEqualToString:kAll])
            {
                [[ACNetCenter shareNetCenter] getAllSuitsWithOffset:0 withLimit:20];
            }
            else
            {
                [[ACNetCenter shareNetCenter] getSuitsOfCategoryID:categoryID withOffset:0 withLimit:20];
            }
        }
    }
}

#pragma mark -IBAction
-(IBAction)goback:(id)sender
{
    [self.navigationController ACpopViewControllerAnimated:YES];
}

-(IBAction)gotoMyStickers:(id)sender
{
    ACMyStickerController *myStickerC = [[ACMyStickerController alloc] init];
    [self.navigationController pushViewController:myStickerC animated:YES];
}

-(void)downloadSuitWithSuit:(ACSuit *)suit
{
    [[ACNetCenter shareNetCenter] addStickerSuitToMyStickersAndDownloadWithSuitID:suit.suitID progressDelegate:suit];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
