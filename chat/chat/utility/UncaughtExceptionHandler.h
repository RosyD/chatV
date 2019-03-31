//
//  UncaughtExceptionHandler.h
//  chat
//
//  Created by Aculearn on 15/12/17.
//  Copyright © 2015年 Aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UncaughtExceptionHandler : NSObject{
    BOOL dismissed;
}

@end

void HandleException(NSException *exception);
void SignalHandler(int signal);
void InstallUncaughtExceptionHandler(void);
