//
//  ACNoteListVC_Base.h
//  chat
//
//  Created by Aculearn on 14/12/18.
//  Copyright (c) 2014年 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACTableViewVC_Base.h"
#import "ACEntity.h"
#import "EGORefreshTableFooterView.h"

#define kLoadMoreLimit  20

typedef enum    _ACNoteListVC_Type{
    ACNoteListVC_Type_Note_List,
    ACNoteListVC_Type_WallBoard_List,
    ACNoteListVC_Type_TimeLine_List,
    ACNoteListVC_Type_SearchResult,
}ACNoteListVC_Type;


@interface ACNoteListVC_Base : ACTableViewVC_Base


@property (nonatomic,strong) ACTopicEntity          *topicEntity;
//@property (nonatomic,strong,readonly) NSString               *topicEntityTitle; //标题
//@property (weak, nonatomic) IBOutlet UIView         *contentView;
//@property (weak,nonatomic)  IBOutlet UITableView    *mainTableView;
@property (nonatomic,strong) NSMutableArray         *notesSourceArray; // ACNoteMessage
@property (nonatomic) ACNoteListVC_Type             nListType;



//-(void)loadNotesMessage;
//-(NSInteger)loadNotesMessageFunc; //加载信息,返回新的加载信息数,被loadNotesMessage调用


-(void)onDeleteNote:(NSIndexPath*)pIndexPath;
-(void)OnUpdateNote:(NSIndexPath*)pIndexPath;
-(void)onNewNoteMessge;
-(void)sendNoteMessageSuccess:(id)message; //发送信息成功


@end

