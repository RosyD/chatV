//
//  ACUser.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-3.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kUsers @"users"

@interface ACUser : NSObject

@property (nonatomic,strong) NSString   *account;
@property (nonatomic,strong) NSString   *desp;
@property (nonatomic,strong) NSString   *icon;
@property (nonatomic,strong) NSString   *userid;
@property (nonatomic,strong) NSString   *name;
@property (nonatomic) NSTimeInterval    updateTime;
@property (nonatomic,strong) NSString   *belongtoGroupID;//guid不是groupID，是服务器用于转换groupID的一个id
@property (nonatomic,strong) NSString   *groupID;
@property (nonatomic,strong) NSString   *groupName;
@property (nonatomic,readonly) BOOL isMyself; //是我自己的
//@property (nonatomic,readonly,getter=getMyselfID) NSString* myselfID; //我自己的ID


-(instancetype)initWithDict:(NSDictionary *)userDic;

-(void)setUserDic:(NSDictionary *)userDic;

-(BOOL)isEqualToUser:(ACUser *)user;

+(ACUser*)myself;
+(NSString*)myselfUserID;
+(BOOL)isMySelf:(NSString*)pUserID;

@end

#define kUsergroups @"usergroups"

@interface ACUserGroup : NSObject

@property (nonatomic,strong) NSString   *desp;
@property (nonatomic,strong) NSString   *groupID;
@property (nonatomic,strong) NSString   *name;
@property (nonatomic,strong) NSString   *icon;
@property (nonatomic,strong) NSString   *cr;    //TXB,新增属性


-(void)setUserGroupDic:(NSDictionary *)userGroupDic;

@end
