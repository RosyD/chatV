//
//  main.m
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-27.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ACAppDelegate.h"


int main(int argc, char * argv[])
{
    @autoreleasepool {
        
//        NSPredicate* Tt = [NSPredicate predicateWithFormat:@"firstname LIKE \'*\'"];
        
        // 将日志文件重定向到ITLog.txt文件中去，方便测试时找bug用
#ifdef ACUtility_Log_UseFile
        
        #if DEBUG
        if(2==argc&&strcmp("debuging",argv[1])==0){
            argc    =   1;
        }
        else{
            //如果不是运行在XCode中
            [ACUtility LogFile_Swich];
        }
        #else
            [ACUtility LogFile_Swich];
        #endif
#endif
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([ACAppDelegate class]));
    }
}
