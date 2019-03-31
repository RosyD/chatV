//
//  ACContributeViewController.h
//  chat
//
//  Created by 王方帅 on 14-6-3.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GCPlaceholderTextView.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "ACNoteMessage.h"
#import "ACEntity.h"
#import "ELCImagePickerHeader.h"
#import "NIDropDown.h"

enum ACButtonType
{
    ACButtonType_none,
    ACButtonType_photo,
    ACButtonType_video,
    ACButtonType_webLink,
};

#define kHasPhoto   @"hasPhoto"
#define kHasVideo   @"hasVideo"
#define kHasLocation   @"hasLocation"

@class ACNoteListVC_Base;
@interface ACContributeViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate,NIDropDownDelegate,UIActionSheetDelegate,UIAlertViewDelegate>
{
    __weak IBOutlet GCPlaceholderTextView      *_textView;
    
    __weak IBOutlet UILabel             *_wallBoardLable; //标题
    __weak IBOutlet UIView                     *_buttonBarView;
    __weak IBOutlet UIImageView                *_buttonBarBgImageView;
    
    __weak IBOutlet UIView                     *_detailView;
    __weak IBOutlet UIImageView                *_detailBgImageView;
    
    __weak IBOutlet UIButton                   *_cameraButton;
    __weak IBOutlet UIButton                   *_photoButton;
    
    __weak IBOutlet UIImageView                *_directImageView;
    __weak IBOutlet UIButton                   *_photoBarButton;
    __weak IBOutlet UIButton                   *_videoBarButton;
    __weak IBOutlet UIButton                   *_locationBarButton;
    

    __weak IBOutlet UIImageView                *_detailHolderImageView;
    
    __weak IBOutlet UITableView                *_detailTableView;
    
    int                                 _movieToMp4FinishedCount;
    
    BOOL                                _isAppear;
    float                               _currentHeight;
    
    //上传进度展示
    __weak IBOutlet UIView                     *_uploadView;
    __weak IBOutlet UIProgressView             *_uploadProgressView;
    __weak IBOutlet UILabel                    *_uploadProgressLabel;
    __weak IBOutlet UILabel                    *_uploadLabel;
    
    __weak IBOutlet UIView                     *_contentView;
    int                                 _movieCount;
    
    __weak IBOutlet UIView                     *_categoryView;
    __weak IBOutlet UIView                     *_promptView;
    
    __weak IBOutlet UILabel *_categoryTitle;
    __weak IBOutlet UIButton                   *_cancelUploadButton;
    __weak IBOutlet UIButton                   *_enterButton;
    __weak IBOutlet UIButton                   *_cancelButton;
    
    int                                 _compresseFailCount;
    __weak IBOutlet UIButton                   *_dropDownButton;
    BOOL                                _isCancelSend;
    
    
    __weak IBOutlet UIButton *_postButton;
    
    __weak IBOutlet UIButton            *_webLinkBarButton;
    __weak IBOutlet UIButton            *_webLinkButton;
    __weak IBOutlet UIButton            *_webLinkDelButton;
    __weak IBOutlet UIView              *_webInfoBk;
    __weak IBOutlet UIImageView         *_webInfoIcon;
    __weak IBOutlet UILabel             *_webInfoTitle;
    __weak IBOutlet UILabel             *_webInfoURL;
    __weak IBOutlet UILabel *_webInfoDesc;
}

@property (nonatomic) enum ACButtonType     buttonType;
//@property (nonatomic,strong) ACWallBoard_Message  *noteMessage;
//@property (nonatomic,strong) ACTopicEntity      *topicEntity;
//@property (nonatomic,strong) NSMutableArray     *detailDataSourceArray;

//@property (nonatomic) CLLocationCoordinate2D    coordinate;
//@property (nonatomic,strong) NSString           *locationAddress;
@property (nonatomic,strong) NSMutableDictionary    *barDic;
@property (nonatomic,strong) NIDropDown         *dropDown;
//@property (nonatomic,strong) ACCategory         *category;
@property (nonatomic) BOOL                      isOpenHotspot;
@property (nonatomic,weak) ACNoteListVC_Base* superVC;

-(instancetype)initForWallBoard:(BOOL)bForWallBoard withSuperVC:(ACNoteListVC_Base*)superVC;

-(void)reloadBarButtonImage;

-(void)removeContent:(ACNoteContentImageOrVideo*)pFile;

-(void)setLocaltion:(ACNoteContentLocation*)localInfo;

//-(void)setLocationCoordinate:(CLLocationCoordinate2D) coordinate withAddress:(NSString*)locationAddress;



@end
