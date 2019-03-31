//
//  ACUrlEditViewController.m
//  chat
//
//  Created by Aculearn on 15/4/23.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#import "ACUrlEditViewController.h"
#import "ACConfigs.h"
#import "ACGroupInfoVC.h"
#import "ACGroupInfoOptionVC.h"
#import "ACDataCenter.h"


@interface ACUrlEditViewController (){
    __weak IBOutlet UILabel *_lableTitle;
}

@end

@implementation ACUrlEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (![ACConfigs isPhone5]){
        [self.view setFrame_height:self.view.size.height-88];
    }
    
    ACGroupInfoVC* pGroupInfo = [[ACGroupInfoVC alloc] init];
    AC_MEM_Alloc(pGroupInfo);
    pGroupInfo.entity = _urlEntity;
    pGroupInfo.superVC  =   self;
    [self addChildViewController:pGroupInfo];

    [self.view addSubview:pGroupInfo.view];
    
    _lableTitle.text    =   _urlEntity.title;
    
    CGRect frame = self.view.frame;
    frame.origin.y  =   64;
    frame.size.height -= 64;
    pGroupInfo.view.frame =frame;
    [pGroupInfo didMoveToParentViewController:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(topicInfoChange) name:kDataCenterTopicInfoChangedNotifation object:nil];
}


- (void)topicInfoChange{
    _lableTitle.text = _urlEntity.title;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onGroupInfoOption:(id)sender {
    ACGroupInfoOptionVC* pGroupInfoOptionVC =  [[ACGroupInfoOptionVC alloc] init];
    pGroupInfoOptionVC.entity  =   _urlEntity;
    pGroupInfoOptionVC.isPushedViewController = YES;
    [self.navigationController pushViewController:pGroupInfoOptionVC animated:YES];
}

- (IBAction)onBack:(id)sender {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
