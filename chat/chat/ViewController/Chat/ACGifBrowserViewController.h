//
//  ACGifBrowserViewController.h
//  chat
//
//  Created by 王方帅 on 14-5-25.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SvGifView.h"
#import "ACMessage.h"

@interface ACGifBrowserViewController : UIViewController<UIWebViewDelegate>
{
    SvGifView           *_gifView;
    UIImageView         *_pngImageView;
    IBOutlet UIView     *_contentView;
    IBOutlet UIButton   *_backButton;
}

@property (nonatomic,strong) ACStickerMessage  *stickerMessage;
@property (nonatomic) BOOL                      isOpenHotspot;

@end
