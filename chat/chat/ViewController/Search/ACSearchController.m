//
//  ACSearchController.m
//  chat
//
//  Created by 王方帅 on 14-7-8.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACSearchController.h"
#import "ACSearchDetailController.h"
#import "UINavigationController+Additions.h"
#import "ACNetCenter.h"
#import "ACSearchCell.h"
#import "UIView+Additions.h"
#import "ACChatViewController.h"
#import "ACConfigs.h"

#define kPrivacyMode    @"kPrivacyMode"
#define kHistoryCount   10

#define kIphone5Height  460
#define kIphone4Height  460-88
#define kHistoryHeight  50

#define kAlertTag       3242

@interface ACSearchController ()

@end

@implementation ACSearchController

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
    [nc addObserver:self selector:@selector(searchCount:) name:kNetCenterSearchCountNotifation object:nil];
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [_searchBar becomeFirstResponder];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.historyList = [NSMutableArray arrayWithArray:[defaults objectForKey:kHistoryList]];
    [_clearHistoryButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    _privacyModeSwitch.on = [[defaults objectForKey:kPrivacyMode] boolValue];
    _searchMode = SearchMode_Search;
    
    _titleLable.text = NSLocalizedString(@"Search", nil);
    [_privateBrowButton setNomalText:NSLocalizedString(@"Private browsing",nil)];
    [_clearHistoryButton setNomalText:NSLocalizedString(@"Clear history",nil)];
    
//    [_privacyModeButton setTitle:NSLocalized String(@"Private browsing", nil) forState:UIControlStateNormal];
    
//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mainTableViewTap:)];
//    [_mainTableView addGestureRecognizer:tap];
}

#pragma mark -tap
-(void)mainTableViewTap:(UITapGestureRecognizer *)tap
{
    [_searchBar resignFirstResponder];
}

#pragma mark -tableViewDelegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_searchMode == SearchMode_Search)
    {
        ACSearchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACSearchCell"];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACSearchCell" owner:nil options:nil];
            cell = [nib objectAtIndex:0];
        }
        [cell setSearchCountType:[[_dataSourceArray objectAtIndex:indexPath.row] intValue] superVC:self];
        return cell;
    }
    else if (_searchMode == SearchMode_History)
    {
        NSString *const identifier = @"Cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
            UIView *view  = [[UIView alloc] initWithFrame:CGRectMake(0, kHistoryHeight-1, cell.contentView.size.width, 1)];
            [view setBackgroundColor:kLineColor];
            [cell.contentView addSubview:view];
        }
        [cell.textLabel setText:[_dataSourceArray objectAtIndex:indexPath.row]];
        return cell;
    }
    __autoreleasing UITableViewCell *cell = [[UITableViewCell alloc] init];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_dataSourceArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_searchMode == SearchMode_Search)
    {
        return 69;
    }
    else
    {
        return kHistoryHeight;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (_searchMode == SearchMode_Search)
    {
        ACSearchDetailController *searchDetailC = [[ACSearchDetailController alloc] init];
        AC_MEM_Alloc(searchDetailC);
        searchDetailC.searchDetailType = [[_dataSourceArray objectAtIndex:indexPath.row] intValue];
        searchDetailC.searchKey = _searchKey;
        searchDetailC.chatVC = _chatVC;
        [self.navigationController pushViewController:searchDetailC animated:YES];
    }
    else
    {
        _searchBar.text = [_historyList objectAtIndex:indexPath.row];
        [self searchBar:_searchBar textDidChange:@""];
        [self searchBarSearchButtonClicked:_searchBar];
    }
}

#pragma mark -noti
-(void)searchCount:(NSNotification *)noti
{
    NSDictionary *dic = noti.object;
    [_contentView hideProgressHUDWithAnimated:NO];
    self.searchCountDic = dic;
    self.searchArray = [NSMutableArray arrayWithCapacity:3];
    if ([[_searchCountDic objectForKey:kTopicTotal] intValue]>0)
    {
        [_searchArray addObject:[NSNumber numberWithInt:ACSearchDetailType_Chat]];
    }
    if ([[_searchCountDic objectForKey:kNoteTotal] intValue]>0)
    {
        [_searchArray addObject:[NSNumber numberWithInt:ACSearchDetailType_Note]];
    }
    if ([[_searchCountDic objectForKey:kAccountTotal] intValue]>0)
    {
        [_searchArray addObject:[NSNumber numberWithInt:ACSearchDetailType_AccountUser]];
    }
    if ([[_searchCountDic objectForKey:kUserTotal] intValue]>0)
    {
        [_searchArray addObject:[NSNumber numberWithInt:ACSearchDetailType_User]];
    }
    if ([[_searchCountDic objectForKey:kUserGroupTotal] intValue]>0)
    {
        [_searchArray addObject:[NSNumber numberWithInt:ACSearchDetailType_UserGroup]];
    }
    if (_searchMode == SearchMode_Search)
    {
        self.dataSourceArray = _searchArray;
    }
    [_mainTableView reloadData];
}

#pragma mark -searchBar
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self searchBar:searchBar textDidChange:@""];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self searchBar:searchBar textDidChange:@""];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSString *searchKey = [searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([searchKey length] > 0)
    {
        self.searchKey = searchKey;
        [_contentView showNetLoadingWithAnimated:NO];
        [[ACNetCenter shareNetCenter] getSearchCountWithKey:_searchKey];
        [searchBar resignFirstResponder];
        
        if (!_privacyModeSwitch.on)
        {
            for (int i = 0; i < [_historyList count]; i++)
            {
                NSString *history = [_historyList objectAtIndex:i];
                if ([history isEqualToString:searchKey])
                {
                    [_historyList removeObject:history];
                }
            }
            if ([_historyList count] > kHistoryCount)
            {
                [_historyList removeLastObject];
            }
            [_historyList insertObject:searchKey atIndex:0];
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:_historyList forKey:kHistoryList];
            [defaults synchronize];
        }
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchBar.text length] == 0 && searchBar.isFirstResponder)
    {
        _searchMode = SearchMode_History;
        self.dataSourceArray = _historyList;
        _mainTableView.tableFooterView = _tableFooterView;
        if ([_historyList count] == 0)
        {
            [_clearHistoryButton setEnabled:NO];
        }
        else
        {
            [_clearHistoryButton setEnabled:YES];
        }
    }
    else
    {
        _searchMode = SearchMode_Search;
        self.dataSourceArray = _searchArray;
        _mainTableView.tableFooterView = nil;
    }
    [_mainTableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
    [searchBar resignFirstResponder];
}

#pragma mark -keyboard
-(void)keyboardWillShow:(NSNotification *)noti
{
    NSDictionary *info = [noti userInfo];
    CGSize size = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    int curve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];

    [_mainTableView setFrame_height:([ACConfigs isPhone5]?kIphone5Height:kIphone4Height)-size.height];
    
    [UIView commitAnimations];
}

-(void)keyboardWillHide:(NSNotification *)noti
{
    NSDictionary *info = [noti userInfo];
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    int curve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    
    [_mainTableView setFrame_height:([ACConfigs isPhone5]?kIphone5Height:kIphone4Height)];
    
    [UIView commitAnimations];
}

#pragma mark -IBAction
-(IBAction)returnViewController:(id)sender
{
    [self.navigationController ACpopViewControllerAnimated:YES];
}

-(IBAction)clearHistory:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:NSLocalizedString(@"Do you want to clear history?", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                          otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    alert.tag = kAlertTag;
    [alert show];
}

-(IBAction)privacyMode:(id)sender
{
    _privacyModeSwitch.on = !_privacyModeSwitch.on;
}

-(IBAction)privacyModeChange:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:_privacyModeSwitch.on] forKey:kPrivacyMode];
    [defaults synchronize];
}

#pragma mark -alert
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kAlertTag)
    {
        if (buttonIndex == alertView.firstOtherButtonIndex)
        {
            [_historyList removeAllObjects];
            [_clearHistoryButton setEnabled:NO];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:_historyList forKey:kHistoryList];
            [defaults synchronize];
            [_mainTableView reloadData];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
