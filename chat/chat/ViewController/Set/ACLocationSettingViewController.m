//
//  ACLocationSettingViewController.m
//  chat
//
//  Created by 王方帅 on 14-6-17.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACLocationSettingViewController.h"
#import "UIView+Additions.h"
#import "ACConfigs.h"
#import "UINavigationController+Additions.h"
#import "ACRepeatDayController.h"

#define kAm9Date    [NSDate dateWithTimeIntervalSince1970:1*3600]
#define kPm6Date    [NSDate dateWithTimeIntervalSince1970:10*3600]

@interface ACLocationSettingViewController ()

@end

@implementation ACLocationSettingViewController

AC_MEM_Dealloc_implementation


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
    // Do any additional setup after loading the view from its nib.
//    _datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, 320, 162)];
//    _datePicker.datePickerMode = UIDatePickerModeTime;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL alldaySwitch = ![defaults boolForKey:kLocationAllDayClose];
    
    _alldaySwitch.on = alldaySwitch;
    
    _weekLabel.text = [[ACConfigs shareConfigs] getWeekTitle];
    
    [self alldaySwitchValueChange];
    
    _repeatLable.text   =   NSLocalizedString(@"Repeat", nil);
    _allDayLable.text   =   NSLocalizedString(@"All Day", nil);
    _titleLable.text   =   NSLocalizedString(@"Location Settings", nil);
    [_promptLabel setText:NSLocalizedString(@"Set location report time", nil)];
    [_beginTimeLabel setText:NSLocalizedString(@"Report Begin", nil)];
    [_endTimeLabel setText:NSLocalizedString(@"Report End", nil)];
    
    NSDate *date = [defaults objectForKey:kLocationStartTime];
    if (date)
    {
        _startTimeLabel.text = [self getTimeWithDate:date];
    }
    else
    {
        _startTimeLabel.text = [NSString stringWithFormat:@"09:00 %@",NSLocalizedString(@"am", nil)];
        [defaults setObject:kAm9Date forKey:kLocationStartTime];
    }
    
    date = [defaults objectForKey:kLocationStopTime];
    if (date)
    {
        _stopTimeLabel.text = [self getTimeWithDate:date];
    }
    else
    {
        _stopTimeLabel.text = [NSString stringWithFormat:@"06:00 %@",NSLocalizedString(@"pm", nil)];
        [defaults setObject:kPm6Date forKey:kLocationStopTime];
    }
    [defaults synchronize];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self initHotspot];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initHotspot];
}

-(void)alldaySwitchValueChange
{
    if (_alldaySwitch.on)
    {
        [_startTimeView setHidden:YES];
        [_stopTimeView setHidden:YES];
        [_promptLabel setHidden:NO];
        [_alldayView setFrame_height:84];
        [_alldayLineView setFrame_y:_alldayView.size.height-1];
    }
    else
    {
        [_startTimeView setHidden:NO];
        [_stopTimeView setHidden:NO];
        [_promptLabel setHidden:YES];
        [_alldayView setFrame_height:60];
        [_alldayLineView setFrame_y:_alldayView.size.height-1];
    }
}

#pragma mark -IBAction
-(IBAction)goback:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)locationButtonTouchUp:(id)sender
{
    _locationState = locationState_None;
    _alldaySwitch.on = !_alldaySwitch.on;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:!_alldaySwitch.on forKey:kLocationAllDayClose];
    [defaults synchronize];
    
    [self alldaySwitchValueChange];
}

-(IBAction)alldaySwitchValueChange:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:!_alldaySwitch.on forKey:kLocationAllDayClose];
    [defaults synchronize];
    
    [self alldaySwitchValueChange];
}

-(IBAction)startTimeButtonTouchUp:(id)sender
{
    _locationState = locationState_StartTime;
    
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSDate *date = [defaults objectForKey:kLocationStartTime];
//    if (date)
//    {
//        _datePicker.date = date;
//    }
//    else
//    {
//        _datePicker.date = [NSDate dateWithTimeIntervalSince1970:1*3600];
//    }
    
    [self showAlert];
}

-(IBAction)stopTimeButtonTouchUp:(id)sender
{
    _locationState = locationState_StopTime;
    
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSDate *date = [defaults objectForKey:kLocationStopTime];
//    if (date)
//    {
//        _datePicker.date = date;
//    }
//    else
//    {
//        _datePicker.date = [NSDate dateWithTimeIntervalSince1970:10*3600];
//    }
    
    [self showAlert];
}

-(IBAction)repeatButtonTouchUp:(id)sender
{
    ACRepeatDayController *repeatDayC = [[ACRepeatDayController alloc] init];
    AC_MEM_Alloc(repeatDayC);
    repeatDayC.superVC = self;
    [self.navigationController pushViewController:repeatDayC animated:YES];
}

#pragma mark -alertView
-(void)showAlert
{
   /// UIDatePicker *_datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, 320, 162)];
    
    UIDatePicker *_datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, kScreen_Width, 162)];
    _datePicker.datePickerMode = UIDatePickerModeTime;

    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDate *date = [defaults objectForKey:locationState_StartTime==_locationState?kLocationStartTime:kLocationStopTime];
        if(nil==date){
            date =  [NSDate dateWithTimeIntervalSince1970:(locationState_StartTime==_locationState?1:10)*3600];
        }
        _datePicker.date =  date;
    }

    CXAlertView *alert = [[CXAlertView alloc] initWithTitle:NSLocalizedString(@"Select time", nil) contentView:_datePicker cancelButtonTitle:NSLocalizedString(@"Cancel", nil)];
    
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)
                         type:CXAlertViewButtonTypeDefault
                      handler:^(CXAlertView *alertView, CXAlertButtonItem *button) {
                          // Dismiss alertview
                          [alertView dismiss];
                          NSDate *date = _datePicker.date;
                          
                          NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                          if (_locationState == locationState_StartTime)
                          {
                              [defaults setObject:date forKey:kLocationStartTime];
                              _startTimeLabel.text = [self getTimeWithDate:date];
                          }
                          else if (_locationState == locationState_StopTime)
                          {
                              [defaults setObject:date forKey:kLocationStopTime];
                              _stopTimeLabel.text = [self getTimeWithDate:date];
                          }
                          [defaults synchronize];
                      }];
    [alert show];
}

-(NSString *)getTimeWithDate:(NSDate *)date
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps  = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:date];
    NSInteger hour = [comps hour];
    NSInteger min = [comps minute];
    BOOL isAm = (hour/12) == 0;
    hour %= 12;
    NSString *time = [NSString stringWithFormat:@"%02ld:%02ld %@",(long)hour,(long)min,isAm?NSLocalizedString(@"am", nil):NSLocalizedString(@"pm", nil)];
    return time;
}

-(void)setWeekTitle:(NSString *)weekTitle
{
    _weekLabel.text = weekTitle;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
