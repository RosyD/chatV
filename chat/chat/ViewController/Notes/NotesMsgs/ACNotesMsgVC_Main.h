//
//  ACNotesMsgViewController.h
//  chat
//
//  Created by 王方帅 on 14-6-3.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACEntity.h"


@interface ACNotesMsgVC_Main : UIViewController


@property (weak, nonatomic) IBOutlet UIView *subView;
@property(nonatomic, assign) NSInteger selectedViewControllerIndex;
@property (weak, nonatomic) IBOutlet UILabel *titleLable;
@property (weak, nonatomic) IBOutlet UIButton *gotoChatButton;


@property (nonatomic,strong) ACTopicEntity          *topicEntity;
@property (nonatomic) BOOL                          isOpenHotspot;
@property (nonatomic) BOOL                          isFromChatMessageVC; //是否来自ChatMessageVC

//- (id)initWithSuperVC:(ACChatMessageViewController *)superVC;

@end
