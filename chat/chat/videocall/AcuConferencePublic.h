//
//  AcuConferencePublic.h
//  AcuConference
//
//  Created by aculearn on 13-7-12.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#ifndef AcuConference_AcuConferencePublic_h
#define AcuConference_AcuConferencePublic_h

typedef enum _tagAcuConferenceEndStatus
{
    AcuConferenceEndStatusUnknown,
	AcuConferenceEndStatusModeratorLeave,
	AcuConferenceEndStatusModeratorStop,
    AcuConferenceEndStatusLeave,
    AcuConferenceEndStatusStopped,
	AcuConferenceEndStatusKickOut,
    AcuConferenceEndStatusReconnection,
    AcuConferenceEndStatusUserRejected,
    AcuConferenceEndStatusAcceptAnother,
    AcuConferenceEndStatusForceTerminal
}AcuConferenceEndStatus;

typedef enum _tagAcuConferenceLayoutStatus
{
    AcuConferenceLayoutStatusUnknown,
    AcuConferenceLayoutStatus1Video,
    AcuConferenceLayoutStatus2Video,
    AcuConferenceLayoutStatus4Video,
    AcuConferenceLayoutStatus1SVideo,
    AcuConferenceLayoutStatus2SVideo,
	AcuConferenceLayoutStatus0SVideo
}AcuConferenceLayoutStatus;


typedef enum _tagAcuLayoutTag
{
	eNormalView = 1,		//Normal view, not used now
	eLectureView,			//1+S
	eVideoDiscussionView,	//4+S
	eChatView,				//0+S
	eLargeView,				//2+S
	e1VideoView,			//1 Video View
	e2VideoView,
	e4VideoView,
	e9VideoView,
	e16VideoView,
	e25VideoView,
	e1Plus_N_View,
	e1Plus_5_View,
	e3S_View,				//3+S
	eFullScreenView
}AcuLayoutTag;

typedef enum _tagAcuSpeakerHangupStatus
{
	AcuSpeakerHangupStatus_None,
	AcuSpeakerHangupStatus_WaitingRequest,
	AcuSpeakerHangupStatus_Request,
	AcuSpeakerHangupStatus_WaitingGiveup,
	AcuSpeakerHangupStatus_Giveup
	
}AcuSpeakerHangupStatus;

typedef enum _tagAcuConferenceNetworkStatus
{
    AcuConferenceNetworkStatus_Bad,
    AcuConferenceNetworkStatus_General,
	AcuConferenceNetworkStatus_Good
}AcuConferenceNetworkStatus;

typedef enum _tagAcuConferenceLoginErrorCode
{
    eLOGON_SUCCESSED                = 0,
    eLOGON_CHANGE2JOIN              = 1,
    
    eFAILED_VERSION_SMALL           = 2,
    eFAILED_VERSION_LARGE           = 3,
    eFAILED_CREATE_SESSION          = 4,
    
    eFAILED_WAIT_FINISH             = 5,
    eFAILED_FIND_SESSION            = 6,
    eFAILED_CHECK_PASSWORD          = 7,
    eFAILED_SESSION_STOPING         = 8,
    eFAILED_SESSION_STOPING_AS      = 9,
    eAILED_SESSION_STARTING         = 10,
    eFAILED_WAIT_FINISH_AS          = 11,
    eFAILED_CREATE_SESSION_AS       = 12,
    eFAILED_SIP_START_SESSION       = 13,
    eFAILED_GRANT                   = 14,
    eFAILED_EX_PARAMTER             = 15,
    eFAILED_CONNECTION_MAS          = 16,
    eFAILED_AUTH_FAILED             = 17,
    eFAILED_MAX_SESSION             = 18,
    eACU_FAILED_NO_GATEWAY          = 19,
    eACU_FAILED_DNS_SRC             = 20,
    eACU_FAILED_DNS_DEST            = 21,
    eLOGON_UNKNOWN_FAILED           = 63,
}AcuConferenceLoginErrorCode;

#endif
