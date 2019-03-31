//
//  ACGroupInfoVCCell.h
//  chat
//
//  Created by Aculearn on 1/21/15.
//  Copyright (c) 2015 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACGroupInfoVC;
@interface ACGroupInfoVCCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *userNameLable;
@property (weak, nonatomic) IBOutlet UIImageView *userIconImageView;
@property (weak, nonatomic) IBOutlet UIButton *buttonDel;
@property (weak, nonatomic) ACGroupInfoVC *pSuperVC;


-(void)buttonDelShow:(BOOL)bShow;

@end
