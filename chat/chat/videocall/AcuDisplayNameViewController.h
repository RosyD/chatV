//
//  AcuDisplayNameViewController.h
//  AcuConference
//
//  Created by aculearn on 13-7-29.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AcuDisplayNameViewController;
@protocol AcuDisplayNameViewControllerDelegate <NSObject>

- (void)acuDisplayNameViewControllerDidCancel:(AcuDisplayNameViewController*)controller;
- (void)acuDisplayNameViewController:(AcuDisplayNameViewController*)controller didOK:(NSString*)displayName;

@end

@interface AcuDisplayNameViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *m_error;
@property (weak, nonatomic) IBOutlet UITextField *displayName;
@property (weak, nonatomic) IBOutlet UIView *displayNameView;

@property (weak, nonatomic) id<AcuDisplayNameViewControllerDelegate> diplayNameDelegate;


- (IBAction)didOK:(id)sender;
- (IBAction)didCancel:(id)sender;


@end
