//
//  ACLocationSettingViewController.h
//  chat
//
//  Created by 王方帅 on 14-6-17.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CXAlertView.h"

#define kLocationStartTime      @"locationStartTime"
#define kLocationStopTime       @"locationStopTime"
#define kLocationAllDayClose     @"locationAllDayClose"

enum locationState
{
    locationState_None,
    locationState_StartTime,
    locationState_StopTime,
};

@interface ACLocationSettingViewController : UIViewController
{
//    UIDatePicker        *_datePicker;
    enum locationState  _locationState;
    
    __weak IBOutlet UILabel    *_startTimeLabel;
    __weak IBOutlet UILabel    *_stopTimeLabel;
    __weak IBOutlet UISwitch   *_alldaySwitch;
    
    __weak IBOutlet UIView     *_startTimeView;
    __weak IBOutlet UIView     *_stopTimeView;
    
    __weak IBOutlet UILabel    *_promptLabel;
    __weak IBOutlet UIView     *_alldayView;
    __weak IBOutlet UIView     *_alldayLineView;
    
    __weak IBOutlet UILabel    *_beginTimeLabel;
    __weak IBOutlet UILabel    *_endTimeLabel;
    
    __weak IBOutlet UILabel    *_weekLabel;
    
    
    __weak IBOutlet UILabel *_repeatLable;
    __weak IBOutlet UILabel *_allDayLable;
    __weak IBOutlet UILabel *_titleLable;
}

@property (nonatomic) BOOL                      isOpenHotspot;

-(void)setWeekTitle:(NSString *)weekTitle;

@end
