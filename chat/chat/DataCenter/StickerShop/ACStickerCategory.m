//
//  ACStickerCategory.m
//  chat
//
//  Created by 王方帅 on 14-8-18.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACStickerCategory.h"
#import "ACConfigs.h"

@implementation ACStickerCategory

- (instancetype)initWithDic:(NSDictionary *)dic
{
    self = [super init];
    if (self) {
        self.categoryID = [dic objectForKey:kId];
        self.categoryName = [dic objectForKey:kName];
    }
    return self;
}

+(NSMutableArray *)categoryArrayWithDicArray:(NSMutableArray *)dicArray
{
    NSMutableArray *categoryArray = [NSMutableArray arrayWithCapacity:[dicArray count]];
    for (NSDictionary *dic in dicArray)
    {
        ACStickerCategory *category = [[ACStickerCategory alloc] initWithDic:dic];
        [categoryArray addObject:category];
    }
    return categoryArray;
}

@end
