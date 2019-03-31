//
//  ACParticipant.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-22.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACUser.h"

enum participantType
{
    participantType_User    = 10,
    participantType_Group   = 20,
};

@interface ACParticipant : ACUser

@property (nonatomic) int               type;

//@property (nonatomic,strong) NSString   *participantID;
//@property (nonatomic,strong) NSString   *name;
//@property (nonatomic,strong) NSString   *icon;
@property (nonatomic) BOOL              isAdmin;
@property (nonatomic) BOOL              isJoinedUsersGroup; //是否是 "Joined users" 组
//@property (nonatomic) BOOL              isCreater;

+(NSMutableArray *)participantArrayWithDicArray:(NSArray *)array;
+(NSMutableArray *)participantArraySort:(NSMutableArray *)pParticipants withAdminIDS:(NSArray *)adminUserIds;
@end
