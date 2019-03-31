//
//  ACWallBoardViewController.h
//  chat
//
//  Created by 王方帅 on 14-6-1.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACNoteListVC_Base.h"

//extern NSString *const kScrollFinishedNotification;

@interface ACWallBoardViewController : ACNoteListVC_Base
{
    IBOutlet UIButton       *_contributeButton;
//    MPMoviePlayerViewController     *_moviePlayerVC;
//    EGORefreshTableFooterView       *_refreshView;
//    IBOutlet UIView                 *_contentView;
//    BOOL                            _reloading;
//    BOOL                            _isHadLoadMore;
    IBOutlet UIView                 *_contributeView;
}

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UITableView *mainTableView;

//@property (nonatomic,strong) NSMutableArray     *dataSourceArray;
//@property (nonatomic,strong) ACTopicEntity      *topicEntity;
//@property (nonatomic,strong) NSArray     *photoArray;
//@property (nonatomic,strong) MWPhotoBrowser     *browser;
//@property (nonatomic) BOOL                      isScrolling;



@end
