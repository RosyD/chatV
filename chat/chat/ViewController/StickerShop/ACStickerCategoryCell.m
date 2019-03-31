//
//  ACStickerCategoryCell.m
//  chat
//
//  Created by 王方帅 on 14-8-19.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACStickerCategoryCell.h"
#import "ACStickerGalleryController.h"

@implementation ACStickerCategoryCell



-(void)setCategory:(ACStickerCategory *)category superVC:(ACStickerGalleryController *)superVC
{
    _category = category;
    _superVC = superVC;
    _titleLabel.text = _category.categoryName;
}

-(void)selectViewHidden:(BOOL)hidden
{
    [_selectedView setHidden:hidden];
}

@end
