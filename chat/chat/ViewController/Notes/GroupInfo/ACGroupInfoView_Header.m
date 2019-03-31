//
//  ACGroupInfoView_Header.m
//  chat
//
//  Created by Aculearn on 1/21/15.
//  Copyright (c) 2015 Aculearn. All rights reserved.
//

#import "ACGroupInfoView_Header.h"

@implementation ACGroupInfoView_Header

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [_groupEditButton setTitle:NSLocalizedString(@"MemberEdit", nil) forState:UIControlStateNormal];
}



@end
