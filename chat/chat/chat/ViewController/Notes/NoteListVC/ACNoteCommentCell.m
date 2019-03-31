//
//  ACNoteCommentCell.m
//  chat
//
//  Created by Aculearn on 14/12/25.
//  Copyright (c) 2014年 Aculearn. All rights reserved.
//

#import "ACNoteDetailVC.h"
#import "ACNoteCommentCell.h"
#import "ACNoteMessage.h"
#import "ACNoteListVC_Cell.h"
#import "NSDate+Additions.h"
#import "ACConfigs.h"


//#define UIFont_for_Chat_Lable [ACConfigs shareConfigs].chatTextFont

#ifndef UIFont_for_Chat_Lable
    #define UIFont_for_Chat_Lable [UIFont systemFontOfSize:16]
#endif

@interface ACNoteCommentCell()<UITableViewDataSource,UITableViewDelegate>{
    __weak  ACNoteDetailVC    *_superVC;
}

@property (weak, nonatomic) IBOutlet UIImageView *userIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLable;
@property (weak, nonatomic) IBOutlet UILabel *commontDateLable;
@property (weak, nonatomic) IBOutlet UILabel *commontLable;
@property (weak, nonatomic) IBOutlet UIButton *moreRepliesButton;



@end

///#define kWebInfoWidth   246
#define kWebInfoWidth    (kScreen_Width - 74)
///#define replyInfoWidth  (200-10) //回复显示
#define replyInfoWidth (kWebInfoWidth - 46 - 10)
#define commontLable_X      66
#define commontLable_Y       37
#define moreRepliesButton_Hight 20

#define commont_user_Icon_WH    50
#define reply_user_Icon_WH    40


@implementation ACNoteCommentCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
//    [_userIconImageView.layer setMasksToBounds:YES];
//    [_userIconImageView.layer setCornerRadius:5.0];
    _repliesTableView.delegate = self;
    _repliesTableView.dataSource = self;
    [_moreRepliesButton setTitle:NSLocalizedString(@"Load more",nil) forState:UIControlStateNormal];
//    _repliesTableView.
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)];
    [self.contentView addGestureRecognizer:longPress];
}

+(ACNoteCommentCell*)loadCellFromTable:(UITableView*)tableView withCommentBase:(ACNoteCommentBase*) noteCommentBase andSuperVC:(ACNoteDetailVC*)superVC  withIndex:(NSInteger)nIndex{
    ACNoteCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACNoteComment_Cell"];
    if (!cell){
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACNoteCommentCell" owner:nil options:nil];
        cell = [nib objectAtIndex:0];
        NSAssert([cell.reuseIdentifier isEqualToString:@"ACNoteComment_Cell"],@"ACNoteComment_Cell");
        cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
        cell.selectedBackgroundView.backgroundColor = [UIColor clearColor];
    }
    [cell _setNoteCommentBase:noteCommentBase withSuperVC:superVC];
//    cell.commentBaseIndex = nIndex;
    cell.selectedBackgroundView.frame = cell.bounds;
    return cell;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)onLongPress:(UIGestureRecognizer *)ges{
    if (ges.state == UIGestureRecognizerStateBegan){
        [_superVC selectedCommentCell:self forLongPress:YES];
    }
}

- (IBAction)onMoreReplies:(id)sender {
    NSAssert([_noteCommentBase isKindOfClass:[ACNoteComment class]],@"[_noteCommentBase isKindOfClass:[ACNoteComment class]]");
    [_superVC moreReplies:(ACNoteComment*)_noteCommentBase];
}


-(void)_setNoteCommentBase:(ACNoteCommentBase*) noteCommentBase withSuperVC:(ACNoteDetailVC*)superVC{
    _superVC = superVC;
    _noteCommentBase =  noteCommentBase;
    BOOL isNoteComment = [noteCommentBase isKindOfClass:[ACNoteComment class]];

    CGRect tempFrame;
    tempFrame   =   _userIconImageView.frame;
    if(isNoteComment){
        tempFrame.size.width = tempFrame.size.height = commont_user_Icon_WH;
        tempFrame.origin.x = 8;
    }
    else{
        tempFrame.origin.x = 8+(commont_user_Icon_WH-reply_user_Icon_WH);
        tempFrame.size.width = tempFrame.size.height = reply_user_Icon_WH;
    }
    _userIconImageView.frame =  tempFrame;
    [_userIconImageView setToCircle];
    
    //Icon
    [ACNoteListVC_Cell setUserIcon:noteCommentBase.creator forImageView:_userIconImageView];
    
    //UserName
    _userNameLable.text  =  noteCommentBase.creator.name;
    [_userNameLable setAutoresizeWithLimitWidth:120 andLimitHight:22];
    
    //根据UserName 设置时间日期的显示位置
    {
        CGRect frame =  _commontDateLable.frame;
        int nNewX   =   _userNameLable.frame.origin.x+_userNameLable.frame.size.width+10;
        _commontDateLable.frame = CGRectMake(nNewX, frame.origin.y, frame.origin.x+frame.size.width-nNewX, frame.size.height);
    }
    
#if 0
    //判断是否今天
    {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:noteCommentBase.createTime/1000];
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *comp = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit|NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:date];
        
        if([[[date description] substringToIndex:10] isEqualToString:[[[[NSDate alloc] init] description] substringToIndex:10]]){
            //今天
             _commontDateLable.text = [NSString stringWithFormat:@"%02d:%02d",(int)comp.hour,(int)comp.minute];
        }
        else{
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            NSLocale *curLocale = [NSLocale currentLocale];
            [dateFormatter setLocale:curLocale];// 设置为当前区域
            [dateFormatter setDateFormat:@"EEEE"];
            
//            NSString* pDateStr = [NSString stringWithFormat:@"%4d-%02d-%02d %@ %02d:%02d",(int)comp.year,(int)comp.month,(int)comp.day,[dateFormatter stringFromDate:date],(int)comp.hour,(int)comp.minute];

            _commontDateLable.text = [NSString stringWithFormat:@"%4d-%02d-%02d %@ %02d:%02d",(int)comp.year,(int)comp.month,(int)comp.day,[dateFormatter stringFromDate:date],(int)comp.hour,(int)comp.minute];
            
            

        }
    }
#else
    _commontDateLable.text = [NSDate dateAndTimeStringForRecentDate:[NSDate dateWithTimeIntervalSince1970:noteCommentBase.updateTime/1000]];
#endif
    
    _commontLable.font  =   UIFont_for_Chat_Lable;
    _commontLable.text = noteCommentBase.content;
    
    [_commontLable setAutoresizeWithLimitWidth:isNoteComment?kWebInfoWidth:replyInfoWidth];
    
    _repliesTableView.hidden = YES;
    _moreRepliesButton.hidden = YES;
    
    if(!isNoteComment){
        return;
    }
    
    //处理 ACNoteComment
    _noteComment = (ACNoteComment*)noteCommentBase;
    if(0==_noteComment.loadedCommentReplys.count&&
       _noteComment.commentReplyAllCount<=0){
        return;
    }

    CGFloat fY = CGRectGetMaxY(_commontLable.frame)+8;
    if(_noteComment.commentReplyAllCount>_noteComment.loadedCommentReplys.count){
        //显示 More Replies
        _moreRepliesButton.hidden = NO;
        [_moreRepliesButton setFrame_y:fY];
        fY = CGRectGetMaxY(_moreRepliesButton.frame)+8;
    }
    
    if(_noteComment.loadedCommentReplys.count){
    _repliesTableView.hidden = NO;
//    _repliesTableView.backgroundColor = [UIColor greenColor];
        ///
        [_repliesTableView setFrame_width:kWebInfoWidth];
        
        tempFrame = _repliesTableView.frame;
        tempFrame.origin.y =   fY;
        tempFrame.size.height = _noteComment.loadedReplysTableViewHight;
        _repliesTableView.frame = tempFrame;
        [_repliesTableView reloadData];
    }
}

+(void)_getNoteCommentHightFunc:(ACNoteCommentBase*)noteCommentBase width:(NSInteger)nInfoWidth{
    
    
    noteCommentBase.hightInList = commontLable_Y+[noteCommentBase.content getHeightAutoresizeWithLimitWidth:nInfoWidth
                                                                                                       font:UIFont_for_Chat_Lable]+8;
//    return noteCommentBase.hightInList;
}

+(NSInteger)_getNoteCommentReplyHight:(ACNoteCommentReply*)reply{
    if(reply.hightInList<=0){
        [self _getNoteCommentHightFunc:reply width:replyInfoWidth];
    }
    return reply.hightInList;
}

+(NSInteger)getNoteCommentHight:(ACNoteComment*)noteComment{
    
    if(noteComment.hightInList<=0){
        [self _getNoteCommentHightFunc:noteComment width:kWebInfoWidth];
        
        if(noteComment.loadedCommentReplys.count||noteComment.commentReplyAllCount>0){
            //处理回复
            if(noteComment.commentReplyAllCount>noteComment.loadedCommentReplys.count){
                //显示 More Replies
                noteComment.hightInList += 8+moreRepliesButton_Hight;
            }
            //回复
            noteComment.loadedReplysTableViewHight = 0;
            for(ACNoteCommentReply* reply in noteComment.loadedCommentReplys){
                noteComment.loadedReplysTableViewHight +=  [self _getNoteCommentReplyHight:reply];
            }
            noteComment.hightInList += noteComment.loadedReplysTableViewHight;
        }
    }
    
    return noteComment.hightInList;
}

//-(void)removeReplyWithIndex:(NSInteger)nReplyIndex{ //移除Reply
//    [_repliesTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:nReplyIndex inSection:0]]
//                             withRowAnimation:UITableViewRowAnimationAutomatic];
//}


#pragma mark UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _noteComment==_noteCommentBase?_noteComment.loadedCommentReplys.count:0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ACNoteCommentCell* cell = [ACNoteCommentCell loadCellFromTable:tableView
                                 withCommentBase:_noteComment.loadedCommentReplys[indexPath.row]
                                      andSuperVC:_superVC
                                       withIndex:indexPath.row];
    cell.noteComment = _noteComment;
    return cell;
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [ACNoteCommentCell _getNoteCommentReplyHight:_noteComment.loadedCommentReplys[indexPath.row]];
}

#pragma mark UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSAssert([_noteCommentBase isKindOfClass:[ACNoteComment class]],@"[_noteCommentBase isKindOfClass:[ACNoteComment class]]");
    [_superVC selectedCommentCell:[tableView cellForRowAtIndexPath:indexPath] forLongPress:NO];
}

@end
