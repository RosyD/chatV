//
//  ACNoteDetailVC.h
//  chat
//
//  Created by Aculearn on 14/12/24.
//  Copyright (c) 2014年 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACNoteMessage.h"
#import "THChatInput.h"
#import "ACTableViewVC_Base.h"

@class ACNoteListVC_Base;
@class ACNoteCommentCell;


@interface ACNoteDetailVC : ACTableViewVC_Base <THChatInputDelegate,UIAlertViewDelegate>


//@property (weak,nonatomic)  IBOutlet UITableView    *mainTableView;
@property (nonatomic,strong,readonly)   ACNoteMessage      *noteMessage;
@property (nonatomic,strong,readonly)   ACTopicEntity      *topicEntity;
//@property (nonatomic) BOOL                      isOpenHotspot;

+(void)showNote:(ACNoteObject*)noteObj
      withTopic:(ACTopicEntity*)pTopic
   inTimeLineVC:(ACNoteListVC_Base*)timeLineVC;

+(void)showNoteMsg:(ACNoteMessage *)noteMessage
     withIndexPath:(NSIndexPath*)noteIndexPath
      inNoteListVC:(ACNoteListVC_Base *)noteListVC;

+(void)showNoteMsgWithNoteID:(NSString*)pNoteID
                  andTopic:(ACTopicEntity*)pTopic
                andHighlight:(NSArray<NSString*>*)highlights
              inNomalSuperVC:(UIViewController*)pSuperVC;

/*+(BOOL)showWithSearchText:(NSString*)searchText
        andSearchNoteInfo:(NSDictionary*)pSearchResult
              inNomalSuperVC:(UIViewController*)pSuperVC;*/

-(void)noteContentUpdated;


-(void)selectedCommentCell:(ACNoteCommentCell*)commentCell
          forLongPress:(BOOL)forLongPress; //选择
-(void)moreReplies:(ACNoteComment*)comment;



@end
