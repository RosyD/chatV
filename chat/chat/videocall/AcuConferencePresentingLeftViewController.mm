//
//  AcuConferencePresentingLeftViewController.m
//  AcuConference
//
//  Created by aculearn on 13-7-12.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import "AcuConferencePresentingLeftViewController.h"
#import "AcuParticipantCell.h"
#import "AcuParticipantInfo.h"
#import "KxMenu.h"
#import "UIPopoverListView.h"
#include "conf_api_define.h"


#define Acu_Participant_Icon_Prefix			@"list%02d.png"

@interface AcuConferencePresentingLeftViewController () <UIGestureRecognizerDelegate,
                                                        UIPopoverListViewDataSource,
                                                        UIPopoverListViewDelegate>

@end

@implementation AcuConferencePresentingLeftViewController
{
    int                     _nMenuParticipantID;
    
    BOOL                    _bModerator;
    
    int                     _nConferenceMode;
    NSMutableArray          *_arrayConferenceMode;
    UIPopoverListView       *_conferenceModePop;
    
    int                     _nVideoQuality;
    NSMutableArray          *_arrayVideoQuality;
    UIPopoverListView       *_videoQualityPop;
    NSUInteger              _nVideoQualityPos;
}

@synthesize conferenceParticipantList;
@synthesize participantList;
@synthesize participantListMenuDelegate;
@synthesize conferenceCommandDelegate;
@synthesize conferenceModeBtn;
@synthesize videoQualityBtn;

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
        CGRect frame = self.participantLabel.frame;
        frame.origin.y += 20;
        self.participantLabel.frame = frame;
        
        frame = self.participantList.frame;
        frame.origin.y += 20;
        self.participantList.frame = frame;
        
        
        
		self.edgesForExtendedLayout = UIRectEdgeNone;
	}
	
	// Do any additional setup after loading the view.
    _nMenuParticipantID = 0;

//    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self
//                                                                                       action:@selector(handleLongPress:)];
//    lpgr.minimumPressDuration = 0.3; //seconds
//    lpgr.delegate = self;
//    [self.participantList addGestureRecognizer:lpgr];
    
    _bModerator = NO;
    [conferenceModeBtn setTitle:[_arrayConferenceMode objectAtIndex:_nConferenceMode]
                       forState:UIControlStateNormal];
    [videoQualityBtn setTitle:[_arrayVideoQuality objectAtIndex:_nVideoQualityPos]
                     forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleWillShowKeyboard:)
												 name:UIKeyboardWillShowNotification
                                               object:nil];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleWillHideKeyboard:)
												 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload
{
    [self setParticipantList:nil];
    [self setParticipantLabel:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight ||
            toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
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
//    UIViewController* viewControllerA = (UIViewController*) [[self.view superview] nextResponder];
//    return [viewControllerA preferredInterfaceOrientationForPresentation];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.conferenceParticipantList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AcuParticipantCell *participantCell = [tableView dequeueReusableCellWithIdentifier:@"AcuParticipantCell"];
	
	NSString *strIconName;
	UIImage *colImage;
    if (participantCell)
    {
		AcuParticipantInfo* participantInfo = [self.conferenceParticipantList objectAtIndex:indexPath.row];
        participantCell.participantName.text = participantInfo.name;
		
		
		strIconName = [[NSString alloc] initWithFormat:Acu_Participant_Icon_Prefix, participantInfo.image_col_1+1];
		//NSLog(@"icon 1: %@", strIconName);
		colImage = [UIImage imageNamed:strIconName];
		if (colImage)
		{
			[participantCell.participantIcon1 setImage:colImage];
		}
		
		strIconName = nil;
		
		strIconName = [[NSString alloc] initWithFormat:Acu_Participant_Icon_Prefix, participantInfo.image_col_3+1];
		//NSLog(@"icon 2: %@", strIconName);
		colImage = [UIImage imageNamed:strIconName];
		if (colImage)
		{
			[participantCell.participantIcon2 setImage:colImage];
		}
		
		strIconName = nil;
		
		strIconName = [[NSString alloc] initWithFormat:Acu_Participant_Icon_Prefix, participantInfo.image_col_2+1];
		//NSLog(@"icon 3: %@", strIconName);
		colImage = [UIImage imageNamed:strIconName];
		if (colImage)
		{
			[participantCell.participantIcon3 setImage:colImage];
		}
		
		strIconName = nil;
		
		strIconName = [[NSString alloc] initWithFormat:Acu_Participant_Icon_Prefix, participantInfo.image_col_4+1];
		//NSLog(@"icon 4: %@", strIconName);
		colImage = [UIImage imageNamed:strIconName];
		if (colImage)
		{
			[participantCell.participantIcon4 setImage:colImage];
		}
		
		strIconName = nil;
		
		strIconName = [[NSString alloc] initWithFormat:Acu_Participant_Icon_Prefix, participantInfo.image_col_5+1];
		//NSLog(@"icon 5: %@", strIconName);
		colImage = [UIImage imageNamed:strIconName];
		if (colImage)
		{
			[participantCell.participantIcon5 setImage:colImage];
		}
		
		strIconName = nil;
		
//		strIconName = [[NSString alloc] initWithFormat:Acu_Participant_Icon_Prefix, participantInfo.image_col_6+1];
//		colImage = [UIImage imageNamed:strIconName];
//		if (colImage)
//		{
//			[participantCell.participantIcon6 setImage:colImage];
//		}
//		
//		strIconName = nil;
		
		
    }
    
    return participantCell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    AcuParticipantCell *participantCell = (AcuParticipantCell*)[tableView cellForRowAtIndexPath:indexPath];
    if (participantCell)
    {
        [self showParticipantMenu:indexPath.row inRect:participantCell.frame];
    }
}


- (IBAction)pressConferenceMode:(id)sender
{
    [_conferenceModePop show];
}

- (IBAction)pressVideoQuality:(id)sender
{
    [_videoQualityPop show];
}


- (void)updateParticipantList:(NSMutableArray*)newParticipantList
{
	self.conferenceParticipantList = newParticipantList;
	[self.participantList reloadData];
}

- (void)setModeratorRole:(BOOL)bModerator
{
    if (_bModerator == bModerator)
    {
        return;
    }
    
    _bModerator = bModerator;
    if (bModerator)
    {
        CGRect participantListFrame = self.participantList.frame;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            participantListFrame.size.height -= 60;
        }
        else
        {
            participantListFrame.size.height -= 40;
        }
        
        self.participantList.frame = participantListFrame;
        conferenceModeBtn.hidden = NO;
        videoQualityBtn.hidden = NO;
    }
    else
    {
        CGRect participantListFrame = self.participantList.frame;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            participantListFrame.size.height += 60;
        }
        else
        {
            participantListFrame.size.height += 40;
        }
        
        self.participantList.frame = participantListFrame;
        conferenceModeBtn.hidden = YES;
        videoQualityBtn.hidden = YES;

    }
}

- (void)initConferenceMode:(int)confMode
              videoQuality:(int)qulity
                videoWidth:(int)video_width
               videoHeight:(int)video_height
{
    _nConferenceMode = confMode;
    if (_nConferenceMode > 1)
    {
        _nConferenceMode -= 1;
    }
    
    _arrayConferenceMode = [[NSMutableArray alloc] initWithObjects:NSLocalizedString(@"Host Control", @"Participant List ConferenceMode"),
                            NSLocalizedString(@"Interactive", @"Participant List ConferenceMode"),
                            NSLocalizedString(@"Boss Secretary", @"Participant List ConferenceMode"),
                            NSLocalizedString(@"Video Conference", @"Participant List ConferenceMode"),
                            nil];
    
    
    
    _nVideoQuality = qulity;
    
    _arrayVideoQuality = [[NSMutableArray alloc] init];
    
    if (_nVideoQuality >= 0)
    {
        [_arrayVideoQuality addObject:NSLocalizedString(@"640x480", @"Participant List Video Quality")];
    }
    if (_nVideoQuality >= 1)
    {
        [_arrayVideoQuality addObject:NSLocalizedString(@"800x600", @"Participant List Video Quality")];
    }
    if (_nVideoQuality >= 2)
    {
        [_arrayVideoQuality addObject:NSLocalizedString(@"960x720", @"Participant List Video Quality")];
    }
    if (_nVideoQuality >= 3)
    {
        [_arrayVideoQuality addObject:NSLocalizedString(@"1280x720", @"Participant List Video Quality")];
    }
    if (_nVideoQuality >= 4)
    {
        [_arrayVideoQuality addObject:NSLocalizedString(@"1920x1080", @"Participant List Video Quality")];
    }
    
    _nVideoQualityPos = 0;
    
    NSUInteger pos = 0;
    if( video_width== 1920 && video_height == 1080 )
    {
        pos = [_arrayVideoQuality indexOfObject:@"1920x1080"];
        if (pos != NSNotFound)
        {
            _nVideoQualityPos = pos;
        }
    }
    else if( video_width== 1280 && video_height == 720 )
    {
        pos = [_arrayVideoQuality indexOfObject:@"1280x720"];
        if (pos != NSNotFound)
        {
            _nVideoQualityPos = pos;
        }
    }
    else if( video_width== 960 && video_height == 720 )
    {
        pos = [_arrayVideoQuality indexOfObject:@"960x720"];
        if (pos != NSNotFound)
        {
            _nVideoQualityPos = pos;
        }
    }
    else if( video_width== 800 && video_height == 600 )
    {
        pos = [_arrayVideoQuality indexOfObject:@"800x600"];
        if (pos != NSNotFound)
        {
            _nVideoQualityPos = pos;
        }
    }
    else if( video_width== 640 && video_height == 480 )
    {
        pos = [_arrayVideoQuality indexOfObject:@"640x480"];
        if (pos != NSNotFound)
        {
            _nVideoQualityPos = pos;
        }
    }
    
    CGSize size;
    size.width = 240.0f;
    size.height = 240.0f;
    
    _conferenceModePop = [[UIPopoverListView alloc] initWithSize:size];
    _conferenceModePop.delegate = self;
    _conferenceModePop.datasource = self;
    _conferenceModePop.listView.scrollEnabled = FALSE;
    [_conferenceModePop setTitle:NSLocalizedString(@"Conference Mode", @"Participant List ConferenceMode")];
    
    
    _videoQualityPop = [[UIPopoverListView alloc] initWithSize:size];
    _videoQualityPop.delegate = self;
    _videoQualityPop.datasource = self;
    _videoQualityPop.listView.scrollEnabled = FALSE;
    [_videoQualityPop setTitle:NSLocalizedString(@"Conference Quality", @"Participant List VideoQuality")];
    
}

- (void)setConferneceMode:(int)mode
{
    int nTempMode = mode;
    if (nTempMode > 1)
    {
        nTempMode -= 1;
    }
    
    if (_nConferenceMode != nTempMode)
    {
        _nConferenceMode = nTempMode;
        [conferenceModeBtn setTitle:[_arrayConferenceMode objectAtIndex:_nConferenceMode]
                           forState:UIControlStateNormal];
    }
}

- (void)setVideoQualityWithWidth:(int)video_width
                     videoHeight:(int)video_height
{
    NSUInteger pos = 0;
    if( video_width== 1920 && video_height == 1080 )
    {
        pos = [_arrayVideoQuality indexOfObject:@"1920x1080"];
        if (pos != NSNotFound)
        {
            _nVideoQualityPos = pos;
            [videoQualityBtn setTitle:[_arrayVideoQuality objectAtIndex:pos]
                             forState:UIControlStateNormal];
        }
    }
    else if( video_width== 1280 && video_height == 720 )
    {
        pos = [_arrayVideoQuality indexOfObject:@"1280x720"];
        if (pos != NSNotFound)
        {
            _nVideoQualityPos = pos;
            [videoQualityBtn setTitle:[_arrayVideoQuality objectAtIndex:pos]
                             forState:UIControlStateNormal];
        }
    }
    else if( video_width== 960 && video_height == 720 )
    {
        pos = [_arrayVideoQuality indexOfObject:@"960x720"];
        if (pos != NSNotFound)
        {
            _nVideoQualityPos = pos;
            [videoQualityBtn setTitle:[_arrayVideoQuality objectAtIndex:pos]
                             forState:UIControlStateNormal];
        }
    }
    else if( video_width== 800 && video_height == 600 )
    {
        pos = [_arrayVideoQuality indexOfObject:@"800x600"];
        if (pos != NSNotFound)
        {
            _nVideoQualityPos = pos;
            [videoQualityBtn setTitle:[_arrayVideoQuality objectAtIndex:pos]
                             forState:UIControlStateNormal];
        }
    }
    else if( video_width== 640 && video_height == 480 )
    {
        pos = [_arrayVideoQuality indexOfObject:@"640x480"];
        if (pos != NSNotFound)
        {
            _nVideoQualityPos = pos;
            [videoQualityBtn setTitle:[_arrayVideoQuality objectAtIndex:pos]
                             forState:UIControlStateNormal];
        }
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
    
    if ([popoverListView isEqual:_conferenceModePop])
    {
        cell.textLabel.text = [_arrayConferenceMode objectAtIndex:row];
        
        if (_nConferenceMode == row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    else if ([popoverListView isEqual:_videoQualityPop])
    {
        cell.textLabel.text = [_arrayVideoQuality objectAtIndex:row];
        
        if (_nVideoQualityPos == row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    
    return cell;
}

- (NSInteger)popoverListView:(UIPopoverListView *)popoverListView
       numberOfRowsInSection:(NSInteger)section
{
    if ([popoverListView isEqual:_conferenceModePop])
    {
        return [_arrayConferenceMode count];
    }
    else if ([popoverListView isEqual:_videoQualityPop])
    {
        return [_arrayVideoQuality count];
    }
    return 0;
}

#pragma mark - UIPopoverListViewDelegate
- (void)popoverListView:(UIPopoverListView *)popoverListView
     didSelectIndexPath:(NSIndexPath *)indexPath
{
    int row = (int)indexPath.row;
    
    if ([popoverListView isEqual:_conferenceModePop])
    {
        if (_nConferenceMode != row)
        {
            [conferenceModeBtn setTitle:[_arrayConferenceMode objectAtIndex:row]
                               forState:UIControlStateNormal];
            _nConferenceMode = row;
            
            int nTempMode = row;
            if (nTempMode > 1)
            {
                nTempMode++;
            }
            
            NSMutableDictionary *commandDict = [NSMutableDictionary new];
            [commandDict setValue:[NSNumber numberWithInt:nTempMode] forKey:@"mode"];
            
            NSError *error = nil;
            NSData *commandData = [NSJSONSerialization dataWithJSONObject:commandDict
                                                                  options:NSJSONWritingPrettyPrinted
                                                                    error:&error];
            
            const char *commandJsonData = (const char*)[commandData bytes];
            [self.conferenceCommandDelegate acuConferenceSendCommand:cmd_change_conf_mode
                                                            withInfo:commandJsonData];
            
            [commandDict removeAllObjects];
            commandDict = nil;
        }
        
    }
    else if ([popoverListView isEqual:_videoQualityPop])
    {
        if (_nVideoQualityPos != row)
        {
            [videoQualityBtn setTitle:[_arrayVideoQuality objectAtIndex:row]
                             forState:UIControlStateNormal];
            _nVideoQualityPos = row;
            
            int videoWidth = 0;
            int videoHeight = 0;
            if (_nVideoQualityPos == 0)
            {
                videoWidth = 648;
                videoHeight = 480;
            }
            else if(_nVideoQualityPos == 1)
            {
                videoWidth = 800;
                videoHeight = 600;
            }
            else if(_nVideoQualityPos == 2)
            {
                videoWidth = 960;
                videoHeight = 720;
            }
            else if(_nVideoQualityPos == 3)
            {
                videoWidth = 1280;
                videoHeight = 720;
            }
            else if(_nVideoQualityPos == 4)
            {
                videoWidth = 1920;
                videoHeight = 1080;
            }
            
            
            NSMutableDictionary *commandDict = [NSMutableDictionary new];
            [commandDict setValue:[NSNumber numberWithInt:videoWidth] forKey:@"video_width"];
            [commandDict setValue:[NSNumber numberWithInt:videoHeight] forKey:@"video_height"];
            
            NSError *error = nil;
            NSData *commandData = [NSJSONSerialization dataWithJSONObject:commandDict
                                                                  options:NSJSONWritingPrettyPrinted
                                                                    error:&error];
            
            const char *commandJsonData = (const char*)[commandData bytes];
            [self.conferenceCommandDelegate acuConferenceSendCommand:cmd_change_room_video_size
                                                            withInfo:commandJsonData];
            
            [commandDict removeAllObjects];
            commandDict = nil;
        }
    }
}

- (CGFloat)popoverListView:(UIPopoverListView *)popoverListView
   heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40.0f;
}

#pragma mark ----Others----

//-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
//{
//    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
//    {
//        CGPoint p = [gestureRecognizer locationInView:self.participantList];
//        
//        NSIndexPath *indexPath = [self.participantList indexPathForRowAtPoint:p];
//        if (indexPath == nil)
//        {
//            NSLog(@"long press on table view but not on a row");
//        }
//        else
//        {
//            NSLog(@"long press on table view at row %d", indexPath.row);
//
//            if (self.participantListMenuDelegate)
//            {
//#if 1
//                AcuParticipantInfo* participantInfo = [self.conferenceParticipantList objectAtIndex:indexPath.row];
//                bool bRet = false;
//                char *pMenuData = 0;
//                _nMenuParticipantID = participantInfo.nId;
//                [self.participantListMenuDelegate getParticipantListMenu:_nMenuParticipantID
//                                                                menuData:&pMenuData];
//                if (!bRet || pMenuData == 0)
//                {
//                    return;
//                }
//                
//                NSString *jsonString = [NSString stringWithUTF8String:pMenuData];
//                NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
//                NSMutableDictionary *menuData = [NSJSONSerialization JSONObjectWithData:jsonData
//                                                                                    options:NSJSONReadingMutableContainers
//                                                                                      error:nil];
//                
//                NSUInteger index = 0;
//                NSMutableArray *menuItems = [NSMutableArray new];
//                for(NSString *menuDataItem in menuData)
//                {
//                    KxMenuItem *menuItem = [KxMenuItem menuItem:NSLocalizedString(menuDataItem, @"Participant List Menu Item")
//                                                          image:nil
//                                                          index:index
//                                                         target:self
//                                                        action:@selector(doParticipantMenu:)];
//                    [menuItems addObject:menuItem];
//                    index++;
//                }
//            
//            
//                if ([menuItems count] == 0)
//                {
//                    return;
//                }
//#else
//                NSArray *menuItems =
//                @[
//                  [KxMenuItem menuItem:NSLocalizedString(@"Invite to present", @"Participant List Menu Item")
//                                 image:nil
//                                 index:0
//                                target:self
//                                action:@selector(doParticipantMenu:)],
//                  
//                  [KxMenuItem menuItem:NSLocalizedString(@"Set as secretary", @"Participant List Menu Item")
//                                 image:nil
//                                 index:1
//                                target:self
//                                action:@selector(doParticipantMenu:)],
//                  [KxMenuItem menuItem:NSLocalizedString(@"Set as host", @"Participant List Menu Item")
//                                 image:nil
//                                 index:2
//                                target:self
//                                action:@selector(doParticipantMenu:)],
//                  [KxMenuItem menuItem:NSLocalizedString(@"Set as boss", @"Participant List Menu Item")
//                                 image:nil
//                                 index:3
//                                target:self
//                                action:@selector(doParticipantMenu:)],
//                  [KxMenuItem menuItem:NSLocalizedString(@"Set as Co-host", @"Participant List Menu Item")
//                                 image:nil
//                                 index:4
//                                target:self
//                                action:@selector(doParticipantMenu:)],
//                  [KxMenuItem menuItem:NSLocalizedString(@"Take presenter control", @"Participant List Menu Item")
//                                 image:nil
//                                 index:5
//                                target:self
//                                action:@selector(doParticipantMenu:)],
//                  [KxMenuItem menuItem:NSLocalizedString(@"Set as presenter", @"Participant List Menu Item")
//                                 image:nil
//                                 index:6
//                                target:self
//                                action:@selector(doParticipantMenu:)],
//                  [KxMenuItem menuItem:NSLocalizedString(@"Invite to speak", @"Participant List Menu Item")
//                                 image:nil
//                                 index:7
//                                target:self
//                                action:@selector(doParticipantMenu:)],
//                  [KxMenuItem menuItem:NSLocalizedString(@"Invite to present", @"Participant List Menu Item")
//                                 image:nil
//                                 index:8
//                                target:self
//                                action:@selector(doParticipantMenu:)],
//                  [KxMenuItem menuItem:NSLocalizedString(@"Set as participant", @"Participant List Menu Item")
//                                 image:nil
//                                 index:9
//                                target:self
//                                action:@selector(doParticipantMenu:)],
//                  [KxMenuItem menuItem:NSLocalizedString(@"Grant", @"Participant List Menu Item")
//                                 image:nil
//                                 index:10
//                                target:self
//                                action:@selector(doParticipantMenu:)],
//                  [KxMenuItem menuItem:NSLocalizedString(@"Revoke", @"Participant List Menu Item")
//                                 image:nil
//                                 index:11
//                                target:self
//                                action:@selector(doParticipantMenu:)],
//                  [KxMenuItem menuItem:NSLocalizedString(@"Kick Out", @"Participant List Menu Item")
//                                 image:nil
//                                 index:12
//                                target:self
//                                action:@selector(doParticipantMenu:)],
//                  [KxMenuItem menuItem:NSLocalizedString(@"Lock", @"Participant List Menu Item")
//                                 image:nil
//                                 index:13
//                                target:self
//                                action:@selector(doParticipantMenu:)],
//                  [KxMenuItem menuItem:NSLocalizedString(@"Unlock", @"Participant List Menu Item")
//                                 image:nil
//                                 index:14
//                                target:self
//                                action:@selector(doParticipantMenu:)],
//                  ];
//#endif
//                CGRect r;
//                r.origin.x = p.x;
//                r.origin.y = p.y;
//                r.size.width = 0;
//                r.size.height = 0;
//                
//                [KxMenu showMenuInView:self.participantList
//                              fromRect:r
//                             menuItems:menuItems];
//                
//            }
//        }
//    }
//    
//}

- (void)showParticipantMenu:(NSInteger)participantIndex inRect:(CGRect)frame
{
    if (self.participantListMenuDelegate)
    {
#if 1
        AcuParticipantInfo* participantInfo = [self.conferenceParticipantList objectAtIndex:participantIndex];
        bool bRet = false;
        char pMenuData[2048];
        memset(pMenuData, 0, 2048);
        _nMenuParticipantID = participantInfo.nId;
        bRet = [self.participantListMenuDelegate getParticipantListMenu:_nMenuParticipantID
                                                        menuData:pMenuData
                                                         dataLen:2048];
        if (!bRet)
        {
            return;
        }
        
        NSString *jsonString = [NSString stringWithUTF8String:pMenuData];
        if (!jsonString)
        {
            return;
        }
        
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        if (!jsonData)
        {
            return;
        }
        
        NSArray *menuInfoArray = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                 options:NSJSONReadingMutableContainers
                                                                   error:nil];
        if (!menuInfoArray)
        {
            return;
        }
        
        NSMutableArray *menuItems = [NSMutableArray new];
        for(NSDictionary* menuItemInfo in menuInfoArray)
        {
            NSString *menuItemLabel = menuItemInfo[@"menu_label"];
            int cmdId = [menuItemInfo[@"menu_comm_id"] intValue];
            KxMenuItem *menuItem = [KxMenuItem menuItem:NSLocalizedString(menuItemLabel, @"Participant List Menu Item")
                                                  image:nil
                                                  index:cmdId
                                                 target:self
                                                 action:@selector(doParticipantMenu:)];
            [menuItems addObject:menuItem];
        }
        
        
        if ([menuItems count] == 0)
        {
            return;
        }
#else
        NSArray *menuItems =
        @[
          [KxMenuItem menuItem:NSLocalizedString(@"Invite to present", @"Participant List Menu Item")
                         image:nil
                         index:0
                        target:self
                        action:@selector(doParticipantMenu:)],
          
          [KxMenuItem menuItem:NSLocalizedString(@"Set as secretary", @"Participant List Menu Item")
                         image:nil
                         index:1
                        target:self
                        action:@selector(doParticipantMenu:)],
          [KxMenuItem menuItem:NSLocalizedString(@"Set as host", @"Participant List Menu Item")
                         image:nil
                         index:2
                        target:self
                        action:@selector(doParticipantMenu:)],
          [KxMenuItem menuItem:NSLocalizedString(@"Set as boss", @"Participant List Menu Item")
                         image:nil
                         index:3
                        target:self
                        action:@selector(doParticipantMenu:)],
          [KxMenuItem menuItem:NSLocalizedString(@"Set as Co-host", @"Participant List Menu Item")
                         image:nil
                         index:4
                        target:self
                        action:@selector(doParticipantMenu:)],
          [KxMenuItem menuItem:NSLocalizedString(@"Take presenter control", @"Participant List Menu Item")
                         image:nil
                         index:5
                        target:self
                        action:@selector(doParticipantMenu:)],
          [KxMenuItem menuItem:NSLocalizedString(@"Set as presenter", @"Participant List Menu Item")
                         image:nil
                         index:6
                        target:self
                        action:@selector(doParticipantMenu:)],
          [KxMenuItem menuItem:NSLocalizedString(@"Invite to speak", @"Participant List Menu Item")
                         image:nil
                         index:7
                        target:self
                        action:@selector(doParticipantMenu:)],
          [KxMenuItem menuItem:NSLocalizedString(@"Invite to present", @"Participant List Menu Item")
                         image:nil
                         index:8
                        target:self
                        action:@selector(doParticipantMenu:)],
          [KxMenuItem menuItem:NSLocalizedString(@"Set as participant", @"Participant List Menu Item")
                         image:nil
                         index:9
                        target:self
                        action:@selector(doParticipantMenu:)],
          [KxMenuItem menuItem:NSLocalizedString(@"Grant", @"Participant List Menu Item")
                         image:nil
                         index:10
                        target:self
                        action:@selector(doParticipantMenu:)],
          [KxMenuItem menuItem:NSLocalizedString(@"Revoke", @"Participant List Menu Item")
                         image:nil
                         index:11
                        target:self
                        action:@selector(doParticipantMenu:)],
          [KxMenuItem menuItem:NSLocalizedString(@"Kick Out", @"Participant List Menu Item")
                         image:nil
                         index:12
                        target:self
                        action:@selector(doParticipantMenu:)],
          [KxMenuItem menuItem:NSLocalizedString(@"Lock", @"Participant List Menu Item")
                         image:nil
                         index:13
                        target:self
                        action:@selector(doParticipantMenu:)],
          [KxMenuItem menuItem:NSLocalizedString(@"Unlock", @"Participant List Menu Item")
                         image:nil
                         index:14
                        target:self
                        action:@selector(doParticipantMenu:)],
          ];
#endif
        CGRect r;
        r.origin.x = frame.origin.x + frame.size.width/2;
        r.origin.y = frame.origin.y + frame.size.height/2;
        r.size.width = 0;
        r.size.height = 0;
        
        [KxMenu showMenuInView:self.participantList
                      fromRect:r
                     menuItems:menuItems];
        
    }
}

- (void)doParticipantMenu:(KxMenuItem*)sender
{
    if (self.participantListMenuDelegate && sender)
    {
        NSDictionary * parameters = @{
                                      @"user_id":[NSNumber numberWithInt:_nMenuParticipantID]
                                      };
        NSError *error = nil;
		NSData *commandData = [NSJSONSerialization dataWithJSONObject:parameters
															  options:NSJSONWritingPrettyPrinted
																error:&error];
		
		const char *commandJsonData = (const char*)[commandData bytes];

        
        [self.participantListMenuDelegate sendMenuCommand:(int)sender.index cmdInfo:commandJsonData];
    }
}

- (void)handleWillShowKeyboard:(NSNotification *)notification
{
    [KxMenu dismissMenu];
}

- (void)handleWillHideKeyboard:(NSNotification *)notification
{
    [KxMenu dismissMenu];
}


@end
