//
//  ACImgsScrollView.h
//  UIScrollView极限优化demo
//
//  Created by Aculearn on 15/11/25.
//  Copyright © 2015年 devgj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ELCAsset.h"

/*
 用于处理图片滚动的基本信息
 */

@interface AC_ImgsScrollItem:UIScrollView <UIScrollViewDelegate>
@property (nonatomic,weak)UIImage* image;
@end

@protocol AC_ImgsScrollViewDelegate <NSObject>
    -(NSInteger)AC_image_count;
    -(void)AC_image_AtIndex:(NSInteger)nIndex withBlock:(ELCAsset_LoadImgBlock)block;
    -(void)AC_image_Unuse_AtIndex:(NSInteger)nIndex;
    -(void)AC_image_FocusAtIndex:(NSInteger)nIndex forNext:(BOOL)bNext;
@end

@interface AC_ImgsScrollView : UIScrollView

@property (nonatomic) NSInteger curImgNo;   //当前的图像编号

-(void)setDelegate:(id<AC_ImgsScrollViewDelegate>)delegate withFirstNo:(NSInteger)nFirstNo;
@end
