//
//  ACUser.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-3.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACUser.h"
#import "ACNetCenter.h"

@implementation ACUser

#define kAccount        @"account"
#define kDescription    @"description"
#define kIcon           @"icon"
#define kId             @"id"
#define kName           @"name"
#define kUpdateTime     @"updateTime"
#define kGuid           @"guid"
#define kGroup          @"group"

-(void)setUserDic:(NSDictionary *)userDic
{
    self.account = [userDic objectForKey:kAccount];
    self.desp = [userDic objectForKey:kDescription];
    self.icon = [userDic objectForKey:kIcon];
    self.userid = [userDic objectForKey:kId];
    self.name = [userDic objectForKey:kName];
    self.updateTime = [[userDic objectForKey:kUpdateTime] doubleValue];
    self.belongtoGroupID = [userDic objectForKey:kGuid];
    NSDictionary *groupDic = [userDic objectForKey:kGroup];
    if (groupDic)
    {
        self.groupID = [groupDic objectForKey:kId];
        self.groupName = [groupDic objectForKey:kName];
    }
}

-(instancetype)initWithDict:(NSDictionary *)userDic{
    self = [super init];
    [self setUserDic:userDic];
    return self;
}

-(NSString *)description
{
//    return [_description isKindOfClass:[NSString class]] && [_description length]>0?_description:@"";
    return (self.desp != nil && self.desp.length > 0) ? self.desp : @"";
}

-(BOOL)isEqualToUser:(ACUser *)user
{
    return [self.account isEqualToString:user.account] && [self.desp isEqualToString:user.desp] && [self.icon isEqualToString:user.icon] && [self.userid isEqualToString:user.userid] && [self.name isEqualToString:user.name] && self.updateTime == user.updateTime && [self.belongtoGroupID isEqualToString:user.belongtoGroupID];
}


-(BOOL)isMyself{
    return [ACUser isMySelf:_userid];
}

extern NSString* g__pMySelfUserID;

+(NSString*)myselfUserID{
    if(nil==g__pMySelfUserID){
        g__pMySelfUserID = [[NSUserDefaults standardUserDefaults] objectForKey:kUserID];
    }
    return g__pMySelfUserID;
}

+(BOOL)isMySelf:(NSString*)pUserID{
    return pUserID.length&&[pUserID isEqualToString:[ACUser myselfUserID]];
}

+(ACUser*)myself{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    ACUser* pRet = [[ACUser alloc] init];
    pRet.icon   =   [defaults objectForKey:kIcon];
    pRet.name   =   [defaults objectForKey:kName];
    pRet.userid =   [defaults objectForKey:kUserID];    
    return pRet;
}

@end

@implementation ACUserGroup

#define kDesp   @"desp"
#define kId     @"id"
#define kName   @"name"
#define kIcon   @"icon"
#define kCr   @"cr"

-(void)setUserGroupDic:(NSDictionary *)userGroupDic
{
    self.desp = [userGroupDic objectForKey:kDesp];
    self.groupID = [userGroupDic objectForKey:kId];
    self.name = [userGroupDic objectForKey:kName];
    self.icon = [userGroupDic objectForKey:kIcon];
    self.cr  = [userGroupDic objectForKey:kCr];
}

@end
