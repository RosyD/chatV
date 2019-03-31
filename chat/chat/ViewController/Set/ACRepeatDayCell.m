//
//  ACRepeatDayCell.m
//  chat
//
//  Created by 王方帅 on 14-8-5.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACRepeatDayCell.h"

@implementation ACRepeatDayCell


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setIndex:(int)index
{
    NSString *title = nil;
    switch (index)
    {
        case RepeatDay_Sunday:
        {
            title = NSLocalizedString(@"Sunday",nil);
        }
            break;
        case RepeatDay_Monday:
        {
            title = NSLocalizedString(@"Monday",nil);
        }
            break;
        case RepeatDay_Tuesday:
        {
            title = NSLocalizedString(@"Tuesday",nil);
        }
            break;
        case RepeatDay_Wednesday:
        {
            title = NSLocalizedString(@"Wednesday",nil);
        }
            break;
        case RepeatDay_Thursday:
        {
            title = NSLocalizedString(@"Thursday",nil);
        }
            break;
        case RepeatDay_Friday:
        {
            title = NSLocalizedString(@"Friday",nil);
        }
            break;
        case RepeatDay_Saturday:
        {
            title = NSLocalizedString(@"Saturday",nil);
        }
            break;
        default:
            break;
    }
    [_titleLabel setText:title];
}

-(void)setSelect:(BOOL)select
{
    [_selectedButton setSelected:select];
}

@end
