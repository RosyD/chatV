//
//  UIView+Additions.h
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-28.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Additions)

//纵坐标和宽高不变，只修改横坐标，以下分别修改一项
-(void)setFrame_x:(CGFloat)x;
-(void)setFrame_y:(CGFloat)y;
-(void)setFrame_width:(CGFloat)width;
-(void)setFrame_height:(CGFloat)height;

-(void)setCenter_x:(CGFloat)x;
-(void)setCenter_y:(CGFloat)y;

-(CGFloat)getFrame_right;
-(CGFloat)getFrame_Bottom;

@property (nonatomic,assign) CGSize size;

-(CGPoint)origin;

//展示ProgressHUD
-(void)showProgressHUDWithLabelText:(NSString *)labelText withAnimated:(BOOL)animated;
-(void)showProgressHUDWithLabelText:(NSString *)labelText withAnimated:(BOOL)animated withAfterDelayHide:(NSTimeInterval)afterDelay;

//显示网络错误提示
-(void)showNetErrorHUD;
-(void)showNomalTipHUD:(NSString*)pTip;

//显示加载
-(void)showNetLoadingWithAnimated:(BOOL)animated;
-(void)showProgressHUD;

//展示ProgressHUD成功
-(void)showProgressHUDSuccessWithLabelText:(NSString *)labelText withAfterDelayHide:(NSTimeInterval)afterDelay;

//展示ProgressHUD
-(void)showProgressHUDNoActivityWithLabelText:(NSString *)labelText withAfterDelayHide:(NSTimeInterval)afterDelay;

//隐藏ProgressHUD
-(void)hideProgressHUDWithAnimated:(BOOL)animated;

-(BOOL)HUDShowed;

//设置圆角
-(void)setRectRound:(CGFloat)fRound;
//设置为圆形
-(void)setToCircle;

@end

@interface UILabel (Additions)

-(void)setSingleRowAutosizeLimitWidth:(float)limitWidth;

-(void)setAutoresizeWithLimitWidth:(float)limitWidth;

-(CGSize)getAutoresizeWithLimitWidth:(float)limitWidth andLimitHight:(float)fLimitHight;

-(void)setAutoresizeWithLimitWidth:(float)limitWidth andLimitHight:(float)fLimitHight;

-(void)setHighlight:(NSArray<NSString*>*)highlights withText:(NSString*)text;

@end

@interface UIButton (Additions)

-(void)setAutoresizeWithLimitWidth:(float)limitWidth;
-(void)setNomalText:(NSString*)pText;

@end

@interface UIImageView (Additions)
-(void)fitFrame; //通过图像适配Frame
-(void)fitFrame_width:(CGFloat)fW;
@end
