//
//  AcuSendChatProtocol.h
//  AcuConference
//
//  Created by aculearn on 13-9-11.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AcuSendChatProtocol <NSObject>
- (void)sendChatMsg:(NSString*)chatMsg;
@end
