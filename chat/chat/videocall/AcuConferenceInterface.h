//
//  AcuConferenceInterface.h
//  AcuConference
//
//  Created by aculearn on 13-8-14.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#ifndef __acu_conference_interface_h__
#define __acu_conference_interface_h__

#import <Foundation/Foundation.h>

class AcuConferenceSessionEvent;

bool initializeConference();
void setConferenceSessionEvent(AcuConferenceSessionEvent* pEvent);
bool exitConference();
bool startConference(char* sessionStr);
void sendAudio(char *pAudioData, int nLen);
int  getAudioData(char* pAudioData, int& nLen);
void sendVideo(char *pVideoData, int nLen, int nWidth, int nHeight, int nColorSpace);
bool getVideoData(int nIndex,
                  unsigned char** pVideoData,
                  int* pVideoDataLen,
				  int* pVideoBufferSize,				  
                  int* pVideoWidth,
                  int* pVideoHeight,
                  int* pVideoColorSpace,
                  int* pVideoUserID);
void freeVideoData(unsigned char *pVideoData, int nVideoBufferSize);
void onUserEvent( int event_id, char * utf8_str );
void setInputSampleRate(int nSampleRate);
void setOutputSampleRate(int nSampleRate);
bool getUserList(NSMutableArray* participantList);
bool sendCommand( int cmd_id, const char* utf8_arg );
bool getParticipantListMenuData(int participantId, char* pMenuData, int nLen);
void updateVideoFilter( int indexOfVideo, bool is_show_video );
void setVideoParam(int bit_rate, int frame_rate, int i_frame_interval);

#endif  //__acu_conference_interface_h__
