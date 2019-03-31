//
//  AcuChatViewController.m
//  AcuConference
//
//  Created by aculearn on 13-8-6.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import "AcuChatViewController.h"
#import "KxMenu.h"

@implementation AcuChatMessage

@synthesize message;
@synthesize messageType;

@end

@interface AcuChatViewController ()

@end

@implementation AcuChatViewController

@synthesize localUserName;

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
        CGRect frame = self.view.frame;
        frame.origin.y += 20;
        self.view.frame = frame;
        
		self.edgesForExtendedLayout = UIRectEdgeNone;
	}
	
    self.delegate = self;
    self.dataSource = self;
	
	self.localUserName = @"Woz";
    
    self.title = NSLocalizedString(@"Messages", "Conference Presention Chat");
    
    self.messages = [NSMutableArray new];

//	AcuChatMessage *chatMsg1 = [AcuChatMessage alloc];
//	chatMsg1.message = @"Jobs: Testing some messages here.";
//	chatMsg1.messageType = JSBubbleMessageTypeIncoming;
//	[self.messages addObject:chatMsg1];
//	
//    AcuChatMessage *chatMsg2 = [AcuChatMessage alloc];
//	chatMsg2.message = @"Jobs: Options for avatars: none, circles, or squares";
//	chatMsg2.messageType = JSBubbleMessageTypeIncoming;
//	[self.messages addObject:chatMsg2];
//	
//	AcuChatMessage *chatMsg3 = [AcuChatMessage alloc];
//	chatMsg3.message = @"Woz: WThis is a complete re-write and refactoring.";
//	chatMsg3.messageType = JSBubbleMessageTypeOutgoing;
//	[self.messages addObject:chatMsg3];
//	
//	AcuChatMessage *chatMsg4 = [AcuChatMessage alloc];
//	chatMsg4.message = @"Jobs: It's easy to implement. Sound effects and images included. Animations are smooth and messages can be of arbitrary size!";
//	chatMsg4.messageType = JSBubbleMessageTypeIncoming;
//	[self.messages addObject:chatMsg4];
    
//    self.timestamps = [[NSMutableArray alloc] initWithObjects:
//                       [NSDate distantPast],
//                       [NSDate distantPast],
//                       [NSDate distantPast],
//                       [NSDate date],
//                       nil];
	
	self.timestamps = [NSMutableArray new];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTappedBackground:)];
    tapGesture.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tapGesture];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
	[self.messages removeAllObjects];
	self.messages = nil;
	[self.timestamps removeAllObjects];
	self.timestamps = nil;
	self.localUserName = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight ||
            toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

- (void)didTappedBackground:(id) sender
{
    [KxMenu dismissMenu];
    [self.view endEditing:YES];
}

- (void)hideKeyboard
{
    [self.view endEditing:YES];
}

- (void)addChatMessage:(NSString*)userName
			   message:(NSString*)msg
{
	NSMutableString *msgContent = [[NSMutableString alloc] initWithString:userName];
	[msgContent appendString:@": "];
	[msgContent appendString:msg];
	
	AcuChatMessage *chatMsg = [AcuChatMessage alloc];
	chatMsg.message = msgContent;
	chatMsg.messageType = JSBubbleMessageTypeIncoming;
	
    [self.messages addObject:chatMsg];
    
    [self.timestamps addObject:[NSDate date]];
    
	//    if((self.messages.count - 1) % 2)
	//        [JSMessageSoundEffect playMessageSentSound];
	//    else
	//        [JSMessageSoundEffect playMessageReceivedSound];
    
	[self.tableView reloadData];
    [self scrollToBottomAnimated:NO];
}

#pragma mark - Initialization
- (UIButton *)sendButton
{
    // Override to use a custom send button
    // The button's frame is set automatically for you
    return [UIButton defaultSendButton];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

#pragma mark - Messages view delegate
- (void)sendPressed:(UIButton *)sender withText:(NSString *)text
{
//	NSMutableString *msg = [[NSMutableString alloc] initWithString:self.localUserName];
//	[msg appendString:@": "];
//	[msg appendString:text];
	
	AcuChatMessage *chatMsg = [AcuChatMessage alloc];
	chatMsg.message = text;
	chatMsg.messageType = JSBubbleMessageTypeOutgoing;
	
    [self.messages addObject:chatMsg];
    
    [self.timestamps addObject:[NSDate date]];
    
//    if((self.messages.count - 1) % 2)
//        [JSMessageSoundEffect playMessageSentSound];
//    else
//        [JSMessageSoundEffect playMessageReceivedSound];
    
    [self finishSend];
	
	if (self.sendChatDelegate)
	{
		[self.sendChatDelegate sendChatMsg:text];
	}
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
	AcuChatMessage* chatMsg = [self.messages objectAtIndex:indexPath.row];
	return chatMsg.messageType;
    //return (indexPath.row % 2) ? JSBubbleMessageTypeIncoming : JSBubbleMessageTypeOutgoing;
}

- (JSBubbleMessageStyle)messageStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //return JSBubbleMessageStyleSquare;
    //return JSBubbleMessageStyleDefaultGreen;
    return JSBubbleMessageStyleDefault;
}

- (JSMessagesViewTimestampPolicy)timestampPolicy
{
    return JSMessagesViewTimestampPolicyEveryFive;
}

- (JSMessagesViewAvatarPolicy)avatarPolicy
{
    //return JSMessagesViewAvatarPolicyBoth;
    return JSMessagesViewAvatarPolicyNone;
}

- (JSAvatarStyle)avatarStyle
{
    return JSAvatarStyleCircle;
    //return JSAvatarStyleSquare;
}

//  Optional delegate method
//  Required if using `JSMessagesViewTimestampPolicyCustom`
//
//- (BOOL)hasTimestampForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//	if(indexPath.row > 0 && indexPath.row % 10 == 0)
//	{
//		return true;
//	}
//	
//	return NO;
//}


#pragma mark - Messages view data source
- (NSString *)textForRowAtIndexPath:(NSIndexPath *)indexPath
{
	AcuChatMessage *chatMsg = [self.messages objectAtIndex:indexPath.row];
	return chatMsg.message;
    //return [self.messages objectAtIndex:indexPath.row];
}

- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.timestamps objectAtIndex:indexPath.row];
}

- (UIImage *)avatarImageForIncomingMessage
{
    return [UIImage imageNamed:@"chat.png"];
}

- (UIImage *)avatarImageForOutgoingMessage
{
    return [UIImage imageNamed:@"chat.png"];
}

@end
