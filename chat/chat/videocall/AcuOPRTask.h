//
//  AcuOPRTask.h
//  AcuConference
//
//  Created by aculearn on 13-7-26.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AcuOPRTask;
@class AcuOPRResult;

@protocol AcuOPRTaskDelegate <NSObject>

- (void)acuOPRTask:(AcuOPRTask*)oprTask
          onResult:(AcuOPRResult*)result
          withInfo:(NSString*)info;

- (void)acuOPRTask:(AcuOPRTask*)oprTask
     withErrorInfo:(NSString*)info;

- (void)acuOPRTask:(AcuOPRTask *)oprTask
        reportInfo:(NSString *)info;

@end

@interface AcuOPRTask : NSObject

@property (nonatomic, strong) id<AcuOPRTaskDelegate> oprDelegate;

- (void)startOPR:(NSString*)server
      roomHostID:(NSString*)hostId
 roomHostCompany:(NSString*)hostCompany
   roomSessionID:(NSString*)sessionID;


@end
