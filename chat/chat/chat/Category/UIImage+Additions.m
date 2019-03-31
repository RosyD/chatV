//
//  UIImage+Additions.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-16.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "UIImage+Additions.h"

@implementation UIImage (Additions)

+(UIImage*)imageInBundle:(NSString *)name{
    return [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name
                                                                            ofType:nil]];
    
}

//UIImage缩放到固定的尺寸，新图片通过返回值返回
// Resize a UIImage. From http://stackoverflow.com/questions/2658738/the-simplest-way-to-resize-an-uiimage
-(UIImage *)imageScaledToSize:(CGSize)newSize
{
    
    UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
//不能使用这个方法，缩小图片时它只显示左上角的小图    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


//UIImage尺寸不足添黑边处理
-(UIImage *)imageBlackBackGroundToSize:(CGSize)newSize
{
    UIImage *image = [self imageScaledToBigFixedSize:newSize];
    UIGraphicsBeginImageContext(newSize);
    UIImage *backGroundImage = [UIImage imageNamed:@"5pix_blackImage.png"];
    [backGroundImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    [image drawInRect:CGRectMake((newSize.width-image.size.width)/2, (newSize.height-image.size.height)/2, image.size.width, image.size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

//UIImage缩放到固定的尺寸，高度宽度按照大的一边算
-(UIImage *)imageScaledToBigFixedSize:(CGSize)newSize
{
    CGFloat heightMultiple = self.size.height/newSize.height;
    CGFloat widthMultiple = self.size.width/newSize.width;
    if (widthMultiple > heightMultiple) {
        CGSize scaledSize = CGSizeMake(newSize.width, self.size.height/widthMultiple);
        return [self imageScaledToSize:scaledSize];
    } else {
        CGSize scaledSize = CGSizeMake(self.size.width/heightMultiple, newSize.height);
        return [self imageScaledToSize:scaledSize];
    }
}

//Intercept 会截取
-(UIImage *)imageInterceptToRect:(CGRect)newRect
{
    struct CGImage *cgImage = CGImageCreateWithImageInRect([self CGImage], newRect);
    UIImage *newImage = [UIImage imageWithCGImage:cgImage];
    
    // 要释放，否则会保留original image
    CGImageRelease(cgImage);
    return newImage;
}

//UIImage按比例将宽度高度差异小的一方缩放到指定的大小，然后截取另一方，使其跟newSize一样大
-(UIImage *)imageScaledInterceptToSize:(CGSize)newSize
{
    CGFloat heightMultiple = self.size.height/newSize.height;
    CGFloat widthMultiple = self.size.width/newSize.width;
    if (heightMultiple<widthMultiple) {
        CGSize scaledSize = CGSizeMake(self.size.width/heightMultiple, newSize.height);
        UIImage *scaledImage = [self imageScaledToSize:scaledSize];
        
        UIImage *newImage = [scaledImage imageInterceptToRect:CGRectMake((scaledSize.width-newSize.width)/2, 0, newSize.width, newSize.height)];
        return newImage;
    } else {
        CGSize scaledSize = CGSizeMake(newSize.width, self.size.height/widthMultiple);
        UIImage *scaledImage = [self imageScaledToSize:scaledSize];
        
        UIImage *newImage = [scaledImage imageInterceptToRect:CGRectMake(0, (scaledSize.height-newSize.height)/2, newSize.width, newSize.height)];
        return newImage;
    }
}

//UIImage图案填充到指定size
-(UIImage *)imageFillToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext(newSize);
    CGSize imageSize = self.size;
    int iCount = newSize.width/imageSize.width+1;
    int jCount = newSize.height/imageSize.height+1;
    for (int i = 0; i < iCount; i++)
    {
        for (int j = 0; j < jCount; j++)
        {
            [self drawInRect:CGRectMake(i*imageSize.width, j*imageSize.height, imageSize.width, imageSize.height)];
        }
    }
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    newImage = [newImage imageInterceptToRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    return newImage;
}

//UIImage左右两点拉伸
-(UIImage *)imageStretchToSize:(CGSize)newSize withX1:(float)x1 withX2:(float)x2 y:(float)y
{
    @autoreleasepool {
    UIImage *leftImage = [self imageInterceptToRect:CGRectMake(0, 0, x1*2, self.size.height*2)];
    
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"leftImage"];
    [UIImageJPEGRepresentation(leftImage, 1) writeToFile:path atomically:YES];
    
    UIImage *leftStrechImage = [self imageInterceptToRect:CGRectMake(x1*2-1, 0, 1, self.size.height*2)];
    path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"leftStrechImage"];
    [UIImageJPEGRepresentation(leftStrechImage, 1) writeToFile:path atomically:YES];
    
    UIImage *centerImage = [self imageInterceptToRect:CGRectMake(x1*2, 0, x2*2-x1*2, self.size.height*2)];
    path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"centerImage"];
    [UIImageJPEGRepresentation(centerImage, 1) writeToFile:path atomically:YES];
    
    UIImage *rightImage = [self imageInterceptToRect:CGRectMake(x2*2, 0, self.size.width*2-x2*2, self.size.height*2)];
    path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"rightImage"];
    [UIImageJPEGRepresentation(rightImage, 1) writeToFile:path atomically:YES];
    
    UIImage *rightStrechImage = [self imageInterceptToRect:CGRectMake(x2*2, 0, 2, self.size.height*2)];
    path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"rightStrechImage"];
    [UIImageJPEGRepresentation(rightStrechImage, 1) writeToFile:path atomically:YES];
    
    float width = (newSize.width - self.size.width)/2;
    
    
    UIGraphicsBeginImageContext(CGSizeMake(newSize.width*2, newSize.height*2));
    float currentX = 0;
    //左
    [leftImage drawInRect:CGRectMake(0, 0, leftImage.size.width, leftImage.size.height)];
    currentX = leftImage.size.width;
    for (int i = 0; i < width; i++)
    {
        [leftStrechImage drawInRect:CGRectMake(currentX+i, 0, 1, leftStrechImage.size.height)];
    }
    currentX += width;
    //中
    [centerImage drawInRect:CGRectMake(currentX, 0, centerImage.size.width, centerImage.size.height)];
    currentX += centerImage.size.width;
    //右
    for (int i = 0; i < width; i++)
    {
        [rightStrechImage drawInRect:CGRectMake(currentX+i, 0, 1, rightStrechImage.size.height)];
    }
    currentX += width;
    [rightImage drawInRect:CGRectMake(currentX, 0, rightImage.size.width, rightImage.size.height)];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
    }
}

- (UIImage *)fixOrientation {
    
    // No-op if the orientation is already correct
    if (self.imageOrientation == UIImageOrientationUp) return self;
    
#if 0
    // 原始图片可以根据照相时的角度来显示，但UIImage无法判定，于是出现获取的图片会向左转９０度的现象。
    // 以下为调整图片角度的部分
    UIGraphicsBeginImageContext(self.size);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    UIImage* pRetImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    // 调整图片角度完毕
    
    return pRetImage;
#else
    
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage), 0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
#endif
}
@end
