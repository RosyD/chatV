//
//  ACRepeatDayCell.h
//  chat
//
//  Created by 王方帅 on 14-8-5.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>

enum RepeatDay
{
    RepeatDay_Sunday,
    RepeatDay_Monday,
    RepeatDay_Tuesday,
    RepeatDay_Wednesday,
    RepeatDay_Thursday,
    RepeatDay_Friday,
    RepeatDay_Saturday,
};

@interface ACRepeatDayCell : UITableViewCell
{
    IBOutlet UILabel    *_titleLabel;
    IBOutlet UIButton   *_selectedButton;
}

-(void)setIndex:(int)index;
-(void)setSelect:(BOOL)select;

@end
