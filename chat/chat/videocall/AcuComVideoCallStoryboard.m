//
//  AcuComBundleStoryboard.m
//  videocall
//
//  Created by Aculearn on 15-1-20.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AcuComVideoCallStoryboard.h"

@implementation AcuComVideoCallStoryboard

+ (id)acuComVideoCallStoryboardNamed:(NSString*)name
{
    UIStoryboard *bundleStoryboard = [UIStoryboard storyboardWithName:@"videocall_iPhone" bundle:nil];
    
    return [bundleStoryboard instantiateViewControllerWithIdentifier:name];
}

@end
