//
//  ACUserDB.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-3.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACUser.h"

@interface ACUserDB : NSObject

+(BOOL)createTable:(NSInteger)nDB_Ver;

+(void)dropTable;

//+(BOOL)addUserToDB:(ACUser *)user;

//+(BOOL)updateUserToDB:(ACUser *)user;

//+(BOOL)deleteUserFromDBWithUserID:(NSString *)userID;

+(void)saveUserToDBWithUser:(ACUser *)user;//先select，有update，没有insert

+(ACUser *)getUserFromDBWithUserID:(NSString *)userID;

//根据UserIDArray从数据库取出对应User信息，以UserID为key，创建字典返回
+(NSDictionary *)getUserFromDBWithUserIDArray:(NSArray *)userIDArray;

#if DEBUG
+(NSArray*) allUser;
#endif

@end
