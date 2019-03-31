//
//  AcuConferencePresentingRightViewController.m
//  videocall
//
//  Created by Aculearn on 15-1-20.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#import "AcuConferencePresentingRightViewController.h"

@interface AcuConferencePresentingRightViewController ()

@end

@implementation AcuConferencePresentingRightViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _videoCallMode = 1;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)setVideoCallMode:(int)videoCallMode
{
    _videoCallMode = videoCallMode;
    if (_videoCallMode == 0)
    {
        CGRect frame = self.view.frame;
        ///frame.size.height = 320;
        frame.size.height = kScreen_Width;
        self.view.frame = frame;
    }
}

@end
