//
//  ACMapBrowerViewController.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-18.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACMapBrowerViewController.h"
#import "UINavigationController+Additions.h"
#import "ACConfigs.h"
#import "UIView+Additions.h"
///
#import "ACGoogleHotspot.h"
#import "ASIHTTPRequest.h"
#import "JSONKit.h"

@interface ACMapBrowerViewController ()

@property (nonatomic,strong) NSMutableArray     *dataSourceArray;

//@property (nonatomic,strong) NSString* destination;

@end

@implementation ACMapBrowerViewController

- (void)dealloc
{
    _mapView.delegate = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _mapView.centerCoordinate = _coordinate;
    if (![ACConfigs isPhone5])
    {
        [_mapView setFrame_height:_mapView.size.height-88];
    }
    
    _isFirstBrowser = YES;
    MKPointAnnotation *ann = [[MKPointAnnotation alloc] init];
    ann.coordinate = _coordinate;
    [_mapView addAnnotation:ann];
//    [_backButton setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateNormal];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
}

- (IBAction)gotoMap:(id)sender {
//    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
//     //app名称
//    NSString *appName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
//    
//    NSString *urlScheme = @"Acucom";
    
    //当前的位置
//    MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
    
    [self _googleSearchWithCoordinateDefault:_mapView.centerCoordinate];
//    currentLocation.name = _destination;
//    NSLog(@"%@",_destination);
//    //目的地的位置
//    MKMapItem *toLocation = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:_mapView.centerCoordinate addressDictionary:nil]];
//    
//   
//
//    NSArray *items = [NSArray arrayWithObjects:currentLocation, toLocation, nil];
//    
//    NSDictionary *options = @{ MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving, MKLaunchOptionsMapTypeKey: [NSNumber numberWithInteger:MKMapTypeStandard], MKLaunchOptionsShowsTrafficKey:@YES }; //打开苹果自身地图应用，并呈现特定的item
//    
//    [MKMapItem openMapsWithItems:items launchOptions:options];
    
    //谷歌地图
   // NSString *urlString = [[NSString stringWithFormat:@"comgooglemaps://?x-source=%@&x-success=%@&saddr=&daddr=%f,%f&directionsmode=driving",appName,urlScheme,_mapView.centerCoordinate.latitude, _mapView.centerCoordinate.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

//    //高德地图

  //  NSString *urlString = [[NSString stringWithFormat:@"iosamap://navi?sourceApplication=%@&backScheme=%@&lat=%f&lon=%f&dev=0&style=2",appName,urlScheme,_mapView.centerCoordinate.latitude, _mapView.centerCoordinate.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    
    //[[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]];

    /*
    //网页版google地图
    CLLocationCoordinate2D coords1 = CLLocationCoordinate2DMake(39.915,116.404);
    
    CLLocationCoordinate2D coords2 = CLLocationCoordinate2DMake(40.001,116.404);
    
    NSString *urlString = [[NSString alloc] initWithFormat:@"http://maps.google.com/maps?saddr=%f,%f&daddr=%f,%f&dirfl=d", coords1.latitude,coords1.longitude,coords2.latitude,coords2.longitude];
    
    NSURL *aURL = [NSURL URLWithString:urlString]; //打开网页google地图
    
    [[UIApplication sharedApplication] openURL:aURL];

    */
}

-(void)_googleSearchWithCoordinateDefault:(CLLocationCoordinate2D)coordinate{
    ACGoogleHotspot *hotspotUser = [[ACGoogleHotspot alloc] init];
    hotspotUser.name    =   NSLocalizedString(@"Send the location at the center", nil);
    [self _googleSearchWithCoordinate1:coordinate withInfo:hotspotUser];
}

-(void)_googleSearchWithCoordinate1:(CLLocationCoordinate2D)coordinate withInfo:(ACGoogleHotspot*)coordinateInfo{
    
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *googleSearchUrl = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/search/json?location=%lf,%lf&radius=%d&sensor=false&key=%@",coordinate.latitude,coordinate.longitude,coordinateInfo?500:1,kGoogleSearchKey];
        ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:googleSearchUrl]];
        request.timeOutSeconds = 100;
        [request setValidatesSecureCertificate:NO];
        __block ASIHTTPRequest *requestTmp = request;
        
        
        
        [request setCompletionBlock:^{
            NSDictionary *jsonDic = [[requestTmp responseData] objectFromJSONData];
            NSArray *results = [jsonDic objectForKey:@"results"];
            //            ITLogEX(@"%@ %@",googleSearchUrl,jsonDic);
            NSMutableArray* resultAddrs = [ACGoogleHotspot googleHotspotsWithJsonArray:results];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if(coordinateInfo){
                    _dataSourceArray    =   resultAddrs;
                    [_dataSourceArray insertObject:coordinateInfo atIndex:0];
                    
                    ACGoogleHotspot *hotspot = _dataSourceArray[4];

                    //目的地的位置
                    MKMapItem *toLocation = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:_mapView.centerCoordinate addressDictionary:nil]];
                    
                    toLocation.name = hotspot.name;
                    
                    NSArray *items = [NSArray arrayWithObjects:[MKMapItem mapItemForCurrentLocation], toLocation, nil];
                    
                    NSDictionary *options = @{ MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving, MKLaunchOptionsMapTypeKey: [NSNumber numberWithInteger:MKMapTypeStandard], MKLaunchOptionsShowsTrafficKey:@YES }; //打开苹果自身地图应用，并呈现特定的item
                    
                    [MKMapItem openMapsWithItems:items launchOptions:options];


                }
                else if(resultAddrs.count) {
                    [self _googleSearchWithCoordinate1:coordinate withInfo:resultAddrs[0]];
                }
                else{
                    [self _googleSearchWithCoordinateDefault:coordinate];
                }
            });
        }];
        [request setFailedBlock:^{
            if(coordinateInfo){
                dispatch_async(dispatch_get_main_queue(), ^{
///                    _mainTableView.tableHeaderView = nil;

                    [self.view showNetErrorHUD];
                });
            }
            else{
                [self _googleSearchWithCoordinateDefault:coordinate];
            }
        }];
        [request startAsynchronous];
//    });
}


-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self initHotspot];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initHotspot];
}

#pragma mark -notification
-(void)hotspotStateChange:(NSNotification *)noti
{
    if (_isOpenHotspot)
    {
        [_mapView setFrame_height:_mapView.size.height-hotsoptHeight];
    }
    else
    {
        [_mapView setFrame_height:_mapView.size.height+hotsoptHeight];
    }
}

#pragma mark -mapViewDelegate
-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (_isFirstBrowser)
    {
        _isFirstBrowser = NO;
        CLLocation *objectLocaton = [[CLLocation alloc] initWithLatitude:_coordinate.latitude longitude:_coordinate.longitude];
        CLLocation *selfLocaton = userLocation.location;
        double distance = [selfLocaton distanceFromLocation:objectLocaton];
        _mapView.region = MKCoordinateRegionMake(_coordinate, MKCoordinateSpanMake(distance/1000000.0, distance/1000000.0));
    }
}

#pragma mark -IBAction
-(IBAction)goback:(id)sender
{
    ITLog(@"TXB");
    [self ACdismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
