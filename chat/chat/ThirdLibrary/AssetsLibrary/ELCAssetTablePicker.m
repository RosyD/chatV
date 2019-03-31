//
//  ELCAssetTablePicker.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetTablePicker.h"
#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCAlbumPickerController.h"
#import "AC_PreViewImagesWithCaption.h"
#import "UIImage+Additions.h"
#import "AC_ImgsScrollView.h"
#import "AC_ScrollPreViewController.h"

//#define ELCAssetTablePicker_Cell_height 79

#define ELCAssetTablePicker_Cell_height ((kScreen_Width - 4 * 5)/4 + 4)

@interface ELCAssetTablePicker (){
    NSInteger _nOldSelectCount;
//    int _selectedCount;
    int _columns;
    BOOL _bVisable;
    NSInteger _nFirstRow;
}

//@property (nonatomic, assign) int columns;
//@property (nonatomic, assign) int selectedCount;
//@property (nonatomic, assign) BOOL bVisable;

@end

@implementation ELCAssetTablePicker

//Using auto synthesizers

- (id)init
{
    self = [super init];
    if (self) {
        //Sets a reasonable default bigger then 0 for columns
        //So that we don't have a divide by 0 scenario
        _columns = 4;
    }
    return self;
}

//-(void)dealloc{
//    [_phCachingManger stopCachingImagesForAllAssets];
//    ITLog(@"stopCachingImagesForAllAssets");
//}

- (void)viewDidLoad
{
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	[self.tableView setAllowsSelection:NO];

    _cellOverlayImageForSelected    =   [UIImage imageInBundle:@"Overlay_selected@2x.png"];
    _cellOverlayImageForUnSelect    =   [UIImage imageInBundle:@"Overlay_unselected@2x.png"];
    
    _nOldSelectCount    =   _selectedELCAssets.count;
    
    self.elcAssets = [[NSMutableArray alloc] init];
	
//    if (self.immediateReturn) {
//        
//    } else
    
    {
        UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doSelectFinish)];
        [self.navigationItem setRightBarButtonItem:doneButtonItem];
        [self.navigationItem setTitle:NSLocalizedString(@"Loading...", nil)];
    }
    
	[self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
//    [self clearElcAssetsSendImage];
    // Register for notifications when the photo library has changed
    //不处理改变，避免出现用户在这里截屏，会死机
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preparePhotos) name:ALAssetsLibraryChangedNotification object:nil];

    
   // _columns = self.view.bounds.size.width / 80;
    _bVisable = YES;
    if(_elcAssets.count){
        [self _showSelectedTitle];
        if(_selectedELCAssets.count!=_nOldSelectCount){
            [self.tableView reloadData];
        }
    }
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    _nOldSelectCount = _selectedELCAssets.count;
    _bVisable = NO;
    [super viewWillDisappear:animated];
    
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    _columns = self.view.bounds.size.width / 80;
    [self.tableView reloadData];
}

-(void)_checkSelectELCAssets:(NSMutableArray*) elcAssets {
    if(_selectedELCAssets.count){
        NSArray<ELCAsset*> *selectItems = [NSArray arrayWithArray:_selectedELCAssets];
        [_selectedELCAssets removeAllObjects];
        for(ELCAsset* sel_item in selectItems){
            BOOL bNotFinded = YES;
            for(ELCAsset* item in elcAssets){
                if([item.asset isEqual:sel_item.asset]){
                    [item setInfoFromELCAsset:sel_item];
                    [_selectedELCAssets addObject:item];
                    bNotFinded = NO;
                    break;
                }
            }
            if(bNotFinded){
                sel_item.parent = self;
                [_selectedELCAssets addObject:sel_item];
            }
        }
    }
}

- (void)preparePhotos
{
    @autoreleasepool {
        
        [self.elcAssets removeAllObjects];
        
        if (_phAssetGroup){
            
            NSMutableArray* temp = [NSMutableArray array];
            for(PHAsset* assert in self.phAssetGroup.assets){
                ELCAsset* Item = [[ELCAsset alloc] init];
                Item.parent = self;
                Item.asset  = assert;
                [temp addObject:Item];
            }
            _thumbCachingManger = [[ELCAssetCacheManger alloc] initWithAssets:temp
                                                                   andWinSize:_columns*(1+(self.view.bounds.size.height/ELCAssetTablePicker_Cell_height))
                                                                   forImgType:ELCAssetLoad_Thumb];
            [self _checkSelectELCAssets:temp];
            self.elcAssets =    temp;
        }
        else{
            [self.assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                
                if (result == nil) {
                    return;
                }
                
                
                ELCAsset *elcAsset = [[ELCAsset alloc] init];
                elcAsset.parent = self;
                elcAsset.asset  = result;
                BOOL isAssetFiltered = NO;
                if (self.assetPickerFilterDelegate &&
                   [self.assetPickerFilterDelegate respondsToSelector:@selector(assetTablePicker:isAssetFilteredOut:)])
                {
                    isAssetFiltered = [self.assetPickerFilterDelegate assetTablePicker:self isAssetFilteredOut:(ELCAsset*)elcAsset];
                }

                if (!isAssetFiltered) {
                    [self.elcAssets addObject:elcAsset];
                }

             }];
            [self _checkSelectELCAssets:self.elcAssets];
        }


        dispatch_sync(dispatch_get_main_queue(), ^{
            
            [self.tableView reloadData];

            // scroll to bottom
            /*
            long section = [self numberOfSectionsInTableView:self.tableView] - 1;
            long row = [self tableView:self.tableView numberOfRowsInSection:section] - 1;
            if (section >= 0 && row >= 0) {
                NSIndexPath *ip = [NSIndexPath indexPathForRow:row
                                                     inSection:section];
                [self.tableView scrollToRowAtIndexPath:ip
                                      atScrollPosition:UITableViewScrollPositionBottom
                                              animated:NO];
            }*/
            
//            [self.navigationItem setTitle:self.singleSelection ? NSLocalized String(@"Pick Photo", nil) : NSLocalized String(@"Select photos", nil)];
            [self _showSelectedTitle];
//            [self.navigationItem setTitle:NSLocalized String(@"Select photos", nil)];
        });
    }
}

-(void)showSelectedTitleWithVC:(UIViewController*)pVC{
    NSString* pTitle = nil;
    int selectedCount = (int)_selectedELCAssets.count;
    if(selectedCount){
        pTitle = [NSString stringWithFormat:@"%@ (%d/%d)",NSLocalizedString(@"Selected", nil),selectedCount,(int)[_parent selectMaximumImagesCount]];
    }
    else{
        pTitle  =   NSLocalizedString(@"Select photos", nil);
    }
    [pVC.navigationItem setTitle:pTitle];
    pVC.navigationItem.rightBarButtonItem.enabled = selectedCount>0;
}

-(void)_showSelectedTitle{
    if(_bVisable){
        [self showSelectedTitleWithVC:self];
    }
}

-(void)_selectedAssetsFinishFunc:(BOOL)needPreViewSend withVC:(UIViewController*)pVC{
//    NSMutableArray *selectedAssetsImages = [[NSMutableArray alloc] init];
//    
//    for (ELCAsset *elcAsset in self.elcAssets) {
//        if ([elcAsset selected]) {
//            [selectedAssetsImages addObject:elcAsset];
//        }
//    }
    if(_selectedELCAssets.count==0){
        return;
    }
    
    //排序
    [_selectedELCAssets sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        ELCAsset* asset1 = (ELCAsset*) obj1;
        ELCAsset* asset2 = (ELCAsset*) obj2;
        return asset1.index>asset2.index?NSOrderedDescending:NSOrderedAscending;
    }];
    
    if(needPreViewSend){
        [pVC.view showProgressHUD];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            AC_PreViewImagesWithCaption* pPreview = [[AC_PreViewImagesWithCaption alloc] initWithNibName:nil bundle:nil];
            AC_MEM_Alloc(pPreview);
            pPreview.parent = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [pVC presentViewController:pPreview animated:YES completion:nil];
                [pVC.view hideProgressHUDWithAnimated:NO];
            });
        });
        return;
    }
    
    //TXB    if ([[ELCConsole mainConsole] onOrder]) {
    //        [selectedAssetsImages sortUsingSelector:@selector(compareWithIndex:)];
    //    }
    [self.parent selectedAssets:_selectedELCAssets];
}

- (void)previewAssetsFinish{ //选择图片结束
    [self _selectedAssetsFinishFunc:NO withVC:self];
}

- (void)doSelectFinish{
    [self _selectedAssetsFinishFunc:[_parent needSendPreview] withVC:self];
}

- (void)doSelectFinishWithVC:(UIViewController*)pVC{
    [self _selectedAssetsFinishFunc:[_parent needSendPreview] withVC:pVC];
}

-(NSInteger)selectMaximumImagesCount{
    return [_parent selectMaximumImagesCount];
}

- (BOOL)shouldSelectAsset:(ELCAsset *)asset
{
    BOOL shouldSelect = YES;
    if ([self.parent respondsToSelector:@selector(shouldSelectAsset:previousCount:)]) {
        shouldSelect = [self.parent shouldSelectAsset:asset previousCount:_selectedELCAssets.count];
    }
    return shouldSelect;
}


- (void)assetSelected:(ELCAsset *)asset
{
    /*
    if (self.singleSelection) {

        for (ELCAsset *elcAsset in self.elcAssets) {
            if (asset != elcAsset) {
                elcAsset.selected = NO;
            }
        }
    }
    if (self.immediateReturn) {
        NSArray *singleAssetArray = @[asset];
        [(NSObject *)self.parent performSelector:@selector(selectedAssets:) withObject:singleAssetArray afterDelay:0];
    }*/
    
//    _selectedCount ++;
    [_selectedELCAssets addObject:asset];
    [self _showSelectedTitle];
}

- (BOOL)shouldDeselectAsset:(ELCAsset *)asset
{
    /*
    if (self.immediateReturn){
        return NO;
    }*/
    
    return YES;
}

- (void)assetDeselected:(ELCAsset *)asset
{
/*
    if (self.singleSelection) {
        for (ELCAsset *elcAsset in self.elcAssets) {
            if (asset != elcAsset) {
                elcAsset.selected = NO;
            }
        }
    }

    if (self.immediateReturn) {
        NSArray *singleAssetArray = @[asset.asset];
        [(NSObject *)self.parent performSelector:@selector(selectedAssets:) withObject:singleAssetArray afterDelay:0];
    }
    */
    
    [_selectedELCAssets removeObject:asset];
    [self _showSelectedTitle];

    
//TXB
/*    int numOfSelectedElements = [[ELCConsole mainConsole] numOfSelectedElements];
    if (asset.index < numOfSelectedElements - 1) {
        NSMutableArray *arrayOfCellsToReload = [[NSMutableArray alloc] initWithCapacity:1];
        
        for (int i = 0; i < [self.elcAssets count]; i++) {
            ELCAsset *assetInArray = [self.elcAssets objectAtIndex:i];
            if (assetInArray.selected && (assetInArray.index > asset.index)) {
                assetInArray.index -= 1;
                
                int row = i / self.columns;
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
                BOOL indexExistsInArray = NO;
                for (NSIndexPath *indexInArray in arrayOfCellsToReload) {
                    if (indexInArray.row == indexPath.row) {
                        indexExistsInArray = YES;
                        break;
                    }
                }
                if (!indexExistsInArray) {
                    [arrayOfCellsToReload addObject:indexPath];
                }
            }
        }
        [self.tableView reloadRowsAtIndexPaths:arrayOfCellsToReload withRowAnimation:UITableViewRowAnimationNone];
    }*/
}
/*
-(void)reloadCellForAssetSelectChange:(ELCAsset*)asset{ //在别的界面选择改变时，重新加载
    //修改界面
    for (int i = 0; i < [self.elcAssets count]; i++){
        if(asset==self.elcAssets[i]){
            int row = i / _columns;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
    }
}
 */

//-(void)clearElcAssetsSendImage{
////    for (ELCAsset *asset in self.elcAssets) {
////        asset.imageForSend = nil;
////    }
//}

#define PreView_CacheCount 20
-(void)previewWithELCAsset:(ELCAsset*)asset{
    
//    @autoreleasepool
    {

//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        AC_ScrollPreViewController* pPreVC = [[AC_ScrollPreViewController alloc] initPreVCWithParent:self];
        AC_MEM_Alloc(pPreVC);
        for(NSInteger i=0;i<_elcAssets.count;i++){
            if(asset==_elcAssets[i]){
                pPreVC.nFistShowImgNo = i;
                break;
            }
        }
   //        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationItem setTitle:@""];
            [self.navigationController pushViewController:pPreVC animated:YES];
//        });
//    });

    }
}

#pragma mark UITableViewDataSource Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (_columns <= 0) { //Sometimes called before we know how many columns we have
        _columns = 4;
    }
    NSInteger numRows = ceil([self.elcAssets count] / (float)_columns);
    return numRows;
}

- (NSArray *)assetsForIndexPath:(NSIndexPath *)path
{
    long index = path.row * _columns;
    long length = MIN(_columns, [self.elcAssets count] - index);
    return [self.elcAssets subarrayWithRange:NSMakeRange(index, length)];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"ELCAsset_Cell";
        
    ELCAssetCell *cell = (ELCAssetCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {		        
        cell = [[ELCAssetCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    cell.superAssetTablePicker = self;
    [cell setAssets:[self assetsForIndexPath:indexPath]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return ELCAssetTablePicker_Cell_height;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
//    [super scrollViewDidScroll:scrollView];
    NSInteger nNowFirstRow = scrollView.contentOffset.y/ELCAssetTablePicker_Cell_height;
    if(nNowFirstRow!=_nFirstRow){
        [_thumbCachingManger cacheCheck:nNowFirstRow*_columns forNext:nNowFirstRow>_nFirstRow];
        _nFirstRow = nNowFirstRow;
    }
}




@end
