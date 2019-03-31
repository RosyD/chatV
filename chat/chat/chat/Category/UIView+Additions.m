//
//  UIView+Additions.m
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-28.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "UIView+Additions.h"
#import "MBProgressHUD.h"
#import "NSString+Additions.h"

#define kProgressHUDTag 4334

@implementation UIView (Additions)

//纵坐标和宽高不变，只修改横坐标，以下分别修改一项
-(void)setFrame_x:(CGFloat)x
{
    [self setFrame:CGRectMake(x, self.frame.origin.y, self.frame.size.width, self.frame.size.height)];
}
-(void)setFrame_y:(CGFloat)y
{
    [self setFrame:CGRectMake(self.frame.origin.x, y, self.frame.size.width, self.frame.size.height)];
}
-(void)setFrame_width:(CGFloat)width
{
    [self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, width, self.frame.size.height)];
}
-(void)setFrame_height:(CGFloat)height
{
    [self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height)];
}

-(void)setCenter_y:(CGFloat)y
{
    [self setCenter:CGPointMake(self.center.x, y)];
}

-(void)setCenter_x:(CGFloat)x
{
    [self setCenter:CGPointMake(x, self.center.y)];
}

-(CGFloat)getFrame_right
{
    return self.frame.origin.x + self.frame.size.width;
}

-(CGFloat)getFrame_Bottom
{
    return self.frame.origin.y + self.frame.size.height;
}

-(void)setSize:(CGSize)size
{
    CGRect rect = self.frame;
    rect.size = size;
    self.frame = rect;
}

-(CGSize)size
{
    return self.frame.size;
}

-(CGPoint)origin
{
    return self.frame.origin;
}

-(void)setRectRound:(CGFloat)fRound{
    [self.layer setCornerRadius:fRound];
    [self.layer setMasksToBounds:YES];
}

-(void)setToCircle{
    [self setRectRound:self.size.height/2];
}

-(void)showNetErrorHUD{
    [self showNomalTipHUD:NSLocalizedString(@"Check_Network", nil)];
}

-(void)showNomalTipHUD:(NSString*)pTip{
    [self showProgressHUDNoActivityWithLabelText:pTip
                              withAfterDelayHide:0.8];
}

-(void)showNetLoadingWithAnimated:(BOOL)animated{
    [self showProgressHUDWithLabelText:NSLocalizedString(@"Loading",nil)
                          withAnimated:animated];
}

-(void)showProgressHUD{
    [self showProgressHUDWithLabelText:nil
                          withAnimated:YES];

}


//展示ProgressHUD成功
-(void)showProgressHUDSuccessWithLabelText:(NSString *)labelText
                        withAfterDelayHide:(NSTimeInterval)afterDelay
{
    MBProgressHUD *hud = (MBProgressHUD *)[self viewWithTag:kProgressHUDTag];
    if (!hud)
    {
        hud = [[MBProgressHUD alloc] initWithView:self];
        hud.tag = kProgressHUDTag;
        [self addSubview:hud];
    }
    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
    hud.mode = MBProgressHUDModeCustomView;
    hud.labelText = labelText;
    [hud show:YES];
    [hud hide:YES afterDelay:afterDelay];
}

//展示ProgressHUD
-(void)showProgressHUDNoActivityWithLabelText:(NSString *)labelText withAfterDelayHide:(NSTimeInterval)afterDelay
{
    MBProgressHUD *hud = (MBProgressHUD *)[self viewWithTag:kProgressHUDTag];
    if (!hud)
    {
        hud = [[MBProgressHUD alloc] initWithView:self];
        hud.tag = kProgressHUDTag;
        [self addSubview:hud];
    }
    hud.customView = [[UIView alloc] init];
    hud.mode = MBProgressHUDModeCustomView;
    hud.labelText = labelText;
    [hud show:YES];
    [hud hide:YES afterDelay:afterDelay];
}

-(void)showProgressHUDWithLabelText:(NSString *)labelText withAnimated:(BOOL)animated withAfterDelayHide:(NSTimeInterval)afterDelay{
    MBProgressHUD *hud = (MBProgressHUD *)[self viewWithTag:kProgressHUDTag];
    if (!hud)
    {
        hud = [[MBProgressHUD alloc] initWithView:self];
        hud.tag = kProgressHUDTag;
        [self addSubview:hud];
    }
    hud.mode = MBProgressHUDModeIndeterminate;
//    if (!labelText){
//        labelText = NSLocalizedString(@"Loading", nil);
//    }
    hud.labelText = labelText;
    [hud show:animated];
    
    if(afterDelay>0){
        [self performSelector:@selector(hideProgressHUDWithAnimated:) withObject:[NSNumber numberWithBool:NO] afterDelay:afterDelay];
    }
}

//展示ProgressHUD
-(void)showProgressHUDWithLabelText:(NSString *)labelText withAnimated:(BOOL)animated{
    [self showProgressHUDWithLabelText:labelText withAnimated:animated withAfterDelayHide:20];
}

//隐藏ProgressHUD
-(void)hideProgressHUDWithAnimated:(BOOL)animated
{
    MBProgressHUD *hud = (MBProgressHUD *)[self viewWithTag:kProgressHUDTag];
    if (hud)
    {
        [hud hide:animated];
        [hud removeFromSuperview];
    }
}

-(BOOL)HUDShowed{
    return nil!=[self viewWithTag:kProgressHUDTag];
}

@end

@implementation UILabel (Additions)

-(void)setSingleRowAutosizeLimitWidth:(float)limitWidth
{
    NSDictionary *tdic = [NSDictionary dictionaryWithObjectsAndKeys:self.font,NSFontAttributeName, nil];
    CGSize size = [self.text boundingRectWithSize:CGSizeMake(limitWidth, self.size.height)
                                                options:(NSStringDrawingOptions)(NSStringDrawingTruncatesLastVisibleLine |NSStringDrawingUsesLineFragmentOrigin |NSStringDrawingUsesFontLeading)
                                             attributes:tdic
                                                context:nil].size;
    [self setFrame_width:size.width];
}




-(CGSize)getAutoresizeWithLimitWidth:(float)limitWidth andLimitHight:(float)fLimitHight{
    return [self.text getAutoSizeWithLimitWidth:limitWidth andLimitHight:fLimitHight font:self.font];
    /*
    NSDictionary *tdic = [NSDictionary dictionaryWithObjectsAndKeys:self.font,NSFontAttributeName, nil];
    return  [self.text boundingRectWithSize:CGSizeMake(limitWidth, fLimitHight)
                                          options:(NSStringDrawingOptions)(
                                                                           NSStringDrawingTruncatesLastVisibleLine |NSStringDrawingUsesLineFragmentOrigin |NSStringDrawingUsesFontLeading)
                                       attributes:tdic
                                          context:nil].size;*/
}

-(void)setAutoresizeWithLimitWidth:(float)limitWidth{
    [self setAutoresizeWithLimitWidth:limitWidth andLimitHight:MAXFLOAT];
}

-(void)setAutoresizeWithLimitWidth:(float)limitWidth andLimitHight:(float)fLimitHight{
    //    CGSize size = [self.text sizeWithFont:self.font constrainedToSize:CGSizeMake(limitWidth, MAXFLOAT) lineBreakMode:NSLineBreakByCharWrapping];
    //    [self setSize:size];
    //    int height = size.height/ 1000;
    //    if (size.height > 300)
    //    {
    //        size.height -= 40;
    //    }
    
    CGSize size = [self getAutoresizeWithLimitWidth:limitWidth andLimitHight:fLimitHight];
//    if(size.height>12000){
//        ITLogEX(@"%f",size.height);
//        size.height = 13000;
//    }
    
    [self setSize:size];

}

-(void)setHighlight:(NSArray<NSString*>*)highlights  withText:(NSString*)content{
    NSMutableAttributedString* pStr = [[NSMutableAttributedString alloc] initWithString:content];
    [pStr addAttributes:@{NSFontAttributeName:self.font,NSForegroundColorAttributeName:[UIColor blackColor]} range:NSMakeRange(0, content.length)];
    
    for (NSString *highLightString in highlights){
        NSUInteger len = [highLightString length];
        NSArray *array = [content componentsSeparatedByString:highLightString];
        if ([array count] > 1)
        {
            UIColor* redColor = [UIColor redColor];
            NSUInteger loc = [[array objectAtIndex:0] length];
            [pStr addAttribute:NSForegroundColorAttributeName value:redColor range:NSMakeRange(loc, len)];
            loc += len;
            for (int i = 2; i < [array count]; i++)
            {
                loc += [[array objectAtIndex:i-1] length];
                [pStr addAttribute:NSForegroundColorAttributeName value:redColor range:NSMakeRange(loc, len)];
                loc += len;
            }
        }
    }
    
    self.attributedText = pStr;
}

@end

@implementation UIButton (Additions)

-(void)setAutoresizeWithLimitWidth:(float)limitWidth
{
    NSDictionary *tdic = [NSDictionary dictionaryWithObjectsAndKeys:self.titleLabel.font,NSFontAttributeName, nil];
    CGSize size = [self.titleLabel.text boundingRectWithSize:CGSizeMake(limitWidth, 300)
                                          options:(NSStringDrawingOptions)(NSStringDrawingUsesLineFragmentOrigin |NSStringDrawingUsesFontLeading)
                                       attributes:tdic
                                          context:nil].size;
    [self setSize:CGSizeMake(size.width+30, size.height+20)];
}

-(void)setNomalText:(NSString*)pText{
    [self setTitle:pText forState:UIControlStateNormal];
}

@end

@implementation UIImageView (Additions)
-(void)fitFrame{ //通过图像适配Frame
    [self fitFrame_width:self.frame.size.width];
}
-(void)fitFrame_width:(CGFloat)fW{
    if(self.image){
        CGSize imagSize = self.image.size;
        CGRect frame = self.frame;
        frame.size.height   =   frame.size.width*imagSize.height/imagSize.width;
        self.frame  =   frame;
    }
    
}
@end
