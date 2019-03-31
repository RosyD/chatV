//
//  NSStream+StreamsToHost.h
//  chat
//
//  Created by Aculearn on 15/11/27.
//  Copyright © 2015年 Aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSStream(StreamsToHost)

+ (void)getStreamsToHostNamed:(NSString *)hostName
                         port:(int)port
                  inputStream:(out NSInputStream **)inputStreamPtr
                 outputStream:(out NSOutputStream **)outputStreamPtr;

@end
