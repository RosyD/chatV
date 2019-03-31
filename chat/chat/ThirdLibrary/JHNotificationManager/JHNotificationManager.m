//
//  JHNotificationManager.m
//  Notifications
//
//  Created by Jeff Hodnett on 13/09/2011.
//
//  Updated by Toni Chau on 12/12/13.
//  Copyright (c) 2013 Toni Chau. All rights reserved.
//

#import "JHNotificationManager.h"
#import <math.h>
#import <QuartzCore/QuartzCore.h>
#import "ACAppDelegate.h"

#define kSecondsVisibleDelay 3.0f
#define kSecondsVisibleDelayForActive 2.0f
#define kAnimationDuration 0.4f
#define kAnimationDelay 0.1f

#define DEGREES_RADIANS(angle) ((angle) / 180.0 * M_PI)


@interface JHNotificationManager()
{
    // The notificatin views array
    NSMutableArray<NSDictionary*> *_notificationQueue;
    
    // Are we showing a notification
//    BOOL _showingNotification;
    NSDictionary    *_nowShowingNotification;
    UIView          *_nowShowingNotificationView;
    BOOL            _callForActive;
}

@end

@implementation JHNotificationManager

+(JHNotificationManager *)sharedManager
{
    static JHNotificationManager *instance = nil;
    
    @synchronized(self) {
        if(instance == nil) {
            instance = [[self alloc] init];
        }
    }
    
    return instance;
}

-(id)init
{
    if( (self = [super init]) ) {
        
        // Setup the array
        _notificationQueue = [[NSMutableArray alloc] init];
        
        // Set not showing by default
        _nowShowingNotification = nil;
        _nowShowingNotificationView = nil;
    }
    return self;
}


#pragma mark Messages
+(void)notificationWithMessage:(NSString *)message  withUserInfo:(NSObject*)userInfo
{
    // Show the notification -- default animation to slide from top
   [self notificationWithMessage:message
                       direction:JHNotificationAnimationDirectionSlideInTop
                    withUserInfo:userInfo];
}

+(void)notificationWithMessage:(NSString *)message direction:(JHNotificationAnimationDirection)direction  withUserInfo:(NSObject*)userInfo
{
//    dispatch_async(dispatch_get_main_queue(), ^{

    // Show the notification
    [[JHNotificationManager sharedManager] addNotificationViewWithMessage:message
                                                                direction:direction
                                                             withUserInfo:userInfo];
//    });
}

-(void)_notificationRemoveMsgWithBlock:(BOOL (^)(NSObject* userInfo)) func{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @synchronized (self) {
            for(NSInteger n=0;n<_notificationQueue.count;n++){
                if(func(_notificationQueue[n][@"userinfo"])){
                    [_notificationQueue removeObjectAtIndex:n];
                    n--;
                }
            }
        }
    });
}

+(void)notificationRemoveMsgWithBlock:(BOOL (^)(NSObject* userInfo)) func{
        [[JHNotificationManager sharedManager] _notificationRemoveMsgWithBlock:func];
}

-(void)addNotificationViewWithMessage:(NSString *)message direction:(JHNotificationAnimationDirection)direction  withUserInfo:(NSObject*)userInfo
{
    
    // Create array of notification view dictionaries
    @synchronized (self) {
        [_notificationQueue addObject:[NSDictionary dictionaryWithObjectsAndKeys:message,@"msg",[NSNumber numberWithInt:direction], @"direction", userInfo,@"userinfo",nil]];
    }
    
    // Should we show this notification view
    if(nil==_nowShowingNotification) {
        [self showCurrentNotificationWithdelay:@(0)];
    }
}

-(void)onActive{
    if([ACAppDelegate canShowNotification]){
        _callForActive = YES;
    }
    [self _hideCurrentNotification:_nowShowingNotification];
}

-(void)showCurrentNotificationWithdelay:(NSNumber*)pDelay
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    if(![ACAppDelegate canShowNotification]){
        [self performSelector:@selector(showCurrentNotificationWithdelay:)
                   withObject:pDelay
                   afterDelay:5];
        //延时处理5秒，再检查是否继续
        return;
    }
    
    CGFloat delay = pDelay.floatValue;
    NSDictionary* pNotification = nil;
    @synchronized (self) {
        pNotification = _nowShowingNotification = [_notificationQueue objectAtIndex:0];
        [_notificationQueue removeObjectAtIndex:0];
    }
    
    _callForActive = NO;

//    UIView *notificationView    =   pNotification[@"view"];
    JHNotificationAnimationDirection direction = [pNotification[@"direction"] intValue];

    // Grab the main window
//    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    // Setup size variables
    CGSize notificationViewSize = CGSizeMake(CGRectGetWidth(window.bounds), 65.0f);
    
    // Create the notification view
    CGRect notificationViewFrame;
    UIView* notificationView =  [[UIView alloc] init];

    _nowShowingNotificationView =   notificationView;
    // Get starting position
    switch (direction) {
        case JHNotificationAnimationDirectionSlideInLeft:
        case JHNotificationAnimationDirectionSlideInLeftOutRight:
            notificationViewFrame = CGRectMake(-notificationViewSize.width, 0, notificationViewSize.width, notificationViewSize.height);
            break;
        case JHNotificationAnimationDirectionSlideInRight:
        case JHNotificationAnimationDirectionSlideInRightOutLeft:
            notificationViewFrame = CGRectMake(notificationViewSize.width, 0, notificationViewSize.width, notificationViewSize.height);
            break;
        case JHNotificationAnimationDirectionSwingInUpLeft:
            _nowShowingNotificationView.layer.anchorPoint = CGPointMake(0, 0);
            notificationViewFrame = CGRectMake(0, -notificationViewSize.height, notificationViewSize.width, notificationViewSize.height);
            break;
        case JHNotificationAnimationDirectionSwingInDownLeft:
            _nowShowingNotificationView.layer.anchorPoint = CGPointMake(0, 1);
            notificationViewFrame = CGRectMake(0, -notificationViewSize.height, notificationViewSize.width, notificationViewSize.height);
            break;
        case JHNotificationAnimationDirectionSwingInUpRight:
            _nowShowingNotificationView.layer.anchorPoint = CGPointMake(1, 0);
            notificationViewFrame = CGRectMake(0, -notificationViewSize.height, notificationViewSize.width, notificationViewSize.height);
            break;
        case JHNotificationAnimationDirectionSwingInDownRight:
            _nowShowingNotificationView.layer.anchorPoint = CGPointMake(1, 1);
            notificationViewFrame = CGRectMake(0, -notificationViewSize.height, notificationViewSize.width, notificationViewSize.height);
            break;
        case JHNotificationAnimationDirectionFlipDown:
        case JHNotificationAnimationDirectionRotateIn:
        case JHNotificationAnimationDirectionSlideInTop:
        default:
            //-notificationViewSize.height
            notificationViewFrame = CGRectMake(0, -notificationViewSize.height, notificationViewSize.width, notificationViewSize.height);
            break;
    }
    
    // Create the view
    [_nowShowingNotificationView setFrame:notificationViewFrame];
    [_nowShowingNotificationView setBackgroundColor:[UIColor blackColor]];
    notificationView.alpha = 0.8;
    
#define ICON_IMG_XY 5
#define ICON_IMG_WH 20
    
    CGRect rectTemp =   CGRectMake(ICON_IMG_XY, (notificationViewSize.height-ICON_IMG_WH)/2, ICON_IMG_WH, ICON_IMG_WH);
    UIImageView* pImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_about.png"]];
    pImgView.frame =    rectTemp;
    [notificationView addSubview:pImgView];
    
    // Add some text to the label
    rectTemp.origin.y = ICON_IMG_XY;
    rectTemp.origin.x += ICON_IMG_WH+ICON_IMG_XY;
    rectTemp.size.width = notificationViewSize.width-rectTemp.origin.x-ICON_IMG_XY;
    rectTemp.size.height = notificationViewSize.height-ICON_IMG_XY-ICON_IMG_XY;
    
    UILabel *label = [[UILabel alloc] initWithFrame:rectTemp];
    [label setNumberOfLines:2];
    [label setText:pNotification[@"msg"]];
    [label setFont:[UIFont systemFontOfSize:16.0f]];
//    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    [label setBackgroundColor:[UIColor clearColor]];
    [notificationView addSubview:label];
    
//    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, notificationViewSize.width, notificationViewSize.height)];
//    [button addTarget:self action:@selector(onActive) forControlEvents:UIControlEventTouchUpInside];
//    [button setTitle:pNotification[@"msg"] forState:UIControlStateNormal];
//    [notificationView addSubview:button];
    
//    notificationView.userInteractionEnabled = YES;
    // Add to the window
//    [window.rootViewController.view addSubview:notificationView];
    [window addSubview:notificationView];
    [window bringSubviewToFront:notificationView];
    
    

    
    // Animate the notification
    [UIView animateWithDuration:kAnimationDuration delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        // Create the notification view frame
        CGRect notificationViewFrame;
        CABasicAnimation *rotate;
        
        // Setup end positions
        switch (direction) {
            case JHNotificationAnimationDirectionSlideInLeft:
            case JHNotificationAnimationDirectionSlideInLeftOutRight:
                notificationViewFrame = CGRectMake(notificationView.frame.origin.x+CGRectGetWidth(notificationView.frame), notificationView.frame.origin.y, CGRectGetWidth(notificationView.frame), CGRectGetHeight(notificationView.frame));
                break;
            case JHNotificationAnimationDirectionSlideInRight:
            case JHNotificationAnimationDirectionSlideInRightOutLeft:
                notificationViewFrame = CGRectMake(notificationView.frame.origin.x-CGRectGetWidth(notificationView.frame), notificationView.frame.origin.y, CGRectGetWidth(notificationView.frame), CGRectGetHeight(notificationView.frame));
                break;
            case JHNotificationAnimationDirectionFlipDown:
                // Flip in on x-axis
                rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation.x"];
                rotate.fromValue = [NSNumber numberWithFloat:0];
                rotate.toValue = [NSNumber numberWithFloat:M_PI / 2.0];
                rotate.duration = kAnimationDuration;

                [notificationView.layer addAnimation:rotate forKey:nil];
                    notificationViewFrame = CGRectMake(notificationView.frame.origin.x, notificationView.frame.origin.y+CGRectGetHeight(notificationView.frame), CGRectGetWidth(notificationView.frame), CGRectGetHeight(notificationView.frame));
                break;
            case JHNotificationAnimationDirectionRotateIn:
                // Rotate in from top
            case JHNotificationAnimationDirectionSwingInUpLeft:
                // Swing upwards from left
            case JHNotificationAnimationDirectionSwingInDownRight:
                // Swing downwards from right
                rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
                rotate.fromValue = [NSNumber numberWithFloat:DEGREES_RADIANS(180)];
                rotate.toValue = [NSNumber numberWithFloat:DEGREES_RADIANS(0)];
                rotate.duration = kAnimationDuration;
                [notificationView.layer addAnimation:rotate forKey:nil];
                
                notificationViewFrame = CGRectMake(notificationView.frame.origin.x, notificationView.frame.origin.y+CGRectGetHeight(notificationView.frame), CGRectGetWidth(notificationView.frame), CGRectGetHeight(notificationView.frame));
                break;
            case JHNotificationAnimationDirectionSwingInDownLeft:
                // Swing downwards from left
            case JHNotificationAnimationDirectionSwingInUpRight:
                // Swing downwards from left
                rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
                rotate.fromValue = [NSNumber numberWithFloat:DEGREES_RADIANS(-180)];
                rotate.toValue = [NSNumber numberWithFloat:DEGREES_RADIANS(0)];
                rotate.duration = kAnimationDuration;
                [notificationView.layer addAnimation:rotate forKey:nil];
                
                notificationViewFrame = CGRectMake(notificationView.frame.origin.x, notificationView.frame.origin.y+CGRectGetHeight(notificationView.frame), CGRectGetWidth(notificationView.frame), CGRectGetHeight(notificationView.frame));
                break;
            case JHNotificationAnimationDirectionSlideInTop:
            default:
                notificationViewFrame = CGRectMake(notificationView.frame.origin.x, notificationView.frame.origin.y+CGRectGetHeight(notificationView.frame), CGRectGetWidth(notificationView.frame), CGRectGetHeight(notificationView.frame));
                break;
        }
        
        [notificationView setFrame: notificationViewFrame];
        
    } completion:^(BOOL finished) {
        //添加Active
        notificationView.userInteractionEnabled = YES;
        [notificationView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onActive)]];

        // Hide the notification after a set second delay
        [self performSelector:@selector(_hideCurrentNotification:)
                   withObject:pNotification
                   afterDelay:kSecondsVisibleDelay];
//        [self hideCurrentNotification:pNotification delay:kSecondsVisibleDelay];
    }];
}


-(void)_hideNotificationView:(BOOL)anima{
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if(anima){
        [self _hideCurrentNotification:_nowShowingNotification];
        return;
    }
    
    [_nowShowingNotificationView removeFromSuperview];
    _nowShowingNotification = nil;
    _nowShowingNotificationView = nil;

    @synchronized (self) {

        if(_notificationQueue.count) {
            //呆一会显示
            [self performSelector:@selector(showCurrentNotificationWithdelay:)
                       withObject:@(0)
                       afterDelay:5];
        }
    }
}

+(void)hideNotificationView:(BOOL)anima{
    [[JHNotificationManager sharedManager] _hideNotificationView:anima];
}



-(void)_hideCurrentNotification:(NSDictionary*)pNotification
{
    
    if(pNotification==_nowShowingNotification&&_callForActive){
        _callForActive = NO;
        
        NSDictionary* pUserInfo = _nowShowingNotification[@"userinfo"];
        [_nowShowingNotificationView removeFromSuperview];
        _nowShowingNotification = nil;
        _nowShowingNotificationView = nil;
       
        [ACAppDelegate activeNotification:pUserInfo];
        
        @synchronized (self) {
            if(_notificationQueue.count) {
                [self showCurrentNotificationWithdelay:@(kSecondsVisibleDelayForActive)];
            }
        }
        return;
    }

    
    // Animate the view
    [UIView animateWithDuration:kAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect notificationViewFrame;
        
        if(pNotification!=_nowShowingNotification){
            return;
        }

        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        UIView* notificationView  = _nowShowingNotificationView;
        JHNotificationAnimationDirection direction = [pNotification[@"direction"] intValue];

        // Get positions
        switch (direction) {
            case JHNotificationAnimationDirectionSlideInLeft:
            case JHNotificationAnimationDirectionSlideInRightOutLeft:
                notificationViewFrame = CGRectMake(-CGRectGetWidth(notificationView.frame), notificationView.frame.origin.y, CGRectGetWidth(notificationView.frame), CGRectGetHeight(notificationView.frame));
                break;
            case JHNotificationAnimationDirectionSlideInRight:
            case JHNotificationAnimationDirectionSlideInLeftOutRight:
                notificationViewFrame = CGRectMake(notificationView.frame.origin.x+CGRectGetWidth(notificationView.frame), notificationView.frame.origin.y, CGRectGetWidth(notificationView.frame), CGRectGetHeight(notificationView.frame));
                break;
            case JHNotificationAnimationDirectionFlipDown:
            case JHNotificationAnimationDirectionRotateIn:
            case JHNotificationAnimationDirectionSwingInUpLeft:
            case JHNotificationAnimationDirectionSwingInUpRight:
            case JHNotificationAnimationDirectionSwingInDownRight:
            case JHNotificationAnimationDirectionSlideInTop:
            default:
                notificationViewFrame = CGRectMake(notificationView.frame.origin.x, notificationView.frame.origin.y-notificationView.frame.size.height, notificationView.frame.size.width, notificationView.frame.size.height);
                break;
        }
        
        [notificationView setFrame:notificationViewFrame];
        
    } completion:^(BOOL finished) {
        if(pNotification!=_nowShowingNotification){
            return;
        }
//        NSDictionary* pUserInfo = _nowShowingNotification[@"userinfo"];
        [_nowShowingNotificationView removeFromSuperview];
        _nowShowingNotificationView = nil;
        _nowShowingNotification = nil;
        _callForActive = NO;
        
//        if(_callForActive){
//            [ACAppDelegate activeNotification:pUserInfo];
//        }
        @synchronized (self) {

            if(_notificationQueue.count) {
                [self showCurrentNotificationWithdelay:@(kAnimationDelay)];
    //            [self showCurrentNotificationWithdelay:_callForActive?kSecondsVisibleDelayForActive:kAnimationDelay];
            }
        }
    }];
}

//-(UIView *)currentView
//{
//    NSDictionary *notificationDataQueue = [_notificationQueue objectAtIndex:0];
//    UIView *view  = [notificationDataQueue objectForKey:@"view"];
//    return view;
//}
//
//-(JHNotificationAnimationDirection)currentDirection
//{
//    NSDictionary *notificationDataQueue = [_notificationQueue objectAtIndex:0];
//    JHNotificationAnimationDirection direction = [[notificationDataQueue objectForKey:@"direction"] intValue];
//    return direction;
//}
@end
