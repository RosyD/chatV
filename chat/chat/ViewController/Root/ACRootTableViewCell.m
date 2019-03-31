//
//  ACRootTableViewCell.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-27.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACRootTableViewCell.h"

@implementation ACRootTableViewCell


-(void)setSelect:(BOOL)selected
{
    if (selected)
    {
        [self setBackgroundColor:[UIColor colorWithRed:84/255.0 green:111/255.0 blue:151/255.0 alpha:1]];
    }
    else
    {
        [self setBackgroundColor:nil];
    }
}

-(void)setRow:(int)row
{
    switch (row)
    {
        case ACCenterViewControllerType_All:
        {
            _iconImageView.image = [UIImage imageNamed:@"slide_all_iv.png"];
            _titleLabel.text = kAll;
        }
            break;
        case ACCenterViewControllerType_Chat:
        {
            _iconImageView.image = [UIImage imageNamed:@"slide_chat_iv.png"];
            _titleLabel.text = NSLocalizedString(@"Chat", nil);
        }
            break;
        case ACCenterViewControllerType_Event:
        {
            _iconImageView.image = [UIImage imageNamed:@"slide_event_iv.png"];
            _titleLabel.text = NSLocalizedString(@"Event", nil);
        }
            break;
        case ACCenterViewControllerType_Survey:
        {
            _iconImageView.image = [UIImage imageNamed:@"slide_survey_iv.png"];
            _titleLabel.text = NSLocalizedString(@"Survey", nil);
        }
            break;
        case ACCenterViewControllerType_Link:
        {
            _iconImageView.image = [UIImage imageNamed:@"slide_link_iv.png"];
            _titleLabel.text = NSLocalizedString(@"Link", nil);
        }
            break;
        case ACCenterViewControllerType_Page:
        {
            _iconImageView.image = [UIImage imageNamed:@"slide_page_iv.png"];
            _titleLabel.text = NSLocalizedString(@"Webpage", nil);
        }
            break;
        case ACCenterViewControllerType_Services:
        {
            _iconImageView.image = [UIImage imageNamed:@"services.png"];
            _titleLabel.text = NSLocalizedString(@"Services", nil);
        }
            break;
        case ACCenterViewControllerType_Setting:
        {
            _iconImageView.image = [UIImage imageNamed:@"slide_setting_iv.png"];
            _titleLabel.text = kSetting;
        }
            break;
            
        default:
        {
            _iconImageView.image = nil;
            _titleLabel.text = @"";
        }
            break;
    }

}

@end
