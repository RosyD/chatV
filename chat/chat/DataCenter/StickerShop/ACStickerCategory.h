//
//  ACStickerCategory.h
//  chat
//
//  Created by 王方帅 on 14-8-18.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ACStickerCategory : NSObject

@property (nonatomic,strong) NSString   *categoryID;
@property (nonatomic,strong) NSString   *categoryName;

- (instancetype)initWithDic:(NSDictionary *)dic;

+(NSMutableArray *)categoryArrayWithDicArray:(NSMutableArray *)dicArray;

@end
