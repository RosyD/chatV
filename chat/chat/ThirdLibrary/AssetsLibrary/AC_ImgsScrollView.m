//
//  AC_ImgsScrollView.m
//  UIScrollView极限优化demo
//
//  Created by Aculearn on 15/11/25.
//  Copyright © 2015年 devgj. All rights reserved.
//

#import "AC_ImgsScrollView.h"


@interface AC_ImgsScrollView () <UIScrollViewDelegate>{
    NSMutableSet                    *_visibleImageViews;
    NSMutableSet                    *_reusedImageViews;
    AC_ImgsScrollItem               *_curImgItem;
//    NSInteger                       _curImgNo; //当前的图像编号
    __weak id<AC_ImgsScrollViewDelegate>    _delegate;
}
@end

@implementation AC_ImgsScrollView

AC_MEM_Dealloc_implementation

#pragma mark Init Views

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        self.pagingEnabled  = YES;
        self.delegate       = self;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
    }
    return self;
}

-(void)setDelegate:(id<AC_ImgsScrollViewDelegate>)delegate withFirstNo:(NSInteger)nFirstNo{
    _delegate        =  delegate;
    _curImgNo        =  -1;
    self.contentSize = CGSizeMake([delegate AC_image_count] * CGRectGetWidth(self.frame), 0);
    self.contentOffset = CGPointMake(nFirstNo*self.bounds.size.width, 0);
    [self showImages];
    [delegate AC_image_FocusAtIndex:nFirstNo forNext:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if(interfaceOrientation ==UIInterfaceOrientationPortrait||interfaceOrientation ==UIInterfaceOrientationPortraitUpsideDown)
    {
        return YES;
    }
    return NO;
}

-(void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    CGRect imageViewFrame = self.bounds;
    for(AC_ImgsScrollItem* item in _visibleImageViews){
        imageViewFrame.origin.x = imageViewFrame.size.width * item.tag;
        item.frame = imageViewFrame;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self showImages];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{      // called when scroll view grinds to a halt
    [_curImgItem setZoomScale:1.0 animated:YES];
    _curImgItem = nil;
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return nil;
}


#pragma mark - Private Method

- (void)showImages {
//    static BOOL bIsRuning = NO;
    
    // 获取当前处于显示范围内的图片的索引
    CGRect visibleBounds = self.bounds;
    CGFloat minX = CGRectGetMinX(visibleBounds);
    CGFloat maxX = CGRectGetMaxX(visibleBounds);
    CGFloat width = CGRectGetWidth(visibleBounds);
    
    NSInteger firstIndex = (NSInteger)floorf(minX / width);
    if(firstIndex<0)    {   firstIndex = 0;}
    if(firstIndex==_curImgNo){
        return;
    }
//    NSLog(@"%ld %ld",firstIndex,_curImgNo);
    
//    bIsRuning = YES;
    NSInteger lastIndex  = (NSInteger)floorf(maxX / width);
    NSInteger imgsCount    =   [_delegate AC_image_count];
    
    
    [_delegate AC_image_FocusAtIndex:firstIndex forNext:firstIndex>_curImgNo];
    _curImgNo = firstIndex;

    
    //多加载两个
    firstIndex -= 2;
    lastIndex += 2;
    
    // 处理越界的情况
    if (firstIndex < 0) {
        firstIndex = 0;
    }
    
    if (lastIndex >= imgsCount) {
        lastIndex = imgsCount - 1;
    }
 
    // 回收不再显示的ImageView
    NSInteger imageViewIndex = 0;
//    AC_ImgsScrollItem* reSetScaleView = nil;
    for (AC_ImgsScrollItem *imageView in self.visibleImageViews) {
        imageViewIndex = imageView.tag;
        // 不在显示范围内
        if (imageViewIndex < firstIndex || imageViewIndex > lastIndex) {
            [self.reusedImageViews addObject:imageView];
            imageView.image = nil;
            [_delegate AC_image_Unuse_AtIndex:imageViewIndex];
            [imageView removeFromSuperview];
        }
    }
    
    [self.visibleImageViews minusSet:self.reusedImageViews];

    // 是否需要显示新的视图
    for (NSInteger index = firstIndex; index <= lastIndex; index++) {
        BOOL isShow = NO;
        
        for (AC_ImgsScrollItem *imageView in self.visibleImageViews) {
            if (imageView.tag == index) {
                isShow = YES;
                break;
            }
        }
        
        if (!isShow) {
//            NSLog(@"Show %d",(int)index);
            [self showImageViewAtIndex:index];
        }
    }
    
    _curImgItem = nil;
    for (AC_ImgsScrollItem *imageView in self.visibleImageViews){
        if(imageView.zoomScale!=1.0){
            _curImgItem = imageView;
//            imageView.zoomScale  =1.0;
            break;
        }
    }
    
//    [reSetScaleView setZoomScale:1.0 animated:NO];
//    bIsRuning = NO;
}

// 显示一个图片view
- (void)showImageViewAtIndex:(NSInteger)index {
    
    AC_ImgsScrollItem *imageView = [self.reusedImageViews anyObject];
    
    if (imageView) {
        [self.reusedImageViews removeObject:imageView];
    } else {
        imageView = [[AC_ImgsScrollItem alloc] initWithFrame:CGRectZero];
    }
    [self.visibleImageViews addObject:imageView];
    
    imageView.zoomScale = 1.0;
    
    CGRect bounds = self.bounds;
    CGRect imageViewFrame = bounds;
    imageViewFrame.origin.x = CGRectGetWidth(bounds) * index;
    imageView.tag = index;
    imageView.frame = imageViewFrame;
//    imageView.image = [_delegate AC_image_AtIndex:index];
//    [self addSubview:imageView];
    [self addSubview:imageView];

    [_delegate AC_image_AtIndex:index withBlock:^(UIImage *img) {
        dispatch_async(dispatch_get_main_queue(), ^{
            imageView.image =   img;
        });
    }];
    
/*
    if(index==_curImgNo){
        imageView.image = [_delegate AC_image_AtIndex:index];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIImage* pImg = [_delegate AC_image_AtIndex:index];
        dispatch_async(dispatch_get_main_queue(), ^{
            @synchronized(self){
                imageView.image =   pImg;
            }
        });
    });*/
}

#pragma mark - Getters and Setters

- (NSMutableSet *)visibleImageViews {
    if (_visibleImageViews == nil) {
        _visibleImageViews = [[NSMutableSet alloc] init];
    }
    return _visibleImageViews;
}

- (NSMutableSet *)reusedImageViews {
    if (_reusedImageViews == nil) {
        _reusedImageViews = [[NSMutableSet alloc] init];
    }
    return _reusedImageViews;
}


@end

@interface AC_ImgsScrollItem(){
    UIImageView *_imageView;
}

@end

@implementation AC_ImgsScrollItem

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        self.backgroundColor = [UIColor clearColor];
//        self.backgroundColor = [UIColor greenColor];
        //        s.contentSize =CGSizeMake(320,568);
        self.delegate = self;
        self.minimumZoomScale =1;
        self.maximumZoomScale =3.0;
        //        s.tag = i+1;
        
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        
        
        UITapGestureRecognizer *doubleTap2 =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        [doubleTap2 setNumberOfTapsRequired:2];
        
        _imageView = [[UIImageView alloc]initWithFrame:self.bounds];
        _imageView.contentMode    =   UIViewContentModeScaleAspectFit;
        _imageView.userInteractionEnabled =YES;
        [_imageView addGestureRecognizer:doubleTap2];
        [self addSubview:_imageView];
    }
    return self;
}

-(UIImage*)image{
    return _imageView.image;
}

-(void)setImage:(UIImage *)image{
    _imageView.image = image;
}

-(void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    _imageView.frame = self.bounds;
}

#pragma mark UIScrollViewDelegate

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return _imageView;
}

-(void)handleDoubleTap:(UIGestureRecognizer *)gesture{
    
    UIScrollView* pScrollView = (UIScrollView*)gesture.view.superview;
    
    // Zoom
    if (pScrollView.zoomScale >= pScrollView.maximumZoomScale){// && self.zoomScale != [self initialZoomScaleWithMinScale]) {
        
        // Zoom out
        [pScrollView setZoomScale:1.0 animated:YES];
        
    } else {
        
        float newScale = [pScrollView zoomScale] * pScrollView.maximumZoomScale;//每次双击放大倍数
        CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[gesture locationInView:gesture.view]];
        [pScrollView zoomToRect:zoomRect animated:YES];
        NSLog(@"%@",NSStringFromCGSize(zoomRect.size));
    }
}

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center
{
    CGRect zoomRect;
    zoomRect.size.height =  self.frame.size.height / scale;
    zoomRect.size.width  =  self.frame.size.width  / scale;
    zoomRect.origin.x = center.x - (zoomRect.size.width  /2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height /2.0);
    return zoomRect;
}


@end
