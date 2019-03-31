//
//  AcuConferenceSessionController.h
//  AcuConference
//
//  Created by aculearn on 13-7-11.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "AcuSessionProperty.h"
#include "acucom_listener_interface.h"

typedef struct tagAcuLoginHeader
{
	uint16_t        rotation_source;
	uint16_t        rotation_mode;
	uint16_t        video_max_width;
	uint16_t        video_max_height;
	uint16_t        video_max_bps;
    uint16_t        user_id;
    uint32_t        user_unique_id;
    uint16_t        view_id;
    uint16_t        active_speaker;
    bool            bIsStarter;
    
    uint16_t        conference_mode;
    uint16_t        room_video_quality;
    uint16_t        company_video_quality;
}ACU_LOGIN_HEADER;

@interface AcuConferenceSessionController : NSObject

@property (nonatomic, strong) NSMutableArray	*conferenceParticipantList;
@property (nonatomic, weak) UIViewController	*parentController;
/*
//1是1对1的视频会议， 0是多人视频会议
 */
@property (nonatomic, assign) int               videoCallMode;
/*
//1是语音呼叫， 0是视频呼叫
 */
@property (nonatomic, assign) int               videoCallAVMode;


- (void)startSession:(AcuSessionProperty*)session
    parentController:(UIViewController*)parent
                join:(bool)bJoin
        reconnection:(BOOL)bReconnection;

- (void)setCaptureVideoData:(char*)pVideoData
		captureVideoDataLen:(int)nVideoDataLen
		  captureVideoWidth:(int)nVideoWidth
		 captureVideoHeight:(int)nVideoHeight
	 captureVideoColorSpace:(FourCharCode)videoColorSpace;

- (bool)getRemoteVideo:(int)nIndex
	   remoteVideoData:(unsigned char**)pVideoData
 remoteVideoDataLength:(int*)nVideoDataLen
 remoteVideoBufferSize:(int*)nVideoBufferSize
	  remoteVideoWidth:(int*)nVideoWidth
	 remoteVideoHeight:(int*)nVideoHeight
 remoteVideoColorSpace:(int*)nVideoColorSpace
	 remoteVideoUserID:(int*)nVideoUserID;

- (void)freeRemoteVideoData:(unsigned char*)pVideoData
	  remoteVideoBufferSize:(int)nVideoBufferSize;

- (void)setCaptureAudioData:(char*)pAudioData
		captureAudioDataLen:(int)nAudioDataLen;

- (void)getPlayAudioData:(char*)pAudioData
		playAudioDataLen:(int)nAudioDataLen;

- (void)onUserEvent:(int)event_id
		   withInfo:(char*)utf8_str;

#pragma mark ----AcuCom Functions----
- (void)canceledConference;
- (void)setAcuComListener:(AcuComListener*)listener;

- (void)setVideoCallMode:(int)videoCallMode;
- (void)setVideoCallAVMode:(int)videoCallAVMode;

- (BOOL)isInConference;
- (UIViewController*)getAcuComMsgViewController;

- (void)messageNotification:(NSString*)msgSumary
             chatGroupTitle:(NSString*)groupTitle
                chatGroupId:(NSString*)groupId;

- (void)incomingCallDialog:(NSString*)dlgTitle
                dlgContent:(NSString*)content
                dlgYesName:(NSString*)yesName
                 dlgNoName:(NSString*)noName
                    config:(NSDictionary*)config;

- (void)conferenceNotification:(int)type
                     msgSumary:(NSString*)sumary
                       session:(NSString*)sessinId;

- (void)forceTerminate;

@end
