//
//  ELCImagePickerController.m
//  ELCImagePickerDemo
//
//  Created by ELC on 9/9/10.
//  Copyright 2010 ELC Technologies. All rights reserved.
//

#import "ELCImagePickerController.h"
#import "ELCAsset.h"
#import "ELCAssetCell.h"
#import "ELCAssetTablePicker.h"
#import "ELCAlbumPickerController.h"
#import <CoreLocation/CoreLocation.h>
#import <MobileCoreServices/UTCoreTypes.h>

#import "UIImage+Additions.h"
#import "ACAddress.h"
#import <MediaPlayer/MediaPlayer.h>


NSString *const ELCImagePickerControllerResourceID = @"UIImagePickerControllerResourceID";
NSString *const ELCImagePickerControllerImageHeight = @"UIImagePickerControllerImageHeight";

@implementation ELCImagePickerController

//Using auto synthesizers

- (id)initImagePicker
{
    ELCAlbumPickerController *albumPicker = [[ELCAlbumPickerController alloc] initWithStyle:UITableViewStylePlain];
    
    self = [super initWithRootViewController:albumPicker];
    if (self) {
        self.maximumImagesCount = 4;
        self.returnsImage = YES;
        self.returnsOriginalImage = YES;
        self.onOrder  = NO;
        [ELCAsset selectBegin]; //初始化ELCAsset选择索引
        [albumPicker setParent:self];
//        self.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
    }
    return self;
}

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        self.maximumImagesCount = 4;
        self.returnsImage = YES;
    }
    return self;
}

#ifdef ACUtility_Need_Log
-(void)dealloc{
    ITLog(@"");
}
#endif

- (ELCAlbumPickerController *)albumPicker
{
    return self.viewControllers[0];
}

//- (void)setMediaTypes:(NSArray *)mediaTypes
//{
//    self.albumPicker.mediaTypes = mediaTypes;
//}
//
//- (NSArray *)mediaTypes
//{
//    return self.albumPicker.mediaTypes;
//}

- (void)cancelSelectAssert
{
	if ([_imagePickerDelegate respondsToSelector:@selector(elcImagePickerControllerDidCancel:)]) {
		[_imagePickerDelegate performSelector:@selector(elcImagePickerControllerDidCancel:) withObject:self];
	}
}
- (BOOL)needSendPreview{
    return [_imagePickerDelegate respondsToSelector:@selector(elcImagePickerController:sendPreviewImgWithCaptions:)];
}

- (NSUInteger)selectMaximumImagesCount{
    return self.maximumImagesCount;
}


- (BOOL)shouldSelectAsset:(ELCAsset *)asset previousCount:(NSUInteger)previousCount
{
    BOOL shouldSelect = previousCount < self.maximumImagesCount;
    if (!shouldSelect) {
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Only %d photos please!", nil), self.maximumImagesCount];
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"You can only send %d photos at a time.", nil), self.maximumImagesCount];
        [[[UIAlertView alloc] initWithTitle:title
                                    message:message
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"Okay", nil), nil] show];
    }
    return shouldSelect;
}

- (BOOL)shouldDeselectAsset:(ELCAsset *)asset previousCount:(NSUInteger)previousCount;
{
    return YES;
}


-(void)selectedAssets:(NSArray*)_assets {
    
    
    //为chat项目做得修改
    if([_imagePickerDelegate respondsToSelector:@selector(elcImagePickerController:sendPreviewImgWithCaptions:)]){
        
        NSMutableArray *sendImages = [ELCSelectedImageInfo loadFromELCAssets:_assets];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(0==sendImages.count){
                [self cancelSelectAssert];
                return;
            }
            
            [self.view hideProgressHUDWithAnimated:YES];
            [self popToRootViewControllerAnimated:NO];
            [[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
            
            
            [_imagePickerDelegate performSelector:@selector(elcImagePickerController:sendPreviewImgWithCaptions:)
                                       withObject:self
                                       withObject:sendImages];
        });
        return;
    }

    //处理Note信息
    [self.view showProgressHUDWithLabelText:NSLocalizedString(@"Preparing", nil) withAnimated:YES];
    CGSize fullScreenSize = [UIScreen mainScreen].bounds.size;
    {
        CGFloat scale = [UIScreen mainScreen].scale;
        fullScreenSize = CGSizeMake(fullScreenSize.width * scale, fullScreenSize.height * scale);
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *returnArray = [[NSMutableArray alloc] init];
        
        NSString *resourceBaseID = [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]];
        for (int i = 0; i < [_assets count]; i++){
            
            ELCAsset* assert =  _assets[i];
            
            NSString *resourceID = [resourceBaseID stringByAppendingFormat:@"_%d",i];
//            BOOL succ = YES;
            float height = 200;
            
            
            // 对找到的图片进行操作
            @autoreleasepool {
                
                NSString *imagePath = [ACAddress getAddressWithFileName:resourceID fileType:ACFile_Type_WallboardPhoto isTemp:NO subDirName:nil];
                UIImage* fullResolutionImage =  assert.fullResolutionImageNoCache;
                [UIImageJPEGRepresentation(fullResolutionImage, 1) writeToFile:imagePath atomically:YES];
            
                //全屏图用于本地大图显示
               UIImage *middleImage = assert.fullScreenImageNoCache;
                NSString *middleImagePath = [ACAddress getAddressWithFileName:[resourceID stringByAppendingString:@"_m"] fileType:ACFile_Type_WallboardPhoto isTemp:NO subDirName:nil];
                [UIImageJPEGRepresentation(middleImage, 0.75) writeToFile:middleImagePath atomically:YES];
                
                height = middleImage.size.height;
                if (middleImage.size.width > 640)
                {
                    height /= middleImage.size.width/640;
                }
                
                UIImage *scaledImage = [middleImage imageScaledToBigFixedSize:CGSizeMake(200, 200)];
                NSString *scaledImagePath = [ACAddress getAddressWithFileName:[resourceID stringByAppendingString:@"_s"] fileType:ACFile_Type_WallboardPhoto isTemp:NO subDirName:nil];
                [UIImageJPEGRepresentation(scaledImage, 0.75) writeToFile:scaledImagePath atomically:YES];
            }
            
            NSMutableDictionary *workingDictionary = [[NSMutableDictionary alloc] init];
            
            
            [workingDictionary setObject:resourceID forKey:ELCImagePickerControllerResourceID];
            [workingDictionary setObject:[NSNumber numberWithFloat:height] forKey:ELCImagePickerControllerImageHeight];
            
//            [workingDictionary setObject:[[asset valueForProperty:ALAssetPropertyURLs] valueForKey:[[[asset valueForProperty:ALAssetPropertyURLs] allKeys] objectAtIndex:0]] forKey:UIImagePickerControllerReferenceURL];
            
            [returnArray addObject:workingDictionary];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view hideProgressHUDWithAnimated:YES];
            [self popToRootViewControllerAnimated:NO];
            [[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
            
            if([_imagePickerDelegate respondsToSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:)]) {
                [_imagePickerDelegate performSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:) withObject:self withObject:[NSArray arrayWithArray:returnArray]];
            }
        });
    });

}


/* ELCImagePickerController 原来的功能
- (void)selectedAssets:(NSArray *)assets
{
	NSMutableArray *returnArray = [[NSMutableArray alloc] init];
	
	for(ELCAsset *elcasset in assets) {
        ALAsset *asset = elcasset.asset;
		id obj = [asset valueForProperty:ALAssetPropertyType];
		if (!obj) {
			continue;
		}
		NSMutableDictionary *workingDictionary = [[NSMutableDictionary alloc] init];
		
		CLLocation* wgs84Location = [asset valueForProperty:ALAssetPropertyLocation];
		if (wgs84Location) {
			[workingDictionary setObject:wgs84Location forKey:ALAssetPropertyLocation];
		}
        
        [workingDictionary setObject:obj forKey:UIImagePickerControllerMediaType];

        //This method returns nil for assets from a shared photo stream that are not yet available locally. If the asset becomes available in the future, an ALAssetsLibraryChangedNotification notification is posted.
        ALAssetRepresentation *assetRep = [asset defaultRepresentation];

        if(assetRep != nil) {
            if (_returnsImage) {
                CGImageRef imgRef = nil;
                //defaultRepresentation returns image as it appears in photo picker, rotated and sized,
                //so use UIImageOrientationUp when creating our image below.
                UIImageOrientation orientation = UIImageOrientationUp;
            
                if (_returnsOriginalImage) {
                    imgRef = [assetRep fullResolutionImage];
                    orientation = [assetRep orientation];
                } else {
                    imgRef = [assetRep fullScreenImage];
                }
                UIImage *img = [UIImage imageWithCGImage:imgRef
                                                   scale:1.0f
                                             orientation:orientation];
                [workingDictionary setObject:img forKey:UIImagePickerControllerOriginalImage];
            }
            else{
                
            }

            [workingDictionary setObject:[[asset valueForProperty:ALAssetPropertyURLs] valueForKey:[[[asset valueForProperty:ALAssetPropertyURLs] allKeys] objectAtIndex:0]] forKey:UIImagePickerControllerReferenceURL];
            
            [returnArray addObject:workingDictionary];
        }
		
	}    
	if (_imagePickerDelegate != nil && [_imagePickerDelegate respondsToSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:)]) {
		[_imagePickerDelegate performSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:) withObject:self withObject:returnArray];
	} else {
        [self popToRootViewControllerAnimated:NO];
    }
}*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
    }
}



//TXB
//- (BOOL)onOrder
//{
//    return NO;
//    return [[ELCConsole mainConsole] onOrder];
//}
//
//- (void)setOnOrder:(BOOL)onOrder
//{
//    [[ELCConsole mainConsole] setOnOrder:onOrder];
//}

@end

@implementation ELCSelectedImageInfo
+(NSMutableArray<ELCSelectedImageInfo*> *) loadFromELCAssets:(NSArray<ELCAsset*>*)assets{
    NSMutableArray *sendImages = [[NSMutableArray alloc] init];
    for(ELCAsset* ELC_asset in assets){
        ELCSelectedImageInfo* temp = [[ELCSelectedImageInfo alloc] init];
        temp.image =    ELC_asset.fullResolutionImageNoCache;
        temp.caption    =   ELC_asset.caption;
        [sendImages addObject:temp];
    }
    return sendImages;
}

@end
