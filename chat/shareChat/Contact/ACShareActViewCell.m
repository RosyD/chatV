//
//  ACShareActViewCell.m
//  chat
//
//  Created by 李朝霞 on 2017/2/10.
//  Copyright © 2017年 李朝霞. All rights reserved.
//

#import "ACShareActViewCell.h"


@implementation ACShareActViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
//    [_lineView setFrame:CGRectMake(0, 44, self.frame.size.width, 1)];
//    
//    [_iconImage setFrame:CGRectMake(8, 3, 38, 38)];
//    _iconImage.layer.cornerRadius = _iconImage.frame.size.width / 2;
//    _iconImage.layer.masksToBounds = YES;
//    [_iconImage setFrame:CGRectMake(0, 0, 38, 38)];
//    
//    [_title setFrame:CGRectMake(54, 12, (self.frame.size.width - 60), 20)];
    
     NSLog(@"sssssss  %@",NSStringFromCGRect(_iconImage.frame) );
    
}



- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


@end
