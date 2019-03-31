//
//  AcuConferencePresentingViewController.m
//  AcuConference
//
//  Created by aculearn on 13-7-11.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import "AcuConferencePresentingViewController.h"
#import "AcuVideoViewController.h"
#import "AcuVideoCapture.h"
#import "AcuVideoPixelBuffer.h"
#import "AcuConferenceSessionController.h"
#import "AcuDeviceHardware.h"
#import "AcuParticipantInfo.h"
#include "conf_api_define.h"
#include "fifo.h"

#define ACU_IOS_SAVE_AUDIO_CAPTURE_DATA     0
#define ACU_IOS_SAVE_AUDIO_PLAYBACK_DATA    0
#define ACU_HUD_TOOLBAR_DISAPPEAR_TIMER     5

#define ACU_COM_USE_ALERTCONTROLLER         1
#define ACU_COM_IOS8    [[UIDevice currentDevice].systemVersion hasPrefix:@"8"]

@interface AcuConferencePresentingViewController () <AcuVideoCaptureOutputDataSampleDelegate>

@end

@implementation AcuConferencePresentingViewController
{
    BOOL                        _needDeallocResource;
    BOOL                        _isLeftToggled;
    NSTimer                     *_hudToolbarTimer;
    
    int							_activeSpeakerID;
    
    BOOL						_bMuteLocalVideo;
    BOOL						_bMuteLocalAudio;
    
    
    BOOL						_bModerator;
    BOOL						_bCanSpeaker;
    BOOL						_bSpeaker;
    BOOL						_bPresenter;
    
    AcuSpeakerHangupStatus		_eSpeakerHangingUpStatus;
    
    BOOL						_bWaitingSpeakerStatus;
    BOOL						_bWaitingPresenterStatus;
    
    BOOL                        _bLocalVideoViewPin;
    
    AcuConferenceLayoutStatus   _layoutStatus;
    UIPopoverListView           *_layoutModePop;
    NSMutableArray              *_layoutMode;
    
    NSLock                      *_videoFrameMutex;
    AcuVideoPixelBuffer         *_videoFrame1;
    AcuVideoPixelBuffer         *_videoFrame2;
    AcuVideoPixelBuffer         *_videoFrame3;
    AcuVideoPixelBuffer         *_videoFrame4;
    NSTimer                     *_remoteVideoTimer;
    NSTimer                     *_localVideoTimer;
    
    EAGLContext					*_glContext;
    
    BOOL                        _bStillGotVideoData;
    
    AcuVideoCapture             *_videoCapture;
    int                         _videoWidth;
    int                         _videoHeight;
    
    int                         _localPreviewVideoWidth;
    int                         _localPreviewVideoHeight;
    
    AcuAudioManager             *_audioManager;
    
#if ACU_IOS_SAVE_AUDIO_CAPTURE_DATA
    NSFileHandle                *_audioCaptureDataFileHandler;
#endif
    
#if ACU_IOS_SAVE_AUDIO_PLAYBACK_DATA
    NSFileHandle                *_audioPlaybackDataFileHandler;
#endif
    
    NSMutableDictionary         *_participantList;
    
    UIAlertController           *_hostEndConferenceAlertController;
    UIAlertController           *_participantEndConferenceAlertController;
    UIAlertController			*_endConferenceAlertController;
    UIAlertController			*_invitedPresentAlertController;
    UIAlertController			*_invitedSpeakerAlertController;
    UIAlertController           *_acuComIncomingAlertController;
    UIAlertController           *_acuComNotificationAlertController;
    
    UIAlertView                 *_hostEndConferenceAlertView;
    UIAlertView                 *_participantEndConferenceAlertView;
    UIAlertView					*_endConferenceAlertView;
    UIAlertView					*_invitedPresentAlertView;
    UIAlertView					*_invitedSpeakerAlertView;
    
    UIAlertView                 *_acuComIncomingAlertView;
    UIAlertView                 *_acuComNotificationAlertView;
    int                         _acuComNotificationType;
    
    AcuComListener              *_acucomListener;
    NSDictionary                *_inComingCallConfig;
    
    BOOL                        _bVideoCallLauncher;
    
    
    CGAffineTransform           rotationTransform;
    BOOL                        _biPhone5Above;
    
    BOOL                        _bAcuComHandFree;
    
    BOOL                        _bConferenceShowing;
    BOOL                        _bHasQueueNotification;
    int                         _nQueueNotificationType;
    NSString                    *_strQueueNotificationSumary;
    NSString                    *_strQueueNotificationSessinId;
    
}

@synthesize isHDQuality;
@synthesize isHighQualityVideo;
@synthesize isWIFINetwork;
@synthesize startConference;
@synthesize conferenceDelegate;
@synthesize conferenceCommandDelegate;
@synthesize conferenceSessionController;
@synthesize conferenceParticipantList;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            self.isHDQuality = YES;
        }
        else
        {
            self.isHDQuality = NO;
        }
        self.isHighQualityVideo = NO;
        self.isWIFINetwork = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //for ios7
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }
    
    self.audioIndicator.hidden = YES;
    self.videoIndicator.hidden = YES;
    self.chatMsgIndicator.hidden = YES;
    
    _bMuteLocalVideo = NO;
    _bMuteLocalAudio = NO;
    _bAcuComHandFree = NO;
    
    _activeSpeakerID = -1;
    
    _bModerator = NO;
    _bCanSpeaker = YES;
    _bSpeaker = NO;
    _bPresenter = NO;
    
    _eSpeakerHangingUpStatus = AcuSpeakerHangupStatus_None;
    
    _bWaitingSpeakerStatus = NO;
    _bWaitingPresenterStatus = NO;
    
    _bLocalVideoViewPin = NO;
    
    _videoFrameMutex = [NSLock new];
    
    _layoutStatus = AcuConferenceLayoutStatus1Video;
    _layoutMode = [[NSMutableArray alloc] initWithObjects: NSLocalizedString(@"1 Video", @"Conference Presention LayoutMode"),
                   NSLocalizedString(@"2 Videos", @"Conference Presention LayoutMode"),
                   NSLocalizedString(@"4 Videos", @"Conference Presention LayoutMode"),
                   NSLocalizedString(@"1+S", @"Conference Presention LayoutMode"),
                   NSLocalizedString(@"2+S", @"Conference Presention LayoutMode"),
                   nil];
    
    [self showAcuComHubToolbar];
    [self showAcuComLocalPreviewToolbar];
    
    if(_videoCallAVMode == 0 && _videoCallMode == 1)
    {
        [self pressedLocalVideoViewPin:nil];
    }
    
    
    _videoFrame1 = [[AcuVideoPixelBuffer alloc] init];
    _videoFrame2 = [[AcuVideoPixelBuffer alloc] init];
    _videoFrame3 = [[AcuVideoPixelBuffer alloc] init];
    _videoFrame4 = [[AcuVideoPixelBuffer alloc] init];
    
    _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    _videoCapture = [[AcuVideoCapture alloc] init];
    _videoCapture.videoSampleDelegate = self;
    _videoCapture.isHighQualityVideo = self.isHighQualityVideo;
    _videoCapture.isWIFINetwork = self.isWIFINetwork;
    [_videoCapture setVideoCallMode:_videoCallMode];
    [_videoCapture setupCapture];
    [_videoCapture captureWidth:&_videoWidth Height:&_videoHeight];
    
    _localPreviewVideoWidth = _videoWidth;
    _localPreviewVideoHeight = _videoHeight;
    
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    _biPhone5Above = NO;
    NSString *sDeviceModel = [AcuDeviceHardware platformString];
    NSString *aux = [[sDeviceModel componentsSeparatedByString:@","] objectAtIndex:0];
    if ([aux rangeOfString:@"iPhone"].location != NSNotFound)
    {
        int version = [[aux stringByReplacingOccurrencesOfString:@"iPhone" withString:@""] intValue];
        if (version >= 5)
        {
            _biPhone5Above = YES;
        }
    }
    
    
    CGRect frame;
    if (_videoCallMode == 1)
    {
        if (deviceOrientation == UIDeviceOrientationLandscapeRight ||
            deviceOrientation == UIDeviceOrientationLandscapeLeft)
        {
            if (_biPhone5Above)
            {
                frame = self.localVideoView.frame;
                frame.origin.x = 290+88;
                frame.origin.y = 20;
                self.localVideoView.frame = frame;
#if 0
                frame = self.hudToolbar.frame;
                frame.origin.x = 120+44;
                frame.origin.y = 240;
                self.hudToolbar.frame = frame;
#else
                frame = self.videoCallToolbar.frame;
                frame.origin.x = 150+44;
                frame.origin.y = 240;
                self.videoCallToolbar.frame = frame;
#endif
                frame = self.indicatorToolbar.frame;
                frame.origin.x = 448+88;
                frame.origin.y = 210;
                self.indicatorToolbar.frame = frame;
            }
            else
            {
                frame = self.localVideoView.frame;
                frame.origin.x = 290;
                frame.origin.y = 20;
                self.localVideoView.frame = frame;
#if 0
                frame = self.hudToolbar.frame;
                frame.origin.x = 120;
                frame.origin.y = 240;
                self.hudToolbar.frame = frame;
#else
                frame = self.videoCallToolbar.frame;
                frame.origin.x = 150;
                frame.origin.y = 240;
                self.videoCallToolbar.frame = frame;
#endif
                
                frame = self.indicatorToolbar.frame;
                frame.origin.x = 448;
                frame.origin.y = 210;
                self.indicatorToolbar.frame = frame;
            }
            
        }
        else
        {
            if (_biPhone5Above)
            {
                frame = self.localVideoView.frame;
                frame.origin.x = 130;
                frame.origin.y = 20;
                self.localVideoView.frame = frame;
#if 0
                frame = self.hudToolbar.frame;
                frame.origin.x = 40;
                frame.origin.y = 400+88;
                self.hudToolbar.frame = frame;
#else
                frame = self.videoCallToolbar.frame;
                frame.origin.x = 70;
                frame.origin.y = 400+88;
                self.videoCallToolbar.frame = frame;
#endif
                
                frame = self.indicatorToolbar.frame;
                frame.origin.x = 288;
                frame.origin.y = 370+88;
                self.indicatorToolbar.frame = frame;
            }
            else
            {
                frame = self.localVideoView.frame;
                frame.origin.x = 130;
                frame.origin.y = 20;
                self.localVideoView.frame = frame;
#if 0
                frame = self.hudToolbar.frame;
                frame.origin.x = 40;
                frame.origin.y = 400;
                self.hudToolbar.frame = frame;
#else
                frame = self.videoCallToolbar.frame;
                frame.origin.x = 70;
                frame.origin.y = 400;
                self.videoCallToolbar.frame = frame;
#endif
                
                frame = self.indicatorToolbar.frame;
                frame.origin.x = 288;
                frame.origin.y = 370;
                self.indicatorToolbar.frame = frame;
            }
        }
    }
    else
    {
        if (_biPhone5Above)
        {
            frame = self.localVideoView.frame;
            frame.origin.x = 290+88;
            frame.origin.y = 20;
            self.localVideoView.frame = frame;
            
            frame = self.hudToolbar.frame;
            frame.origin.x = 90+44;
            frame.origin.y = 240;
            self.hudToolbar.frame = frame;
            
            frame = self.indicatorToolbar.frame;
            frame.origin.x = 448+88;
            frame.origin.y = 210;
            self.indicatorToolbar.frame = frame;
        }
        else
        {
            frame = self.localVideoView.frame;
            frame.origin.x = 290;
            frame.origin.y = 20;
            self.localVideoView.frame = frame;
            
            frame = self.hudToolbar.frame;
            frame.origin.x = 90;
            frame.origin.y = 240;
            self.hudToolbar.frame = frame;
            
            frame = self.indicatorToolbar.frame;
            frame.origin.x = 448;
            frame.origin.y = 210;
            self.indicatorToolbar.frame = frame;
        }
    }
    
    
    self.localPreviewVideoController = [[self storyboard] instantiateViewControllerWithIdentifier:@"AcuVideoView"];
    self.localPreviewVideoController.participantLabel.hidden = YES;
    self.localPreviewVideoController.activeSpeakerIndictor.hidden = YES;
    
    if (_videoCallMode == 1)
    {
        if (deviceOrientation == UIDeviceOrientationPortrait ||
            deviceOrientation == UIDeviceOrientationPortraitUpsideDown)
        {
            self.localPreviewVideoController.view.frame = CGRectMake(70, 0, 90, 120);
        }
        else if (deviceOrientation == UIDeviceOrientationLandscapeRight ||
                 deviceOrientation == UIDeviceOrientationLandscapeLeft)
        {
            self.localPreviewVideoController.view.frame = CGRectMake(0, 0, 160, 120);
        }
        else
        {
            self.localPreviewVideoController.view.frame = CGRectMake(70, 0, 90, 120);
        }
    }
    else
    {
        self.localPreviewVideoController.view.frame = CGRectMake(0, 0, 160, 120);
    }
    
    
    [self.localVideoView addSubview:self.localPreviewVideoController.view];
    [self.localPreviewVideoController.videoView setupGL:_glContext];
    self.localPreviewVideoController.videoView.presentationRect = CGSizeMake(_videoWidth, _videoHeight);
    
    
    [_videoCapture startCapture:15];
    
    if (_videoCallMode == 1)
    {
        if (!self.videoCallToolbar.hidden)
        {
            _hudToolbarTimer = [NSTimer scheduledTimerWithTimeInterval:ACU_HUD_TOOLBAR_DISAPPEAR_TIMER
                                                                target:self
                                                              selector:@selector(handleHudToolbarTimer:)
                                                              userInfo:nil
                                                               repeats:NO];
        }
    }
    else
    {
        if (!self.hudToolbar.hidden)
        {
            _hudToolbarTimer = [NSTimer scheduledTimerWithTimeInterval:ACU_HUD_TOOLBAR_DISAPPEAR_TIMER
                                                                target:self
                                                              selector:@selector(handleHudToolbarTimer:)
                                                              userInfo:nil
                                                               repeats:NO];
        }
    }
    
    CGSize size;
    size.width = 240.0f;
    size.height = 240.0f;
    _layoutModePop = [[UIPopoverListView alloc] initWithSize:size];
    _layoutModePop.delegate = self;
    _layoutModePop.datasource = self;
    _layoutModePop.listView.scrollEnabled = FALSE;
    [_layoutModePop setTitle:NSLocalizedString(@"Layout Mode", @"Conference Presention")];
    
    
    _audioManager = [[AcuAudioManager alloc] init];
    _audioManager.audioDelegate = self;
    [_audioManager setVideoCallAVMode:_videoCallAVMode];
    
    [_audioManager setMute:YES];
    [_audioManager startAudioManager];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(willEndConference)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
    
    
    NSError *error = nil;
#if ACU_IOS_SAVE_AUDIO_CAPTURE_DATA
    NSArray *paths4Capture = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory4Capture = [paths4Capture objectAtIndex:0];
    NSLog(@"%@",documentsDirectory4Capture);
    
    //make a full file name
    NSString *fileName4Capture = [NSString stringWithFormat:@"%@/acuAudioCaptureData.raw", documentsDirectory4Capture];
    NSLog(@"File path and name:%@", fileName4Capture);
    
    NSFileManager *filemgr4Capture = [NSFileManager defaultManager];
    if ([filemgr4Capture fileExistsAtPath: fileName4Capture ] == YES)
    {
        NSLog (@"File exists");
        [filemgr4Capture removeItemAtPath:fileName4Capture error:&error];
        if (error != nil)
        {
            NSLog(@"Remove file error");
        }
        NSLog(@"Create file");
        [filemgr4Capture createFileAtPath:fileName4Capture contents:nil attributes:nil];
    }
    else
    {
        NSLog (@"File not found");
        [filemgr4Capture createFileAtPath:fileName4Capture contents:nil attributes:nil];
    }
    
    _audioCaptureDataFileHandler = [NSFileHandle fileHandleForWritingAtPath:fileName4Capture];
    if (_audioCaptureDataFileHandler == nil)
    {
        NSLog(@"Failed to open file");
    }
    
#endif
    
#if ACU_IOS_SAVE_AUDIO_PLAYBACK_DATA
    NSArray *paths4Playback = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory4Playback = [paths4Playback objectAtIndex:0];
    NSLog(@"%@",documentsDirectory4Playback);
    
    //make a full file name
    NSString *fileName4Playback = [NSString stringWithFormat:@"%@/acuAudioPlaybackData.raw", documentsDirectory4Playback];
    NSLog(@"File path and name:%@", fileName4Playback);
    
    NSFileManager *filemgr4Playback = [NSFileManager defaultManager];
    if ([filemgr4Playback fileExistsAtPath: fileName4Playback] == YES)
    {
        NSLog (@"File exists");
        [filemgr4Playback removeItemAtPath:fileName4Playback error:&error];
        if (error != nil)
        {
            NSLog(@"Remove file error");
        }
        NSLog(@"Create file");
        [filemgr4Playback createFileAtPath:fileName4Playback contents:nil attributes:nil];
    }
    else
    {
        NSLog (@"File not found");
        [filemgr4Playback createFileAtPath:fileName4Playback contents:nil attributes:nil];
    }
    
    _audioPlaybackDataFileHandler = [NSFileHandle fileHandleForWritingAtPath:fileName4Playback];
    if (_audioPlaybackDataFileHandler == nil)
    {
        NSLog(@"Failed to open file");
    }
    
#endif
    
    self.conferenceParticipantList = nil;
    
    _hostEndConferenceAlertController = nil;
    _participantEndConferenceAlertController = nil;
    _endConferenceAlertController = nil;
    _invitedPresentAlertController = nil;
    _invitedSpeakerAlertController = nil;
    _acuComIncomingAlertController = nil;
    _acuComNotificationAlertController = nil;
    
    _hostEndConferenceAlertView = nil;
    _participantEndConferenceAlertView = nil;
    _endConferenceAlertView = nil;
    _invitedPresentAlertView = nil;
    _invitedSpeakerAlertView = nil;
    
    _acuComIncomingAlertView = nil;
    _acuComNotificationAlertView = nil;
    _acuComNotificationType = 0;
    
    //_acucomListener = 0;
    _inComingCallConfig = nil;
    
    _bStillGotVideoData = NO;
    NSTimeInterval dbFrameRate = 1/15.0;
    _remoteVideoTimer = [NSTimer scheduledTimerWithTimeInterval:dbFrameRate
                                                         target:self
                                                       selector:@selector(getRemoteVideoData:)
                                                       userInfo:nil
                                                        repeats:YES];
    
    _localVideoTimer = [NSTimer scheduledTimerWithTimeInterval:dbFrameRate
                                                        target:self
                                                      selector:@selector(getLocalVideoData:)
                                                      userInfo:nil
                                                       repeats:YES];
    
    _needDeallocResource = YES;
    
    _bConferenceShowing = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.conferenceDelegate)
    {
        if (_videoCallAVMode == 1 && _bVideoCallLauncher)
        {
            NSMutableDictionary *commandDict = [NSMutableDictionary new];
            [commandDict setValue:[NSNumber numberWithBool: NO] forKey:@"enable"];
            
            
            NSError *error = nil;
            NSData *commandData = [NSJSONSerialization dataWithJSONObject:commandDict
                                                                  options:NSJSONWritingPrettyPrinted
                                                                    error:&error];
            
            const char *commandJsonData = (const char*)[commandData bytes];
            [self.conferenceCommandDelegate acuConferenceSendCommand:cmd_enable_room_video
                                                            withInfo:commandJsonData];
            
            [commandDict removeAllObjects];
            commandDict = nil;
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [_videoFrameMutex lock];
    [self setLayout];
    _bStillGotVideoData = YES;
    [_videoFrameMutex unlock];
    
    if (_acucomListener)
    {
        //_acucomListener->conferenceNotification(AcuCom_ConferenceSession_Start_Success);
    }
    
    _bConferenceShowing = YES;
    
    if (_bHasQueueNotification)
    {
        [self conferenceNotification:_nQueueNotificationType
                           msgSumary:_strQueueNotificationSumary
                             session:_strQueueNotificationSessinId];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willEndConference
{
    [self exitConference:AcuConferenceEndStatusLeave];
}

#pragma mark ----UIViewControllerRotation----

//this is only support iOS6
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (_videoCallMode == 0)
    {
        return (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight ||
                toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft);
    }
    else
    {
        return YES;
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if (_videoCallMode == 1)
    {
        if (_videoCallAVMode == 1)
        {
            return UIInterfaceOrientationMaskPortrait;
        }
        else
        {
            return UIInterfaceOrientationMaskAll;
        }
    }
    else
    {
        return UIInterfaceOrientationMaskLandscape;
    }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    if (_videoCallMode == 1)
    {
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        if (_videoCallAVMode == 1)
        {
            return UIInterfaceOrientationPortrait;
        }
        else
        {
            if (orientation == UIDeviceOrientationLandscapeLeft)
            {
                return UIInterfaceOrientationLandscapeRight;
            }
            else if ( orientation == UIDeviceOrientationLandscapeRight )
            {
                return UIInterfaceOrientationLandscapeLeft;
            }
            else if (orientation == UIDeviceOrientationPortrait)
            {
                return UIInterfaceOrientationPortrait;
            }
            else if (orientation == UIDeviceOrientationPortraitUpsideDown)
            {
                return UIInterfaceOrientationPortraitUpsideDown;
            }
            
            return UIInterfaceOrientationPortrait;
        }
        
    }
    else
    {
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        if (orientation == UIDeviceOrientationLandscapeLeft)
        {
            return UIInterfaceOrientationLandscapeRight;
        }
        else if ( orientation == UIDeviceOrientationLandscapeRight )
        {
            return UIInterfaceOrientationLandscapeLeft;
        }
        
        return UIInterfaceOrientationLandscapeRight;
    }
    //    UIViewController* viewControllerA = (UIViewController*) [[self.view superview] nextResponder];
    //    return [viewControllerA preferredInterfaceOrientationForPresentation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if(_videoCallMode != 1)
        return;
    
    
    
    //[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if (_layoutStatus == AcuConferenceLayoutStatus1Video && self.videoViewController1 != nil)
    {
        //self.videoViewController1.view.hidden = YES;
    }
    
    
    
    CGRect frame;
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait ||
        toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        NSLog(@"Rotate to Portrait");
        if (_biPhone5Above)
        {
            frame = self.localVideoView.frame;
            frame.origin.x = 130;
            frame.origin.y = 20;
            self.localVideoView.frame = frame;
#if 0
            frame = self.hudToolbar.frame;
            frame.origin.x = 40;
            frame.origin.y = 400+88;
            self.hudToolbar.frame = frame;
#else
            frame = self.videoCallToolbar.frame;
            frame.origin.x = 70;
            frame.origin.y = 400+88;
            self.videoCallToolbar.frame = frame;
#endif
            
            frame = self.indicatorToolbar.frame;
            frame.origin.x = 288;
            frame.origin.y = 370+88;
            self.indicatorToolbar.frame = frame;
        }
        else
        {
            frame = self.localVideoView.frame;
            frame.origin.x = 130;
            frame.origin.y = 20;
            self.localVideoView.frame = frame;
#if 0
            frame = self.hudToolbar.frame;
            frame.origin.x = 40;
            frame.origin.y = 400;
            self.hudToolbar.frame = frame;
#else
            frame = self.videoCallToolbar.frame;
            frame.origin.x = 70;
            frame.origin.y = 400;
            self.videoCallToolbar.frame = frame;
#endif
            frame = self.indicatorToolbar.frame;
            frame.origin.x = 288;
            frame.origin.y = 370;
            self.indicatorToolbar.frame = frame;
        }
        
    }
    else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
             toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        NSLog(@"Rotate to Landscape");
        if (_biPhone5Above)
        {
            frame = self.localVideoView.frame;
            frame.origin.x = 290+88;
            frame.origin.y = 20;
            self.localVideoView.frame = frame;
#if 0
            frame = self.hudToolbar.frame;
            frame.origin.x = 120+44;
            frame.origin.y = 240;
            self.hudToolbar.frame = frame;
#else
            frame = self.videoCallToolbar.frame;
            frame.origin.x = 150+44;
            frame.origin.y = 240;
            self.videoCallToolbar.frame = frame;
#endif
            frame = self.indicatorToolbar.frame;
            frame.origin.x = 448+88;
            frame.origin.y = 210;
            self.indicatorToolbar.frame = frame;
        }
        else
        {
            frame = self.localVideoView.frame;
            frame.origin.x = 290;
            frame.origin.y = 20;
            self.localVideoView.frame = frame;
#if 0
            frame = self.hudToolbar.frame;
            frame.origin.x = 120;
            frame.origin.y = 240;
            self.hudToolbar.frame = frame;
#else
            frame = self.videoCallToolbar.frame;
            frame.origin.x = 150;
            frame.origin.y = 240;
            self.videoCallToolbar.frame = frame;
#endif
            frame = self.indicatorToolbar.frame;
            frame.origin.x = 448;
            frame.origin.y = 210;
            self.indicatorToolbar.frame = frame;
        }
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    if(_videoCallMode != 1)
        return;
    
    if (_videoCallAVMode == 1)
    {
        return;
    }
    
    
    NSLog(@"did Rotate");
    //[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    int nViewWidth = self.view.frame.size.width;
    int nViewHight = self.view.frame.size.height;
    
    //NSLog(@"view w:%d, h:%d", nViewWidth, nViewHight);
    
    if (_layoutStatus == AcuConferenceLayoutStatus1Video && self.videoViewController1 != nil)
    {
        //self.videoViewController1.view.hidden = YES;
#if 0
        BOOL animated = YES;
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        CGFloat radians = 0;
        if (UIInterfaceOrientationIsLandscape(orientation)) {
            if (orientation == UIInterfaceOrientationLandscapeLeft) { radians = -(CGFloat)M_PI_2; }
            else { radians = (CGFloat)M_PI_2; }
            // Window coordinates differ!
            self.view.bounds = CGRectMake(0, 0, self.view.bounds.size.height, self.view.bounds.size.width);
        } else {
            if (orientation == UIInterfaceOrientationPortraitUpsideDown) { radians = (CGFloat)M_PI; }
            else { radians = 0; }
        }
        rotationTransform = CGAffineTransformMakeRotation(radians);
        
        if (animated) {
            [UIView beginAnimations:nil context:nil];
        }
        [self.view setTransform:rotationTransform];
        if (animated) {
            [UIView commitAnimations];
        }
#endif
        self.videoViewController1.view.frame = CGRectMake(0, 0, nViewWidth, nViewHight);
        //self.videoViewController1.view.hidden = NO;
    }
    
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view.superview isKindOfClass:[UIButton class]] || [touch.view isKindOfClass:[UIButton class]])
    {
        return NO;
    }
    return YES;
    
    //return ! ([touch.view isKindOfClass:[UIControl class]]);
}


- (IBAction)didTapGesture:(UIGestureRecognizer *)sender
{
    CGPoint pt;
    CGRect audioIndicatorRect = self.audioIndicator.frame;
    CGRect videoIndicatorRect = self.videoIndicator.frame;
    
    pt = [sender locationInView:self.indicatorToolbar];
    if (CGRectContainsPoint(audioIndicatorRect, pt) && !self.audioIndicator.hidden)
    {
        [self pressedLocalVideoViewAudio:nil];
        return;
    }
    else if (CGRectContainsPoint(videoIndicatorRect, pt) && !self.videoIndicator.hidden)
    {
        [self pressedLocalVideoViewVideo:nil];
        return;
    }
    
    if (_videoCallMode == 1)
    {
        self.videoCallToolbar.hidden = !self.videoCallToolbar.hidden;
        
    }
    else
    {
        self.hudToolbar.hidden = !self.hudToolbar.hidden;
    }
    
    if (_videoCallAVMode == 1)
    {
        self.localVideoView.hidden = YES;
    }
    else
    {
        if (!_bLocalVideoViewPin)
        {
            self.localVideoView.hidden = !self.localVideoView.hidden;
        }
    }
    
    //[[UIApplication sharedApplication] setStatusBarHidden:self.hudToolbar.hidden  withAnimation:UIStatusBarAnimationFade];
    
    
    if (_hudToolbarTimer)
    {
        [_hudToolbarTimer invalidate];
        _hudToolbarTimer = nil;
    }
    
    if (_videoCallMode == 1)
    {
        if (!self.videoCallToolbar.hidden)
        {
            _hudToolbarTimer = [NSTimer scheduledTimerWithTimeInterval:ACU_HUD_TOOLBAR_DISAPPEAR_TIMER
                                                                target:self
                                                              selector:@selector(handleHudToolbarTimer:)
                                                              userInfo:nil
                                                               repeats:NO];
        }
    }
    else
    {
        if (!self.hudToolbar.hidden)
        {
            _hudToolbarTimer = [NSTimer scheduledTimerWithTimeInterval:ACU_HUD_TOOLBAR_DISAPPEAR_TIMER
                                                                target:self
                                                              selector:@selector(handleHudToolbarTimer:)
                                                              userInfo:nil
                                                               repeats:NO];
        }
    }
    
}

- (IBAction)pressedLocalVideoViewPin:(id)sender
{
    _bLocalVideoViewPin = !_bLocalVideoViewPin;
    if (!_bLocalVideoViewPin)
    {
        if (_videoCallMode == 1)
        {
            if (self.videoCallToolbar.hidden)
            {
                self.localVideoView.hidden = YES;
            }
        }
        else
        {
            if (self.hudToolbar.hidden)
            {
                self.localVideoView.hidden = YES;
            }
        }
        
        
        self.localVideoViewPinBtn.selected = NO;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            [self.localVideoViewPinBtn setImage:[UIImage imageNamed:@"iPad_pin.png"]
                                       forState:UIControlStateNormal];
        }
        else
        {
            [self.localVideoViewPinBtn setImage:[UIImage imageNamed:@"iPhone_pin.png"]
                                       forState:UIControlStateNormal];
        }
        
    }
    else
    {
        self.localVideoViewPinBtn.selected = YES;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            [self.localVideoViewPinBtn setImage:[UIImage imageNamed:@"iPad_pin_d.png"]
                                       forState:UIControlStateSelected];
        }
        else
        {
            [self.localVideoViewPinBtn setImage:[UIImage imageNamed:@"iPhone_pin_d.png"]
                                       forState:UIControlStateSelected];
        }
        
    }
}

- (IBAction)pressedLocalVideoViewSwitch:(id)sender
{
    if(_videoCallAVMode == 1)
        return;
    
    [_videoCapture switchCamera];
}

- (IBAction)pressedLocalVideoViewVideo:(id)sender
{
    if (_videoCallAVMode == 1)
        return;
    
    _bMuteLocalVideo = !_bMuteLocalVideo;
    if (self.conferenceDelegate)
    {
        NSMutableDictionary *commandDict = [NSMutableDictionary new];
        [commandDict setValue:[NSNumber numberWithInt:0] forKey:@"video_channel"];
        [commandDict setValue:[NSNumber numberWithBool:!_bMuteLocalVideo] forKey:@"enable"];
        [commandDict setValue:[NSNumber numberWithInt:1] forKey:@"is_send_status"];
        
        
        NSError *error = nil;
        NSData *commandData = [NSJSONSerialization dataWithJSONObject:commandDict
                                                              options:NSJSONWritingPrettyPrinted
                                                                error:&error];
        
        const char *commandJsonData = (const char*)[commandData bytes];
        [self.conferenceCommandDelegate acuConferenceSendCommand:cmd_enable_local_video
                                                        withInfo:commandJsonData];
        
        [commandDict removeAllObjects];
        commandDict = nil;
    }
    [self updateLocalVideoBtnStatus:_bSpeaker
                          localMute:_bMuteLocalVideo];
    
    [self updateAcuComNoVideoBtnStatus];
}

- (IBAction)pressedLocalVideoViewAudio:(id)sender
{
    _bMuteLocalAudio = !_bMuteLocalAudio;
    
    if (self.conferenceDelegate)
    {
        NSMutableDictionary *commandDict = [NSMutableDictionary new];
        [commandDict setValue:[NSNumber numberWithBool:!_bMuteLocalAudio] forKey:@"enable"];
        [commandDict setValue:[NSNumber numberWithInt:1] forKey:@"is_send_status"];
        
        
        NSError *error = nil;
        NSData *commandData = [NSJSONSerialization dataWithJSONObject:commandDict
                                                              options:NSJSONWritingPrettyPrinted
                                                                error:&error];
        
        const char *commandJsonData = (const char*)[commandData bytes];
        [self.conferenceCommandDelegate acuConferenceSendCommand:cmd_enable_local_audio
                                                        withInfo:commandJsonData];
        
        [commandDict removeAllObjects];
        commandDict = nil;
    }
    
    
    [self updateLocalAudioBtnStatus:_bSpeaker
                          localMute:_bMuteLocalAudio];
    
    if (_videoCallAVMode == 1)
    {
        [self updateAcuComMuteMicBtnStatus];
    }
}

- (IBAction)pressedLayout:(id)sender
{
    if (_videoCallMode == 1)
    {
        return;
    }
    
    [_layoutModePop.listView reloadData];
    [_layoutModePop show];
}

- (IBAction)pressedPresenter:(id)sender
{
    if (_videoCallMode == 1)
    {
        return;
    }
    
    _bWaitingPresenterStatus = YES;
    
    if (_bPresenter)
    {
        if (self.conferenceDelegate)
        {
            [self.conferenceCommandDelegate acuConferenceSendCommand:cmd_give_up_presenting
                                                            withInfo:""];
        }
    }
    else
    {
        if (self.conferenceDelegate)
        {
            [self.conferenceCommandDelegate acuConferenceSendCommand:cmd_ask_become_presenter
                                                            withInfo:""];
        }
        
    }
    
    [self updateToolbarPresenterStatus:_bSpeaker isPresenter:_bPresenter];
    [self updateToolbarLayoutStatus];
    
    //	[self updateToolbarSpeakerStatus:NO isSpeaker:_bSpeaker];
    //	_bPresenter = !_bPresenter;
    //	[self updateToolbarPresenterStatus:_bSpeaker
    //						   isPresenter:_bPresenter];
    //
    //	[self updateToolbarLayoutStatus];
}

- (IBAction)pressedSpeaker:(id)sender
{
    if (_videoCallMode == 1)
    {
        return;
    }
    
    _bWaitingSpeakerStatus = YES;
    
    if (_bSpeaker)
    {
        if (self.conferenceDelegate)
        {
            _eSpeakerHangingUpStatus = AcuSpeakerHangupStatus_WaitingGiveup;
            [self.conferenceCommandDelegate acuConferenceSendCommand:cmd_give_up_speaking
                                                            withInfo:""];
        }
    }
    else
    {
        if (self.conferenceDelegate)
        {
            if (_eSpeakerHangingUpStatus == AcuSpeakerHangupStatus_None ||
                _eSpeakerHangingUpStatus == AcuSpeakerHangupStatus_Giveup)
            {
                _eSpeakerHangingUpStatus = AcuSpeakerHangupStatus_WaitingRequest;
                [self.conferenceCommandDelegate acuConferenceSendCommand:cmd_request_become_speaker
                                                                withInfo:""];
            }
            else if(_eSpeakerHangingUpStatus == AcuSpeakerHangupStatus_Request)
            {
                _eSpeakerHangingUpStatus = AcuSpeakerHangupStatus_WaitingGiveup;
                [self.conferenceCommandDelegate acuConferenceSendCommand:cmd_give_up_speaking
                                                                withInfo:""];
            }
        }
        
    }
    
    [self updateToolbarSpeakerStatus:_bCanSpeaker isSpeaker:_bSpeaker];
    [self updateToolbarPresenterStatus:_bSpeaker isPresenter:_bPresenter];
    [self updateToolbarLayoutStatus];
}

- (IBAction)pressedExit:(id)sender
{
#if ACU_COM_USE_ALERTCONTROLLER
    if (_videoCallMode == 0)
    {
        if (_bModerator && [self.conferenceParticipantList count] > 1)
        {
            if (ACU_COM_IOS8)
            {
                NSString *title = NSLocalizedString(@"Confirm Exit", nil);
                NSString *message = NSLocalizedString(@"You are the host of this session. Transfer host rights will allow the session to continue while you exit the conference. Click 'Yes' to transfer host rights or 'No' to end the conference session.", nil);
                NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", nil);
                NSString *yesButtonTitle = NSLocalizedString(@"Yes", nil);
                NSString *noButtonTitle = NSLocalizedString(@"No", nil);
                
                _hostEndConferenceAlertController = [UIAlertController alertControllerWithTitle:title
                                                                                        message:message
                                                                                 preferredStyle:UIAlertControllerStyleAlert];
                
                // Create the actions.
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle
                                                                       style:UIAlertActionStyleCancel
                                                                     handler:^(UIAlertAction *action) {
                                                                         NSLog(@"hostEndConferenceAlert Pressed cancel");
                                                                         _hostEndConferenceAlertController = nil;
                                                                     }];
                
                
                
                UIAlertAction *yesAction = [UIAlertAction actionWithTitle:yesButtonTitle
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {
                                                                      [self exitConference:AcuConferenceEndStatusModeratorLeave];
                                                                      _hostEndConferenceAlertController = nil;
                                                                  }];
                
                UIAlertAction *noAction = [UIAlertAction actionWithTitle:noButtonTitle
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action) {
                                                                     [self exitConference:AcuConferenceEndStatusModeratorStop];
                                                                     _hostEndConferenceAlertController = nil;
                                                                 }];
                
                // Add the actions.
                [_hostEndConferenceAlertController addAction:cancelAction];
                [_hostEndConferenceAlertController addAction:yesAction];
                [_hostEndConferenceAlertController addAction:noAction];
                
                [self presentViewController:_hostEndConferenceAlertController animated:YES completion:nil];
            }
            else
            {
                _hostEndConferenceAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Confirm Exit", @"Conference Presention Host Exit Alert")
                                                                         message:NSLocalizedString(@"You are the host of this session. Transfer host rights will allow the session to continue while you exit the conference. Click 'Yes' to transfer host rights or 'No' to end the conference session.", @"Conference Presention Host Exit Alert")
                                                                        delegate:self
                                                               cancelButtonTitle:NSLocalizedString(@"Cancel", @"Conference Presention Host Exit Alert")
                                                               otherButtonTitles:NSLocalizedString(@"Yes", @"Conference Presention Host Exit Alert"),
                                               NSLocalizedString(@"No", @"Conference Presention Host Exit Alert"),
                                               nil];
                
                [_hostEndConferenceAlertView show];
            }
            
        }
        else
        {
            if (ACU_COM_IOS8)
            {
                NSString *title = NSLocalizedString(@"Confirm Exit", nil);
                NSString *message = NSLocalizedString(@"Do you want to exit this session?", nil);
                NSString *yesButtonTitle = NSLocalizedString(@"Yes", nil);
                NSString *noButtonTitle = NSLocalizedString(@"No", nil);
                
                _participantEndConferenceAlertController = [UIAlertController alertControllerWithTitle:title
                                                                                               message:message
                                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
                // Create the actions.
                
                UIAlertAction *yesAction = [UIAlertAction actionWithTitle:yesButtonTitle
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {
                                                                      [self exitConference:AcuConferenceEndStatusLeave];
                                                                      _participantEndConferenceAlertController = nil;
                                                                  }];
                
                UIAlertAction *noAction = [UIAlertAction actionWithTitle:noButtonTitle
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action) {
                                                                     NSLog(@"participantEndConferenceAlert Pressed NO");
                                                                     [_participantEndConferenceAlertController dismissViewControllerAnimated:YES
                                                                                                                                  completion:nil];
                                                                     _participantEndConferenceAlertController = nil;
                                                                 }];
                
                // Add the actions.
                [_participantEndConferenceAlertController addAction:yesAction];
                [_participantEndConferenceAlertController addAction:noAction];
                
                [self presentViewController:_participantEndConferenceAlertController animated:YES completion:nil];
            }
            else
            {
                _participantEndConferenceAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Confirm Exit", @"Conference Presention Exit Alert")
                                                                                message:NSLocalizedString(@"Do you want to exit this session?", @"Conference Presention Exit Alert")
                                                                               delegate:self
                                                                      cancelButtonTitle:NSLocalizedString(@"Yes", @"Conference Presention Exit Alert")
                                                                      otherButtonTitles:NSLocalizedString(@"No", @"Conference Presention Exit Alert"),
                                                      nil];
                
                [_participantEndConferenceAlertView show];
            }
        }
    }
    else
    {
        if (ACU_COM_IOS8)
        {
            NSString *title = NSLocalizedString(@"Confirm Exit", nil);
            NSString *message = NSLocalizedString(@"Do you want to exit this session?", nil);
            NSString *yesButtonTitle = NSLocalizedString(@"Yes", nil);
            NSString *noButtonTitle = NSLocalizedString(@"No", nil);
            
            _participantEndConferenceAlertController = [UIAlertController alertControllerWithTitle:title
                                                                                           message:message
                                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            // Create the actions.
            
            UIAlertAction *yesAction = [UIAlertAction actionWithTitle:yesButtonTitle
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
                                                                  [self exitConference:AcuConferenceEndStatusLeave];
                                                                  _participantEndConferenceAlertController = nil;
                                                              }];
            
            UIAlertAction *noAction = [UIAlertAction actionWithTitle:noButtonTitle
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 [_participantEndConferenceAlertController dismissViewControllerAnimated:YES completion:nil];
                                                                 _participantEndConferenceAlertController = nil;
                                                                 NSLog(@"participantEndConferenceAlert Pressed NO");
                                                             }];
            
            // Add the actions.
            [_participantEndConferenceAlertController addAction:yesAction];
            [_participantEndConferenceAlertController addAction:noAction];
            
            [self presentViewController:_participantEndConferenceAlertController animated:YES completion:nil];
        }
        else
        {
            _participantEndConferenceAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Confirm Exit", @"Conference Presention Exit Alert")
                                                                            message:NSLocalizedString(@"Do you want to exit this session?", @"Conference Presention Exit Alert")
                                                                           delegate:self
                                                                  cancelButtonTitle:NSLocalizedString(@"Yes", @"Conference Presention Exit Alert")
                                                                  otherButtonTitles:NSLocalizedString(@"No", @"Conference Presention Exit Alert"),
                                                  nil];
            
            [_participantEndConferenceAlertView show];
        }
    }
#else
    if (_videoCallMode == 0)
    {
        if (_bModerator && [self.conferenceParticipantList count] > 1)
        {
            _hostEndConferenceAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Confirm Exit", @"Conference Presention Host Exit Alert")
                                                                     message:NSLocalizedString(@"You are the host of this session. Transfer host rights will allow the session to continue while you exit the conference. Click 'Yes' to transfer host rights or 'No' to end the conference session.", @"Conference Presention Host Exit Alert")
                                                                    delegate:self
                                                           cancelButtonTitle:NSLocalizedString(@"Cancel", @"Conference Presention Host Exit Alert")
                                                           otherButtonTitles:NSLocalizedString(@"Yes", @"Conference Presention Host Exit Alert"),
                                           NSLocalizedString(@"No", @"Conference Presention Host Exit Alert"),
                                           nil];
            
            [_hostEndConferenceAlertView show];
        }
        else
        {
            _participantEndConferenceAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Confirm Exit", @"Conference Presention Exit Alert")
                                                                            message:NSLocalizedString(@"Do you want to exit this session?", @"Conference Presention Exit Alert")
                                                                           delegate:self
                                                                  cancelButtonTitle:NSLocalizedString(@"Yes", @"Conference Presention Exit Alert")
                                                                  otherButtonTitles:NSLocalizedString(@"No", @"Conference Presention Exit Alert"),
                                                  nil];
            
            [_participantEndConferenceAlertView show];
        }
    }
    else
    {
        _participantEndConferenceAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Confirm Exit", @"Conference Presention Exit Alert")
                                                                        message:NSLocalizedString(@"Do you want to exit this session?", @"Conference Presention Exit Alert")
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"Yes", @"Conference Presention Exit Alert")
                                                              otherButtonTitles:NSLocalizedString(@"No", @"Conference Presention Exit Alert"),
                                              nil];
        
        [_participantEndConferenceAlertView show];
    }
#endif
}

- (IBAction)pressedAcuComNoVideo:(id)sender
{
    if (_videoCallAVMode != 0)
    {
        return;
    }
    
    [self pressedLocalVideoViewVideo:nil];
    
    //[self updateAcuComNoVideoBtnStatus];
//    
//    
//    [self.toolbarAcuComNoVideo setTitleColor:[UIColor whiteColor]
//                                forState:UIControlStateNormal];
}

- (void)updateAcuComNoVideoBtnStatus
{
    if (!_bMuteLocalVideo)
    {
        self.toolbarAcuComNoVideo.selected = YES;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            [self.toolbarAcuComNoVideo setBackgroundImage:[UIImage imageNamed:@"iPad_novideo_d.png"]
                                                 forState:UIControlStateSelected];
        }
        else
        {
            [self.toolbarAcuComNoVideo setBackgroundImage:[UIImage imageNamed:@"iPhone_novideo_d.png"]
                                                 forState:UIControlStateSelected];
        }
    }
    else
    {
        self.toolbarAcuComNoVideo.selected = NO;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            [self.toolbarAcuComNoVideo setBackgroundImage:[UIImage imageNamed:@"iPad_novideo.png"]
                                                 forState:UIControlStateNormal];
        }
        else
        {
            [self.toolbarAcuComNoVideo setBackgroundImage:[UIImage imageNamed:@"iPhone_novideo.png"]
                                                 forState:UIControlStateNormal];
        }
    }
}

- (IBAction)pressedAcuComHandFree:(id)sender
{
    if (_videoCallAVMode != 1)
    {
        return;
    }
    
    _bAcuComHandFree = !_bAcuComHandFree;
    
    if (_audioManager)
    {
        [_audioManager setHandFreeMode:_bAcuComHandFree];
    }
    
    [self updateAcuComHandFreeBtnStatus];
    
//    [self.toolbarAcuComHandFree setTitleColor:[UIColor whiteColor]
//                                    forState:UIControlStateNormal];
}

- (IBAction)pressedAcuComVideoQuality:(id)sender 
{
    isHDQuality = !isHDQuality;
    
    //send quality changed command.
    if (self.conferenceDelegate)
    {
        NSMutableDictionary *commandDict = [NSMutableDictionary new];
        if (isHDQuality)
        {
            [commandDict setValue:[NSNumber numberWithInt:1] forKey:@"stream_number"];
        }
        else
        {
            [commandDict setValue:[NSNumber numberWithInt:2] forKey:@"stream_number"];
        }
        
        NSError *error = nil;
        NSData *commandData = [NSJSONSerialization dataWithJSONObject:commandDict
                                                              options:NSJSONWritingPrettyPrinted
                                                                error:&error];
        
        const char *commandJsonData = (const char*)[commandData bytes];
        [self.conferenceCommandDelegate acuConferenceSendCommand:cmd_switch_video_stream_number
                                                        withInfo:commandJsonData];
        
        [commandDict removeAllObjects];
        commandDict = nil;
    }
    
    [self updateToolbarQulityStatus];
}

- (void)updateAcuComHandFreeBtnStatus
{
    if (_bAcuComHandFree)
    {
        self.toolbarAcuComHandFree.selected = YES;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            [self.toolbarAcuComHandFree setBackgroundImage:[UIImage imageNamed:@"iPad_handfree_d.png"]
                                                  forState:UIControlStateSelected];
        }
        else
        {
            [self.toolbarAcuComHandFree setBackgroundImage:[UIImage imageNamed:@"iPhone_handfree_d.png"]
                                                  forState:UIControlStateSelected];
        }
    }
    else
    {
        self.toolbarAcuComHandFree.selected = NO;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            [self.toolbarAcuComHandFree setBackgroundImage:[UIImage imageNamed:@"iPad_handfree.png"]
                                                  forState:UIControlStateNormal];
        }
        else
        {
            [self.toolbarAcuComHandFree setBackgroundImage:[UIImage imageNamed:@"iPhone_handfree.png"]
                                                  forState:UIControlStateNormal];
        }
    }
}

- (void)updateAcuComMuteMicBtnStatus
{
    if (_videoCallAVMode != 1)
    {
        return;
    }
    
    if (_videoCallMode == 0)
    {
        if (_bMuteLocalAudio)
        {
            self.toolbarAcuComConfMuteMic.selected = YES;
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                [self.toolbarAcuComConfMuteMic setBackgroundImage:[UIImage imageNamed:@"iPad_toolbar_mic_d.png"]
                                                     forState:UIControlStateSelected];
            }
            else
            {
                [self.toolbarAcuComConfMuteMic setBackgroundImage:[UIImage imageNamed:@"iPhone_toolbar_mic_d.png"]
                                                     forState:UIControlStateSelected];
            }
        }
        else
        {
            self.toolbarAcuComConfMuteMic.selected = NO;
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                [self.toolbarAcuComConfMuteMic setBackgroundImage:[UIImage imageNamed:@"iPad_toolbar_mic.png"]
                                                     forState:UIControlStateNormal];
            }
            else
            {
                [self.toolbarAcuComConfMuteMic setBackgroundImage:[UIImage imageNamed:@"iPhone_toolbar_mic.png"]
                                                     forState:UIControlStateNormal];
            }
        }
    }
    else
    {
        if (_bMuteLocalAudio)
        {
            self.toolbarAcuComMuteMic.selected = YES;
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                [self.toolbarAcuComMuteMic setBackgroundImage:[UIImage imageNamed:@"iPad_toolbar_mic_d.png"]
                                                      forState:UIControlStateSelected];
            }
            else
            {
                [self.toolbarAcuComMuteMic setBackgroundImage:[UIImage imageNamed:@"iPhone_toolbar_mic_d.png"]
                                                      forState:UIControlStateSelected];
            }
        }
        else
        {
            self.toolbarAcuComMuteMic.selected = NO;
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                [self.toolbarAcuComMuteMic setBackgroundImage:[UIImage imageNamed:@"iPad_toolbar_mic.png"]
                                                      forState:UIControlStateNormal];
            }
            else
            {
                [self.toolbarAcuComMuteMic setBackgroundImage:[UIImage imageNamed:@"iPhone_toolbar_mic.png"]
                                                      forState:UIControlStateNormal];
            }
        }
    }
}

- (IBAction)pressedAcuComAVSwitch:(id)sender
{
    BOOL bEnableVideo = NO;
    if (_videoCallAVMode == 0)
    {
        bEnableVideo = NO;
        _videoCallAVMode = 1;
    }
    else
    {
        bEnableVideo = YES;
        _videoCallAVMode = 0;
    }
    
    [self showAcuComLocalPreviewToolbar];
    
    if (self.conferenceDelegate)
    {
        NSMutableDictionary *commandDict = [NSMutableDictionary new];
        [commandDict setValue:[NSNumber numberWithBool:bEnableVideo] forKey:@"enable"];
        
        
        NSError *error = nil;
        NSData *commandData = [NSJSONSerialization dataWithJSONObject:commandDict
                                                              options:NSJSONWritingPrettyPrinted
                                                                error:&error];
        
        const char *commandJsonData = (const char*)[commandData bytes];
        [self.conferenceCommandDelegate acuConferenceSendCommand:cmd_enable_room_video
                                                        withInfo:commandJsonData];
        
        [commandDict removeAllObjects];
        commandDict = nil;
        [self.conferenceCommandDelegate acuConferenceAVSwitch:_videoCallAVMode];
    }
}

- (void)viewDidUnload
{
    [self setHudToolbar:nil];
    [self setLocalVideoView:nil];
    [self setLocalVideoViewPinBtn:nil];
    [self setLocalVideoViewSwitchCamBtn:nil];
    [self setLocalVideoViewVideoBtn:nil];
    [self setLocalVideoViewAudioBtn:nil];
    [self setToolbarLayoutBtn:nil];
    [self setToolbarPresenterBtn:nil];
    [self setToolbarSpeakerBtn:nil];
    [self setToolbarExitBtn:nil];
    
    [super viewDidUnload];
}

-(void)dealloc
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self];
}

- (void)setLayout
{
    if(self.videoViewController1)
    {
        self.videoViewController1.view.hidden = YES;
        self.videoViewController1 = nil;
    }
    if(self.videoViewController2)
    {
        self.videoViewController2.view.hidden = YES;
        self.videoViewController2 = nil;
    }
    if(self.videoViewController3)
    {
        self.videoViewController3.view.hidden = YES;
        self.videoViewController3 = nil;
    }
    if(self.videoViewController4)
    {
        self.videoViewController4.view.hidden = YES;
        self.videoViewController4 = nil;
    }
    
    CGRect frame;
    int nViewWidth = self.view.frame.size.width;
    int nViewHight = self.view.frame.size.height;
    
    NSLog(@"view w:%d, h:%d", nViewWidth, nViewHight);
    
    switch (_layoutStatus)
    {
        case AcuConferenceLayoutStatus1Video:
        {
            self.videoViewController1 = [[self storyboard] instantiateViewControllerWithIdentifier:@"AcuVideoView"];
            
//            if (_videoCallAVMode == 1)
//            {
//                self.videoViewController1.view.hidden = YES;
//            }
            
            frame = CGRectMake(0, 0, nViewWidth, nViewHight);

            
            [self addChildViewController:self.videoViewController1];
            self.videoViewController1.view.frame = frame;
            [self.view addSubview:self.videoViewController1.view];
            
            self.videoViewController1.participantLabel.hidden = NO;
            [self.videoViewController1.videoView setupGL:_glContext];
            self.videoViewController1.videoView.presentationRect = CGSizeMake(_videoWidth, _videoHeight);
            
            if (_videoCallMode == 1 && _videoCallAVMode == 1)
            {
                self.videoViewController1.videoView.backgroundColor = [UIColor clearColor];
            }
            
            self.videoViewController1.videoCallMode = _videoCallMode;
            self.videoViewController1.videoCallAVMode = _videoCallAVMode;

            
            break;
        }
            
        case AcuConferenceLayoutStatus2Video:
        {
            self.videoViewController1 = [[self storyboard] instantiateViewControllerWithIdentifier:@"AcuVideoView"];
            self.videoViewController2 = [[self storyboard] instantiateViewControllerWithIdentifier:@"AcuVideoView"];
            
//            if (_videoCallAVMode == 1)
//            {
//                self.videoViewController1.view.hidden = YES;
//                self.videoViewController2.view.hidden = YES;
//            }
            
            frame = CGRectMake(0, 0, nViewWidth/2, nViewHight);
            
            [self addChildViewController:self.videoViewController1];
            self.videoViewController1.view.frame = frame;
            [self.view addSubview:self.videoViewController1.view];
            
            self.videoViewController1.participantLabel.hidden = NO;
            [self.videoViewController1.videoView setupGL:_glContext];
            self.videoViewController1.videoView.presentationRect = CGSizeMake(_videoWidth, _videoHeight);
            
            frame = CGRectMake(nViewWidth/2, 0, nViewWidth/2, nViewHight);
            
            [self addChildViewController:self.videoViewController2];
            self.videoViewController2.view.frame = frame;
            [self.view addSubview:self.videoViewController2.view];
            
            self.videoViewController2.participantLabel.hidden = NO;
            [self.videoViewController2.videoView setupGL:_glContext];
            self.videoViewController2.videoView.presentationRect = CGSizeMake(_videoWidth, _videoHeight);
            break;
        }
            
        case AcuConferenceLayoutStatus4Video:
        {
            self.videoViewController1 = [[self storyboard] instantiateViewControllerWithIdentifier:@"AcuVideoView"];
            self.videoViewController2 = [[self storyboard] instantiateViewControllerWithIdentifier:@"AcuVideoView"];
            self.videoViewController3 = [[self storyboard] instantiateViewControllerWithIdentifier:@"AcuVideoView"];
            self.videoViewController4 = [[self storyboard] instantiateViewControllerWithIdentifier:@"AcuVideoView"];
            
//            if (_videoCallAVMode == 1)
//            {
//                self.videoViewController1.view.hidden = YES;
//                self.videoViewController2.view.hidden = YES;
//                self.videoViewController3.view.hidden = YES;
//                self.videoViewController4.view.hidden = YES;
//            }
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                frame = CGRectMake(0, 0, nViewWidth/2, nViewHight/2);
                
                [self addChildViewController:self.videoViewController1];
                self.videoViewController1.view.frame = frame;
                [self.view addSubview:self.videoViewController1.view];
                
                self.videoViewController1.participantLabel.hidden = NO;
                [self.videoViewController1.videoView setupGL:_glContext];
                self.videoViewController1.videoView.presentationRect = CGSizeMake(_videoWidth, _videoHeight);
                
                frame = CGRectMake(nViewWidth/2, 0, nViewWidth/2, nViewHight/2);
                
                [self addChildViewController:self.videoViewController2];
                self.videoViewController2.view.frame = frame;
                [self.view addSubview:self.videoViewController2.view];
                
                self.videoViewController2.participantLabel.hidden = NO;
                [self.videoViewController2.videoView setupGL:_glContext];
                self.videoViewController2.videoView.presentationRect = CGSizeMake(_videoWidth, _videoHeight);
                
                frame = CGRectMake(0, nViewHight/2, nViewWidth/2, nViewHight/2);
                
                [self addChildViewController:self.videoViewController3];
                self.videoViewController3.view.frame = frame;
                [self.view addSubview:self.videoViewController3.view];
                
                self.videoViewController3.participantLabel.hidden = NO;
                [self.videoViewController3.videoView setupGL:_glContext];
                self.videoViewController3.videoView.presentationRect = CGSizeMake(_videoWidth, _videoHeight);
                
                
                frame = CGRectMake(nViewWidth/2, nViewHight/2, nViewWidth/2, nViewHight/2);
                
                [self addChildViewController:self.videoViewController4];
                self.videoViewController4.view.frame = frame;
                [self.view addSubview:self.videoViewController4.view];
                
                self.videoViewController4.participantLabel.hidden = NO;
                [self.videoViewController4.videoView setupGL:_glContext];
                self.videoViewController4.videoView.presentationRect = CGSizeMake(_videoWidth, _videoHeight);
                
            }
            else
            {
                int nNewWidth = 0;
                int nNewHeight = 0;
                bool bUseHeight = false;
                if (nViewHight > nViewWidth)
                {
                    bUseHeight = true;
                    nNewHeight = nViewWidth*1.0/0.75;
                    if (nNewHeight%2 != 0)
                    {
                        nNewHeight += 1;
                    }
                }
                else
                {
                    nNewWidth = nViewHight/0.75;
                    if (nNewWidth%2 != 0)
                    {
                        nNewWidth += 1;
                    }
                }
                
                CGRect newFrame;
                if (bUseHeight)
                {
                    newFrame = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(nViewWidth, nNewHeight), self.view.bounds);
                }
                else
                {
                    newFrame = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(nNewWidth, nViewHight), self.view.bounds);
                }
                
                NSLog(@"new Frame: x:%f, y:%f, w:%f, h:%f", newFrame.origin.x, newFrame.origin.y, newFrame.size.width, newFrame.size.height);
                
                
                nViewWidth = newFrame.size.width;
                nViewHight = newFrame.size.height;
                
                frame = CGRectMake(newFrame.origin.x, newFrame.origin.y, nViewWidth/2, nViewHight/2);
                
                [self addChildViewController:self.videoViewController1];
                self.videoViewController1.view.frame = frame;
                [self.view addSubview:self.videoViewController1.view];
                
                self.videoViewController1.participantLabel.hidden = NO;
                [self.videoViewController1.videoView setupGL:_glContext];
                self.videoViewController1.videoView.presentationRect = CGSizeMake(_videoWidth, _videoHeight);
                
                frame = CGRectMake(nViewWidth/2+newFrame.origin.x, 0, nViewWidth/2, nViewHight/2);
                
                [self addChildViewController:self.videoViewController2];
                self.videoViewController2.view.frame = frame;
                [self.view addSubview:self.videoViewController2.view];
                
                self.videoViewController2.participantLabel.hidden = NO;
                [self.videoViewController2.videoView setupGL:_glContext];
                self.videoViewController2.videoView.presentationRect = CGSizeMake(_videoWidth, _videoHeight);
                
                frame = CGRectMake(newFrame.origin.x, newFrame.origin.y+nViewHight/2, nViewWidth/2, nViewHight/2);
                
                [self addChildViewController:self.videoViewController3];
                self.videoViewController3.view.frame = frame;
                [self.view addSubview:self.videoViewController3.view];
                
                self.videoViewController3.participantLabel.hidden = NO;
                [self.videoViewController3.videoView setupGL:_glContext];
                self.videoViewController3.videoView.presentationRect = CGSizeMake(_videoWidth, _videoHeight);
                
                
                frame = CGRectMake(newFrame.origin.x+nViewWidth/2, newFrame.origin.y+nViewHight/2, nViewWidth/2, nViewHight/2);
                
                [self addChildViewController:self.videoViewController4];
                self.videoViewController4.view.frame = frame;
                [self.view addSubview:self.videoViewController4.view];
                
                self.videoViewController4.participantLabel.hidden = NO;
                [self.videoViewController4.videoView setupGL:_glContext];
                self.videoViewController4.videoView.presentationRect = CGSizeMake(_videoWidth, _videoHeight);
                
            }
            
            
            break;
        }
            
        case AcuConferenceLayoutStatus0SVideo:
        {
            self.videoViewController1 = [[self storyboard] instantiateViewControllerWithIdentifier:@"AcuVideoView"];
            
//            if (_videoCallAVMode == 1)
//            {
//                self.videoViewController1.view.hidden = YES;
//            }
            
            frame = CGRectMake(0, 0, nViewWidth, nViewHight);
            
            [self addChildViewController:self.videoViewController1];
            self.videoViewController1.view.frame = frame;
            [self.view addSubview:self.videoViewController1.view];
            
            self.videoViewController1.participantLabel.hidden = NO;
            [self.videoViewController1.videoView setupGL:_glContext];
            self.videoViewController1.videoView.presentationRect = CGSizeMake(_videoWidth, _videoHeight);
            break;
        }
            
        case AcuConferenceLayoutStatus1SVideo:
        {
            /*  1. video width is nViewWidth * 1/3
             2. video height is nViewHieght
             3. slide width is nViewWidth * 2/3
             4. sidee height is nViewHeight
             */
            self.videoViewController1 = [[self storyboard] instantiateViewControllerWithIdentifier:@"AcuVideoView"];
            self.videoViewController2 = [[self storyboard] instantiateViewControllerWithIdentifier:@"AcuVideoView"];
            
//            if (_videoCallAVMode == 1)
//            {
//                self.videoViewController1.view.hidden = YES;
//                self.videoViewController2.view.hidden = YES;
//            }
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                frame = CGRectMake(0, 0, 320, nViewHight/2);
            }
            else
            {
                frame = CGRectMake(0, 0, 160, nViewHight/2);
            }
            
            frame.origin.x = 0;
            frame.origin.y = 0;
            frame.size.width = nViewWidth/3;
            frame.size.height = nViewHight;
            
            
            [self addChildViewController:self.videoViewController1];
            self.videoViewController1.view.frame = frame;
            [self.view addSubview:self.videoViewController1.view];
            
            self.videoViewController1.participantLabel.hidden = NO;
            [self.videoViewController1.videoView setupGL:_glContext];
            self.videoViewController1.videoView.presentationRect = CGSizeMake(_videoWidth, _videoHeight);
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                frame = CGRectMake(320, 0, nViewWidth-320, nViewHight);
            }
            else
            {
                frame = CGRectMake(160, 0, nViewWidth-160, nViewHight);
            }
            frame.origin.x = nViewWidth/3;
            frame.origin.y = 0;
            frame.size.width = nViewWidth/3*2;
            frame.size.height = nViewHight;
            
            [self addChildViewController:self.videoViewController2];
            self.videoViewController2.view.frame = frame;
            [self.view addSubview:self.videoViewController2.view];
            
            self.videoViewController2.participantLabel.hidden = NO;
            [self.videoViewController2.videoView setupGL:_glContext];
            self.videoViewController2.videoView.presentationRect = CGSizeMake(_videoWidth, _videoHeight);
            
            break;
        }
            
        case AcuConferenceLayoutStatus2SVideo:
        {
            /*  1. video width is nViewWidth * 1/3
             2. video height is nViewWidth * 1/4
             3. slide width is nViewWidth * 2/3
             4. sidee height is nViewHeight
             5. so we should blank height before video1 : (nViewHeight - (nViewWidth/4 + nViewWidth/4))/2
             */
            self.videoViewController1 = [[self storyboard] instantiateViewControllerWithIdentifier:@"AcuVideoView"];
            self.videoViewController2 = [[self storyboard] instantiateViewControllerWithIdentifier:@"AcuVideoView"];
            self.videoViewController3 = [[self storyboard] instantiateViewControllerWithIdentifier:@"AcuVideoView"];
            
//            if (_videoCallAVMode == 1)
//            {
//                self.videoViewController1.view.hidden = YES;
//                self.videoViewController2.view.hidden = YES;
//                self.videoViewController3.view.hidden = YES;
//            }
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                frame = CGRectMake(0, 0, 320, nViewHight/2);
            }
            else
            {
                frame = CGRectMake(0, 0, 160, nViewHight/2);
            }
            
            frame.origin.x = 0;
            frame.origin.y = (nViewHight - nViewWidth/2)/2;
            frame.size.width = nViewWidth/3;
            frame.size.height = nViewWidth/4;
            
            
            [self addChildViewController:self.videoViewController1];
            self.videoViewController1.view.frame = frame;
            [self.view addSubview:self.videoViewController1.view];
            
            self.videoViewController1.participantLabel.hidden = NO;
            [self.videoViewController1.videoView setupGL:_glContext];
            self.videoViewController1.videoView.presentationRect = CGSizeMake(_videoWidth, _videoHeight);
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                frame = CGRectMake(0, nViewHight/2, 320, nViewHight/2);
            }
            else
            {
                frame = CGRectMake(0, nViewHight/2, 160, nViewHight/2);
            }
            
            frame.origin.x = 0;
            frame.origin.y = ((nViewHight - nViewWidth/2)/2)+nViewWidth/4;
            frame.size.width = nViewWidth/3;
            frame.size.height = nViewWidth/4;
            
            
            [self addChildViewController:self.videoViewController2];
            self.videoViewController2.view.frame = frame;
            [self.view addSubview:self.videoViewController2.view];
            
            self.videoViewController2.participantLabel.hidden = NO;
            [self.videoViewController2.videoView setupGL:_glContext];
            self.videoViewController2.videoView.presentationRect = CGSizeMake(_videoWidth, _videoHeight);
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                frame = CGRectMake(320, 0, nViewWidth - 320, nViewHight);
            }
            else
            {
                frame = CGRectMake(160, 0, nViewWidth - 160, nViewHight);
            }
            
            frame.origin.x = nViewWidth/3;
            frame.origin.y = 0;
            frame.size.width = nViewWidth/3*2;
            frame.size.height = nViewHight;
            
            
            [self addChildViewController:self.videoViewController3];
            self.videoViewController3.view.frame = frame;
            [self.view addSubview:self.videoViewController3.view];
            
            self.videoViewController3.participantLabel.hidden = NO;
            [self.videoViewController3.videoView setupGL:_glContext];
            self.videoViewController3.videoView.presentationRect = CGSizeMake(_videoWidth, _videoHeight);
            
            break;
        }
            
        default:
            break;
    }
    
    [self.view bringSubviewToFront:self.localVideoView];
    
    if (_videoCallMode == 1)
    {
        [self.view bringSubviewToFront:self.videoCallToolbar];
    }
    else
    {
        [self.view bringSubviewToFront:self.hudToolbar];
    }
    
    [self.view bringSubviewToFront:self.indicatorToolbar];
    
    //	[self.view bringSubviewToFront:self.audioIndicator];
    //	[self.view bringSubviewToFront:self.videoIndicator];
    //	[self.view bringSubviewToFront:self.chatMsgIndicator];
    //	[self.view bringSubviewToFront:self.networkIndicator];
    
    
}


- (void)exitConference:(AcuConferenceEndStatus)exitStatus
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    if (exitStatus == AcuConferenceEndStatusForceTerminal)
    {
        if (ACU_COM_IOS8)
        {
            if(_hostEndConferenceAlertController ||
               _participantEndConferenceAlertController ||
               _participantEndConferenceAlertController ||
               _endConferenceAlertController ||
               _invitedPresentAlertController ||
               _invitedSpeakerAlertController)
            {
                [self dismissViewControllerAnimated:NO completion:nil];
            }
        }
        else
        {
            if (_hostEndConferenceAlertView)
            {
                [_hostEndConferenceAlertView dismissWithClickedButtonIndex:0 animated:YES];
            }
            
            if (_participantEndConferenceAlertView)
            {
                [_participantEndConferenceAlertView dismissWithClickedButtonIndex:1 animated:YES];
            }
            
            if (_endConferenceAlertView)
            {
                [_endConferenceAlertView dismissWithClickedButtonIndex:0 animated:YES];
            }
            
            if (_invitedPresentAlertView)
            {
                [_invitedPresentAlertView dismissWithClickedButtonIndex:1 animated:YES];
            }
            
            if (_invitedSpeakerAlertView)
            {
                [_invitedSpeakerAlertView dismissWithClickedButtonIndex:1 animated:YES];
            }
        }
    }
    _needDeallocResource = NO;
    _bMuteLocalVideo = YES;
    _bSpeaker = NO;
    [_audioManager setMute:YES];
    
    _bStillGotVideoData = NO;
    
    if (_localVideoTimer)
    {
        [_localVideoTimer invalidate];
        _localVideoTimer = nil;
    }
    
    if (_remoteVideoTimer)
    {
        [_remoteVideoTimer invalidate];
        _remoteVideoTimer = nil;
    }
    
    [_videoCapture stopCapture];
    [_audioManager stopAudioManager];
    
#if ACU_IOS_SAVE_AUDIO_CAPTURE_DATA
    [_audioCaptureDataFileHandler closeFile];
#endif
    
#if ACU_IOS_SAVE_AUDIO_PLAYBACK_DATA
    [_audioPlaybackDataFileHandler closeFile];
#endif
    
    
    _videoCapture = nil;
    _audioManager = nil;
    
    if (_hudToolbarTimer)
    {
        [_hudToolbarTimer invalidate];
        _hudToolbarTimer = nil;
    }
    
    _layoutModePop.delegate = nil;
    _layoutModePop.datasource = nil;
    _layoutModePop = nil;
    
    [_videoFrameMutex lock];
    if (_videoFrame1)
    {
        _videoFrame1 = nil;
    }
    
    if (_videoFrame2)
    {
        _videoFrame2 = nil;
    }
    
    if (_videoFrame3)
    {
        _videoFrame3 = nil;
    }
    
    if (_videoFrame4)
    {
        _videoFrame4 = nil;
    }
    
    if(self.videoViewController1)
    {
        self.videoViewController1.view.hidden = YES;
    }
    if(self.videoViewController2)
    {
        self.videoViewController2.view.hidden = YES;
    }
    if(self.videoViewController3)
    {
        self.videoViewController3.view.hidden = YES;
    }
    if(self.videoViewController4)
    {
        self.videoViewController4.view.hidden = YES;
    }
    self.videoViewController1 = nil;
    self.videoViewController2 = nil;
    self.videoViewController3 = nil;
    self.videoViewController4 = nil;
    [_videoFrameMutex unlock];
    _videoFrameMutex = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.conferenceDelegate/* && exitStatus != AcuConferenceEndStatusForceTerminal*/)
        {
            [self.conferenceDelegate acuConferencePresentingViewController:self didEnd:exitStatus];
        }
    });
}

- (void)getRemoteVideoData:(NSTimer*)theTimer
{
#if 0
    if (_videoCallAVMode == 1)
        return;
#endif
    
    if (!_bStillGotVideoData)
    {
        return;
    }
    [_videoFrameMutex lock];
    
    bool bGotVideoData = false;
    unsigned char   *pVideoData = 0;
    int nVideoDataLen;
    int nVideoBufferSize;
    int nVideoWidth;
    int nVideoHeight;
    int nVideoColorSpace;
    int nVideoUserID = 0;
    switch (_layoutStatus)
    {
        case AcuConferenceLayoutStatus1Video:
        {
            if (self.conferenceSessionController)
            {
                nVideoUserID = 0;
                bGotVideoData = [self.conferenceSessionController getRemoteVideo:0
                                                                 remoteVideoData:&pVideoData
                                                           remoteVideoDataLength:&nVideoDataLen
                                                           remoteVideoBufferSize:&nVideoBufferSize
                                                                remoteVideoWidth:&nVideoWidth
                                                               remoteVideoHeight:&nVideoHeight
                                                           remoteVideoColorSpace:&nVideoColorSpace
                                                               remoteVideoUserID:&nVideoUserID];
                if (bGotVideoData)
                {
                    if (_videoCallAVMode == 0)
                    {
                        [_videoFrame1 setVideoData:pVideoData
                                        withLenght:nVideoDataLen
                                   videoColorSpace:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                                        videoWidth:nVideoWidth
                                       videoHeight:nVideoHeight];
                        self.videoViewController1.videoView.presentationRect = CGSizeMake(nVideoWidth, nVideoHeight);
                        [self.videoViewController1.videoView displayPixelBuffer:_videoFrame1->_videoFrame];
                    }
                    
                    
                    [self.videoViewController1 setParticipantName:[self getUserNameByID:nVideoUserID]];
                    
                    [self.conferenceSessionController freeRemoteVideoData:pVideoData
                                                    remoteVideoBufferSize:nVideoBufferSize];
                    pVideoData = 0;
                }
                
                if (nVideoUserID > 0 && nVideoUserID == _activeSpeakerID)
                {
                    [self.videoViewController1 setAcitveSpeaker:YES];
                }
                
            }
            break;
        }
            
        case AcuConferenceLayoutStatus2Video:
        {
            if (self.conferenceSessionController)
            {
                nVideoUserID = 0;
                bGotVideoData = [self.conferenceSessionController getRemoteVideo:0
                                                                 remoteVideoData:&pVideoData
                                                           remoteVideoDataLength:&nVideoDataLen
                                                           remoteVideoBufferSize:&nVideoBufferSize
                                                                remoteVideoWidth:&nVideoWidth
                                                               remoteVideoHeight:&nVideoHeight
                                                           remoteVideoColorSpace:&nVideoColorSpace
                                                               remoteVideoUserID:&nVideoUserID];
                
                if (bGotVideoData)
                {
                    if (_videoCallAVMode == 0)
                    {
                        [_videoFrame1 setVideoData:pVideoData
                                        withLenght:nVideoDataLen
                                   videoColorSpace:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                                        videoWidth:nVideoWidth
                                       videoHeight:nVideoHeight];
                        self.videoViewController1.videoView.presentationRect = CGSizeMake(nVideoWidth, nVideoHeight);
                        [self.videoViewController1.videoView displayPixelBuffer:_videoFrame1->_videoFrame];
                    }
                    
                    [self.videoViewController1 setParticipantName:[self getUserNameByID:nVideoUserID]];
                    
                    [self.conferenceSessionController freeRemoteVideoData:pVideoData
                                                    remoteVideoBufferSize:nVideoBufferSize];
                    pVideoData = 0;
                }
                
                if (nVideoUserID > 0 && nVideoUserID == _activeSpeakerID)
                {
                    [self.videoViewController2 setAcitveSpeaker:NO];
                    [self.videoViewController1 setAcitveSpeaker:YES];
                }
                
                nVideoUserID = 0;
                bGotVideoData = [self.conferenceSessionController getRemoteVideo:1
                                                                 remoteVideoData:&pVideoData
                                                           remoteVideoDataLength:&nVideoDataLen
                                                           remoteVideoBufferSize:&nVideoBufferSize
                                                                remoteVideoWidth:&nVideoWidth
                                                               remoteVideoHeight:&nVideoHeight
                                                           remoteVideoColorSpace:&nVideoColorSpace
                                                               remoteVideoUserID:&nVideoUserID];
                
                if (bGotVideoData)
                {
                    if (_videoCallAVMode == 0)
                    {
                        [_videoFrame2 setVideoData:pVideoData
                                        withLenght:nVideoDataLen
                                   videoColorSpace:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                                        videoWidth:nVideoWidth
                                       videoHeight:nVideoHeight];
                        self.videoViewController2.videoView.presentationRect = CGSizeMake(nVideoWidth, nVideoHeight);
                        [self.videoViewController2.videoView displayPixelBuffer:_videoFrame2->_videoFrame];
                    }
                    [self.videoViewController2 setParticipantName:[self getUserNameByID:nVideoUserID]];
                    
                    [self.conferenceSessionController freeRemoteVideoData:pVideoData
                                                    remoteVideoBufferSize:nVideoBufferSize];
                    pVideoData = 0;
                }
                
                if (nVideoUserID > 0 && nVideoUserID == _activeSpeakerID)
                {
                    [self.videoViewController1 setAcitveSpeaker:NO];
                    [self.videoViewController2 setAcitveSpeaker:YES];
                }
            }
            break;
        }
            
        case AcuConferenceLayoutStatus4Video:
        {
            if (self.conferenceSessionController)
            {
                nVideoUserID = 0;
                bGotVideoData = [self.conferenceSessionController getRemoteVideo:0
                                                                 remoteVideoData:&pVideoData
                                                           remoteVideoDataLength:&nVideoDataLen
                                                           remoteVideoBufferSize:&nVideoBufferSize
                                                                remoteVideoWidth:&nVideoWidth
                                                               remoteVideoHeight:&nVideoHeight
                                                           remoteVideoColorSpace:&nVideoColorSpace
                                                               remoteVideoUserID:&nVideoUserID];
                if (bGotVideoData)
                {
                    if (_videoCallAVMode == 0)
                    {
                        [_videoFrame1 setVideoData:pVideoData
                                        withLenght:nVideoDataLen
                                   videoColorSpace:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                                        videoWidth:nVideoWidth
                                       videoHeight:nVideoHeight];
                        self.videoViewController1.videoView.presentationRect = CGSizeMake(nVideoWidth, nVideoHeight);
                        [self.videoViewController1.videoView displayPixelBuffer:_videoFrame1->_videoFrame];
                    }
                    [self.videoViewController1 setParticipantName:[self getUserNameByID:nVideoUserID]];
                    
                    [self.conferenceSessionController freeRemoteVideoData:pVideoData
                                                    remoteVideoBufferSize:nVideoBufferSize];
                    pVideoData = 0;
                }
                
                if (nVideoUserID > 0 && nVideoUserID == _activeSpeakerID)
                {
                    [self.videoViewController2 setAcitveSpeaker:NO];
                    [self.videoViewController3 setAcitveSpeaker:NO];
                    [self.videoViewController4 setAcitveSpeaker:NO];
                    [self.videoViewController1 setAcitveSpeaker:YES];
                }
                
                nVideoUserID = 0;
                bGotVideoData = [self.conferenceSessionController getRemoteVideo:1
                                                                 remoteVideoData:&pVideoData
                                                           remoteVideoDataLength:&nVideoDataLen
                                                           remoteVideoBufferSize:&nVideoBufferSize
                                                                remoteVideoWidth:&nVideoWidth
                                                               remoteVideoHeight:&nVideoHeight
                                                           remoteVideoColorSpace:&nVideoColorSpace
                                                               remoteVideoUserID:&nVideoUserID];
                if (bGotVideoData)
                {
                    if (_videoCallAVMode == 0)
                    {
                        [_videoFrame2 setVideoData:pVideoData
                                        withLenght:nVideoDataLen
                                   videoColorSpace:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                                        videoWidth:nVideoWidth
                                       videoHeight:nVideoHeight];
                        self.videoViewController2.videoView.presentationRect = CGSizeMake(nVideoWidth, nVideoHeight);
                        [self.videoViewController2.videoView displayPixelBuffer:_videoFrame2->_videoFrame];
                    }
                    [self.videoViewController2 setParticipantName:[self getUserNameByID:nVideoUserID]];
                    
                    [self.conferenceSessionController freeRemoteVideoData:pVideoData
                                                    remoteVideoBufferSize:nVideoBufferSize];
                    pVideoData = 0;
                }
                
                if (nVideoUserID > 0 && nVideoUserID == _activeSpeakerID)
                {
                    [self.videoViewController1 setAcitveSpeaker:NO];
                    [self.videoViewController3 setAcitveSpeaker:NO];
                    [self.videoViewController4 setAcitveSpeaker:NO];
                    [self.videoViewController2 setAcitveSpeaker:YES];
                }
                
                nVideoUserID = 0;
                bGotVideoData = [self.conferenceSessionController getRemoteVideo:2
                                                                 remoteVideoData:&pVideoData
                                                           remoteVideoDataLength:&nVideoDataLen
                                                           remoteVideoBufferSize:&nVideoBufferSize
                                                                remoteVideoWidth:&nVideoWidth
                                                               remoteVideoHeight:&nVideoHeight
                                                           remoteVideoColorSpace:&nVideoColorSpace
                                                               remoteVideoUserID:&nVideoUserID];
                if (bGotVideoData)
                {
                    if (_videoCallAVMode == 0)
                    {
                        [_videoFrame3 setVideoData:pVideoData
                                        withLenght:nVideoDataLen
                                   videoColorSpace:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                                        videoWidth:nVideoWidth
                                       videoHeight:nVideoHeight];
                        self.videoViewController3.videoView.presentationRect = CGSizeMake(nVideoWidth, nVideoHeight);
                        [self.videoViewController3.videoView displayPixelBuffer:_videoFrame3->_videoFrame];
                    }
                    [self.videoViewController3 setParticipantName:[self getUserNameByID:nVideoUserID]];
                    
                    [self.conferenceSessionController freeRemoteVideoData:pVideoData
                                                    remoteVideoBufferSize:nVideoBufferSize];
                    pVideoData = 0;
                }
                
                if (nVideoUserID > 0 && nVideoUserID == _activeSpeakerID)
                {
                    [self.videoViewController1 setAcitveSpeaker:NO];
                    [self.videoViewController2 setAcitveSpeaker:NO];
                    [self.videoViewController4 setAcitveSpeaker:NO];
                    [self.videoViewController3 setAcitveSpeaker:YES];
                }
                
                nVideoUserID = 0;
                bGotVideoData = [self.conferenceSessionController getRemoteVideo:3
                                                                 remoteVideoData:&pVideoData
                                                           remoteVideoDataLength:&nVideoDataLen
                                                           remoteVideoBufferSize:&nVideoBufferSize
                                                                remoteVideoWidth:&nVideoWidth
                                                               remoteVideoHeight:&nVideoHeight
                                                           remoteVideoColorSpace:&nVideoColorSpace
                                                               remoteVideoUserID:&nVideoUserID];
                if (bGotVideoData)
                {
                    if (_videoCallAVMode == 0)
                    {
                        [_videoFrame4 setVideoData:pVideoData
                                        withLenght:nVideoDataLen
                                   videoColorSpace:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                                        videoWidth:nVideoWidth
                                       videoHeight:nVideoHeight];
                        self.videoViewController4.videoView.presentationRect = CGSizeMake(nVideoWidth, nVideoHeight);
                        [self.videoViewController4.videoView displayPixelBuffer:_videoFrame4->_videoFrame];
                    }
                    [self.videoViewController4 setParticipantName:[self getUserNameByID:nVideoUserID]];
                    
                    [self.conferenceSessionController freeRemoteVideoData:pVideoData
                                                    remoteVideoBufferSize:nVideoBufferSize];
                    pVideoData = 0;
                }
                
                if (nVideoUserID > 0 && nVideoUserID == _activeSpeakerID)
                {
                    [self.videoViewController1 setAcitveSpeaker:NO];
                    [self.videoViewController2 setAcitveSpeaker:NO];
                    [self.videoViewController3 setAcitveSpeaker:NO];
                    [self.videoViewController4 setAcitveSpeaker:YES];
                }
            }
            break;
        }
            
        case AcuConferenceLayoutStatus0SVideo:
        {
            if (self.conferenceSessionController)
            {
                nVideoUserID = 0;
                bGotVideoData = [self.conferenceSessionController getRemoteVideo:0
                                                                 remoteVideoData:&pVideoData
                                                           remoteVideoDataLength:&nVideoDataLen
                                                           remoteVideoBufferSize:&nVideoBufferSize
                                                                remoteVideoWidth:&nVideoWidth
                                                               remoteVideoHeight:&nVideoHeight
                                                           remoteVideoColorSpace:&nVideoColorSpace
                                                               remoteVideoUserID:&nVideoUserID];
                if (bGotVideoData)
                {
                    if (_videoCallAVMode == 0)
                    {
                        [_videoFrame1 setVideoData:pVideoData
                                        withLenght:nVideoDataLen
                                   videoColorSpace:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                                        videoWidth:nVideoWidth
                                       videoHeight:nVideoHeight];
                        self.videoViewController1.videoView.presentationRect = CGSizeMake(nVideoWidth, nVideoHeight);
                        [self.videoViewController1.videoView displayPixelBuffer:_videoFrame1->_videoFrame];
                    }
                    [self.videoViewController1 setParticipantName:[self getUserNameByID:nVideoUserID]];
                    
                    [self.conferenceSessionController freeRemoteVideoData:pVideoData
                                                    remoteVideoBufferSize:nVideoBufferSize];
                    pVideoData = 0;
                }
            }
            break;
        }
            
        case AcuConferenceLayoutStatus1SVideo:
        {
            if (self.conferenceSessionController)
            {
                nVideoUserID = 0;
                bGotVideoData = [self.conferenceSessionController getRemoteVideo:0
                                                                 remoteVideoData:&pVideoData
                                                           remoteVideoDataLength:&nVideoDataLen
                                                           remoteVideoBufferSize:&nVideoBufferSize
                                                                remoteVideoWidth:&nVideoWidth
                                                               remoteVideoHeight:&nVideoHeight
                                                           remoteVideoColorSpace:&nVideoColorSpace
                                                               remoteVideoUserID:&nVideoUserID];
                if (bGotVideoData)
                {
                    if (_videoCallAVMode == 0)
                    {
                        [_videoFrame1 setVideoData:pVideoData
                                        withLenght:nVideoDataLen
                                   videoColorSpace:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                                        videoWidth:nVideoWidth
                                       videoHeight:nVideoHeight];
                        self.videoViewController1.videoView.presentationRect = CGSizeMake(nVideoWidth, nVideoHeight);
                        [self.videoViewController1.videoView displayPixelBuffer:_videoFrame1->_videoFrame];
                    }
                    [self.videoViewController1 setParticipantName:[self getUserNameByID:nVideoUserID]];
                    
                    [self.conferenceSessionController freeRemoteVideoData:pVideoData
                                                    remoteVideoBufferSize:nVideoBufferSize];
                    pVideoData = 0;
                    
                }
                
                if (nVideoUserID > 0 && nVideoUserID == _activeSpeakerID)
                {
                    [self.videoViewController1 setAcitveSpeaker:YES];
                }
                
                nVideoUserID = 0;
                bGotVideoData = [self.conferenceSessionController getRemoteVideo:1
                                                                 remoteVideoData:&pVideoData
                                                           remoteVideoDataLength:&nVideoDataLen
                                                           remoteVideoBufferSize:&nVideoBufferSize
                                                                remoteVideoWidth:&nVideoWidth
                                                               remoteVideoHeight:&nVideoHeight
                                                           remoteVideoColorSpace:&nVideoColorSpace
                                                               remoteVideoUserID:&nVideoUserID];
                if (bGotVideoData)
                {
                    if (_videoCallAVMode == 0)
                    {
                        [_videoFrame2 setVideoData:pVideoData
                                        withLenght:nVideoDataLen
                                   videoColorSpace:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                                        videoWidth:nVideoWidth
                                       videoHeight:nVideoHeight];
                        self.videoViewController2.videoView.presentationRect = CGSizeMake(nVideoWidth, nVideoHeight);
                        [self.videoViewController2.videoView displayPixelBuffer:_videoFrame2->_videoFrame];
                    }
                    
                    [self.conferenceSessionController freeRemoteVideoData:pVideoData
                                                    remoteVideoBufferSize:nVideoBufferSize];
                    pVideoData = 0;
                    
                }
            }
            break;
        }
            
        case AcuConferenceLayoutStatus2SVideo:
        {
            if (self.conferenceSessionController)
            {
                nVideoUserID = 0;
                bGotVideoData = [self.conferenceSessionController getRemoteVideo:0
                                                                 remoteVideoData:&pVideoData
                                                           remoteVideoDataLength:&nVideoDataLen
                                                           remoteVideoBufferSize:&nVideoBufferSize
                                                                remoteVideoWidth:&nVideoWidth
                                                               remoteVideoHeight:&nVideoHeight
                                                           remoteVideoColorSpace:&nVideoColorSpace
                                                               remoteVideoUserID:&nVideoUserID];
                if (bGotVideoData)
                {
                    if (_videoCallAVMode == 0)
                    {
                        [_videoFrame1 setVideoData:pVideoData
                                        withLenght:nVideoDataLen
                                   videoColorSpace:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                                        videoWidth:nVideoWidth
                                       videoHeight:nVideoHeight];
                        self.videoViewController1.videoView.presentationRect = CGSizeMake(nVideoWidth, nVideoHeight);
                        [self.videoViewController1.videoView displayPixelBuffer:_videoFrame1->_videoFrame];
                    }
                    [self.videoViewController1 setParticipantName:[self getUserNameByID:nVideoUserID]];
                    
                    [self.conferenceSessionController freeRemoteVideoData:pVideoData
                                                    remoteVideoBufferSize:nVideoBufferSize];
                    pVideoData = 0;
                }
                
                if (nVideoUserID > 0 && nVideoUserID == _activeSpeakerID)
                {
                    [self.videoViewController2 setAcitveSpeaker:NO];
                    [self.videoViewController1 setAcitveSpeaker:YES];
                }
                
                nVideoUserID = 0;
                bGotVideoData = [self.conferenceSessionController getRemoteVideo:1
                                                                 remoteVideoData:&pVideoData
                                                           remoteVideoDataLength:&nVideoDataLen
                                                           remoteVideoBufferSize:&nVideoBufferSize
                                                                remoteVideoWidth:&nVideoWidth
                                                               remoteVideoHeight:&nVideoHeight
                                                           remoteVideoColorSpace:&nVideoColorSpace
                                                               remoteVideoUserID:&nVideoUserID];
                if (bGotVideoData)
                {
                    if (_videoCallAVMode == 0)
                    {
                        [_videoFrame2 setVideoData:pVideoData
                                        withLenght:nVideoDataLen
                                   videoColorSpace:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                                        videoWidth:nVideoWidth
                                       videoHeight:nVideoHeight];
                        self.videoViewController2.videoView.presentationRect = CGSizeMake(nVideoWidth, nVideoHeight);
                        [self.videoViewController2.videoView displayPixelBuffer:_videoFrame2->_videoFrame];
                    }
                    [self.videoViewController2 setParticipantName:[self getUserNameByID:nVideoUserID]];
                    
                    [self.conferenceSessionController freeRemoteVideoData:pVideoData
                                                    remoteVideoBufferSize:nVideoBufferSize];
                    pVideoData = 0;
                }
                
                if (nVideoUserID > 0 && nVideoUserID == _activeSpeakerID)
                {
                    [self.videoViewController1 setAcitveSpeaker:NO];
                    [self.videoViewController2 setAcitveSpeaker:YES];
                }
                
                nVideoUserID = 0;
                bGotVideoData = [self.conferenceSessionController getRemoteVideo:2
                                                                 remoteVideoData:&pVideoData
                                                           remoteVideoDataLength:&nVideoDataLen
                                                           remoteVideoBufferSize:&nVideoBufferSize
                                                                remoteVideoWidth:&nVideoWidth
                                                               remoteVideoHeight:&nVideoHeight
                                                           remoteVideoColorSpace:&nVideoColorSpace
                                                               remoteVideoUserID:&nVideoUserID];
                if (bGotVideoData)
                {
                    if (_videoCallAVMode == 0)
                    {
                        [_videoFrame3 setVideoData:pVideoData
                                        withLenght:nVideoDataLen
                                   videoColorSpace:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                                        videoWidth:nVideoWidth
                                       videoHeight:nVideoHeight];
                        self.videoViewController3.videoView.presentationRect = CGSizeMake(nVideoWidth, nVideoHeight);
                        [self.videoViewController3.videoView displayPixelBuffer:_videoFrame3->_videoFrame];
                    }
                    
                    [self.conferenceSessionController freeRemoteVideoData:pVideoData
                                                    remoteVideoBufferSize:nVideoBufferSize];
                    pVideoData = 0;
                }
            }
            break;
        }
            
        default:
            break;
            
    }
    
    [_videoFrameMutex unlock];
}

- (void)getLocalVideoData:(NSTimer*)theTimer
{
    if (_videoCallAVMode == 1)
        return;
    
    if (!_bStillGotVideoData)
    {
        return;
    }
    
    char *pVideoData = 0;
    int nVideoDataLen = 0;
    [_videoCapture gotVideoData:pVideoData withLength:nVideoDataLen];
    
    if (_bMuteLocalVideo /*|| !_bSpeaker*/)
    {
        return;
    }
    
    [_videoCapture captureWidth:&_videoWidth Height:&_videoHeight];
    
    if (self.conferenceSessionController)
    {
        [self.conferenceSessionController setCaptureVideoData:pVideoData
                                          captureVideoDataLen:nVideoDataLen
                                            captureVideoWidth:_videoWidth
                                           captureVideoHeight:_videoHeight
                                       captureVideoColorSpace:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange];
    }
}


#pragma mark ----Toolbar timer Handler----

- (void)handleHudToolbarTimer:(NSTimer*)theTimer
{
    if (_videoCallMode == 1)
    {
        if (!self.videoCallToolbar.hidden)
        {
            self.videoCallToolbar.hidden = YES;
        }
    }
    else
    {
        if (!self.hudToolbar.hidden)
        {
            self.hudToolbar.hidden = YES;
        }
    }
    
    if (_videoCallAVMode == 1)
    {
        self.localVideoView.hidden = YES;
    }
    else
    {
        if (!_bLocalVideoViewPin)
        {
            self.localVideoView.hidden = YES;
        }
    }
    
}


#pragma mark ----AcuVideoCaptureOutputDataSampleDelegate----

//- (void)videoCapture:(AcuVideoCapture*)videoCapture OutputSampleData:(char*)data dataLength:(int)length
//{
//
//}

- (void)videoCapture:(AcuVideoCapture*)videoCapture OutputImageBuffer:(CVImageBufferRef)videoFrame
{
    if (_videoCallAVMode == 1)
        return;
    
    int nTempVideoW = 0, nTempVideH = 0;
    
    [_videoCapture captureWidth:&nTempVideoW Height:&nTempVideH];
    if (_localPreviewVideoWidth != nTempVideoW ||
        _localPreviewVideoHeight != nTempVideH)
    {
        _localPreviewVideoWidth = nTempVideoW;
        _localPreviewVideoHeight = nTempVideH;
        
        if(self.localPreviewVideoController)
        {
            self.localPreviewVideoController.view.hidden = YES;
            self.localPreviewVideoController = nil;
        }
        
        self.localPreviewVideoController = [[self storyboard] instantiateViewControllerWithIdentifier:@"AcuVideoView"];
        self.localPreviewVideoController.participantLabel.hidden = YES;
        self.localPreviewVideoController.activeSpeakerIndictor.hidden = YES;
        
        if(_videoCallMode == 1)
        {
            UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
            if (deviceOrientation == UIDeviceOrientationPortrait ||
                deviceOrientation == UIDeviceOrientationPortraitUpsideDown)
            {
                self.localPreviewVideoController.view.frame = CGRectMake(70, 0, 90, 120);
            }
            else if (deviceOrientation == UIDeviceOrientationLandscapeRight ||
                     deviceOrientation == UIDeviceOrientationLandscapeLeft)
            {
                self.localPreviewVideoController.view.frame = CGRectMake(0, 0, 160, 120);
            }
            else
            {
                self.localPreviewVideoController.view.frame = CGRectMake(70, 0, 90, 120);
            }
        }
        else
        {
            self.localPreviewVideoController.view.frame = CGRectMake(0, 0, 160, 120);
        }
        
        [self.localVideoView addSubview:self.localPreviewVideoController.view];
        [self.localPreviewVideoController.videoView setupGL:_glContext];
        self.localPreviewVideoController.videoView.presentationRect = CGSizeMake(_localPreviewVideoWidth, _localPreviewVideoHeight);
    }
    
    [self.localPreviewVideoController.videoView displayPixelBuffer:videoFrame];
}

#pragma mark ----AcuAudioManagerSampleDataDelegate----
- (void)audioManager:(AcuAudioManager*)audioManager playbackSample:(char*)sampleData withLength:(int)audioLength
{
    //memset(sampleData, 0, audioLength);
    if (self.conferenceSessionController)
    {
        [self.conferenceSessionController getPlayAudioData:sampleData
                                          playAudioDataLen:audioLength];
#if ACU_IOS_SAVE_AUDIO_PLAYBACK_DATA
        [_audioPlaybackDataFileHandler seekToEndOfFile];
        [_audioPlaybackDataFileHandler writeData:[NSData dataWithBytes:sampleData
                                                                length:audioLength]];
#endif
    }
}

- (void)audioManager:(AcuAudioManager*)audioManager captureSample:(char*)sampleData withLength:(int)audioLength
{
#if ACU_IOS_SAVE_AUDIO_CAPTURE_DATA
    [_audioCaptureDataFileHandler seekToEndOfFile];
    [_audioCaptureDataFileHandler writeData:[NSData dataWithBytes:sampleData
                                                           length:audioLength]];
#endif
    
    if (self.conferenceSessionController)
    {
        [self.conferenceSessionController setCaptureAudioData:sampleData
                                          captureAudioDataLen:audioLength];
    }
}

#pragma mark - UIPopoverListViewDataSource

- (UITableViewCell *)popoverListView:(UIPopoverListView *)popoverListView
                    cellForIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"cell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:identifier];
    
    int row = (int)indexPath.row;
    
    if ([popoverListView isEqual:_layoutModePop])
    {
        cell.textLabel.text = [_layoutMode objectAtIndex:row];
        
        if (_layoutStatus-1 == row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    
    
    return cell;
}

- (NSInteger)popoverListView:(UIPopoverListView *)popoverListView
       numberOfRowsInSection:(NSInteger)section
{
    if ([popoverListView isEqual:_layoutModePop])
    {
        return [_layoutMode count];
    }
    return 0;
}

#pragma mark - UIPopoverListViewDelegate
- (void)popoverListView:(UIPopoverListView *)popoverListView
     didSelectIndexPath:(NSIndexPath *)indexPath
{
    int row = (int)indexPath.row;
    
    
    int tempLayoutStatus = 0;
    
    if ([popoverListView isEqual:_layoutModePop])
    {
        tempLayoutStatus = row + 1;
    }
    
    [_videoFrameMutex lock];
    if (tempLayoutStatus != _layoutStatus)
    {
        _layoutStatus = (AcuConferenceLayoutStatus)tempLayoutStatus;
        [self setLayout];
    }
    
    if (self.conferenceDelegate)
    {
        //		AcuConferenceLayoutStatus1Video,
        //		AcuConferenceLayoutStatus2Video,
        //		AcuConferenceLayoutStatus4Video,
        //		AcuConferenceLayoutStatus1SVideo,
        //		AcuConferenceLayoutStatus2SVideo,
        AcuLayoutTag nViewID = eNormalView;
        switch (_layoutStatus)
        {
            case AcuConferenceLayoutStatus1Video:
            {
                nViewID = e1VideoView;
                break;
            }
                
            case AcuConferenceLayoutStatus2Video:
            {
                nViewID = e2VideoView;
                break;
            }
                
            case AcuConferenceLayoutStatus4Video:
            {
                nViewID = e4VideoView;
                break;
            }
                
            case AcuConferenceLayoutStatus1SVideo:
            {
                nViewID = eLectureView;
                break;
            }
                
            case AcuConferenceLayoutStatus2SVideo:
            {
                nViewID = eLargeView;
                break;
            }
                
            default:
                break;
        }
        NSMutableDictionary *commandDict = [NSMutableDictionary new];
        [commandDict setValue:[NSNumber numberWithInt:nViewID] forKey:@"view_id"];
        
        
        NSError *error = nil;
        NSData *commandData = [NSJSONSerialization dataWithJSONObject:commandDict
                                                              options:NSJSONWritingPrettyPrinted
                                                                error:&error];
        
        const char *commandJsonData = (const char*)[commandData bytes];
        [self.conferenceCommandDelegate acuConferenceSendCommand:cmd_set_sync_view
                                                        withInfo:commandJsonData];
        
        [commandDict removeAllObjects];
        commandDict = nil;
    }
    
    [_videoFrameMutex unlock];
    
}

- (CGFloat)popoverListView:(UIPopoverListView *)popoverListView
   heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40.0f;
}

#pragma mark ----UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (_hostEndConferenceAlertView == alertView)
    {
        switch (buttonIndex)
        {
            case 0:
            {
                //NSLog(@"host alert, click button 'Cancel'");
                //do nothing
                break;
            }
                
            case 1:
            {
                //NSLog(@"host alert, click button 'Yes'");
                //show participant list and transfer host rights
                [self exitConference:AcuConferenceEndStatusModeratorLeave];
                break;
            }
                
            case 2:
            {
                //NSLog(@"host alert, click button 'No'");
                [self exitConference:AcuConferenceEndStatusModeratorStop];
                break;
            }
                
            default:
                break;
        }
    }
    else if(_participantEndConferenceAlertView == alertView)
    {
        switch (buttonIndex)
        {
            case 0:
            {
                //NSLog(@"participant alert, click button 'Yes'");
                [self exitConference:AcuConferenceEndStatusLeave];
                break;
            }
                
            case 1:
            {
                //NSLog(@"participant alert, click button 'No'");
                break;
            }
                
            default:
                break;
        }
    }
    else if(_endConferenceAlertView == alertView)
    {
        [self exitConference:AcuConferenceEndStatusStopped];
    }
    else if(_invitedPresentAlertView == alertView)
    {
        switch(buttonIndex)
        {
            case 0:
            {
                //NSLog(@"Present Yes to accept!");
                if (self.conferenceDelegate)
                {
                    [self.conferenceCommandDelegate acuConferenceSendCommand:cmd_agree_presenter
                                                                    withInfo:""];
                }
                break;
            }
                
            case 1:
            {
                //NSLog(@"Present Not accept!");
                break;
            }
                
            default:
                break;
        }
        
    }
    else if(_invitedSpeakerAlertView == alertView)
    {
        switch(buttonIndex)
        {
            case 0:
            {
                //NSLog(@"Speaker Yes to accept!");
                if (self.conferenceDelegate)
                {
                    [self.conferenceCommandDelegate acuConferenceSendCommand:cmd_agree_speaker
                                                                    withInfo:""];
                }
                break;
            }
                
            case 1:
            {
                //NSLog(@"Speaker Not accept!");
                break;
            }
                
            default:
                break;
        }
    }
    else if (_acuComIncomingAlertView == alertView)
    {
        switch (buttonIndex)
        {
            case 0:
            {
                //NSLog(@"Click YES Button");
                if (_hostEndConferenceAlertView)
                {
                    [_hostEndConferenceAlertView dismissWithClickedButtonIndex:0 animated:YES];
                }
                
                if (_participantEndConferenceAlertView)
                {
                    [_participantEndConferenceAlertView dismissWithClickedButtonIndex:1 animated:YES];
                }
                
                if (_endConferenceAlertView)
                {
                    [_endConferenceAlertView dismissWithClickedButtonIndex:0 animated:YES];
                }
                
                if (_invitedPresentAlertView)
                {
                    [_invitedPresentAlertView dismissWithClickedButtonIndex:1 animated:YES];
                }
                
                if (_invitedSpeakerAlertView)
                {
                    [_invitedSpeakerAlertView dismissWithClickedButtonIndex:1 animated:YES];
                }
                
                if (_acucomListener)
                {
                    [self exitConference:AcuConferenceEndStatusAcceptAnother];
                    //_acucomListener->conferenceClosed(100, _inComingCallConfig);
                    _acucomListener->conferenceClosed(30, nil);
                }
                break;
            }
                
            case 1:
            {
                //NSLog(@"Click NO Button");
                if (_acucomListener)
                {
                    //_acucomListener->userRejected(_inComingCallConfig);
                }
                break;
            }
                
            case 2:
            {
                
                break;
            }
                
            default:
                break;
        }
    }
    else if (_acuComNotificationAlertView == alertView)
    {
        switch (buttonIndex)
        {
            case 0:
            {
                //NSLog(@"Click OK Button");
                if (_acuComNotificationType == 1)
                {
                    //NSLog(@"Click YES Button");
                    if (_hostEndConferenceAlertView)
                    {
                        [_hostEndConferenceAlertView dismissWithClickedButtonIndex:0 animated:YES];
                    }
                    
                    if (_participantEndConferenceAlertView)
                    {
                        [_participantEndConferenceAlertView dismissWithClickedButtonIndex:1 animated:YES];
                    }
                    
                    if (_endConferenceAlertView)
                    {
                        [_endConferenceAlertView dismissWithClickedButtonIndex:0 animated:YES];
                    }
                    
                    if (_invitedPresentAlertView)
                    {
                        [_invitedPresentAlertView dismissWithClickedButtonIndex:1 animated:YES];
                    }
                    
                    if (_invitedSpeakerAlertView)
                    {
                        [_invitedSpeakerAlertView dismissWithClickedButtonIndex:1 animated:YES];
                    }
                    
                    [self exitConference:AcuConferenceEndStatusUserRejected];
                }
                break;
            }
                
            case 1:
            {
                
                break;
            }
                
            case 2:
            {
                //NSLog(@"Click NO Button");
                break;
            }
                
            default:
                break;
        }
    }
}

#pragma mark ----conference logic----
- (void)initConferenceStatus
{
    [self updateToolbarSpeakerStatus:_bCanSpeaker
                           isSpeaker:_bSpeaker];
    
    [self updateToolbarPresenterStatus:_bSpeaker
                           isPresenter:_bPresenter];
    
    [self updateToolbarLayoutStatus];
    
    [self updateLocalAudioBtnStatus:_bSpeaker
                          localMute:YES];
    
    [self updateLocalVideoBtnStatus:_bSpeaker
                          localMute:YES];
}

- (void)updateParticipantList:(NSMutableArray*)newParticipantList
{
    self.conferenceParticipantList = newParticipantList;
}

- (void)setActiveSpeaker:(int)activeSpeakerID
{
    _activeSpeakerID = activeSpeakerID;
}

- (void)setLayoutStatus:(AcuConferenceLayoutStatus)layoutStatus
{
    if (_layoutStatus == layoutStatus)
    {
        return;
    }
    
    _layoutStatus = layoutStatus;
    
    [self setLayout];
}

//Host
- (void)setModeratorRole:(BOOL)bModerator
{
    _bModerator = bModerator;
}

- (void)setSpeakerRole:(BOOL)bSpeaker
{
    _bWaitingSpeakerStatus = NO;
    _eSpeakerHangingUpStatus = AcuSpeakerHangupStatus_None;
    _bSpeaker = bSpeaker;
    
    [self removeAllActiveSpeaker];
    
    [self updateToolbarSpeakerStatus:_bCanSpeaker
                           isSpeaker:_bSpeaker];
    
    [self updateToolbarPresenterStatus:_bSpeaker
                           isPresenter:_bPresenter];
    
    if (!bSpeaker)
    {
        [self updateToolbarPresenterBtnStatus:0];
    }
    
    
    [self updateToolbarLayoutStatus];
    
    [self updateLocalAudioBtnStatus:_bSpeaker
                          localMute:_bMuteLocalAudio];
    
    [self updateLocalVideoBtnStatus:_bSpeaker
                          localMute:_bMuteLocalVideo];
    
}

- (void)setPresenterRole:(BOOL)bPresenter
{
    _bWaitingPresenterStatus = NO;
    _bPresenter = bPresenter;
    [self updateToolbarPresenterStatus:_bSpeaker
                           isPresenter:_bPresenter];
    
    [self updateToolbarLayoutStatus];
}

- (void)setHangingUp:(BOOL)bHandingUp
{
    _bWaitingSpeakerStatus = NO;
    
    if (_eSpeakerHangingUpStatus == AcuSpeakerHangupStatus_WaitingRequest && bHandingUp)
    {
        _eSpeakerHangingUpStatus = AcuSpeakerHangupStatus_Request;
        [self updateToolbarSpeakerStatus:_bCanSpeaker
                               isSpeaker:YES];
    }
    else if(_eSpeakerHangingUpStatus == AcuSpeakerHangupStatus_WaitingGiveup && !bHandingUp)
    {
        _eSpeakerHangingUpStatus = AcuSpeakerHangupStatus_Giveup;
        [self updateToolbarSpeakerStatus:_bCanSpeaker
                               isSpeaker:NO];
    }
}

- (NSString*)getUserNameByID:(uint16_t)nUserID
{
    NSString *returnString = nil;
    
    for (AcuParticipantInfo *participantInfo in self.conferenceParticipantList)
    {
        if (participantInfo.nId == nUserID)
        {
            returnString = participantInfo.name;
            break;
        }
    }
    
    
    return returnString;
}

- (void)updateToolbarQulityStatus
{
    if (_videoCallMode == 1)
    {
        if (isHDQuality)
        {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                [self.toolbarAcuComVideoQuality setBackgroundImage:[UIImage imageNamed:@"iPad_hdQuality_d.png"] forState:UIControlStateSelected];
            }
            else
            {
                [self.toolbarAcuComVideoQuality setBackgroundImage:[UIImage imageNamed:@"iPhone_hdQuality_d.png"] forState:UIControlStateSelected];
            }
        }
        else
        {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                [self.toolbarAcuComVideoQuality setBackgroundImage:[UIImage imageNamed:@"iPad_sdQuality_d.png"] forState:UIControlStateSelected];
            }
            else
            {
                [self.toolbarAcuComVideoQuality setBackgroundImage:[UIImage imageNamed:@"iPhone_sdQuality_d.png"] forState:UIControlStateSelected];
            }
        }
    }
    else
    {
        if (isHDQuality)
        {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                [self.toolbarQualityBtn setBackgroundImage:[UIImage imageNamed:@"iPad_hdQuality_d.png"] forState:UIControlStateSelected];
            }
            else
            {
                [self.toolbarQualityBtn setBackgroundImage:[UIImage imageNamed:@"iPhone_hdQuality_d.png"] forState:UIControlStateSelected];
            }
        }
        else
        {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                [self.toolbarQualityBtn setBackgroundImage:[UIImage imageNamed:@"iPad_sdQuality_d.png"] forState:UIControlStateSelected];
            }
            else
            {
                [self.toolbarQualityBtn setBackgroundImage:[UIImage imageNamed:@"iPhone_sdQuality_d.png"] forState:UIControlStateSelected];
            }
        }
    }
    
}

- (void)updateToolbarSpeakerStatus:(BOOL)bCanSpeaker
                         isSpeaker:(BOOL)bSpeaker
{
    if (_bWaitingSpeakerStatus)
    {
        self.toolbarSpeakerBtn.selected = NO;
        self.toolbarSpeakerBtn.enabled = NO;
        [self.toolbarSpeakerBtn setTitleColor:[UIColor grayColor]
                                     forState:UIControlStateDisabled];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            [self.toolbarSpeakerBtn setBackgroundImage:[UIImage imageNamed:@"iPad_speak_g.png"]
                                              forState:UIControlStateDisabled];
        }
        else
        {
            [self.toolbarSpeakerBtn setBackgroundImage:[UIImage imageNamed:@"iPhone_speak_g.png"]
                                              forState:UIControlStateDisabled];
        }
    }
    else
    {
        if (bCanSpeaker)
        {
            self.toolbarSpeakerBtn.enabled = YES;
            [self.toolbarSpeakerBtn setTitleColor:[UIColor whiteColor]
                                         forState:UIControlStateNormal];
            if (bSpeaker)
            {
                self.toolbarSpeakerBtn.selected = YES;
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                {
                    [self.toolbarSpeakerBtn setBackgroundImage:[UIImage imageNamed:@"iPad_speak_d.png"]
                                                      forState:UIControlStateSelected];
                }
                else
                {
                    [self.toolbarSpeakerBtn setBackgroundImage:[UIImage imageNamed:@"iPhone_speak_d.png"]
                                                      forState:UIControlStateSelected];
                }
            }
            else
            {
                self.toolbarSpeakerBtn.selected = NO;
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                {
                    [self.toolbarSpeakerBtn setBackgroundImage:[UIImage imageNamed:@"iPad_speak.png"]
                                                      forState:UIControlStateNormal];
                }
                else
                {
                    [self.toolbarSpeakerBtn setBackgroundImage:[UIImage imageNamed:@"iPhone_speak.png"]
                                                      forState:UIControlStateNormal];
                }
            }
        }
        else
        {
            self.toolbarSpeakerBtn.selected = NO;
            self.toolbarSpeakerBtn.enabled = NO;
            [self.toolbarSpeakerBtn setTitleColor:[UIColor grayColor]
                                         forState:UIControlStateDisabled];
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                [self.toolbarSpeakerBtn setBackgroundImage:[UIImage imageNamed:@"iPad_speak_g.png"]
                                                  forState:UIControlStateDisabled];
            }
            else
            {
                [self.toolbarSpeakerBtn setBackgroundImage:[UIImage imageNamed:@"iPhone_speak_g.png"]
                                                  forState:UIControlStateDisabled];
            }
        }
    }
    
}

- (void)updateToolbarPresenterStatus:(BOOL)bSpeaker
                         isPresenter:(BOOL)bPresenter
{
#if 0
    if (_bWaitingSpeakerStatus || _bWaitingPresenterStatus)
    {
        self.toolbarPresenterBtn.enabled = NO;
        [self.toolbarPresenterBtn setTitleColor:[UIColor grayColor]
                                       forState:UIControlStateDisabled];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            [self.toolbarPresenterBtn setBackgroundImage:[UIImage imageNamed:@"iPad_present_g.png"]
                                                forState:UIControlStateDisabled];
        }
        else
        {
            [self.toolbarPresenterBtn setBackgroundImage:[UIImage imageNamed:@"iPhone_present_g.png"]
                                                forState:UIControlStateDisabled];
        }
        
        [self.toolbarPresenterBtn setTitleColor:[UIColor grayColor]
                                       forState:UIControlStateDisabled];
    }
    else
    {
        if (bSpeaker)
        {
            if (bPresenter)
            {
                self.toolbarPresenterBtn.enabled = NO;
                [self.toolbarPresenterBtn setTitleColor:[UIColor grayColor]
                                               forState:UIControlStateDisabled];
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                {
                    [self.toolbarPresenterBtn setBackgroundImage:[UIImage imageNamed:@"iPad_present_g.png"]
                                                        forState:UIControlStateDisabled];
                }
                else
                {
                    [self.toolbarPresenterBtn setBackgroundImage:[UIImage imageNamed:@"iPhone_present_g.png"]
                                                        forState:UIControlStateDisabled];
                }
            }
            else
            {
                self.toolbarPresenterBtn.enabled = YES;
                [self.toolbarPresenterBtn setTitleColor:[UIColor whiteColor]
                                               forState:UIControlStateNormal];
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                {
                    [self.toolbarPresenterBtn setBackgroundImage:[UIImage imageNamed:@"iPad_present.png"]
                                                        forState:UIControlStateNormal];
                }
                else
                {
                    [self.toolbarPresenterBtn setBackgroundImage:[UIImage imageNamed:@"iPhone_present.png"]
                                                        forState:UIControlStateNormal];
                }
                
            }
        }
        else
        {
            self.toolbarPresenterBtn.enabled = NO;
            [self.toolbarPresenterBtn setTitleColor:[UIColor grayColor]
                                           forState:UIControlStateDisabled];
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                [self.toolbarPresenterBtn setBackgroundImage:[UIImage imageNamed:@"iPad_present_g.png"]
                                                    forState:UIControlStateDisabled];
            }
            else
            {
                [self.toolbarPresenterBtn setBackgroundImage:[UIImage imageNamed:@"iPhone_present_g.png"]
                                                    forState:UIControlStateDisabled];
            }
        }
    }
#endif
    
}

- (void)updateToolbarPresenterBtnStatus:(int)nStatus
{
    if (nStatus == 0)
    {
        //NSLog(@"status == 0");
        self.toolbarPresenterBtn.enabled = NO;
        [self.toolbarPresenterBtn setTitleColor:[UIColor grayColor]
                                       forState:UIControlStateDisabled];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            [self.toolbarPresenterBtn setBackgroundImage:[UIImage imageNamed:@"iPad_present_g.png"]
                                                forState:UIControlStateDisabled];
        }
        else
        {
            [self.toolbarPresenterBtn setBackgroundImage:[UIImage imageNamed:@"iPhone_present_g.png"]
                                                forState:UIControlStateDisabled];
        }
    }
    else
    {
        //NSLog(@"status == 1");
        self.toolbarPresenterBtn.enabled = YES;
        [self.toolbarPresenterBtn setTitleColor:[UIColor whiteColor]
                                       forState:UIControlStateNormal];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            [self.toolbarPresenterBtn setBackgroundImage:[UIImage imageNamed:@"iPad_present.png"]
                                                forState:UIControlStateNormal];
        }
        else
        {
            [self.toolbarPresenterBtn setBackgroundImage:[UIImage imageNamed:@"iPhone_present.png"]
                                                forState:UIControlStateNormal];
        }
        
    }
}

- (void)updateToolbarLayoutStatus
{
    if (_bWaitingPresenterStatus || _bWaitingSpeakerStatus)
    {
        self.toolbarLayoutBtn.enabled = NO;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            [self.toolbarLayoutBtn setBackgroundImage:[UIImage imageNamed:@"iPad_layout_g.png"]
                                             forState:UIControlStateDisabled];
        }
        else
        {
            [self.toolbarLayoutBtn setBackgroundImage:[UIImage imageNamed:@"iPhone_layout_g.png"]
                                             forState:UIControlStateDisabled];
        }
        
        [self.toolbarLayoutBtn setTitleColor:[UIColor grayColor]
                                    forState:UIControlStateNormal];
    }
    else
    {
        if (_bPresenter)
        {
            self.toolbarLayoutBtn.enabled = YES;
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                [self.toolbarLayoutBtn setBackgroundImage:[UIImage imageNamed:@"iPad_layout.png"]
                                                 forState:UIControlStateNormal];
            }
            else
            {
                [self.toolbarLayoutBtn setBackgroundImage:[UIImage imageNamed:@"iPhone_layout.png"]
                                                 forState:UIControlStateNormal];
            }
            
            [self.toolbarLayoutBtn setTitleColor:[UIColor whiteColor]
                                        forState:UIControlStateNormal];
            
            
        }
        else
        {
            self.toolbarLayoutBtn.enabled = NO;
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                [self.toolbarLayoutBtn setBackgroundImage:[UIImage imageNamed:@"iPad_layout_g.png"]
                                                 forState:UIControlStateDisabled];
            }
            else
            {
                [self.toolbarLayoutBtn setBackgroundImage:[UIImage imageNamed:@"iPhone_layout_g.png"]
                                                 forState:UIControlStateDisabled];
            }
            
            [self.toolbarLayoutBtn setTitleColor:[UIColor grayColor]
                                        forState:UIControlStateNormal];
            
        }
    }
    
    
}

- (void)updateLocalAudioBtnStatus:(BOOL)bSpeaker
                        localMute:(BOOL)bMute
{
    [self removeAllActiveSpeaker];
    
    if (bSpeaker)
    {
        self.localVideoViewAudioBtn.enabled = YES;
        if (!bMute)
        {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                [self.localVideoViewAudioBtn setImage:[UIImage imageNamed:@"iPad_mic.png"]
                                             forState:UIControlStateNormal];
            }
            else
            {
                [self.localVideoViewAudioBtn setImage:[UIImage imageNamed:@"iPhone_mic.png"]
                                             forState:UIControlStateNormal];
            }
            
            [self updateAudioIndicator:YES];
        }
        else
        {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                [self.localVideoViewAudioBtn setImage:[UIImage imageNamed:@"iPad_mic_d.png"]
                                             forState:UIControlStateNormal];
            }
            else
            {
                [self.localVideoViewAudioBtn setImage:[UIImage imageNamed:@"iPhone_mic_d.png"]
                                             forState:UIControlStateNormal];
            }
            
            [self updateAudioIndicator:NO];
            
        }
        
        if (_audioManager)
        {
            [_audioManager setMute:bMute];
        }
    }
    else
    {
        self.localVideoViewAudioBtn.enabled = NO;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            [self.localVideoViewAudioBtn setImage:[UIImage imageNamed:@"iPad_mic_g.png"]
                                         forState:UIControlStateDisabled];
        }
        else
        {
            [self.localVideoViewAudioBtn setImage:[UIImage imageNamed:@"iPhone_mic_g.png"]
                                         forState:UIControlStateDisabled];
        }
        
        [self updateAudioIndicator:NO];
        
        if (_audioManager)
        {
            [_audioManager setMute:YES];
        }
    }
}

- (void)updateLocalVideoBtnStatus:(BOOL)bSpeaker
                        localMute:(BOOL)bMute
{
    if (bSpeaker)
    {
        self.localVideoViewVideoBtn.enabled = YES;
        if (!bMute)
        {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                [self.localVideoViewVideoBtn setImage:[UIImage imageNamed:@"iPad_cam.png"]
                                             forState:UIControlStateNormal];
            }
            else
            {
                [self.localVideoViewVideoBtn setImage:[UIImage imageNamed:@"iPhone_cam.png"]
                                             forState:UIControlStateNormal];
            }
            
            [self updateVideoIndicator:YES];
        }
        else
        {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                [self.localVideoViewVideoBtn setImage:[UIImage imageNamed:@"iPad_cam_d.png"]
                                             forState:UIControlStateNormal];
            }
            else
            {
                [self.localVideoViewVideoBtn setImage:[UIImage imageNamed:@"iPhone_cam_d.png"]
                                             forState:UIControlStateNormal];
            }
            
            [self updateVideoIndicator:NO];
        }
    }
    else
    {
        self.localVideoViewVideoBtn.enabled = NO;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            [self.localVideoViewVideoBtn setImage:[UIImage imageNamed:@"iPad_cam_g.png"]
                                         forState:UIControlStateDisabled];
        }
        else
        {
            [self.localVideoViewVideoBtn setImage:[UIImage imageNamed:@"iPhone_cam_g.png"]
                                         forState:UIControlStateDisabled];
        }
        
        [self updateVideoIndicator:NO];
    }
}

-(void)removeAllActiveSpeaker
{
//    if (_videoCallAVMode == 1)
//    {
//        return;
//    }
    //	AcuConferenceLayoutStatus1Video,
    //    AcuConferenceLayoutStatus2Video,
    //    AcuConferenceLayoutStatus4Video,
    //    AcuConferenceLayoutStatus1SVideo,
    //    AcuConferenceLayoutStatus2SVideo,
    [_videoFrameMutex lock];
    switch (_layoutStatus)
    {
        case AcuConferenceLayoutStatus1Video:
        {
            [self.videoViewController1 setAcitveSpeaker:NO];
            break;
        }
            
        case AcuConferenceLayoutStatus2Video:
        {
            [self.videoViewController1 setAcitveSpeaker:NO];
            [self.videoViewController2 setAcitveSpeaker:NO];
            break;
        }
            
        case AcuConferenceLayoutStatus4Video:
        {
            [self.videoViewController1 setAcitveSpeaker:NO];
            [self.videoViewController2 setAcitveSpeaker:NO];
            [self.videoViewController3 setAcitveSpeaker:NO];
            [self.videoViewController4 setAcitveSpeaker:NO];
            break;
        }
            
        case AcuConferenceLayoutStatus1SVideo:
        {
            [self.videoViewController1 setAcitveSpeaker:NO];
            break;
        }
            
        case AcuConferenceLayoutStatus2SVideo:
        {
            [self.videoViewController1 setAcitveSpeaker:NO];
            [self.videoViewController2 setAcitveSpeaker:NO];
            break;
        }
            
        default:
            break;
    }
    [_videoFrameMutex unlock];
}

- (void)remoteMuteLocalVideo:(BOOL)bMute
{
    if (bMute)
    {
        //NSLog(@"remote mute video");
        [self updateLocalVideoBtnStatus:NO localMute:bMute];
    }
    else
    {
        //NSLog(@"remote unmute video");
        [self updateLocalVideoBtnStatus:YES localMute:_bMuteLocalVideo];
    }
}

- (void)remoteMuteLocalAudio:(BOOL)bMute
{
    if (bMute)
    {
        [self updateLocalAudioBtnStatus:NO localMute:bMute];
    }
    else
    {
        [self updateLocalAudioBtnStatus:YES localMute:_bMuteLocalAudio];
    }
}

- (void)invite2Present:(int)nReason
{
#if ACU_COM_USE_ALERTCONTROLLER
    if (ACU_COM_IOS8)
    {
        if (_hostEndConferenceAlertController ||
            _participantEndConferenceAlertController ||
            _endConferenceAlertController ||
            _acuComIncomingAlertView ||
            _invitedSpeakerAlertController)
        {
            return;
        }
        
        if (_invitedSpeakerAlertController)
        {
            [_invitedSpeakerAlertController dismissViewControllerAnimated:YES completion:nil];
            _invitedSpeakerAlertController = nil;
        }
        
        NSString *title = NSLocalizedString(@"Invite to present", nil);
        NSString *message = NSLocalizedString(@"Host invites you to present, accept?", nil);
        NSString *yesButtonTitle = NSLocalizedString(@"Yes", nil);
        NSString *noButtonTitle = NSLocalizedString(@"No", nil);
        
        _invitedPresentAlertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
        
        // Create the actions.
        
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:yesButtonTitle
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              if (self.conferenceDelegate)
                                                              {
                                                                  [self.conferenceCommandDelegate acuConferenceSendCommand:cmd_agree_presenter
                                                                                                                  withInfo:""];
                                                              }
                                                              _invitedPresentAlertController = nil;
                                                          }];
        
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:noButtonTitle
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             NSLog(@"invitedPresentAlert pressed NO");
                                                             _invitedPresentAlertController = nil;
                                                         }];
        
        // Add the actions.
        [_invitedPresentAlertController addAction:yesAction];
        [_invitedPresentAlertController addAction:noAction];
        [self presentViewController:_invitedPresentAlertController animated:YES completion:nil];
    }
    else
    {
        if (_invitedSpeakerAlertView != nil && _invitedSpeakerAlertView.hidden == NO)
        {
            [_invitedSpeakerAlertView dismissWithClickedButtonIndex:1 animated:NO];
        }
        
        _invitedPresentAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invite to present", @"Conference Presention Invited Presenter AlertView")
                                                              message:NSLocalizedString(@"Host invites you to present, accept?", @"Conference Presention Invited Presenter AlertView")
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Yes", @"Conference Presention Invited Presenter AlertView")
                                                    otherButtonTitles:NSLocalizedString(@"No", @"Conference Presention Invited Presenter AlertView"),
                                    nil];
        [_invitedPresentAlertView show];
    }
#else
    if (_invitedSpeakerAlertView != nil && _invitedSpeakerAlertView.hidden == NO)
    {
        [_invitedSpeakerAlertView dismissWithClickedButtonIndex:1 animated:NO];
    }
    
    _invitedPresentAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invite to present", @"Conference Presention Invited Presenter AlertView")
                                                          message:NSLocalizedString(@"Host invites you to present, accept?", @"Conference Presention Invited Presenter AlertView")
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"Yes", @"Conference Presention Invited Presenter AlertView")
                                                otherButtonTitles:NSLocalizedString(@"No", @"Conference Presention Invited Presenter AlertView"),
                                nil];
    [_invitedPresentAlertView show];
#endif
}

- (void)invite2Speaker:(int)nReason
{
#if ACU_COM_USE_ALERTCONTROLLER
    if (ACU_COM_IOS8)
    {
        if (_hostEndConferenceAlertController ||
            _participantEndConferenceAlertController ||
            _endConferenceAlertController ||
            _invitedPresentAlertController ||
            _acuComIncomingAlertView)
        {
            return;
        }
        
        
        if (_invitedPresentAlertController)
        {
            [_invitedPresentAlertController dismissViewControllerAnimated:YES completion:nil];
            _invitedPresentAlertController = nil;
        }
        
        NSString *title = NSLocalizedString(@"Invite to speak", nil);
        NSString *message = NSLocalizedString(@"Host invites you to speak, accept?", nil);
        NSString *yesButtonTitle = NSLocalizedString(@"Yes", nil);
        NSString *noButtonTitle = NSLocalizedString(@"No", nil);
        
        _invitedSpeakerAlertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
        
        // Create the actions.
        
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:yesButtonTitle
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              if (self.conferenceDelegate)
                                                              {
                                                                  [self.conferenceCommandDelegate acuConferenceSendCommand:cmd_agree_speaker
                                                                                                                  withInfo:""];
                                                              }
                                                              _invitedSpeakerAlertController = nil;
                                                          }];
        
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:noButtonTitle
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             NSLog(@"invitedSpeakAlert pressed NO");
                                                             _invitedSpeakerAlertController = nil;
                                                         }];
        
        // Add the actions.
        [_invitedSpeakerAlertController addAction:yesAction];
        [_invitedSpeakerAlertController addAction:noAction];
        [self presentViewController:_invitedSpeakerAlertController animated:YES completion:nil];
    }
    else
    {
        if (_invitedPresentAlertView != nil && _invitedPresentAlertView.hidden == NO)
        {
            [_invitedPresentAlertView dismissWithClickedButtonIndex:1 animated:NO];
        }
        
        _invitedSpeakerAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invite to speak", @"Conference Presention Invited Speaker AlertView")
                                                              message:NSLocalizedString(@"Host invites you to speak, accept?", @"Conference Presention Invited Speaker AlertView")
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Yes", @"Conference Presention Invited Speaker AlertView")
                                                    otherButtonTitles:NSLocalizedString(@"No", @"Conference Presention Invited Speaker AlertView"),
                                    nil];
        [_invitedSpeakerAlertView show];
    }
#else
    if (_invitedPresentAlertView != nil && _invitedPresentAlertView.hidden == NO)
    {
        [_invitedPresentAlertView dismissWithClickedButtonIndex:1 animated:NO];
    }
    
    _invitedSpeakerAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invite to speak", @"Conference Presention Invited Speaker AlertView")
                                                          message:NSLocalizedString(@"Host invites you to speak, accept?", @"Conference Presention Invited Speaker AlertView")
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"Yes", @"Conference Presention Invited Speaker AlertView")
                                                otherButtonTitles:NSLocalizedString(@"No", @"Conference Presention Invited Speaker AlertView"),
                                nil];
    [_invitedSpeakerAlertView show];
#endif
}

- (void)endConference:(int)nReason
       andDescription:(NSString*)description
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
#if ACU_COM_USE_ALERTCONTROLLER
    if (ACU_COM_IOS8)
    {
        if (_invitedSpeakerAlertController)
        {
            [_invitedSpeakerAlertController dismissViewControllerAnimated:YES completion:nil];
            _invitedSpeakerAlertController = nil;
        }
        
        if (_invitedPresentAlertController)
        {
            [_invitedPresentAlertController dismissViewControllerAnimated:YES completion:nil];
            _invitedPresentAlertController = nil;
        }
        
        if (_acuComIncomingAlertController)
        {
            [_acuComIncomingAlertController dismissViewControllerAnimated:YES completion:nil];
            _acuComIncomingAlertController = nil;
        }
        
        if (_acuComNotificationAlertController)
        {
            [_acuComNotificationAlertController dismissViewControllerAnimated:YES completion:nil];
            _acuComNotificationAlertController = nil;
        }
    }
    else
    {
        if (_invitedSpeakerAlertView != nil && _invitedSpeakerAlertView.hidden == NO)
        {
            [_invitedSpeakerAlertView dismissWithClickedButtonIndex:1 animated:NO];
        }
        
        if (_invitedPresentAlertView != nil && _invitedPresentAlertView.hidden == NO)
        {
            [_invitedPresentAlertView dismissWithClickedButtonIndex:1 animated:NO];
        }
        
        if (_acuComNotificationAlertView != nil && _acuComNotificationAlertView.hidden == NO)
        {
            [_acuComNotificationAlertView dismissWithClickedButtonIndex:0 animated:NO];
        }
        
        if (_acuComIncomingAlertView != nil && _acuComIncomingAlertView.hidden == NO)
        {
            [_acuComIncomingAlertView dismissWithClickedButtonIndex:1 animated:NO];
        }
    }
#else
    if (_invitedSpeakerAlertView != nil && _invitedSpeakerAlertView.hidden == NO)
    {
        [_invitedSpeakerAlertView dismissWithClickedButtonIndex:1 animated:NO];
    }
    
    if (_invitedPresentAlertView != nil && _invitedPresentAlertView.hidden == NO)
    {
        [_invitedPresentAlertView dismissWithClickedButtonIndex:1 animated:NO];
    }
#endif
    
    if (nReason == 0)
    {
#if ACU_COM_USE_ALERTCONTROLLER
        if (ACU_COM_IOS8)
        {
            NSString *title = NSLocalizedString(@"Information", nil);
            NSString *message = NSLocalizedString(@"Conference ended!", nil);
            NSString *okButtonTitle = NSLocalizedString(@"OK", nil);
            
            _endConferenceAlertController = [UIAlertController alertControllerWithTitle:title
                                                                                message:message
                                                                         preferredStyle:UIAlertControllerStyleAlert];
            
            // Create the actions.
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:okButtonTitle
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 [self exitConference:AcuConferenceEndStatusStopped];
                                                             }];
            
            // Add the actions.
            [_endConferenceAlertController addAction:okAction];
            
            [self presentViewController:_endConferenceAlertController animated:YES completion:nil];
            
        }
        else
        {
            _endConferenceAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information", @"Conference Presention Conference End AlertView")
                                                                 message:NSLocalizedString(@"Conference ended!", @"Conference Presention Conference End AlertView")
                                                                delegate:self
                                                       cancelButtonTitle:NSLocalizedString(@"OK", @"Conference Presention Conference End AlertView")
                                                       otherButtonTitles:nil];
            
            if (_endConferenceAlertView)
            {
                [_endConferenceAlertView show];
            }
        }
#else
        _endConferenceAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information", @"Conference Presention Conference End AlertView")
                                                             message:NSLocalizedString(@"Conference ended!", @"Conference Presention Conference End AlertView")
                                                            delegate:self
                                                   cancelButtonTitle:NSLocalizedString(@"OK", @"Conference Presention Conference End AlertView")
                                                   otherButtonTitles:nil];
        
        if (_endConferenceAlertView)
        {
            [_endConferenceAlertView show];
        }
#endif
    }
    else if(nReason == 3)
    {
        [self exitConference:AcuConferenceEndStatusKickOut];
    }
    else if(nReason == -2)
    {
        
    }
}

- (void)updateAudioIndicator:(BOOL)bHidden
{
    self.audioIndicator.hidden = bHidden;
}

- (void)updateVideoIndicator:(BOOL)bHidden
{
    self.videoIndicator.hidden = bHidden;
}

- (void)updateChatMsgIndicator:(BOOL)bHidden
{
    self.chatMsgIndicator.hidden = bHidden;
}

- (void)updateNetworkIndicator:(AcuConferenceNetworkStatus)eStatus
{
    switch (eStatus)
    {
        case AcuConferenceNetworkStatus_Good:
        {
            self.networkIndicator.image = [UIImage imageNamed:@"indicator_network_good.png"];
            break;
        }
            
        case AcuConferenceNetworkStatus_General:
        {
            self.networkIndicator.image = [UIImage imageNamed:@"indicator_network_general.png"];
            break;
        }
            
        case AcuConferenceNetworkStatus_Bad:
        {
            self.networkIndicator.image = [UIImage imageNamed:@"indicator_network_bad.png"];
            break;
        }
            
        default:
            break;
    }
}

- (void)deallocResource
{
    if (!_needDeallocResource)
    {
        return;
    }
    
    _needDeallocResource = NO;
    _bMuteLocalVideo = YES;
    _bSpeaker = NO;
    [_audioManager setMute:YES];
    
    _bStillGotVideoData = NO;
    
    if (_localVideoTimer)
    {
        [_localVideoTimer invalidate];
        _localVideoTimer = nil;
    }
    
    if (_remoteVideoTimer)
    {
        [_remoteVideoTimer invalidate];
        _remoteVideoTimer = nil;
    }
    
    [_videoCapture stopCapture];
    [_audioManager stopAudioManager];
    
#if ACU_IOS_SAVE_AUDIO_CAPTURE_DATA
    [_audioCaptureDataFileHandler closeFile];
#endif
    
#if ACU_IOS_SAVE_AUDIO_PLAYBACK_DATA
    [_audioPlaybackDataFileHandler closeFile];
#endif
    
    
    _videoCapture = nil;
    _audioManager = nil;
    
    if (_hudToolbarTimer)
    {
        [_hudToolbarTimer invalidate];
        _hudToolbarTimer = nil;
    }
    
    _layoutModePop.delegate = nil;
    _layoutModePop.datasource = nil;
    _layoutModePop = nil;
    
    [_videoFrameMutex lock];
    if (_videoFrame1)
    {
        _videoFrame1 = nil;
    }
    
    if (_videoFrame2)
    {
        _videoFrame2 = nil;
    }
    
    if (_videoFrame3)
    {
        _videoFrame3 = nil;
    }
    
    if (_videoFrame4)
    {
        _videoFrame4 = nil;
    }
    
    if(self.videoViewController1)
    {
        self.videoViewController1.view.hidden = YES;
    }
    if(self.videoViewController2)
    {
        self.videoViewController2.view.hidden = YES;
    }
    if(self.videoViewController3)
    {
        self.videoViewController3.view.hidden = YES;
    }
    if(self.videoViewController4)
    {
        self.videoViewController4.view.hidden = YES;
    }
    self.videoViewController1 = nil;
    self.videoViewController2 = nil;
    self.videoViewController3 = nil;
    self.videoViewController4 = nil;
    [_videoFrameMutex unlock];
    _videoFrameMutex = nil;
}

#pragma mark ----AcuCom Functions----
- (void)setVideoCallLauncher:(BOOL)bLauncher
{
    _bVideoCallLauncher = bLauncher;
}

- (void)setAcuComListener:(AcuComListener*)listener
{
    _acucomListener = listener;
}

- (void)setVideoCallMode:(int)videoCallMode
{
    _videoCallMode = videoCallMode;
    if(_videoCallMode == 0)
    {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        
        //        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:YES];
        
        //        float arch = M_PI_2;
        //
        //        self.view.transform = CGAffineTransformMakeRotation(arch);
        
        if (orientation != UIInterfaceOrientationLandscapeLeft &&
            orientation != UIInterfaceOrientationLandscapeRight)
        {
            CGRect frame;
            if (_biPhone5Above)
            {
                frame = self.localVideoView.frame;
                frame.origin.x = 290+88;
                frame.origin.y = 20;
                self.localVideoView.frame = frame;
                
                frame = self.hudToolbar.frame;
                frame.origin.x = 90+44;
                frame.origin.y = 240;
                self.hudToolbar.frame = frame;
                
                frame = self.indicatorToolbar.frame;
                frame.origin.x = 448+88;
                frame.origin.y = 210;
                self.indicatorToolbar.frame = frame;
            }
            else
            {
                frame = self.localVideoView.frame;
                frame.origin.x = 290;
                frame.origin.y = 20;
                self.localVideoView.frame = frame;

                frame = self.hudToolbar.frame;
                frame.origin.x = 90;
                frame.origin.y = 240;
                self.hudToolbar.frame = frame;

                frame = self.indicatorToolbar.frame;
                frame.origin.x = 448;
                frame.origin.y = 210;
                self.indicatorToolbar.frame = frame;
            }
            
            //self.localPreviewVideoController.view.frame = CGRectMake(0, 0, 160, 120);
        }
        
        
        //        if (_layoutStatus == AcuConferenceLayoutStatus1Video && self.videoViewController1 != nil)
        //        {
        //            int nViewWidth;
        //            int nViewHight;
        //            UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        //            if (orientation == UIInterfaceOrientationPortrait ||
        //                orientation == UIInterfaceOrientationPortraitUpsideDown)
        //            {
        //                nViewWidth = self.view.frame.size.height;
        //                nViewHight = self.view.frame.size.width;
        //            }
        //            else if (orientation == UIInterfaceOrientationLandscapeLeft ||
        //                     orientation == UIInterfaceOrientationLandscapeRight)
        //            {
        //                nViewWidth = self.view.frame.size.width;
        //                nViewHight = self.view.frame.size.height;
        //            }
        //
        //            self.videoViewController1.view.frame = CGRectMake(0, 0, nViewWidth, nViewHight);
        //        }
    }
    
    [self showAcuComHubToolbar];
    
    if (_videoCapture)
    {
        [_videoCapture setVideoCallMode:_videoCallMode];
    }
}

- (void)setVideoCallAVMode:(int)videoCallAVMode
{
    if(videoCallAVMode == 0)
    {
        int aaa = 0;
    }
    _videoCallAVMode = videoCallAVMode;
    [self showAcuComLocalPreviewToolbar];
}

- (void)incomingCallDialog:(NSString*)dlgTitle
                dlgContent:(NSString*)content
                dlgYesName:(NSString*)yesName
                 dlgNoName:(NSString*)noName
                    config:(NSDictionary*)config
{
    /*
     YES: accept new session
     NO: reject new session
     */
    _inComingCallConfig = config;
    
    if (_acucomListener)
    {
        //_acucomListener->userRejected(_inComingCallConfig);
    }
    return;
    
#if ACU_COM_USE_ALERTCONTROLLER
    if (ACU_COM_IOS8)
    {
        if (_hostEndConferenceAlertController ||
            _participantEndConferenceAlertController ||
            _endConferenceAlertController ||
            _invitedPresentAlertController ||
            _invitedSpeakerAlertController)
        {
            if (_acucomListener)
            {
                //_acucomListener->userRejected(_inComingCallConfig);
            }
            return;
        }
        
        NSString *title = dlgTitle;
        NSString *message = content;
        NSString *yesButtonTitle = yesName;
        NSString *noButtonTitle = noName;
        
        _acuComIncomingAlertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
        
        // Create the actions.
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:yesButtonTitle
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              if (_hostEndConferenceAlertController)
                                                              {
                                                                  [_hostEndConferenceAlertController dismissViewControllerAnimated:YES
                                                                                                                        completion:nil];
                                                              }
                                                              
                                                              if (_participantEndConferenceAlertController)
                                                              {
                                                                  [_participantEndConferenceAlertController dismissViewControllerAnimated:YES
                                                                                                                               completion:nil];
                                                              }
                                                              
                                                              if (_endConferenceAlertController)
                                                              {
                                                                  [_endConferenceAlertController dismissViewControllerAnimated:YES
                                                                                                                    completion:nil];
                                                              }
                                                              
                                                              if (_invitedSpeakerAlertController)
                                                              {
                                                                  [_invitedSpeakerAlertController dismissViewControllerAnimated:YES
                                                                                                                     completion:nil];
                                                              }
                                                              
                                                              if (_invitedPresentAlertController)
                                                              {
                                                                  [_invitedPresentAlertController dismissViewControllerAnimated:YES
                                                                                                                     completion:nil];
                                                              }
                                                              
                                                              if (_acucomListener)
                                                              {
                                                                  [self exitConference:AcuConferenceEndStatusAcceptAnother];
                                                                  //_acucomListener->conferenceClosed(100, _inComingCallConfig);
                                                                  _acucomListener->conferenceClosed(30, nil);
                                                              }
                                                              
                                                              _acuComIncomingAlertController = nil;
                                                              
                                                          }];
        
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:noButtonTitle
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             if (_acucomListener)
                                                             {
                                                                 //_acucomListener->userRejected(_inComingCallConfig);
                                                             }
                                                             _acuComIncomingAlertController = nil;
                                                         }];
        
        // Add the actions.
        [_acuComIncomingAlertController addAction:yesAction];
        [_acuComIncomingAlertController addAction:noAction];
        [self presentViewController:_acuComIncomingAlertController animated:YES completion:nil];
    }
    else
    {
        if (_hostEndConferenceAlertView ||
            _participantEndConferenceAlertView ||
            _endConferenceAlertView ||
            _invitedPresentAlertView ||
            _invitedSpeakerAlertView)
        {
            if (_acucomListener)
            {
                //_acucomListener->userRejected(_inComingCallConfig);
            }
            return;
        }
        
        _acuComIncomingAlertView = nil;
        _acuComIncomingAlertView = [[UIAlertView alloc] initWithTitle:dlgTitle
                                                              message:content
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                                    otherButtonTitles:yesName, noName, nil];
        
        [_acuComIncomingAlertView show];
    }
#else
    _acuComIncomingAlertView = nil;
    _acuComIncomingAlertView = [[UIAlertView alloc] initWithTitle:dlgTitle
                                                          message:content
                                                         delegate:self
                                                cancelButtonTitle:nil
                                                otherButtonTitles:yesName, noName, nil];
    
    [_acuComIncomingAlertView show];
#endif
}

- (void)conferenceNotification:(int)type
                     msgSumary:(NSString*)sumary
                       session:(NSString*)sessinId
{
    if (!_bConferenceShowing)
    {
        _bHasQueueNotification = YES;
        _nQueueNotificationType = type;
        _strQueueNotificationSumary = sumary;
        _strQueueNotificationSessinId = sessinId;
        return;
    }
    
    if (type == 1)
    {
        if (_videoCallMode == 0)
        {
            return;
        }
        
        _acuComNotificationType = type;
#if ACU_COM_USE_ALERTCONTROLLER
        if (ACU_COM_IOS8)
        {
            NSString *title = NSLocalizedString(@"Prompt", nil);
            NSString *message = NSLocalizedString(sumary, nil);
            NSString *okButtonTitle = NSLocalizedString(@"OK", nil);
            
            _acuComNotificationAlertController = [UIAlertController alertControllerWithTitle:title
                                                                                     message:message
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            
            // Create the actions.
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:okButtonTitle
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 if (_hostEndConferenceAlertController)
                                                                 {
                                                                     [_hostEndConferenceAlertController dismissViewControllerAnimated:YES
                                                                                                                           completion:nil];
                                                                 }
                                                                 
                                                                 if (_acuComNotificationType == 1)
                                                                 {
                                                                     [self exitConference:AcuConferenceEndStatusUserRejected];
                                                                 }
                                                                 
                                                                 _acuComNotificationAlertController = nil;
                                                             }];
            
            // Add the actions.
            [_acuComNotificationAlertController addAction:okAction];
            [self presentViewController:_acuComNotificationAlertController animated:YES completion:nil];
        }
        else
        {
            _acuComNotificationAlertView = nil;
            _acuComNotificationAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil)
                                                                      message:NSLocalizedString(sumary, @"AcuCom Notification dlg")
                                                                     delegate:self
                                                            cancelButtonTitle:nil
                                                            otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
            
            [_acuComNotificationAlertView show];
        }
#else
        
        _acuComNotificationType = type;
        _acuComNotificationAlertView = nil;
        _acuComNotificationAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil)
                                                                  message:NSLocalizedString(sumary, @"AcuCom Notification dlg")
                                                                 delegate:self
                                                        cancelButtonTitle:nil
                                                        otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        
        [_acuComNotificationAlertView show];
        
#endif
    }
}

- (void)showAcuComHubToolbar
{
    /*
     1: 1V1的视频会议，
     0: 多人视频会议
     */
    if (_videoCallMode == 1)
    {
        self.hudToolbar.hidden = YES;
        self.videoCallToolbar.hidden = NO;
        
        if (_videoCallAVMode == 1)
        {
            self.toolbarAcuComVideoQuality.hidden = YES;
            self.toolbarAcuComNoVideo.hidden = YES;
            self.toolbarAcuComHangup.hidden = YES;
            
            self.toolbarAcuComMuteMic.hidden = NO;
            self.toolbarAcuComHandFree.hidden = NO;
            self.toolbarAcuComAudioHangup.hidden = NO;
        }
        else
        {
            self.toolbarAcuComVideoQuality.hidden = NO;
            self.toolbarAcuComNoVideo.hidden = NO;
            self.toolbarAcuComHangup.hidden = NO;
            
            self.toolbarAcuComMuteMic.hidden = YES;
            self.toolbarAcuComHandFree.hidden = YES;
            self.toolbarAcuComAudioHangup.hidden = YES;
        }
    }
    else
    {
        self.hudToolbar.hidden = NO;
        self.videoCallToolbar.hidden = YES;
        if (_videoCallAVMode == 1)
        {
            self.toolbarQualityBtn.hidden = YES;
            self.toolbarAcuComConfMuteMic.hidden = NO;
        }
        else
        {
            self.toolbarQualityBtn.hidden = NO;
            self.toolbarAcuComConfMuteMic.hidden = YES;
        }
        
        //[self setVideoCallAVMode:0];
    }
}

- (void)showAcuComLocalPreviewToolbar
{
    /*
     1: 语音呼叫，
     0: 视频呼叫
     */
    if (_videoCallAVMode == 1)
    {
        self.localVideoView.hidden = YES;
        if(_videoCallMode == 1)
        {
            self.AcuComAudioCallBackgroundImage.hidden = NO;
            self.AcuComAudioCallImage.hidden = NO;
            _acucomListener->showCalledUserIcon(self.AcuComAudioCallImage); //txb
        }
        else
        {
            self.AcuComAudioCallBackgroundImage.hidden = YES;
            self.AcuComAudioCallImage.hidden = YES;
        }
        //_videoViewController1.videoView.hidden = YES;
//        _localPreviewVideoController.videoView.hidden = YES;
//        self.localVideoViewSwitchCamBtn.hidden = YES;
//        self.localVideoViewVideoBtn.hidden = YES;
    }
    else
    {
        self.AcuComAudioCallBackgroundImage.hidden = YES;
        self.AcuComAudioCallImage.hidden = YES;
        
        _localPreviewVideoController.videoView.hidden = NO;
        _videoViewController1.videoView.hidden = NO;
        
        self.localVideoViewSwitchCamBtn.hidden = NO;
        self.localVideoViewVideoBtn.hidden = NO;
    }
}

@end
