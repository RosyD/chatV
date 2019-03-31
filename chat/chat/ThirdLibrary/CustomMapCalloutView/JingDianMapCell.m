//
//  JingDianMapCell.m
//  IYLM
//
//  Created by Jian-Ye on 12-11-8.
//  Copyright (c) 2012年 Jian-Ye. All rights reserved.
//

#import "JingDianMapCell.h"

@implementation JingDianMapCell

-(void)awakeFromNib
{
    [super awakeFromNib];
    UIImage *image = [[UIImage imageNamed:@"mapinfo_textbox_default.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 10, 5)];
    [_cellButton setBackgroundImage:image forState:UIControlStateNormal];
    
    image = [[UIImage imageNamed:@"mapinfo_textbox_on.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 10, 5)];
    [_cellButton setBackgroundImage:image forState:UIControlStateHighlighted];
//    [_cellButton setBackgroundImage:nil forState:UIControlStateNormal];
//    [_cellButton setBackgroundImage:nil forState:UIControlStateHighlighted];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
