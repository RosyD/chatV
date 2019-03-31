//
//  ACMapShareLocalDef.m
//  chat
//
//  Created by Aculearn on 16/5/27.
//  Copyright © 2016年 Aculearn. All rights reserved.
//

#import "ACMapShareLocalDef.h"
#import "ACAddress.h"
#import "UIImageView+WebCache.h"



#define LocationSharing_Member_Icon_FileName(p__IconID) \
    [ACAddress getAddressWithFileName:[NSString stringWithFormat:@"%@_map.png",p__IconID] fileType:ACFile_Type_LocationSharing_Member_Icon isTemp:NO subDirName:nil]


@implementation MKAnnotationView (AC_LocationSharing)


//#define MapIcon_BK_Img_WH  126
//#define MapIcon_Icon_X      21
//#define MapIcon_Icon_Y      15
//#define MapIcon_Icon_WH     82

#define MapIcon_BK_Img_WH  126/2
#define MapIcon_Icon_X      11
#define MapIcon_Icon_Y      8
#define MapIcon_Icon_WH     82/2

+(UIImage*)_createMapIcon:(UIImage*)pIcon withSaveFile:(NSString*)pCacheFileName{
    
    UIImage *imageBk = [UIImage imageNamed:@"locationSharing_Member_bg"];
    
    UIGraphicsBeginImageContextWithOptions(imageBk.size,NO,imageBk.scale);
    
//    UIGraphicsBeginImageContext(CGSizeMake(MapIcon_BK_Img_WH, MapIcon_BK_Img_WH));
    [imageBk drawInRect:CGRectMake(0, 0, MapIcon_BK_Img_WH, MapIcon_BK_Img_WH)];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextAddArc(ctx, MapIcon_Icon_X+MapIcon_Icon_WH/2, MapIcon_Icon_Y+MapIcon_Icon_WH/2, MapIcon_Icon_WH/2, 0, M_PI*2, 0);
    CGContextClip(ctx);
    
    [pIcon drawInRect:CGRectMake(MapIcon_Icon_X, MapIcon_Icon_Y, MapIcon_Icon_WH, MapIcon_Icon_WH)];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [UIImagePNGRepresentation(newImage) writeToFile:pCacheFileName atomically:NO];
    
    return newImage;
}


-(void)setImageForUsr:(NSString*)usrID withIcon:(NSString*)iconID{
    
    //检查本地是否有缓存
    NSString* pCacheFileName =  LocationSharing_Member_Icon_FileName(usrID);
    UIImage* pIconImg = [UIImage imageWithContentsOfFile:pCacheFileName];
    if(pIconImg){
        self.image =    pIconImg;
        return;
    }

    //加载
    BOOL bIsURL = NO;
    NSString* pIconInfo = [UIImageView getIconInfoWithIconString:iconID ImageType:ImageType_UserIcon100 isURL:&bIsURL];
    if(nil==pIconInfo){
        self.image =  [UIImage imageNamed:@"locationSharing_Member_def"];
        return;
    }
    
    if(!bIsURL){
        self.image = [MKAnnotationView _createMapIcon:[UIImage imageWithContentsOfFile:pIconInfo]
                                         withSaveFile:pCacheFileName];
        return;
    }
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager cancelForDelegate:self];
    self.image = [UIImage imageNamed:@"locationSharing_Member_def"];
    
    [manager downloadWithURL:[NSURL URLWithString:pIconInfo]
                    delegate:self
                     options:(SDWebImageOptions)0
                    userInfo:@{@"usrid":usrID}];
}

- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image forURL:(NSURL *)url userInfo:(NSDictionary *)info{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.image = [MKAnnotationView _createMapIcon:image
                                         withSaveFile:LocationSharing_Member_Icon_FileName(info[@"usrid"])];
        [self setNeedsLayout];
    });
}

@end


@implementation ACMapShareLocalDef


@end
