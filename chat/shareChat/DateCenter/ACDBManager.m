//
//  ACDBManager.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-3.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACDBManager.h"
#import "ACAddress.h"
#import "ACTopicEntity.h"


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


#define kDb_Version @"db_Version"


//程序启动先建表
-(void)createTableIfNotExist
{

    NSUserDefaults* Default =   [NSUserDefaults standardUserDefaults];
    NSInteger nDB_Ver = [[Default objectForKey:kDb_Version] integerValue];
    
    BOOL bDB_NewVer ;
    
    if([ACTopicEntity createTable:nDB_Ver])   { bDB_NewVer = YES;}
    

    if(bDB_NewVer){
        [Default setInteger:nDB_Ver+1 forKey:kDb_Version];
        [Default synchronize];
    }

}

//注销删除表
-(void)dropTableIfExist
{
    
        [ACTopicEntity dropTable];


}

- (id)init
{
    self = [super init];
    if (self) {
//        NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.aculearn.chat2"];
//        NSURL *fileURL = [containerURL URLByAppendingPathComponent:kDBName];
//        
//        [[NSFileManager defaultManager]copyItemAtPath:dbPath toPath:[fileURL path] error:nil];
        //获取分组的共享目录
        NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.aculearn.chat2"];
        NSURL *fileURL = [containerURL URLByAppendingPathComponent:kDBName];
       
        self.queue = [FMDatabaseQueue databaseQueueWithPath:[fileURL path]];
    }
    return self;
}


@end
