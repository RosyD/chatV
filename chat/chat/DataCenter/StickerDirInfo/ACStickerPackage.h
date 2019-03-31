//
//  ACStickerPackage.h
//  chat
//
//  Created by 王方帅 on 14-5-22.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ACStickerPackage : NSObject

@property (nonatomic,strong) NSString   *title;
@property (nonatomic,strong) NSString   *path;
@property (nonatomic,strong) NSString   *provider;
@property (nonatomic,strong) NSString   *thumbnail;
@property (nonatomic,strong) NSMutableArray     *imageNameArray;
@property (nonatomic) float             progress;
@property (nonatomic) BOOL              isDownloading;

+(NSArray *)getStickerPackageArrayWithDicArray:(NSArray *)dicArray;

@end
