//
//  ACWallBoardHorizontalCell.m
//  chat
//
//  Created by 王方帅 on 14-6-3.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACNoteListVC_Cell_Media_H_Cell.h"
#import "ACAddress.h"
#import "ACTableViewVC_Base.h"
#import "UIImageView+WebCache.h"
#import "ACNetCenter.h"

@implementation ACNoteListVC_Cell_Media_H_Cell

- (void)dealloc
{
//    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//    [nc removeObserver:self];
    if(_addedObserver){
        [_page removeObserver:self forKeyPath:kProgress];
        _addedObserver = NO;
    }
}


-(void)pageImageTap:(UITapGestureRecognizer *)tap{
    
    if(!_page.bIsImage){
        
        NSString *filePath = _page.resourceFilePath;
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
            
            //处理下载
            if(!_page.video_downloading){
                _page.video_downloading = YES;
                _videoDownloadProcess.hidden = NO;
                _videoPlayImageView.hidden = YES;
                [[ACNetCenter shareNetCenter] downloadNote:_noteMessage VideoContent:_page];
            }
             return;
        }
    }
    
    
    [_superVC imageOrVideoTapWithNoteMessage:_noteMessage forIndex:_index];
}

-(void)setNoteMessage:(ACNoteMessage *)noteMessage index:(int)index   withSuperVC:(ACTableViewVC_Base*)superVC{
    _noteMessage = noteMessage;
    ACNoteContentImageOrVideo *page = _noteMessage.imgs_Videos_List[index];
    _index = index;
    _superVC = superVC;
    if (_page == page){
        return;
    }
    
    if(_addedObserver){
        [_page removeObserver:self forKeyPath:kProgress];
        _addedObserver = NO;
    }
    
    _page = page;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pageImageTap:)];
    [_contentImageView addGestureRecognizer:tap];
    
    
    //加载图片
    {
        UIImage *image = [UIImage imageWithContentsOfFile:_page.thumbFilePath];
        if (image){
            [_contentImageView setImage:image];
        }
        else{
            image = [UIImage imageNamed:@"image_placeHolder.png"];
            if(_noteMessage.categoryIDForWallBoard){
                [_contentImageView setImage:image];
            }
            else{
                [_contentImageView setImageWithURL:[_page getResourceURLForThumb:YES withNoteMessage:_noteMessage] placeholderImage:image imageName:_page.thumbResourceID imageType:ImageType_ImageMessage];
            }
        }
    }
    
    _videoDownloadProcess.hidden  =YES;
    _videoPlayImageView.hidden = YES;
    if(_page.bIsImage){
        return;
    }

    _addedObserver = YES;
    [_page addObserver:self forKeyPath:kProgress options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
    
    //处理视频
    if(_page.video_downloading){
        _videoDownloadProcess.hidden = NO;
    }
    
    _videoPlayImageView.hidden = NO;
    if([[NSFileManager defaultManager] fileExistsAtPath:_page.resourceFilePath]){
        [_videoPlayImageView setImage:[UIImage imageNamed:@"videoPlay.png"]];
    }
    else{
        [_videoPlayImageView setImage:[UIImage imageNamed:@"download.png"]];
    }
    
 /*
  ACFileMessage *msg = (ACFileMessage *)message;
  [_chatContentLabel setHidden:YES];
  [_chatContentImageView setHidden:NO];
  [_isVideoImageView setHidden:NO];
  [_contentLengthLabel setHidden:NO];
  _contentLengthLabel.font = [UIFont systemFontOfSize:16];
  [_contentLengthLabel setTextAlignment:NSTextAlignmentRight];
  
  //视频下载显示进度条
  [msg addObserver:self forKeyPath:kProgress options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
  
  if (msg.isDownloading)
  {
  _contentProgressView.progress = msg.progress;
  [_contentProgressView setHidden:NO];
  [_videoPlayImageView setHidden:YES];
  }
  else
  {
  [_contentProgressView setHidden:YES];
  [_videoPlayImageView setHidden:NO];
  }
  
  NSString *filePathT = [ACAddress getAddressWithFileName:msg.thumbResourceID fileType:ACFile_Type_VideoThumbFile isTemp:NO subDirName:nil];;
  UIImage *image = [UIImage imageWithContentsOfFile:filePathT];
  if (image)
  {
  [_chatContentImageView setImage:image];
  }
  else
  {
  [_chatContentImageView setImageWithEntityID:msg.topicEntityID withTopicID:msg.messageID thumbRid:msg.thumbResourceID placeholderImage:[UIImage imageNamed:@"video_placeHolder.png"]];
  }
  contentView = _chatContentImageView;
  
  NSString *filePath = [ACAddress getAddressWithFileName:((ACFileMessage *)msg).resourceID fileType:ACFile_Type_VideoFile isTemp:NO subDirName:nil];
  if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
  {
  [_videoPlayImageView setImage:kPlayImage];
  
  _contentLengthLabel.text = [NSString stringWithFormat:@"%d%@",msg.duration,NSLocalizedString(@"sec", nil)];
  }
  else
  {
  [_videoPlayImageView setImage:[UIImage imageNamed:@"download.png"]];
  _contentLengthLabel.text = [self getTextWithLength:msg.length];
  }

  
  */
    
/*TXB    if (g__pAcNoteListVC.isScrolling){
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc removeObserver:self];
        [nc addObserver:self selector:@selector(loadImage) name:kScrollFinishedNotification object:nil];
        return;
    }
*/
 
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(_page==object){
        if (_page.video_downloading){
                _videoDownloadProcess.progress = _page.progress;
            NSLog(@"%f",_page.progress);
        }
        if (_page.progress == 1){
            _videoDownloadProcess.hidden = YES;
            _videoPlayImageView.hidden = NO;
            _page.video_downloading = NO;
            [_videoPlayImageView setImage:[UIImage imageNamed:@"videoPlay.png"]];
        }
    }
}


@end
