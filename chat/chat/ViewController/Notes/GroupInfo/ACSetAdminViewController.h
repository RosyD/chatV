//
//  ACSetAdminViewController.h
//  chat
//
//  Created by Aculearn on 15/4/17.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>

extern  NSString * const kSetAdminParticipantNotifation;

typedef void (^TrasferAdminFinish)(NSArray* pAdminIDs); //切换Admin成功

@class ACBaseEntity;
@interface ACSetAdminViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate>

@property (nonatomic,strong) ACBaseEntity           *entity;
@property (nonatomic,strong) TrasferAdminFinish    transferAdminFinishFunc; //是否是为了Transfer

@end
