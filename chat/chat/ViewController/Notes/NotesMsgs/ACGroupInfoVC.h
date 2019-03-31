//
//  ACGroupInfoVC.h
//  chat
//
//  Created by Aculearn on 15/1/13.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>



@class ACBaseEntity;
@interface ACGroupInfoVC : UIViewController<UICollectionViewDelegateFlowLayout,UICollectionViewDataSource>


//@property (nonatomic,strong) NSString           *singleChatCurrentUserID;
//@property (nonatomic,strong) NSMutableArray     *dataSourceArray;
//@property (nonatomic,strong) NSString           *titleString;
@property (nonatomic,strong) ACBaseEntity      *entity;
@property (nonatomic,weak) UIViewController    *superVC;


-(void)deleteCell:(UICollectionViewCell*)pCell;

@end
