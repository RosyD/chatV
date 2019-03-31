//
//  Asset.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAsset.h"
#import "ELCAssetTablePicker.h"

@interface ELCAssetCacheManger(){
    __weak  NSArray<ELCAsset*>* _elcAssets;
    int                         _windowSize;
    NSInteger                   _cachedBeginIndex;
    NSInteger                   _cachedEndIndex;
    enum ELCAssetLoadImgType    _cacheType;
}
@end

@implementation ELCAssetCacheManger

-(instancetype)initWithAssets:(NSArray<ELCAsset*>*)elcAssets andWinSize:(int)nWinSize forImgType:(enum ELCAssetLoadImgType)nType{
    self = [super init];
    if(self){
        _elcAssets  =   elcAssets;
        _windowSize =   nWinSize;
        _cacheType  =   nType;
        NSInteger nCount =   MIN(_windowSize*2,elcAssets.count);
        NSMutableArray *addedAssets = [NSMutableArray array];
        for(_cachedEndIndex=0;_cachedEndIndex<nCount;_cachedEndIndex++){
            [addedAssets addObject:elcAssets[_cachedEndIndex].asset];
        }
        [self _cachingAssets:addedAssets forStop:NO];
    }
    return self;
}

#define ELCAssetLoad_Thumb_PHImageContentMode PHImageContentModeAspectFill

-(void)_cachingAssets:(NSArray<PHAsset*>*)assets
           forStop:(BOOL)bStop{
    if(0==assets.count){
        return;
    }
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize theSize;
    PHImageRequestOptions *phImageRequestOptions = nil;
    PHImageContentMode theMode = PHImageContentModeDefault;
    if(ELCAssetLoad_Thumb==_cacheType){
        theSize =   CGSizeMake(ELCAsset_thumb_WH * scale, ELCAsset_thumb_WH * scale);
#ifdef ELCAssetLoad_Thumb_PHImageContentMode
        theMode =   ELCAssetLoad_Thumb_PHImageContentMode;
        phImageRequestOptions = [[PHImageRequestOptions alloc] init];
        phImageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
#endif
    }
    else //if(ELCAssetLoad_FullScreen==_cacheType)
    {
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        theSize =   CGSizeMake(screenSize.width * scale, screenSize.height * scale);
    }
//    else{
//        theSize =   PHImageManagerMaximumSize;
//    }
    
    if(bStop){
        //停止缓存
        [self stopCachingImagesForAssets:assets
                                targetSize:theSize
                               contentMode:theMode
                                   options:phImageRequestOptions];
        return;
    }
    //启动缓存
    [self startCachingImagesForAssets:assets
                             targetSize:theSize
                            contentMode:theMode
                                options:phImageRequestOptions];
}


-(void)cacheCheck:(NSInteger)nIndex forNext:(BOOL)forNext{
    NSInteger bBegin = forNext?(nIndex-_windowSize):(nIndex-_windowSize-_windowSize);
    if(bBegin<0){bBegin=0;}
    
    NSInteger nOffset = ABS(_cachedBeginIndex-bBegin);
    if(nOffset<(_windowSize/2)){
        return;
    }
    
    NSInteger nEndInex  =   bBegin+_windowSize*3;
    if(nEndInex>_elcAssets.count){nEndInex = _elcAssets.count;}
    
    NSMutableArray *tempAssets = [NSMutableArray array];
//    NSMutableArray *removedAssets = [NSMutableArray array];
    for (NSInteger n=_cachedBeginIndex; n<_cachedEndIndex; n++) {
        if(n<bBegin||n>=nEndInex){
            [tempAssets addObject:_elcAssets[n].asset];
        }
    }
    [self _cachingAssets:tempAssets forStop:YES];
    [tempAssets removeAllObjects];
    
    for (NSInteger n=bBegin; n<nEndInex; n++) {
        if(n<_cachedBeginIndex||n>=_cachedEndIndex){
            [tempAssets addObject:_elcAssets[n].asset];
        }
    }
    [self _cachingAssets:tempAssets forStop:NO];
}

-(void)loadAsset:(ELCAsset*)elcAsset  withBlock:(ELCAsset_LoadImgBlock)block{
    [ELCAssetCacheManger loadImg:_cacheType
                        forAsset:(PHAsset*)(elcAsset.asset)
                      withManger:self
                        andBlock:block];
}

-(void)loadImgNo:(NSInteger)nIndex withBlock:(ELCAsset_LoadImgBlock)block{
    [self loadAsset:_elcAssets[nIndex] withBlock:block];
}


+(void)loadImg:(enum ELCAssetLoadImgType)nType
      forAsset:(PHAsset*)asset
    withManger:(PHImageManager*)manger
      andBlock:(ELCAsset_LoadImgBlock)block{
    
    if(nil==manger){
        manger = [PHImageManager defaultManager];
    }
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize theSize;
    PHImageRequestOptions *phImageRequestOptions = nil;
    PHImageContentMode theMode = PHImageContentModeDefault;
    if(ELCAssetLoad_Thumb==nType){
        theSize =   CGSizeMake(ELCAsset_thumb_WH * scale, ELCAsset_thumb_WH * scale);
#ifdef ELCAssetLoad_Thumb_PHImageContentMode
        theMode =   ELCAssetLoad_Thumb_PHImageContentMode;
        phImageRequestOptions = [[PHImageRequestOptions alloc] init];
        phImageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
#endif
    }
    else //if(ELCAssetLoad_FullScreen==nType)
    {
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        theSize =   CGSizeMake(screenSize.width * scale, screenSize.height * scale);
    }
//    else{
//        theSize =   PHImageManagerMaximumSize;
//    }
    
    [manger requestImageForAsset:asset
                      targetSize:theSize
                     contentMode:theMode
                         options:phImageRequestOptions
                   resultHandler:^(UIImage *  result, NSDictionary *  info) {
                       if(result){
                           block(result);
//                           ITLogEX(@"%@ \n %@",info,result);
                       }
//                       else{
//                           ITLogEX(@"%@",info);
//                       }
                   }];
}

@end



@implementation ELCAsset

//Using auto synthesizers
- (NSString *)description
{
    return @"ELCAsset index:TXB";
//    return [NSString stringWithFormat:@"ELCAsset index:%d",self.index];
}

//#ifdef ACUtility_Need_Log
//-(void)dealloc{
//    ITLog(@"");
//}
//#endif
//- (id)initWithAsset:(NSObject *)asset{
//	self = [super init];
//	if (self) {
//		_asset = asset;
//        _selected = NO;
//    }
//	return self;	
//}

- (void)toggleSelection
{
    self.selected = !self.selected;
}

static int g__ELCAsset_SelectIndex = 0;
+(void)selectBegin{
    g__ELCAsset_SelectIndex = 0;
}

- (void)setSelected:(BOOL)selected
{
    if (selected) {
        if ([_parent respondsToSelector:@selector(shouldSelectAsset:)]) {
            if (![_parent shouldSelectAsset:self]) {
                return;
            }
        }
    } else {
        if ([_parent respondsToSelector:@selector(shouldDeselectAsset:)]) {
            if (![_parent shouldDeselectAsset:self]) {
                return;
            }
        }
    }
    _selected = selected;
    if (selected) {
        _index =    g__ELCAsset_SelectIndex++;
        if (_parent != nil && [_parent respondsToSelector:@selector(assetSelected:)]) {
            [_parent assetSelected:self];
        }
    } else {
        if (_parent != nil && [_parent respondsToSelector:@selector(assetDeselected:)]) {
            [_parent assetDeselected:self];
        }
    }
}

-(void)setInfoFromELCAsset:(ELCAsset*)asset{
    _index      =   asset.index;
    _caption    =   asset.caption;
    _selected   =   asset.selected;
}

-(void)loadThumbWithBlock:(ELCAsset_LoadImgBlock)block{
    if(_parent.thumbCachingManger){
        [ELCAssetCacheManger loadImg:ELCAssetLoad_Thumb
                            forAsset:(PHAsset*)(_asset)
                          withManger:_parent.thumbCachingManger
                            andBlock:block];
        return;
    }
    block([self loadImgForALAsset:ELCAssetLoad_Thumb]);
}



-(UIImage*)_loadSynchronousNocacheImg:(BOOL)bForFullScreen{
    
    __block UIImage* resultImage = nil;
    
    PHImageRequestOptions* option = [[PHImageRequestOptions alloc] init];
    option.synchronous = YES;

    CGSize theSize;
    if(bForFullScreen){
        CGFloat scale = [UIScreen mainScreen].scale;
        theSize =  [UIScreen mainScreen].bounds.size;
        theSize =   CGSizeMake(theSize.width * scale, theSize.height * scale);
    }
    else{
        theSize =   PHImageManagerMaximumSize;
    }
    
    [[PHImageManager defaultManager] requestImageForAsset:(PHAsset*)_asset
                                               targetSize:theSize
                                              contentMode:PHImageContentModeDefault
                                                  options:option
                                            resultHandler:^(UIImage * result, NSDictionary * info) {
                                                resultImage = result;
                                            }];
    return resultImage;
}

-(UIImage*)fullResolutionImageNoCache{
    @autoreleasepool {
        
        if(_parent.phAssetGroup){
            return [self _loadSynchronousNocacheImg:NO];
          }
        
        ALAssetRepresentation *assetRepresentation =[(ALAsset*)_asset defaultRepresentation];
        //            CGImageRef imageRef = [assetRepresentation fullResolutionImage];
        return [[UIImage alloc] initWithCGImage:[assetRepresentation fullResolutionImage]
                                          scale:[assetRepresentation scale]
                                    orientation:(UIImageOrientation)[assetRepresentation orientation]];
    }
}

-(UIImage*)fullScreenImageNoCache{
    @autoreleasepool {
        if(_parent.phAssetGroup){
            return [self _loadSynchronousNocacheImg:YES];
        }
        ALAssetRepresentation *assetRepresentation =[(ALAsset*)_asset defaultRepresentation];
        //            CGImageRef imageRef = [assetRepresentation fullResolutionImage];
        return [[UIImage alloc] initWithCGImage:[assetRepresentation fullScreenImage]
                                          scale:[assetRepresentation scale]
                                    orientation:(UIImageOrientation)[assetRepresentation orientation]];
    }
}


-(UIImage*)loadImgForALAsset:(enum ELCAssetLoadImgType)nType{

    @autoreleasepool {
        if(ELCAssetLoad_Thumb==nType){
            return [UIImage imageWithCGImage:((ALAsset*)_asset).thumbnail];
        }
        
//        if(ELCAssetLoad_FullScreen==nType)
        {
            ALAssetRepresentation *assetRepresentation =[(ALAsset*)_asset defaultRepresentation];
            return  [[UIImage alloc] initWithCGImage:[assetRepresentation fullScreenImage]
                                              scale:[assetRepresentation scale]
                                        orientation:(UIImageOrientation)[assetRepresentation orientation]];
        }
        
        
        
//        ALAssetRepresentation *assetRepresentation =[(ALAsset*)_asset defaultRepresentation];
//        return [[UIImage alloc] initWithCGImage:[assetRepresentation fullResolutionImage]
//                                          scale:[assetRepresentation scale]
//                                    orientation:(UIImageOrientation)[assetRepresentation orientation]];
    };
}







//- (NSComparisonResult)compareWithIndex:(ELCAsset *)_ass
//{
//    if (self.index > _ass.index) {
//        return NSOrderedDescending;
//    }
//    else if (self.index < _ass.index)
//    {
//        return NSOrderedAscending;
//    }
//    return NSOrderedSame;
//}

@end




@implementation PHAssetsGroup
@end

