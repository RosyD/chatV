//
//  ACMyStickerCell.h
//  chat
//
//  Created by 王方帅 on 14-8-20.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACSuit.h"
#import "MCProgressBarView.h"

@class ACMyStickerController;
@interface ACMyStickerCell : UITableViewCell
{
    __weak ACMyStickerController           *_superVC;
    __weak IBOutlet UIImageView            *_iconImageView;
    __weak IBOutlet UILabel                *_titleLabel;
    __weak IBOutlet UIButton               *_downloadButton;
    BOOL                            _isDelete;
    MCProgressBarView               *_progressView;
}

@property (nonatomic,strong) ACSuit     *suit;

-(void)setSuit:(ACSuit *)suit superVC:(ACMyStickerController *)superVC;

-(void)isEditing:(BOOL)isEditing;

-(void)progressUpdate:(float)progress;

@end
