//
//  ACSearchDetailCell.h
//  chat
//
//  Created by 王方帅 on 14-7-8.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>


@class ACSearchDetailController;
@interface ACSearchDetailCell : UITableViewCell
{
    __weak IBOutlet UIImageView            *_iconImageView;
    __weak IBOutlet UILabel                *_contentLabel;
    __weak IBOutlet UIView                 *_lineView;
    __weak IBOutlet UILabel                *_personLabel;
    __weak IBOutlet UILabel                *_sessionLabel;
    __weak IBOutlet UIImageView            *_detailImageView;
    __weak IBOutlet UILabel                *_deletedLabel;
    
    __weak IBOutlet UILabel *_dateLable;
}

@property (nonatomic,strong) NSObject   *dataObject;
@property (nonatomic,weak) ACSearchDetailController  *superVC;

+(float)getCellHeightWithDataObject:(NSObject *)dataObject;

-(void)setDataObject:(NSObject *)dataObject superVC:(ACSearchDetailController *)superVC;

@end
