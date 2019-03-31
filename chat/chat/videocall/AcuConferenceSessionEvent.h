//
//  AcuAVMediaDataCallback.h
//  AcuConference
//
//  Created by aculearn on 13-8-9.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#ifndef __acu_conference_session_event_h__
#define __acu_conference_session_event_h__

#import "AcuConferenceSessionController.h"

class AcuConferenceSessionEvent
{
public:
    AcuConferenceSessionEvent();
    virtual ~AcuConferenceSessionEvent();
    
public:
    void setSessionController(AcuConferenceSessionController *conferenceController);
    
public:
	bool InitializeConference();
	//void SetConferenceSessionEvent(AcuConferenceSessionEvent* pEvent);
	bool ExitConference();
	void StartConference(char* sessionStr);
	void SendAudio(char *pAudioData, int nLen);
	int  GetAudioData(char* pAudioData, int& nLen);
	void SendVideo(char *pVideoData, int nLen, int nWidth, int nHeight, int nColorSpace);
	bool GetVideoData(int nIndex,
					  unsigned char** pVideoData,
					  int* pVideoDataLen,
					  int* pVideoBufferSize,
					  int* pVideoWidth,
					  int* pVideoHeight,
					  int* pVideoColorSpace,
					  int* pVideoUserID);
	void FreeVideoDataEx(unsigned char* pVideoData, int nVideoBufferSize);
	void OnUserEvent(int event_id, char* utf8_str);
	void SetInputSampleRate(int nSampleRate);
	void SetOutputSampleRate(int nSampleRate);
	bool GetUserList(NSMutableArray *participantList);
    bool SendCommand(int cmd_id, const char* utf8_arg);
	
    bool GetParticipantListMenuData(int paticipantId, char* pMenuData, int nLen);
    
    void UpdateVideoFilter(int indexOfVideo, bool is_show_video);
    
    void SetVideoParam(int bit_rate, int frame_rate, int i_frame_interval);
	
private:
    NSLock		*m_Mutex;
	bool		m_bInit;
    AcuConferenceSessionController *m_ConferenceSessionController;
};

#endif