//
//  ACChatMessageTableViewCell.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-10.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACMessage.h"
#import <MapKit/MapKit.h>
#import "SvGifView.h"
#import "YLGIFImage.h"
#import "YLImageView.h"
#import "KZLinkLabel.h"
//#import "AttributedLabel.h"


#define kProgress       @"progress"

#define kMsgOpt_Transmit NSLocalizedString(@"Forward", nil)
#define kMsgOpt_Copy NSLocalizedString(@"Copy", nil)
#define kMsgOpt_Download  NSLocalizedString(@"Download", nil)
#define kMsgOpt_SaveToAblum NSLocalizedString(@"Save to album", nil)
#define kMsgOpt_PrivateChat NSLocalizedString(@"Direct chat", nil)
#define kMsgOpt_ShowLocation NSLocalizedString(@"Show Location", nil)
#define kMsgOpt_HadReadList NSLocalizedString(@"Had_Read_List",nil)

@class ACChatMessageViewController;
@interface ACChatMessageTableViewCell : UITableViewCell //<AttributedLabelDelegate>
{
    __weak IBOutlet UIImageView        *_iconImageView;///用户照片
    __weak IBOutlet UILabel            *_nameLabel;///用户姓名
    
    //content
    __weak IBOutlet UIImageView        *_chatContentBgImageView;///聊天内容的背景图片
    __weak IBOutlet KZLinkLabel        *_chatContentLabel;///聊天内容
    __weak IBOutlet UIImageView        *_chatContentImageView;///聊天发送的图片
    __weak IBOutlet UIImageView        *_videoPlayImageView;///发送视频图片
    
    //语音
    __weak IBOutlet UIImageView        *_audioPlayImageView;
    
    //显示视频长度label,视频指示图片
    __weak IBOutlet UIImageView        *_isVideoImageView;
    __weak IBOutlet UILabel            *_contentLengthLabel;
    
    //日期view和contentView
    __weak IBOutlet UIView             *_dateView;
    __weak IBOutlet UIView             *_contentView;
    
    //日期view详情
    __weak IBOutlet UIImageView        *_dateBgImageView;
    __weak IBOutlet UILabel            *_dateLabel;
    
    //time
    __weak IBOutlet UILabel            *_timeLabel;
    
    //指示上传按钮
    __weak IBOutlet UIButton           *_uploadStateButton;
    __weak IBOutlet UIProgressView     *_contentProgressView;
    
    __weak IBOutlet UILabel            *_hadReadLabel;
    __weak IBOutlet UIButton           *_hadReadButton;
    NSArray                     *_links;
    __weak IBOutlet UIActivityIndicatorView    *_activityView;
    
    __weak IBOutlet UIView *_newMsgFlagView;
    __weak IBOutlet UILabel *_newMsgFlagLable;
    __weak IBOutlet UIImageView *_newMsgFlagBkView;
    
    
    __weak IBOutlet UILabel *_systemMsg_Lable;

    UIButton               *_mulSelectButton;
    
}

@property (nonatomic,strong) ACMessage      *messageData;
@property (nonatomic,weak) ACChatMessageViewController   *superVC;
@property (nonatomic,strong) NSTimer                *audioPlayingTimer;
//sticker
//@property (nonatomic,strong) SvGifView              *gifView;
@property (nonatomic,strong) YLImageView            *gifImageView;

-(void)setMessage:(ACMessage *)message superVC:(ACChatMessageViewController *)superVC;
-(void)videoMsgOptionForSave;


+(float)getCellHeightWithMessage:(ACMessage *)message withNewMsgSeq:(long)lNewMsgSequence withNewMsgSeqFor99_Plus:(long)lNewMsgSequenceFor99_Plus;

//-(void)stickerStartGif;
//
//-(void)stickerStopGif;

@end
