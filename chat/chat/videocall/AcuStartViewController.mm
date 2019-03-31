//
//  AcuOPRViewController.m
//  AcuConference
//
//  Created by aculearn on 13-7-25.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import "AcuStartViewController.h"

@interface AcuStartViewController ()

@end

@implementation AcuStartViewController

//@synthesize startInfo;
//@synthesize progressCtrl;
@synthesize labelDisplayName;
@synthesize labelDisplayInfo;
@synthesize hangUpBtn;
@synthesize labelHangup;
@synthesize startDelegate;

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
	// Do any additional setup after loading the view.
	//for ios7
	if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
	{
		self.edgesForExtendedLayout = UIRectEdgeNone;
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload
{
//    [self setStartInfo:nil];
//    [self setProgressCtrl:nil];
    [self setHangUpBtn:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        return YES;
    }
    
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        return YES;
    }
    
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        return UIInterfaceOrientationMaskAll;
    }
    
    return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)didHangup:(id)sender
{
    if (self.startDelegate)
    {
        [self.startDelegate acuStartViewControllerDidCancel:self];
    }
}

#if 0
- (void)beginQuery
{
    self.progressCtrl.hidden = NO;
}
- (void)endQuery
{
    self.progressCtrl.hidden = YES;
}

- (NSString*)getStatus
{
    return self.startInfo.text;
}

- (void)addStatus:(NSString*)status
{
    NSMutableString *msg = [[NSMutableString alloc] initWithString:self.startInfo.text];
	if ([msg length] > 0)
	{
		[msg appendString:@"\n"];
	}
    [msg appendString:status];
    self.startInfo.textColor = [UIColor whiteColor];
    self.startInfo.text = [NSString stringWithString:msg];
}

- (void)clearStatus
{
    self.startInfo.text = @"";
}
#endif

- (void)setDisplayName:(NSString*)name
{
    labelDisplayName.text = name;
}

- (void)setDisplayInfo:(NSString*)info
{
    labelDisplayInfo.text = info;
}
- (void)clearDisplayInfo
{
    labelDisplayInfo.text = @"";
}

- (void)setErrorStatus:(NSString*)status
{
#if 0
    self.startInfo.textColor = [UIColor redColor];
    self.startInfo.text = status;
    self.progressCtrl.hidden = YES;
#endif
    labelDisplayInfo.textColor = [UIColor redColor];
    labelDisplayInfo.text = status;

    if (self.startDelegate)
    {
        [self.startDelegate acuStartViewControllerHasError];
    }
}

- (void)setConnectedStatus
{
    labelHangup.enabled = NO;
    hangUpBtn.enabled = NO;
    labelDisplayInfo.text = NSLocalizedString(@"Connected", @"Start Conference Tips");
}

@end
