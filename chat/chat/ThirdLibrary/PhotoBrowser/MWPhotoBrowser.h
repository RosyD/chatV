//
//  MWPhotoBrowser.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "MWPhoto.h"
#import "MWPhotoProtocol.h"
#import "MWCaptionView.h"
#import "UIView+Additions.h"

// Debug Logging
#if 1 // Set to 1 to enable debug logging
#define MWLog(x, ...) //NSLog(x, ## __VA_ARGS__);
#else
#define MWLog(x, ...)
#endif

enum BrowserType {
    BrowserType_DefineBrowser = 0,
    BrowserType_SendImageBrowser = 1,
    };

/*
 1.通过显示方向，预加载网络上的数据信息,并不马上加载。
 
 */

#define MWPhotoBrowser_NET_Images_func_load_forward  1       //预加载后面的
#define MWPhotoBrowser_NET_Images_func_load_back     -1      //预加载前面的

#define MWPhotoBrowser_NET_Images_load_state_Load_End_Head  0x01    //前面加载完毕
#define MWPhotoBrowser_NET_Images_load_state_Load_End_Tail  0x02    //后面加载完毕
#define MWPhotoBrowser_NET_Images_load_state_Load_End_All   0x03    //全部加载完毕了,如果没有网络时，状态也是这个
#define MWPhotoBrowser_NET_Images_load_state_allow          0x04    //允许网络图片功能

// Delgate
@class MWPhotoBrowser;
@class MWZoomingScrollView;
@protocol MWPhotoBrowserDelegate <NSObject>
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser;
- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser sendAtIndex:(NSUInteger)index;  ///<发送图片
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser NetPreLoad:(int)loadDir; ///<调用网络预加载
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser NetLoadAtCurIndex:(int*) pcurrentPageIndex; ///<加载预加载的数据,返回新的当前IndexNo
//pcurrentPageIndex = NULL表示只是检测，不加载数据
@optional
- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index;

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser getBigPhotoAtIndex:(NSUInteger)index withRefreshUI:(BOOL)refreshUI;
@end


@protocol MWPhotoBrowserShowPhotoExitDelegate <NSObject>
-(void)onPhotoBrowserShowPhotoExit:(MWPhotoBrowser*) pphotoBrower;
@end


// MWPhotoBrowser
@class ELCAssetTablePicker;
@interface MWPhotoBrowser : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>
{
        ELCAssetTablePicker *_assetPicker;
    BOOL _elcAssetSelected;
    UIButton *_sendNumButton;
//    NSInteger _previousIndex;
}

// Properties
@property (nonatomic) BOOL displayActionButton;
@property (nonatomic) int  NET_Images_load_state; //MWPhotoBrowser_NET_Images_load_state_*
@property (nonatomic,retain) NSMutableArray *photos;
@property (nonatomic) enum BrowserType browserType;
@property (nonatomic,retain) id<MWPhotoBrowserShowPhotoExitDelegate> delegateForShowPhoto;


// Init
//- (id)initWithPhotos:(NSArray *)photosArray; //<MWPhoto>
- (id)initWithPhotoFile:(NSString*)pFilePathName withURL:(NSString*)pURL;
//__attribute__((deprecated)); // Depreciated<MWPhoto>
- (id)initWithDelegate:(id <MWPhotoBrowserDelegate>)delegate browserType:(enum BrowserType)browserType;

// Reloads the photo browser and refetches data
- (void)reloadData;

- (void)tileCurrentPage;

-(UIProgressView *)processbarForPhoto:(id<MWPhoto>)photo;

// Set page that photo browser starts on
- (void)setInitialPageIndex:(NSUInteger)index;

- (MWZoomingScrollView *)pageDisplayingPhoto:(id<MWPhoto>)photo;

- (id<MWPhoto>)photoAtIndex:(NSUInteger)index;

-(void)refreshDataWithIndex:(NSInteger)index imagePath:(NSString *)imagePath;

-(void)refreshDataWithIndex:(NSInteger)index image:(UIImage *)image;

- (void)performLayout;

@end


