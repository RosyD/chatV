//
//  AcuParticipantInfo.h
//  AcuConference
//
//  Created by aculearn on 13-8-28.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>


const int icon_moderator				= 0;
const int icon_comoderator				= 1;
const int icon_participant				= 2;
const int icon_audio_enable				= 3;
const int icon_video_enable				= 4;
const int icon_hand						= 5;
const int icon_speaker					= 6;
const int icon_attention_disable		= 7;
const int icon_attention_enable			= 8;
const int icon_presenter				= 9;

const int icon_video_remote_disable		= 10;
const int icon_audio_remote_disable		= 11;
const int icon_video_local_disable		= 12;
const int icon_auido_local_disable		= 13;
const int icon_telephone				= 14;
const int icon_boss						= 15;
const int icon_blank					= 16;


@interface AcuParticipantInfo : NSObject

@property (nonatomic, assign) int image_col_1;
@property (nonatomic, assign) int image_col_2;
@property (nonatomic, assign) int image_col_3;
@property (nonatomic, assign) int image_col_4;
@property (nonatomic, assign) int image_col_5;
@property (nonatomic, assign) int image_col_6;

@property (nonatomic, assign) int		nId;
@property (nonatomic, retain) NSString	*name;
@property (nonatomic, assign) int		type;
@property (nonatomic, assign) BOOL		has_audio_device;
@property (nonatomic, assign) BOOL		has_video_device;

@property (nonatomic, assign) BOOL		video_is_running;
@property (nonatomic, assign) BOOL		audio_is_running;

@property (nonatomic, assign) BOOL		is_speaker;
@property (nonatomic, assign) BOOL		is_presenter;
@property (nonatomic, assign) BOOL		is_screener;
@property (nonatomic, assign) BOOL		is_screen_controller;
@property (nonatomic, assign) BOOL		hand_up_speaking;
@property (nonatomic, assign) BOOL		is_request_presenter;
@property (nonatomic, assign) BOOL		is_request_screen_control;

@property (nonatomic, assign) BOOL		is_local_video_enabled;
@property (nonatomic, assign) BOOL		is_local_audio_enabled;

@property (nonatomic, assign) BOOL		is_remote_video_enabled;
@property (nonatomic, assign) BOOL		is_remote_audio_enabled;

@property (nonatomic, assign) BOOL		is_monitor;
@property (nonatomic, assign) BOOL		is_locked;
@property (nonatomic, assign) BOOL		is_monitored;

@end
