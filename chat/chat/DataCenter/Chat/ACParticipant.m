//
//  ACParticipant.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-22.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACParticipant.h"

@implementation ACParticipant

/*
 type = 10;
 admin = 1;
 creator = 1;

 account = john;
 description = "";
 domain = john;
 icon = "/rest/apis/user/icon/user/5458852c3004d589430c3b9a?t=1421221399561";
 id = 5458852c3004d589430c3b9a;
 name = john;
 updateTime = 1421221399700;
 */
- (id)initWithDic:(NSDictionary *)dic
{
    self = [super init];
    if (self) {
        _type = [[dic objectForKey:@"type"] intValue];
        if(participantType_User==_type){
            [super setUserDic:dic];
            _isAdmin = [[dic objectForKey:@"admin"] boolValue];
//            _isCreater = [[dic objectForKey:@"creator"] boolValue];
        }
        else{
            self.name = [dic objectForKey:@"name"];
            self.userid = [dic objectForKey:@"id"];
            self.icon   =   [dic objectForKey:@"icon"];

            //Joined users
            if(0==self.name.length&&10==[[dic objectForKey:@"ugtype"] intValue]){
                self.isJoinedUsersGroup = YES;
                self.name  = NSLocalizedString(@"Joined users", nil);
            }
        }
    }
    return self;
}

+(NSMutableArray *)participantArrayWithDicArray:(NSArray *)array
{
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:[array count]];
    for (NSDictionary *dic in array)
    {
        ACParticipant *participant = [[ACParticipant alloc] initWithDic:dic];
        [returnArray addObject:participant];
    }
    return returnArray;
}

+(NSMutableArray*)participantArraySort:(NSMutableArray *)pParticipants withAdminIDS:(NSArray *)adminUserIds{
    
    NSMutableArray* pRet  = [[NSMutableArray alloc] init];
    
    if(adminUserIds.count){
        
        //重新配置isAdmin
        for(ACParticipant* pParticipantTemp in pParticipants){
            pParticipantTemp.isAdmin = NO;
        }
        
        //配置is admin
        for(NSDictionary* pDictTemp in adminUserIds){
            NSString* pUserID = [pDictTemp objectForKey:@"id"];
            for(NSInteger nNo=0;nNo<pParticipants.count;nNo++){
                ACParticipant* pParticipantTemp =   pParticipants[nNo];
                if([pParticipantTemp.userid isEqualToString:pUserID]){
                    pParticipantTemp.isAdmin = YES;
                    break;
                }
            }
        }
    }

    //取得admin
    for(NSInteger nNo=0;nNo<pParticipants.count;nNo++){
        ACParticipant* pParticipantTemp =   pParticipants[nNo];
        if(pParticipantTemp.isAdmin&&participantType_User==pParticipantTemp.type){
            [pParticipants removeObjectAtIndex:nNo];
            [pRet addObject:pParticipantTemp];
            nNo --;
        }
    }

    //按名称排序
    [pRet sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [((ACParticipant*)obj1).name compare:((ACParticipant*)obj2).name];
    }];
    
    [pParticipants sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [((ACParticipant*)obj1).name compare:((ACParticipant*)obj2).name];
    }];
    
    //组成一组
    [pRet addObjectsFromArray:pParticipants];
    
    return pRet;
}

@end
