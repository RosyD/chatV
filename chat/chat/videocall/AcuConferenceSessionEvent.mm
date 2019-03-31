//
//  AcuAVMediaDataCallback.m
//  AcuConference
//
//  Created by aculearn on 13-8-9.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#include "AcuConferenceSessionEvent.h"
#include "AcuConferenceInterface.h"

AcuConferenceSessionEvent::AcuConferenceSessionEvent()
{
    m_Mutex = [NSLock new];
	m_bInit = false;
    m_ConferenceSessionController = nil;
}

AcuConferenceSessionEvent::~AcuConferenceSessionEvent()
{
    [m_Mutex lock];
	m_bInit = false;
    m_ConferenceSessionController = nil;
    [m_Mutex unlock];
	m_Mutex = nil;
}

void AcuConferenceSessionEvent::setSessionController(AcuConferenceSessionController *conferenceController)
{
    [m_Mutex lock];
    m_ConferenceSessionController = conferenceController;
    [m_Mutex unlock];
}

bool AcuConferenceSessionEvent::InitializeConference()
{
	[m_Mutex lock];
	m_bInit = initializeConference();
	
	if (m_bInit)
	{
		setConferenceSessionEvent(this);
	}
    [m_Mutex unlock];
	
	return m_bInit;
}


bool AcuConferenceSessionEvent::ExitConference()
{
	bool bRet = false;
	
	[m_Mutex lock];
	if (m_bInit)
	{
		bRet = exitConference();
		setConferenceSessionEvent(nil);
	}
	[m_Mutex unlock];
	
	return bRet;
}

void AcuConferenceSessionEvent::StartConference(char* sessionStr)
{
	[m_Mutex lock];
	if (m_bInit)
	{
		startConference(sessionStr);
	}
	[m_Mutex unlock];
}
void AcuConferenceSessionEvent::SendAudio(char *pAudioData, int nLen)
{
	[m_Mutex lock];
	if (m_bInit)
	{
		sendAudio(pAudioData, nLen);
	}
	[m_Mutex unlock];
}
int AcuConferenceSessionEvent::GetAudioData(char* pAudioData, int& nLen)
{
	int nRet = 0;
	[m_Mutex lock];
	if (m_bInit)
	{
		nRet = getAudioData(pAudioData, nLen);
	}
	[m_Mutex unlock];
	
	return nRet;
}

void AcuConferenceSessionEvent::SendVideo(char *pVideoData,
										  int nLen,
										  int nWidth,
										  int nHeight,
										  int nColorSpace)
{
	[m_Mutex lock];
	if (m_bInit)
	{
		sendVideo(pVideoData,
				  nLen,
				  nWidth,
				  nHeight,
				  nColorSpace);
	}
	[m_Mutex unlock];
}

bool AcuConferenceSessionEvent::GetVideoData(int nIndex,
											 unsigned char** pVideoData,
											 int* pVideoDataLen,
											 int* pVideoBufferSize,
											 int* pVideoWidth,
											 int* pVideoHeight,
											 int* pVideoColorSpace,
											 int* pVideoUserID)
{
	bool bRet = false;
	[m_Mutex lock];
	if (m_bInit)
	{
		bRet = getVideoData(nIndex,
							pVideoData,
							pVideoDataLen,
							pVideoBufferSize,
							pVideoWidth,
							pVideoHeight,
							pVideoColorSpace,
							pVideoUserID);
	}
	[m_Mutex unlock];
	
	return bRet;
}

void AcuConferenceSessionEvent::FreeVideoDataEx(unsigned char* pVideoData, int nVideoBufferSize)
{
	[m_Mutex lock];
	if (m_bInit)
	{
		freeVideoData(pVideoData, nVideoBufferSize);
	}
	[m_Mutex unlock];
}

void AcuConferenceSessionEvent::OnUserEvent(int event_id, char* utf8_str)
{
    if (m_bInit && m_ConferenceSessionController)
    {
        [m_ConferenceSessionController onUserEvent:event_id
										  withInfo:utf8_str];
    }

}
void AcuConferenceSessionEvent::SetInputSampleRate(int nSampleRate)
{
	[m_Mutex lock];
	if (m_bInit)
	{
		setInputSampleRate(nSampleRate);
	}
	[m_Mutex unlock];
}

void AcuConferenceSessionEvent::SetOutputSampleRate(int nSampleRate)
{
	[m_Mutex lock];
	if (m_bInit)
	{
		setOutputSampleRate(nSampleRate);
	}
	[m_Mutex unlock];
}

bool AcuConferenceSessionEvent::GetUserList(NSMutableArray *participantList)
{
	bool bRet = false;
	[m_Mutex lock];
	if (m_bInit)
	{
		bRet = getUserList(participantList);
	}
	[m_Mutex unlock];
	
	return bRet;
}

bool AcuConferenceSessionEvent::SendCommand(int cmd_id, const char* utf8_arg)
{
	bool bRet = false;
	[m_Mutex lock];
	if (m_bInit)
	{
		bRet = sendCommand(cmd_id, utf8_arg);
	}
	[m_Mutex unlock];
	
	return bRet;
}
bool AcuConferenceSessionEvent::GetParticipantListMenuData(int participantId, char* pMenuData, int nLen)
{
    bool bRet = false;
	[m_Mutex lock];
	if (m_bInit)
	{
		bRet = getParticipantListMenuData(participantId, pMenuData, nLen);
	}
	[m_Mutex unlock];
	
	return bRet;
}

void AcuConferenceSessionEvent::UpdateVideoFilter(int indexOfVideo, bool is_show_video)
{
    [m_Mutex lock];
	if (m_bInit)
	{
		updateVideoFilter(indexOfVideo, is_show_video);
	}
	[m_Mutex unlock];
}

void AcuConferenceSessionEvent::SetVideoParam(int bit_rate, int frame_rate, int i_frame_interval)
{
    [m_Mutex lock];
	if (m_bInit)
	{
		setVideoParam(bit_rate, frame_rate, i_frame_interval);
	}
	[m_Mutex unlock];
}