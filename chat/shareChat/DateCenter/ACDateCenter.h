//
//  ACDateCenter.h
//  chat
//
//  Created by 李朝霞 on 2017/2/17.
//  Copyright © 2017年 李朝霞. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACTopicEntity.h"

@interface ACDateCenter : NSObject

@property (nonatomic,strong) ACTopicEntity  *wallboardTopicEntity;

+(ACDateCenter *)shareDataCenter;

+(NSMutableArray *)getTopicEntityListFromDB;

@end
