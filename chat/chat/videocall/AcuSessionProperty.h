//
//  AcuSessionProperty.h
//  AcuConference
//
//  Created by aculearn on 13-7-26.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AcuSessionProperty : NSObject
{
@public
    NSMutableDictionary *room;
    NSString *HostDisplayName;
    NSString *HostCompany;
    NSString *GuestID;
    NSString *GuestAccount;
    NSString *GuestCompany;
    NSString *GuestDisplayName;
    NSString *GuestPassword;
    NSString *AcuManager;
    NSString *Port;
    NSString *HostStream;
    NSString *GuestStream;
    NSString *IsModerator;
    NSString *IsStandalone;
    NSString *HasContent;
    NSString *BasePath;
    NSString *HDMode;
    NSString *AutoAccept;
    NSString *SenderID;
    NSString *LocalTitle;
    BOOL      _bUseUDP;
    BOOL      _bUseHighQuality;
    int _amVersion;
}

@end
