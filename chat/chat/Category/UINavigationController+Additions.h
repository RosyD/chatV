//
//  UINavigationController+Additions.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-17.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIAlertView+Blocks.h"

@interface UINavigationController (Additions)

-(UIViewController *)ACpopViewControllerAnimated:(BOOL)animated;

-(NSArray *)ACpopToViewController:(UIViewController *)viewController animated:(BOOL)animated;

-(NSArray *)ACpopToRootViewControllerAnimated:(BOOL)animated;

@end


#define Send_Video_Maximum_Duration 90
//发送视频最大时间长度

@class MPMoviePlayerViewController;
@interface UIViewController (Additions) 

@property (nonatomic) BOOL  isOpenHotspot;

-(void)initHotspot;

-(void)hotspotStateChange:(NSNotification *)noti;

- (void)ACpresentMoviePlayerViewControllerAnimated:(MPMoviePlayerViewController *)moviePlayerViewController;

-(void)ACpresentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion;

-(void)ACdismissViewControllerAnimated:(BOOL)flag completion:(void (^)())completion;

-(void)ACdismissViewControllerAnimated:(BOOL)flag completion:(void (^)())completion withTip:(NSString*)pTip;


//-(void) MWPhotoBrowser_ShowPhotos:(NSArray *)photosArray; //<MWPhoto>
-(void) MWPhotoBrowser_ShowPhotoFile:(NSString*)pFilePathName withURL:(NSString*)pURL;
-(void) MWPhotoBrowser_ShowUserIcon1000:(NSString*)icon;


-(void) selectImagesWithELC_Delegate:(id)delgate withCount:(int)nCount; //选多图
-(void) selectImageWithUIImagePickerController_Delegate:(id)delgate forCamera:(BOOL)camera; //选取一张图片或拍照
-(void) videoWithUIImagePickerController_Delegate:(id)delgate fromRecord:(BOOL)bRecord; //录像

@end
