//
//  ACMapViewController.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-18.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACMapViewController.h"
#import "ASIHTTPRequest.h"
#import "JSONKit.h"
#import "ACGoogleHotspot.h"
#import "ACChatMessageViewController.h"
#import "ACChatMessageViewController+Board.h"
#import "UINavigationController+Additions.h"
#import "ACConfigs.h"
#import "UIView+Additions.h"
#import "ACContributeViewController.h"

@interface ACMapViewController ()<UISearchBarDelegate>{
    __weak IBOutlet MKMapView      *_mapView;
    __weak IBOutlet UITableView    *_mainTableView;
    
    __weak IBOutlet UIButton       *_backButton;
    
    //    NSString                *_your_current_location;
    
    __weak IBOutlet UIImageView     *_centerImgView;
    
    __weak IBOutlet UIButton        *_mapLocationButton;
    __weak IBOutlet UILabel         *_titleLable;
    __weak IBOutlet UISearchBar     *_searchBar;
    __weak IBOutlet UIView          *_searchBarMarkView; //遮罩，只能放在searchBar后面
    __weak IBOutlet UITableView     *_searchResultTableView;

    __weak UIViewController                *_superVC;
    NSMutableArray                  *_searchResults;
    
}
@end

@implementation ACMapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithSuperVC:(ACChatMessageViewController *)superVC
{
    self = [super init];
    if (self) {
        _superVC = superVC;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (![ACConfigs isPhone5])
    {
        [_mainTableView setFrame_height:_mainTableView.frame.size.height-88];
        [_searchResultTableView setFrame_height:_searchResultTableView.frame.size.height-88];
//        [_mapLocationButton setFrame_y:_mapLocationButton.origin.y-88];
    }
    
   /// _centerImgView.center = CGPointMake(_mapView.center.x, _mapView.center.y-_centerImgView.bounds.size.height/2+3);
     _centerImgView.center = CGPointMake(kScreen_Width/2, (kScreen_Height - 104)/4 + 44-10);
    _centerImgView.hidden = YES;
    
    
#if TARGET_IPHONE_SIMULATOR
    _searchResults = [[NSMutableArray alloc] initWithCapacity:20];
    for(int i=0;i<20;i++){
        ACGoogleHotspot* pTT = [[ACGoogleHotspot alloc] init];
        pTT.name = [NSString stringWithFormat:@"%d",i];
        pTT.address = [NSString stringWithFormat:@"%d %d %d %d %d",i,i,i,i,i];
        [_searchResults addObject:pTT];
    }
#endif
    
    if ([CLLocationManager locationServicesEnabled])
    {
//        _mainTableView.hidden = YES;
//        _loadingActer.hidden = NO;
//        [_loadingActer startAnimating];
        [self _setActivityForTable:_mainTableView];

        _mapView.showsUserLocation = YES;
    }
    else
    {
        AC_ShowTipFunc(NSLocalizedString(@"Prompt", nil), NSLocalizedString(@"Please_Open_Location", nil));
    }
//    [_backButton setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateNormal];
    [_titleLable setText:NSLocalizedString(@"Send Location", nil)];
    _searchBar.placeholder = NSLocalizedString(@"Search Location", nil);
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
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
    if (_isOpenHotspot){
        [_mainTableView setFrame_height:_mainTableView.frame.size.height-hotsoptHeight];
    }
    else{
        [_mainTableView setFrame_height:_mainTableView.frame.size.height+hotsoptHeight];
    }
}

#pragma mark -mapViewDelegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    if(!_centerImgView.hidden){
        _mapLocationButton.hidden = NO;
        [self googleSearchWithCoordinate:_mapView.region.center];
    }
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if(_centerImgView.hidden){
        //初始化
        CLLocationCoordinate2D location =   userLocation.location.coordinate;
        _centerImgView.hidden = NO;
//        _mapLocationButton.hidden = YES;
//        bSetUserLocationCenter = YES;
        _mapView.centerCoordinate = location;
        _mapView.region = MKCoordinateRegionMake(location, MKCoordinateSpanMake(0.01, 0.01));
        [self googleSearchWithCoordinate:location];
    }
}

-(void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error
{
    if(_centerImgView.hidden){
        AC_ShowTip(error.localizedDescription);
    }
    
    ITLog(error.localizedDescription);
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    NSString* pIdentifier = nil;
    NSString* pImageName = nil;
    if (annotation == mapView.userLocation){
//        if(annotation == mapView.userLocation&&_your_current_location.length){
//            return nil;
//        }
        return nil;
        pIdentifier =   @"Custom_Annotation_Location";
        pImageName  =   @"location_MySelf";
    }
    else{
        pIdentifier =   @"Custom_Annotation";
        pImageName  =   @"location_green";
    }
    
    MKAnnotationView *annotationView =[mapView dequeueReusableAnnotationViewWithIdentifier:pIdentifier];
    if(!annotationView){
       annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                  reuseIdentifier:pIdentifier];
        annotationView.canShowCallout = YES;

        annotationView.image = [UIImage imageNamed:pImageName];
        
        UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
//        UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
//        [button setBackgroundImage:[UIImage imageNamed:@"navigate-right"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"navigate-right"] forState:UIControlStateNormal];
        [button setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin];
        button.contentEdgeInsets =  UIEdgeInsetsMake(15,15,15,15);
        annotationView.rightCalloutAccessoryView = button;
    }
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
    [self _sendLocationNo:-1 withAnnotationView:view];

//    [_superVC sendLocationMessageWithCoordinate:view.annotation.coordinate];
//    [self goback:nil];
}

//- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
//    ITLog(@"");
//}

#pragma mark -googleSearch

-(void)_setActivityForTable:(UITableView*)table{
    if(table.tableHeaderView){
        return;
    }
    CGRect rect = table.bounds;
    rect.size.height = 44;
    UIView* pView = [[UIView alloc] initWithFrame:rect];
    
    UIActivityIndicatorView* activityView= [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((rect.size.width-30)/2 , 3, 30, 30)];
    [activityView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    [activityView startAnimating];
    [pView addSubview:activityView];
    
    table.tableHeaderView = pView;
}

-(void)googleSearchWithCoordinate:(CLLocationCoordinate2D)coordinate{
    //    [self.view showNetLoadingWithAnimated:YES];
    [_dataSourceArray removeAllObjects];
    //    _mainTableView.hidden = YES;
    [_mainTableView reloadData];
    [_mapView removeAnnotations:_mapView.annotations];
    [self _setActivityForTable:_mainTableView];
    
#if 0
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    //创建位置
    CLGeocoder *revGeo = [[CLGeocoder alloc] init];
    [revGeo reverseGeocodeLocation:loc   //反向地理编码
                 completionHandler:^(NSArray *placemarks, NSError *error) {
                     ACGoogleHotspot *hotspotUser = nil;
                     if (!error && [placemarks count] > 0)
                     {
                         CLPlacemark* placemark =  [placemarks objectAtIndex:0];

                        ITLogEX(@"addressDictionary=%@\n\n",placemark.addressDictionary);
                        ITLogEX(@"name:%@\n\
                              country:%@\n\
                              postalCode:%@\n\
                              ISOcountryCode:%@\n\
                              ocean:%@\n\
                              inlandWater:%@\n\
                              locality:%@\n\
                              subLocality:%@\n\
                              administrativeArea:%@\n\
                              subAdministrativeArea:%@\n\
                              thoroughfare:%@\n\
                              subThoroughfare:%@",
                              placemark.name,
                              placemark.country,
                              placemark.postalCode,
                              placemark.ISOcountryCode,
                              placemark.ocean,
                              placemark.inlandWater,
                              placemark.administrativeArea,
                              placemark.subAdministrativeArea,
                              placemark.locality,
                              placemark.subLocality,
                              placemark.thoroughfare,
                              placemark.subThoroughfare);
                         
                         hotspotUser = [[ACGoogleHotspot alloc] init];
                         hotspotUser.name = placemark.thoroughfare;
                         if(nil==hotspotUser.name){
                             hotspotUser.name    =   [ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO) stringByReplacingOccurrencesOfString:@"\n" withString:@","];
                         }
                     }
                     [self _googleSearchWithCoordinate1:coordinate withInfo:hotspotUser];
                 }];
#else
    [self _googleSearchWithCoordinate1:coordinate withInfo:nil];
#endif
}

-(void)_googleSearchWithCoordinateDefault:(CLLocationCoordinate2D)coordinate{
    ACGoogleHotspot *hotspotUser = [[ACGoogleHotspot alloc] init];
    hotspotUser.name    =   NSLocalizedString(@"Send the location at the center", nil);
    [self _googleSearchWithCoordinate1:coordinate withInfo:hotspotUser];
}

-(void)_googleSearchWithCoordinate1:(CLLocationCoordinate2D)coordinate withInfo:(ACGoogleHotspot*)coordinateInfo{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
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
                    
                    for (ACGoogleHotspot *hotspot in _dataSourceArray){
                        MKPointAnnotation *ann = [[MKPointAnnotation alloc] init];
                        ann.coordinate = hotspot.loaction;
                        ann.title = hotspot.name;
                        ann.subtitle = hotspot.address;
                        [_mapView addAnnotation:ann];
                    }
                    _mainTableView.tableHeaderView = nil;
                    [_mainTableView reloadData];
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
                    _mainTableView.tableHeaderView = nil;
    //                [_loadingActer stopAnimating];
    //                _loadingActer.hidden = YES;
                    [self.view showNetErrorHUD];
                });
            }
            else{
                [self _googleSearchWithCoordinateDefault:coordinate];
            }
        }];
        [request startAsynchronous];
    });
}

#pragma mark -tableViewDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView==_searchResultTableView){
        return _searchResults.count;
    }
    
    return [_dataSourceArray count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"UITableViewCell_ForMapList";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
    }
    ACGoogleHotspot *googleHotspot = nil;
    if(tableView==_searchResultTableView){
        googleHotspot   =   _searchResults[indexPath.row];
    }
    else{
        googleHotspot   =   _dataSourceArray[indexPath.row];
    }
    
    cell.textLabel.text = googleHotspot.name; //21
    cell.detailTextLabel.text = googleHotspot.address; //16
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    ACGoogleHotspot *googleHotspot = _dataSourceArray[indexPath.row];
//    if(nil==_curPointAnnotation){
//        _curPointAnnotation = [[MKPointAnnotation alloc] init];
//        _curPointAnnotation.coordinate = googleHotspot.loaction;
//        _curPointAnnotation.title = googleHotspot.name;
//        _curPointAnnotation.subtitle = googleHotspot.address;
//        [_mapView addAnnotation:_curPointAnnotation];
//    }
//    else{
//        _curPointAnnotation.coordinate = googleHotspot.loaction;
//        _curPointAnnotation.title = googleHotspot.name;
//        _curPointAnnotation.subtitle = googleHotspot.address;
//    }
//    _mapView.centerCoordinate = googleHotspot.loaction;
//    _mapView.region = MKCoordinateRegionMake(googleHotspot.loaction, MKCoordinateSpanMake(0.003, 0.003));
    
    if(tableView==_searchResultTableView){
        _searchResultTableView.hidden = YES;
//        _searchBar.text = nil;
        ACGoogleHotspot *googleHotspot = _searchResults[indexPath.row];
        [self _setNewCenter:googleHotspot.loaction];
        return;
    }
    
    [self _sendLocationNo:indexPath.row withAnnotationView:nil];
    /*
    CLLocationCoordinate2D location = indexPath.row?((ACGoogleHotspot*)_dataSourceArray[indexPath.row]).loaction:_mapView.centerCoordinate;
    [_superVC sendLocationMessageWithCoordinate:location];
    [self goback:nil];*/
}

#pragma mark -IBActon

-(void)_sendLocationNo:(NSInteger)locationNo withAnnotationView:(MKAnnotationView *)view{


    if ([_superVC isKindOfClass:[ACContributeViewController class]])
    {
        ACNoteContentLocation* pInfo = [[ACNoteContentLocation alloc] init];
        if(view){
            pInfo.name =    view.annotation.title;
            pInfo.address = view.annotation.subtitle;
            pInfo.Location  =   view.annotation.coordinate;
        }
        else{
            ACGoogleHotspot* pSrc = _dataSourceArray[locationNo];
            pInfo.name =    pSrc.name;
            pInfo.address = pSrc.address;
            pInfo.Location  =   locationNo?pSrc.loaction:_mapView.centerCoordinate;
        }
        
        [(ACContributeViewController *)_superVC setLocaltion:pInfo];
    }
    else if ([_superVC isKindOfClass:[ACChatMessageViewController class]])
    {
        CLLocationCoordinate2D location = {0};
        if(view){
            location    =   view.annotation.coordinate;
        }
        else{
            location    =   locationNo?((ACGoogleHotspot*)_dataSourceArray[locationNo]).loaction:_mapView.centerCoordinate;
        }
        
        ACChatMessageViewController *superVC = (ACChatMessageViewController *)_superVC;
        [superVC sendLocationMessageWithCoordinate:location];
    }
    [self goback:nil];
}

-(IBAction)goback:(id)sender
{
    [self ACdismissViewControllerAnimated:YES completion:nil];
}

-(void)_setNewCenter:(CLLocationCoordinate2D)local{
    _mapView.centerCoordinate = local;
    _mapView.region = MKCoordinateRegionMake(_mapView.centerCoordinate, _mapView.region.span);
    //    _mapLocationButton.hidden = _bIsAutoCenter = YES;
    [self googleSearchWithCoordinate:_mapView.region.center];
}

- (IBAction)onMapLocation:(id)sender {
    [self _setNewCenter:_mapView.userLocation.location.coordinate];
//    _mapView.centerCoordinate = _mapView.userLocation.location.coordinate;
//    _mapView.region = MKCoordinateRegionMake(_mapView.centerCoordinate, _mapView.region.span);
////    _mapLocationButton.hidden = _bIsAutoCenter = YES;
//    [self googleSearchWithCoordinate:_mapView.region.center];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -keyboardNotification

-(void)_keyboardWillShowFunc:(NSNotification *)noti isShow:(BOOL)bShow{
    
    NSDictionary *info = [noti userInfo];
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    int curve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
//    if(bShow){
//        //取得 searchResultTableView 高度
//        CGSize size = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
//        CGRect frame =  _searchResultTableView.frame;
//        frame.origin.y = CGRectGetMaxY(_searchBar.frame);
//        frame.size.height = self.view.bounds.size.height-frame.origin.y-size.height-64;
//        _searchResultTableView.frame = frame;
//    }
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
//    if(!bShow){
//        _searchResultTableView.hidden = YES;
//    }
    _searchBarMarkView.hidden = !bShow;
    [UIView commitAnimations];
}

-(void)keyboardWillShow:(NSNotification *)noti{
    [self _keyboardWillShowFunc:noti isShow:YES];
}

-(void)keyboardWillHide:(NSNotification *)noti{
    [self _keyboardWillShowFunc:noti isShow:NO];
}

#pragma mark -UISearchBarDelegate

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [_searchBar resignFirstResponder];
    _searchBar.text = nil;
    _searchResultTableView.hidden = YES;
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    
    if(searchText.length==0){
        [_searchResults removeAllObjects];
        [_searchResultTableView reloadData];
        _searchResultTableView.hidden = YES;
        return;
    }
    
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    if(searchBar.text.length==0){
        return;
    }
    
    [searchBar resignFirstResponder];
    
    _searchResultTableView.hidden = NO;
    [self _setActivityForTable:_searchResultTableView];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *googleSearchUrl = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/textsearch/json?query=%@&key=%@",[searchBar.text URL_Encode],kGoogleSearchKey];
        
        ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString: googleSearchUrl]];
//                                                                       [googleSearchUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        request.timeOutSeconds = 100;
        [request setValidatesSecureCertificate:NO];
        __block ASIHTTPRequest *requestTmp = request;
        [request setCompletionBlock:^{
            NSDictionary *jsonDic = [[requestTmp responseData] objectFromJSONData];
            NSArray *results = [jsonDic objectForKey:@"results"];
            //            ITLogEX(@"%@ %@",googleSearchUrl,jsonDic);
            _searchResults = [ACGoogleHotspot googleHotspotsWithJsonArray:results];
            dispatch_async(dispatch_get_main_queue(), ^{
                _searchResultTableView.tableHeaderView = nil;
                [_searchResultTableView reloadData];
                if(_searchResults.count){
                    _searchResultTableView.hidden = NO;
                    [_searchResultTableView reloadData];
                }
                else{
                    _searchResultTableView.hidden = YES;
                }
            });
        }];
        [request setFailedBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                _searchResultTableView.tableHeaderView = nil;
                _searchResultTableView.hidden = YES;
                [self.view showNetErrorHUD];
            });
        }];
        [request startAsynchronous];
    });

}

- (IBAction)searchBarMarkViewTap:(UITapGestureRecognizer *)sender {
    [self searchBarCancelButtonClicked:_searchBar];
}


@end
