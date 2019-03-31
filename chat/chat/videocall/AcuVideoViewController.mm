//
//  AcuVideoViewController.m
//  AcuConference
//
//  Created by aculearn on 13-8-9.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import "AcuVideoViewController.h"

#define ACU_ACTIVE_SPEAKER_INDICATOR_INTERVAL  0.8

@interface AcuVideoViewController ()

@end

@implementation AcuVideoViewController
{
//    BOOL _bSetParticipantName;
    BOOL _bActiveSpeaker;
    
    NSTimer *_activeSpeakerTimer;
}


@synthesize videoView;
@synthesize participantLabel;
@synthesize videoCallAVMode;
@synthesize videoCallMode;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	//for ios7
	if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
	{
		self.edgesForExtendedLayout = UIRectEdgeNone;
	}
	// Do any additional setup after loading the view.
//    _bSetParticipantName = NO;
    _bActiveSpeaker = NO;
    _activeSpeakerTimer = nil;
    videoCallMode = 0;
    videoCallAVMode = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload
{
    [self setParticipantLabel:nil];
    [self setVideoView:nil];
    [self setActiveSpeakerIndictor:nil];
    [super viewDidUnload];
}

- (void)setParticipantName:(NSString*)participantName
{
//	if (participantName == nil)
//	{
//		return;
//	}
	
    dispatch_async(dispatch_get_main_queue(), ^{
//        if (_bSetParticipantName)
//        {
//            return;
//        }
//        
//        _bSetParticipantName = YES;
        
        if (videoCallMode == 1 && videoCallAVMode == 1)
        {
            self.participantLabel.textColor = [UIColor whiteColor];
            
            CGRect videoRealRect = self.view.frame;
            CGRect activeSpeakerInidctorRect = self.activeSpeakerIndictor.frame;
            activeSpeakerInidctorRect.origin.x = videoRealRect.origin.x + 18;
#if 0
            UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
            if (deviceOrientation == UIDeviceOrientationPortrait ||
                deviceOrientation == UIDeviceOrientationPortraitUpsideDown)
            {
                activeSpeakerInidctorRect.origin.y = videoRealRect.origin.y + 115;
            }
            else
            {
                activeSpeakerInidctorRect.origin.y = videoRealRect.origin.y + 50;
            }
#else
            activeSpeakerInidctorRect.origin.y = videoRealRect.origin.y + 115;
#endif
            
            
            self.activeSpeakerIndictor.frame = activeSpeakerInidctorRect;
            
            CGRect participantNameRect = self.participantLabel.frame;
            
#if 0
            if (deviceOrientation == UIDeviceOrientationPortrait ||
                deviceOrientation == UIDeviceOrientationPortraitUpsideDown)
            {
                participantNameRect.origin.y = videoRealRect.origin.y + 115;
            }
            else
            {
                participantNameRect.origin.y = videoRealRect.origin.y + 50;
            }
#else
            participantNameRect.origin.y = videoRealRect.origin.y + 115;
#endif
            participantNameRect.origin.x = ((videoRealRect.size.width - participantNameRect.size.width)/2) + videoRealRect.origin.x;
            self.participantLabel.frame = participantNameRect;
        }
        else
        {
            CGRect videoRealRect = [self.videoView getVideoRealRect];
            
            CGRect activeSpeakerInidctorRect = self.activeSpeakerIndictor.frame;
            activeSpeakerInidctorRect.origin.x = videoRealRect.origin.x + 18;
            activeSpeakerInidctorRect.origin.y = videoRealRect.origin.y + 15;
            self.activeSpeakerIndictor.frame = activeSpeakerInidctorRect;
            
            CGRect participantNameRect = self.participantLabel.frame;
            
            participantNameRect.origin.y = videoRealRect.origin.y + 15;
            participantNameRect.origin.x = ((videoRealRect.size.width - participantNameRect.size.width)/2) + videoRealRect.origin.x;
            self.participantLabel.frame = participantNameRect;
        }
        
        
        
        self.participantLabel.text = participantName;
        
        [self.videoView bringSubviewToFront:participantLabel];
        
    });
}

- (void)setAcitveSpeaker:(BOOL)bActiveSpeaker
{
	if (!bActiveSpeaker)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			self.activeSpeakerIndictor.hidden = YES;
		});
	}
	
	if (_bActiveSpeaker == bActiveSpeaker)
	{
		return;
	}
	
	_bActiveSpeaker = bActiveSpeaker;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_bActiveSpeaker)
        {
            CGRect videoRealRect = [self.videoView getVideoRealRect];
            CGRect activeSpeakerInidctorRect = self.activeSpeakerIndictor.frame;
            
            activeSpeakerInidctorRect.origin.x = videoRealRect.origin.x + 18;
            activeSpeakerInidctorRect.origin.y = videoRealRect.origin.y + 15;
            self.activeSpeakerIndictor.frame = activeSpeakerInidctorRect;
            
            //[self.view bringSubviewToFront:self.activeSpeakerIndictor];
            //self.activeSpeakerIndictor.hidden = NO;
            
            _activeSpeakerTimer = [NSTimer scheduledTimerWithTimeInterval:ACU_ACTIVE_SPEAKER_INDICATOR_INTERVAL
                                                                   target:self
                                                                 selector:@selector(activeSpeakerIndict:)
                                                                 userInfo:nil
                                                                  repeats:YES];
        }
        else
        {
            if (_activeSpeakerTimer)
            {
                [_activeSpeakerTimer invalidate];
                _activeSpeakerTimer = nil;
            }
            
            self.activeSpeakerIndictor.hidden = YES;
        }
    });
}

- (void)activeSpeakerIndict:(NSTimer*)theTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.activeSpeakerIndictor.hidden = !self.activeSpeakerIndictor.hidden;
    });
}
@end
