//
//  ACSearchCell.h
//  chat
//
//  Created by 王方帅 on 14-7-11.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACSearchController.h"
//@class ACSearchController;
@interface ACSearchCell : UITableViewCell
{
    __weak ACSearchController *_superVC;
    IBOutlet UIImageView    *_iconImageView;
    IBOutlet UILabel        *_contentLabel;
    enum SearchCountType    _searchCountType;
}


-(void)setSearchCountType:(enum SearchCountType)searchCountType superVC:(ACSearchController *)superVC;
-(void)setSearchCountType:(enum SearchCountType)searchCountType withCount:(int)nCount;

@end
