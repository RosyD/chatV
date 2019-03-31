//
//  AcuParticipantListMenuProtocol.h
//  EShoreConference
//
//  Created by Aculearn on 13-11-21.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AcuParticipantListMenuProtocol <NSObject>
- (bool)getParticipantListMenu:(int)participantId
                      menuData:(char*)pMenuData
                       dataLen:(int)nLen;
- (void)sendMenuCommand:(int)cmdID cmdInfo:(const char*)info;
@end
