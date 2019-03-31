//
//  ELCImagePickerController.h
//  ELCImagePickerDemo
//
//  Created by ELC on 9/9/10.
//  Copyright 2010 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ELCAssetSelectionDelegate.h"

//只用于选择图片

@class ELCImagePickerController;
@class ELCAlbumPickerController;

@interface ELCSelectedImageInfo : NSObject
@property (nonatomic,strong) UIImage* image;
@property (nonatomic,copy) NSString* caption;
+(NSMutableArray<ELCSelectedImageInfo*> *) loadFromELCAssets:(NSArray<ELCAsset*>*)assets;
@end

extern NSString *const ELCImagePickerControllerResourceID;
extern NSString *const ELCImagePickerControllerImageHeight;

@protocol ELCImagePickerControllerDelegate <UINavigationControllerDelegate>

/**

 info内容为Dict
 {ELCImagePickerControllerResourceID:@"ResourceID",ELCImagePickerControllerImageHeight:(float)hight}
 
 */
- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info;

/**
 * Called when image selection was cancelled, by tapping the 'Cancel' BarButtonItem.
 */
- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker;

//实现发送并预览图片命令 ImagesWithCaption<ELCSelectedImageInfo*>
- (void)elcImagePickerController:(ELCImagePickerController *)picker sendPreviewImgWithCaptions:(NSArray<ELCSelectedImageInfo*> *)ImageWithCaptions;
@end

@interface ELCImagePickerController : UINavigationController <ELCAssetSelectionDelegate>

@property (nonatomic, weak) id<ELCImagePickerControllerDelegate> imagePickerDelegate;
@property (nonatomic, assign) NSInteger maximumImagesCount;
@property (nonatomic, assign) BOOL onOrder;
/**
 * An array indicating the media types to be accessed by the media picker controller.
 * Same usage as for UIImagePickerController.
 */
//@property (nonatomic, strong) NSArray *mediaTypes;

/**
 * YES if the picker should return a UIImage along with other meta info (this is the default),
 * NO if the picker should return the assetURL and other meta info, but no actual UIImage.
 */
@property (nonatomic, assign) BOOL returnsImage;

/**
 * YES if the picker should return the original image,
 * or NO for an image suitable for displaying full screen on the device.
 * Does nothing if `returnsImage` is NO.
 */
@property (nonatomic, assign) BOOL returnsOriginalImage;

- (id)initImagePicker;

@end

