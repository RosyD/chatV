//
//  ACStickerPackage.m
//  chat
//
//  Created by 王方帅 on 14-5-22.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACStickerPackage.h"

@implementation ACStickerPackage

#define kTitle      @"title"
#define kPath       @"path"
#define kProvider   @"provider"
#define kThumbnail  @"thumbnail"
#define kName       @"name"
#define kPages      @"pages"
#define kImages     @"images"

- (instancetype)initWithDic:(NSDictionary *)dic
{
    self = [super init];
    if (self) {
        self.title = [dic objectForKey:kTitle];
        self.path = [dic objectForKey:kPath];
        self.provider = [dic objectForKey:kProvider];
        self.thumbnail = [dic objectForKey:kThumbnail];
        
        NSArray *pages = [dic objectForKey:kPages];
        NSDictionary *page = [pages lastObject];
        NSArray *images = [page objectForKey:kImages];
        self.imageNameArray = [NSMutableArray arrayWithCapacity:[images count]];
        for (NSDictionary *dic in images)
        {
            [_imageNameArray addObject:[dic objectForKey:kName]];
        }
    }
    return self;
}

+(NSArray *)getStickerPackageArrayWithDicArray:(NSArray *)dicArray
{
    NSMutableArray *stickerPackageArray = [NSMutableArray arrayWithCapacity:[dicArray count]];
    for (NSDictionary *dic in dicArray)
    {
        ACStickerPackage *package = [[ACStickerPackage alloc] initWithDic:dic];
        [stickerPackageArray addObject:package];
    }
    return stickerPackageArray;
}

@end
