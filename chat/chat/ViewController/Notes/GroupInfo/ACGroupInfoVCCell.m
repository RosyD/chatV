//
//  ACGroupInfoVCCell.m
//  chat
//
//  Created by Aculearn on 1/21/15.
//  Copyright (c) 2015 Aculearn. All rights reserved.
//

#import "ACGroupInfoVCCell.h"
#import "UIView+Additions.h"
#import "ACGroupInfoVC.h"

@implementation ACGroupInfoVCCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
//    [_userIconImageView.layer setMasksToBounds:YES];
//    [_userIconImageView.layer setCornerRadius:5.0];
    [_userIconImageView setToCircle];

}


-(void)buttonDelShow:(BOOL)bShow{
    [_buttonDel removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
    if(bShow){
        [_buttonDel addTarget:self action:@selector(onMemberDelete:) forControlEvents:UIControlEventTouchUpInside];
    }
    _buttonDel.hidden   =   !bShow;
}

-(void)onMemberDelete:(id)sender{
    [_pSuperVC deleteCell:self];
}

@end
