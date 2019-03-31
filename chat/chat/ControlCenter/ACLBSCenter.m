//
//  ACLBSCenter.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-18.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACLBSCenter.h"
#import "ACConfigs.h"
#import "ACMessage.h"
#import "ACNetCenter.h"
#import "ACLocationSettingViewController.h"

/*
 1. 进入一个位置会话,每个消息都带位置信息,此时需要自动更新位置
 
 2. 在应用内接收到 EntityEventType_RequestLocation 事件,连续发送30秒位置变化信息
    添加到_locationAlerts,并连续发送,直到结束,在后台不处理.
 
 3. 在didReceiveRemoteNotification.fetchCompletionHandler 中取得和2相似的事件,连续发送30秒位置变化信息
    发送完后马上调用fetchCompletionHandler结束,等待处理下一个RemoteNotification,每次处理一个.
 
 
 */

//#define kAutomaticLocationTime   (8*60)   //延时启动时间

//#define uselocationAlertForRemoteNotification

typedef void(^completionHandlerForRemoteNotification)(UIBackgroundFetchResult);

@interface ACLBSCenter(){
//    BOOL                _isLocationing;     //正在定位服务中
//    BOOL                _isAuthorizationed; //授权了
    BOOL                _isInAutoUpdate;    //需要自动更新
    CLLocationManager*  _locationManager;
    NSMutableArray*     _locationAlerts;    //[ACLocationAlert]
    
#ifdef uselocationAlertForRemoteNotification
    ACLocationAlert*    _locationAlertForRemoteNotification; //为ReceiveRemoteNotification
#endif
    completionHandlerForRemoteNotification _completionHandlerForRemoteNotification;
//    BOOL    _isAutoUpdatingLocation;
//    BOOL    _isFirstLocationUpdateFail;
}

//@property (nonatomic) CLLocationCoordinate2D    location;
@property (nonatomic,readonly) BOOL                      isAuthorizationed;
//@property (nonatomic,strong) ACLocationAlert    *locationAlert;
//@property (nonatomic,strong) CLLocationManager   *locationManager;


@end



static ACLBSCenter *_shareLBSCenter = nil;

@implementation ACLBSCenter

/*
- (instancetype)init
{
    self = [super init];
    if (self) {
        _isFirstLocationUpdateFail = YES;
        _isNeedUpdateLocation = NO;
    }
    return self;
}

+(ACLBSCenter *)shareLBSCenter
{
    if (!_shareLBSCenter)
    {
        _shareLBSCenter = [[ACLBSCenter alloc] init];
    }
    return _shareLBSCenter;
}*/

-(void)_startUpdatingLocation{
//    if(_isLocationing){
//        return;
//    }
    ITLogEX(@"startUpdatingLocation");
    [_locationManager startUpdatingLocation];
//    _isLocationing = YES;
}

-(void)_stopUpdatingLocation{
    ITLogEX(@"stopUpdatingLocation");
    [ACConfigs shareConfigs].location = CLLocationCoordinate2DMake(0, 0);
    [_locationManager stopUpdatingLocation];
//    _isLocationing = NO;
}



+(void)_showLocationServicesDisableTip{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil)
                                                    message:NSLocalizedString(@"Please_Open_Location", nil)
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil, nil];
    [alert show];
}

-(BOOL)isAuthorizationed{
    return [CLLocationManager authorizationStatus]==kCLAuthorizationStatusAuthorizedAlways;
}

-(instancetype)init{
    self = [super init];
    if(self){
        _locationManager    =   [[CLLocationManager alloc] init];
        _locationAlerts     =   [[NSMutableArray alloc] init];
        

        _locationManager.distanceFilter     =   5; //每隔100m才更新一次定位信息
        _locationManager.desiredAccuracy    =   kCLLocationAccuracyBest;
        // kCLLocationAccuracyNearestTenMeters; //精确度
        _locationManager.delegate           =   self;
    
        //其实是为了取得权限
        if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        //            [locationManager requestWhenInUseAuthorization];
        //相对应info.plist中的NSLocationWhenInUseUsageDescription键
            [_locationManager requestAlwaysAuthorization];
        //相对应info.plist中的NSLocationAlwaysUsageDescription键
        }
        
        NSString* pAccount =    [[NSUserDefaults standardUserDefaults] objectForKey:kAccount];
        
        if(pAccount.length&&(
           (!self.isAuthorizationed)||(![CLLocationManager locationServicesEnabled]))){
           //提示用户
           [ACLBSCenter _showLocationServicesDisableTip];
        }
    }
    return self;
}

+(void)initACLBSCenter{
    if(nil==_shareLBSCenter){
        _shareLBSCenter = [[ACLBSCenter alloc] init];
    }
}


-(void)_addLocationAlert:(ACLocationAlert *)locationAlert{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for(NSInteger i=0;i<_locationAlerts.count;i++){
            //查找重复
            ACLocationAlert* locationAlertTemp =    _locationAlerts[i];
            if([locationAlertTemp.teid isEqualToString:locationAlert.teid]){
                [_locationAlerts removeObjectAtIndex:i];
                break;
            }
        }
        
        [_locationAlerts addObject:locationAlert];
    
        [self _startUpdatingLocation];
    });
}

+(void)locationAlertWithDic:(NSDictionary *)dic{
    ITLogEX(@"locationAlertWithDic");
    if([ACLBSCenter userAllowLocation]&&
       [CLLocationManager locationServicesEnabled]){
        ACLocationAlert* locationAlert = [[ACLocationAlert alloc] initWithEventDic:dic];
        if(locationAlert){
            ITLogEX(@"locationAlert ok");
            [_shareLBSCenter _addLocationAlert:locationAlert];
        }
    }
}


-(void)_remoteAlertStop{    
    if(_completionHandlerForRemoteNotification){
        ITLogEX(@"remoteAlert . . . . . . . . . . Stop");
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_remoteAlertStop) object:nil];
        _completionHandlerForRemoteNotification(UIBackgroundFetchResultNewData);
        _completionHandlerForRemoteNotification = nil;
     #ifdef uselocationAlertForRemoteNotification
        _locationAlertForRemoteNotification = nil;
    #endif
    }
}

-(void)_remoteAlertWithDic:(NSDictionary *)dic fetchCompletionHandler:(void(^)(UIBackgroundFetchResult)) completionHandler{

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_remoteAlertStop) object:nil];
    _completionHandlerForRemoteNotification = nil;
    
    if ([CLLocationManager locationServicesEnabled]&&
        [ACLBSCenter userAllowLocation]&&
        (self.isAuthorizationed)){
        
        ACLocationAlert* locationAlert = [[ACLocationAlert alloc] initWithEventDic:dic];
        if(locationAlert){
            ITLogEX(@"remoteAlert . . . . . . . . . . Begin");
            
        #ifdef uselocationAlertForRemoteNotification
            _locationAlertForRemoteNotification =   locationAlert;
        #else
            [self _addLocationAlert:locationAlert];
        #endif
            _completionHandlerForRemoteNotification = completionHandler;
            locationAlert.time_begin  +=  3;
            //早点结束,数据发送
            [self performSelector:@selector(_remoteAlertStop) withObject:nil afterDelay:30-10];
            [self _startUpdatingLocation];
            return;
        }
    }
    
    completionHandler(UIBackgroundFetchResultNewData);
}

+(void)remoteAlertWithDic:(NSDictionary *)dic fetchCompletionHandler:(void(^)(UIBackgroundFetchResult)) completionHandler{
    [_shareLBSCenter _remoteAlertWithDic:dic fetchCompletionHandler:completionHandler];
}


+(void)autoUpdatingLocation_Begin{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        if ([CLLocationManager locationServicesEnabled]&&
            _shareLBSCenter.isAuthorizationed){
            
            _shareLBSCenter->_isInAutoUpdate = YES;

            [_shareLBSCenter _startUpdatingLocation];
            
        }
        else{
            [ACLBSCenter _showLocationServicesDisableTip];
        }
    });
}


#ifdef uselocationAlertForRemoteNotification
    #define Have____locationAlerts  (_locationAlerts.count||_locationAlertForRemoteNotification)
#else
    #define Have____locationAlerts  _locationAlerts.count
#endif

-(void)_autoUpdatingLocation_End{
    dispatch_async(dispatch_get_main_queue(), ^{
        _isInAutoUpdate = NO;
        if(!(Have____locationAlerts)){
            //没有自动定位，则关闭它
            [self _stopUpdatingLocation];
        }
    });
}

+(void)autoUpdatingLocation_End{
//    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [_shareLBSCenter _autoUpdatingLocation_End];
}

#pragma mark CLLocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *currentLocation = [locations lastObject];
    CLLocationCoordinate2D location = currentLocation.coordinate;
    [ACConfigs shareConfigs].location = location;
    [ACUtility postNotificationName:kNotificationLocationChanged
                                                        object:nil];
    ITLogEX(@"didUpdateLocations %@",currentLocation);
    
    if(Have____locationAlerts){
       
        time_t time_now = time(NULL);
        NSMutableArray* postArray     =   [[NSMutableArray alloc] init];
        
        
        //处理RemoteNotification
    #ifdef uselocationAlertForRemoteNotification
        BOOL bNeedRemoveRemoteAlert = NO;
        if(_completionHandlerForRemoteNotification){
            NSDictionary* pDict = nil;
            if((time_now-_locationAlertForRemoteNotification.time_begin)<30){
                pDict =   [_locationAlertForRemoteNotification getPostDictFromCoordinate:location];
                if(pDict){
                    [postArray addObject:pDict];
                }
            }
            if(nil==pDict){
                bNeedRemoveRemoteAlert = YES;
            }
        }
    #endif
        
        //后处理其他信息
        for(NSInteger index = 0;index<_locationAlerts.count;index++){
            
            ACLocationAlert* locationAlertTemp =    _locationAlerts[index];
            if((time_now-locationAlertTemp.time_begin)<30){
                NSDictionary* pDict =   [locationAlertTemp getPostDictFromCoordinate:location];
                if(pDict){
                    [postArray addObject:pDict];
                    continue;
                }
            }
            [_locationAlerts removeObjectAtIndex:index];
            index --;
        }
        
        if(postArray.count){
            //发送信息
            [[ACNetCenter shareNetCenter] uploadLocationToLocationAlert:postArray];
        }

    #ifdef uselocationAlertForRemoteNotification
        if(bNeedRemoveRemoteAlert)
    #endif
        {
            [self _remoteAlertStop];
        }
    }
    else if(!_isInAutoUpdate){
        //停止更新
        [self _stopUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    ITLog(error.localizedDescription);
//不处理    [self _stopUpdatingLocation];
}


- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
/*
 kCLAuthorizationStatusNotDetermined：用户还没有被请求获取授权
 kCLAuthorizationStatusRestricted：用户在设置里关闭了位置服务
 kCLAuthorizationStatusDenied：用户收到获取授权的请求，但点击了NO，或者在设置里关闭了
 kCLAuthorizationStatusAuthorized：用户收到获取授权的请求，点击了YES；（此状态在ios8废弃了，ios7以及以下可用）
 kCLAuthorizationStatusAuthorizedAlways = kCLAuthorizationStatusAuthorized用户授权app在任何时候获取位置信息
 kCLAuthorizationStatusAuthorizedWhenInUse：用户授权app在前台获取位置信息
 */
    switch (status) {
//       case kCLAuthorizationStatusNotDetermined:
//            if ([manager respondsToSelector:@selector(requestWhenInUseAuthorization)])
//            {
//                [manager requestWhenInUseAuthorization];
//                [manager startUpdatingLocation];
//            }
//            break;
            
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        {
            ITLogEX(@"didChangeAuthorizationStatus %@",_isInAutoUpdate?@": startUpdatingLocation":@"");
            if(_isInAutoUpdate){
                [manager startUpdatingLocation];
            }
        }
            break;
        
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
        {
            ITLogEX(@"didChangeAuthorizationStatus No Authorizationed");
            [self _stopUpdatingLocation];
        }
            break;
            
        default:
            break;
    }
}

+(BOOL)userAllowLocation
{
    //周几，判断是否在选择的时间之内
    NSArray *repeatDayList = [[NSUserDefaults standardUserDefaults] objectForKey:kRepeatDayList];
    BOOL isCanRepeat = NO;
    if (!repeatDayList)
    {
        isCanRepeat = YES;
    }
    else
    {
        NSDate *date = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *comps =[calendar components:NSWeekdayCalendarUnit fromDate:date];
        
        NSInteger weekday = [comps weekday];
        
        if (weekday-1 < [repeatDayList count])
        {
            isCanRepeat = [[repeatDayList objectAtIndex:weekday-1] boolValue];
        }
    }
    if (!isCanRepeat)
    {
        ITLogEX(@"不在指定的星期内");
        return NO;
    }
    
    //all day开启
    BOOL alldayClose = [[NSUserDefaults standardUserDefaults] boolForKey:kLocationAllDayClose];
    
    NSInteger currentHour = 0,startHour = 0,stopHour = 0;
    if (alldayClose)
    {
        NSDate *date = [NSDate date];
        currentHour = [[ACConfigs shareConfigs] getHourWithDate:date];
        
        date = [[NSUserDefaults standardUserDefaults] objectForKey:kLocationStartTime];
        startHour = [[ACConfigs shareConfigs] getHourWithDate:date];
        
        date = [[NSUserDefaults standardUserDefaults] objectForKey:kLocationStopTime];
        stopHour = [[ACConfigs shareConfigs] getHourWithDate:date];
    }
    
    if (!alldayClose)
    {
        return YES;
    }
    else
    {
        //all day close，判断时间
        NSDate *currentDate = [NSDate date];
        NSDate *betweenDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLocationStartTime];
        NSDate *andDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLocationStopTime];
        if ([[ACConfigs shareConfigs] getHourMinuteIsRangeWithCurrentDate:currentDate betweenDate:betweenDate andDate:andDate])
        {
            return YES;
        }
    }
    ITLogEX(@"不在指定的时间内");
    return NO;
}



#if 0
#pragma mark -
#pragma mark 以下不再使用
-(void)locationAlertWithDic:(NSDictionary *)dic
{
    if (!_isNeedUpdateLocation)
    {
        ACLocationAlert *locationAlert = [[ACLocationAlert alloc] initWithEventDic:dic];
        self.locationAlert = locationAlert;
        _isNeedUpdateLocation = YES;
        [self startUpdatingLocation];
    }
}


-(void)_initLocaltionManger{
    self.locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    //以此来判断，是否是ios8
    if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [_locationManager requestWhenInUseAuthorization]; //相对应info.plist中的NSLocationWhenInUseUsageDescription键
        //      [_locationManager requestAlwaysAuthorization]; //相对应info.plist中的NSLocationAlwaysUsageDescription键
    }
    [_locationManager startUpdatingLocation];
}

-(void)startUpdatingLocation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([CLLocationManager locationServicesEnabled])
        {
            //        if (!_isLocationing)
            {
                //        if (!_locationManager)
                /*TXB    {
                 self.locationManager = [[CLLocationManager alloc] init];
                 _locationManager.delegate = self;
                 }
                 [_locationManager startUpdatingLocation];*/
                [self _initLocaltionManger];
                _isLocationing = YES;
            }
        }
        else
        {
        }
    });
}

-(void)autoUpdatingLocation
{
    if ([CLLocationManager locationServicesEnabled])
    {
        //        if (!_isLocationing)
        {
            _isAutoUpdatingLocation = YES;
            //        if (!_locationManager)
            /*TXB    {
             self.locationManager = [[CLLocationManager alloc] init];
             _locationManager.delegate = self;
             }
             [_locationManager startUpdatingLocation];*/
            [self _initLocaltionManger];
            _isLocationing = YES;
        }
        
    }
}

-(void)cancelAutoUpdatingLocation
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [ACConfigs shareConfigs].location = CLLocationCoordinate2DMake(0, 0);
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    ITLog(@"");
    _isLocationing = NO;
    [manager stopUpdatingLocation];
    CLLocation *currentLocation = [locations lastObject];
    self.location = currentLocation.coordinate;
    [ACConfigs shareConfigs].location = self.location;
    
    if (_isNeedUpdateLocation)
    {
        _isNeedUpdateLocation = NO;
        if (_locationAlert.locationType == locationType_locationNow)
        {
            [[ACNetCenter shareNetCenter] uploadLocationToScan:_location locationAlert:_locationAlert];
        }
        else if (_locationAlert.locationType == locationType_locationInDistanceOfLocation)
        {
            CLLocation *location1 = [[CLLocation alloc] initWithLatitude:_location.latitude longitude:_location.longitude];
            CLLocation *location2 = [[CLLocation alloc] initWithLatitude:_locationAlert.la longitude:_locationAlert.lo];
            CLLocationDistance meters=[location1 distanceFromLocation:location2];
            if (meters < _locationAlert.distanceMeters)
            {
                [[ACNetCenter shareNetCenter] uploadLocationToLocationAlert:_locationAlert coordinate:_location];
            }
        }
    }
    
    _isFirstLocationUpdateFail = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(autoUpdatingLocation) withObject:nil afterDelay:kAutomaticLocationTime];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    ITLog(error.localizedDescription);
    _isLocationing = NO;
    //保证定位失败的情况下多定位一次，然后在一段时间后再重新定位
    if (_isFirstLocationUpdateFail)
    {
        _isFirstLocationUpdateFail = NO;
        [self autoUpdatingLocation];
    }
    else
    {
        _isFirstLocationUpdateFail = YES;
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(autoUpdatingLocation) withObject:nil afterDelay:kAutomaticLocationTime];
    }
}

#endif



@end
