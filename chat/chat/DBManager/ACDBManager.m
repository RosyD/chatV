//
//  ACDBManager.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-3.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACDBManager.h"
#import "ACAddress.h"
#import "ACConfigs.h"
#import "ACUserDB.h"
#import "ACMessageDB.h"
#import "ACTopicEntityDB.h"
#import "ACUrlEntityDB.h"
#import "ACReadSeqDB.h"
#import "ACReadCountDB.h"

#define kDBName @"AcuCom.db"

__strong static ACDBManager *_defaultDBManager = nil;

@implementation ACDBManager

- (void)dealloc
{
    
}

+(ACDBManager *)defaultDBManager
{
    if (_defaultDBManager == nil)
    {
        _defaultDBManager = [[ACDBManager alloc] init];
    }
    return _defaultDBManager;
}

//+(void)clearDBManager
//{
//    _defaultDBManager = nil;
//    NSString *dbPath = [ACAddress getAddressWithFileName:kDBName fileType:ACFile_Type_Database isTemp:NO];
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    if ([fileManager fileExistsAtPath:dbPath])
//    {
//        NSError *error = nil;
//        [fileManager removeItemAtPath:dbPath error:&error];
//        if (error)
//        {
//            ITLog(error.localizedDescription);
//        }
//    }
//}

#define kDb_Version @"db_Version"


//程序启动先建表
-(void)createTableIfNotExist
{
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    NSUserDefaults* Default =   [NSUserDefaults standardUserDefaults];
    NSInteger nDB_Ver = [[Default objectForKey:kDb_Version] integerValue];
    
    BOOL bDB_NewVer = [ACUserDB createTable:nDB_Ver];
    if([ACMessageDB createTable:nDB_Ver])       { bDB_NewVer = YES;}
    if([ACTopicEntityDB createTable:nDB_Ver])   { bDB_NewVer = YES;}
    if([ACUrlEntityDB createTable:nDB_Ver])     { bDB_NewVer = YES;}
    if([ACReadSeqDB createTable:nDB_Ver])       { bDB_NewVer = YES;}
    if([ACReadCountDB createTable:nDB_Ver])     { bDB_NewVer = YES;}

    if(bDB_NewVer){
        [Default setInteger:nDB_Ver+1 forKey:kDb_Version];
        [Default synchronize];
    }
//    });
}

//注销删除表
-(void)dropTableIfExist
{
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [ACUserDB dropTable];
        [ACMessageDB dropTable];
        [ACTopicEntityDB dropTable];
        [ACUrlEntityDB dropTable];
        [ACReadSeqDB dropTable];
        [ACReadCountDB dropTable];
//    });
}

- (id)init
{
    self = [super init];
    if (self) {
        NSString *dbPath = [ACAddress getAddressWithFileName:kDBName fileType:ACFile_Type_Database isTemp:NO subDirName:nil];
        ///
        //获取分组的共享目录
        NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.aculearn.chat2"];
        NSURL *fileURL = [containerURL URLByAppendingPathComponent:kDBName];
        
       [[NSFileManager defaultManager]copyItemAtPath:dbPath toPath:[fileURL path] error:nil];
        ///
        
        
        ITLogEX(@"DB %@",dbPath);
//        self.queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        self.queue = [FMDatabaseQueue databaseQueueWithPath:[fileURL path]];
    }
    return self;
}


@end
