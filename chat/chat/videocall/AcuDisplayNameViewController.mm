//
//  AcuDisplayNameViewController.m
//  AcuConference
//
//  Created by aculearn on 13-7-29.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import "AcuDisplayNameViewController.h"

@interface AcuDisplayNameViewController ()

@end

@implementation AcuDisplayNameViewController

@synthesize displayName;
@synthesize diplayNameDelegate;

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
	//for ios7
	if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
	{
		self.edgesForExtendedLayout = UIRectEdgeNone;
	}
	
	// Do any additional setup after loading the view.
    self.m_error.text = NSLocalizedString(@"Please Input Display Name", @"Start Conference Display Name");
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTappedBackground:)];
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setDisplayName:nil];
    [self setM_error:nil];
    [self setDisplayNameView:nil];
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

- (void)didTappedBackground:(id) sender
{
    [self.view endEditing:YES];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self didOK:self];
    
    return YES; // We do not want UITextField to insert line-breaks.
}

- (IBAction)didOK:(id)sender
{
    [self.view endEditing:YES];
    
    if (displayName.text.length == 0)
    {
        self.m_error.textColor = [UIColor redColor];
        self.m_error.text = NSLocalizedString(@"Display Name cannot be empty!", @"Start Conference Display Name");
        return;
    }
    
    if (self.diplayNameDelegate)
    {
        [self.diplayNameDelegate acuDisplayNameViewController:self didOK:self.displayName.text];
    }
}

- (IBAction)didCancel:(id)sender
{
    if (self.diplayNameDelegate)
    {
        [self.diplayNameDelegate acuDisplayNameViewControllerDidCancel:self];
    }
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    //Assign new frame to your view
    CGRect displayNameViewRect = self.displayNameView.frame;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft ||
            [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight)
        {
            displayNameViewRect.origin.y -= 140;
        }
    }
    else
    {
        displayNameViewRect.origin.y -= 80;
    }
    self.displayNameView.frame = displayNameViewRect;
    
}

-(void)keyboardDidHide:(NSNotification *)notification
{
    CGRect displayNameViewRect = self.displayNameView.frame;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft ||
            [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight)
        {
            displayNameViewRect.origin.y += 140;
        }
    }
    else
    {
        displayNameViewRect.origin.y += 80;
    }
    self.displayNameView.frame = displayNameViewRect;
}

@end
