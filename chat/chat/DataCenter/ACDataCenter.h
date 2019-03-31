//
//  ACDataCenter.h
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-31.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACRootTableViewCell.h"
#import "ACEntity.h"


extern NSString * const kDataCenterEntityDBLoadedNotifation;
extern NSString * const kDataCenterWallboardTopicEntityChangeNotifation;
extern NSString * const kDataCenterTopicInfoChangedNotifation;

@class ACMessage;
@class ACNoteComment;
@interface ACDataCenter : NSObject

+(ACDataCenter *)shareDataCenter;

/*
 all chat urlEntity数据存储方式有两种，一种是建立3个数组，每次添加删除chat同时添加删除all，添加删除urlEntity同时添加删除all，然后切换界面时直接将数据指向不同的数组，另一种方式是建立两个数组chat和urlEntity，每次添加删除操作如果是all界面的时候都要对chat和urlEntity进行合并排序操作
    第一种方式在空间复杂度相差很小的情况下，时间复杂度要小很多
 */
@property (nonatomic,strong) NSMutableArray *allEntityArray;
@property (nonatomic,strong) NSMutableArray *topicEntityArray;
@property (nonatomic,strong) NSMutableArray *urlEntityArray;
@property (nonatomic,strong) ACTopicEntity  *wallboardTopicEntity;

@property (nonatomic,strong) NSMutableArray *topEntityIDs; //置顶的EntityIDs
@property (nonatomic,strong) ACBaseEntity*  entityForNotification; //用户Notification跳转的对象
@property (nonatomic,strong) NSString*      noteIdForNotification;
@property (nonatomic,strong) NSArray*       shareFilePaths; //外部共享来的文件

@property (nonatomic,strong) NSArray        *stickerPackageArray;


//设置dic类型的数据为ACEnitity类型然后存储到array中
-(void)setEntityArrayWithDicArray:(NSArray *)dicArray;

//从url和topic array中读取数据传换成dic类型，然后返回
-(NSArray *)getDicArray;

//获得chatListDataSourceArray
-(NSMutableArray *)getChatListDataSourceArrayWithChatListType:(enum ACCenterViewControllerType)chatListType;

//载入entityList从数据库中
-(void)loadEntityListFromDB;

-(BOOL)unZipFromPath:(NSString *)fromPath toPath:(NSString *)toPath;

//根据时间戳得到当天时分
-(NSString *)getTimeStringWithTimeInterval:(NSTimeInterval)timeInterval;

//根据时间戳得到月日周几
-(NSString *)getDateStringWithTimeInterval:(NSTimeInterval)timeInterval;

//对数据库刚读出来的添加是否展示日期标示
//-(void)addIsNeedDateShowWithArray:(NSMutableArray *)array;
//+(void)checkMessagesNeedShowDate:(NSMutableArray*)array; //检查消息列表是否需要显示时间
+(void)checkACMessages:(NSMutableArray*)array; //1.排序，2.删除重复，3.检查消息列表是否需要显示时间
+(void)addACMessage:(ACMessage *)pMsg toMessages:(NSMutableArray*)array; //添加Msg 1.排序，2.删除重复，3.检查消息列表是否需要显示时间


//查询
+(ACBaseEntity*)findEntify:(NSString*)entityID inArray:(NSMutableArray*)pArray;
-(ACTopicEntity*)findTopicEntity:(NSString*)entityID;
-(ACBaseEntity*)findEntify:(NSString*)entityID;

//删除
-(void)remvoeEntity:(ACBaseEntity*) entity;

-(void)entityTops_remove:(NSString*)entityID;
-(NSInteger)entityTops_find:(NSString*)entityID;
-(void)entityTops_Set:(ACBaseEntity*) entity; //置顶
-(void)entityTops_Clear:(ACBaseEntity*) entity; //放弃置顶


@end
