//
//  ACSuit.m
//  chat
//
//  Created by 王方帅 on 14-8-18.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACSuit.h"
#import "ACUser.h"
#import "ACConfigs.h"

@implementation ACSuit

- (instancetype)initWithDic:(NSDictionary *)dic
{
    self = [super init];
    if (self) {
        self.suitID = [dic objectForKey:kId];
        self.suitName = [dic objectForKey:kName];
        self.desc = [dic objectForKey:kDesc];
        self.categoryID = [dic objectForKey:kCategoryId];
        self.firmID = [dic objectForKey:kFirmId];
        self.expiredDate = [[dic objectForKey:kExpiredDate] longValue];
        self.createTime = [[dic objectForKey:kCreateTime] longValue];
        self.updateTime = [[dic objectForKey:kUpdateTime] longValue];
        self.stickers = [ACSticker stickerArrayWithDicArray:[dic objectForKey:kStickers]];
        self.background = [dic objectForKey:kBackground];
        self.thumbnail = [dic objectForKey:kThumbnail];
        ACUser *user = [[ACUser alloc] init];
        [user setUserDic:[dic objectForKey:kUploader]];
        self.uploader = user;
        _progress = -1;
    }
    return self;
}

+(NSMutableArray *)suitArrayWithDicArray:(NSMutableArray *)dicArray
{
    NSMutableArray *suitArray = [NSMutableArray arrayWithCapacity:[dicArray count]];
    for (NSDictionary *dic in dicArray)
    {
        ACSuit *suit = [[ACSuit alloc] initWithDic:dic];
        [suitArray addObject:suit];
    }
    return suitArray;
}

@end

@implementation ACSticker

- (instancetype)initWithDic:(NSDictionary *)dic
{
    self = [super init];
    if (self) {
        self.rid = [dic objectForKey:kRid];
        self.title = [dic objectForKey:kTitle];
        self.stickerImgResourceId = [dic objectForKey:kStickerImgResourceId];
        
    }
    return self;
}

+(NSMutableArray *)stickerArrayWithDicArray:(NSMutableArray *)dicArray
{
    NSMutableArray *stickerArray = [NSMutableArray arrayWithCapacity:[dicArray count]];
    for (NSDictionary *dic in dicArray)
    {
        ACSticker *sticker = [[ACSticker alloc] initWithDic:dic];
        [stickerArray addObject:sticker];
    }
    return stickerArray;
}

@end


#define _Recent_field_rid   @"rid"
#define _Recent_field_title   @"title"
#define _Recent_field_stickerImgResourceId   @"stickerImgResourceId"
#define _Recent_field_suitID   @"suitID"
#define _Recent_field_useTime   @"useTime"

@interface ACSticker_Recent : ACSticker  <NSCoding>
@property (nonatomic) time_t    useTime; //用于排序
@property (nonatomic,strong) NSString   *suitID;
@end
@implementation ACSticker_Recent

-(BOOL)isDeletedFromSuits:(NSArray*)pSuits{
    for(ACSuit* pSuit in pSuits){
        if([pSuit.suitID isEqualToString:_suitID]){
            for(ACSticker* pSticker in pSuit.stickers){
                if([self.rid isEqualToString:pSticker.rid]){
                    return NO;
                }
            }
        }
    }
    return YES;
}

- (id) initWithCoder: (NSCoder *)coder
{
    if (self = [super init])
    {
        self.rid = [coder decodeObjectForKey:_Recent_field_rid];
        self.title = [coder decodeObjectForKey:_Recent_field_title];
        self.stickerImgResourceId = [coder decodeObjectForKey:_Recent_field_stickerImgResourceId];
        _suitID = [coder decodeObjectForKey:_Recent_field_suitID];
        _useTime = [[coder decodeObjectForKey:_Recent_field_useTime] longValue];
    }
    return self;
}
- (void) encodeWithCoder: (NSCoder *)coder
{
    [coder encodeObject:self.rid forKey:_Recent_field_rid];
    [coder encodeObject:self.title forKey:_Recent_field_title];
    [coder encodeObject:self.stickerImgResourceId forKey:_Recent_field_stickerImgResourceId];
    [coder encodeObject:_suitID forKey:_Recent_field_suitID];
    [coder encodeObject:@(_useTime) forKey:_Recent_field_useTime];
}

@end

@interface ACSuit_Recent(){
    NSMutableArray* _pRecentStickers;
}
@end


#define kRecentUseStickerList   @"kRecentUseStickerList"
#define ACSuit_Recent_MAX_ITEM  8*12

@implementation ACSuit_Recent


+(instancetype)loadFromUserDefaults{
    ACSuit_Recent* pRet = [[ACSuit_Recent alloc] init];
    pRet->_pRecentStickers = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:kRecentUseStickerList]]];
    return pRet;
}

-(NSString*)suitIDForSticker:(ACSticker*)sticker{
    NSAssert([sticker isKindOfClass:[ACSticker_Recent class]],@"[ACSticker_Recent class]");
    return ((ACSticker_Recent*)sticker).suitID;
}

-(NSArray*)stickers{
    return _pRecentStickers;
}

-(void)addSticker:(ACSticker*) sticker  fromSuit:(ACSuit*) pSuit{
    ACSticker_Recent* pAddRecent = nil;
    
    if(pSuit==self){
        NSAssert([sticker isKindOfClass:[ACSticker_Recent class]],@"[ACSticker_Recent class]");
        pAddRecent  = (ACSticker_Recent*)sticker;
    }
    else{
        for(ACSticker_Recent* pRect in _pRecentStickers){
            if([pRect.suitID isEqualToString:pSuit.suitID]&&
               [pRect.rid isEqualToString:sticker.rid]){
                pAddRecent =    pRect;
                break;
            }
        }
        if(nil==pAddRecent){
            if(_pRecentStickers.count>=ACSuit_Recent_MAX_ITEM){
                [_pRecentStickers removeLastObject];
            }
            pAddRecent = [[ACSticker_Recent alloc] init];
            pAddRecent.rid =    sticker.rid;
            pAddRecent.title =  sticker.title;
            pAddRecent.stickerImgResourceId =   sticker.stickerImgResourceId;
            pAddRecent.suitID = pSuit.suitID;
            [_pRecentStickers addObject:pAddRecent];
        }
    }
    //取时间
    pAddRecent.useTime = time(NULL);
    
    
    //排序
    [_pRecentStickers sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if(((ACSticker_Recent*)obj1).useTime>((ACSticker_Recent*)obj2).useTime){
//            return NSOrderedDescending;
            return NSOrderedAscending;
        }
        
//        return NSOrderedAscending;
        return NSOrderedDescending;
    }];
    
    //保存
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:_pRecentStickers] forKey:kRecentUseStickerList];
    [defaults synchronize];
}



-(void)checkDeleteFromSuits:(NSArray*)pSuits{
    for(NSInteger nNo=0;nNo<_pRecentStickers.count;nNo++){
        if([((ACSticker_Recent*)_pRecentStickers[nNo]) isDeletedFromSuits:pSuits]){
            [_pRecentStickers removeObjectAtIndex:nNo];
            nNo --;
        }
    }
}


@end
