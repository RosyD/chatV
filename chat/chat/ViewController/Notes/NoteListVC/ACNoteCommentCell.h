//
//  ACNoteCommentCell.h
//  chat
//
//  Created by Aculearn on 14/12/25.
//  Copyright (c) 2014年 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACNoteCommentBase;
@class ACNoteComment;
@class ACNoteDetailVC;

@interface ACNoteCommentCell : UITableViewCell


@property (weak, nonatomic) ACNoteCommentBase *noteCommentBase;
@property (weak, nonatomic) ACNoteComment *noteComment;

//@property (nonatomic)       NSInteger commentBaseIndex; //索引编号
@property (weak, nonatomic) IBOutlet UITableView *repliesTableView; //reply TableView

/*
    if(noteComment == noteCommentBase){
        普通comment
    }
    else{
        ACNoteCommentReply* reply = (ACNoteCommentReply*)noteCommentBase
        noteComment 是reply的父
    }
 */

+(NSInteger)getNoteCommentHight:(ACNoteComment*)noteComment;

+(ACNoteCommentCell*)loadCellFromTable:(UITableView*)tableView withCommentBase:(ACNoteCommentBase*) noteCommentBase andSuperVC:(ACNoteDetailVC*)superVC withIndex:(NSInteger)nIndex;

@end
