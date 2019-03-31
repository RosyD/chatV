//
//  ACWallBoardTableViewCell.m
//  chat
//
//  Created by 王方帅 on 14-6-1.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACNoteListVC_Cell.h"
#import "ACMapBrowerViewController.h"
#import "UIView+Additions.h"
#import "ACNoteListVC_Cell_Media_H_Cell.h"

#import "NSString+Additions.h"
#import "ACDataCenter.h"
#import "UINavigationController+Additions.h"
#import "ACNoteListVC_Base.h"
#import "ACNetCenter.h"
#import "UIImageView+WebCache.h"
#import "ACAcuLearnWebViewController.h"
#import "ACUserDB.h"
#import "ACNotesMsgVC_Main.h"
#import "NSDate+Additions.h"
#import "UIView+Additions.h"

#define kCategoryWidth  305
#define kWebInfoWidth   246
#define kIconWith       50

//#define UIFont_for_Chat_Lable [ACConfigs shareConfigs].chatTextFont

#ifndef UIFont_for_Chat_Lable
    #define UIFont_for_Chat_Lable [UIFont systemFontOfSize:16]
#endif

@implementation ACNoteListVC_Cell

+(ACNoteListVC_Cell*)loadCellFromTable:(UITableView*)tableView   withSuperVC:(UIViewController*)superVC{
    ACNoteListVC_Cell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACWallBoardTableViewCell"];
    if (!cell){
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACNoteListVC_Cell" owner:nil options:nil];
        cell = [nib objectAtIndex:0];
        NSAssert([cell.reuseIdentifier isEqualToString:@"ACWallBoardTableViewCell"],@"ACWallBoardTableViewCell");
    }
    NSAssert(superVC,@"superVC");
    cell->_superVC  =   superVC;
    return cell;
}

- (void)awakeFromNib{
    [super awakeFromNib];
    // Initialization code

//    [self.contentView.layer setMasksToBounds:YES];
//    [self.contentView.layer setCornerRadius:10.0];
    
//    self.view
//    [_userIcon.layer setMasksToBounds:YES];
//    [_userIcon.layer setCornerRadius:5.0];
    [_userIcon setToCircle];
    
//    [_webLinkIcon.layer setMasksToBounds:YES];
//    [_webLinkIcon.layer setCornerRadius:5.0];
    [_webLinkIcon setRectRound:5.0];
    
    
    _horizontalTableView.transform = CGAffineTransformMakeRotation(M_PI/-2);
    _horizontalTableView.showsVerticalScrollIndicator = NO;
    [_horizontalTableView.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
    [_horizontalTableView setFrame:CGRectMake(0, 0, kScreen_Width-2, 106)];
//    ///
    [_categoryLabel setFrame_width:kScreen_Width];
    [_userInfoView setFrame_width:kScreen_Width];
    [_imagesView setFrame_width:kScreen_Width];
    ///[_textLabel setFrame_width:kScreen_Width];
    [_locationView setFrame_width:kScreen_Width];
    [_webLinkView setFrame_width:kScreen_Width];
    [_commentView setFrame_width:kScreen_Width];
    [_wallBoardDate setFrame_width:kScreen_Width];
    [_lineView setFrame_width:kScreen_Width];
    
    [_amountLabel setFrame_width:kScreen_Width - 40];
    [_locationLabel setFrame_width:kScreen_Width - 40];
    [_webLinkTitle setFrame_width:kScreen_Width - 50-24];
    [_webLinkURL setFrame_width:kScreen_Width - 50- 24];
    [_webLinkInfo setFrame_width:kScreen_Width - 50 - 24];
    
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(float)setCategoryIDForWallBoardShowY:(float)nShowY withTopic:(ACTopicEntity*)pToic{
    _categoryLabel.hidden = YES;
    if(_noteMessage.categoryIDForWallBoard){
        NSArray *categoryArray = pToic.categoriesArray;
        for (ACCategory *category in categoryArray){
            if ([category.cid isEqualToString:_noteMessage.categoryIDForWallBoard]){
                _categoryLabel.text = [NSString stringWithFormat:@"%@ : %@",NSLocalizedString(@"Category", nil),category.name];
                
                [_categoryLabel setAutoresizeWithLimitWidth:(kCategoryWidth *kScreen_Width / 320)];
                
                _categoryLabel.hidden   =   NO;
                [_categoryLabel setFrame_y:nShowY];
                nShowY  +=   _categoryLabel.frame.size.height+8;
                break;
            }
        }
    }
    return nShowY;
}

-(NSString*)getMessageDate{
     
    return [NSDate dateAndTimeStringForRecentDate:[NSDate dateWithTimeIntervalSince1970:_noteObject.createTime/1000]];

    /*
    NSString *dateString = [[ACDataCenter shareDataCenter] getDateStringWithTimeInterval:_noteObject.createTime/1000];
    NSString *timeString = [[ACDataCenter shareDataCenter] getTimeStringWithTimeInterval:_noteObject.createTime/1000];
    return [dateString stringByAppendingFormat:@" %@",timeString];*/
}

+(void) setUserIcon:(ACUser*)pUser forImageView:(UIImageView*)pIconView{
    UIImage* pDefImage = [UIImage imageNamed:@"personIcon100.png"];
    if(pUser.userid.length){
        [pIconView setImageWithIconString:pUser.icon placeholderImage:pDefImage ImageType:ImageType_UserIcon100];
        return;
    }
    
    pIconView.image =   pDefImage;
}

-(float)setUserInfoShowY:(float)nShowY{
    //ICON
    [ACNoteListVC_Cell setUserIcon:_noteObject.creator forImageView:_userIcon];
    
    //名称
    _userNameLable.text = _noteObject.creator.name;
//    _userNameLable.text =  [NSString stringWithFormat:@"%@[%ld]",_noteMessage.creator.name,nShowY];
 
    //日期
    _timeLabel.text = [self getMessageDate];
    
    [_userInfoView setFrame_y:nShowY];

    
    nShowY  +=   _userInfoView.frame.size.height+8;
    
    _buttonForTimeLineNote.hidden = YES;
    ///
    [_buttonForTimeLineNote mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.offset(-10);
    }];
    [_buttonForTimeLineNote mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(10);
    }];
    [_buttonForTimeLineNote mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.offset(kScreen_Width-210);
    }];
    ///[_buttonForTimeLineNote setFrame_width:(kScreen_Width-210)];
    
    return nShowY;
}


-(float)setimgs_Videos_ListShowY:(float)nShowY{
    if (_noteMessage.imgs_Videos_List.count){
        [_horizontalTableView reloadData];
        _amountLabel.text = [NSString stringWithFormat:@"%@ %d",NSLocalizedString(@"Total", nil),(int)[_noteMessage.imgs_Videos_List count]];
        
        _imagesView.hidden = NO;
        [_imagesView setFrame_y:nShowY];
        nShowY  +=   _imagesView.frame.size.height+8;
    }
    else{
        _imagesView.hidden = YES;
    }
    return nShowY;
}

-(float)setMessageContentShowY:(float)nShowY{
    _textLabel.text =   _noteObject.content;
    _textLabel.font =   UIFont_for_Chat_Lable;
   
    ///
   [_textLabel setAutoresizeWithLimitWidth:kScreen_Width-16];
    
    [_textLabel setFrame_y:nShowY];
    nShowY  +=   _textLabel.frame.size.height+8;

    return nShowY;
}

-(float)setLocalShowY:(float)nShowY{
    if (_noteMessage.location){
        if(_noteMessage.location.address.length){
            NSString* pTitle = @"";
            if(_noteMessage.location.name.length){
                pTitle =    [_noteMessage.location.name stringByAppendingString:@" "];
            }
            _locationLabel.text = [pTitle stringByAppendingString:_noteMessage.location.address];
        }
        else{
            _locationLabel.text = [NSString stringWithFormat:@"%f,%f",_noteMessage.location.Location.longitude,_noteMessage.location.Location.latitude];
        }
        //        [_locationLabel setAutoresizeWithLimitWidth:260];
        //        [_locationImageView setCenter_y:_locationLabel.center.y];
        //        [_locationView setFrame_height:[_locationLabel getFrame_Bottom]];
        
        _locationView.hidden =  NO;
        [_locationView setFrame_y:nShowY];
        nShowY  +=   _locationView.frame.size.height+8;
    }
    else{
        _locationView.hidden = YES;
    }

    return nShowY;
}

#define WebLink_SetLimitHight 40 //设置高度限制

#define WebLink_Item_Delta_H   3    //子项间的间隔

+(float)getWebLinkInfoViewHight:(UILabel*)pTitleLable lableURL:(UILabel*)pURLLable descLable:(UILabel*)pDescLable iconView:(UIImageView*)pIconView andMaxW:(float)fMaxWith{
    
//    [pIconView setFrame_height:50];
    
    //计算标题高度
    [pTitleLable setAutoresizeWithLimitWidth:fMaxWith andLimitHight:WebLink_SetLimitHight];
    float nWebLinkY = [pTitleLable getFrame_Bottom]+WebLink_Item_Delta_H;
    
    //URL
    [pURLLable setFrame_y:nWebLinkY];
    nWebLinkY   =   [pURLLable getFrame_Bottom]+WebLink_Item_Delta_H;
    
    //限制两行
    [pDescLable setFrame_y:nWebLinkY];
    [pDescLable setAutoresizeWithLimitWidth:fMaxWith andLimitHight:WebLink_SetLimitHight];
    
    float fRetHight =   [pDescLable getFrame_Bottom]+8;
    
    //Icon垂直居中
    [pIconView setFrame_y:(fRetHight-pIconView.frame.size.height)/2];
    
    return fRetHight;
}

-(float)setWebLinkShowY:(float)nShowY{
    if(_noteMessage.link){
        //计算大小
        _webLinkTitle.text  =   _noteMessage.link.linkTitle;
        _webLinkURL.text    =   _noteMessage.link.linkURL;
        _webLinkInfo.text   =   _noteMessage.link.linkDesc;
        
        //ICON
        [_webLinkIcon setImageWithURL:[NSURL URLWithString:_noteMessage.link.linkIcon] placeholderImage:[UIImage imageNamed:@"image_placeHolder.png"] imageName:@"" imageType:ImageType_ImageMessage];
        
        float fWebInfoHight = [ACNoteListVC_Cell getWebLinkInfoViewHight:_webLinkTitle lableURL:_webLinkURL descLable:_webLinkInfo iconView:_webLinkIcon andMaxW:kWebInfoWidth];
        
        //设置高度
        [_webLinkView setFrame_height:fWebInfoHight];
        [_webLinkButton setFrame_height:fWebInfoHight];
        [_webLinkButton setFrame_width:kScreen_Width];
        
        
        _webLinkView.hidden = NO;
        [_webLinkView setFrame_y:nShowY];
        
        nShowY  +=   fWebInfoHight;
        /*
#if WebLink_SetLimitHight
        
        //计算标题高度
         [_webLinkTitle setAutoresizeWithLimitWidth:kWebInfoWidth andLimitHight:WebLink_SetLimitHight];
        float nWebLinkY = [_webLinkTitle getFrame_Bottom]+8;
        
        //URL
        [_webLinkURL setFrame_y:nWebLinkY];
        nWebLinkY   =   [_webLinkURL getFrame_Bottom]+8;
        
        //限制两行
        [_webLinkInfo setFrame_y:nWebLinkY];
        [_webLinkInfo setAutoresizeWithLimitWidth:kWebInfoWidth andLimitHight:WebLink_SetLimitHight];
#else
    #error 需要计算高度
        [_webLinkInfo setAutoresizeWithLimitWidth:kWebInfoWidth];
#endif
        
        {
            float nHight = [_webLinkInfo getFrame_Bottom]+8;
     
            [_webLinkView setFrame_height:nHight];
            [_webLinkButton setFrame_height:nHight];
        }
        
        _webLinkView.hidden = NO;
        [_webLinkView setFrame_y:nShowY];
        
        //Icon垂直居中
        [_webLinkIcon setFrame_y:(_webLinkView.frame.size.height-_webLinkIcon.frame.size.height)/2];
        
        nShowY  +=   _webLinkView.frame.size.height;*/
    }
    else{
        _webLinkView.hidden = YES;
    }
    return nShowY;
}


/*
+(NSString*) getTopicEntityShowTitle:(ACTopicEntity*)topicEntity{
    if ([topicEntity.mpType isEqualToString:cWallboard]){
        return topicEntity.title;
    }
    
    //单聊显示用户icon和name，组聊显示组icon和组名
    if ([topicEntity.mpType isEqualToString:cSingleChat]){
        ACUser *user = [ACUserDB getUserFromDBWithUserID:topicEntity.singleChatUserID];
        return user.name;
    }
    
    //$$
    if(topicEntity.relateTeID != nil && topicEntity.relateTeID.length > 0) // 特殊会话
    {
        ACUser *user = [ACUserDB getUserFromDBWithUserID:topicEntity.relateChatUserID];
        return user.name;
    }
    return topicEntity.title;
}*/



#define kwallBoardDate_H    17+8
// BOOL g__bShowGray = NO;

-(void)setNoteMessage:(ACNoteMessage *)noteMessage
            forDetail:(BOOL)bForDetail
      forTimeLineList:(BOOL)bTimeLineList
            withTopic:(ACTopicEntity*)pToic{
    
//    self.contentView.backgroundColor = g__bShowGray?[UIColor lightGrayColor]:[UIColor greenColor];
//    g__bShowGray  =!g__bShowGray;
    
    _noteObject = _noteMessage = noteMessage;
    
    float nShowY = 8;
    
    if(noteMessage.categoryIDForWallBoard){
        
        _wallBoardDate.hidden = NO;
        
        _userInfoView.hidden = YES;
        _commentView.hidden = YES;
        _webLinkView.hidden = YES;
        
        //日期
        _wallBoardDate.text = [self getMessageDate];
        [_wallBoardDate setFrame_y:nShowY];
        nShowY +=  kwallBoardDate_H;

        //文本
        nShowY  =   [self setMessageContentShowY:nShowY];

        //Local
        nShowY  =   [self setLocalShowY:nShowY];
        
        //图片列表
        nShowY  =   [self setimgs_Videos_ListShowY:nShowY];
        
        //CategoryID
        nShowY  =   [self setCategoryIDForWallBoardShowY:nShowY withTopic:pToic];
        [_lineView  setFrame_y:nShowY];
        ///
        [_lineView setFrame_width:kScreen_Width];
        return;
    }
    
    _wallBoardDate.hidden = YES;
    _categoryLabel.hidden = YES;
//    _lineView.hidden = YES;
    
    _userInfoView.hidden = NO;
    _commentView.hidden = NO;

    //User 信息
    nShowY  =   [self setUserInfoShowY:nShowY];
    if((!bForDetail)&&bTimeLineList){
        NSString* pTitle = _noteMessage.topicEntity.showTitle;
        if(pTitle.length){
            _buttonForTimeLineNote.hidden = NO;
            [_buttonForTimeLineNote setTitle:pTitle forState:UIControlStateNormal];
            CALayer * downButtonLayer = [_buttonForTimeLineNote layer];
            [downButtonLayer setMasksToBounds:YES];
            [downButtonLayer setCornerRadius:6.0];
            [downButtonLayer setBorderWidth:1.0];
//            [downButtonLayer setBorderColor:[[UIColor colorWithRed:0xf6/255.0 green:0xf7/255.0 blue:0xf7/255.0 alpha:100] CGColor]];
            
            [downButtonLayer setBorderColor: [[UIColor lightGrayColor] CGColor]];
        }
    }
    
    //图片列表
    nShowY  =   [self setimgs_Videos_ListShowY:nShowY];
    
    //文本
    nShowY  =   [self setMessageContentShowY:nShowY];

    //Local
    nShowY  =   [self setLocalShowY:nShowY];
    
    //Web Link
    nShowY  =   [self setWebLinkShowY:nShowY];
    
    //Comment
    if(bForDetail){
        _commentView.hidden   =   YES;
        _lineView.hidden       =    YES;
    }
    else{
        _commentCountLable.hidden = NO;
        _commentIcon.hidden = NO;
        
        if(noteMessage.commentNum){
            _commentCountLable.text =   [@(noteMessage.commentNum) stringValue];
        }
        else{
            _commentCountLable.text =   @"";
        }
        
//        _commentCountLable.text =   [@(rand()) stringValue];
        
        float nWidth =    [_commentCountLable getAutoresizeWithLimitWidth:kWebInfoWidth andLimitHight:MAXFLOAT].width+6;
        CGRect frame = _commentCountLable.frame;
        ///frame.origin.x =   frame.origin.x+frame.size.width-nWidth;
        frame.origin.x  = kScreen_Width - 26 ;
        frame.size.width    =   nWidth;
        _commentCountLable.frame    =   frame;
        
        CGRect iconFrame =  _commentIcon.frame;
        iconFrame.origin.x  =   frame.origin.x-4-iconFrame.size.width;
        _commentIcon.frame  =   iconFrame;
        
        
        [_commentView setFrame_y:nShowY];
        nShowY  +=   _commentView.frame.size.height+8;
        [_lineView  setFrame_y:nShowY];

    }

    
//    NSLog(@".......%ld,%ld,%f",nShowY,_noteMessage.hightInList,self.frame.size.height);
    
//    [_lineView  setFrame_y:self.contentView.frame.size.height-2];
}


-(void)setNoteComment:(ACNoteComment*)noteComment{
    _noteObject =   noteComment;
    float nShowY = 8;
    
    _wallBoardDate.hidden = YES;
    _categoryLabel.hidden = YES;
    //    _lineView.hidden = YES;
    
    _userInfoView.hidden = NO;
    _commentView.hidden = NO;
    _lineView.hidden = NO;
    
    _webLinkView.hidden = YES;
    _imagesView.hidden  =   YES;
    _locationView.hidden = YES;
    
    //User 信息
    nShowY  =   [self setUserInfoShowY:nShowY];
    
    //文本
    nShowY  =   [self setMessageContentShowY:nShowY];
    
    //Comment
#if 1
    _commentView.hidden = YES;
    nShowY += 8;
#else
    _commentCountLable.hidden = YES;
    _commentIcon.hidden = YES;
    [_commentView setFrame_y:nShowY];
    nShowY  +=   _commentView.frame.size.height+8;
#endif
    
    [_lineView  setFrame_y:nShowY];
}

-(void)setHighlight:(NSArray<NSString*>*)highlights{
    if(highlights.count){
        [_textLabel setHighlight:highlights withText:_noteObject.content];
    }
}

+(float)getCellHeightWithNoteComment:(ACNoteComment*)noteComment{
    if(noteComment.hightInList>0){
        return noteComment.hightInList;
    }
    //文本高度
    int nContentH = [noteComment.content getHeightAutoresizeWithLimitWidth:(288*kScreen_Width/320) font:UIFont_for_Chat_Lable]+8;
    float nShowY = 8;
    
    //User 信息
    nShowY  +=  54+8;
    
    //文本
    nShowY += nContentH;
    
    //Comment
    nShowY += 30+8;
    
    nShowY  +=  2;
    
    noteComment.hightInList = nShowY;
    return noteComment.hightInList;
}

+(float)getCellHeightWithNoteMessage:(ACNoteMessage *)noteMessage  forDetail:(BOOL)bForDetail
{
    if(noteMessage.hightInList>0){
        return noteMessage.hightInList;
    }
    
    //文本高度
    int nContentH = [noteMessage.content getHeightAutoresizeWithLimitWidth:(288*kScreen_Width/320) font:UIFont_for_Chat_Lable]+8;
    
    //Local
    int nLocalH =   noteMessage.location?(30+8):0;
    
    //图片列表
    int nImagH =    noteMessage.imgs_Videos_List.count?(133+8):0;

    
    float nShowY = 8;
    
    if(noteMessage.categoryIDForWallBoard){
 
        //日期
        nShowY  +=  kwallBoardDate_H;
        
        //文本
        nShowY += nContentH;
        
        //Local
        nShowY  +=  nLocalH;
        
        //图片列表
        nShowY  +=  nImagH;
        
        
        if (noteMessage.categoryIDForWallBoard.length){
            NSArray *categoryArray = [ACDataCenter shareDataCenter].wallboardTopicEntity.categoriesArray;
            for (ACCategory *category in categoryArray){
                if ([category.cid isEqualToString:noteMessage.categoryIDForWallBoard]){
                    NSString *categoryName = [NSString stringWithFormat:@"%@ : %@",NSLocalizedString(@"Category", nil),category.name];
                    nShowY += 8+[categoryName getHeightAutoresizeWithLimitWidth:(305*kScreen_Width/320) font:[UIFont systemFontOfSize:11]];
                    break;
                }
            }
        }
        
        nShowY += 10;
    }
    else{

        //User 信息
        nShowY  +=  54+8;
    
        //图片列表
        nShowY  +=  nImagH;
    
        //文本
        nShowY += nContentH;
    
    
        //Local
        nShowY  +=  nLocalH;
    
        //Web Link
        if(noteMessage.link){
            
            //计算标题高度
            nShowY += 8;
            
            UIFont* uFont16 =   [UIFont systemFontOfSize:16];

            //Title
            nShowY  +=  [noteMessage.link.linkTitle getAutoSizeWithLimitWidth:kWebInfoWidth
                                                                        andLimitHight:WebLink_SetLimitHight font:uFont16].height+WebLink_Item_Delta_H;
            
            //URL
            nShowY  +=  18+WebLink_Item_Delta_H;

            //描述
            nShowY += [noteMessage.link.linkDesc getAutoSizeWithLimitWidth:kWebInfoWidth
                                                                        andLimitHight:WebLink_SetLimitHight font:uFont16].height+8;
        }
    
        //Comment
        if(!bForDetail){
            nShowY += 30+8;
        }
        
        //_lineView
        nShowY ++;
    }
    
    noteMessage.hightInList = nShowY;
    return noteMessage.hightInList;
}


/*
-(void)setNoteMessage:(ACNoteMessage *)noteMessage{
    if(_noteMessage==noteMessage){
        return;
    }
    _noteMessage = noteMessage;
    
    UIView *currentView = nil;
    NSString *dateString = [[ACDataCenter shareDataCenter] getDateStringWithTimeInterval:_noteMessage.createTime/1000];
    NSString *timeString = [[ACDataCenter shareDataCenter] getTimeStringWithTimeInterval:_noteMessage.createTime/1000];
    
    //日期
    _timeLabel.text = [dateString stringByAppendingFormat:@" %@",timeString];
    
    //文本
    _textLabel.text = noteMessage.content;
    [_textLabel setAutoresizeWithLimitWidth:288];
    currentView = _textLabel;
    
    if (noteMessage.location){
        _locationLabel.text = noteMessage.location.address;
        [_locationLabel setAutoresizeWithLimitWidth:260];
        [_locationImageView setCenter_y:_locationLabel.center.y];
        [_locationView setFrame_height:[_locationLabel getFrame_Bottom]];
        [_locationView setHidden:NO];
        [_locationView setFrame_y:[currentView getFrame_Bottom]+8];
        currentView = _locationView;
    }
    else{
        [_locationView setHidden:YES];
    }
    
    if (noteMessage.imgs_Videos_List.count)
    {
        [_horizontalTableView setHidden:NO];
        [_horizontalTableView setFrame_y:[currentView getFrame_Bottom]+8];
        [_horizontalTableView reloadData];
        currentView = _horizontalTableView;
        
        [_amountLabel setHidden:NO];
        _amountLabel.text = [NSString stringWithFormat:@"%@ %d",NSLocalizedString(@"Total", nil),(int)[noteMessage.imgs_Videos_List count]];
        [_amountLabel setFrame_y:[currentView getFrame_Bottom]+8];
        currentView = _amountLabel;
        
        [_amountImageView setHidden:NO];
        [_amountImageView setCenter_y:_amountLabel.center.y];
    }
    else
    {
        [_horizontalTableView setHidden:YES];
        
        [_amountLabel setHidden:YES];
        
        [_amountImageView setHidden:YES];
    }
    
    _categoryLabel.text = nil;
    
    if(noteMessage.categoryIDForWallBoard){
        NSArray *categoryArray = _superVC.topicEntity.categoriesArray;
        for (ACCategory *category in categoryArray)
        {
            if ([category.cid isEqualToString:noteMessage.categoryIDForWallBoard])
            {
                _categoryLabel.text = [NSString stringWithFormat:@"%@ : %@",NSLocalizedString(@"Category", nil),category.name];
                [_categoryLabel setAutoresizeWithLimitWidth:kCategoryWidth];
                break;
            }
        }
    }
    
    if (_categoryLabel.text != nil)
    {
        [_categoryLabel setFrame_y:[currentView getFrame_Bottom]+8];
        currentView = _categoryLabel;
    }
    else
    {
        [_categoryLabel setHidden:YES];
    }
    
    [_lineView setFrame_y:[currentView getFrame_Bottom]+10];
    
    
     NSString *imageName = @"personIcon100.png";
     
     NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
     if ([message.sendUserID isEqualToString:[defaults objectForKey:kUserID]])
     {
     [_iconImageView setImageWithIconString:[defaults objectForKey:kIcon] placeholderImage:[UIImage imageNamed:@"personIcon100.png"] type:ImageType_UserIcon100];
     }
     else if (user.icon)
     {
     [_iconImageView setImageWithIconString:user.icon placeholderImage:[UIImage imageNamed:imageName] type:ImageType_UserIcon100];
     }
     else
     {
     _iconImageView.image = [UIImage imageNamed:imageName];
     }
 
     
//    noteMessage.hightInList =   _lineView.frame.origin.y+_lineView.frame.size.height;
}

+(float)getCellHeightWithNoteMessage:(ACNoteMessage *)noteMessage
{
    if(noteMessage.hightInList>0){
        return noteMessage.hightInList;
    }
    float height = 25;
    
    height += [noteMessage.content getHeightAutoresizeWithLimitWidth:288 font:[UIFont systemFontOfSize:16]];
    
    if (noteMessage.location&&noteMessage.location.address.length>0)
    {
        height += [noteMessage.location.address getHeightAutoresizeWithLimitWidth:284 font:[UIFont systemFontOfSize:10]]+8;
    }
    
    if (noteMessage.imgs_Videos_List.count)
    {
        height += 106+8;
        
        height += 8+21;
    }
    
    if (noteMessage.categoryIDForWallBoard.length)
    {
        NSArray *categoryArray = [ACDataCenter shareDataCenter].wallboardTopicEntity.categoriesArray;
        for (ACCategory *category in categoryArray)
        {
            if ([category.cid isEqualToString:noteMessage.categoryIDForWallBoard])
            {
                NSString *categoryName = [NSString stringWithFormat:@"%@ : %@",NSLocalizedString(@"Category", nil),category.name];
                height += 8+[categoryName getHeightAutoresizeWithLimitWidth:305 font:[UIFont systemFontOfSize:11]];
                break;
            }
        }
//        height += 8+17;
    }
    
    height += 10;
    
    noteMessage.hightInList =   height;
    return height;
}
*/

#pragma mark -IBAction
-(IBAction)locationButtonTouchUp:(id)sender
{
    ACMapBrowerViewController *mapBrowserVC = [[ACMapBrowerViewController alloc] init];
    mapBrowserVC.coordinate = _noteMessage.location.Location;
    [_superVC ACpresentViewController:mapBrowserVC animated:YES completion:nil];
}

- (IBAction)onTimeLineNoteButton:(id)sender {
    ACTopicEntity* ptopicEntity = _noteMessage.topicEntity;
    if(nil==ptopicEntity){
        AC_ShowTip(NSLocalizedString(@"Topic has been removed!",nil));
        return;
    }
    
    ACNotesMsgVC_Main *notesVC = [[ACNotesMsgVC_Main alloc] init];
    AC_MEM_Alloc(notesVC);
    notesVC.topicEntity = ptopicEntity;
    [_superVC.navigationController pushViewController:notesVC animated:YES];
}


- (IBAction)onWebLinkClick:(id)sender {
    ACAcuLearnWebViewController *acuLearnWebVC = [[ACAcuLearnWebViewController alloc] initWithUrlString:_noteMessage.link.linkURL];
    acuLearnWebVC.titleString = @"";
    //    [_superVC ACpresentViewController:acuLearnWebVC animated:YES completion:nil];
    [_superVC.navigationController pushViewController:acuLearnWebVC animated:YES];
}


- (IBAction)onCommentClick:(id)sender {
    //     NSLog(@"onCommentClick");
}


#pragma mark -UITableViewDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_noteMessage.imgs_Videos_List count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACNoteListVC_Cell_Media_H_Cell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACNoteListVC_Cell_Media_H_Cell"];
    if (!cell)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACNoteListVC_Cell_Media_H_Cell" owner:nil options:nil];
        cell = [nib objectAtIndex:0];
        cell.transform = CGAffineTransformMakeRotation(M_PI/2);
    }
    
    [cell setNoteMessage:_noteMessage index:(int)indexPath.row withSuperVC:_superVC];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 104;
}

@end
