//
//  ELCAssetTablePicker.h
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ELCAsset.h"
#import "ELCAssetSelectionDelegate.h"
#import "ELCAssetPickerFilterDelegate.h"


@interface ELCAssetTablePicker : UITableViewController <ELCAssetDelegate>

@property (nonatomic, weak) id <ELCAssetSelectionDelegate> parent;
@property (nonatomic, weak) PHAssetsGroup * phAssetGroup;
@property (nonatomic, weak) ALAssetsGroup *assetGroup;
@property (nonatomic, weak) NSMutableArray<ELCAsset*> *selectedELCAssets;

@property (nonatomic, strong) NSMutableArray *elcAssets;
@property (nonatomic, strong) ELCAssetCacheManger *thumbCachingManger;
@property   (nonatomic)     BOOL    needCaption; //需要标题
//@property (nonatomic, strong) IBOutlet UILabel *selectedAssetsLabel;
//@property (nonatomic, assign) BOOL singleSelection;
//@property (nonatomic, assign) BOOL immediateReturn;

@property (nonatomic, strong) UIImage*  cellOverlayImageForSelected;
@property (nonatomic, strong) UIImage*  cellOverlayImageForUnSelect;

// optional, can be used to filter the assets displayed
@property(nonatomic, weak) id<ELCAssetPickerFilterDelegate> assetPickerFilterDelegate;

//- (int)totalSelectedAssets;
- (void)preparePhotos;
//-(void)clearElcAssetsSendImage;

-(void)previewWithELCAsset:(ELCAsset*)asset; //预览
//-(void)reloadCellForAssetSelectChange:(ELCAsset*)asset; //在别的界面选择改变时，重新加载

- (void)previewAssetsFinish; //预览图片结束
-(void)doSelectFinishWithVC:(UIViewController*)pVC; //选择结束"完成"
-(void)showSelectedTitleWithVC:(UIViewController*)pVC;

@end