//
//  videocall.m
//  videocall
//
//  Created by Aculearn on 15-1-16.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#import "videocall.h"
#import "AcuConferenceSessionController.h"



@implementation videocall
{
    AcuConferenceSessionController *_conferenceSession;
    AcuComListener                 *_acucomListener;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _conferenceSession = nil;
        _acucomListener = 0;
    }
    return self;
}

- (void)dealloc
{
    _conferenceSession = nil;
}

- (BOOL)startConference:(NSDictionary*)sessionDict
       parentController:(UIViewController*)parent
{
    if (sessionDict == nil || parent == nil)
    {
        return NO;
    }
    
    
#if 0
    NSError *error = nil;
    NSString *jsonString = [NSString stringWithUTF8String:config];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *sessionDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&error];
    if (sessionDict == nil)
    {
        NSLog(@"read json error: %@", error);
        return NO;
    }
#endif
    AcuSessionProperty *launchSession = [[AcuSessionProperty alloc] init];
    //launchSession->HostDisplayName;
    launchSession->HostCompany = [sessionDict valueForKey:@"HostCompany"];
    launchSession->GuestID = [sessionDict valueForKey:@"ClientID"];
    launchSession->GuestAccount = [sessionDict valueForKey:@"ClientName"];
    launchSession->GuestCompany = [sessionDict valueForKey:@"ClientCompany"];
    launchSession->GuestDisplayName = [sessionDict valueForKey:@"ClientDisplayName"];
    //launchSession->GuestPassword;
    //launchSession->AcuManager;
    launchSession->Port = [[sessionDict valueForKey:@"Port"] stringValue];
    //launchSession->HostStream;
    //launchSession->GuestStream;
    launchSession->IsModerator = [[sessionDict valueForKey:@"Moderator"] stringValue];
    //launchSession->IsStandalone = @"0";
    //launchSession->HasContent;
    //launchSession->BasePath;
    launchSession->HDMode = [[sessionDict valueForKey:@"HDMode"] stringValue];
    launchSession->AutoAccept = [[sessionDict valueForKey:@"AutoAccept"] stringValue];
    launchSession->_bUseUDP = YES;
    launchSession->_amVersion = [[sessionDict valueForKey:@"AMVersion"] intValue];
    if (launchSession->_amVersion != 7 && launchSession->_amVersion != 8)
    {
        launchSession->_amVersion = 8;
    }
    
    launchSession->SenderID = [sessionDict valueForKey:@"SenderID"];
    launchSession->LocalTitle = [sessionDict valueForKey:@"LocalTitle"];
    
    launchSession->room = [NSMutableDictionary new];
    //[launchSession->room setObject:@"0" forKey:@"AVMode"];
    //[launchSession->room setObject:@"0" forKey:@"Active"];
    //[launchSession->room setObject: forKey:@"Authorization"];
    //[launchSession->room setObject: forKey:@"CallMe"];
    //[launchSession->room setObject: forKey:@"CallOut"];
    //[launchSession->room setObject: forKey:@"CallYou"];
    //[launchSession->room setObject: forKey:@"Chat"];
    [launchSession->room setObject:@"1" forKey:@"ClearTOC"];
    [launchSession->room setObject:[[sessionDict valueForKey:@"ConfMode"] stringValue] forKey:@"ConfMode"];
    [launchSession->room setObject:[[sessionDict valueForKey:@"VideoQuality"] stringValue] forKey:@"ConfQuality"];
    [launchSession->room setObject:[[sessionDict valueForKey:@"QualityPower"] stringValue] forKey:@"QualityPower"];
    [launchSession->room setObject:[[sessionDict valueForKey:@"AllowAllRecord"] stringValue] forKey:@"AllowAllRecord"];
    //[launchSession->room setObject: forKey:@"CreatedDate"];
    [launchSession->room setObject:[sessionDict valueForKey:@"Description"] forKey:@"Description"];
    //[launchSession->room setObject: forKey:@"Email"];
    [launchSession->room setObject:@"" forKey:@"HasContent"];
    [launchSession->room setObject:[sessionDict valueForKey:@"Server"] forKey:@"MainIP"];
    [launchSession->room setObject:[[sessionDict valueForKey:@"MaxSpeaker"] stringValue] forKey:@"MaxSpeaker"];
    [launchSession->room setObject:[[sessionDict valueForKey:@"MaxSpeed"] stringValue] forKey:@"MaxSpeed"];
    [launchSession->room setObject:[[sessionDict valueForKey:@"MaxUser"] stringValue] forKey:@"MaxUser"];
    [launchSession->room setObject:[sessionDict valueForKey:@"SessionID"] forKey:@"ModuleName"];
    [launchSession->room setObject:@"acuconference-av" forKey:@"ModuleType"];
    //[launchSession->room setObject: forKey:@"PresenterMode"];
    //[launchSession->room setObject: forKey:@"SecurityType"];
    //[launchSession->room setObject: forKey:@"SecurityValue"];
    [launchSession->room setObject:[[sessionDict valueForKey:@"StartMode"] stringValue] forKey:@"StartMode"];
    [launchSession->room setObject:[sessionDict valueForKey:@"Title"] forKey:@"Title"];
    [launchSession->room setObject:[sessionDict valueForKey:@"HostID"] forKey:@"UserID"];
    //[launchSession->room setObject: forKey:@"UserName"];
    //[launchSession->room setObject: forKey:@"VBRMode"];
    
    int videoCallMode = [[sessionDict valueForKey:@"VideoCall"] intValue];
    int videoCallAVMode = [[sessionDict valueForKey:@"CallType"] intValue];
    
    _conferenceSession = [[AcuConferenceSessionController alloc] init];
    [_conferenceSession setVideoCallMode:videoCallMode];
    [_conferenceSession setVideoCallAVMode:videoCallAVMode];
    if (_acucomListener != 0)
    {
        [_conferenceSession setAcuComListener:_acucomListener];
    }
    
    
    
    [_conferenceSession startSession:launchSession
                    parentController:parent
                                join:true
                        reconnection:NO];
    
    return YES;
}

- (void)cancelConference
{
    if (_conferenceSession)
    {
        [_conferenceSession canceledConference];
    }
}


- (UIViewController*)getMsgController
{
    if (_conferenceSession)
    {
        return [_conferenceSession getAcuComMsgViewController];
    }
    
    return nil;
}

- (BOOL)isConferenceActive
{
    if (_conferenceSession)
    {
        return [_conferenceSession isInConference];
    }
    
    return NO;
}

- (void)messageNotification:(NSString*)msgSumary
             chatGroupTitle:(NSString*)groupTitle
                chatGroupId:(NSString*)groupId
{
    return;
    if (_conferenceSession)
    {
        [_conferenceSession messageNotification:msgSumary
                                 chatGroupTitle:groupTitle
                                    chatGroupId:groupId];
    }
}

- (void)incomingCallDialog:(NSString*)dlgTitle
                dlgContent:(NSString*)content
                dlgYesName:(NSString*)yesName
                 dlgNoName:(NSString*)noName
                    config:(NSDictionary*)config
{
    return;
    if (_conferenceSession)
    {
        [_conferenceSession incomingCallDialog:dlgTitle
                                    dlgContent:content
                                    dlgYesName:yesName
                                     dlgNoName:noName
                                        config:config];
    }
}

- (void)setAcuComListener:(AcuComListener*)listener
{
    _acucomListener = listener;
    if (_conferenceSession)
    {
        [_conferenceSession setAcuComListener:listener];
    }
}

- (void)conferenceNotification:(int)type
                     msgSumary:(NSString*)sumary
                       session:(NSString*)sessinId
{
    return;
    if (_conferenceSession)
    {
        [_conferenceSession conferenceNotification:type
                                         msgSumary:sumary
                                           session:sessinId];
    }
}

- (void)forceTerminate
{
    if (_conferenceSession)
    {
        [_conferenceSession forceTerminate];
    }
}

@end
