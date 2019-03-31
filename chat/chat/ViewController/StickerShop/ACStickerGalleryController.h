//
//  ACStickerGalleryController.h
//  chat
//
//  Created by 王方帅 on 14-8-14.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACSuit.h"

@class ACChatMessageViewController;
@interface ACStickerGalleryController : UIViewController
{
    __weak IBOutlet UITableView    *_mainTableView;
    __weak IBOutlet UITableView    *_categoryTableView;
    __weak ACChatMessageViewController     *_superVC;
    __weak IBOutlet UIView         *_contentView;
    int                     _requestReturnCount;
    
    __weak IBOutlet UILabel *_titleLable;
}

@property (nonatomic,strong) NSMutableArray     *dataSourceArray;
@property (nonatomic,strong) NSMutableArray     *categoryArray;
@property (nonatomic) int   selectedCategoryIndex;
@property (nonatomic,strong) NSMutableDictionary    *suitCategoryDic;

-(void)downloadSuitWithSuit:(ACSuit *)suit;

- (id)initWithSuperVC:(ACChatMessageViewController *)superVC;

@end
