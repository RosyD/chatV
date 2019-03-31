//
//  ACWallBoardTableViewCell.h
//  chat
//
//  Created by 王方帅 on 14-6-1.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACNoteListVC_Base.h"

@class ACNoteObject;
@class ACNoteMessage;
@class ACNoteListVC_Base;
@class ACNoteComment;
@class ACUser;
@class ACTopicEntity;
@interface ACNoteListVC_Cell : UITableViewCell<UITableViewDelegate,UITableViewDataSource> //Note 内容的列表
{
    __weak IBOutlet UILabel        *_categoryLabel;
    __weak IBOutlet UILabel *_wallBoardDate;
    
    __weak IBOutlet UIView *_userInfoView;
    __weak IBOutlet UIImageView *_userIcon;
    __weak IBOutlet UILabel     *_userNameLable;
    __weak IBOutlet UILabel     *_timeLabel;
    __weak IBOutlet UIButton *_buttonForTimeLineNote;
    
    __weak IBOutlet UIView *_imagesView;
    __weak IBOutlet UITableView    *_horizontalTableView; //包含 ACNoteListVC_Cell_Media_H_Cell
    __weak IBOutlet UILabel        *_amountLabel;
    __weak IBOutlet UIImageView    *_amountImageView;
    
    
    __weak IBOutlet UILabel        *_textLabel;
    
    
    __weak IBOutlet UIView         *_locationView;
    __weak IBOutlet UILabel        *_locationLabel;
    __weak IBOutlet UIImageView    *_locationImageView;
    
    
    __weak IBOutlet UIView *_webLinkView;
    __weak IBOutlet UILabel *_webLinkTitle;
    __weak IBOutlet UILabel *_webLinkURL;
    __weak IBOutlet UILabel *_webLinkInfo;
    __weak IBOutlet UIImageView *_webLinkIcon;
    __weak IBOutlet UIButton *_webLinkButton;
    
    
    __weak IBOutlet UIView *_commentView;
    __weak IBOutlet UILabel *_commentCountLable;
    __weak IBOutlet UIImageView *_commentIcon;
    
    
    __weak IBOutlet UIView         *_lineView;
    
    ACNoteMessage          *_noteMessage;
    ACNoteObject           *_noteObject;
    __weak UIViewController       *_superVC;
}

//这个在TimeLine中使用
-(void)setNoteComment:(ACNoteComment*)noteComment;
+(float)getCellHeightWithNoteComment:(ACNoteComment*)noteComment;


-(void)setNoteMessage:(ACNoteMessage *)noteMessage
            forDetail:(BOOL)bForDetail
      forTimeLineList:(BOOL)bTimeLineList
            withTopic:(ACTopicEntity*)pToic;
+(float)getCellHeightWithNoteMessage:(ACNoteMessage *)noteMessage forDetail:(BOOL)bForDetail;

-(void)setHighlight:(NSArray<NSString*>*)highlights;

+(void) setUserIcon:(ACUser*)pUser forImageView:(UIImageView*)pIconView;


//计算WebLinkInfoView的高度
+(float)getWebLinkInfoViewHight:(UILabel*)pTitleLable lableURL:(UILabel*)pURLLable descLable:(UILabel*)pDescLable iconView:(UIImageView*)pIconView andMaxW:(float)fMaxWith;

+(ACNoteListVC_Cell*)loadCellFromTable:(UITableView*)table  withSuperVC:(UIViewController*)superVC;


@end
