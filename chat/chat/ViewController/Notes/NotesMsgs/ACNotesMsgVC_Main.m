//
//  ACNotesMsgViewController.m
//  chat
//
//  Created by 王方帅 on 14-6-3.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACNotesMsgVC_Main.h"
#import "ACNotesMsgVC_Posts.h"
#import "ACChatMessageViewController.h"
#import "UINavigationController+Additions.h"
#import "ACMessageDB.h"
#import "ACNetCenter.h"
#import "ACContributeViewController.h"
#import "ACDataCenter.h"
#import "HMSegmentedControl.h"
#import "ACGroupInfoVC.h"
#import "ACGroupInfoOptionVC.h"


@interface ACNotesMsgVC_Main ()

@property (weak, nonatomic) IBOutlet UIView *segmentBkView;
@property (weak, nonatomic) IBOutlet UIView *segmenToolsBkView;
@property (weak,nonatomic)  UIViewController *selectedViewController;
@property (nonatomic) CGRect TheSubViewFrame;

@end

@implementation ACNotesMsgVC_Main


AC_MEM_Dealloc_implementation


//- (id)initWithSuperVC:(ACChatMessageViewController *)superVC
//{
//    self = [super init];
//    if (self) {
//        _superVC = superVC;
//    }
//    return self;
//}


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
    
    if (![ACConfigs isPhone5]){
        [self.view setFrame_height:self.view.size.height-88];
    }
    
    _gotoChatButton.hidden = _isFromChatMessageVC;
    
//    [_segmentForSubViews addTarget:self action:@selector(segmentedControlSelected:) forControlEvents:UIControlEventValueChanged];
//    
//    [_segmentForSubViews setTitle:@"Posts" forSegmentAtIndex:0];
//    [_segmentForSubViews setTitle:@"Members" forSegmentAtIndex:1];
//    _segmentForSubViews.hidden = YES;
    
    
    HMSegmentedControl *segmentedControl = [[HMSegmentedControl alloc] initWithSectionTitles:@[NSLocalizedString(@"Posts",nil), NSLocalizedString(@"Members",nil)]];
    ///
    [segmentedControl setFrame:CGRectMake(0,0,kScreen_Width-45,44)];
    NSLog(@"%@",NSStringFromCGRect(_segmentBkView.bounds));
    segmentedControl.selectionIndicatorMode =  HMSelectionIndicatorFillsSegment;
    segmentedControl.selectionIndicatorHeight  =2;
//    segmentedControl.alpha = 0.6;
//    segmentedControl.backgroundColor = [UIColor clearColor];
    
    wself_define();
    [segmentedControl setIndexChangeBlock:^(NSUInteger index) {
        
        wself.selectedViewControllerIndex = index;
        wself.selectedViewController = wself.childViewControllers[wself.selectedViewControllerIndex];
        [wself.view addSubview:wself.selectedViewController.view];
        wself.selectedViewController.view.frame = wself.TheSubViewFrame;
        [wself.selectedViewController didMoveToParentViewController:wself];

    }];
    
    [_segmentBkView addSubview:segmentedControl];

    
    
//    NSLog(@"%@",_segmentForSubViews.tintColor);
//    _segmentForSubViews.tintColor = [UIColor colorWithRed:0x77/255. green:0xaa/255 blue:0xbf/255.0 alpha:1];
    //0.356863 0.603922 0.698039
    {
        ACNotesMsgVC_Posts* pPostsVC =  [[ACNotesMsgVC_Posts alloc] init];
        AC_MEM_Alloc(pPostsVC);
        pPostsVC.topicEntity = _topicEntity;
       ///pPostsVC.view.frame =   _subView.frame;
        pPostsVC.view.size= CGSizeMake(kScreen_Width, kScreen_Height - 104);
        [self addChildViewController:pPostsVC];
        
        
        _titleLable.text    =   _topicEntity.showTitle;
    }

    {
        ACGroupInfoVC* pGroupInfo = [[ACGroupInfoVC alloc] init];
        AC_MEM_Alloc(pGroupInfo);
        pGroupInfo.entity = _topicEntity;
        pGroupInfo.superVC  =   self;
        [self addChildViewController:pGroupInfo];
    }
    

    
    
   /// _TheSubViewFrame    =   self.view.frame;
    _TheSubViewFrame = CGRectMake(0, 0, kScreen_Width, kScreen_Height);
    _TheSubViewFrame.origin.y   =   _segmenToolsBkView.frame.origin.y+_segmenToolsBkView.frame.size.height;
    _TheSubViewFrame.size.height    -=  _TheSubViewFrame.origin.y;
    
    
    [segmentedControl setSelectedIndex:0 animated:NO];
    
    [[NSNotificationCenter defaultCenter]  addObserver:self selector:@selector(topicInfoChange) name:kDataCenterTopicInfoChangedNotifation object:nil];

}

- (void)topicInfoChange{
    _titleLable.text  = _topicEntity.title;
}


//
//
//- (void)segmentedControlSelected:(id)sender
//{
//    _selectedViewControllerIndex = _segmentForSubViews.selectedSegmentIndex;
//    _selectedViewController = self.childViewControllers[_selectedViewControllerIndex];
//    [self.view addSubview:_selectedViewController.view];
//    _selectedViewController.view.frame = _TheSubViewFrame;
//    [_selectedViewController didMoveToParentViewController:self];
//}

- (IBAction)gotoChatMessage:(id)sender {
    ACChatMessageViewController *chatMessageVC = [[ACChatMessageViewController alloc] initWithSuperVC:self withTopicEntity:_topicEntity];
//    chatMessageVC.topicEntity = _topicEntity;
//    [chatMessageVC preloadDB];
    AC_MEM_Alloc(chatMessageVC);
    [self.navigationController pushViewController:chatMessageVC animated:YES];}

-(IBAction)goback:(id)sender
{
//    [_pGroupInfoVC clearOnClose];
//    [self.childViewControllers[0] removeFromParentViewController];
//    [self.childViewControllers[0] removeFromParentViewController];
    [self.navigationController ACpopViewControllerAnimated:YES];
}

- (IBAction)onGroupInfoOption:(id)sender {
    ACGroupInfoOptionVC* pGroupInfoOptionVC =  [[ACGroupInfoOptionVC alloc] init];
    pGroupInfoOptionVC.entity  =   _topicEntity;
    pGroupInfoOptionVC.isPushedViewController = YES;
    
//    UINavigationController *navC = [[UINavigationController alloc] initWithRootViewController:pGroupInfoOptionVC];
//    navC.navigationBarHidden = YES;
//    [self ACpresentViewController:navC animated:YES completion:nil];
    
    [self.navigationController pushViewController:pGroupInfoOptionVC animated:YES];

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
