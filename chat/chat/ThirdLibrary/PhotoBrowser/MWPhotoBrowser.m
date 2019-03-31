//
//  MWPhotoBrowser.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MWPhotoBrowser.h"
#import "MWZoomingScrollView.h"
#import "MBProgressHUD.h"
#import "SDImageCache.h"
#import "ELCAssetTablePicker.h"
#import "UIView+Additions.h"
#import "ELCAlbumPickerController.h"
#import "ELCImagePickerController.h"
#import "ACContributeViewController.h"
#import "ELCAssetTablePicker.h"

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define PADDING                 10
#define PAGE_INDEX_TAG_OFFSET   1000
#define PAGE_INDEX(page)        ([(page) tag] - PAGE_INDEX_TAG_OFFSET)

// Private
@interface MWPhotoBrowser () {
    
	// Data
    id <MWPhotoBrowserDelegate> _delegate;
    NSUInteger _photoCount;
//    NSArray *_depreciatedPhotoData; // Depreciated
    MWPhoto* _pSimplePhoto;
	
	// Views
	UIScrollView *_pagingScrollView;
	
	// Paging
	NSMutableSet *_visiblePages, *_recycledPages;
	NSUInteger _currentPageIndex;
	NSUInteger _pageIndexBeforeRotation;
	
	// Navigation & controls
	UIToolbar *_toolbar;
	NSTimer *_controlVisibilityTimer;
	UIBarButtonItem *_previousButton, *_nextButton, *_actionButton, *_sendBarButton;
    UIButton *_sendButton;
    UIActionSheet *_actionsSheet;
    MBProgressHUD *_progressHUD;
    
    // Appearance
    UIImage *_navigationBarBackgroundImageDefault, 
    *_navigationBarBackgroundImageLandscapePhone;
    UIColor *_previousNavBarTintColor;
    UIBarStyle _previousNavBarStyle;
    UIStatusBarStyle _previousStatusBarStyle;
    UIBarButtonItem *_previousViewControllerBackButton;
    
    // Misc
    BOOL _displayActionButton;
	BOOL _performingLayout;
	BOOL _rotating;
    BOOL _viewIsActive; // active as in it's in the view heirarchy
    BOOL _didSavePreviousStateOfNavBar;
    
}

// Private Properties
@property (nonatomic, retain) UIColor *previousNavBarTintColor;
@property (nonatomic, retain) UIBarButtonItem *previousViewControllerBackButton;
@property (nonatomic, retain) UIImage *navigationBarBackgroundImageDefault, *navigationBarBackgroundImageLandscapePhone;
@property (nonatomic, retain) UIActionSheet *actionsSheet;
@property (nonatomic, retain) MBProgressHUD *progressHUD;

// Private Methods

// Layout
- (void)performLayout;

// Nav Bar Appearance
- (void)setNavBarAppearance:(BOOL)animated;
- (void)storePreviousNavBarAppearance;
- (void)restorePreviousNavBarAppearance:(BOOL)animated;

// Paging
- (void)tilePages;
- (BOOL)isDisplayingPageForIndex:(NSUInteger)index;
- (MWZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index;
- (MWZoomingScrollView *)pageDisplayingPhoto:(id<MWPhoto>)photo;
- (MWZoomingScrollView *)dequeueRecycledPage;
- (void)configurePage:(MWZoomingScrollView *)page forIndex:(NSUInteger)index;
- (void)didStartViewingPageAtIndex:(NSUInteger)index;

// Frames
- (CGRect)frameForPagingScrollView;
- (CGRect)frameForPageAtIndex:(NSUInteger)index;
- (CGSize)contentSizeForPagingScrollView;
- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index;
- (CGRect)frameForToolbarAtOrientation:(UIInterfaceOrientation)orientation;
- (CGRect)frameForCaptionView:(MWCaptionView *)captionView atIndex:(NSUInteger)index;

// Navigation
- (void)updateNavigation;
- (void)jumpToPageAtIndex:(NSUInteger)index;
- (void)gotoPreviousPage;
- (void)gotoNextPage;

// Controls
- (void)cancelControlHiding;
- (void)hideControlsAfterDelay;
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent;
- (void)toggleControls;
- (BOOL)areControlsHidden;

// Data
- (NSUInteger)numberOfPhotos;
- (id<MWPhoto>)photoAtIndex:(NSUInteger)index;
- (UIImage *)imageForPhoto:(id<MWPhoto>)photo;
- (void)loadAdjacentPhotosIfNecessary:(id<MWPhoto>)photo;
- (void)releaseAllUnderlyingPhotos;

// Actions
- (void)savePhoto;
- (void)copyPhoto;
- (void)emailPhoto;

@end

// Handle depreciations and supress hide warnings
@interface UIApplication (DepreciationWarningSuppresion)
- (void)setStatusBarHidden:(BOOL)hidden animated:(BOOL)animated;
@end

// MWPhotoBrowser
@implementation MWPhotoBrowser

// Properties
@synthesize previousNavBarTintColor = _previousNavBarTintColor;
@synthesize navigationBarBackgroundImageDefault = _navigationBarBackgroundImageDefault,
navigationBarBackgroundImageLandscapePhone = _navigationBarBackgroundImageLandscapePhone;
@synthesize displayActionButton = _displayActionButton, actionsSheet = _actionsSheet;
@synthesize progressHUD = _progressHUD;
@synthesize delegateForShowPhoto = _delegateForShowPhoto;
@synthesize previousViewControllerBackButton = _previousViewControllerBackButton;

#pragma mark - NSObject

- (id)init {
    
    if ((self = [super init])) {
        
        // Defaults
        self.wantsFullScreenLayout = YES;
        self.hidesBottomBarWhenPushed = YES;
        _photoCount = NSNotFound;
		_currentPageIndex = 0;
		_performingLayout = NO; // Reset on view did appear
		_rotating = NO;
        _viewIsActive = NO;
        _displayActionButton = NO;
        _didSavePreviousStateOfNavBar = NO;
        
        // Listen for MWPhoto notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleMWPhotoLoadingDidEndNotification:)
                                                     name:MWPHOTO_LOADING_DID_END_NOTIFICATION
                                                   object:nil];
    }
    return self;
}

- (id)initWithDelegate:(id <MWPhotoBrowserDelegate>)delegate browserType:(enum BrowserType)browserType{
    
    if ((self = [self init])) {
        _delegate = delegate;
        _browserType = browserType;
        if (browserType == BrowserType_SendImageBrowser&&[_delegate isKindOfClass:[ELCAssetTablePicker class]]) {
            _assetPicker = (ELCAssetTablePicker *)delegate;
        }
	}
	return self;
}

//- (id)initWithPhotos:(NSArray *)photosArray {
//    
//	if ((self = [self init])) {
//		_depreciatedPhotoData = [photosArray retain];
//        _browserType    =   BrowserType_DefineBrowser;
//	}
//	return self;
//}

- (id)initWithPhotoFile:(NSString*)pFilePathName withURL:(NSString*)pURL{
    MWPhoto *photo = nil;
    
    if (pFilePathName.length&&[[NSFileManager defaultManager] fileExistsAtPath:pFilePathName]){
        photo = [MWPhoto photoWithFilePath:pFilePathName]; //已经 autorelease
    }
    
    if (nil==photo&&pURL.length){
        photo = [MWPhoto photoWithURL:[NSURL URLWithString:pURL]]; //已经 autorelease
    }
    
    if(photo){
        if ((self = [self init])) {
            _pSimplePhoto = [photo retain];
//            _depreciatedPhotoData = [NSArray arrayWithObject:photo];
            _browserType    =   BrowserType_DefineBrowser;
        }
//        [photo release]; //已经 autorelease
        return self;
    }
    return nil;
}


- (void)dealloc {
//    ITLog(@"xxxxxxx");
    [_sendNumButton release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_previousNavBarTintColor release];
    [_navigationBarBackgroundImageDefault release];
    [_navigationBarBackgroundImageLandscapePhone release];
    [_previousViewControllerBackButton release];
    _pagingScrollView.delegate = nil;
    [_pagingScrollView release];
    [_visiblePages release];
    [_recycledPages release];
    [_toolbar release];
    [_previousButton release];
    [_nextButton release];
    [_actionButton release];
    [_sendButton release];
    [_sendBarButton release];
//    [_depreciatedPhotoData release];
    [self releaseAllUnderlyingPhotos];
    [[SDImageCache sharedImageCache] clearMemory]; // clear memory
    [_photos release];
    [_progressHUD release];
    _assetPicker = nil;
//    [_delegate release];
    _delegate = nil;
    [_delegateForShowPhoto release];
    _delegateForShowPhoto = nil;
    [_pSimplePhoto release];
    [super dealloc];
}

- (void)releaseAllUnderlyingPhotos {
    
    for (id p in _photos) { if (p != [NSNull null]) [p unloadUnderlyingImage]; } // Release photos
}

- (void)didReceiveMemoryWarning {
	
	// Release any cached data, images, etc that aren't in use.
    [self releaseAllUnderlyingPhotos];
	[_recycledPages removeAllObjects];
    
	[super didReceiveMemoryWarning];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0)
    {
        if([self.view window] == nil)
        {
            [self memoryLowOperator];
            self.view = nil;
        }
    }
}

#pragma mark - View Loading

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
//    ITLog(([NSString stringWithFormat:@"%@",self.view.subviews]));
//    
//    [self setIos7SpecialSetting];
    
    _visiblePages = [[NSMutableSet alloc] init];
    _recycledPages = [[NSMutableSet alloc] init];
    _photos = [[NSMutableArray alloc] init];

	// View
	self.view.backgroundColor = [UIColor blackColor];
	
	// Setup paging scrolling view
	CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
	_pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
    _pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_pagingScrollView.pagingEnabled = YES;
	_pagingScrollView.delegate = self;
	_pagingScrollView.showsHorizontalScrollIndicator = NO;
	_pagingScrollView.showsVerticalScrollIndicator = NO;
	_pagingScrollView.backgroundColor = [UIColor blackColor];
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
	[self.view addSubview:_pagingScrollView];
	
    // Toolbar
    _toolbar = [[UIToolbar alloc] initWithFrame:[self frameForToolbarAtOrientation:self.interfaceOrientation]];
    _toolbar.tintColor = nil;
    if ([[UIToolbar class] respondsToSelector:@selector(appearance)]) {
        [_toolbar setBackgroundImage:nil forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
        [_toolbar setBackgroundImage:nil forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsLandscapePhone];
    }
    _toolbar.barStyle = UIBarStyleBlackTranslucent;
    _toolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    // Toolbar Items
    _previousButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"MWPhotoBrowser.bundle/images/UIBarButtonItemArrowLeft.png"] style:UIBarButtonItemStylePlain target:self action:@selector(gotoPreviousPage)];
    _nextButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"MWPhotoBrowser.bundle/images/UIBarButtonItemArrowRight.png"] style:UIBarButtonItemStylePlain target:self action:@selector(gotoNextPage)];
    _actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonPressed:)];
    
    {//发送按钮BrowserType_SendImageBrowser
        UIView *sendView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 29)];
        
        _sendButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 80, 29)];
        [_sendButton setBackgroundImage:[[UIImage imageNamed:@"photoTransfer_send.png"] stretchableImageWithLeftCapWidth:18 topCapHeight:15] forState:UIControlStateNormal];
        [_sendButton setBackgroundImage:[[UIImage imageNamed:@"photoTransfer_sendDown.png"] stretchableImageWithLeftCapWidth:18 topCapHeight:15] forState:UIControlStateHighlighted];
        [_sendButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
        [_sendButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [_sendButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [sendView addSubview:_sendButton];
        
        _sendNumButton = [[UIButton alloc] initWithFrame:CGRectMake(60, -10, 25, 25)];
        [_sendNumButton setUserInteractionEnabled:NO];
        [_sendNumButton setBackgroundImage:[UIImage imageNamed:@"photoTransfer_numBg.png"] forState:UIControlStateNormal];
        [sendView addSubview:_sendNumButton];
        
        _sendBarButton = [[UIBarButtonItem alloc] initWithCustomView:sendView];
        [sendView release];
        if (_browserType == BrowserType_SendImageBrowser) {
            NSInteger totalCount = [_assetPicker totalSelectedAssetsCount];
            if (totalCount >= 1) {
                [_sendButton setAlpha:1];
                [_sendButton setEnabled:YES];
                [_sendNumButton setHidden:NO];
                [_sendNumButton setTitle:[NSString stringWithFormat:@"%d",totalCount] forState:UIControlStateNormal];
            } else {
//                [_sendButton setAlpha:0.7];
//                [_sendButton setEnabled:NO];
                [_sendNumButton setHidden:YES];
            }
        }
    }
    // Update
    [self reloadData];
    
	// Super
    [super viewDidLoad];
	
}

-(void)viewDidAppear:(BOOL)animated
{
    
    [super viewDidAppear:animated];
    _viewIsActive = YES;
}

-(void)refreshDataWithIndex:(NSInteger)index imagePath:(NSString *)imagePath
{
//    ITLog(([NSString stringWithFormat:@"%d %@",index,imagePath]));
    CGRect visibleBounds = _pagingScrollView.bounds;
	int iFirstIndex = (int)floorf((CGRectGetMinX(visibleBounds)+PADDING*2) / CGRectGetWidth(visibleBounds));
	int iLastIndex  = (int)floorf((CGRectGetMaxX(visibleBounds)-PADDING*2-1) / CGRectGetWidth(visibleBounds));
    if (iFirstIndex < 0) iFirstIndex = 0;
    if (iFirstIndex > [self numberOfPhotos] - 1) iFirstIndex = [self numberOfPhotos] - 1;
    if (iLastIndex < 0) iLastIndex = 0;
    if (iLastIndex > [self numberOfPhotos] - 1) iLastIndex = [self numberOfPhotos] - 1;
    
    NSInteger pageIndex;
    
    if (_visiblePages == nil)
    {
        return;
    }
    
    @synchronized(_visiblePages)
    {
        
//        ITLog(([NSString stringWithFormat:@"%@",_visiblePages]));
        NSArray *visiblePagesArray = [_visiblePages allObjects];
        for (int i = 0; i < [visiblePagesArray count]; i++) {
            MWZoomingScrollView *page = [visiblePagesArray objectAtIndex:i];
            @synchronized(page)
            {
                if (page == nil)
                {
                    return;
                }
                
                pageIndex = PAGE_INDEX(page);
                
//                ITLog(([NSString stringWithFormat:@"pageIndex4:::%d,%d,%d,%d",pageIndex,iFirstIndex,iLastIndex,index]));
                if (pageIndex >= (NSUInteger)iFirstIndex && pageIndex <= (NSUInteger)iLastIndex && pageIndex == index)
                {
                    page.photoImageView.image = [UIImage imageWithContentsOfFile:imagePath];
                    
                    if (_browserType == BrowserType_DefineBrowser) {
                        [page.spinner stopAnimating];
                        page.photoImageView.hidden = NO;
                        page.photoImageView.frame = CGRectMake(123, 208, 75, 75);
                        
                        CGSize size = page.photoImageView.image.size;
                        if (size.width < 640) {
                            size.height = size.height * (640.0/size.width);
                            size.width = 640;
                        }
//                        ITLog(([NSString stringWithFormat:@"pageIndex1:::%d,%@,%@",pageIndex,page,page.photoImageView]));
                        [UIView animateWithDuration:0.2f animations:^
                         {
                             page.photoImageView.frame = CGRectMake((self.view.bounds.size.width-size.width/2)/2, (self.view.bounds.size.height-size.height/2)/2, size.width/2, size.height/2);
                         }
                                         completion:^(BOOL finished)
                         {
                             if ([page progressHud] != nil && [[page progressHud] superview])
                             {
                                 [page.progressHud hide:NO];
//                                 [[page progressHud] removeFromSuperview];
//                                 page.progressHud = nil;
                             }
                         }];
                    } else {
                        page.photoImageView.size = page.photoImageView.image.size;
//                        ITLog(([NSString stringWithFormat:@"pageIndex2:::%d,%@,%@",pageIndex,page,page.photoImageView]));
                    }
                } else {
//                    ITLog(([NSString stringWithFormat:@"pageIndex3:::%d,%@,%@",pageIndex,page,page.photoImageView]));
                }
            }
        }
    }
}

//从本地读图片使用
-(void)refreshDataWithIndex:(NSInteger)index image:(UIImage *)image
{
    
    CGRect visibleBounds = _pagingScrollView.bounds;
	int iFirstIndex = (int)floorf((CGRectGetMinX(visibleBounds)+PADDING*2) / CGRectGetWidth(visibleBounds));
	int iLastIndex  = (int)floorf((CGRectGetMaxX(visibleBounds)-PADDING*2-1) / CGRectGetWidth(visibleBounds));
    if (iFirstIndex < 0) iFirstIndex = 0;
    if (iFirstIndex > [self numberOfPhotos] - 1) iFirstIndex = [self numberOfPhotos] - 1;
    if (iLastIndex < 0) iLastIndex = 0;
    if (iLastIndex > [self numberOfPhotos] - 1) iLastIndex = [self numberOfPhotos] - 1;
    
    NSInteger pageIndex;
    
    if (_visiblePages == nil)
    {
        return;
    }
    
    @synchronized(_visiblePages)
    {
        NSArray *array = [_visiblePages allObjects];
        for (int i = 0; i < [array count]; i++) {
            MWZoomingScrollView *page = [array objectAtIndex:i];
            @synchronized(page)
            {
                if (page == nil)
                {
                    return;
                }
                
                pageIndex = PAGE_INDEX(page);
                
                
                if (pageIndex >= (NSUInteger)iFirstIndex && pageIndex <= (NSUInteger)iLastIndex && pageIndex == index)
                {
                    page.photoImageView.image = image;
                    if (_browserType == BrowserType_DefineBrowser) {
                        page.photoImageView.frame = CGRectMake(123, 208, 75, 75);
                        [UIView beginAnimations:nil context:nil];
                        
                        CGSize size = page.photoImageView.image.size;
                        
                        [UIView animateWithDuration:8.f animations:^
                         {
                             page.photoImageView.frame = CGRectMake((self.view.bounds.size.width-size.width/2)/2, (self.view.bounds.size.height-size.height/2)/2, size.width/2, size.height/2);
                         }
                                         completion:^(BOOL finished)
                         {
                             if ([page progressHud] != nil && [[page progressHud] superview])
                             {
                                 [page.progressHud hide:NO];
//                                 [[page progressHud] removeFromSuperview];
//                                 page.progressHud = nil;
                             }
                         }];
                        [UIView commitAnimations];
                    } else {
                        page.photoImageView.size = page.photoImageView.image.size;
                    }
                } else {
                }
            }
        }
    }
}

-(void)rrefreshData
{
    
}


- (void)performLayout {
    
    // Setup
    _performingLayout = YES;
    NSUInteger numberOfPhotos = [self numberOfPhotos];
    
	// Setup pages
    [_visiblePages removeAllObjects];
    [_recycledPages removeAllObjects];
    
    // Toolbar
    if (numberOfPhotos > 1 || _displayActionButton || _browserType == BrowserType_SendImageBrowser) {
        [self.view addSubview:_toolbar];
    } else {
        [_toolbar removeFromSuperview];
    }
    
    // Toolbar items & navigation
    UIBarButtonItem *fixedLeftSpace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil] autorelease];
    if (_browserType == BrowserType_SendImageBrowser) {
        fixedLeftSpace.width = 80;
    } else {
        fixedLeftSpace.width = 32; // To balance action button
    }
    UIBarButtonItem *flexSpace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil] autorelease];
    NSMutableArray *items = [[NSMutableArray alloc] init];
    if (_displayActionButton||_browserType == BrowserType_SendImageBrowser) [items addObject:fixedLeftSpace];
    [items addObject:flexSpace];
    if (numberOfPhotos > 1) [items addObject:_previousButton];
    [items addObject:flexSpace];
    if (numberOfPhotos > 1) [items addObject:_nextButton];
    [items addObject:flexSpace];
    if (_browserType == BrowserType_SendImageBrowser) {
        [items addObject:_sendBarButton];
    } else {
        if (_displayActionButton) [items addObject:_actionButton];
    }
    [_toolbar setItems:items];
    [items release];
	[self updateNavigation];
    
    // Navigation buttons
    
    if ([self.navigationController.viewControllers objectAtIndex:0] == self) {
        // We're first on stack so show done button

        UIBarButtonItem *doneButton = [[[UIBarButtonItem alloc] initWithTitle:_browserType == BrowserType_SendImageBrowser?NSLocalizedString(@"Cancel",nil):NSLocalizedString(@"Finished", nil)
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(doneButtonPressed:)] autorelease];
        // Set appearance
        if ([UIBarButtonItem respondsToSelector:@selector(appearance)]) {
            [doneButton setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
            [doneButton setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
            [doneButton setBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
            [doneButton setBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsLandscapePhone];
            [doneButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateNormal];
            [doneButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateHighlighted];
        }
        self.navigationItem.rightBarButtonItem = doneButton;
    } else {
        if (_browserType == BrowserType_SendImageBrowser) {
            UIButton *customButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 49, 49)];
            [customButton addTarget:self action:@selector(selectedButtonPressedDown:) forControlEvents:UIControlEventTouchDown];
            [customButton setImage:[UIImage imageNamed:@"photoTransfer_bigNoSelected.png"] forState:UIControlStateNormal];
            [customButton setImage:[UIImage imageNamed:@"photoTransfer_bigSelected.png"] forState:UIControlStateSelected];
            UIBarButtonItem *selectedButton = [[UIBarButtonItem alloc] initWithCustomView:customButton];
            [customButton release];
            self.navigationItem.rightBarButtonItem = selectedButton;
            [selectedButton release];
        }
        // We're not first so show back button
        UIViewController *previousViewController = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
        NSString *backButtonTitle = previousViewController.navigationItem.backBarButtonItem ? previousViewController.navigationItem.backBarButtonItem.title : previousViewController.title;
        UIBarButtonItem *newBackButton = [[[UIBarButtonItem alloc] initWithTitle:backButtonTitle style:UIBarButtonItemStylePlain target:nil action:nil] autorelease];
        // Appearance
        if ([UIBarButtonItem respondsToSelector:@selector(appearance)]) {
            [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
            [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
            [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
            [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsLandscapePhone];
            [newBackButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateNormal];
            [newBackButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateHighlighted];
        }
        self.previousViewControllerBackButton = previousViewController.navigationItem.backBarButtonItem; // remember previous
        previousViewController.navigationItem.backBarButtonItem = newBackButton;
    }
    
    // Content offset
	_pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:_currentPageIndex];
    [self tilePages];
    _performingLayout = NO;
    
}

-(void)memoryLowOperator
{
    
    [_pagingScrollView release];
    _pagingScrollView = nil;
    [_visiblePages release];
    _visiblePages = nil;
    [_recycledPages release];
    _recycledPages= nil;
    [_toolbar release];
    _toolbar = nil;
    [_previousButton release];
    _previousButton = nil;
    [_nextButton release];
    _nextButton = nil;
    [_actionButton release];
    _actionButton = nil;

    self.progressHUD = nil;

}

// Release any retained subviews of the main view.
- (void)viewDidUnload
{
    
	_currentPageIndex = 0;
    [self memoryLowOperator];
    [super viewDidUnload];
}

#pragma mark - Appearance

- (void)viewWillAppear:(BOOL)animated {
    
	// Super
	[super viewWillAppear:animated];
	if (_browserType == BrowserType_SendImageBrowser) {
        NSInteger totalCount = [_assetPicker totalSelectedAssetsCount];
        if (totalCount >= 1) {
            [_sendButton setAlpha:1];
            [_sendButton setEnabled:YES];
            [_sendNumButton setHidden:NO];
            [_sendNumButton setTitle:[NSString stringWithFormat:@"%d",totalCount] forState:UIControlStateNormal];
        } else {
//            [_sendButton setAlpha:0.7];
//            [_sendButton setEnabled:NO];
            [_sendNumButton setHidden:YES];
        }
    }
    
	// Layout manually (iOS < 5)
    if (SYSTEM_VERSION_LESS_THAN(@"5")) {
        [self viewWillLayoutSubviews];
    }
    
    // Status bar
    if (self.wantsFullScreenLayout && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _previousStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:animated];
    }
    
    // Navigation bar appearance
    if (!_viewIsActive && [self.navigationController.viewControllers objectAtIndex:0] != self) {
        [self storePreviousNavBarAppearance];
    }
    [self setNavBarAppearance:animated];
    
    // Update UI
	[self hideControlsAfterDelay];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    
    // Check that we're being popped for good
    if ([self.navigationController.viewControllers objectAtIndex:0] != self &&
        ![self.navigationController.viewControllers containsObject:self]) {
        
        // State
        _viewIsActive = NO;
        
        // Bar state / appearance
        [self restorePreviousNavBarAppearance:animated];
        
    }
    
    // Controls
    [self.navigationController.navigationBar.layer removeAllAnimations]; // Stop all animations on nav bar
    [NSObject cancelPreviousPerformRequestsWithTarget:self]; // Cancel any pending toggles from taps
    [self setControlsHidden:NO animated:NO permanent:YES];
    
    // Status bar
    if (self.wantsFullScreenLayout && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication] setStatusBarStyle:_previousStatusBarStyle animated:animated];
    }
    
	// Super
	[super viewWillDisappear:animated];
    
}

#pragma mark - Nav Bar Appearance

- (void)setNavBarAppearance:(BOOL)animated {
    
    self.navigationController.navigationBar.tintColor = nil;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    if ([[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
        [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsLandscapePhone];
    }
}

- (void)storePreviousNavBarAppearance {
    
    _didSavePreviousStateOfNavBar = YES;
    self.previousNavBarTintColor = self.navigationController.navigationBar.tintColor;
    _previousNavBarStyle = self.navigationController.navigationBar.barStyle;
    if ([[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
        self.navigationBarBackgroundImageDefault = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
        self.navigationBarBackgroundImageLandscapePhone = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsLandscapePhone];
    }
}

- (void)restorePreviousNavBarAppearance:(BOOL)animated {
    
    if (_didSavePreviousStateOfNavBar) {
        self.navigationController.navigationBar.tintColor = _previousNavBarTintColor;
        self.navigationController.navigationBar.barStyle = _previousNavBarStyle;
        if ([[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
            [self.navigationController.navigationBar setBackgroundImage:_navigationBarBackgroundImageDefault forBarMetrics:UIBarMetricsDefault];
            [self.navigationController.navigationBar setBackgroundImage:_navigationBarBackgroundImageLandscapePhone forBarMetrics:UIBarMetricsLandscapePhone];
        }
        // Restore back button if we need to
        if (_previousViewControllerBackButton) {
            UIViewController *previousViewController = [self.navigationController topViewController]; // We've disappeared so previous is now top
            previousViewController.navigationItem.backBarButtonItem = _previousViewControllerBackButton;
            self.previousViewControllerBackButton = nil;
        }
    }
}

#pragma mark - Layout

- (void)viewWillLayoutSubviews {
    
    // Super
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5")) [super viewWillLayoutSubviews];
	
	// Flag
	_performingLayout = YES;
	
	// Toolbar
	_toolbar.frame = [self frameForToolbarAtOrientation:self.interfaceOrientation];
	
	// Remember index
	NSUInteger indexPriorToLayout = _currentPageIndex;
	
	// Get paging scroll view frame to determine if anything needs changing
	CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    
	// Frame needs changing
	_pagingScrollView.frame = pagingScrollViewFrame;
	
	// Recalculate contentSize based on current orientation
	_pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
	
	// Adjust frames and configuration of each visible page
	for (MWZoomingScrollView *page in _visiblePages) {
        NSUInteger index = PAGE_INDEX(page);
		page.frame = [self frameForPageAtIndex:index];
        [page setFrame_y:0];
//        ITLog(([NSString stringWithFormat:@"MWZoomingScrollView----Frame:::%@",NSStringFromCGRect(page.frame)]));
        page.captionView.frame = [self frameForCaptionView:page.captionView atIndex:index];
		[page setMaxMinZoomScalesForCurrentBounds];
	}
	
	// Adjust contentOffset to preserve page location based on values collected prior to location
	_pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:indexPriorToLayout];
//    if (_browserType != BrowserType_SendImageBrowser) {
        [self didStartViewingPageAtIndex:_currentPageIndex]; // initial
//    }
	
    
	// Reset
	_currentPageIndex = indexPriorToLayout;
	_performingLayout = NO;
    if ([_delegate respondsToSelector:@selector(photoBrowser:getBigPhotoAtIndex:withRefreshUI:)]) {
        [_delegate photoBrowser:self getBigPhotoAtIndex:_currentPageIndex withRefreshUI:YES];
    }
}

#pragma mark - Rotation

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
//    NSLog(@"ViewController supportedInterfaceOrientations");
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
	// Remember page index before rotation
	_pageIndexBeforeRotation = _currentPageIndex;
	_rotating = YES;
	
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	// Perform layout
	_currentPageIndex = _pageIndexBeforeRotation;
    
	// Layout manually (iOS < 5)
    if (SYSTEM_VERSION_LESS_THAN(@"5")) [self viewWillLayoutSubviews];
	
	// Delay control holding
	[self hideControlsAfterDelay];
	
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
	_rotating = NO;
}

#pragma mark - Data

- (void)reloadData {
    
    // Reset
    _photoCount = NSNotFound;
    
    // Get data
    NSUInteger numberOfPhotos = [self numberOfPhotos];
    [self releaseAllUnderlyingPhotos];
    [_photos removeAllObjects];
    for (int i = 0; i < numberOfPhotos; i++) [_photos addObject:[NSNull null]];
    
    // Update
    [self performLayout];
    
    // Layout
    if (SYSTEM_VERSION_LESS_THAN(@"5")) [self viewWillLayoutSubviews];
    else [self.view setNeedsLayout];
    
}

- (NSUInteger)numberOfPhotos {
    
    if (_photoCount == NSNotFound) {
        if ([_delegate respondsToSelector:@selector(numberOfPhotosInPhotoBrowser:)]) {
            _photoCount = [_delegate numberOfPhotosInPhotoBrowser:self];
        }
        else if(_pSimplePhoto){
            _photoCount = 1;
        }
//        } else if (_depreciatedPhotoData) {
//            _photoCount = _depreciatedPhotoData.count;
//        }
    }
    if (_photoCount == NSNotFound) _photoCount = 0;
    return _photoCount;
}

- (id<MWPhoto>)photoAtIndex:(NSUInteger)index {
    
    id <MWPhoto> photo = nil;
    if (index < _photos.count) {
        if ([_photos objectAtIndex:index] == [NSNull null]) {
            if ([_delegate respondsToSelector:@selector(photoBrowser:photoAtIndex:)]) {
                photo = [_delegate photoBrowser:self photoAtIndex:index];
            }
            else{
                photo = _pSimplePhoto;
            }
//            } else if (_depreciatedPhotoData && index < _depreciatedPhotoData.count) {
//                photo = [_depreciatedPhotoData objectAtIndex:index];
//            }
            if (photo) [_photos replaceObjectAtIndex:index withObject:photo];
        } else {
            photo = [_photos objectAtIndex:index];
        }
    }
    return photo;
}

- (MWCaptionView *)captionViewForPhotoAtIndex:(NSUInteger)index {
    
    MWCaptionView *captionView = nil;
    if ([_delegate respondsToSelector:@selector(photoBrowser:captionViewForPhotoAtIndex:)]) {
        captionView = [_delegate photoBrowser:self captionViewForPhotoAtIndex:index];
    } else {
        id <MWPhoto> photo = [self photoAtIndex:index];
        if ([photo respondsToSelector:@selector(caption)]) {
            if ([photo caption]) captionView = [[[MWCaptionView alloc] initWithPhoto:photo] autorelease];
        }
    }
    captionView.alpha = [self areControlsHidden] ? 0 : 1; // Initial alpha
    return captionView;
}

-(UIProgressView *)processbarForPhoto:(id<MWPhoto>)photo {
    
	if (photo) {
		// Get image or obtain in background
		return ((MWPhoto *)photo).progressView;
	}
	return nil;
}


- (UIImage *)imageForPhoto:(id<MWPhoto>)photo {
    
	if (photo) {
		// Get image or obtain in background
		if ([photo underlyingImage]) {
			return [photo underlyingImage];
		}
        else {
            [photo loadUnderlyingImageAndNotify];
		}
	}
	return nil;
}

- (void)loadAdjacentPhotosIfNecessary:(id<MWPhoto>)photo {
    
    MWZoomingScrollView *page = [self pageDisplayingPhoto:photo];
    if (page) {
        // If page is current page then initiate loading of previous and next pages
        NSUInteger pageIndex = PAGE_INDEX(page);
        if (_currentPageIndex == pageIndex) {
            if (pageIndex > 0) {
                // Preload index - 1
                id <MWPhoto> photo = [self photoAtIndex:pageIndex-1];
                if (![photo underlyingImage]) {
                    [photo loadUnderlyingImageAndNotify];
                    MWLog(@"Pre-loading image at index %i", pageIndex-1);
                }
            }
            if (pageIndex < [self numberOfPhotos] - 1) {
                // Preload index + 1
                id <MWPhoto> photo = [self photoAtIndex:pageIndex+1];
                if (![photo underlyingImage]) {
                    [photo loadUnderlyingImageAndNotify];
                    MWLog(@"Pre-loading image at index %i", pageIndex+1);
                }
            }
        }
    }
}


-(int)checkNetImagesForIndex:(int)index{
    if (index < 0) index = 0;
    if (index > [self numberOfPhotos] - 1) index = [self numberOfPhotos] - 1;
    
    if ((MWPhotoBrowser_NET_Images_load_state_allow&_NET_Images_load_state)&&
        [_delegate respondsToSelector:@selector(photoBrowser:NetPreLoad:)]&&
        MWPhotoBrowser_NET_Images_load_state_Load_End_All!=(_NET_Images_load_state&MWPhotoBrowser_NET_Images_load_state_Load_End_All)) {
        
        NSInteger nCurVisableTag = PAGE_INDEX_TAG_OFFSET+index;
        
        if([_delegate photoBrowser:self NetLoadAtCurIndex:&index]){
            ITLog(@"Load More");

            
            _photoCount = [_delegate numberOfPhotosInPhotoBrowser:self];
            for (MWZoomingScrollView *page in _visiblePages){
                if(page.tag==nCurVisableTag){
                    //避免闪烁
                    page.tag =  PAGE_INDEX_TAG_OFFSET+ index;
                    page.frame = [self frameForPageAtIndex:index];
                    [page setFrame_y:0];
                    break;
                }
            }
            [self releaseAllUnderlyingPhotos];
            [_photos removeAllObjects];
            for (int i = 0; i < _photoCount; i++) [_photos addObject:[NSNull null]];
            _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
            _pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:index];
            
        }
        else{
            int nLoadMoreDir = 0;  //加载更多的方向
//            NSAssert([self numberOfPhotos]>5,@"[self numberOfPhotos]>5");
            
            if(4==index&&
               index<_currentPageIndex&&
               0==(_NET_Images_load_state&MWPhotoBrowser_NET_Images_load_state_Load_End_Head)){
                //向前
                nLoadMoreDir = MWPhotoBrowser_NET_Images_func_load_back;
            }
            
            if(index==[self numberOfPhotos]-4&&
               index>_currentPageIndex&&
               0==(_NET_Images_load_state&MWPhotoBrowser_NET_Images_load_state_Load_End_Tail)){
                //向前
                nLoadMoreDir = MWPhotoBrowser_NET_Images_func_load_forward;
            }
            
            if(nLoadMoreDir){
                ITLog(@"Pre Load More");
                [_delegate photoBrowser:self NetPreLoad:nLoadMoreDir];
            }
        }
    }
    return index;
}

#pragma mark - MWPhoto Loading Notification

- (void)handleMWPhotoLoadingDidEndNotification:(NSNotification *)notification {
    
    id <MWPhoto> photo = [notification object];
    MWZoomingScrollView *page = [self pageDisplayingPhoto:photo];
    if (page) {
        if ([photo underlyingImage]) {
            // Successful load
            [page displayImage];
            [self loadAdjacentPhotosIfNecessary:photo];
        } else {
            // Failed to load
            [page displayImageFailure];
        }
    }
}

#pragma mark - Paging

- (void)tilePages {
	
	// Calculate which pages should be visible
	// Ignore padding as paging bounces encroach on that
	// and lead to false page loads
	CGRect visibleBounds = _pagingScrollView.bounds;
	int iFirstIndex = (int)floorf((CGRectGetMinX(visibleBounds)+PADDING*2) / CGRectGetWidth(visibleBounds));
	int iLastIndex  = (int)floorf((CGRectGetMaxX(visibleBounds)-PADDING*2-1) / CGRectGetWidth(visibleBounds));
    if (iFirstIndex < 0) iFirstIndex = 0;
    if (iFirstIndex > [self numberOfPhotos] - 1) iFirstIndex = [self numberOfPhotos] - 1;
    if (iLastIndex < 0) iLastIndex = 0;
    if (iLastIndex > [self numberOfPhotos] - 1) iLastIndex = [self numberOfPhotos] - 1;
	//NSLog(@"%d %d",iFirstIndex,iLastIndex);
	// Recycle no longer needed pages
    NSInteger pageIndex;
    
	for (MWZoomingScrollView *page in _visiblePages)
    {
        pageIndex = PAGE_INDEX(page);
        
		if (pageIndex < (NSUInteger)iFirstIndex || pageIndex > (NSUInteger)iLastIndex)
        {
            if ([page progressHud] != nil && [[page progressHud] superview])
            {
                [page.progressHud hide:NO];
//                [[page progressHud] removeFromSuperview];
//                page.progressHud = nil;
            }
            
			[_recycledPages addObject:page];
            [page prepareForReuse];
			[page removeFromSuperview];
//			ITLogEX(@"Removed page at index %i", PAGE_INDEX(page));
		}
	}
	[_visiblePages minusSet:_recycledPages];
    while (_recycledPages.count > 2) // Only keep 2 recycled pages
    {
        /*if ([[_recycledPages anyObject] progressView] != nil && [[[_recycledPages anyObject] progressView] superview])
        {
            [[[_recycledPages anyObject] progressView] removeFromSuperview];
        }*/
        
        [_recycledPages removeObject:[_recycledPages anyObject]];
    }
	
	// Add missing pages
	for (NSUInteger index = (NSUInteger)iFirstIndex; index <= (NSUInteger)iLastIndex; index++) {
		if (![self isDisplayingPageForIndex:index]) {
            
            // Add new page
			MWZoomingScrollView *page = [self dequeueRecycledPage];
            // page.progressView = nil;
			if (!page) {
				page = [[MWZoomingScrollView alloc] initWithPhotoBrowser:self];
			}
            
            if (page.progressHud != nil && [page.progressHud superview] != nil)
            {
                [page.progressHud hide:NO];
//                [page.progressHud removeFromSuperview];
//                page.progressHud = nil;
            }
            
			[self configurePage:page forIndex:index];
			[_visiblePages addObject:page];
            [page release];
			[_pagingScrollView addSubview:page];
//			ITLogEX(@"Added page at index %i", index);
            
            // Add caption
            MWCaptionView *captionView = [self captionViewForPhotoAtIndex:index];
            captionView.frame = [self frameForCaptionView:captionView atIndex:index];
            [_pagingScrollView addSubview:captionView];
            page.captionView = captionView;
            
		}
	}
	
}

- (void)tileCurrentPage {
	
	// Calculate which pages should be visible
	// Ignore padding as paging bounces encroach on that
	// and lead to false page loads
	CGRect visibleBounds = _pagingScrollView.bounds;
	int iFirstIndex = (int)floorf((CGRectGetMinX(visibleBounds)+PADDING*2) / CGRectGetWidth(visibleBounds));
	int iLastIndex  = (int)floorf((CGRectGetMaxX(visibleBounds)-PADDING*2-1) / CGRectGetWidth(visibleBounds));
    if (iFirstIndex < 0) iFirstIndex = 0;
    if (iFirstIndex > [self numberOfPhotos] - 1) iFirstIndex = [self numberOfPhotos] - 1;
    if (iLastIndex < 0) iLastIndex = 0;
    if (iLastIndex > [self numberOfPhotos] - 1) iLastIndex = [self numberOfPhotos] - 1;
	
	// Recycle no longer needed pages
    NSInteger pageIndex;
	for (MWZoomingScrollView *page in _visiblePages) {
        pageIndex = PAGE_INDEX(page);
		if (pageIndex < (NSUInteger)iFirstIndex || pageIndex > (NSUInteger)iLastIndex) {
			[_recycledPages addObject:page];
            [page prepareForReuse];
            [[page retain] autorelease];
			[page removeFromSuperview];
			MWLog(@"Removed page at index %i", PAGE_INDEX(page));
		}
	}
	[_visiblePages minusSet:_recycledPages];
    while (_recycledPages.count > 2) // Only keep 2 recycled pages
        [_recycledPages removeObject:[_recycledPages anyObject]];
	
	// Add missing pages
	for (MWZoomingScrollView *page in _visiblePages) {
            [self configurePage:page forIndex:_currentPageIndex];
		}
}


- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
//    ITLog(([NSString stringWithFormat:@"%d",index]));
	for (MWZoomingScrollView *page in _visiblePages)
		if (PAGE_INDEX(page) == index) return YES;
	return NO;
}

- (MWZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index {
    
	MWZoomingScrollView *thePage = nil;
	for (MWZoomingScrollView *page in _visiblePages) {
		if (PAGE_INDEX(page) == index) {
			thePage = page; break;
		}
	}
	return thePage;
}

- (MWZoomingScrollView *)pageDisplayingPhoto:(id<MWPhoto>)photo {
    
	MWZoomingScrollView *thePage = nil;
	for (MWZoomingScrollView *page in _visiblePages) {
		if (page.photo == photo) {
			thePage = page; break;
		}
	}
	return thePage;
}

- (void)configurePage:(MWZoomingScrollView *)page forIndex:(NSUInteger)index {
    
	page.frame = [self frameForPageAtIndex:index];
    [page setFrame_y:0];
//    ITLog(([NSString stringWithFormat:@"MWZoomingScrollView----Frame:::%@",NSStringFromCGRect(page.frame)]));
    page.tag = PAGE_INDEX_TAG_OFFSET + index;
    page.photo = [self photoAtIndex:index];
}

- (MWZoomingScrollView *)dequeueRecycledPage {
    
	MWZoomingScrollView *page = [_recycledPages anyObject];
	if (page) {
		[page retain];
		[_recycledPages removeObject:page];
        
        
	}
	return page;
}

// Handle page changes
- (void)didStartViewingPageAtIndex:(NSUInteger)index {
    
    // Release images further away than +/-1
    
    if (_browserType == BrowserType_SendImageBrowser) {
        _elcAssetSelected = [_assetPicker getELCAssetSelectedWithIndex:index];
        if (_elcAssetSelected) {
            [(UIButton *)self.navigationItem.rightBarButtonItem.customView setSelected:YES];
        } else {
            [(UIButton *)self.navigationItem.rightBarButtonItem.customView setSelected:NO];
        }
    }
    
//    _previousIndex = index;
    NSUInteger i;
    if (index > 0) {
        // Release anything < index - 1
        for (i = 0; i < index-1; i++) {
            if ([_photos count] > i) {
                id photo = [_photos objectAtIndex:i];
                if (photo != [NSNull null]) {
                    [photo unloadUnderlyingImage];
                    [_photos replaceObjectAtIndex:i withObject:[NSNull null]];
                    MWLog(@"Released underlying image at index %i", i);
                }
            }
        }
    }
    if (index < [self numberOfPhotos] - 1) {
        // Release anything > index + 1
        for (i = index + 2; i < _photos.count; i++) {
            id photo = [_photos objectAtIndex:i];
            if (photo != [NSNull null]) {
                [photo unloadUnderlyingImage];
                [_photos replaceObjectAtIndex:i withObject:[NSNull null]];
                MWLog(@"Released underlying image at index %i", i);
            }
        }
    }
    
    // Load adjacent images if needed and the photo is already
    // loaded. Also called after photo has been loaded in background
    id <MWPhoto> currentPhoto = [self photoAtIndex:index];
    if ([currentPhoto underlyingImage]) {
        // photo loaded so load ajacent now
        [self loadAdjacentPhotosIfNecessary:currentPhoto];
    }
    
}

#pragma mark - Frame Calculations

- (CGRect)frameForPagingScrollView {
    
    CGRect frame = self.view.bounds;// [[UIScreen mainScreen] bounds];
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return frame;
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    
    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
    // because it has a rotation transform applied.
    CGRect bounds = _pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (bounds.size.width * index) + PADDING;
    return pageFrame;
}

- (CGSize)contentSizeForPagingScrollView {
    
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = _pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self numberOfPhotos], bounds.size.height);
}

- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index {
    
	CGFloat pageWidth = _pagingScrollView.bounds.size.width;
	CGFloat newOffset = index * pageWidth;
	return CGPointMake(newOffset, 0);
}

- (CGRect)frameForToolbarAtOrientation:(UIInterfaceOrientation)orientation {
    
    CGFloat height = 44;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
        UIInterfaceOrientationIsLandscape(orientation)) height = 32;
	return CGRectMake(0, self.view.bounds.size.height - height, self.view.bounds.size.width, height);
}

- (CGRect)frameForCaptionView:(MWCaptionView *)captionView atIndex:(NSUInteger)index {
    
    CGRect pageFrame = [self frameForPageAtIndex:index];
    captionView.frame = CGRectMake(0, 0, pageFrame.size.width, 44); // set initial frame
    CGSize captionSize = [captionView sizeThatFits:CGSizeMake(pageFrame.size.width, 0)];
    CGRect captionFrame = CGRectMake(pageFrame.origin.x, pageFrame.size.height - captionSize.height - (_toolbar.superview?_toolbar.frame.size.height:0), pageFrame.size.width, captionSize.height);
    return captionFrame;
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	
    // Checks
    if (!_viewIsActive || _performingLayout || _rotating){
//        ITLog(@"Checks");
        return;
    }
    
    if (scrollView.contentOffset.y != 0) {
        /*TXB禁止上下滚动
         禁止UIScrollView垂直方向滚动，只允许水平方向滚动
         
         scrollview.contentSize =  CGSizeMake(你要的长度, 0);
         禁止UIScrollView水平方向滚动，只允许垂直方向滚动
         
         scrollview.contentSize =  CGSizeMake(0, 你要的宽度)
         
         这个在这里不好使，不知道为什么
         */
        scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, 0);
    }
    
    CGRect visibleBounds = _pagingScrollView.bounds;
//    ITLogEX(@"%d",(int)(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds))));
    _currentPageIndex = [self checkNetImagesForIndex:(int)(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)))];
//    ITLogEX(@"index = %ld x=%f,y=%f",_currentPageIndex,visibleBounds.origin.x,visibleBounds.origin.y);
	// Tile pages
	[self tilePages];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
//    ITLog(@"");
	// Hide controls when dragging begins
	[self setControlsHidden:YES animated:YES permanent:NO];
    
   /* if([_delegate photoBrowser:self NetLoadAtCurIndex:NULL]){
//        ITLog(@"Load More");
        
        int index = (int)_currentPageIndex;
        [_delegate photoBrowser:self NetLoadAtCurIndex:&index];
        _currentPageIndex = index;
        
        _photoCount = [_delegate numberOfPhotosInPhotoBrowser:self];
        [self releaseAllUnderlyingPhotos];
        [_photos removeAllObjects];
        for (int i = 0; i < _photoCount; i++) [_photos addObject:[NSNull null]];
        _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
        _pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:index];
    }*/
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//    ITLog(@"");
	// Update nav when page changes
//    [self performSelectorOnMainThread:@selector(updateNavigation) withObject:nil waitUntilDone:YES];
    
    // Calculate current page
	CGRect visibleBounds = _pagingScrollView.bounds;
//	NSUInteger previousCurrentPage = _currentPageIndex;
 
    _currentPageIndex = [self checkNetImagesForIndex:(int)(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)))];
//	if (_currentPageIndex != previousCurrentPage) {
        [self didStartViewingPageAtIndex:_currentPageIndex];
        [self updateNavigation];
//    }
    
    if ([_delegate respondsToSelector:@selector(photoBrowser:getBigPhotoAtIndex:withRefreshUI:)]) {
        [_delegate photoBrowser:self getBigPhotoAtIndex:_currentPageIndex withRefreshUI:YES];
    }
  }

#pragma mark - Navigation

- (void)updateNavigation {
	// Title
	if ([self numberOfPhotos] > 1&&0==(_NET_Images_load_state&MWPhotoBrowser_NET_Images_load_state_allow)) {
//		self.title = [NSString stringWithFormat:@"%i %@ %i", _currentPageIndex+1, NSLocalizedString(@"/", @"Used in the context: 'Showing 1 of 3 items'"), [self numberOfPhotos]];
        self.title = [NSString stringWithFormat:@"%i/%i", (int)(_currentPageIndex+1), (int)[self numberOfPhotos]];
//        ITLog(self.title);
	} else {
		self.title = nil;
	}
	
	// Buttons
	_previousButton.enabled = (_currentPageIndex > 0);
	_nextButton.enabled = (_currentPageIndex < [self numberOfPhotos]-1);
}

- (void)jumpToPageAtIndex:(NSUInteger)index
{
	
	// Change page
	if (index < [self numberOfPhotos])
    {
		CGRect pageFrame = [self frameForPageAtIndex:index];
		_pagingScrollView.contentOffset = CGPointMake(pageFrame.origin.x - PADDING, 0);
        
        [self didStartViewingPageAtIndex:index];
		[self updateNavigation];
        
        if ([_delegate respondsToSelector:@selector(photoBrowser:getBigPhotoAtIndex:withRefreshUI:)])
        {
            [_delegate photoBrowser:self getBigPhotoAtIndex:_currentPageIndex withRefreshUI:YES];
        }
	}
	
	// Update timer to give more time
	[self hideControlsAfterDelay];
	
}

- (void)gotoPreviousPage
{
    _currentPageIndex = [self checkNetImagesForIndex:_currentPageIndex -1];
    [self jumpToPageAtIndex:_currentPageIndex];
}
- (void)gotoNextPage
{
    _currentPageIndex = [self checkNetImagesForIndex:_currentPageIndex +1];
    [self jumpToPageAtIndex:_currentPageIndex];
}

#pragma mark - Control Hiding / Showing

// If permanent then we don't set timers to hide again
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent {
    
    if (_browserType != BrowserType_SendImageBrowser) {
        // Cancel any timers
        [self cancelControlHiding];
        
        // Status bar and nav bar positioning
        if (self.wantsFullScreenLayout) {
            
            // Get status bar height if visible
            CGFloat statusBarHeight = 0;
            if (![UIApplication sharedApplication].statusBarHidden) {
                CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
                statusBarHeight = MIN(statusBarFrame.size.height, statusBarFrame.size.width);
            }
            
            // Status Bar
            if ([UIApplication instancesRespondToSelector:@selector(setStatusBarHidden:withAnimation:)]) {
                [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:animated?UIStatusBarAnimationFade:UIStatusBarAnimationNone];
            } else {
                [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:animated];
            }
            
            // Get status bar height if visible
            if (![UIApplication sharedApplication].statusBarHidden) {
                CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
                statusBarHeight = MIN(statusBarFrame.size.height, statusBarFrame.size.width);
            }
            
            // Set navigation bar frame
            CGRect navBarFrame = self.navigationController.navigationBar.frame;
            navBarFrame.origin.y = statusBarHeight;
            self.navigationController.navigationBar.frame = navBarFrame;
            
        }
        
        // Captions
        NSMutableSet *captionViews = [[[NSMutableSet alloc] initWithCapacity:_visiblePages.count] autorelease];
        for (MWZoomingScrollView *page in _visiblePages) {
            if (page.captionView) [captionViews addObject:page.captionView];
        }
        
        // Animate
        if (animated) {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.35];
        }
        CGFloat alpha = hidden ? 0 : 1;
        [self.navigationController.navigationBar setAlpha:alpha];
        [_toolbar setAlpha:alpha];
        for (UIView *v in captionViews) v.alpha = alpha;
        if (animated) [UIView commitAnimations];
        
        // Control hiding timer
        // Will cancel existing timer but only begin hiding if
        // they are visible
        if (!permanent) [self hideControlsAfterDelay];
    }
}

- (void)cancelControlHiding {
    
	// If a timer exists then cancel and release
	if (_controlVisibilityTimer) {
		[_controlVisibilityTimer invalidate];
		[_controlVisibilityTimer release];
		_controlVisibilityTimer = nil;
	}
}

// Enable/disable control visiblity timer
- (void)hideControlsAfterDelay {
    
	if (![self areControlsHidden]) {
        [self cancelControlHiding];
		_controlVisibilityTimer = [[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(hideControls) userInfo:nil repeats:NO] retain];
	}
}

- (BOOL)areControlsHidden { return (_toolbar.alpha == 0); /* [UIApplication sharedApplication].isStatusBarHidden; */ }
- (void)hideControls { [self setControlsHidden:YES animated:YES permanent:NO]; }
- (void)toggleControls { [self setControlsHidden:![self areControlsHidden] animated:YES permanent:NO]; }

#pragma mark - Properties

- (void)setInitialPageIndex:(NSUInteger)index {
    
    // Validate
    if (index >= [self numberOfPhotos]) index = [self numberOfPhotos]-1;
    _currentPageIndex = index;
	if ([self isViewLoaded]) {
        [self jumpToPageAtIndex:index];
        if (!_viewIsActive) [self tilePages]; // Force tiling if view is not visible
    }
}

#pragma mark - Misc

- (void)doneButtonPressed:(id)sender {
    
    if(_delegateForShowPhoto){
        [_delegateForShowPhoto onPhotoBrowserShowPhotoExit:self];
    }
    else{
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (void)selectedButtonPressedDown:(UIButton *)sender {
    
    [sender setSelected:!sender.selected];
    [_assetPicker setELCAssetSelected:sender.selected WithIndex:_currentPageIndex];
    NSInteger totalCount = [_assetPicker totalSelectedAssetsCount];
/*WB
    不知道在什么地方使用
    int canSelectCount = (int)(kMultiCount - ((ACContributeViewController *)(((ELCImagePickerController *)(((ELCAlbumPickerController *)(_assetPicker.parent)).parent)).delegate)).noteMessage.multiArray.count);
    int canSelectCount  = 10;
    
    if(totalCount > canSelectCount) {
        NSString *message = [NSString stringWithFormat:@"%@ %d",NSLocalizedString(@"accessory max count is", nil),kMultiCount];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:message delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
		[alert show];
		[alert release];
        [sender setSelected:!sender.selected];
        [_assetPicker setELCAssetSelected:sender.selected WithIndex:_currentPageIndex];
    } else {
        [_assetPicker reloadSendImgNum];
        if (totalCount >= 1) {
            [_sendButton setAlpha:1];
            [_sendButton setEnabled:YES];
            [_sendNumButton setHidden:NO];
            [_sendNumButton setTitle:[NSString stringWithFormat:@"%d",totalCount] forState:UIControlStateNormal];
        } else {
//            [_sendButton setAlpha:0.7];
//            [_sendButton setEnabled:NO];
            [_sendNumButton setHidden:YES];
        }
 }*/

}

- (void)sendButtonPressed:(id)sender {
    
    if (_assetPicker != nil) {
        NSInteger totalCount = [_assetPicker totalSelectedAssetsCount];
        if (totalCount > 0) {
            if ([_assetPicker respondsToSelector:@selector(sendImage:)]) {
                [_assetPicker sendImage:nil];
            }
        } else {
            [_assetPicker setELCAssetSelected:YES WithIndex:_currentPageIndex];
            if ([_assetPicker respondsToSelector:@selector(sendImage:)]) {
                [_assetPicker sendImage:nil];
            }
//            ELCAsset *elcAsset = [_assetPicker getElcAssetWithIndex:_currentPageIndex];
//            if ([_assetPicker respondsToSelector:@selector(sendSingleImageWithELCAsset:)]) {
//                [_assetPicker sendSingleImageWithELCAsset:elcAsset];
//            }
        }
    }
    else{
        //TXB 调用发送
        if ([_delegate respondsToSelector:@selector(photoBrowser:sendAtIndex:)]) {
            [_delegate photoBrowser:self sendAtIndex:_currentPageIndex];
        }
    }
}

- (void)actionButtonPressed:(id)sender {
    
    if (_actionsSheet) {
        // Dismiss
        [_actionsSheet dismissWithClickedButtonIndex:_actionsSheet.cancelButtonIndex animated:YES];
        [_actionsSheet release];
        _actionsSheet = nil;
    } else {
        id <MWPhoto> photo = [self photoAtIndex:_currentPageIndex];
        if ([self numberOfPhotos] > 0 && [photo underlyingImage]) {
            
            // Keep controls hidden
            [self setControlsHidden:NO animated:YES permanent:YES];
            
            // Sheet
            if ([MFMailComposeViewController canSendMail]) {
                self.actionsSheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil
                                                        otherButtonTitles:NSLocalizedString(@"Save to album", nil), NSLocalizedString(@"Copy to clipboard", nil), NSLocalizedString(@"Send by email", nil), nil] autorelease];
            } else {
                self.actionsSheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil
                                                        otherButtonTitles:NSLocalizedString(@"Save to album", nil), NSLocalizedString(@"Copy to clipboard", nil), nil] autorelease];
            }
            _actionsSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                [_actionsSheet showFromBarButtonItem:sender animated:YES];
            } else {
                [_actionsSheet showInView:self.view];
            }
            
        }
    }
}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet == _actionsSheet) {           
        // Actions 
        self.actionsSheet = nil;
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            if (buttonIndex == actionSheet.firstOtherButtonIndex) {
                [self savePhoto]; return;
            } else if (buttonIndex == actionSheet.firstOtherButtonIndex + 1) {
                [self copyPhoto]; return;	
            } else if (buttonIndex == actionSheet.firstOtherButtonIndex + 2) {
                [self emailPhoto]; return;
            }
        }
    }
    [self hideControlsAfterDelay]; // Continue as normal...
    [_actionsSheet release];
    _actionsSheet = nil;
}

#pragma mark - MBProgressHUD

- (MBProgressHUD *)progressHUD {
    if (!_progressHUD)
    {
        if (self.view)
        {
            _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        }
        
        if (_progressHUD)
        {
            _progressHUD.minSize = CGSizeMake(120, 120);
            _progressHUD.minShowTime = 1;
            // The sample image is based on the
            // work by: http://www.pixelpressicons.com
            // licence: http://creativecommons.org/licenses/by/2.5/ca/
            self.progressHUD.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MWPhotoBrowser.bundle/images/Checkmark.png"]] autorelease];
            [self.view addSubview:_progressHUD];
        }
    }
    
    return _progressHUD;
}

- (void)showProgressHUDWithMessage:(NSString *)message {
    self.progressHUD.labelText = message;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD show:YES];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
}

- (void)hideProgressHUD:(BOOL)animated {
    [self.progressHUD hide:animated];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

- (void)showProgressHUDCompleteMessage:(NSString *)message {
    if (message) {
        if (self.progressHUD.isHidden) [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.mode = MBProgressHUDModeCustomView;
        [self.progressHUD hide:YES afterDelay:1.5];
    } else {
        [self.progressHUD hide:YES];
    }
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

#pragma mark - Actions

- (void)savePhoto {
    id <MWPhoto> photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage]) {
        [self showProgressHUDWithMessage:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"Saving",@"Displayed with ellipsis as 'Saving...' when an item is in the process of being saved")]];
        [self performSelector:@selector(actuallySavePhoto:) withObject:photo afterDelay:0];
    }
}

- (void)actuallySavePhoto:(id<MWPhoto>)photo {
    if ([photo underlyingImage]) {
        UIImageWriteToSavedPhotosAlbum([photo underlyingImage], self, 
                                       @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    [self showProgressHUDCompleteMessage: error ? NSLocalizedString(@"Saving", @"Informing the user a process has failed") : NSLocalizedString(@"Saved", @"Informing the user an item has been saved")];
    [self hideControlsAfterDelay]; // Continue as normal...
}

- (void)copyPhoto {
    id <MWPhoto> photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage]) {
        [self showProgressHUDWithMessage:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"Copying", @"Displayed with ellipsis as 'Copying...' when an item is in the process of being copied")]];
        [self performSelector:@selector(actuallyCopyPhoto:) withObject:photo afterDelay:0];
    }
}

- (void)actuallyCopyPhoto:(id<MWPhoto>)photo {
    if ([photo underlyingImage]) {
        [[UIPasteboard generalPasteboard] setData:UIImagePNGRepresentation([photo underlyingImage])
                                forPasteboardType:@"public.png"];
        [self showProgressHUDCompleteMessage:NSLocalizedString(@"Copied", @"Informing the user an item has finished copying")];
        [self hideControlsAfterDelay]; // Continue as normal...
    }
}

- (void)emailPhoto {
    id <MWPhoto> photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage]) {
        [self showProgressHUDWithMessage:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"Email open in", @"Displayed with ellipsis as 'Preparing...' when an item is in the process of being prepared")]];
        [self performSelector:@selector(actuallyEmailPhoto:) withObject:photo afterDelay:0];
    }
}

- (void)actuallyEmailPhoto:(id<MWPhoto>)photo {
    if ([photo underlyingImage]) {
        MFMailComposeViewController *emailer = [[MFMailComposeViewController alloc] init];
        emailer.mailComposeDelegate = self;
        [emailer setSubject:@""];
        [emailer addAttachmentData:UIImagePNGRepresentation([photo underlyingImage]) mimeType:@"png" fileName:@"Photo.png"];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            emailer.modalPresentationStyle = UIModalPresentationPageSheet;
        }
        [self presentModalViewController:emailer animated:YES];
        [emailer release];
        [self hideProgressHUD:NO];
    }
}

#pragma mark Mail Compose Delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    if (result == MFMailComposeResultFailed) {
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:nil
                                                         message:NSLocalizedString(@"Email failed to send. Please try again.", nil)
                                                        delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil] autorelease];
		[alert show];
    }
	[self dismissModalViewControllerAnimated:YES];
}

@end
