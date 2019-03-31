//
//  NSStream+StreamsToHost.m
//  chat
//
//  Created by Aculearn on 15/11/27.
//  Copyright © 2015年 Aculearn. All rights reserved.
//

#import "NSStream+StreamsToHost.h"

@implementation NSStream(StreamsToHost)

+ (void)getStreamsToHostNamed:(NSString *)hostName
                         port:(int)port
                  inputStream:(out NSInputStream **)inputStreamPtr
                 outputStream:(out NSOutputStream **)outputStreamPtr
{
    CFReadStreamRef     readStream;
    CFWriteStreamRef    writeStream;
    
    assert(hostName != nil);
    assert( (port > 0) && (port < 65536) );
    assert( (inputStreamPtr != NULL) || (outputStreamPtr != NULL) );
    
    readStream = NULL;
    writeStream = NULL;
    
    CFStreamCreatePairWithSocketToHost(
                                       NULL,
                                       (__bridge CFStringRef) hostName,
                                       port,
                                       ((inputStreamPtr  != NULL) ? &readStream : NULL),
                                       ((outputStreamPtr != NULL) ? &writeStream : NULL)
                                       );
    
    if (inputStreamPtr != NULL) {
        *inputStreamPtr  = CFBridgingRelease(readStream);
    }
    
    if (outputStreamPtr != NULL) {
        *outputStreamPtr = CFBridgingRelease(writeStream);
    }
}

@end