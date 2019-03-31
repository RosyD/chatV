//
//  AcuRoomProperty.m
//  AcuConference
//
//  Created by aculearn on 13-7-26.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import "AcuRoomProperty.h"

@implementation AcuRoomProperty

- (id)init
{
    self = [super init];
    if (self)
    {
        SessionID = @"";
		SessionType = @"acuconference-av";
		HostID = @"";
		HostAccount = @"";
		CreatedDate = @"";
		Title = @"";
		Description = @"";
		Email = @"";
		QualityPower = @"0";
		ClearToc = @"1";
		AllowRecording = @"0";
		Active = @"0";
		ConfMode = @"0";
		AuthType = @"0";
		AccessCode = @"";
		MaxParticipant = @"2";
		MaxSpeaker = @"2";
		MaxSpeed = @"128";
		StartMode = @"1";
		ConfQuality = @"0";
		AVMode = @"0";
		VBRMode = @"2";
		Monitor = @"0";
		CallOut = @"0";
		CallYou = @"0";
		CallMe = @"0";
		
		Groups = [NSMutableArray new];
    }
    return self;
}

@end
