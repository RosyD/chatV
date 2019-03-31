//
//  AcuConferenceInterface.m
//  AcuConference
//
//  Created by aculearn on 13-8-14.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#include "AcuConferenceInterface.h"
#include "conference_core_api.h"
#include "conference7_api_const.h"
#include "AcuConferenceSessionEvent.h"
#import "AcuParticipantInfo.h"

AcuConferenceSessionEvent *g_pConferenceSessionEvent = nil;

bool initializeConference()
{
    bool bResult = intialize_conferene();
    if (bResult)
    {
        //set callback here
        set_user_event_callback(onUserEvent);
    }
    
    return bResult;
}

void setConferenceSessionEvent(AcuConferenceSessionEvent* pEvent)
{
    g_pConferenceSessionEvent = pEvent;
}

bool exitConference()
{
    exit_conference(false);
    return true;
}

bool startConference(char* sessionStr)
{
    int nRet = start_conference( sessionStr );
    enable_agc(true);
    return nRet == ACU_SUCCESS ? true : false;
}

void sendAudio(char *pAudioData, int nLen)
{
    if (pAudioData)
    {
		send_audio_data( pAudioData,  nLen);
	}
}

int  getAudioData(char* pAudioData, int& nLen)
{
    int ret_result = get_audio_output(&pAudioData, nLen);
    return ret_result;

}

void sendVideo(char *pVideoData, int nLen, int nWidth, int nHeight, int nColorSpace)
{
    if(pVideoData)
    {
        send_video_data( (unsigned char * )pVideoData, nLen, nWidth, nHeight, nColorSpace );
    }
}

bool getVideoData(int nIndex,
                  unsigned char** pVideoData,
                  int* pVideoDataLen,
				  int* pVideoBufferSize,
                  int* pVideoWidth,
                  int* pVideoHeight,
                  int* pVideoColorSpace,
                  int* pVideoUserID)
{
    int video_count = get_video_count();
	if(  video_count <= 0 )
		return false;
    
//    if (nIndex == 0)
//    {
//        int aaa = 0;
//        NSLog(@"getVideo Data at index = %d", aaa);
//    }
//    else if(nIndex == 1)
//    {
//        int aaa = 1;
//        NSLog(@"getVideo Data at index = %d", aaa);
//    }
//    else if (nIndex == 2)
//    {
//        int aaa = 2;
//        NSLog(@"getVideo Data at index = %d", aaa);
//    }
//    else if (nIndex == 3)
//    {
//        int aaa = 3;
//        NSLog(@"getVideo Data at index = %d", aaa);
//    }
    
    conf_api::VideoDataFrame vdf = get_video_data( nIndex );
    if( !vdf.len || !vdf.pData )
        return false;
    
    *pVideoData = vdf.pData;
    *pVideoDataLen = vdf.len;
	*pVideoBufferSize = vdf.buff_szie;
    *pVideoWidth = vdf.width;
    *pVideoHeight = vdf.height;
    *pVideoColorSpace = vdf.color_space;
    *pVideoUserID = vdf.user_id;
	
    return true;
}

void freeVideoData(unsigned char *pVideoData, int nVideoBufferSize)
{
	free_video_data_ex(pVideoData, nVideoBufferSize);
}

void onUserEvent( int event_id, char * utf8_str )
{
    //NSLog(@"OnUserEvent: event_id:%d, info:%s\n", event_id, utf8_str);
	if (g_pConferenceSessionEvent)
	{
		g_pConferenceSessionEvent->OnUserEvent(event_id, utf8_str);
	}
	
}

void setInputSampleRate(int nSampleRate)
{
    set_audio_input_sample_rate( nSampleRate );
}

void setOutputSampleRate(int nSampleRate)
{
    set_audio_output_sample_rate( nSampleRate );
}

bool getUserList(NSMutableArray* participantList)
{
	bool bRet = false;
    std::string strUserJson;
	if( user_list_to_string(strUserJson) )
	{
        NSString *jsonString = [NSString stringWithUTF8String:strUserJson.c_str()];
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableDictionary *userList = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                        options:NSJSONReadingMutableContainers
                                                                          error:nil];
        
		for( NSDictionary *userInfo in userList )
		{
			AcuParticipantInfo *participantInfo = [[AcuParticipantInfo alloc] init];
			
			participantInfo.nId = [[userInfo valueForKey:@"user_id"] intValue];
			participantInfo.name = [userInfo valueForKey:@"user_name"];
            participantInfo.type = [[userInfo valueForKey:@"user_type"] intValue];
			participantInfo.has_audio_device = [[userInfo valueForKey:@"has_audio"] boolValue];
			participantInfo.has_video_device = [[userInfo valueForKey:@"has_video"] boolValue];
			participantInfo.audio_is_running = [[userInfo valueForKey:@"audio_running"] boolValue];
			participantInfo.video_is_running = [[userInfo valueForKey:@"video_running"] boolValue];
			
			participantInfo.is_speaker = [[userInfo valueForKey:@"is_speaker"] boolValue];
			participantInfo.is_presenter = [[userInfo valueForKey:@"is_presenter"] boolValue];
			participantInfo.is_screener = [[userInfo valueForKey:@"is_screener"] boolValue];
			participantInfo.is_screen_controller = [[userInfo valueForKey:@"is_screen_controller"] boolValue];
			participantInfo.hand_up_speaking = [[userInfo valueForKey:@"hand_up_speaking"] boolValue];
			participantInfo.is_request_presenter = [[userInfo valueForKey:@"hand_up_presenter"] boolValue];
			participantInfo.is_request_screen_control = [[userInfo valueForKey:@"hand_up_screen_control"] boolValue];
			
			participantInfo.is_local_audio_enabled = [[userInfo valueForKey:@"local_audio"] boolValue];
			participantInfo.is_local_video_enabled = [[userInfo valueForKey:@"local_video"] boolValue];
			participantInfo.is_remote_audio_enabled = [[userInfo valueForKey:@"remote_audio"] boolValue];
			participantInfo.is_remote_video_enabled = [[userInfo valueForKey:@"remote_video"] boolValue];
			participantInfo.is_monitor = [[userInfo valueForKey:@"is_monitor"] boolValue];
			participantInfo.is_locked = [[userInfo valueForKey:@"is_locked"] boolValue];
            participantInfo.is_monitored = [[userInfo valueForKey:@"is_monitored"] boolValue];
			
			participantInfo.image_col_1 = [[userInfo valueForKey:@"image_col_1"] intValue];
			participantInfo.image_col_2 = [[userInfo valueForKey:@"image_col_2"] intValue];
			participantInfo.image_col_3 = [[userInfo valueForKey:@"image_col_3"] intValue];
			participantInfo.image_col_4 = [[userInfo valueForKey:@"image_col_4"] intValue];
			participantInfo.image_col_5 = [[userInfo valueForKey:@"image_col_5"] intValue];
			participantInfo.image_col_6 = [[userInfo valueForKey:@"image_col_6"] intValue];
			
#if 0
			// user images :
			// column 1 [moderator||Co-moderator||Participant||monitor]
			if( pUserList[user_index].nType == PT_MODERATOR )
			{
				participantInfo.image_col_1 = 0;
			}
			else if( pUserList[user_index].nType == PT_COMODERATOR )
			{
				participantInfo.image_col_1 = 1;
			}
			else if( pUserList[user_index].nType == PT_PARTICIPANT )
			{
				participantInfo.image_col_1 = 2;
			}
			else
			{
				participantInfo.image_col_1 = 10;
			}
			
			if(  pUserList[user_index].bMonitor )
			{
				participantInfo.image_col_1 = 16;
			}
			
			// user images : column 2 [presenter]
			participantInfo.image_col_2	= 10;
			if (pUserList[user_index].bIsPresenter)
			{
				participantInfo.image_col_2 = 9;
			}
			else if (pUserList[user_index].bHandUpForPresenter)
			{
				participantInfo.image_col_2 = 10;
			}
			
			// user images : column 3 [speaker]
			participantInfo.image_col_3 = 10;
			if (pUserList[user_index].bIsSpeaker)
			{
				participantInfo.image_col_3 = 6;
				if (is_speaking_exclusive())
				{
					participantInfo.image_col_3 = 7;
					if (PT_MODERATOR == pUserList[user_index].nType || pUserList[user_index].bIsPresenter  )
					{
						participantInfo.image_col_3 = 8;
					}
				}
			}
			else if (pUserList[user_index].bHandUpForSpeaker)
			{
				participantInfo.image_col_3 = 5;
			}
			
			// image column 4 [audio]
			participantInfo.image_col_4 = 10;
			if (pUserList[user_index].bHasAudio )
			{
				participantInfo.image_col_4 = 14;
				
				if( !pUserList[user_index].bAllowAudio )
					participantInfo.image_col_4 = 12;
				else if( !pUserList[user_index].bSendAudio )
					participantInfo.image_col_4 = 14;
				else if( !pUserList[user_index].bIsSpeaker )
					participantInfo.image_col_4 = 14;
				else
					participantInfo.image_col_4 = 3;
			}
			
			
			// image column 5 [video]
			participantInfo.image_col_5 = 10;
			if (pUserList[user_index].bHasVideo)
			{
				participantInfo.image_col_5 = 13;
				
				if( !pUserList[user_index].bAllowVideo )
					participantInfo.image_col_5 = 11;
				else if( !pUserList[user_index].bSendVideo )
					participantInfo.image_col_5 = 13;
				else if( !pUserList[user_index].bIsSpeaker )
					participantInfo.image_col_5 = 13;
				else
					participantInfo.image_col_5 = 4;
				
				if(is_screen_sharing())
				{
					participantInfo.image_col_5 = 13;
				}
					
			}
#endif
			[participantList addObject:participantInfo];
		}

		
		bRet = true;
	}
	
	return bRet;
}

bool sendCommand( int cmd_id, const char* utf8_arg )
{
	return send_command(cmd_id, (char*)utf8_arg);
}

bool getParticipantListMenuData(int participantId, char* pMenuData, int nLen)
{
    return get_menu_option(participantId, pMenuData, nLen);
}

void updateVideoFilter( int indexOfVideo, bool is_show_video )
{
    update_videl_filter(indexOfVideo, is_show_video);
}

void setVideoParam(int bit_rate, int frame_rate, int i_frame_interval)
{
    SetVideoParam(bit_rate, frame_rate, i_frame_interval);
}