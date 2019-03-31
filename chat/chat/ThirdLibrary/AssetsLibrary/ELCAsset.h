//
//  Asset.h
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>


#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>


@interface PHAssetsGroup : NSObject
@property (nonatomic, copy) NSString* title;
//@property (nonatomic, strong) UIImage* thumbnail;
@property (nonatomic, strong) PHAssetCollection* collection;
@property (nonatomic, strong) PHFetchResult* assets;
@end


@class ELCAsset;
@class ELCAssetTablePicker;

@protocol ELCAssetDelegate <NSObject>

@optional
- (void)assetSelected:(ELCAsset *)asset;
- (BOOL)shouldSelectAsset:(ELCAsset *)asset;
- (void)assetDeselected:(ELCAsset *)asset;
- (BOOL)shouldDeselectAsset:(ELCAsset *)asset;
@end


enum ELCAssetLoadImgType{
    ELCAssetLoad_Thumb,     //缩略图
    ELCAssetLoad_FullScreen, //全屏图
//    ELCAssetLoad_Resolution,    //原始图,不缓存
};

#define ELCAsset_thumb_WH    75

typedef void (^ELCAsset_LoadImgBlock)(UIImage* img); //加载图像



@interface ELCAsset : NSObject


@property (nonatomic, assign)   BOOL selected;

//@property (nonatomic,strong,readonly)   UIImage *thumbnail;
@property (nonatomic, strong,readonly)  UIImage *fullResolutionImageNoCache;
@property (nonatomic, strong,readonly)  UIImage *fullScreenImageNoCache;
@property (nonatomic,weak) ELCAssetTablePicker *parent;
@property (nonatomic,strong) NSObject* asset;
@property (nonatomic,strong) NSString* caption; //标题
//@property (nonatomic, strong) UIImage* loadedImg; //加载了的图像

@property (nonatomic,assign) int index;

-(void)setInfoFromELCAsset:(ELCAsset*)asset;

-(void)loadThumbWithBlock:(ELCAsset_LoadImgBlock)block;

-(UIImage*)loadImgForALAsset:(enum ELCAssetLoadImgType)nType;


+(void)selectBegin;

@end

@interface ELCAssetCacheManger : PHCachingImageManager

-(instancetype)initWithAssets:(NSArray<ELCAsset*>*)elcAssets andWinSize:(int)nWinSize forImgType:(enum ELCAssetLoadImgType)nType;
-(void)cacheCheck:(NSInteger)nIndex forNext:(BOOL)forNext;
-(void)loadImgNo:(NSInteger)nIndex withBlock:(ELCAsset_LoadImgBlock)block;
-(void)loadAsset:(ELCAsset*)elcAsset  withBlock:(ELCAsset_LoadImgBlock)block;

//-(void)loadImgs:(NSArray<ELCAsset*>*)assets withBlock:(void (^)()) resultHandler;

+(void)loadImg:(enum ELCAssetLoadImgType)nType
      forAsset:(PHAsset*)asset
    withManger:(PHImageManager*)manger
      andBlock:(ELCAsset_LoadImgBlock)block;


@end

