//
//  ACNoteDetailViewController.h
//  chat
//
//  Created by 王方帅 on 14-6-3.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACNoteMessage.h"



@interface ACNoteDetailViewController : UIViewController
{
    IBOutlet UIView     *_tableHeaderView;
    IBOutlet UILabel    *_createTimeLabel;
    IBOutlet UILabel    *_contentLabel;
    IBOutlet UIView     *_locationView;
    IBOutlet UILabel    *_locationLabel;
    
    IBOutlet UITableView    *_mainTableView;
    IBOutlet UIView         *_contentView;
    
//    UIViewController                *_superVC;
    IBOutlet UIButton               *_noteButton;
    IBOutlet UILabel                *_categoryLabel;
}


@property (nonatomic,strong) ACNoteMessage      *noteMessage;
@property (nonatomic) BOOL                      isOpenHotspot;


@end
