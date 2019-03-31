//
//  ACMyStickerController.m
//  chat
//
//  Created by 王方帅 on 14-8-20.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACMyStickerController.h"
#import "ACMyStickerCell.h"
#import "UINavigationController+Additions.h"
#import "ACNetCenter.h"
#import "ACAddress.h"
#import "UIView+Additions.h"

@interface ACMyStickerController ()

@end

@implementation ACMyStickerController


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
//    _mainTableView.tableHeaderView = _tableHeaderView;
    
    _titleLable.text = NSLocalizedString(@"My Stickers", nil);
    
//    _tableHeadTitleLable.text =NSLocalizedString(@"Stickers on chat page", nil);
    [_sortButton setNomalText:NSLocalizedString(@"Sort", nil)];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(getMyStickers:) name:kNetCenterGetUserOwnStickersNotifation object:nil];
    [nc addObserver:self selector:@selector(suitDownload:) name:kNetCenterAddAndSuitDownloadNotifation object:nil];
    [nc addObserver:self selector:@selector(suitDownload:) name:kNetCenterSuitDownloadNotifation object:nil];
    [nc addObserver:self selector:@selector(removeUserOwnSticker:) name:kNetCenterRemoveUserOwnStickerNotifation object:nil];
    [nc addObserver:self selector:@selector(suitDelete:) name:kNetCenterSuitDeleteNotifation object:nil];
    [nc addObserver:self selector:@selector(suitProgressUpdate:) name:kNetCenterSuitProgressUpdateNotifition object:nil];
    
    [[ACNetCenter shareNetCenter] getUserOwnStickers];
    
    [_contentView showNetLoadingWithAnimated:NO];
    
    if (![ACConfigs isPhone5])
    {
        [_contentView setFrame_height:_contentView.size.height-88];
        [_mainTableView setFrame_height:_mainTableView.size.height-88];
    }
}

+(NSMutableArray*)loadMySuits{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *downloadSuitIDArray = [defaults objectForKey:kDownloadSuitList];
    NSMutableArray* suitArray = [NSMutableArray arrayWithCapacity:[downloadSuitIDArray count]];
    for (NSString *suitID in downloadSuitIDArray)
    {
        NSString *filePath = [ACAddress getAddressWithFileName:suitID
                                                      fileType:ACFile_Type_GetSuitInfo
                                                        isTemp:NO
                                                    subDirName:suitID];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
        {
            NSDictionary *suitDic = [NSDictionary dictionaryWithContentsOfFile:filePath];
            ACSuit *suit = [[ACSuit alloc] initWithDic:suitDic];
            [suitArray addObject:suit];
        }
    }
    return suitArray;
}

static BOOL _ACSuits_Find(NSArray* pSuits,NSString* suitID){
    for(ACSuit *suit in pSuits){
        if([suit.suitID isEqualToString:suitID]){
            return YES;
        }
    }
    return NO;
}

-(void)loadDownloadSuitWithArray:(NSArray *)array_Server
{
    _downloadArray      =   [ACMyStickerController loadMySuits];
    _undownloadArray    =   [NSMutableArray arrayWithCapacity:[array_Server count]];
    
    //查看哪些被删除
    for(ACSuit *suit_My in _downloadArray){
        suit_My.isFromServer = _ACSuits_Find(array_Server,suit_My.suitID);
    }
    
    
    for(ACSuit *suit_Server in array_Server){
        if(!_ACSuits_Find(_downloadArray,suit_Server.suitID)){
            [_undownloadArray addObject:suit_Server];
        }
    }
    
    /*
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *suits = [defaults objectForKey:kDownloadSuitList]; //这里包含的时suitID
    
    if ([array_Server count] >= [suits count])
    {
        //挑出下载的suit和没下载的suit
        self.downloadArray = [NSMutableArray arrayWithCapacity:[suits count]];
        self.undownloadArray = [NSMutableArray arrayWithCapacity:[array_Server count] - [suits count]];
        for (int i = (int)[array_Server count]-1; i >= 0; i--)
        {
            ACSuit *suit = [array_Server objectAtIndex:i];
            if ([suits containsObject:suit.suitID])
            {
                [_downloadArray addObject:suit];
            }
            else
            {
                [_undownloadArray addObject:suit];
            }
        }
        
        //对下载的suit按照suits排序
        NSMutableArray *sortSuitArray = [NSMutableArray arrayWithCapacity:[suits count]];
        for (int i = 0; i < [suits count]; i++)
        {
            NSString *suitID = [suits objectAtIndex:i];
            for (ACSuit *suit in _downloadArray)
            {
                if ([suit.suitID isEqualToString:suitID])
                {
                    [sortSuitArray addObject:suit];
                    break;
                }
            }
        }
        self.downloadArray = sortSuitArray;
    }*/
}

#pragma mark -noti
-(void)suitDelete:(NSNotification *)noti
{
    ACSuit *suit = noti.object;
    if(suit.isFromServer){
        [_undownloadArray insertObject:suit atIndex:0];
    }
    [_downloadArray removeObject:suit];
    [_mainTableView reloadData];
}

-(void)getMyStickers:(NSNotification *)noti
{
    NSArray *array = noti.object;
    [self loadDownloadSuitWithArray:array];
    [_contentView hideProgressHUDWithAnimated:NO];
    [_mainTableView reloadData];
}

-(void)suitDownload:(NSNotification *)noti
{
    ACSuit *suit = noti.object;
    BOOL isExist = NO;
    for (ACSuit *suitT in _downloadArray)
    {
        if ([suit.suitID isEqualToString:suitT.suitID])
        {
            isExist = YES;
            break;
        }
    }
    if (!isExist)
    {
        [_downloadArray insertObject:suit atIndex:0];
    }
    for (int i = 0; i < [_undownloadArray count]; i++)
    {
        ACSuit *suitT = [_undownloadArray objectAtIndex:i];
        if ([suit.suitID isEqualToString:suitT.suitID])
        {
            [_undownloadArray removeObject:suitT];
            break;
        }
    }
    [_mainTableView reloadData];
}

-(void)suitProgressUpdate:(NSNotification *)noti
{
    NSString *suitID = noti.object;
    ACSuit *downloadSuit = [[ACNetCenter shareNetCenter].suitDownloadDic objectForKey:suitID];
    for (int i = 0; i < [_undownloadArray count]; i++)
    {
        ACSuit *suit = [_undownloadArray objectAtIndex:i];
        if ([suit.suitID isEqualToString:suitID])
        {
            ACMyStickerCell *cell = (ACMyStickerCell *)[_mainTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            [cell progressUpdate:downloadSuit.progress];
            break;
        }
    }
}

-(void)removeUserOwnSticker:(NSNotification *)noti
{
    NSString *suitID = noti.object;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *suitPath = [ACAddress getAddressWithFileName:suitID fileType:ACFile_Type_AddStickerSuitToMyStickersAndDownload isTemp:NO subDirName:suitID];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:suitPath])
        {
            [fileManager removeItemAtPath:suitPath error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_mainTableView reloadData];
            });
        }
    });
}

#pragma mark -tableViewDelegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACMyStickerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACMyStickerCell"];
    if (!cell)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACMyStickerCell" owner:nil options:nil];
        cell = [nib objectAtIndex:0];
    }
    if (indexPath.row < [_downloadArray count])
    {
        [cell setSuit:[_downloadArray objectAtIndex:indexPath.row] superVC:self];
    }
    else
    {
        NSUInteger row = indexPath.row - [_downloadArray count];
        [cell setSuit:[_undownloadArray objectAtIndex:row] superVC:self];
    }
    
    [cell isEditing:_mainTableView.editing];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([_mainTableView isEditing])
    {
        return [_downloadArray count];
    }
    else
    {
        return [_downloadArray count]+[_undownloadArray count];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    __strong ACSuit *suit = [_downloadArray objectAtIndex:sourceIndexPath.row];
    
    [_downloadArray removeObjectAtIndex:sourceIndexPath.row];
    
    [_downloadArray insertObject:suit atIndex:destinationIndexPath.row];
    
    NSMutableArray *suits = [NSMutableArray arrayWithCapacity:[_downloadArray count]];
    for (ACSuit *suit in _downloadArray)
    {
        [suits addObject:suit.suitID];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:suits forKey:kDownloadSuitList];
    [defaults synchronize];
    [ACUtility postNotificationName:kNetCenterStickerSortNotifition object:nil];
}

#pragma mark -delete
-(void)reloadData
{
    [_mainTableView reloadData];
}

-(void)downloadSuitWithSuit:(ACSuit *)suit
{
    [[ACNetCenter shareNetCenter] downloadWithSuitID:suit.suitID progressDelegate:suit];
}

-(void)removeSuit:(ACSuit *)suit
{
    [[ACNetCenter shareNetCenter] removeUserOwnStickerWithSuitID:suit.suitID];
}

#pragma mark -IBAction
-(IBAction)goback:(id)sender
{
    [self.navigationController ACpopViewControllerAnimated:YES];
}

-(IBAction)sort:(UIButton *)sender
{
    if ([_mainTableView isEditing])
    {
        [_mainTableView setEditing:NO animated:YES];
        [_mainTableView reloadData];
        [sender setTitle:NSLocalizedString(@"Sort", nil) forState:UIControlStateNormal];
    }
    else
    {
        [_mainTableView setEditing:YES animated:YES];
        [_mainTableView reloadData];
        [sender setTitle:NSLocalizedString(@"Done", nil) forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
