//
//  AcuConferenceSessionController.m
//  AcuConference
//
//  Created by aculearn on 13-7-11.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import "AcuConferenceSessionController.h"

#define ACU_COM_USE_KGMODAL         0

#import "AcuStartViewController.h"
#import "AcuStartSessionTask.h"
#import "AcuOPRTask.h"
//#import "AcuGlobalParams.h"
#if ACU_COM_USE_KGMODAL
#import "KGModal.h"
#endif
#import "MMDrawerController.h"
#import "AcuConferencePresentingLeftViewController.h"
#import "AcuConferencePresentingRightViewController.h"
#import "AcuConferencePresentingViewController.h"
#include "AcuConferenceSessionEvent.h"
#import "AcuOPRResult.h"
#import "AcuParticipantInfo.h"
#import "AcuSendChatProtocol.h"
#include "conf_api_define.h"
#include "conference7_api_const.h"
#import "AcuDeviceHardware.h"
#import "AcuParticipantListMenuProtocol.h"
#import "AcuComVideoCallStoryboard.h"
#import "AcuStartSessionCancelParam.h"

/*
 NSArray *sortedArray;
 sortedArray = [drinkDetails sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
 NSDate *first = [(Person*)a birthDate];
 NSDate *second = [(Person*)b birthDate];
 return [first compare:second];
 }];
 */

#define CUSTOME_CMDTYPE_ENTER_CONFERENCE_MODE       112

@interface AcuConferenceSessionController() <AcuStartViewControllerDelegate,
                                            AcuStartSessionTaskDelegate,
                                            AcuOPRTaskDelegate,
                                            AcuConferencePresentingDelegate,
                                            AcuConferenceCommandDelegate,
                                            AcuSendChatProtocol,
                                            AcuParticipantListMenuProtocol>
{
    int _screenWidth;
    int _screenHeight;
    AcuSessionProperty *_session;
    AcuStartSessionTask *_startSessionTask;
    AcuOPRTask *_oprTask;
    bool _bJoin;
	BOOL _bReconnection;
    //AcuGlobalParams *_params;
    NSString *_displayName;
    BOOL _bInConference;
    
    AcuConferenceSessionEvent	*_conferenceEvent;
	
	//conference info defines
	ACU_LOGIN_HEADER		_loginHeader;
	uint16_t				_conferenceSessionID;
	//end conference info defines
    
    bool                _hasSettedVideoParam;
    BOOL                _bMMDrawerLeftOpen;
    
    AcuComListener      *_acucomListener;
    AcuStartSessionCancelParam  *_cancelParam;
    NSLock              *_cancelMutex;
    
    BOOL                _bConferencePresented;
    
    NSTimer             *_startViewControllerDismissTimer;
    
    BOOL                _forceTerminite;
    NSLock              *_terminiteMutex;
}

- (void)forceTerminateConference;

@property (nonatomic, weak) AcuStartViewController  *startViewController;

#if ACU_COM_USE_KGMODAL
@property (nonatomic, weak) KGModal                 *startDlg;
#endif

@property (nonatomic, retain) MMDrawerController								*conferencePresentingStarterController;
@property (nonatomic, retain) AcuConferencePresentingLeftViewController			*conferencePresentingLeftViewController;
@property (nonatomic, retain) AcuConferencePresentingRightViewController		*conferencePresentingRightViewController;
@property (nonatomic, retain) AcuConferencePresentingViewController				*conferencePresentingMainViewController;

@end


@implementation AcuConferenceSessionController

@synthesize conferenceParticipantList;
@synthesize parentController;
@synthesize startViewController;
#if ACU_COM_USE_KGMODAL
@synthesize startDlg;
#endif
@synthesize conferencePresentingLeftViewController;
@synthesize conferencePresentingRightViewController;
@synthesize conferencePresentingMainViewController;
@synthesize conferencePresentingStarterController;

- (id)init
{
    self = [super init];
    if (self)
    {
        //_params = [AcuGlobalParams sharedInstance];
		_bReconnection = NO;
		_bInConference = NO;
        
        _conferenceEvent = nil;
        _hasSettedVideoParam = false;
		
		self.conferenceParticipantList = [NSMutableArray new];
        
        _bMMDrawerLeftOpen = NO;
        
        _acucomListener = 0;
        _cancelParam = [AcuStartSessionCancelParam sharedInstance];
        _cancelParam.sessionCanceled = NO;
        _cancelParam.sessionCanceledCommandSended = NO;
        _cancelParam.sessionCanceledInside = NO;
        _cancelParam.sessionCanceledOutside = NO;
        _cancelMutex = [NSLock new];

        _videoCallMode = 1;
        _videoCallAVMode = 0;
        
        _bConferencePresented = NO;
        _startViewControllerDismissTimer = nil;
        
        _forceTerminite = NO;
        _terminiteMutex = [NSLock new];
    }
    
    return self;
}

- (void)startSession:(AcuSessionProperty*)launchSession
	parentController:(UIViewController*)parent
				join:(bool)isJoin
		reconnection:(BOOL)bReconnection
{
    //NSLog(@"launch Session: %@", launchSession->room);
    _bJoin = isJoin;
    _session = launchSession;
    self.parentController = parent;
	_bReconnection = bReconnection;
    
    if (_videoCallMode == 1 && _videoCallAVMode == 1)
    {
        [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    }
    

    _displayName = launchSession->GuestDisplayName;
    [self doStart];
}

//- (void)getDisplayName
//{
//    self.startDlg = [KGModal sharedInstance];
//    self.startDlg.showCloseButton = NO;
//    self.startDlg.tapOutsideToDismiss = NO;
//    
//    AcuDisplayNameViewController *displayNameViewController = [self.parentController.storyboard instantiateViewControllerWithIdentifier:@"AcuDisplayNameDlg"];
//    
//    displayNameViewController.diplayNameDelegate = self;
//    
//    [self.startDlg showWithContentViewController:displayNameViewController andAnimated:YES];
//	
//}

//different name
//  UserID          : HostID
//  UserName        : HostAccount
//  ModuleName      : SessionID
//  ModuleType      : SessionType
//  MaxUser         : MaxParticipant
//  ClearTOC        : ClearToc
//  AllowAllRecord  : AllowRecording
//  AlreadyStarted  : Active

- (void)doStart
{
#if ACU_COM_USE_KGMODAL
    self.startDlg = [KGModal sharedInstance];
    self.startDlg.showCloseButton = NO;
    self.startDlg.tapOutsideToDismiss = NO;
    self.startDlg.animateWhenDismissed = NO;
    self.startDlg.backgroundDisplayStyle = KGModalBackgroundDisplayStyleSolid;
#endif
    self.startViewController = nil;
    self.startViewController = [AcuComVideoCallStoryboard acuComVideoCallStoryboardNamed:@"AcuStartDlg"];
    self.startViewController.startDelegate = self;
    
#if ACU_COM_USE_KGMODAL
    [self.startDlg showWithContentViewController:self.startViewController andAnimated:NO];
#else
    [self.parentController presentViewController:self.startViewController animated:YES completion:^{
        [self.startViewController setDisplayName:_session->LocalTitle];
        
        [self.startViewController setDisplayInfo:NSLocalizedString(@"Conference_Connecting...", @"Start Conference Session Controller")];
    }];
#endif
    
#if 0
    //NSLog(@"session room property:%@", _session->room);
    NSMutableDictionary *sessionParams = [[NSMutableDictionary alloc] init];
    if (_bJoin)
    {
        [sessionParams setObject:@"join_conf" forKey:@"functionid"];
        [sessionParams setObject:[_session->room valueForKey:@"UserID"] forKey:@"hostid"];
        [sessionParams setObject:[_session->room valueForKey:@"ModuleName"] forKey:@"modulename"];
        [sessionParams setObject:[_session->room valueForKey:@"ModuleType"] forKey:@"moduletype"];
    }
    else
    {
        [sessionParams setObject:@"start_conf"
                          forKey:@"functionid"];
        
        [sessionParams setObject:[_session->room valueForKey:@"UserID"]
                          forKey:@"userid"];
        [sessionParams setObject:[_session->room valueForKey:@"ModuleName"]
                          forKey:@"modulename"];
        
        [sessionParams setObject:[_session->room valueForKey:@"ModuleType"]
                          forKey:@"moduletype"];
    }
    _startSessionTask = [[AcuStartSessionTask alloc] init];
    _startSessionTask.startSessionDelegate = self;
    _startSessionTask->_session = _session;
    _startSessionTask->_bJoin = _bJoin;
    
    [_startSessionTask startSession:sessionParams onServer:[_session->room valueForKey:@"MainIP"]];
#else
    //if (!_bReconnection)
//TXB    {
//        [self.startViewController setDisplayName:_session->LocalTitle];
//        
//        [self.startViewController setDisplayInfo:NSLocalizedString(@"Conference_Connecting...", @"Start Conference Session Controller")];
//    }
    
    [self doOPR];
#endif
    
    
//	if (_bReconnection)
//	{
//		[self.startViewController addStatus:NSLocalizedString(@"Control channel disconnectd, reconnecting...", @"Start Conference Session Controller")];
//	}
}

- (void)startComplete
{
    [self doOPR];
}

- (void)doOPR
{
    //[self.startViewController addStatus:NSLocalizedString(@"Getting available server list...", @"Start Conference Session Controller")];
    _oprTask = [[AcuOPRTask alloc] init];
    _oprTask.oprDelegate = self;
    
    
    [_oprTask startOPR:[_session->room valueForKey:@"MainIP"]
            roomHostID:[_session->room valueForKey:@"UserID"]
       roomHostCompany:_session->HostCompany
         roomSessionID:[_session->room valueForKey:@"ModuleName"]];
}

- (void)oprComplete:(AcuOPRResult*)oprResult
{
    if (_cancelParam.sessionCanceledInside)
    {
        if (!_cancelParam.sessionCanceledCommandSended)
        {
            _cancelParam.sessionCanceledCommandSended = YES;
            if (_acucomListener)
            {
                _acucomListener->conferenceClosed(30, nil);
            }
        }
        return;
    }
    
#if 0
	[self.startDlg hide];
	
	
	BOOL bAnimated = NO;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		bAnimated = YES;
	}
	
	
	self.conferencePresentingMainViewController = nil;
	self.conferencePresentingLeftViewController = nil;
    self.conferencePresentingRightViewController = nil;
	self.conferencePresentingStarterController = nil;
	
	self.conferencePresentingMainViewController = [self.parentController.storyboard instantiateViewControllerWithIdentifier:@"AcuConferencePresenting"];
    self.conferencePresentingMainViewController.isHighQualityVideo = _params->bHighVideoQuality;
    self.conferencePresentingMainViewController.isWIFINetwork = _params->bWIFINetwork;
	self.conferencePresentingMainViewController.conferenceDelegate = self;
    self.conferencePresentingMainViewController.conferenceCommandDelegate = self;
	self.conferencePresentingMainViewController.conferenceSessionController = self;
	
	self.conferencePresentingLeftViewController = [self.parentController.storyboard instantiateViewControllerWithIdentifier:@"AcuConferencePresenting_Left"];
	self.conferencePresentingLeftViewController.sendChatDelegate = self;
    self.conferencePresentingLeftViewController.participantListMenuDelegate = self;
    self.conferencePresentingLeftViewController.conferenceCommandDelegate = self;
	
	self.conferencePresentingStarterController = [[IIViewDeckController alloc] initWithCenterViewController:self.conferencePresentingMainViewController
																						 leftViewController:self.conferencePresentingLeftViewController];
	
	
	
	//initialize conference status here
	[self.conferencePresentingMainViewController initConferenceStatus];
	[self.conferencePresentingMainViewController setLayoutStatus:[self getLayoutStatus:_loginHeader.view_id]];
	self.conferencePresentingStarterController.centerhiddenInteractivity = IIViewDeckCenterHiddenNotUserInteractiveWithTapToClose;
	self.conferencePresentingStarterController.delegate = self.conferencePresentingLeftViewController;
	//the center view visiable size after slide bar show
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		self.conferencePresentingStarterController.leftSize = 324;
	}
	else
	{
		NSString *sDeviceModel = [AcuDeviceHardware platformString];
        NSString *aux = [[sDeviceModel componentsSeparatedByString:@","] objectAtIndex:0];
        if ([aux rangeOfString:@"iPhone"].location != NSNotFound)
        {
            int version = [[aux stringByReplacingOccurrencesOfString:@"iPhone" withString:@""] intValue];
            if (version <= 4)
            {
                // <= iPhone 4S
                self.conferencePresentingStarterController.leftSize = 130;
            }
            else if(version == 5 || version == 6)
            {
                //iPhone 5, iPhone 5C, iPhone 5S
                self.conferencePresentingStarterController.leftSize = 130+88;
            }
            else if(version == 7)
            {   
                int minVersion = [[sDeviceModel stringByReplacingOccurrencesOfString:@"iPhone7," withString:@""] intValue];
                if (minVersion == 1)
                {
                    //iPhone 6 Plus
                    self.conferencePresentingStarterController.leftSize = 130+480;
                }
                else if(minVersion == 2)
                {
                    //iPhone 6,
                    self.conferencePresentingStarterController.leftSize = 130+187;
                }
            }
            else
            {
                self.conferencePresentingStarterController.leftSize = 130;
            }
        }
        else if ([aux rangeOfString:@"iPod"].location != NSNotFound)
        {
            int version = [[aux stringByReplacingOccurrencesOfString:@"iPod" withString:@""] intValue];
            if (version <= 4)
            {
                self.conferencePresentingStarterController.leftSize = 130;
            }
            else
            {
                self.conferencePresentingStarterController.leftSize = 130+88;
            }
        }
        else
        {
            self.conferencePresentingStarterController.leftSize = 130;
        }
	}
	//    [_conferencePresentingStarterController enablePanOverViewsOfClass:NSClassFromString(@"JSDismissiveTextView")];
	//    [_conferencePresentingStarterController disablePanOverViewsOfClass:NSClassFromString(@"JSMessageInputView")];
	
	[self.parentController presentViewController:self.conferencePresentingStarterController
										animated:bAnimated
                                      completion:nil];
#else
	
//#define ACU_DEVICE_TYPE_IOS_PAD				4
//#define ACU_DEVICE_TYPE_IOS_PHONE				6
//#define ACU_DEVICE_TYPE_IOS_PAD_V2			10
//#define ACU_DEVICE_TYPE_IOS_PHONE_v2			11

	int ACU_DEVICE_TYPE_IOS_DEVICE = 10;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
	{
		ACU_DEVICE_TYPE_IOS_DEVICE = 11;
	}
	NSMutableDictionary *startSessionParam = [NSMutableDictionary new];
	
	[startSessionParam setObject:[_session->room valueForKey:@"ModuleName"]
						  forKey:@"session_id"];
	//	int anyone_can_start = 0;
	if ([[_session->room valueForKey:@"ModuleName"] isEqualToString:@"0"])
	{
		[startSessionParam setObject:[NSNumber numberWithInt:1]
							  forKey:@"is_author"];
	}
	else
	{
		[startSessionParam setObject:[NSNumber numberWithInt:[_session->IsModerator intValue]]
							  forKey:@"is_author"];
	}
	[startSessionParam setObject:[_session->room valueForKey:@"UserID"]
						  forKey:@"author_name"];
	
	NSMutableString* tempString = [[NSMutableString alloc] initWithString:_session->GuestID];
	[tempString appendString:@"||"];
#if 0
	if(_bJoin)
	{
		[tempString appendString:_session->GuestDisplayName];
	}
	else
	{
		[tempString appendString:_session->HostDisplayName];
	}
#else
    [tempString appendString:_session->GuestDisplayName];
#endif
    
	[startSessionParam setObject:tempString
						  forKey:@"user_name"];
	
	[startSessionParam setObject:_session->GuestPassword
						  forKey:@"password"];
	[startSessionParam setObject:oprResult->gatewayIP
						  forKey:@"main_stream_ip"];
	
    if ([oprResult->myStream length] == 0)
    {
        [startSessionParam setObject:oprResult->gatewayIP
                              forKey:@"stream_ip"];
    }
    else
    {
        [startSessionParam setObject:oprResult->myStream
                              forKey:@"stream_ip"];
    }
	
	
	[startSessionParam setObject:[NSNumber numberWithInt:[_session->Port intValue]]
						  forKey:@"remote_port"];
	
	[startSessionParam setObject:@""
						  forKey:@"local_ip"];
	
	[startSessionParam setObject:[NSNumber numberWithInt:0]
						  forKey:@"local_port"];
	
	[startSessionParam setObject:[NSNumber numberWithInt:0]
						  forKey:@"dof_mode"];
	
	[startSessionParam setObject:[NSNumber numberWithInt:[[_session->room valueForKey:@"ConfMode"] intValue]]
						  forKey:@"conf_mode"];
	
	[startSessionParam setObject:[NSNumber numberWithInt:[[_session->room valueForKey:@"VBRMode"] intValue]]
						  forKey:@"vbr_mode"];
	
	[startSessionParam setObject:[NSNumber numberWithInt:0]
						  forKey:@"hide_self"];
	
	[startSessionParam setObject:[NSNumber numberWithInt:[[_session->room valueForKey:@"AllowAllRecord"] intValue]]
						  forKey:@"record_mode"];
	
	[startSessionParam setObject:[NSNumber numberWithInt:[[_session->room valueForKey:@"MaxUser"] intValue]]
						  forKey:@"max_user"];
	
	[startSessionParam setObject:[NSNumber numberWithInt:[[_session->room valueForKey:@"MaxSpeaker"] intValue]]
						  forKey:@"max_speaker"];
	
	[startSessionParam setObject:[NSNumber numberWithInt:[[_session->room valueForKey:@"MaxSpeed"] intValue]]
						  forKey:@"max_speed"];
	
	//gateway_host_addr
	
	[startSessionParam setObject:oprResult->mainAS->iisIP
						  forKey:@"main_stream_web_svr"];
	
	[startSessionParam setObject:oprResult->mainAS->gatewayIP
						  forKey:@"main_stream_gateway_addr"];
	
	[startSessionParam setObject:_session->AcuManager
						  forKey:@"am_ip"];
	
	if ([oprResult->gatewayParam length] != 0)
	{
		[startSessionParam setObject:oprResult->gatewayParam
							  forKey:@"reserved_param"];
	}
	else
	{
		tempString = [[NSMutableString alloc] initWithString:_session->AcuManager];
		[tempString appendString:@"*"];
		[tempString appendString:_session->HostStream];
		[tempString appendString:@"|"];
		[startSessionParam setObject:tempString
							  forKey:@"reserved_param"];
	}
	
	[startSessionParam setObject:[NSNumber numberWithInt:0]
						  forKey:@"use_multicast"];
	
	[startSessionParam setObject:[NSNumber numberWithInt:0]
						  forKey:@"use_lan_tcp"];
	
	[startSessionParam setObject:[NSNumber numberWithInt:3]
						  forKey:@"retry_times"];
	
	[startSessionParam setObject:[NSNumber numberWithInt:0]
						  forKey:@"rotation_source"];
	
	[startSessionParam setObject:[NSNumber numberWithInt:[[_session->room valueForKey:@"ConfQuality"] intValue]]
						  forKey:@"rotatioin_mode"];
	
	[startSessionParam setObject:[NSNumber numberWithInt:[[_session->room valueForKey:@"QualityPower"] intValue]]
						  forKey:@"video_max_size"];
	
	//zhiyuan not complete
	[startSessionParam setObject:[NSNumber numberWithInt:[[_session->room valueForKey:@"MaxSpeed"] intValue]]
						  forKey:@"video_max_bps"];
	
	
	[startSessionParam setObject:[NSNumber numberWithInt:ACU_DEVICE_TYPE_IOS_DEVICE]
						  forKey:@"device_type"];
	
	[startSessionParam setObject:[NSNumber numberWithInt:0]
						  forKey:@"last_user_id"];
	
	[startSessionParam setObject:[NSNumber numberWithInt:0]
						  forKey:@"last_unique"];
	
	[startSessionParam setObject:[NSNumber numberWithInt:6]
						  forKey:@"view_id"];
	
	[startSessionParam setObject:[NSNumber numberWithInt:4]
						  forKey:@"max_video_ability"];
	
	[startSessionParam setObject:[NSNumber numberWithBool:_session->_bUseUDP]
						  forKey:@"use_udp"];
	
	[startSessionParam setObject:[NSNumber numberWithBool:YES]
						  forKey:@"use_tcp"];
    
    BOOL bUseHighVideoQuality = [self useHighQuality];
    [startSessionParam setObject:[NSNumber numberWithBool:bUseHighVideoQuality]
						  forKey:@"use_high_qulity"];
    
    [startSessionParam setObject:[NSNumber numberWithInt:_session->_amVersion]
                          forKey:@"am_version"];
    
	
	NSError *error = nil;
	NSData *startSessionJson = [NSJSONSerialization dataWithJSONObject:startSessionParam
															   options:NSJSONWritingPrettyPrinted
																 error:&error];
	
	char *confParams = (char*)[startSessionJson bytes];
	//NSLog(@"the json: %s", confParams);
	
	//connect server and start conference
	_conferenceEvent = new AcuConferenceSessionEvent;
	if (!_conferenceEvent)
	{
		//NSLog(@"create conference event error!!!");
		return;
	}
    _conferenceEvent->ExitConference();
	
	_conferenceEvent->setSessionController(self);
	
    bool bRet = false;
    bRet = _conferenceEvent->InitializeConference();
    if (!bRet)
    {
        //set info on start dlg;
		[self.startViewController setErrorStatus:NSLocalizedString(@"Video call error.", @"Start Conference Session Controller")];
		return;
    }
    
    if (_cancelParam.sessionCanceledInside)
    {
        if (!_cancelParam.sessionCanceledCommandSended)
        {
            _cancelParam.sessionCanceledCommandSended = YES;
            if (_acucomListener)
            {
                _acucomListener->conferenceClosed(0, nil);
            }
        }
        return;
    }
	
	_conferenceEvent->StartConference(confParams);
	
	//set info on start dlg;
    //[self.startViewController addStatus:NSLocalizedString(@"Starting conference...", @"Start Conference Session Controller")];
#endif
    
}

- (BOOL)useHighQuality
{
    NSString *sDeviceModel = [AcuDeviceHardware platformString];
    NSString *aux = [[sDeviceModel componentsSeparatedByString:@","] objectAtIndex:0];
    
    if (_session->_bUseHighQuality)
    {
        return YES;
    }
    
    //is low preset iPhone device
    if ([aux rangeOfString:@"iPhone"].location != NSNotFound)
    {
        //check iPhone version
        int version = [[aux stringByReplacingOccurrencesOfString:@"iPhone" withString:@""] intValue];
        //iPhone4 version : 3
        //iPhone4S version : 4
        if (version <= 4)
        {
            //NSLog(@"iPhone4 or iPhone4S");
            return NO;
        }
    }
    
    return YES;
}

-(MMDrawerControllerDrawerVisualStateBlock)getDrawerVisualStateBlock
{
    MMDrawerControllerDrawerVisualStateBlock visualStateBlock =
    ^(MMDrawerController * drawerController, MMDrawerSide drawerSide, CGFloat percentVisible)
    {
        if (drawerSide == MMDrawerSideRight)
        {
            if (percentVisible == 1.0)
            {
                if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
                {
                    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
                }
                
                if (_bInConference)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.conferencePresentingMainViewController updateChatMsgIndicator:YES];
                        
                    });
                }
                
                _bMMDrawerLeftOpen = YES;

            }
            else if (percentVisible == 0.0)
            {
                if (_bInConference)
                {
                    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
                    {
                        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
                    }
                    
                }
                _bMMDrawerLeftOpen = NO;
                
            }
        }
    };
    return visualStateBlock;
}

#pragma mark ----sendChatDelegate----
- (void)sendChatMsg:(NSString*)chatMsg
{
	if (_conferenceEvent)
	{
#if 0
        if ([chatMsg length] == 3)
        {
            NSArray *videoFilterArray = [chatMsg componentsSeparatedByString:@"|"];
            int nVideoIndex = [[videoFilterArray objectAtIndex:0] intValue];
            int nVideoDisable = [[videoFilterArray objectAtIndex:1] intValue];
            _conferenceEvent->UpdateVideoFilter(nVideoIndex, nVideoDisable);
        }
#endif
		NSMutableDictionary *chatMsgDict = [NSMutableDictionary new];
		[chatMsgDict setValue:[NSNumber numberWithInt:0] forKey:@"receive_id"];
		[chatMsgDict setValue:[NSNumber numberWithUnsignedLong:[chatMsg length]] forKey:@"length"];
		[chatMsgDict setValue:chatMsg forKey:@"text"];
		
		
		NSError *error = nil;
		NSData *chatMsgData = [NSJSONSerialization dataWithJSONObject:chatMsgDict
																   options:NSJSONWritingPrettyPrinted
																	 error:&error];
		
		const char *chatJsonData = (const char*)[chatMsgData bytes];
		_conferenceEvent->SendCommand(cmd_chat_message, chatJsonData);
		[chatMsgDict removeAllObjects];
		chatMsgDict = nil;
	}
}

#pragma mark ----AcuParticipantListMenuProtocol----
- (bool)getParticipantListMenu:(int)participantId menuData:(char *)pMenuData dataLen:(int)nLen
{
    if (_conferenceEvent)
    {
        return _conferenceEvent->GetParticipantListMenuData(participantId, pMenuData, nLen);
    }
    
    return false;
}

- (void)sendMenuCommand:(int)cmdID cmdInfo:(const char*)info;
{
    if (_conferenceEvent)
    {
        _conferenceEvent->SendCommand(cmdID, info);
    }
}

//#pragma mark ----AcuDisplayNameViewControllerDelegate----
//
//- (void)acuDisplayNameViewControllerDidCancel:(AcuDisplayNameViewController*)controller
//{
//    [self.startDlg hide];
//
//}
//
//
//- (void)acuDisplayNameViewController:(AcuDisplayNameViewController*)controller didOK:(NSString*)displayname
//{
//    _displayName = displayname;
//    _session->GuestDisplayName = displayname;
//    //[self.startDlg hide];
//    
//    NSMutableDictionary *dict = nil;
//    
//    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
//    NSString *path=[paths objectAtIndex:0];
//    NSString *filename=[path stringByAppendingPathComponent:@"config.plist"];   //获取路径
//    dict = [[NSMutableDictionary alloc] initWithContentsOfFile:filename];
//    
//    if (!dict)
//    {
//        dict = [[NSMutableDictionary alloc] init];
//    }
//    
//    
//    [dict setObject:_params->joinserver forKey:@"joinserver"];
//    [dict setObject:_params->joincompany forKey:@"joincompany"];
//    [dict setObject:_params->joinuser forKey:@"joinuser"];
//    [dict setObject:_displayName forKey:@"displayname"];
//    
//    BOOL bRet = [dict writeToFile:filename atomically:YES];
//    if (bRet)
//    {
//        NSLog(@"Write Display Name OK!");
//    }
//    else
//    {
//        NSLog(@"Write Display Name Error!");
//    }
//	
//	//NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
//	//[standardDefaults setObject:_displayName forKey:@"displayName_key"];
//	//[standardDefaults synchronize];
//    
//    [self doStart];
//    
//
//}


#pragma mark ----AcuStartViewControllerDelegate----

- (void)acuStartViewControllerDidCancel:(AcuStartViewController*)controller
{
    //[_cancelMutex lock];
    _cancelParam.sessionCanceledCommandSended = YES;
    _cancelParam.sessionCanceledInside = YES;
    _cancelParam.sessionCanceled = YES;
    if (_acucomListener)
    {
        _acucomListener->conferenceClosed(30, nil);
    }
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
#if ACU_COM_USE_KGMODAL
        [self.startDlg hideAnimated:NO];
#else
        if (self.startViewController)
        {
            [self.parentController dismissViewControllerAnimated:YES completion:nil];
        }
#endif
        self.startViewController = nil;
        
        if (_bInConference && self.conferencePresentingMainViewController != nil)
        {
            [self.conferencePresentingMainViewController exitConference:AcuConferenceEndStatusLeave];
        }
        else
        {
            [self acuConferencePresentingViewController:nil
                                                 didEnd:AcuConferenceEndStatusLeave];
        }

    });
    //[_cancelMutex unlock];
}

- (void)acuStartViewControllerDidErrorOK
{
    if (_startViewControllerDismissTimer)
    {
        [_startViewControllerDismissTimer invalidate];
        _startViewControllerDismissTimer = nil;
    }
    
    if (self.startViewController)
    {
        [self.parentController dismissViewControllerAnimated:YES completion:nil];
    }
    self.startViewController = nil;
}

- (void)acuStartViewControllerHasError
{
    if (_cancelParam.sessionCanceled)
    {
        return;
    }
    _startViewControllerDismissTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                        target:self
                                                                      selector:@selector(startViewControllerAutoDismiss:)
                                                                      userInfo:nil
                                                                       repeats:NO];
}

- (void)startViewControllerAutoDismiss:(NSTimer*)theTimer
{
    [_startViewControllerDismissTimer invalidate];
    _startViewControllerDismissTimer = nil;
    
    if (self.startViewController)
    {
        [self.parentController dismissViewControllerAnimated:YES completion:nil];
    }
    self.startViewController = nil;
    
    if (!_cancelParam.sessionCanceledCommandSended)
    {
        _cancelParam.sessionCanceledCommandSended = YES;
        if (_acucomListener)
        {
            _acucomListener->conferenceClosed(30, nil);
        }
    }
}

#pragma mark ----AcuStartSessionTaskDelegate----

- (void)acuStartSessionTask:(AcuStartSessionTask*)startSessionTask
                   onResult:(bool)bResult
                   withInfo:(NSString*)info
{
    if (bResult)
    {
        //[self.startViewController addStatus:NSLocalizedString(@"Connected Server Success!", @"Start Conference Session Controller")];
        [self startComplete];
    }
    else
    {
        [self.startViewController setErrorStatus:info];
    }
    
}

#pragma mark ----AcuOPRTaskDelegate----

- (void)acuOPRTask:(AcuOPRTask*)oprTask
          onResult:(AcuOPRResult*)result
          withInfo:(NSString*)info
{
    //[self.startViewController addStatus:info];
    [self oprComplete:result];
}

- (void)acuOPRTask:(AcuOPRTask*)oprTask
     withErrorInfo:(NSString*)info
{
    if (_cancelParam.sessionCanceled)
    {
        return;
    }
    
    [self.startViewController setErrorStatus:info];
}

- (void)acuOPRTask:(AcuOPRTask *)oprTask
        reportInfo:(NSString *)info
{
    //[self.startViewController addStatus:info];
}

#pragma mark ----AcuConferenceCommandDelegate----

- (bool)acuConferenceSendCommand:(int)cmd_id
                        withInfo:(const char*)info
{
    if (_conferenceEvent)
	{
		return _conferenceEvent->SendCommand(cmd_id, info);
	}
	
	return false;
}

- (void)acuConferenceAVSwitch:(int)videoCallAVMode
{
    _videoCallAVMode = videoCallAVMode;
}

#pragma mark ----AcuConferencePresentingDelegate----

- (void)acuConferencePresentingViewController:(AcuConferencePresentingViewController*)controller
                                       didEnd:(AcuConferenceEndStatus)endStatus
{
	_bInConference = false;
    
    if (_videoCallMode == 1 && _videoCallAVMode == 1)
    {
        [UIDevice currentDevice].proximityMonitoringEnabled = NO;
    }
	
    if (AcuConferenceEndStatusReconnection != endStatus)
    {
        BOOL bAnimated = NO;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            bAnimated = YES;
        }
        
        if (self.parentController.presentedViewController)
        {
            [self.parentController dismissViewControllerAnimated:bAnimated
                                                      completion:^{
                                                          _bConferencePresented = NO;
                                                      }];
        }
        
    }
    
	self.conferencePresentingMainViewController.conferenceDelegate = nil;
    self.conferencePresentingMainViewController.conferenceCommandDelegate = nil;
	self.conferencePresentingMainViewController.conferenceSessionController = nil;
    
    self.conferencePresentingLeftViewController.conferenceCommandDelegate = nil;
	self.conferencePresentingLeftViewController.participantListMenuDelegate = nil;
    
    
    
	self.conferencePresentingStarterController = nil;
	self.conferencePresentingMainViewController = nil;
    self.conferencePresentingLeftViewController = nil;
    self.conferencePresentingRightViewController = nil;
    
    if(_conferenceEvent)
	{
		if (endStatus == AcuConferenceEndStatusModeratorLeave)
		{
			//leave with assign host provilige to second one in participant list
			
			AcuParticipantInfo *participantInfo = [self.conferenceParticipantList objectAtIndex:1];
			uint16_t assignHostToUserID = participantInfo.nId;
			
			NSMutableDictionary *commandDict = [NSMutableDictionary new];
			[commandDict setValue:[NSNumber numberWithInt:assignHostToUserID] forKey:@"user_id"];
			
			
			NSError *error = nil;
			NSData *commandData = [NSJSONSerialization dataWithJSONObject:commandDict
																  options:NSJSONWritingPrettyPrinted
																	error:&error];
			
			const char *commandJsonData = (const char*)[commandData bytes];
			_conferenceEvent->SendCommand(cmd_set_moderator, commandJsonData);
			
			[commandDict removeAllObjects];
			commandDict = nil;
			
			[NSThread sleepForTimeInterval:1];
			
			//_conferenceEvent->SendCommand(cmd_terminate_conference, "");
			
		}
		else if(endStatus == AcuConferenceEndStatusModeratorStop)
		{
			_conferenceEvent->SendCommand(cmd_terminate_conference, "");
		}
        
        if (_videoCallMode == 1)
        {
            _conferenceEvent->SendCommand(cmd_terminate_conference, "");
        }
		
		_conferenceEvent->ExitConference();
		_conferenceEvent->setSessionController(nil);
		delete _conferenceEvent;
		_conferenceEvent = nil;
	}
	
	if (endStatus == AcuConferenceEndStatusKickOut)
	{
		UIAlertView *endConferenceAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information", @"Start Conference Session Controller KickOut Alert")
																		 message:NSLocalizedString(@"Your session has been terminated by the host.", @"Start Conference Session Controller KickOut Alert")
																		delegate:nil
															   cancelButtonTitle:NSLocalizedString(@"OK", @"Start Conference Session Controller KickOut Alert")
															   otherButtonTitles:nil];
		
		[endConferenceAlertView show];
		
	}
	
	[self.conferenceParticipantList removeAllObjects];
	self.conferenceParticipantList = nil;
	_startSessionTask = nil;
	_oprTask = nil;
    //self.startViewController.view.hidden = YES;
	self.startViewController = nil;
    _hasSettedVideoParam = false;
    
#if 0
    if (endStatus == AcuConferenceEndStatusModeratorLeave ||
        endStatus == AcuConferenceEndStatusModeratorStop ||
        endStatus == AcuConferenceEndStatusUserRejected)
    {
        if (_acucomListener)
        {
            _acucomListener->conferenceClosed(5, nil);
        }
    }
    else if (endStatus == AcuConferenceEndStatusLeave ||
             endStatus == AcuConferenceEndStatusStopped)
    {
        if (_acucomListener && !_cancelParam.sessionCanceled)
        {
            _acucomListener->conferenceClosed(1, nil);
        }
    }
    else if (endStatus == AcuConferenceEndStatusKickOut)
    {
        if (_acucomListener)
        {
            _acucomListener->conferenceClosed(10, nil);
        }
    }
#else
    if (_acucomListener && endStatus != AcuConferenceEndStatusReconnection)
    {
        _acucomListener->conferenceClosed(30, nil);
    }
#endif
}


#pragma mark ----AcuConferenceSession Logic----

- (void)onUserEvent:(int)event_id
		   withInfo:(char*)utf8_str
{
    if (_cancelParam.sessionCanceledInside)
    {
        if (!_cancelParam.sessionCanceledCommandSended)
        {
            _cancelParam.sessionCanceledCommandSended = YES;
            
            if (_acucomListener)
            {
                _acucomListener->conferenceClosed(0, nil);
            }
        }
        return;
    }
    
    if(_forceTerminite)
    {
        return;
    }
    
	if (!_conferenceEvent)
	{
		return;
	}
    
    //[_cancelMutex lock];
	
	NSString *jsonString = [NSString stringWithUTF8String:utf8_str];
	NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
	NSMutableDictionary *userInfo = [NSJSONSerialization JSONObjectWithData:jsonData
																	options:NSJSONReadingMutableContainers
																	  error:nil];
	
	//NSLog(@"onUserEvent ---- event_id:%d,\n info:%@\n", (CONF_EVENT_TYPE)event_id, userInfo);
	
	switch (event_id)
	{
        case event_enter_conference_failed:
        {
            int nErrorCode = [[userInfo valueForKey:@"error_code"] intValue];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                BOOL bShowError = YES;
                NSMutableString *errorInfo;
                switch( nErrorCode )
                {
					case eFAILED_VERSION_SMALL :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Software is out dated. Please upgrade the software from the server.", @"Conference Error Code Info")];
						break;
					}
					case eFAILED_VERSION_LARGE :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Software version is higher and not compatible. Please install the software from the server.", @"Conference Error Code Info")];
						break;
					}
					case eFAILED_CREATE_SESSION :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Fail to create session.", @"Conference Error Code Info")];
						break;
					}
					case eFAILED_WAIT_FINISH :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Timeout.", @"Conference Error Code Info")];
						break;
					}
					case eFAILED_FIND_SESSION :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Session not found.", @"Conference Error Code Info")];
						break;
					}
					case eFAILED_CHECK_PASSWORD :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Password error!", @"Conference Error Code Info")];
						break;
					}
					case eFAILED_SESSION_STOPING :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Session has ended.", @"Conference Error Code Info")];
                        break;
					}
					case eFAILED_SESSION_STOPING_AS :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Session has ended.", @"Conference Error Code Info")];
						break;
					}
					case eAILED_SESSION_STARTING :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Session has not started. Please try again later.", @"Conference Error Code Info")];
						break;
					}
					case eFAILED_WAIT_FINISH_AS :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Server timeout.", @"Conference Error Code Info")];
						break;
					}
					case eFAILED_CREATE_SESSION_AS :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Server fails to create session.", @"Conference Error Code Info")];
						break;
					}
					case eFAILED_SIP_START_SESSION :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"SIP server fails to start.", @"Conference Error Code Info")];
						break;
					}
					case eFAILED_GRANT :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Authorization failure.", @"Conference Error Code Info")];
						break;
					}
					case eFAILED_EX_PARAMTER :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Invaid extension parameter!", @"Conference Error Code Info")];
						break;
					}
					case eFAILED_CONNECTION_MAS :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Cannot connect to server. Please contact your administrator.", @"Conference Error Code Info")];
						break;
					}
					case eFAILED_AUTH_FAILED :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Authorization failure.", @"Conference Error Code Info")];
						break;
					}
					case eFAILED_MAX_SESSION :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Exceeded the maximum number of connections.", @"Conference Error Code Info")];
						break;
					}
					case eACU_FAILED_NO_GATEWAY :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Server not found. Please contact your administrator.", @"Conference Error Code Info")];
						break;
					}
					case eACU_FAILED_DNS_SRC :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Cannot connect to server. Please contact your administrator.", @"Conference Error Code Info")];
						break;
					}
					case eACU_FAILED_DNS_DEST :
					{
                        errorInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Cannot connect to server. Please contact your administrator.", @"Conference Error Code Info")];
						break;
					}
					default :
                    {
                        bShowError = NO;
						break;
                    }
				}

                if (bShowError)
                {
                    [self.startViewController setErrorStatus:errorInfo];
                    errorInfo = nil;
                }
                
            });
            break;
        }
            
		case event_channel_connn:
		{
			//server address
			NSString *strConnSvr = [userInfo valueForKey:@"server"];
            
			//sever's port
			int nPort = [[userInfo valueForKey:@"server_port"] intValue];
			
			NSString *strConnectType;
			int conn_type = [[userInfo valueForKey:@"connection_type"] intValue];
			if( conn_type == CONNECTION_TCP )
			{
				strConnectType = @"TCP";
			}
			else if( conn_type == CONNECTION_UDP )
			{
				strConnectType = @"UDP";
			}
			
			NSString *strChannelType;
			int channel_type = [[userInfo valueForKey:@"channel_type"] intValue];
			if( channel_type == CHANNEL_AUDIO )
			{
				strChannelType = @"Audio channel";
			}
			else if( channel_type == CHANNEL_VIDEO)
			{
				strChannelType = @"Video channel";
			}
			else if( channel_type == CHANNEL_CONTROL )
			{
				strChannelType = @"Control channel";
			}
			else if( channel_type == CHANNEL_SCREEN )
			{
				strChannelType = @"Screen channel";
			}
			else if( channel_type == CHANNEL_UNKNOWN )
			{
				strChannelType = @"Unknown channel";
			}
			
			int conn_status = [[userInfo valueForKey:@"channel_conn_status"] intValue];			
			if(channel_type == CHANNEL_CONTROL &&  conn_status == conn_ok )
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					if(channel_type == CHANNEL_CONTROL)
					{
//						NSMutableString *connectInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Control channel connected to:", @"Start Confernece Session Controller")];
//						[connectInfo appendFormat:@"%@:%@ %@", strConnSvr, strPort, strConnectType];
//						[self.startViewController addStatus:connectInfo];
//						connectInfo = nil;
//						
//						[self.startViewController addStatus:NSLocalizedString(@"Control channel connected OK!", @"Start Confernece Session Controller")];
					}
				});
			}
			else if(channel_type == CHANNEL_CONTROL && conn_status == conn_disconnection )
			{
                //NSLog(@"conntrol channel disconnected!");
                if (_bInConference)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //[self.startViewController clearStatus];
                        [self.conferencePresentingMainViewController deallocResource];
                        
                        BOOL bAnimated = NO;
                        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                        {
                            bAnimated = YES;
                        }
                        [self.parentController dismissViewControllerAnimated:bAnimated completion:^{
                            _bConferencePresented = NO;
                            [self acuConferencePresentingViewController:nil
                                                                 didEnd:AcuConferenceEndStatusReconnection];
                            
                            [self startSession:_session
                              parentController:self.parentController
                                          join:_bJoin
                                  reconnection:YES];
                        }];
                    });
                }
				
			}
			else if(channel_type == CHANNEL_CONTROL && conn_status == conn_failure )
			{
				//NSLog(@"Warnning -- control channel failure");
				dispatch_async(dispatch_get_main_queue(), ^{
                    if( conn_type == CONNECTION_TCP && nPort == 80 )
                    {
                        [self.startViewController setErrorStatus:NSLocalizedString(@"Video call error.", @"Start Confernece Session Controller")];
                    }
                    
//					NSMutableString *connectInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Control Channel Connecting failure.", @"Start Confernece Session Controller")];
//					[self.startViewController setErrorStatus:connectInfo];
//					connectInfo = nil;
				});
			}
			else if(channel_type == CHANNEL_CONTROL && conn_status == conn_is_connecting )
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					NSMutableString *connectInfo = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Control Channel Connecting...", @"Start Confernece Session Controller")];
					//[self.startViewController addStatus:connectInfo];
					connectInfo = nil;
				});
			}
			
			break;
		}
			
		case event_follow_presenter_layout:
		{
			if (_bInConference)
			{
				_loginHeader.video_max_bps			= [[userInfo valueForKey:@"video_max_bps"] unsignedShortValue];
				_loginHeader.video_max_width		= [[userInfo valueForKey:@"video_max_width"] unsignedShortValue];
				_loginHeader.video_max_height		= [[userInfo valueForKey:@"video_max_height"] unsignedShortValue];
				_loginHeader.view_id				= [[userInfo valueForKey:@"view_id"] unsignedShortValue];
				
				AcuConferenceLayoutStatus layoutStatus = [self getLayoutStatus:_loginHeader.view_id];
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.conferencePresentingMainViewController setLayoutStatus:layoutStatus];
				});
			}
			break;
		}	
			
		case event_enter_conference:
		{
            [UIApplication sharedApplication].idleTimerDisabled = NO;
            [UIApplication sharedApplication].idleTimerDisabled = YES;
			_conferenceEvent->SetInputSampleRate(16000);
			_conferenceEvent->SetOutputSampleRate(16000);
			_conferenceSessionID = [[userInfo valueForKey:@"session_id"] unsignedShortValue];
			_bInConference = YES;
			
			dispatch_async(dispatch_get_main_queue(), ^{
                [_terminiteMutex lock];
				BOOL bAnimated = NO;
				if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				{
					bAnimated = YES;
				}

                self.conferencePresentingMainViewController = nil;
				self.conferencePresentingLeftViewController = nil;
                self.conferencePresentingRightViewController = nil;
				self.conferencePresentingStarterController = nil;
				
                self.conferencePresentingMainViewController = [AcuComVideoCallStoryboard acuComVideoCallStoryboardNamed:@"AcuConferencePresenting"];
                
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                {
                    self.conferencePresentingMainViewController.isHDQuality = YES;
                }
                else
                {
                    self.conferencePresentingMainViewController.isHDQuality = NO;
                }
				
                self.conferencePresentingMainViewController.isHighQualityVideo = _session->_bUseHighQuality;
                self.conferencePresentingMainViewController.isWIFINetwork = YES;
				self.conferencePresentingMainViewController.conferenceDelegate = self;
                self.conferencePresentingMainViewController.conferenceCommandDelegate = self;
				self.conferencePresentingMainViewController.conferenceSessionController = self;
                [self.conferencePresentingMainViewController setVideoCallAVMode:_videoCallAVMode];
                [self.conferencePresentingMainViewController setVideoCallMode:_videoCallMode];
                if (_acucomListener)
                {
                    [self.conferencePresentingMainViewController setAcuComListener:_acucomListener];
                }
                
                if ([_session->SenderID isEqualToString:_session->GuestID])
                {
                    [self.conferencePresentingMainViewController setVideoCallLauncher:YES];
                }
                else
                {
                    [self.conferencePresentingMainViewController setVideoCallLauncher:NO];
                }
				
                self.conferencePresentingLeftViewController = [AcuComVideoCallStoryboard acuComVideoCallStoryboardNamed:@"AcuConferencePresenting_Left"];
				
                [self.conferencePresentingLeftViewController initConferenceMode:_loginHeader.conference_mode
                                                                   videoQuality:_loginHeader.company_video_quality
                                                                     videoWidth:_loginHeader.video_max_width
                                                                    videoHeight:_loginHeader.video_max_height];
                self.conferencePresentingLeftViewController.participantListMenuDelegate = self;
                self.conferencePresentingLeftViewController.conferenceCommandDelegate = self;
                self.conferencePresentingRightViewController = [AcuComVideoCallStoryboard acuComVideoCallStoryboardNamed:@"AcuConferencePresenting_Right"];
                
#if 0
                if (_videoCallMode == 0)
                {
                    self.conferencePresentingStarterController = [[MMDrawerController alloc] initWithCenterViewController:self.conferencePresentingMainViewController
                                                                                                 leftDrawerViewController:self.conferencePresentingLeftViewController
                                                                                                rightDrawerViewController:self.conferencePresentingRightViewController];
                }
                else
                {
                    self.conferencePresentingStarterController = [[MMDrawerController alloc] initWithCenterViewController:self.conferencePresentingMainViewController
                                                                                                rightDrawerViewController:self.conferencePresentingRightViewController];
                }
#else
                if (_videoCallMode == 0)
                {
                    self.conferencePresentingStarterController = [[MMDrawerController alloc] initWithCenterViewController:self.conferencePresentingMainViewController
                                                                                                 leftDrawerViewController:self.conferencePresentingLeftViewController
                                                                                                rightDrawerViewController:nil];
                }
                else
                {
                    self.conferencePresentingStarterController = [[MMDrawerController alloc] initWithCenterViewController:self.conferencePresentingMainViewController
                                                                                                rightDrawerViewController:nil];
                }
#endif
                [self.conferencePresentingStarterController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeAll];
                [self.conferencePresentingStarterController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeAll];
                [self.conferencePresentingStarterController setDrawerVisualStateBlock:[self getDrawerVisualStateBlock]];
				
				
				//initialize conference status here
				[self.conferencePresentingMainViewController initConferenceStatus];
				[self.conferencePresentingMainViewController setLayoutStatus:[self getLayoutStatus:_loginHeader.view_id]];

				//the center view visiable size after slide bar show
				if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				{
                    [self.conferencePresentingStarterController setMaximumLeftDrawerWidth:700];
                    [self.conferencePresentingStarterController setMaximumRightDrawerWidth:700];
				}
				else
                {
                    NSString *sDeviceModel = [AcuDeviceHardware platformString];
                    NSString *aux = [[sDeviceModel componentsSeparatedByString:@","] objectAtIndex:0];
                    if ([aux rangeOfString:@"iPhone"].location != NSNotFound)
                    {
                        int version = [[aux stringByReplacingOccurrencesOfString:@"iPhone" withString:@""] intValue];
                        if (version <= 4)
                        {
                            // <= iPhone 4S
                            [self.conferencePresentingStarterController setMaximumLeftDrawerWidth:250];
                            [self.conferencePresentingStarterController setMaximumRightDrawerWidth:250];
                        }
                        else if (version >= 5) //if(version == 5 || version == 6)
                        {
                            //iPhone 5, iPhone 5C, iPhone 5S, iPhone6, iPhone6Plus
                            [self.conferencePresentingStarterController setMaximumLeftDrawerWidth:250];
                            [self.conferencePresentingStarterController setMaximumRightDrawerWidth:250];
                        }
                        else
                        {
                            [self.conferencePresentingStarterController setMaximumLeftDrawerWidth:250];
                            [self.conferencePresentingStarterController setMaximumRightDrawerWidth:250];
                        }
                    }
                    else if ([aux rangeOfString:@"iPod"].location != NSNotFound)
                    {
                        int version = [[aux stringByReplacingOccurrencesOfString:@"iPod" withString:@""] intValue];
                        if (version <= 4)
                        {
                            [self.conferencePresentingStarterController setMaximumLeftDrawerWidth:250];
                            [self.conferencePresentingStarterController setMaximumRightDrawerWidth:250];
                        }
                        else
                        {
                            [self.conferencePresentingStarterController setMaximumLeftDrawerWidth:250];
                            [self.conferencePresentingStarterController setMaximumRightDrawerWidth:250];
                        }
                    }
                    else
                    {
                        [self.conferencePresentingStarterController setMaximumLeftDrawerWidth:250];
                        [self.conferencePresentingStarterController setMaximumRightDrawerWidth:250];
                    }
                }
				//    [_conferencePresentingStarterController enablePanOverViewsOfClass:NSClassFromString(@"JSDismissiveTextView")];
				//    [_conferencePresentingStarterController disablePanOverViewsOfClass:NSClassFromString(@"JSMessageInputView")];

#if ACU_COM_USE_KGMODAL
                [self.startDlg hideAnimated:NO];
#else
                [self.parentController dismissViewControllerAnimated:NO completion:^{
                    [_terminiteMutex lock];
                    self.startViewController = nil;
                    if (self.conferencePresentingStarterController)
                    {
                        [self.parentController presentViewController:self.conferencePresentingStarterController
                                                            animated:bAnimated
                                                          completion:^{
                                                              _bConferencePresented = YES;
                                                          }];
                    }
                    else
                    {
                        [self acuConferencePresentingViewController:nil
                                                             didEnd:AcuConferenceEndStatusLeave];
                    }
                    
                    [_terminiteMutex unlock];
                }];
#endif
                
				[_terminiteMutex unlock];
				
			});
			break;
		}	
			
		case event_exit_conference:
		{
			if (_bInConference)
			{
				int endReason = [[userInfo valueForKey:@"exit_reason"] intValue];
				NSString *reasonDesc = [userInfo valueForKey:@"reason_description"];
				dispatch_async(dispatch_get_main_queue(), ^{
#if 0
					[self.parentController dismissViewControllerAnimated:NO completion:nil];
					
					self.conferencePresentingStarterController.delegate = nil;
					self.conferencePresentingMainViewController.conferenceDelegate = nil;
					self.conferencePresentingMainViewController.conferenceSessionController = nil;
					self.conferencePresentingMainViewController = nil;
					self.conferencePresentingLeftViewController = nil;
					self.conferencePresentingStarterController = nil;
					
					_conferenceEvent->ExitConference();
#else
					[self.conferencePresentingMainViewController endConference:endReason
																andDescription:reasonDesc];
#endif
				});
			}
			break;
		}
			
		case event_user_enter:
		{
			break;
		}
			
		case event_be_invited_presenter:
		{
			if (_bInConference)
			{
				int nStatus = [[userInfo valueForKey:@"status"] intValue];
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.conferencePresentingMainViewController invite2Present:nStatus];
				});
			}
			break;
		}
			
		case event_be_invited_speaker:
		{
			if (_bInConference)
			{
				int nStatus = [[userInfo valueForKey:@"status"] intValue];
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.conferencePresentingMainViewController invite2Speaker:nStatus];
				});
			}
			break;
		}
			
			
		case event_remote_user_audio_status_changed:
		{
			uint16_t userID = [[userInfo valueForKey:@"user_id"] unsignedShortValue];
			BOOL bEnable = [[userInfo valueForKey:@"enable"] boolValue];
			if (userID == _loginHeader.user_id)
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.conferencePresentingMainViewController remoteMuteLocalAudio:!bEnable];
				});
			}
			break;
		}
			
		case event_remote_user_video_status_changed:
		{
			uint16_t userID = [[userInfo valueForKey:@"user_id"] unsignedShortValue];
			BOOL bEnable = [[userInfo valueForKey:@"enable"] boolValue];
			if (userID == _loginHeader.user_id)
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.conferencePresentingMainViewController remoteMuteLocalVideo:!bEnable];
				});
			}
			break;
		}
			
		case event_active_speaker:
		{
			if (_bInConference)
			{
				uint16_t activeSpeakerID = [[userInfo valueForKey:@"user_id"] unsignedShortValue];
				
				if (activeSpeakerID > 0)
				{
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.conferencePresentingMainViewController setActiveSpeaker:activeSpeakerID];
					});
				}
			}
			break;
		}
			
		case event_conference_mode_changed:
		{
            if (_bInConference)
            {
                int nConferenceMode = [[userInfo valueForKey:@"conf_mode"] unsignedShortValue];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.conferencePresentingLeftViewController setConferneceMode:nConferenceMode];
                });
            }
			break;
		}
			
		case event_moderator_role_changed:
		{
			if (_bInConference)
			{
				uint16_t userID = [[userInfo valueForKey:@"user_id"] unsignedShortValue];
				BOOL bStatus = [[userInfo valueForKey:@"status"] boolValue];
				if (userID == _loginHeader.user_id)
				{
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.conferencePresentingMainViewController setModeratorRole:bStatus];
                        [self.conferencePresentingLeftViewController setModeratorRole:bStatus];
					});
				}
			}
			break;
		}
			
		case event_participant_role_changed:
		{
			break;
		}
			
		case event_presenter_role_changed:
		{
			if (_bInConference)
			{
				uint16_t userID = [[userInfo valueForKey:@"user_id"] unsignedShortValue];
				BOOL bStatus = [[userInfo valueForKey:@"status"] boolValue];
				if (userID == _loginHeader.user_id)
				{
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.conferencePresentingMainViewController setPresenterRole:bStatus];
					});
				}
			}
			break;
		}
			
		case event_speaker_role_changed:
		{
			if (_bInConference)
			{
				uint16_t userID = [[userInfo valueForKey:@"user_id"] unsignedShortValue];
				BOOL bStatus = [[userInfo valueForKey:@"status"] boolValue];
				if (userID == _loginHeader.user_id)
				{
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.conferencePresentingMainViewController setSpeakerRole:bStatus];
					});
				}
			}
			break;
		}
			
#if 0
		case event_user_chat_message:
		{
			if (_bInConference)
			{
				uint16_t senderID = [[userInfo valueForKey:@"sender_id"] unsignedShortValue];
				NSString *message = [userInfo valueForKey:@"message"];
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.conferencePresentingLeftViewController addChatMessage:senderID
																		message:message];
					

                    if (!_bMMDrawerLeftOpen)
                    {
                        [self.conferencePresentingMainViewController updateChatMsgIndicator:NO];
                    }
				});
			}

			break;
		}
#endif
			
		case event_user_exit:
		{
			if (_bInConference)
			{
                uint16_t exitUserID = [[userInfo valueForKey:@"user_id"] unsignedShortValue];
                dispatch_async(dispatch_get_main_queue(), ^{
                    bool bFind = false;
                    AcuParticipantInfo *participantInfo;
                    NSUInteger removeIndex = 0;
                    for (participantInfo in self.conferenceParticipantList)
                    {
                        if (participantInfo.nId == exitUserID)
                        {
                            bFind = true;
                            break;
                        }
                        removeIndex++;
                    }
                    
                    if (bFind)
                    {
                        [self.conferenceParticipantList removeObject:participantInfo];
                        [self updateParticipantList];
                    }
                });
            }
			break;
		}
			
			
		case event_user_list_changed:
		{
			if (_bInConference)
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					NSMutableArray *tempParticipantList = [[NSMutableArray alloc] init];
					if(_conferenceEvent->GetUserList(tempParticipantList))
					{
						[self.conferenceParticipantList removeAllObjects];
						self.conferenceParticipantList = tempParticipantList;
						[self updateParticipantList];
					}
					tempParticipantList = nil;
				});
			}
			break;
		}
			
		case event_login_info:
		{
			dispatch_async(dispatch_get_main_queue(), ^{
#if 0
				[self.startDlg hideAnimated:NO];
                //self.startViewController.view.hidden = YES;
                self.startViewController = nil;
#else
                if (self.startViewController)
                {
                    [self.startViewController setConnectedStatus];
                }
#endif
                
			});
			_loginHeader.active_speaker			= [[userInfo valueForKey:@"active_speaker"] unsignedShortValue];
			_loginHeader.bIsStarter				= [[userInfo valueForKey:@"is_room_starter"] boolValue];
			_loginHeader.user_id				= [[userInfo valueForKey:@"user_id"] unsignedShortValue];
			_loginHeader.user_unique_id			= [[userInfo valueForKey:@"user_unique_id"] unsignedIntValue];
			_loginHeader.video_max_bps			= [[userInfo valueForKey:@"video_max_bps"] unsignedShortValue];
			_loginHeader.video_max_width		= [[userInfo valueForKey:@"video_max_width"] unsignedShortValue];
			_loginHeader.video_max_height		= [[userInfo valueForKey:@"video_max_height"] unsignedShortValue];
			_loginHeader.view_id				= [[userInfo valueForKey:@"view_id"] unsignedShortValue];
            _loginHeader.conference_mode        = [[userInfo valueForKey:@"coference_mode"] unsignedShortValue];
            //_loginHeader.video_quality          = [[userInfo valueForKey:@"video_quality"] unsignedShortValue];
            _loginHeader.company_video_quality  = [[_session->room valueForKey:@"QualityPower"] integerValue];
            _loginHeader.room_video_quality     = [[_session->room valueForKey:@"ConfQuality"] integerValue];
            
            dispatch_async(dispatch_get_main_queue(), ^{
				if (self.conferencePresentingLeftViewController)
                {
                    [self.conferencePresentingLeftViewController initConferenceMode:_loginHeader.conference_mode
                                                                       videoQuality:_loginHeader.company_video_quality
                                                                         videoWidth:_loginHeader.video_max_width
                                                                        videoHeight:_loginHeader.video_max_height];
                }
			});
            
			
			//			AcuParticipantInfo *localUserInfo = [[AcuParticipantInfo alloc] init];
			//			localUserInfo.nId = _localUserID;
			//			localUserInfo.sUserName = _displayName;
			//			localUserInfo.bHasAudio = true;
			//			localUserInfo.bHasVideo = true;
			//			[self.conferenceParticipantList addObject:localUserInfo];
			break;
		}
			
		case event_user_hand_up_changed:
		{
			uint16_t userID = [[userInfo valueForKey:@"user_id"] unsignedShortValue];
			BOOL is_hanging_up = [[userInfo valueForKey:@"is_handing_up"] boolValue];
			if (userID == _loginHeader.user_id)
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.conferencePresentingMainViewController setHangingUp:is_hanging_up];
				});
			}
			break;
		}
            
        case event_update_bandwidth_measure:
        {
            if(_bInConference)
            {
                uint16_t nStatus = [[userInfo valueForKey:@"status"] unsignedShortValue];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.conferencePresentingMainViewController updateNetworkIndicator:(AcuConferenceNetworkStatus)nStatus];
                });
            }
            break;
        }
            
        case event_update_presenter_button_status :
		{
            if(_bInConference)
            {
                uint16_t nStatus = [[userInfo valueForKey:@"status"] unsignedShortValue];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.conferencePresentingMainViewController updateToolbarPresenterBtnStatus:nStatus];
                });
            }
			break;
		}
            
        case event_room_video_size_changed:
        {
            if (_bInConference)
            {
                _loginHeader.video_max_width = [[userInfo valueForKey:@"video_width"] unsignedShortValue];
                _loginHeader.video_max_height = [[userInfo valueForKey:@"video_height"] unsignedShortValue];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.conferencePresentingLeftViewController setVideoQualityWithWidth:_loginHeader.video_max_width
                                                                              videoHeight:_loginHeader.video_max_height];
                });
            }
            break;
        }
            
        case event_custom_command_notification:
        {
            if (_bInConference)
            {
                int nCount = 0;
                do
                {
                    if (nCount >= 10)
                    {
                        break;
                    }
                    
                    [NSThread sleepForTimeInterval:1.0];
                    
                    nCount++;
                    
                }while (!_bConferencePresented);
                
                int cmd_type = [[userInfo valueForKey:@"cmd_type"] intValue];
                if (cmd_type == CUSTOME_CMDTYPE_ENTER_CONFERENCE_MODE)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self setVideoCallMode:0];
                    });
                }
                
            }
            
            break;
        }
			
		default:
			break;
	}
	
	jsonString = nil;
	jsonData = nil;
	userInfo = nil;
    
    //[_cancelMutex unlock];
}

- (void)setCaptureVideoData:(char*)pVideoData
		captureVideoDataLen:(int)nVideoDataLen
		  captureVideoWidth:(int)nVideoWidth
		 captureVideoHeight:(int)nVideoHeight
	 captureVideoColorSpace:(FourCharCode)videoColorSpace
{
	if (_conferenceEvent)
	{
        if (!_hasSettedVideoParam)
        {
            if (nVideoWidth*nVideoHeight > 192*144)
            {
                _conferenceEvent->SetVideoParam(384, 15, 2);
            }
            else
            {
                _conferenceEvent->SetVideoParam(64, 15, 2);
            }
            
            _hasSettedVideoParam = true;
        }
        
		_conferenceEvent->SendVideo(pVideoData,
									nVideoDataLen,
									nVideoWidth,
									nVideoHeight,
									9);
		
	}
	
}

- (bool)getRemoteVideo:(int)nIndex
	   remoteVideoData:(unsigned char**)pVideoData
 remoteVideoDataLength:(int*)nVideoDataLen
 remoteVideoBufferSize:(int*)nVideoBufferSize
	  remoteVideoWidth:(int*)nVideoWidth
	 remoteVideoHeight:(int*)nVideoHeight
 remoteVideoColorSpace:(int*)nVideoColorSpace
	 remoteVideoUserID:(int*)nVideoUserID;
{
	bool bRet = false;
	if (_conferenceEvent)
	{
		bRet = _conferenceEvent->GetVideoData(nIndex,
											  pVideoData,
											  nVideoDataLen,
											  nVideoBufferSize,
											  nVideoWidth,
											  nVideoHeight,
											  nVideoColorSpace,
											  nVideoUserID);
	}
	
	return bRet;
	
}

- (void)freeRemoteVideoData:(unsigned char*)pVideoData
	  remoteVideoBufferSize:(int)nVideoBufferSize
{
	if (_conferenceEvent)
	{
		_conferenceEvent->FreeVideoDataEx(pVideoData, nVideoBufferSize);
	}
}

- (void)setCaptureAudioData:(char*)pAudioData
		captureAudioDataLen:(int)nAudioDataLen
{
	if (_conferenceEvent)
	{
		_conferenceEvent->SendAudio(pAudioData, nAudioDataLen);
	}
	
}

- (void)getPlayAudioData:(char*)pAudioData
		playAudioDataLen:(int)nAudioDataLen
{
	if (_conferenceEvent) {
		_conferenceEvent->GetAudioData(pAudioData, nAudioDataLen);
	}
	
}



- (void)updateParticipantList
{
	if (self.conferencePresentingLeftViewController)
	{
		[self.conferencePresentingLeftViewController updateParticipantList:self.conferenceParticipantList];
	}
	
	if (self.conferencePresentingMainViewController)
	{
		[self.conferencePresentingMainViewController updateParticipantList:self.conferenceParticipantList];
	}
}


- (AcuConferenceLayoutStatus)getLayoutStatus:(int)nViewID
{
//	eNormalView = 1,		//Normal view, not used now
//	eLectureView,			//1+S
//	eVideoDiscussionView,	//4+S
//	eChatView,				//0+S
//	eLargeView,				//2+S
//	e1VideoView,			//1 Video View
//	e2VideoView,
//	e4VideoView,
//	e9VideoView,
//	e16VideoView,
//	e25VideoView,
//	e1Plus_N_View,
//	e1Plus_5_View,
//	e3S_View,				//3+S
//	eFullScreenView
	AcuConferenceLayoutStatus layoutStatus = AcuConferenceLayoutStatus1Video;
	AcuLayoutTag eLayout = (AcuLayoutTag)nViewID;
	switch (eLayout)
	{
		case eLectureView:
		{
			layoutStatus = AcuConferenceLayoutStatus1SVideo;
			break;
		}
		
		case eLargeView:
		case e3S_View:
		case eVideoDiscussionView:
		{
			layoutStatus = AcuConferenceLayoutStatus2SVideo;
			break;
		}
			
		case e1VideoView:
		{
			layoutStatus = AcuConferenceLayoutStatus1Video;
			break;
		}
		
		case e2VideoView:
		{
			layoutStatus = AcuConferenceLayoutStatus2Video;
			break;
		}
			
		case e4VideoView:
		case e9VideoView:
		case e16VideoView:
		case e25VideoView:
		case e1Plus_N_View:
		case e1Plus_5_View:
		{
			layoutStatus = AcuConferenceLayoutStatus4Video;
			break;
		}
			
		case eChatView:
		{
			layoutStatus = AcuConferenceLayoutStatus0SVideo;
			break;
		}
			
		default:
			break;
	}
	return layoutStatus;
}

#pragma mark ----AcuCom----
- (void)enterConferenceMode
{
    if (_bConferencePresented)
    {
        [self.parentController dismissViewControllerAnimated:NO
                                                  completion:^{
                                                      _bConferencePresented = NO;
                                                  }];
        [self.parentController presentViewController:self.conferencePresentingStarterController
                                            animated:NO
                                          completion:^{
                                              _bConferencePresented = YES;
                                          }];

    }
    else
    {
        NSLog(@"Enter Confernece Mode error");
    }
    
}

- (void)canceledConference
{
    //[_cancelMutex lock];
    
    _cancelParam.sessionCanceledCommandSended = YES;
    _cancelParam.sessionCanceledOutside = YES;
    _cancelParam.sessionCanceled = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
#if ACU_COM_USE_KGMODAL
        [self.startDlg hideAnimated:NO];
#else
        if (self.startViewController)
        {
            [self.parentController dismissViewControllerAnimated:YES completion:nil];
        }
#endif
        self.startViewController = nil;
        
        if (_bInConference && self.conferencePresentingMainViewController != nil)
        {
            [self.conferencePresentingMainViewController exitConference:AcuConferenceEndStatusLeave];
        }
        else
        {
            [self acuConferencePresentingViewController:nil
                                                 didEnd:AcuConferenceEndStatusLeave];
        }
    });
    //[_cancelMutex unlock];
}

- (void)setAcuComListener:(AcuComListener*)listener
{
    _acucomListener = listener;
    if (_bInConference)
    {
        [self.conferencePresentingMainViewController setAcuComListener:listener];
    }
}

- (void)setVideoCallMode:(int)videoCallMode
{
    _videoCallMode = videoCallMode;
    if (_videoCallMode == 0 && _bInConference)
    {
        [self.conferencePresentingStarterController setLeftDrawerViewController:self.conferencePresentingLeftViewController];
        [self.conferencePresentingMainViewController setVideoCallMode:_videoCallMode];
        [self enterConferenceMode];
    }
}

- (void)setVideoCallAVMode:(int)videoCallAVMode
{
    _videoCallAVMode = videoCallAVMode;
}

- (BOOL)isInConference
{
    return _bInConference;
}

- (UIViewController*)getAcuComMsgViewController
{
    return self.conferencePresentingRightViewController;
}

- (void)messageNotification:(NSString*)msgSumary
             chatGroupTitle:(NSString*)groupTitle
                chatGroupId:(NSString*)groupId
{
    if (_bInConference)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!_bMMDrawerLeftOpen)
            {
                [self.conferencePresentingMainViewController updateChatMsgIndicator:NO];
            }
        });
    }
}

- (void)incomingCallDialog:(NSString*)dlgTitle
                dlgContent:(NSString*)content
                dlgYesName:(NSString*)yesName
                 dlgNoName:(NSString*)noName
                    config:(NSDictionary*)config
{
    if (_bInConference)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.conferencePresentingMainViewController incomingCallDialog:dlgTitle
                                                                 dlgContent:content
                                                                 dlgYesName:yesName
                                                                  dlgNoName:noName
                                                                     config:config];
        });
        
    }
}

- (void)conferenceNotification:(int)type
                     msgSumary:(NSString*)sumary
                       session:(NSString*)sessinId
{
    if (_bInConference)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.conferencePresentingMainViewController conferenceNotification:type
                                                                      msgSumary:sumary
                                                                        session:sessinId];
        });
    }
}

- (void)forceTerminateConference
{
    
    
}

- (void)forceTerminate
{   
    _forceTerminite = YES;
    
    _cancelParam.sessionCanceledCommandSended = YES;
    _cancelParam.sessionCanceledOutside = YES;
    _cancelParam.sessionCanceled = YES;
    
    if (_acucomListener)
    {
        _acucomListener->conferenceClosed(20, nil);
    }
    
    if (self.conferencePresentingStarterController &&
        self.conferencePresentingStarterController == self.parentController.presentedViewController)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.conferencePresentingMainViewController exitConference:AcuConferenceEndStatusForceTerminal];
        });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_terminiteMutex lock];
            
            if (self.parentController.presentedViewController)
            {
                [self.parentController dismissViewControllerAnimated:YES completion:nil];
            }
            
            self.startViewController = nil;
            
            if(_videoCallMode == 1 && _videoCallAVMode == 1)
            {
                [UIDevice currentDevice].proximityMonitoringEnabled = NO;
            }
            
            if (self.conferencePresentingMainViewController)
            {
                [self.conferencePresentingMainViewController exitConference:AcuConferenceEndStatusForceTerminal];
            }
            
#if 0
            
            
            _bInConference = false;
            
            self.conferencePresentingMainViewController.conferenceDelegate = nil;
            self.conferencePresentingMainViewController.conferenceCommandDelegate = nil;
            self.conferencePresentingMainViewController.conferenceSessionController = nil;
            
            self.conferencePresentingLeftViewController.conferenceCommandDelegate = nil;
            self.conferencePresentingLeftViewController.participantListMenuDelegate = nil;
            
            self.conferencePresentingStarterController = nil;
            self.conferencePresentingMainViewController = nil;
            self.conferencePresentingLeftViewController = nil;
            self.conferencePresentingRightViewController = nil;
            
           
            
            if(_conferenceEvent)
            {
                _conferenceEvent->ExitConference();
                _conferenceEvent->setSessionController(nil);
                delete _conferenceEvent;
                _conferenceEvent = nil;
            }
            
            
            [self.conferenceParticipantList removeAllObjects];
            self.conferenceParticipantList = nil;
            _startSessionTask = nil;
            _oprTask = nil;
            _hasSettedVideoParam = false;
#endif
            [_terminiteMutex unlock];
        });
    }
}

@end
