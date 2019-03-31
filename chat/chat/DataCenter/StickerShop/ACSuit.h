//
//  ACSuit.h
//  chat
//
//  Created by 王方帅 on 14-8-18.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACUser;
@interface ACSuit : NSObject

@property (nonatomic,strong) NSString   *suitID;
@property (nonatomic,strong) NSString   *suitName;
@property (nonatomic,strong) NSString   *desc;
@property (nonatomic,strong) NSString   *categoryID;
@property (nonatomic,strong) NSString   *firmID;
@property (nonatomic) long              expiredDate;
@property (nonatomic) long              createTime;
@property (nonatomic) long              updateTime;
@property (nonatomic,strong) NSArray    *stickers;
@property (nonatomic,strong) NSString   *background;
@property (nonatomic,strong) NSString   *thumbnail;
@property (nonatomic,strong) ACUser     *uploader;
@property (nonatomic) float             progress;
@property (nonatomic) BOOL              isFromServer; //任然被服务器支持

- (instancetype)initWithDic:(NSDictionary *)dic;

+(NSMutableArray *)suitArrayWithDicArray:(NSMutableArray *)dicArray;

@end


@interface ACSticker : NSObject

@property (nonatomic,strong) NSString   *rid;
@property (nonatomic,strong) NSString   *title;
@property (nonatomic,strong) NSString   *stickerImgResourceId;

- (instancetype)initWithDic:(NSDictionary *)dic;

+(NSMutableArray *)stickerArrayWithDicArray:(NSMutableArray *)dicArray;

@end





@interface ACSuit_Recent : ACSuit
+(instancetype)loadFromUserDefaults;
-(NSString*)suitIDForSticker:(ACSticker*)sticker;
-(void)addSticker:(ACSticker*) sticker fromSuit:(ACSuit*) pSuit;
-(void)checkDeleteFromSuits:(NSArray*)pSuits;
@end