//
//  ACRootViewController.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-27.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACRootViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>
{
    IBOutlet UIImageView    *_iconImageView;
    IBOutlet UILabel        *_nameLabel;
    
    BOOL                    _isFirstAppear;
    IBOutlet UIView         *_beginLineView;
}

@property (nonatomic,strong) NSIndexPath            *previousIndexPath;
@property (nonatomic,strong) IBOutlet UITableView    *mainTableView;
@property (nonatomic) BOOL                      isOpenHotspot;
@property (nonatomic,strong) NSMutableArray     *dataSourceArray;

+(void)showUserIcon200ForImageView:(UIImageView*)imgView withIconStr:(NSString*)iconStr;

-(void)showChatViewController;

@end
