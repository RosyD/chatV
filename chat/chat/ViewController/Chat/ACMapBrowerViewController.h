//
//  ACMapBrowerViewController.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-18.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface ACMapBrowerViewController : UIViewController<MKMapViewDelegate>
{
    IBOutlet __weak MKMapView      *_mapView;
    
    IBOutlet UIButton               *_backButton;
    BOOL                            _isFirstBrowser;
}

@property (nonatomic) CLLocationCoordinate2D    coordinate;
@property (nonatomic) BOOL                      isOpenHotspot;

@end
