//
//  ACDateCenter.m
//  chat
//
//  Created by 李朝霞 on 2017/2/17.
//  Copyright © 2017年 李朝霞. All rights reserved.
//

#import "ACDateCenter.h"
#import "ACDBManager.h"
#import "ACTopicEntity.h"

static ACDateCenter *_dataCenter = nil;

NSString *const cSingleChat =   @"singlechat";


NSString *const cFreeChat =     @"freechat";
NSString *const cAdminChat =    @"adminchat";
NSString *const cEventChat =    @"event";
NSString *const cLocationAlert = @"locationalert";
NSString *const cWallboard =    @"robotpost.wallboard";
NSString *const cSystemChat = @"systemchat";

@implementation ACDateCenter

+(ACDateCenter *)shareDataCenter
{
    if (_dataCenter == nil)
    {
        _dataCenter = [[ACDateCenter alloc] init];
    }
    return _dataCenter;
}

//获取topicEntityList
+(NSMutableArray *)getTopicEntityListFromDB
{
    __block NSMutableArray *topicEntityList = [NSMutableArray arrayWithCapacity:10];
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM topicEntity "\
                         "ORDER BY lastestMessageTime desc"];
        FMResultSet *resultSet = [db executeQuery:sql];
        if (resultSet)
        {
            @autoreleasepool
            {
                while (resultSet.next)
                {
                    ACTopicEntity *topicEntity = [ACTopicEntity getTopicEntityWithFMResultSet:resultSet];
                    if ([topicEntity.mpType isEqualToString:cWallboard])
                    {
                        [ACDateCenter shareDataCenter].wallboardTopicEntity = topicEntity;
                    }
                    else
                    {
                        //                        topicEntity.nSharingLocalUserCount = [[self _loadTopicEntity:topicEntity runtimeInfoIndex:2 withDB:db] intValue];
                        [topicEntityList addObject:topicEntity];
                    }
                }
            }
            [resultSet close];
        }
    }];
    
    NSLog(@"%lu",(unsigned long)topicEntityList.count);
    return topicEntityList;
}


@end
