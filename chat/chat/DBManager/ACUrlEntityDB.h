//
//  ACUrlEntityDB.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-28.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACUrlEntity;
@interface ACUrlEntityDB : NSObject

+(BOOL)createTable:(NSInteger)nDB_Ver;

+(void)dropTable;

+(BOOL)saveUrlEntityToDBWithUrlEntity:(ACUrlEntity *)urlEntity;//先select，有update，没有insert

//删除urlEntity
+(BOOL)deleteUrlEntityFromDBWithUrlEntityID:(NSString *)urlEntityID;

//获取urlEntityList
+(NSMutableArray *)getUrlEntityListFromDB;

@end
