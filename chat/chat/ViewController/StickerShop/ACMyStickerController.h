//
//  ACMyStickerController.h
//  chat
//
//  Created by 王方帅 on 14-8-20.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACSuit.h"

@interface ACMyStickerController : UIViewController<UITableViewDelegate,UITableViewDataSource>
{
    __weak IBOutlet UITableView    *_mainTableView;
//    __weak IBOutlet UIView         *_tableHeaderView;
    __weak IBOutlet UIView         *_contentView;
    
    __weak IBOutlet UILabel *_titleLable;
    __weak IBOutlet UIButton *_sortButton;
    
//    __weak IBOutlet UILabel *_tableHeadTitleLable;
}

@property (nonatomic,strong) NSMutableArray     *downloadArray;
@property (nonatomic,strong) NSMutableArray     *undownloadArray;

-(void)reloadData;

-(void)downloadSuitWithSuit:(ACSuit *)suit;

-(void)removeSuit:(ACSuit *)suit;

+(NSMutableArray*)loadMySuits;  //ACSuit*

@end
