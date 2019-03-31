//
//  AcuStartViewController.h
//  AcuConference
//
//  Created by aculearn on 13-7-25.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AcuStartViewController;

@protocol AcuStartViewControllerDelegate <NSObject>

- (void)acuStartViewControllerDidCancel:(AcuStartViewController*)controller;
- (void)acuStartViewControllerDidErrorOK;
- (void)acuStartViewControllerHasError;

@end

@interface AcuStartViewController : UIViewController


//@property (weak, nonatomic) IBOutlet UITextView *startInfo;
//@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressCtrl;

@property (weak, nonatomic) IBOutlet UILabel *labelDisplayName;
@property (weak, nonatomic) IBOutlet UILabel *labelDisplayInfo;
@property (weak, nonatomic) IBOutlet UIButton *hangUpBtn;
@property (weak, nonatomic) IBOutlet UILabel *labelHangup;

@property (nonatomic, weak) id<AcuStartViewControllerDelegate> startDelegate;

#if 0
- (void)beginQuery;
- (void)endQuery;
- (NSString*)getStatus;
- (void)addStatus:(NSString*)status;
- (void)clearStatus;
#endif

- (void)setDisplayName:(NSString*)name;
- (void)setDisplayInfo:(NSString*)info;
- (void)clearDisplayInfo;

- (void)setErrorStatus:(NSString*)status;
- (void)setConnectedStatus;

- (IBAction)didHangup:(id)sender;


@end
