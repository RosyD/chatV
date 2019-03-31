//
//  ACTopicEntity.h
//  chat
//
//  Created by 李朝霞 on 2017/2/17.
//  Copyright © 2017年 李朝霞. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMResultSet.h"

@interface ACTopicEntity : NSObject


@property (nonatomic,strong) NSString   *mpType;

@property (nonatomic,strong) NSString   *title;//组名
@property (nonatomic,strong) NSString   *icon;//组icon
@property (nonatomic,strong) NSString   *singleChatUserID;//对方的userID
@property (nonatomic,strong) NSString   *entityID;

+(BOOL)createTable:(NSInteger)nDB_Ver;

+(void)dropTable;

//创建topicEntity从数据库
+(ACTopicEntity *)getTopicEntityWithFMResultSet:(FMResultSet *)resultSet;

@end
