//
//  AcuParticipantInfo.m
//  AcuConference
//
//  Created by aculearn on 13-8-28.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import "AcuParticipantInfo.h"

@implementation AcuParticipantInfo

@synthesize image_col_1;
@synthesize image_col_2;
@synthesize image_col_3;
@synthesize image_col_4;
@synthesize image_col_5;
@synthesize image_col_6;

@synthesize nId;
@synthesize name;
@synthesize type;
@synthesize has_audio_device;
@synthesize has_video_device;

@synthesize video_is_running;
@synthesize audio_is_running;

@synthesize is_speaker;
@synthesize is_presenter;
@synthesize is_screener;
@synthesize is_screen_controller;
@synthesize hand_up_speaking;
@synthesize is_request_presenter;
@synthesize is_request_screen_control;

@synthesize is_local_video_enabled;
@synthesize is_local_audio_enabled;

@synthesize is_remote_video_enabled;
@synthesize is_remote_audio_enabled;

@synthesize is_monitor;
@synthesize is_locked;
@synthesize is_monitored;

@end
