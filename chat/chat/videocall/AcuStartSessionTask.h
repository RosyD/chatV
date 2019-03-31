//
//  AcuStartSessionTask.h
//  AcuConference
//
//  Created by aculearn on 13-7-29.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AcuSessionProperty.h"

@class AcuStartSessionTask;

@protocol AcuStartSessionTaskDelegate <NSObject>

- (void)acuStartSessionTask:(AcuStartSessionTask*)startSessionTask
                   onResult:(bool)bResult
                   withInfo:(NSString*)info;

@end

@interface AcuStartSessionTask : NSObject
{
@public
    AcuSessionProperty  *_session;
    bool                _bJoin;
}

@property (nonatomic, strong) id<AcuStartSessionTaskDelegate> startSessionDelegate;


- (void)startSession:(NSMutableDictionary*)sessionParams onServer:(NSString*)server;

@end
