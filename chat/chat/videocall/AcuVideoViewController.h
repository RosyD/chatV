//
//  AcuVideoViewController.h
//  AcuConference
//
//  Created by aculearn on 13-8-9.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AcuVideoView.h"

@interface AcuVideoViewController : UIViewController

@property (strong, nonatomic) IBOutlet AcuVideoView *videoView;
@property (weak, nonatomic) IBOutlet UILabel *participantLabel;
@property (weak, nonatomic) IBOutlet UIImageView *activeSpeakerIndictor;

/*
 //1是1对1的视频会议， 0是多人视频会议
 */
@property (nonatomic, assign) int               videoCallMode;

/*
 //1是语音呼叫， 0是视频呼叫
 */
@property (nonatomic, assign) int               videoCallAVMode;


- (void)setParticipantName:(NSString*)participantName;
- (void)setAcitveSpeaker:(BOOL)bActiveSpeaker;

@end
