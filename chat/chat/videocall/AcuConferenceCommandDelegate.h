//
//  AcuConferenceCommandDelegate.h
//  AcuConference
//
//  Created by Aculearn on 14-4-4.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AcuConferenceCommandDelegate <NSObject>
- (bool)acuConferenceSendCommand:(int)cmd_id
                        withInfo:(const char*)info;

- (void)acuConferenceAVSwitch:(int)avCallType;
@end
