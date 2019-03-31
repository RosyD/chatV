//
//  ELC_PreViewImages.h
//  PicSelectUI
//
//  Created by Aculearn on 15/10/19.
//  Copyright © 2015年 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ELCImagePickerController.h"

@interface AC_ThumbButton : UIButton
@end


#define AC_PreViewImage_Max_Count  10  //最多
@class ELCAssetTablePicker;
@interface AC_PreViewImagesWithCaption : UIViewController <UIScrollViewDelegate,UITextViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property   (weak,nonatomic) ELCAssetTablePicker* parent;


+(void)showPreviewWithCaptionForCameraWithDelegate:(id<ELCImagePickerControllerDelegate>) imagePickerDelegateForCamera
                                withImg:(UIImage*)firstImg
                               fromView:(UIViewController*)pVC;

@end
