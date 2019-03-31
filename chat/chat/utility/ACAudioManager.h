//
//  AcuAudioManager.h
//  
//
//  Created by Aculearn on 13-11-14.
//
//

#import <Foundation/Foundation.h>


@class ACAudioManager;

@protocol ACAudioManagerDelegate <NSObject>
- (void)audioManager:(ACAudioManager*)audioManager headseted:(BOOL)headseted;
@end

@interface ACAudioManager : NSObject

@property (nonatomic) BOOL isHandFreeMode;  //是否外放

+ (instancetype)startAudioManagerWithDelegate:(id <ACAudioManagerDelegate>)dela; //开始
- (void)changeMode:(BOOL)forVideoCall;
- (void)stopAudioManager;


+ (BOOL)isHeadsetPluggedIn; //是否插入了耳机

@end
