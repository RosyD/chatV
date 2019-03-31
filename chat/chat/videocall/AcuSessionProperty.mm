//
//  AcuSessionProperty.m
//  AcuConference
//
//  Created by aculearn on 13-7-26.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import "AcuSessionProperty.h"

@implementation AcuSessionProperty

- (id)init
{
    self = [super init];
    if (self)
    {
        HostDisplayName = @"";
		HostCompany = @"";
		GuestID = @"";
		GuestAccount = @"";
		GuestCompany = @"";
		GuestDisplayName = @"";
		GuestPassword = @"";
		
		AcuManager = @"";
		Port = @"7350";
		HostStream = @"";
		GuestStream = @"";
        
		IsModerator = @"0";
		IsStandalone = @"1";
		HasContent = @"0";
        
		BasePath = @"";
		HDMode = @"0";
		AutoAccept = @"0";
        
        SenderID = @"";
        LocalTitle = @"";
		
        room = nil;
        
        _bUseUDP = YES;
        _bUseHighQuality = YES;
        
        _amVersion = 7;
    }
    return self;
}

@end
