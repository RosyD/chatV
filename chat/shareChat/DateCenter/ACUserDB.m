//
//  ACUserDB.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-3.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACUserDB.h"
#import "ACDBManager.h"
#import "ACUser.h"

//处理Sqlite字符串单引号的问题
//不再使用了，需要测试#define SQLite_String(p_____Str) p_____Str
//[p_____Str stringByReplacingOccurrencesOfString:@"\'" withString:@"\""]

@implementation ACUserDB

+(BOOL)createTable:(NSInteger)nDB_Ver
{
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        BOOL success = [db executeUpdate:
         @"CREATE TABLE IF NOT EXISTS userInfo ("\
         "account TEXT, "\
         "description TEXT, "\
         "icon TEXT, "\
         "id TEXT PRIMARY KEY, "\
         "name TEXT, "\
         "updateTime DOUBLE, "\
         "guid TEXT "\
         ");"];
    }];
    return NO;
}

+(void)dropTable
{
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        BOOL success = [db executeUpdate:
                        @"DROP TABLE IF EXISTS userInfo;"];
    }];
}


+(void)saveUserToDBWithUser:(ACUser *)user
{
    if (user.userid)
    {
        [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
            
            FMDatabase_Enable_Error_logs(db);
            
            NSString *sql = [NSString stringWithFormat:@"SELECT * FROM userInfo "\
                             "WHERE id='%@' ",
                             user.userid];
            FMResultSet *resultSet = [db executeQuery:sql];
            if (resultSet.next)
            {
                ACUser *userTmp = [[ACUser alloc] init];
                userTmp.account = [resultSet stringForColumnIndex:0];
                userTmp.desp = [resultSet stringForColumnIndex:1];
                userTmp.icon = [resultSet stringForColumnIndex:2];
                userTmp.userid = [resultSet stringForColumnIndex:3];
                userTmp.name = [resultSet stringForColumnIndex:4];
                userTmp.updateTime = [resultSet doubleForColumnIndex:5];
                userTmp.belongtoGroupID = [resultSet stringForColumnIndex:6];
                [resultSet close];
                
                BOOL isNeedUpdate =
                ![userTmp.account isEqualToString:user.account]
                || ![userTmp.desp isEqualToString:user.desp]
                || ![userTmp.icon isEqualToString:user.icon]
                || ![userTmp.name isEqualToString:user.name]
                || !((int)userTmp.updateTime == (int)user.updateTime)
                || ![userTmp.belongtoGroupID isEqualToString:user.belongtoGroupID];
                if (isNeedUpdate)
                {
//                    sql = [NSString stringWithFormat:@"UPDATE userInfo SET "\
//                           "account='%@', "\
//                           "description='%@', "\
//                           "icon='%@', "\
//                           "name='%@', "\
//                           "updateTime='%d', "\
//                           "guid='%@' "\
//                           "WHERE id='%@' ",
//                           SQLite_String(user.account),
//                           SQLite_String(user.desp),
//                           user.icon,
//                           SQLite_String(user.name),
//                           (int)user.updateTime,
//                           user.belongtoGroupID,
//                           user.userid];
//                    BOOL succ = [db executeUpdate:sql];
                    BOOL succ = [db executeUpdateWithFormat:@"UPDATE userInfo SET "\
                           "account=%@, "\
                           "description=%@, "\
                           "icon=%@, "\
                           "name=%@, "\
                           "updateTime=%d, "\
                           "guid=%@ "\
                           "WHERE id=%@;",
                           user.account,
                           user.desp,
                           user.icon,
                           user.name,
                           (int)user.updateTime,
                           user.belongtoGroupID,
                           user.userid];

//                    if (!succ)
//                    {
//                        ITLog(@"UPDATE userInfo失败");
//                    }
                }
            }
            else
            {
//                sql = [NSString stringWithFormat:@"INSERT INTO userInfo "\
//                       "(account, description, icon, id, name, updateTime, guid) "\
//                       "VALUES ('%@', '%@', '%@', '%@', '%@', '%d', '%@')",
//                       SQLite_String(user.account),
//                       SQLite_String(user.desp),
//                       user.icon,
//                       user.userid,
//                       SQLite_String(user.name),
//                       (int)user.updateTime,
//                       user.belongtoGroupID];
//                BOOL succ = [db executeUpdate:sql];
                
                BOOL succ = [db executeUpdateWithFormat:@"INSERT INTO userInfo "\
                             "(account, description, icon, id, name, updateTime, guid) "\
                             "VALUES (%@, %@, %@, %@, %@, %d, %@);",
                             user.account,
                             user.desp,
                             user.icon,
                             user.userid,
                             user.name,
                             (int)user.updateTime,
                             user.belongtoGroupID];
                
//                if (!succ)
//                {
//                    ITLog(@"INSERT userInfo失败");
//                }
            }
        }];
    }
}


#if DEBUG
+(NSArray*) allUser{
    __block NSMutableArray *users = [[NSMutableArray alloc] init];
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM userInfo;"];
        FMResultSet *resultSet = [db executeQuery:sql];
        while (resultSet.next){
            ACUser* user = [[ACUser alloc] init];
            user.account = [resultSet stringForColumnIndex:0];
            user.desp = [resultSet stringForColumnIndex:1];
            user.icon = [resultSet stringForColumnIndex:2];
            user.userid = [resultSet stringForColumnIndex:3];
            user.name = [resultSet stringForColumnIndex:4];
            user.updateTime = [resultSet doubleForColumnIndex:5];
            user.belongtoGroupID = [resultSet stringForColumnIndex:6];
            [users addObject:user];
        }
        [resultSet close];
    }];
    return users;
}
#endif

+(ACUser *)getUserFromDBWithUserID:(NSString *)userID
{
    __block ACUser *user = nil;
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM userInfo "\
                         "WHERE id='%@' ",
                         userID];
        FMResultSet *resultSet = [db executeQuery:sql];
        if (resultSet.next)
        {
            user = [[ACUser alloc] init];
            user.account = [resultSet stringForColumnIndex:0];
            user.desp = [resultSet stringForColumnIndex:1];
            user.icon = [resultSet stringForColumnIndex:2];
            user.userid = [resultSet stringForColumnIndex:3];
            user.name = [resultSet stringForColumnIndex:4];
            user.updateTime = [resultSet doubleForColumnIndex:5];
            user.belongtoGroupID = [resultSet stringForColumnIndex:6];
        }
        [resultSet close];
    }];
    return user;
}

//根据UserIDArray从数据库取出对应User信息，以UserID为key，创建字典返回
+(NSDictionary *)getUserFromDBWithUserIDArray:(NSArray *)userIDArray
{
    __block NSMutableDictionary *userDic = [NSMutableDictionary dictionary];
    [[ACDBManager defaultDBManager].queue inDatabase:^(FMDatabase *db) {
        
        FMDatabase_Enable_Error_logs(db);
        
        NSString *sql = @"SELECT * FROM userInfo WHERE ";
        for (int i = 0;i < [userIDArray count]-1;i++)
        {
            NSString *userID = [userIDArray objectAtIndex:i];
            [sql stringByAppendingFormat:@"id='%@' or ",userID];
        }
        [sql stringByAppendingFormat:@"id='%@'",[userIDArray lastObject]];
        FMResultSet *resultSet = [db executeQuery:sql];
        
        while (resultSet.next)
        {
            ACUser *user = [[ACUser alloc] init];
            user.account = [resultSet stringForColumnIndex:0];
            user.desp = [resultSet stringForColumnIndex:1];
            user.icon = [resultSet stringForColumnIndex:2];
            user.userid = [resultSet stringForColumnIndex:3];
            user.name = [resultSet stringForColumnIndex:4];
            user.updateTime = [resultSet doubleForColumnIndex:5];
            user.belongtoGroupID = [resultSet stringForColumnIndex:6];
            [userDic setObject:user forKey:user.userid];
        }
        [resultSet close];
    }];
    return userDic;
}

@end









