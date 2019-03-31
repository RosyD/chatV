//
//  ACChatViewPopMenuView.h
//  chat
//
//  Created by Aculearn on 16/1/26.
//  Copyright © 2016年 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACChatViewPopMenuView : UIView

-(id)initWithPoint:(CGPoint)point titles:(NSArray *)titles images:(NSArray *)images;
-(void)showInSpuerView:(UIView*)pView withBlock:(void(^)(NSInteger index))select;
-(void)dismiss;
-(void)dismiss:(BOOL)animated;

@property (nonatomic, copy) UIColor *borderColor;


@end
