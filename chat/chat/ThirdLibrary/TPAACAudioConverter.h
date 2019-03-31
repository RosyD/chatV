//
//  TPAACAudioConverter.h
//
//  Created by Michael Tyson on 02/04/2011.
//  Copyright 2011 A Tasty Pixel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

static inline BOOL _checkResult(OSStatus result, const char *operation, const char* file, int line) {
    if ( result != noErr ) {
        NSLog(@"%s:%d: %s result %d %08X %4.4s\n", file, line, operation, (int)result, (int)result, (char*)&result);
        return NO;
    }
    return YES;
}

extern NSString * TPAACAudioConverterErrorDomain;

enum {
    TPAACAudioConverterFileError,
    TPAACAudioConverterFormatError,
    TPAACAudioConverterUnrecoverableInterruptionError,
    TPAACAudioConverterInitialisationError
};

@protocol TPAACAudioConverterDelegate;
@protocol TPAACAudioConverterDataSource;

@interface TPAACAudioConverter : NSObject

+ (BOOL)AACConverterAvailable;

- (id)initWithDelegate:(id<TPAACAudioConverterDelegate>)delegate source:(NSString*)sourcePath destination:(NSString*)destinationPath;
- (id)initWithDelegate:(id<TPAACAudioConverterDelegate>)delegate dataSource:(id<TPAACAudioConverterDataSource>)dataSource audioFormat:(AudioStreamBasicDescription)audioFormat destination:(NSString*)destinationPath;
- (void)start;
- (void)cancel;

- (void)interrupt;
- (void)resume;

@property (nonatomic, readonly, retain) NSString *source;
@property (nonatomic, readonly, retain) NSString *destination;
@property (nonatomic, readonly) AudioStreamBasicDescription audioFormat;
@end


@protocol TPAACAudioConverterDelegate <NSObject>
- (void)AACAudioConverterDidFinishConversion:(TPAACAudioConverter*)converter;
- (void)AACAudioConverter:(TPAACAudioConverter*)converter didFailWithError:(NSError*)error;
@optional
- (void)AACAudioConverter:(TPAACAudioConverter*)converter didMakeProgress:(CGFloat)progress;
@end

@protocol TPAACAudioConverterDataSource <NSObject>
- (void)AACAudioConverter:(TPAACAudioConverter*)converter nextBytes:(char*)bytes length:(NSUInteger*)length;
@optional
- (void)AACAudioConverter:(TPAACAudioConverter *)converter seekToPosition:(NSUInteger)position;
@end