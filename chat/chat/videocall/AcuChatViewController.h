//
//  AcuChatViewController.h
//  AcuConference
//
//  Created by aculearn on 13-8-6.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import "JSMessagesViewController.h"
#import "AcuSendChatProtocol.h"

@interface AcuChatMessage : NSObject

@property (nonatomic, retain) NSString					*message;
@property (nonatomic, assign) JSBubbleMessageType		messageType;

@end

@interface AcuChatViewController : JSMessagesViewController
                                    <JSMessagesViewDelegate,
                                    JSMessagesViewDataSource>

@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSMutableArray *timestamps;
@property (nonatomic, retain) NSString *localUserName;

@property (nonatomic, weak) id<AcuSendChatProtocol> sendChatDelegate;

- (void)hideKeyboard;

- (void)addChatMessage:(NSString*)userName
			   message:(NSString*)msg;

@end
