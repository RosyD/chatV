//
//  ACMapShareLocalDef.h
//  chat
//
//  Created by Aculearn on 16/5/27.
//  Copyright © 2016年 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MapKit/MapKit.h"
#import "SDWebImageCompat.h"
#import "SDWebImageManagerDelegate.h"
#import "SDWebImageManager.h"

@interface MKAnnotationView (AC_LocationSharing) <SDWebImageManagerDelegate>
-(void)setImageForUsr:(NSString*)usrID withIcon:(NSString*)iconID;
@end


@interface ACMapShareLocalDef : NSObject

+(void)createMapIcon:(UIImage*)pIcon;

@end
