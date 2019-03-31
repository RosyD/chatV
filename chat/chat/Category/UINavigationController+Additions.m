//
//  UINavigationController+Additions.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-17.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "UINavigationController+Additions.h"
#import "ACConfigs.h"
#import "MWPhotoBrowser.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ELCImagePickerController.h"
#import "ACVideoCall.h"

@implementation UINavigationController (Additions)

-(UIViewController *)ACpopViewControllerAnimated:(BOOL)animated
{
    UIViewController *vc = [self.viewControllers lastObject];
    [NSObject cancelPreviousPerformRequestsWithTarget:vc];
    [[NSNotificationCenter defaultCenter] removeObserver:vc];
    ITLogEX(@"removeObserver %@",vc);
    return [self popViewControllerAnimated:animated];
}

-(NSArray *)ACpopToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    for (int i = (int)[self.viewControllers count]-1;i > 0; i--)
    {
        UIViewController *vc = [self.viewControllers objectAtIndex:i];
        if (vc != viewController)
        {
            [NSObject cancelPreviousPerformRequestsWithTarget:vc];
            [[NSNotificationCenter defaultCenter] removeObserver:vc];
            ITLogEX(@"removeObserver %@",vc);
        }
        else
        {
            break;
        }
    }
    return [self popToViewController:viewController animated:animated];
}

-(NSArray *)ACpopToRootViewControllerAnimated:(BOOL)animated
{
    for (int i = 1; i < [self.viewControllers count]; i++)
    {
        UIViewController *vc = [self.viewControllers objectAtIndex:i];
        [NSObject cancelPreviousPerformRequestsWithTarget:vc];
        [[NSNotificationCenter defaultCenter] removeObserver:vc];
        ITLogEX(@"removeObserver %@",vc);
    }
    return [self popToRootViewControllerAnimated:animated];
}

- (BOOL)shouldAutorotate{
    return [self.topViewController shouldAutorotate];
//    if([self.topViewController isKindOfClass:[MWPhotoBrowser class]]){
//        return YES;
//    }
//    return [super shouldAutorotate];
}
- (NSUInteger)supportedInterfaceOrientations {
    return [self.topViewController supportedInterfaceOrientations];
//    if([self.topViewController isKindOfClass:[MWPhotoBrowser class]]){
//        return UIInterfaceOrientationMaskAll;
//    }
//    return UIInterfaceOrientationMaskPortrait;
}

@end


@interface UIViewController (Additions) <MWPhotoBrowserShowPhotoExitDelegate>
@end

@implementation UIViewController (Additions)

-(void)hotspotStateChange:(NSNotification *)noti
{
    
}

-(void)setIsOpenHotspot:(BOOL)isOpenHotspot
{
    
}

-(BOOL)isOpenHotspot //打开热点分享 turn on personnel HOT SPOT
{
    return NO;
}

-(void)initHotspot
{
    BOOL isOpen = [self isOpenHotspot];
    ///BOOL isCurrent = (self.view.bounds.size.height == ([ACConfigs isPhone5]?548:460));
    BOOL isCurrent = (self.view.bounds.size.height == (kScreen_Height - 20));
//    ITLog(([NSString stringWithFormat:@"%d %d %f",isOpen,isCurrent,self.view.bounds.size.height]));
   
    if (isOpen != isCurrent)
    {
        [self setIsOpenHotspot:isCurrent];
        [self hotspotStateChange:nil];
        [self.view setNeedsLayout];
    }
}

-(void)ACpresentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion
{
    [[ACConfigs shareConfigs].currentPresentVCList addObject:viewControllerToPresent];
    [self presentViewController:viewControllerToPresent animated:flag completion:completion];
}

- (void)ACpresentMoviePlayerViewControllerAnimated:(MPMoviePlayerViewController *)moviePlayerViewController
{
    [[ACConfigs shareConfigs].currentPresentVCList addObject:moviePlayerViewController];
    [self presentMoviePlayerViewControllerAnimated:moviePlayerViewController];
}

-(void)ACdismissViewControllerAnimated:(BOOL)flag completion:(void (^)())completion
{
    ITLogEX(@"%@",self.navigationController.viewControllers);
    for (int i = 1; i < [self.navigationController.viewControllers count]; i++)
    {
        //为什么????
        UIViewController *vc = [self.navigationController.viewControllers objectAtIndex:i];
        [NSObject cancelPreviousPerformRequestsWithTarget:vc];
        [[NSNotificationCenter defaultCenter] removeObserver:vc];
        
#ifdef ACUtility_Need_Log
        NSString* stringInfo = [NSString stringWithFormat:@"%@",vc];
        if([stringInfo containsString:@"ACChatMessageViewController"]){
            ITLogEX(@"removeObserver %@ %@",stringInfo,[NSThread callStackSymbols]);
        }
        else{
            ITLogEX(@"removeObserver %@",stringInfo);
        }
#endif
    }
    [[ACConfigs shareConfigs].currentPresentVCList removeObject:self];
    [self dismissViewControllerAnimated:flag completion:completion];
}

-(void)ACdismissViewControllerAnimated:(BOOL)flag completion:(void (^)())completion withTip:(NSString*)pTip{
    if(nil==pTip){
        [self ACdismissViewControllerAnimated:flag completion:completion];
        return;
    }
    
    RIButtonItem* pCalcelButton = [RIButtonItem itemWithLabel:NSLocalizedString(@"OK", nil) action:^{
        [self ACdismissViewControllerAnimated:flag completion:completion];
    }];
    
    UIAlertView *pTipView = [[UIAlertView alloc] initWithTitle:nil
                                                       message:pTip
                                              cancelButtonItem:pCalcelButton
                                              otherButtonItems:nil, nil];
    [pTipView show];
}

//add by zhiyuan for rotation on 2015-02-02
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

//end by zhiyuan for rotation on 2015-02-02

-(void)onPhotoBrowserShowPhotoExit:(MWPhotoBrowser*) pphotoBrower{
//    [[ACConfigs shareConfigs] presentLoginVCWithErrTip:@"测试" orErrResponse:nil];
//    ITLog(@"TXB");
//    代替[self ACdismissViewControllerAnimated:YES completion:nil];
    [[ACConfigs shareConfigs].currentPresentVCList removeObject:self];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) _MWPhotoBrowser_ShowPhotoFunc:(MWPhotoBrowser*)pMWPhotoBrowser{
    if(pMWPhotoBrowser){
        pMWPhotoBrowser.displayActionButton = YES;
        pMWPhotoBrowser.delegateForShowPhoto = self;
        UINavigationController *navC = [[UINavigationController alloc] initWithRootViewController:pMWPhotoBrowser];
        [self ACpresentViewController:navC animated:YES completion:nil];
    }
}

//-(void) MWPhotoBrowser_ShowPhotos:(NSArray *)photosArray{ //<MWPhoto>
//    [self _MWPhotoBrowser_ShowPhotoFunc:[[MWPhotoBrowser alloc] initWithPhotos:photosArray]];
//}

-(void) MWPhotoBrowser_ShowPhotoFile:(NSString*)pFilePathName withURL:(NSString*)pURL{
    [self _MWPhotoBrowser_ShowPhotoFunc:[[MWPhotoBrowser alloc] initWithPhotoFile:pFilePathName withURL:pURL]];
}

-(void) MWPhotoBrowser_ShowUserIcon1000:(NSString*)icon{
    BOOL bIsURL = NO;
    NSString* pFilePathName = [UIImageView getIconInfoWithIconString:icon ImageType:ImageType_UserIcon1000 isURL:&bIsURL];
    if(nil==pFilePathName){
        return;
    }
    NSString* pURL = nil;
    if(bIsURL){
        pURL =  pFilePathName;
        pFilePathName = nil;
    }
    [self  MWPhotoBrowser_ShowPhotoFile:(NSString*)pFilePathName withURL:(NSString*)pURL];
}


-(void) selectImagesWithELC_Delegate:(id)delgate withCount:(int)nCount{ //选多图
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] initImagePicker];
        
        elcPicker.returnsOriginalImage = YES; //Only return the fullScreenImage, not the fullResolutionImage
        elcPicker.returnsImage = YES; //Return UIimage if YES. If NO, only return asset location information
        //        elcPicker.onOrder = NO; //For multiple image selection, display and return order of selected images
        //        elcPicker.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie]; //Supports image and movie types
        //        [ELCConsole mainConsole]
        elcPicker.maximumImagesCount  = nCount;//Set the maximum number of images to select to 100
        //        elcPicker.mediaTypes          = @[(__bridge NSString *)kUTTypeImage];
        elcPicker.imagePickerDelegate = delgate;
        
        [self ACpresentViewController:elcPicker animated:YES completion:nil];
    }

}

extern const CFStringRef kUTTypeImage;
extern const CFStringRef kUTTypeMovie;


-(void) videoWithUIImagePickerController_Delegate:(id)delgate fromRecord:(BOOL)bRecord{ //录像
    
    if([ACVideoCall inVideoCallAndShowTip]){
        //避免录像和播放视频
        return;
    }
    
    if(bRecord){
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
                UIImagePickerController *imagePC = [[UIImagePickerController alloc] init];
                imagePC.delegate = delgate;
                imagePC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                imagePC.mediaTypes = @[(__bridge NSString *)kUTTypeMovie];
                imagePC.videoQuality = UIImagePickerControllerQualityTypeMedium;
                imagePC.sourceType = UIImagePickerControllerSourceTypeCamera;
                imagePC.videoMaximumDuration = Send_Video_Maximum_Duration;
                [self ACpresentViewController:imagePC animated:YES completion:nil];
        }
        return;
    }

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]){
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = delgate;
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.mediaTypes =  @[(__bridge NSString *) kUTTypeMovie];
        [self ACpresentViewController:imagePicker animated:YES completion:nil];
    }
}

-(void) selectImageWithUIImagePickerController_Delegate:(id)delgate forCamera:(BOOL)camera{ //选取一张图片或拍照
    
    if(camera){
        if([ACVideoCall inVideoCallAndShowTip]){
            return;
        }
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        {
            UIImagePickerController *imagePC = [[UIImagePickerController alloc] init];
            imagePC.delegate = delgate;
            imagePC.videoQuality = UIImagePickerControllerQualityType640x480;
            imagePC.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePC.mediaTypes = @[(__bridge NSString *)kUTTypeImage];
//            imagePC.showsCameraControls = NO;
            [self ACpresentViewController:imagePC animated:YES completion:nil];
        }
        return;
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        UIImagePickerController *imagePC = [[UIImagePickerController alloc] init];
        imagePC.delegate = delgate;
        //        imagePC.allowsEditing = YES;
        imagePC.videoQuality = UIImagePickerControllerQualityType640x480;
        imagePC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self ACpresentViewController:imagePC animated:YES completion:nil];
    }
}

/*
- (UIViewController*)topViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}
- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    } else {
        return rootViewController;
    }
}*/

@end
