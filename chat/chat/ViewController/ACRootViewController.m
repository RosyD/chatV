//
//  ACRootViewController.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-27.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACRootViewController.h"
#import "ACRootTableViewCell.h"
//#import "IIViewDeckController.h"
#import "MMDrawerController.h"
#import "UIViewController+MMDrawerController.h"
#import "ACChatViewController.h"
//#import "ACFavoriteViewController.h"
#import "ACSetViewController.h"
#import "ACNetCenter.h"
#import "ACAddress.h"
#import "ACPersonInfoViewController.h"
#import "UIImageView+WebCache.h"
#import "ACConfigs.h"
#import "UINavigationController+Additions.h"
#import "UIView+Additions.h"
#import "ACDataCenter.h"

@interface ACRootViewController ()

@end

@implementation ACRootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self reloadPersonInfo];
    if (!_isFirstAppear)
    {
        //TXB 不知道为什么屏蔽了
//        [ACConfigs shareConfigs].rootViewControllerShowing = YES;
    }
    else
    {
        _isFirstAppear = NO;
    }
#ifdef kRootViewControllerShowing
    
    ITLog(([NSString stringWithFormat:@"rootViewControllerShowing--->>>%d",[ACConfigs shareConfigs].rootViewControllerShowing]));
#endif
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    [ACConfigs shareConfigs].rootViewControllerShowing = NO;
#ifdef kRootViewControllerShowing
   
    ITLog(([NSString stringWithFormat:@"rootViewControllerShowing--->>>%d",[ACConfigs shareConfigs].rootViewControllerShowing]));
#endif
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
//    [_roundedCornerImageView setImage:[_roundedCornerImageView.image stretchableImageWithLeftCapWidth:27 topCapHeight:27]];
    _isFirstAppear = YES;
#ifdef kRootViewControllerShowing
    
    [ACConfigs shareConfigs].rootViewControllerShowing = NO;
    ITLog(([NSString stringWithFormat:@"rootViewControllerShowing--->>>%d",[ACConfigs shareConfigs].rootViewControllerShowing]));
#endif
    if (![ACConfigs isPhone5])
    {
        [_mainTableView setFrame_height:_mainTableView.size.height-88];
    }
    
    _dataSourceArray = [[NSMutableArray alloc] init];
    [_dataSourceArray addObject:[NSNumber numberWithInt:ACCenterViewControllerType_All]];
    [_dataSourceArray addObject:[NSNumber numberWithInt:ACCenterViewControllerType_Chat]];
    [_dataSourceArray addObject:[NSNumber numberWithInt:ACCenterViewControllerType_Event]];
    
#ifdef BUILD_FOR_EGA
    [_dataSourceArray addObject:[NSNumber numberWithInt:ACCenterViewControllerType_Link]];
#else
    [_dataSourceArray addObject:[NSNumber numberWithInt:ACCenterViewControllerType_Survey]];
    [_dataSourceArray addObject:[NSNumber numberWithInt:ACCenterViewControllerType_Link]];
//    [_dataSourceArray addObject:[NSNumber numberWithInt:ACCenterViewControllerType_Page]];
//    if ([ACDataCenter shareDataCenter].wallboardTopicEntity != nil)
    {
        [_dataSourceArray addObject:[NSNumber numberWithInt:ACCenterViewControllerType_Services]];
    }
#endif
    
    [_dataSourceArray addObject:[NSNumber numberWithInt:ACCenterViewControllerType_Setting]];
    [_mainTableView reloadData];
    
    [_mainTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    
    _previousIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    ACRootTableViewCell *rootTableViewCell = (ACRootTableViewCell *)[_mainTableView cellForRowAtIndexPath:_previousIndexPath];
    [rootTableViewCell setSelect:YES];
    
    [_iconImageView setToCircle];
//    [_iconImageView.layer setCornerRadius:_iconImageView.size.height/2];
//    [_iconImageView.layer setMasksToBounds:YES];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(reloadPersonInfo) name:kPersonInfoPutSuccessNotifation object:nil];
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
    [nc addObserver:self selector:@selector(wallboardTopicEntityChange:) name:kDataCenterWallboardTopicEntityChangeNotifation object:nil];
}

#pragma mark -notification
-(void)reloadPersonInfo
{
    _nameLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:kName];
    [ACRootViewController showUserIcon200ForImageView:_iconImageView withIconStr:[[NSUserDefaults standardUserDefaults] objectForKey:kIcon]];
    
//    [_iconImageView setImageWithIconString:[[NSUserDefaults standardUserDefaults] objectForKey:kIcon] placeholderImage:[UIImage imageNamed:@"personIcon200.png"] ImageType:ImageType_UserIcon200];
}

+(void)showUserIcon200ForImageView:(UIImageView*)imgView withIconStr:(NSString*)iconStr{
    [imgView setImageWithIconString:iconStr
                   placeholderImage:[UIImage imageNamed:@"personIcon200"]
                          ImageType:ImageType_UserIcon200];
}

-(void)hotspotStateChange:(NSNotification *)noti
{
    if (_isOpenHotspot)
    {
        [_mainTableView setFrame_y:_mainTableView.origin.y-hotsoptHeight];
        [_beginLineView setFrame_y:_beginLineView.origin.y-hotsoptHeight];
    }
    else
    {
        [_mainTableView setFrame_y:_mainTableView.origin.y+hotsoptHeight];
        [_beginLineView setFrame_y:_beginLineView.origin.y+hotsoptHeight];
    }
}



-(void)wallboardTopicEntityChange:(NSNotification *)noti
{
//    if ([ACDataCenter shareDataCenter].wallboardTopicEntity == nil)
//    {
//        NSNumber *num = [NSNumber numberWithInt:ACCenterViewControllerType_Services];
//        @synchronized(_dataSourceArray)
//        {
//            for (int i = 0; i < [_dataSourceArray count]; i++)
//            {
//                NSNumber *numTmp = [_dataSourceArray objectAtIndex:i];
//                if ([numTmp isEqual:num])
//                {
//                    [_dataSourceArray removeObject:numTmp];
//                    [_mainTableView reloadData];
//                    break;
//                }
//            }
//        }
//    }
//    else
//    {
//        NSNumber *num = [NSNumber numberWithInt:ACCenterViewControllerType_Services];
//        @synchronized(_dataSourceArray)
//        {
//            BOOL isHaveData = NO;
//            for (int i = 0; i < [_dataSourceArray count]; i++)
//            {
//                NSNumber *numTmp = [_dataSourceArray objectAtIndex:i];
//                if ([numTmp isEqual:num])
//                {
//                    isHaveData = YES;
//                    break;
//                }
//            }
//            if (!isHaveData)
//            {
//                for (int i = [_dataSourceArray count]-1; i > 0; i--)
//                {
//                    NSNumber *numTmp = [_dataSourceArray objectAtIndex:i];
//                    if (numTmp.intValue == ACCenterViewControllerType_Setting)
//                    {
//                        [_dataSourceArray insertObject:num atIndex:i];
//                        [_mainTableView reloadData];
//                        break;
//                    }
//                }
//            }
//        }
//    }
}

#pragma mark -UITableViewDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_dataSourceArray count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACRootTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACRootTableViewCell"];
    if (!cell)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACRootTableViewCell" owner:nil options:nil];
        cell = [nib objectAtIndex:0];
    }
    [cell setRow:[[_dataSourceArray objectAtIndex:indexPath.row] intValue]];
    if ([indexPath isEqual:_previousIndexPath])
    {
        [cell setSelect:YES];
    }
    else
    {
        [cell setSelect:NO];
    }
    return cell;
}



-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self _tableView:tableView didSelectRowAtIndexPath:indexPath animated:YES];
}

-(void)_tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    if (_previousIndexPath)
    {
        if (![_previousIndexPath isEqual:indexPath])
        {
            ACRootTableViewCell *cell = (ACRootTableViewCell *)[tableView cellForRowAtIndexPath:_previousIndexPath];
            [cell setSelect:NO];
            
            cell = (ACRootTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
            [cell setSelect:YES];
        }
    }
    else
    {
        ACRootTableViewCell *cell = (ACRootTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        [cell setSelect:YES];
    }
    _previousIndexPath = indexPath;
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
//    [self.viewDeckController closeLeftViewBouncing:^(IIViewDeckController *controller)
    
    [self.mm_drawerController closeDrawerAnimated:animated completion:^(BOOL finished) {
#ifdef kRootViewControllerShowing
        [ACConfigs shareConfigs].rootViewControllerShowing = NO;
#endif
//        UIViewController *vc = [(UINavigationController *)self.viewDeckController.centerController topViewController];
//        if ([vc isKindOfClass:[ACChatViewController class]])
//        {
//            ACChatViewController *chatVC = (ACChatViewController *)vc;
//            if (chatVC.chatListType == indexPath.row)
//            {
//                return;
//            }
//        }
//        else if ([vc isKindOfClass:[ACSetViewController class]])
//        {
//            if (indexPath.row == ACCenterViewControllerType_Setting)
//            {
//                return;
//            }
//        }
        UIViewController *viewController = nil;
        int type = [[_dataSourceArray objectAtIndex:indexPath.row] intValue];
        switch (type)
        {
            case ACCenterViewControllerType_All:
            case ACCenterViewControllerType_Chat:
            case ACCenterViewControllerType_Event:
            case ACCenterViewControllerType_Survey:
            case ACCenterViewControllerType_Link:
            case ACCenterViewControllerType_Page:
            case ACCenterViewControllerType_Services:
            {
                viewController = [[ACChatViewController alloc] init];
                AC_MEM_Alloc(viewController);
            }
                break;
            case ACCenterViewControllerType_Setting:
            {
                viewController = [[ACSetViewController alloc] init];
                AC_MEM_Alloc(viewController);
            }
                break;
                
            default:
                break;
        }
        if ([viewController isKindOfClass:[ACChatViewController class]])
        {
            ACChatViewController *chatVC = (ACChatViewController *)viewController;
            [chatVC setChatListType:type];
            [chatVC setChatListTitle:((ACRootTableViewCell *)[tableView cellForRowAtIndexPath:indexPath]).titleLabel.text];
        }
        if (viewController)
        {
            UINavigationController *navC = [[UINavigationController alloc] initWithRootViewController:viewController];
            [navC setNavigationBarHidden:YES];
            
//            UINavigationController *navCTmp = (UINavigationController *)(self.viewDeckController.centerController);
//            NSArray *viewControllers = [(UINavigationController *)(self.viewDeckController.centerController) viewControllers];
            UINavigationController *navCTmp = (UINavigationController *)(self.mm_drawerController.centerViewController);
            NSArray *viewControllers = [navCTmp viewControllers];
            if ([viewControllers count] > 1)
            {
                [navCTmp ACpopToRootViewControllerAnimated:NO];
            }
            UIViewController *vc = [viewControllers objectAtIndex:0];
            if ([vc respondsToSelector:@selector(removeNotification)])
            {
                [vc performSelector:@selector(removeNotification)];
            }
//            [self.viewDeckController setCenterController:navC];
            self.mm_drawerController.centerViewController = navC;
        }
    }];
}


-(void)showChatViewController{
    [_mainTableView setContentOffset:CGPointMake(0, 0)];
    [self _tableView:_mainTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO];
}

-(IBAction)personInfoButtonTouchUp:(id)sender
{
    ACPersonInfoViewController *personInfoVC = [[ACPersonInfoViewController alloc] init];
    AC_MEM_Alloc(personInfoVC);
    UINavigationController *navC = [[UINavigationController alloc] initWithRootViewController:personInfoVC];
    navC.navigationBarHidden = YES;
    [self ACpresentViewController:navC animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
