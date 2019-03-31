//
//  ACStickerCategoryCell.h
//  chat
//
//  Created by 王方帅 on 14-8-19.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACStickerCategory.h"

@class ACStickerGalleryController;
@interface ACStickerCategoryCell : UITableViewCell
{
    __weak IBOutlet UILabel        *_titleLabel;
    __weak ACStickerGalleryController  *_superVC;
    __weak IBOutlet UIView         *_selectedView;
}

@property (nonatomic,strong) ACStickerCategory  *category;

-(void)setCategory:(ACStickerCategory *)category superVC:(ACStickerGalleryController *)superVC;

-(void)selectViewHidden:(BOOL)hidden;

@end
