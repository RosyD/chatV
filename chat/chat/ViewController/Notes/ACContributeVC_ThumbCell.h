//
//  ACDetailPageCell.h
//  chat
//
//  Created by 王方帅 on 14-6-5.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACNoteMessage.h"

@class ACContributeViewController;
@interface ACContributeVC_ThumbCell : UITableViewCell //显示图片,视频的thumb
{
    __weak IBOutlet UIImageView        *_detailImageView;
    __weak ACContributeViewController  *_superVC;
    __weak IBOutlet UIImageView        *_playImageView;
    __weak ACNoteContentImageOrVideo   *_filePage;
}


-(void)setFilePage:(ACNoteContentImageOrVideo *)filePage superVC:(ACContributeViewController *)superVC;

@end
