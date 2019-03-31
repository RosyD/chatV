//
//  AcuConferencePresentingViewController.h
//  AcuConference
//
//  Created by aculearn on 13-7-11.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AcuVideoViewController.h"
#import "UIPopoverListView.h"
#import "AcuLocalVideoView.h"
#import "AcuVideoView.h"
#import "AcuAudioManager.h"
#import "AcuConferencePublic.h"
#import "AcuConferenceCommandDelegate.h"
#include "acucom_listener_interface.h"

@class AcuConferenceSessionController;
@class AcuConferencePresentingViewController;

@protocol AcuConferencePresentingDelegate <NSObject>

- (void)acuConferencePresentingViewController:(AcuConferencePresentingViewController*)controller
                                       didEnd:(AcuConferenceEndStatus)endStatus;

@end


@interface AcuConferencePresentingViewController : UIViewController
                                                   <UIGestureRecognizerDelegate,
                                                    UIPopoverListViewDataSource,
                                                    UIPopoverListViewDelegate,
                                                    AcuAudioManagerSampleDataDelegate,
                                                    UIAlertViewDelegate>

@property (nonatomic, assign) BOOL isHDQuality;
@property (nonatomic, assign) BOOL isHighQualityVideo;
@property (nonatomic, assign) BOOL isWIFINetwork;
@property (nonatomic, readwrite) bool startConference;
@property (weak, nonatomic) IBOutlet UIView *indicatorToolbar;
@property (weak, nonatomic) IBOutlet UIView *hudToolbar;
@property (weak, nonatomic) IBOutlet UIView *videoCallToolbar;

@property (weak, nonatomic) IBOutlet AcuLocalVideoView *localVideoView;
//@property (weak, nonatomic) IBOutlet AcuVideoView *localVideoPreviewView;
@property (weak, nonatomic) IBOutlet UIButton *localVideoViewPinBtn;
@property (weak, nonatomic) IBOutlet UIButton *localVideoViewSwitchCamBtn;
@property (weak, nonatomic) IBOutlet UIButton *localVideoViewVideoBtn;
@property (weak, nonatomic) IBOutlet UIButton *localVideoViewAudioBtn;

@property (weak, nonatomic) IBOutlet UIButton *toolbarQualityBtn;
@property (weak, nonatomic) IBOutlet UIButton *toolbarLayoutBtn;
@property (weak, nonatomic) IBOutlet UIButton *toolbarPresenterBtn;
@property (weak, nonatomic) IBOutlet UIButton *toolbarSpeakerBtn;
@property (weak, nonatomic) IBOutlet UIButton *toolbarExitBtn;

@property (weak, nonatomic) IBOutlet UIButton *toolbarAcuComVideoQuality;
@property (weak, nonatomic) IBOutlet UIButton *toolbarAcuComNoVideo;
@property (weak, nonatomic) IBOutlet UIButton *toolbarAcuComConfMuteMic;
@property (weak, nonatomic) IBOutlet UIButton *toolbarAcuComMuteMic;
@property (weak, nonatomic) IBOutlet UIButton *toolbarAcuComHandFree;
@property (weak, nonatomic) IBOutlet UIButton *toolbarAcuComHangup;
@property (weak, nonatomic) IBOutlet UIButton *toolbarAcuComAudioHangup;


@property (weak, nonatomic) IBOutlet UIImageView *audioIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *videoIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *chatMsgIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *networkIndicator;

@property (weak, nonatomic) IBOutlet UIImageView *AcuComAudioCallBackgroundImage;
@property (weak, nonatomic) IBOutlet UIImageView *AcuComAudioCallImage;


@property (nonatomic, weak) id<AcuConferencePresentingDelegate> conferenceDelegate;
@property (nonatomic, weak) id<AcuConferenceCommandDelegate> conferenceCommandDelegate;

@property (nonatomic, weak) AcuConferenceSessionController* conferenceSessionController;

@property (nonatomic, weak) NSMutableArray	 *conferenceParticipantList;

@property (nonatomic, retain) AcuVideoViewController      *localPreviewVideoController;
@property (nonatomic, retain) AcuVideoViewController      *videoViewController1;
@property (nonatomic, retain) AcuVideoViewController      *videoViewController2;
@property (nonatomic, retain) AcuVideoViewController      *videoViewController3;
@property (nonatomic, retain) AcuVideoViewController      *videoViewController4;

/*
 //1是1对1的视频会议， 0是多人视频会议
 */
@property (nonatomic, assign) int               videoCallMode;
/*
 //1是语音呼叫， 0是视频呼叫
 */
@property (nonatomic, assign) int               videoCallAVMode;



- (IBAction)didTapGesture:(UIGestureRecognizer *)sender;


- (IBAction)pressedLocalVideoViewPin:(id)sender;
- (IBAction)pressedLocalVideoViewSwitch:(id)sender;
- (IBAction)pressedLocalVideoViewVideo:(id)sender;
- (IBAction)pressedLocalVideoViewAudio:(id)sender;


- (IBAction)pressedLayout:(id)sender;
- (IBAction)pressedPresenter:(id)sender;
- (IBAction)pressedSpeaker:(id)sender;
- (IBAction)pressedExit:(id)sender;


- (IBAction)pressedAcuComNoVideo:(id)sender;
- (IBAction)pressedAcuComHandFree:(id)sender;
- (IBAction)pressedAcuComVideoQuality:(id)sender;



#pragma mark ----conference logic----
- (void)initConferenceStatus;
- (void)updateParticipantList:(NSMutableArray*)newParticipantList;
- (void)setActiveSpeaker:(int)activeSpeakerID;
- (void)setLayoutStatus:(AcuConferenceLayoutStatus)layoutStatus;

- (void)setModeratorRole:(BOOL)bModerator;	//Host
- (void)setSpeakerRole:(BOOL)bSpeaker;
- (void)setPresenterRole:(BOOL)bPresenter;

- (void)setHangingUp:(BOOL)bHandingUp;

- (void)remoteMuteLocalVideo:(BOOL)bMute;
- (void)remoteMuteLocalAudio:(BOOL)bMute;

- (void)invite2Present:(int)nReason;
- (void)invite2Speaker:(int)nReason;

- (void)endConference:(int)nReason
	   andDescription:(NSString*)description;
- (void)exitConference:(AcuConferenceEndStatus)exitStatus;

- (void)updateChatMsgIndicator:(BOOL)bHidden;
- (void)updateNetworkIndicator:(AcuConferenceNetworkStatus)eStatus;
- (void)updateToolbarPresenterBtnStatus:(int)nStatus;

- (void)deallocResource;

#pragma mark ----AcuCom Function----
- (void)setVideoCallLauncher:(BOOL)bLauncher;
- (void)setAcuComListener:(AcuComListener*)listener;
- (void)setVideoCallMode:(int)videoCallMode;
- (void)setVideoCallAVMode:(int)videoCallAVMode;

- (void)incomingCallDialog:(NSString*)dlgTitle
                dlgContent:(NSString*)content
                dlgYesName:(NSString*)yesName
                 dlgNoName:(NSString*)noName
                    config:(NSDictionary*)config;

- (void)conferenceNotification:(int)type
                     msgSumary:(NSString*)sumary
                       session:(NSString*)sessinId;

@end
