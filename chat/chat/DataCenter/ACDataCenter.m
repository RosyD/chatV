//
//  ACDataCenter.m
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-31.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACDataCenter.h"
#import "ACEntity.h"
#import "ACRootTableViewCell.h"
#import "ACTopicEntityDB.h"
#import "ACUrlEntityDB.h"
#import "ZipArchive.h"
#import "ACAddress.h"
#import "ACNetCenter.h"
#import "JSONKit.h"
#import "ACStickerPackage.h"
#import "ACMessage.h"
#import "ACEntityEvent.h"
#import "ACUser.h"

NSString * const kDataCenterEntityDBLoadedNotifation = @"kDataCenterEntityDBLoadedNotifation";
NSString * const kDataCenterWallboardTopicEntityChangeNotifation = @"kDataCenterWallboardTopicEntityChangeNotifation";
NSString * const kDataCenterTopicInfoChangedNotifation = @"kDataCenterTopicInfoChangedNotifation";

static ACDataCenter *_dataCenter = nil;

@implementation ACDataCenter


- (id)init
{
    self = [super init];
    if (self) {
        _allEntityArray = [[NSMutableArray alloc] init];
        _urlEntityArray = [[NSMutableArray alloc] init];
        _topicEntityArray = [[NSMutableArray alloc] init];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSString *saveAddress = [ACAddress getAddressWithFileName:kStickerDirFileName fileType:ACFile_Type_StickerDir_Json isTemp:NO subDirName:nil];
            NSArray *array = [[NSData dataWithContentsOfFile:saveAddress] objectFromJSONData];
            self.stickerPackageArray = [ACStickerPackage getStickerPackageArrayWithDicArray:array];
        });
    }
    return self;
}

+(ACDataCenter *)shareDataCenter
{
    if (_dataCenter == nil)
    {
        _dataCenter = [[ACDataCenter alloc] init];
    }
    return _dataCenter;
}

-(void)setWallboardTopicEntity:(ACTopicEntity *)wallboardTopicEntity
{
    if (_wallboardTopicEntity != wallboardTopicEntity)
    {
        if (_wallboardTopicEntity)
        {
            [_allEntityArray removeObject:_wallboardTopicEntity];
        }
        if (wallboardTopicEntity)
        {
            [_allEntityArray addObject:wallboardTopicEntity];
        }
        _wallboardTopicEntity = wallboardTopicEntity;
        [ACUtility postNotificationName:kDataCenterWallboardTopicEntityChangeNotifation object:nil];
    }
}

-(BOOL)unZipFromPath:(NSString *)fromPath toPath:(NSString *)toPath
{
    ZipArchive *zip = [[ZipArchive alloc] init];
    if ([zip UnzipOpenFile:fromPath])
    {
        BOOL result = [zip UnzipFileTo:toPath overWrite:YES];
        if (!result)
        {
            ITLog(@"解压失败");
        }
        [zip UnzipCloseFile];
        return result;
    }
    return NO;
}

//载入entityList从数据库中
-(void)loadEntityListFromDB
{
    [self topEntityIDs]; //加载

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    
        self.topicEntityArray = [ACTopicEntityDB getTopicEntityListFromDB];
        NSLog(@"%lu",self.topicEntityArray.count);
        [[ACConfigs shareConfigs] updateApplicationUnreadCount];
        
        self.urlEntityArray = [ACUrlEntityDB getUrlEntityListFromDB]; //数据库已经排序
        
        self.allEntityArray = [NSMutableArray arrayWithCapacity:[_topicEntityArray count]+[_urlEntityArray count]];
        [_allEntityArray addObjectsFromArray:_topicEntityArray];
        if ([ACDataCenter shareDataCenter].wallboardTopicEntity)
        {
            [_allEntityArray addObject:[ACDataCenter shareDataCenter].wallboardTopicEntity];
        }
        [_allEntityArray addObjectsFromArray:_urlEntityArray];
        
        [_allEntityArray sortUsingComparator:^NSComparisonResult(ACBaseEntity *entity1,ACBaseEntity *entity2) {
            NSTimeInterval sortUseTime1 = entity1.updateTime;
            if ([entity1 isKindOfClass:[ACTopicEntity class]])
            {
                sortUseTime1 = ((ACTopicEntity *)entity1).lastestMessageTime;
            }
            NSTimeInterval sortUseTime2 = entity2.updateTime;
            if ([entity2 isKindOfClass:[ACTopicEntity class]])
            {
                sortUseTime2 = ((ACTopicEntity *)entity2).lastestMessageTime;
            }
            if (sortUseTime1 < sortUseTime2)
            {
                return (NSComparisonResult)NSOrderedDescending;
            }
            if (sortUseTime1 > sortUseTime2)
            {
                return (NSComparisonResult)NSOrderedAscending;
            }
            return (NSComparisonResult)NSOrderedSame;
        }];
        
        //排序Top
        NSArray* pTopEntityID = [NSArray arrayWithArray:_topEntityIDs];
        for(NSString* entityID in pTopEntityID){
            ACBaseEntity* entiy = [ACDataCenter findEntify:entityID inArray:_allEntityArray];
            if(entiy){
                [self _entityTops_SetFunc:entiy];
            }
        }
        
        [ACUtility postNotificationName:kDataCenterEntityDBLoadedNotifation object:nil];
    });
}

//设置dic类型的数据为ACEnitity类型然后存储到array中
-(void)setEntityArrayWithDicArray:(NSArray *)dicArray
{
    NSArray *entityArray = [ACBaseEntity setEntityArrayWithDicArray:dicArray];
    
    for (ACBaseEntity *entity in entityArray)
    {
        if(entity.entityType == EntityType_Topic)
        {
            [_topicEntityArray addObject:entity];
        }
        else if(entity.entityType == EntityType_URL)
        {
            [_urlEntityArray addObject:entity];
        }
    }
}

//从url和topic array中读取数据传换成dic类型，然后返回
-(NSArray *)getDicArray
{
    NSMutableArray *entityDicArray = [NSMutableArray arrayWithCapacity:[_topicEntityArray count]+[_urlEntityArray count]];
    NSArray *topicDicArray = [ACBaseEntity getDicArrayWithEntityArray:_topicEntityArray];
    NSArray *urlDicArray = [ACBaseEntity getDicArrayWithEntityArray:_urlEntityArray];
    [entityDicArray addObjectsFromArray:topicDicArray];
    if (_wallboardTopicEntity)
    {
//        [entityDicArray addObject:[_wallboardTopicEntity getDic]];
        [entityDicArray addObjectsFromArray:[ACBaseEntity getDicArrayWithEntityArray:@[_wallboardTopicEntity]]];

    }
    [entityDicArray addObjectsFromArray:urlDicArray];
    return entityDicArray;
}

//获得chatListDataSourceArray
-(NSMutableArray *)getChatListDataSourceArrayWithChatListType:(enum ACCenterViewControllerType)chatListType
{
    NSMutableArray *dataSourceArray = nil;
    switch (chatListType)
    {
        case ACCenterViewControllerType_All:
        {
            dataSourceArray = _allEntityArray;
        }
            break;
        case ACCenterViewControllerType_Chat:
        {
            dataSourceArray = _topicEntityArray;
        }
            break;
        case ACCenterViewControllerType_Event:
        {
            dataSourceArray = [NSMutableArray array];
            for (ACUrlEntity *entity in _urlEntityArray)
            {
                if ([entity.mpType isEqualToString:cEvent])
                {
                    [dataSourceArray addObject:entity];
                }
            }
        }
            break;
        case ACCenterViewControllerType_Survey:
        {
            dataSourceArray = [NSMutableArray array];
            for (ACUrlEntity *entity in _urlEntityArray)
            {
                if ([entity.mpType isEqualToString:cSurvey])
                {
                    [dataSourceArray addObject:entity];
                }
            }
        }
            break;
        case ACCenterViewControllerType_Link:
        {
            dataSourceArray = [NSMutableArray array];
            for (ACUrlEntity *entity in _urlEntityArray)
            {
                if ([entity.mpType isEqualToString:cLink])
                {
                    [dataSourceArray addObject:entity];
                }
            }
        }
            break;
        case ACCenterViewControllerType_Page:
        {
            dataSourceArray = [NSMutableArray array];
            for (ACUrlEntity *entity in _urlEntityArray)
            {
                if ([entity.mpType isEqualToString:cPage])
                {
                    [dataSourceArray addObject:entity];
                }
            }
        }
            break;
        case ACCenterViewControllerType_Services:
        {
            dataSourceArray = [NSMutableArray array];
            if ([ACDataCenter shareDataCenter].wallboardTopicEntity)
            {
                [dataSourceArray addObject:[ACDataCenter shareDataCenter].wallboardTopicEntity];
            }
        }
            break;
        default:
        {
        }
            break;
    }
    return dataSourceArray;
    
}

//根据时间戳得到当天时分
-(NSString *)getTimeStringWithTimeInterval:(NSTimeInterval)timeInterval
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:date];
    
    NSString *timeString = [NSString stringWithFormat:@"%02d:%02d",(int)comp.hour,(int)comp.minute];
    return timeString;
}

//根据时间戳得到月日周几
-(NSString *)getDateStringWithTimeInterval:(NSTimeInterval)timeInterval
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit fromDate:date];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *curLocale = [NSLocale currentLocale];
    [dateFormatter setLocale:curLocale];// 设置为当前区域
    [dateFormatter setDateFormat:@"EEEE"];
    NSString *weekdayString = [dateFormatter stringFromDate:date];
//    NSString *weekdayString = nil;
//    switch ((int)comp.weekday)
//    {
//        case 1:
//        {
//            weekdayString = @"周日";
//        }
//            break;
//        case 2:
//        {
//            weekdayString = @"周一";
//        }
//            break;
//        case 3:
//        {
//            weekdayString = @"周二";
//        }
//            break;
//        case 4:
//        {
//            weekdayString = @"周三";
//        }
//            break;
//        case 5:
//        {
//            weekdayString = @"周四";
//        }
//            break;
//        case 6:
//        {
//            weekdayString = @"周五";
//        }
//            break;
//        case 7:
//        {
//            weekdayString = @"周六";
//        }
//            break;
//        default:
//            break;
//    }
    
    NSString *dateString = [NSString stringWithFormat:@"%4d-%02d-%02d %@",(int)comp.year,(int)comp.month,(int)comp.day,weekdayString];
    return dateString;
}

//对数据库刚读出来的添加是否展示日期标示
+(void)checkACMessages:(NSMutableArray*)array //1.排序，2.删除重复，3.检查消息列表是否需要显示时间
{
    if(0==array.count) {
        return;
    }

    //排序
    [array sortUsingSelector:@selector(compare:)];

    ACMessage* preMsg = array[0];
    preMsg.isNeedDateShow = YES;

    //删除重复
    for(NSInteger i=1;i<array.count&&preMsg.seq!=ACMessage_seq_DEF;i++){
        ACMessage *msgTemp = array[i];
        if(msgTemp.seq==preMsg.seq){
            [array removeObjectAtIndex:i];
            i--;
        }
        else{
            preMsg = msgTemp;
        }
    }

    //检查消息列表是否需要显示时间
    NSInteger nEnd = array.count-1;
    for (NSInteger i = 0; i < nEnd; i++)
    {
        ACMessage *msg1 = array[i];
        ACMessage *msg2 = array[i+1];
        msg2.isNeedDateShow = msg1.createTimeForYYYYMMDD!=msg2.createTimeForYYYYMMDD;
    }
}

+(void)addACMessage:(ACMessage *)pMsg toMessages:(NSMutableArray*)array{
    if(array.count){
        ACMessage *lastMsg = [array lastObject];

        if(pMsg.seq>lastMsg.seq){
            [array addObject:pMsg];
            pMsg.isNeedDateShow = lastMsg.createTimeForYYYYMMDD!=pMsg.createTimeForYYYYMMDD;
            return;
        }
        [array addObject:pMsg];
        [ACDataCenter  checkACMessages:array];
        return;
    }
    pMsg.isNeedDateShow = YES;
    [array addObject:pMsg];
}


+(ACBaseEntity*)findEntify:(NSString*)entityID inArray:(NSMutableArray*)pArray{
    if(entityID.length){
        for(ACBaseEntity* entity in pArray){
            if([entity.entityID isEqualToString:entityID]){
                return entity;
            }
        }
    }
    return nil;
}

-(ACTopicEntity*)findTopicEntity:(NSString*)entityID{
    return (ACTopicEntity*)[ACDataCenter findEntify:entityID inArray:_topicEntityArray];
}

-(ACBaseEntity*)findEntify:(NSString*)entityID{
    return [ACDataCenter findEntify:entityID inArray:_allEntityArray];
}


-(void)remvoeEntity:(ACBaseEntity*) entity{
    if (entity.entityType == EntityType_Topic)
    {
        [ACTopicEntityDB deleteTopicEntityFromDBWithTopicEntityID:entity.entityID];
        [self.topicEntityArray removeObject:entity];
    }
    else if (entity.entityType == EntityType_URL)
    {
        [ACUrlEntityDB deleteUrlEntityFromDBWithUrlEntityID:entity.entityID];
        [self.urlEntityArray removeObject:entity];
    }
    else{
        return;
    }
    [self.allEntityArray removeObject:entity];
    
    [self entityTops_remove:entity.entityID];
}

-(void)entityTops_remove:(NSString*)entityID{
    NSInteger n = [self entityTops_find:entityID];
    if(n>=0){
        [_topEntityIDs removeObjectAtIndex:n];
        [self _topEntityIDs_Load:NO];
        return;
    }
}

-(NSInteger)entityTops_find:(NSString*)entityID{
    NSMutableArray* pArry = self.topEntityIDs;
    for(NSInteger n=0;n<pArry.count;n++){
        if([entityID isEqualToString:pArry[n]]){
            return n;
        }
    }
    return -1;
}

-(void)_entityTops_SetFunc:(ACBaseEntity*) entity{
    //设置置顶
    entity.isToped = YES;
    
    if(![entity.mpType isEqualToString:cWallboard]){
        if (entity.entityType == EntityType_Topic){
            [_topicEntityArray removeObject:entity];
            [_topicEntityArray insertObject:entity atIndex:0];
        }
        else if (entity.entityType == EntityType_URL){
            [_urlEntityArray removeObject:entity];
            [_urlEntityArray insertObject:entity atIndex:0];
        }
    }
    [_allEntityArray removeObject:entity];
    [_allEntityArray insertObject:entity atIndex:0];
}

-(void)entityTops_Set:(ACBaseEntity*) entity{ //置顶
    NSInteger n = [self entityTops_find:entity.entityID];
    NSString* entityID =    entity.entityID;
    if(n>=0){
        entityID    =   _topEntityIDs[n];
        [_topEntityIDs removeObjectAtIndex:n];
    }
    [_topEntityIDs addObject:entityID];
    [self _topEntityIDs_Load:NO]; //最顶的ID在最下面
    
    [self _entityTops_SetFunc:entity];
 }

-(void)entityTops_Clear:(ACBaseEntity*) entity{ //放弃置顶
    NSInteger n = [self entityTops_find:entity.entityID];
    if(n>=0){
        [_topEntityIDs removeObjectAtIndex:n];
        [self _topEntityIDs_Load:NO];
    }
    
    entity.isToped = NO;
    
    if(![entity.mpType isEqualToString:cWallboard]){
        if (entity.entityType == EntityType_Topic){
            [ACEntityEvent insertEntityToArray:_topicEntityArray entity:entity];
        }
        else if (entity.entityType == EntityType_URL){
            [ACEntityEvent insertEntityToArray:_urlEntityArray entity:entity];
        }
    }

    [ACEntityEvent insertEntityToArray:_allEntityArray entity:entity];
}

-(NSMutableArray*)_topEntityIDs_Load:(BOOL)bLoad{
    
    if(nil==_topEntityIDs){
        _topEntityIDs   =   [[NSMutableArray alloc] initWithCapacity:10];
    }
    else if(bLoad){
        return _topEntityIDs;
    }
    
    NSUserDefaults  *defaults   =      [NSUserDefaults standardUserDefaults];
    NSString* topName = [NSString stringWithFormat:@"%@_top",[ACUser myselfUserID]];
    if(bLoad){
        [_topEntityIDs removeAllObjects];
        [_topEntityIDs addObjectsFromArray:[defaults objectForKey:topName]];
    }
    else{
        [defaults setObject:_topEntityIDs forKey:topName];
        [defaults synchronize];
    }
    return _topEntityIDs;
}

-(NSMutableArray*)topEntityIDs{
    return [self _topEntityIDs_Load:YES];
}


@end
