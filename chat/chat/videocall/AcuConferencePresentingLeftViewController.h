//
//  AcuConferencePresentingLeftViewController.h
//  AcuConference
//
//  Created by aculearn on 13-7-12.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AcuParticipantListMenuProtocol.h"
#import "AcuConferenceCommandDelegate.h"

@interface AcuConferencePresentingLeftViewController : UIViewController <UITableViewDelegate,
                                                                        UITableViewDataSource>

@property (nonatomic, weak) NSMutableArray *conferenceParticipantList;

@property (weak, nonatomic) IBOutlet UILabel *participantLabel;
@property (weak, nonatomic) IBOutlet UIButton *showChatBtn;
@property (weak, nonatomic) IBOutlet UITableView *participantList;
@property (weak, nonatomic) IBOutlet UIView *chatContainer;
@property (weak, nonatomic) IBOutlet UIButton *conferenceModeBtn;
@property (weak, nonatomic) IBOutlet UIButton *videoQualityBtn;

@property (nonatomic, weak) id<AcuParticipantListMenuProtocol> participantListMenuDelegate;
@property (nonatomic, weak) id<AcuConferenceCommandDelegate> conferenceCommandDelegate;

- (IBAction)pressConferenceMode:(id)sender;
- (IBAction)pressVideoQuality:(id)sender;


- (void)updateParticipantList:(NSMutableArray*)participantList;


- (void)setModeratorRole:(BOOL)bModerator;
- (void)initConferenceMode:(int)confMode
              videoQuality:(int)qulity
                videoWidth:(int)video_width
               videoHeight:(int)video_height;

- (void)setConferneceMode:(int)mode;
- (void)setVideoQualityWithWidth:(int)video_width
                     videoHeight:(int)video_height;

@end
