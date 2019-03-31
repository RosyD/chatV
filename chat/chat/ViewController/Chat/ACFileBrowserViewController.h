//
//  ACFileBrowserViewController.h
//  chat
//
//  Created by 王方帅 on 14-5-27.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACMessage.h"
#import <QuickLook/QuickLook.h>

@interface ACFileBrowserViewController : UIViewController
<QLPreviewControllerDataSource,
QLPreviewControllerDelegate,
UIDocumentInteractionControllerDelegate>
{
    IBOutlet UILabel        *_nameLabel;
    IBOutlet UIView         *_contentView;
    IBOutlet UIView         *_cannotOpenShowView;
    UIBarButtonItem         *_actionButton;
    IBOutlet UIView         *_navigationView;
}

@property (nonatomic,strong) ACFileMessage *fileMsg;
@property (nonatomic) BOOL                      isOpenHotspot;
@property (nonatomic) UIViewController      *previewController;
@property (nonatomic,strong) UIDocumentInteractionController *docController;

@end
