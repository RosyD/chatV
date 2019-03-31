//
//  ACDBManager.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-3.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"

@interface ACDBManager : NSObject

+(ACDBManager *)defaultDBManager;

//+(void)clearDBManager;

//程序启动先建表
-(void)createTableIfNotExist;

//注销删除表
-(void)dropTableIfExist;

@property (nonatomic,strong) FMDatabaseQueue *queue;

@end


#ifdef ACUtility_Need_Log
    #define FMDatabase_Enable_Error_logs(p_____DB) p_____DB.logsErrors = YES
#else
    #define FMDatabase_Enable_Error_logs(p_____DB)
#endif
