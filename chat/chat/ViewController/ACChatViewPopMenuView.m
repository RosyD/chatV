//
//  ACChatViewPopMenuView.m
//  chat
//
//  Created by Aculearn on 16/1/26.
//  Copyright © 2016年 Aculearn. All rights reserved.
//

#import "ACChatViewPopMenuView.h"
#import "ACUtility.h"


#define kArrowHeight 10.f
#define kArrowCurvature 6.f
#define SPACE 2.f
#define ROW_HEIGHT 44.f
#define TITLE_FONT [UIFont systemFontOfSize:16]
#define RGB(r, g, b)    [UIColor colorWithRed:(r)/255.f green:(g)/255.f blue:(b)/255.f alpha:1.f]

@interface ACChatViewPopMenuView(){
    CGPoint _showPoint;
    NSArray *_titleArray;
    NSArray *_imageArray;
    UIButton *_handerView;
}
@property (nonatomic, copy) void (^selectRowAtIndex)(NSInteger index);

@end

@implementation ACChatViewPopMenuView

AC_MEM_Dealloc_implementation

-(id)initWithPoint:(CGPoint)point titles:(NSArray *)titles images:(NSArray *)images
{
    self = [super init];
    if (self) {
        _showPoint = point;
        _titleArray = titles;
        _imageArray = images;
        
        self.backgroundColor = [UIColor clearColor];
        self.frame = [self getViewFrame];
        self.borderColor = RGB(0x49,0x49,0x4b);
        
        CGRect frame = CGRectMake(SPACE+SPACE, kArrowHeight + SPACE, self.frame.size.width-(SPACE * 4), ROW_HEIGHT-1);
        
        for(int i=0;i<titles.count;i++){
            
            //加横线
            if(i<(titles.count-1)){
                CGRect frameForLine =   frame;
                frameForLine.size.height = 1;
                frameForLine.origin.y += ROW_HEIGHT;
                frameForLine.origin.x += 10;
                frameForLine.size.width -= 20;
                
                UIView* pLine = [[UIView alloc] initWithFrame:frameForLine];
                pLine.backgroundColor = UIColor_RGB(0x5c, 0x5a, 0x5f);
                [self addSubview:pLine];
            }
            
            CGRect TempRect = frame;
            
            //图像
            TempRect.size.width = TempRect.size.height;
            UIImageView* pImagV = [[UIImageView alloc] initWithFrame:TempRect];
            pImagV.contentMode = UIViewContentModeCenter;
            pImagV.image = [UIImage imageNamed:images[i]];
            [self addSubview:pImagV];
            
            //Lable
            TempRect = frame;
            TempRect.origin.x +=    TempRect.size.height;
            TempRect.size.width -=   TempRect.size.height;
            UILabel* lable = [[UILabel alloc] initWithFrame:TempRect];
            lable.text  = titles[i];
            lable.textAlignment = NSTextAlignmentCenter;
            lable.textColor = [UIColor whiteColor];
//            lable.backgroundColor = [UIColor redColor];
            [self addSubview:lable];
            
            
            
            UIButton* pButton = [UIButton buttonWithType:UIButtonTypeCustom];
            pButton.frame = frame;
//            pButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            
            /*
            [pButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            
            UIImage *yuyinImage = [UIImage imageNamed:images[i]];
            [pButton setImage:yuyinImage forState:UIControlStateNormal];
            [pButton setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 15)];
            
            [pButton setTitle:titles[i] forState:UIControlStateNormal];
            [pButton setTitleEdgeInsets:UIEdgeInsetsMake(5, 10, 5, 0)];*/
            
            pButton.tag = 100+i;
            
            [pButton addTarget:self  action:@selector(onButtonSelect:) forControlEvents:UIControlEventTouchUpInside];
//            [myButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)]; 4个参数是上边界，左边界，下边界，右边界。
            
            frame.origin.y +=   ROW_HEIGHT;
            [self addSubview:pButton];
        }
        
    }
    return self;
}

-(CGRect)getViewFrame
{
    CGRect frame = CGRectZero;
    
    frame.size.height = [_titleArray count] * ROW_HEIGHT + SPACE + kArrowHeight+SPACE;
    
    for (NSString *title in _titleArray) {
        CGFloat width =  [title sizeWithFont:TITLE_FONT constrainedToSize:CGSizeMake(300, 100) lineBreakMode:NSLineBreakByCharWrapping].width;
        frame.size.width = MAX(width, frame.size.width);
    }
    
    if ([_titleArray count] == [_imageArray count]) {
        frame.size.width = 10 + 25 + 10 + frame.size.width + 40;
    }else{
        frame.size.width = 10 + frame.size.width + 40;
    }
    
    frame.origin.x = _showPoint.x - frame.size.width/2;
    frame.origin.y = _showPoint.y;
    
    //左间隔最小5x
    if (frame.origin.x < 5) {
        frame.origin.x = 5;
    }
    //右间隔最小5x
    if ((frame.origin.x + frame.size.width) > 315) {
        frame.origin.x = kScreen_Width - 5 - frame.size.width;
    }
    
    return frame;
}

- (void)drawRect:(CGRect)rect
{
//    [self.borderColor set]; //设置线条颜色
    
    CGRect frame = CGRectMake(0, 10, self.bounds.size.width, self.bounds.size.height - kArrowHeight);
    
    float xMin = CGRectGetMinX(frame);
    float yMin = CGRectGetMinY(frame);
    
    float xMax = CGRectGetMaxX(frame);
    float yMax = CGRectGetMaxY(frame);
    
    CGPoint arrowPoint = [self convertPoint:_showPoint fromView:_handerView];
    
    UIBezierPath *popoverPath = [UIBezierPath bezierPath];
    [popoverPath moveToPoint:CGPointMake(xMin, yMin)];//左上角
    
    /********************向上的箭头**********************/
    [popoverPath addLineToPoint:CGPointMake(arrowPoint.x - kArrowHeight, yMin)];//left side
    [popoverPath addCurveToPoint:arrowPoint
                   controlPoint1:CGPointMake(arrowPoint.x - kArrowHeight + kArrowCurvature, yMin)
                   controlPoint2:arrowPoint];//actual arrow point
    
    [popoverPath addCurveToPoint:CGPointMake(arrowPoint.x + kArrowHeight, yMin)
                   controlPoint1:arrowPoint
                   controlPoint2:CGPointMake(arrowPoint.x + kArrowHeight - kArrowCurvature, yMin)];//right side
    /********************向上的箭头**********************/
    
    
    [popoverPath addLineToPoint:CGPointMake(xMax, yMin)];//右上角
    
    [popoverPath addLineToPoint:CGPointMake(xMax, yMax)];//右下角
    
    [popoverPath addLineToPoint:CGPointMake(xMin, yMax)];//左下角
    
    //填充颜色
    [RGB(0x49,0x49,0x4b) setFill];
    [popoverPath fill];
    
    [popoverPath closePath];
    [popoverPath stroke];
}

-(void)showInSpuerView:(UIView*)pView withBlock:(void(^)(NSInteger index))select{
    self.selectRowAtIndex = select;
    _handerView = [UIButton buttonWithType:UIButtonTypeCustom];
    [_handerView setFrame:pView.bounds];
    [_handerView setBackgroundColor:[UIColor clearColor]];
    [_handerView addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [_handerView addSubview:self];
//    _handerView.backgroundColor = [UIColor grayColor];
    
    [pView addSubview:_handerView];
    
    CGPoint arrowPoint = [self convertPoint:_showPoint fromView:_handerView];
    self.layer.anchorPoint = CGPointMake(arrowPoint.x / self.frame.size.width, arrowPoint.y / self.frame.size.height);
    self.frame = [self getViewFrame];

    
    self.alpha = 0.f;
    self.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
    [UIView animateWithDuration:0.2f delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.transform = CGAffineTransformMakeScale(1.05f, 1.05f);
        self.alpha = 1.f;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.08f delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];
}

-(void)onButtonSelect:(UIButton*)pButton{
    NSInteger nIndex = pButton.tag-100;
    void(^TempBlock)(NSInteger index) = self.selectRowAtIndex;
    [self dismiss:NO];
    TempBlock(nIndex);
}

-(void)dismiss
{
    [self dismiss:YES];
}

-(void)dismiss:(BOOL)animate
{
    if (!animate) {
        UIButton* handerView = _handerView;
        [self removeFromSuperview]; //在IOS8中，此时self会被释放
        _handerView = nil;
        [handerView removeFromSuperview];
        return;
    }
    
    [UIView animateWithDuration:0.3f animations:^{
        self.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
        self.alpha = 0.f;
    } completion:^(BOOL finished) {
        [self dismiss:NO];
    }];
    
}


@end
