//
//  ACWallBoardHorizontalCell.h
//  chat
//
//  Created by 王方帅 on 14-6-3.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACNoteMessage.h"


@class ACTableViewVC_Base;
@interface ACNoteListVC_Cell_Media_H_Cell : UITableViewCell //ACNoteListVC_Cell中 用于展示图片和视频的水平TableView的Cell
{
    int                         _index;
    BOOL                        _addedObserver;
    ACNoteContentImageOrVideo   *_page;
    ACNoteMessage               *_noteMessage;
    __weak IBOutlet UIImageView        *_contentImageView;
    __weak IBOutlet UIImageView        *_videoPlayImageView;
    __weak IBOutlet UIProgressView      *_videoDownloadProcess;
    __weak   ACTableViewVC_Base         *_superVC;
}

//@property (nonatomic,strong) ACNoteContentImageOrVideo *page;
//@property (nonatomic,strong) ACWallBoard_Message  *noteMessage;

-(void)setNoteMessage:(ACNoteMessage *)noteMessage index:(int)index  withSuperVC:(ACTableViewVC_Base*)superVC;

@end
