//
//  AcuConferencePresentingRightViewController.h
//  videocall
//
//  Created by Aculearn on 15-1-20.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AcuConferencePresentingRightViewController : UIViewController

/*
 //1是1对1的视频会议， 0是多人视频会议
 */
@property (nonatomic, assign) int               videoCallMode;

- (void)setVideoCallMode:(int)videoCallMode;

@end
