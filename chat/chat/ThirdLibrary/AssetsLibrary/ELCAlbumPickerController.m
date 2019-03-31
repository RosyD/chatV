//
//  AlbumPickerController.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAlbumPickerController.h"
#import "ELCImagePickerController.h"
#import "ELCAssetTablePicker.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "UIImage+Additions.h"




@interface ELCAlbumPickerController (){
    ALAssetsLibrary *_assetsLibrary;
    NSMutableArray *_assetGroups;
    NSMutableArray<ELCAsset*> *_selectedELCAssets;;
//    PHCachingImageManager *_phCachingManger;
}


@end

@implementation ELCAlbumPickerController


#ifdef ACUtility_Need_Log
-(void)dealloc{
    ITLog(@"");
}
#endif

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.parent action:@selector(cancelSelectAssert)];
	[self.navigationItem setRightBarButtonItem:cancelButton];

    _assetGroups = [[NSMutableArray alloc] init];
    _selectedELCAssets = [[NSMutableArray alloc] init];
    
    if ([PHAssetCollection class]){
        // 列出所有相册智能相册
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
            
            dispatch_async(dispatch_get_main_queue(), ^{
            
            if(status==PHAuthorizationStatusAuthorized){
                
                PHFetchResult* smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
                // 这时 smartAlbums 中保存的应该是各个智能相册对应的 PHAssetCollection
                
                PHFetchOptions *options = [[PHFetchOptions alloc] init];
                options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
                options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
                
                for(int i=0;i<2;i++){
                    for(NSInteger n=0;n<smartAlbums.count;n++){
                        PHCollection* assetCollection = [smartAlbums objectAtIndex:n];
                        if([assetCollection isKindOfClass:[PHAssetCollection class]]){
                            PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:(PHAssetCollection*)assetCollection options:options];
                            if(assetsFetchResult.count>0){
                                PHAssetsGroup* item = [[PHAssetsGroup alloc] init];
                                item.title = [NSString stringWithFormat:@"%@ (%ld)",assetCollection.localizedTitle, assetsFetchResult.count];
                                item.collection =   (PHAssetCollection*)assetCollection;
                                item.assets =   assetsFetchResult;
                                [_assetGroups addObject:item];
                            }
                        }
                    }
                    
                    //用户创建的分类
                    smartAlbums = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
                }
                [self.tableView reloadData];
            }
            else if(PHAuthorizationStatusNotDetermined!=status){
                NSString *errorMessage = NSLocalizedString(@"This app does not have access to your photos. You can enable access in Privacy Settings.", nil);
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Access Denied", nil) message:errorMessage delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil] show];
            }
            });
        }];
        
        /*
        if([PHPhotoLibrary authorizationStatus]==PHAuthorizationStatusAuthorized){

            PHFetchResult* smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
            // 这时 smartAlbums 中保存的应该是各个智能相册对应的 PHAssetCollection
         
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
           
            for(int i=0;i<2;i++){
                for(NSInteger n=0;n<smartAlbums.count;n++){
                    PHCollection* assetCollection = [smartAlbums objectAtIndex:n];
                    if([assetCollection isKindOfClass:[PHAssetCollection class]]){
                        PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:(PHAssetCollection*)assetCollection options:options];
                        if(assetsFetchResult.count>0){
                            PHAssetsGroup* item = [[PHAssetsGroup alloc] init];
                            item.title = [NSString stringWithFormat:@"%@ (%ld)",assetCollection.localizedTitle, assetsFetchResult.count];
                            item.collection =   (PHAssetCollection*)assetCollection;
                            item.assets =   assetsFetchResult;
                            item.thumbnail = [ELCAsset thumbFromAsset:assetsFetchResult.lastObject];
                            [_assetGroups addObject:item];
                        }
                    }
                }
                
                //用户创建的分类
                smartAlbums = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
            }
        }
        else if(PHAuthorizationStatusNotDetermined!=[PHPhotoLibrary authorizationStatus]){
            NSString *errorMessage = NSLocalizedString(@"This app does not have access to your photos. You can enable access in Privacy Settings.", nil);
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Access Denied", nil) message:errorMessage delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil] show];
        }*/
    }
    else{
        
        [self.navigationItem setTitle:NSLocalizedString(@"Loading...", nil)];

        ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
        _assetsLibrary = assetLibrary;

        // Load Albums into assetGroups
        dispatch_async(dispatch_get_main_queue(), ^
        {
            @autoreleasepool {
            
            // Group enumerator Block
                void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) 
                {
                    if (group == nil) {
                        return;
                    }
                    
                    // added fix for camera albums order
                    NSString *sGroupPropertyName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
                    NSUInteger nType = [[group valueForProperty:ALAssetsGroupPropertyType] intValue];
                    
                    if ([[sGroupPropertyName lowercaseString] isEqualToString:@"camera roll"] && nType == ALAssetsGroupSavedPhotos) {
                        [_assetGroups insertObject:group atIndex:0];
                    }
                    else {
                        [_assetGroups addObject:group];
                    }

                    // Reload albums
                    [self performSelectorOnMainThread:@selector(reloadTableView) withObject:nil waitUntilDone:YES];
                };
                
                // Group Enumerator Failure Block
                void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
                  
                    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusDenied) {
                        NSString *errorMessage = NSLocalizedString(@"This app does not have access to your photos. You can enable access in Privacy Settings.", nil);
                        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Access Denied", nil) message:errorMessage delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil] show];
                      
                    } else {
                        NSString *errorMessage = [NSString stringWithFormat:@"Album Error: %@ - %@", [error localizedDescription], [error localizedRecoverySuggestion]];
                        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:errorMessage delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil] show];
                    }

                    [self.navigationItem setTitle:nil];
                    NSLog(@"A problem occured %@", [error description]);	                                 
                };	
                        
                // Enumerate Albums
                [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
                                       usingBlock:assetGroupEnumerator 
                                     failureBlock:assetGroupEnumberatorFailure];
            
            }
        });
    }
    
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableView) name:ALAssetsLibraryChangedNotification object:nil];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
}*/

- (void)reloadTableView
{
	[self.tableView reloadData];
	[self.navigationItem setTitle:NSLocalizedString(@"Select an Album", nil)];
}

/*
- (BOOL)shouldSelectAsset:(ELCAsset *)asset previousCount:(NSUInteger)previousCount
{
    return [self.parent shouldSelectAsset:asset previousCount:previousCount];
}

- (BOOL)shouldDeselectAsset:(ELCAsset *)asset previousCount:(NSUInteger)previousCount
{
    return [self.parent shouldDeselectAsset:asset previousCount:previousCount];
}

- (void)selectedAssets:(NSArray*)assets
{
	[_parent selectedAssets:assets];
}

-(void) cancelSelectAssert{
    [_parent cancelSelectAssert];
}

- (BOOL)needSendPreview{
    return [_parent needSendPreview];
}

- (NSUInteger)selectMaximumImagesCount{
    return [_parent selectMaximumImagesCount];
}
*/


- (ALAssetsFilter *)assetFilter
{
    return [ALAssetsFilter allPhotos];
    /*
    if([self.mediaTypes containsObject:(NSString *)kUTTypeImage] && [self.mediaTypes containsObject:(NSString *)kUTTypeMovie])
    {
        return [ALAssetsFilter allAssets];
    }
    else if([self.mediaTypes containsObject:(NSString *)kUTTypeMovie])
    {
        return [ALAssetsFilter allVideos];
    }
    else
    {
        return [ALAssetsFilter allPhotos];
    }*/
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _assetGroups.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ELCAlbumPicker_Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    
    if(_assetsLibrary){
        // Get count
        ALAssetsGroup *g = (ALAssetsGroup*)[_assetGroups objectAtIndex:indexPath.row];
        [g setAssetsFilter:[self assetFilter]];
        NSInteger gCount = [g numberOfAssets];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (%ld)",[g valueForProperty:ALAssetsGroupPropertyName], (long)gCount];
        
        cell.imageView.image = [[UIImage imageWithCGImage:[g posterImage]] imageScaledToSize:CGSizeMake(ELCAsset_thumb_WH, ELCAsset_thumb_WH)];
    }
    else{
        PHAssetsGroup *g= _assetGroups[indexPath.row];
        cell.textLabel.text = g.title;
        
        [ELCAssetCacheManger loadImg:ELCAssetLoad_Thumb
                            forAsset:g.assets.firstObject
                          withManger:nil
                 andBlock:^(UIImage *img) {
                     cell.imageView.image = [img imageScaledToSize:CGSizeMake(ELCAsset_thumb_WH, ELCAsset_thumb_WH)];
        }];
    }
    

	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	ELCAssetTablePicker *picker = [[ELCAssetTablePicker alloc] initWithNibName: nil bundle: nil];
	picker.parent = _parent;
    picker.selectedELCAssets = _selectedELCAssets;
    picker.assetPickerFilterDelegate = self.assetPickerFilterDelegate;

    if(_assetsLibrary){
        picker.assetGroup = _assetGroups[indexPath.row];
        [picker.assetGroup setAssetsFilter:[self assetFilter]];
    }
    else{
//        if(nil==_phCachingManger){
//            _phCachingManger = [[PHCachingImageManager alloc] init];
////            _phCachingManger.allowsCachingHighQualityImages = NO;
//        }
//        picker.phCachingManger =    _phCachingManger;
        picker.phAssetGroup =   _assetGroups[indexPath.row];
    }
	
	[self.navigationController pushViewController:picker animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 95;
}

@end

