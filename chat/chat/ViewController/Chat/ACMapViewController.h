//
//  ACMapViewController.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-18.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>


@interface ACMapViewController : UIViewController<MKMapViewDelegate,UITableViewDataSource,UITableViewDelegate>


- (id)initWithSuperVC:(UIViewController *)superVC;

@property (nonatomic,strong) NSMutableArray     *dataSourceArray;
@property (nonatomic) BOOL                      isOpenHotspot;

@end
