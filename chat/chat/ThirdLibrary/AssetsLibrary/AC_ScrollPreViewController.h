//
//  AC_ScrollPreViewController.h
//  chat
//
//  Created by Aculearn on 15/12/9.
//  Copyright © 2015年 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ELCAssetTablePicker;

/*
 用于滚动大图，选择
 */

@interface AC_ScrollPreViewController : UIViewController
@property   (nonatomic) NSInteger  nFistShowImgNo;


-(instancetype)initPreVCWithParent:(ELCAssetTablePicker*)parent;
@end
