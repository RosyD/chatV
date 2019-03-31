//
//  SvGifView.m
//  SvGifSample
//
//  Created by maple on 3/28/13.
//  Copyright (c) 2013 smileEvday. All rights reserved.
//
//  QQ: 1592232964

#import "SvGifView.h"
#import <ImageIO/ImageIO.h>
#import <QuartzCore/CoreAnimation.h>
#import "UIView+Additions.h"

/*
 * @brief resolving gif information
 */
void getFrameInfo(CFURLRef url, NSMutableArray *frames, NSMutableArray *delayTimes, CGFloat *totalTime,CGFloat *gifWidth, CGFloat *gifHeight)
{
    CGImageSourceRef gifSource = CGImageSourceCreateWithURL(url, NULL);
    
    // get frame count
    size_t frameCount = CGImageSourceGetCount(gifSource);
    for (size_t i = 0; i < frameCount; ++i) {
        // get each frame
        CGImageRef frame = CGImageSourceCreateImageAtIndex(gifSource, i, NULL);
        [frames addObject:(__bridge id)frame];
        CGImageRelease(frame);
        
        // get gif info with each frame
        NSDictionary *dict = (__bridge NSDictionary*)CGImageSourceCopyPropertiesAtIndex(gifSource, i, NULL);
        NSLog(@"kCGImagePropertyGIFDictionary %@", [dict valueForKey:(NSString*)kCGImagePropertyGIFDictionary]);
        
        // get gif size
        if (gifWidth != NULL && gifHeight != NULL) {
            *gifWidth = [[dict valueForKey:(NSString*)kCGImagePropertyPixelWidth] floatValue];
            *gifHeight = [[dict valueForKey:(NSString*)kCGImagePropertyPixelHeight] floatValue];
        }
        
        // kCGImagePropertyGIFDictionary中kCGImagePropertyGIFDelayTime，kCGImagePropertyGIFUnclampedDelayTime值是一样的
        NSDictionary *gifDict = [dict valueForKey:(NSString*)kCGImagePropertyGIFDictionary];
        NSObject *delayTime = [gifDict valueForKey:(NSString*)kCGImagePropertyGIFDelayTime];
        if (delayTime) {
            [delayTimes addObject:delayTime];
        }
        
        if (totalTime) {
            *totalTime = *totalTime + [[gifDict valueForKey:(NSString*)kCGImagePropertyGIFDelayTime] floatValue];
        }
    }
}

@interface SvGifView() {
    NSMutableArray *_frames;
    NSMutableArray *_frameDelayTimes;
    
    CGFloat _totalTime;         // seconds
    CGFloat _width;
    CGFloat _height;
}

@end

@implementation SvGifView

- (void)dealloc
{
    [self stopGif];
}

//- (id)initWithCenter:(CGPoint)center fileURL:(NSURL*)fileURL
//{
//    self = [super initWithFrame:CGRectZero];
//    if (self) {
//        
//        _frames = [[NSMutableArray alloc] init];
//        _frameDelayTimes = [[NSMutableArray alloc] init];
//        
//        _width = 0;
//        _height = 0;
//        
//        if (fileURL) {
//            getFrameInfo((__bridge CFURLRef)fileURL, _frames, _frameDelayTimes, &_totalTime, &_width, &_height);
//        }
//        
//        self.frame = CGRectMake(0, 0, _width, _height);
//        self.center = center;
//    }
//    
//    return self;
//}

-(void)awakeFromNib
{
    [super awakeFromNib];
    _frames = [[NSMutableArray alloc] init];
    _frameDelayTimes = [[NSMutableArray alloc] init];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _frames = [[NSMutableArray alloc] init];
        _frameDelayTimes = [[NSMutableArray alloc] init];
        
    }
    return self;
}

-(void)setFileURL:(NSURL *)fileURL
{
    getFrameInfo((__bridge CFURLRef)fileURL, _frames, _frameDelayTimes, &_totalTime, &_width, &_height);
    [self setFrame_width:_width];
    [self setFrame_height:_height];
}

+ (NSArray*)framesInGif:(NSURL *)fileURL
{
    NSMutableArray *frames = [NSMutableArray arrayWithCapacity:3];
    NSMutableArray *delays = [NSMutableArray arrayWithCapacity:3];
    
    getFrameInfo((__bridge CFURLRef)fileURL, frames, delays, NULL, NULL, NULL);
    
    return frames;
}

- (void)startGif
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    
    NSMutableArray *times = [NSMutableArray arrayWithCapacity:3];
    CGFloat currentTime = 0;
    int count = (int)_frameDelayTimes.count;
    for (int i = 0; i < count; ++i) {
        [times addObject:[NSNumber numberWithFloat:(currentTime / _totalTime)]];
        currentTime += [[_frameDelayTimes objectAtIndex:i] floatValue];
    }
    [animation setKeyTimes:times];
    
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:3];
    for (int i = 0; i < count; ++i) {
        [images addObject:[_frames objectAtIndex:i]];
    }
    
    [animation setValues:images];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    animation.duration = _totalTime;
    animation.delegate = self;
    animation.repeatCount = 10000;
    
    [self.layer addAnimation:animation forKey:@"gifAnimation"];
    
    //
    
}

-(void)pauseLayer
{
    CFTimeInterval pausedTime = [self.layer convertTime:CACurrentMediaTime() fromLayer:nil];
    self.layer.speed = 0.0;
//    self.layer.timeOffset = pausedTime;
}

- (void)resumeLayer
{
    CFTimeInterval pausedTime = [self.layer timeOffset];
    self.layer.speed= 1.0;
//    self.layer.timeOffset= 0.0;
//    self.layer.beginTime= 0.0;
//    CFTimeInterval timeSincePause = [self.layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
//    self.layer.beginTime= pausedTime;
}

- (void)stopGif
{
    [self.layer removeAllAnimations];
}

// remove contents when animation end
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    self.layer.contents = nil;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}


@end


