//
//  ACStickerPackageCell.h
//  chat
//
//  Created by 王方帅 on 14-8-14.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACSuit.h"
#import "MCProgressBarView.h"

@class ACStickerGalleryController;
@interface ACStickerPackageCell : UITableViewCell
{
    __weak ACStickerGalleryController      *_superVC;
    __weak IBOutlet UIImageView            *_iconImageView;
    __weak IBOutlet UILabel                *_titleLabel;
    __weak IBOutlet UILabel                *_descLabel;
    __weak IBOutlet UIButton               *_downloadButton;
    MCProgressBarView               *_progressView;
}

@property (nonatomic,strong) ACSuit     *suit;

-(void)setSuit:(ACSuit *)suit superVC:(ACStickerGalleryController *)superVC;

-(void)progressUpdate:(float)progress;

@end
