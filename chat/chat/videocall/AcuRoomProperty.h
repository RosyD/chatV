//
//  AcuRoomProperty.h
//  AcuConference
//
//  Created by aculearn on 13-7-26.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AcuRoomProperty : NSObject
{
@public
    NSString *SessionID;
	NSString *SessionType;
	NSString *HostID;
	NSString *HostAccount;
	NSString *CreatedDate;
	NSString *Title;
	NSString *Description;
	NSString *Email;
	NSString *MaxParticipant;
	NSString *MaxSpeaker;
	NSString *MaxSpeed;
	NSString *StartMode;
	NSString *ConfQuality;
	NSString *QualityPower;
	NSString *AVMode;
	NSString *VBRMode;
	NSString *Monitor;
	NSString *CallOut;
	NSString *CallYou;
	NSString *CallMe;
	NSString *ClearToc;
	NSString *AllowRecording;
	NSString *Active;
	NSString *ConfMode;
	NSString *AuthType;
	NSString *AccessCode;
    NSMutableArray *Groups;
}

@end
