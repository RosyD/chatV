//
//  ACPermission.h
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-31.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ACPermission : NSObject

@property (nonatomic,readonly) BOOL canDeleteSession;   //删除会话
@property (nonatomic,readonly) BOOL needCheckLastAdmin; //需要检查是不是last admin
@property (nonatomic,readonly) BOOL canUpdateInfo;      //允许修改Icon 标题 URL 等
@property (nonatomic,readonly) BOOL canAddAdmins;       //是否可以修改管理员 Admin
@property (nonatomic,readonly) BOOL canAddParticipants;    //添加参与者
@property (nonatomic,readonly) BOOL canDelParticipants;    //删除参与者
@property (nonatomic,readonly) BOOL canViewParticipants;    //查看参与者

@end
