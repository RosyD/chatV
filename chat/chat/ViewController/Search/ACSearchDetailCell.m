//
//  ACSearchDetailCell.m
//  chat
//
//  Created by 王方帅 on 14-7-8.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACSearchDetailCell.h"
#import "ACMessage.h"
#import "ACUser.h"
#import "UIImageView+WebCache.h"
#import "ACUserDB.h"
#import "ACNetCenter.h"
#import "ACDataCenter.h"
#import "UIView+Additions.h"
#import "NSString+Additions.h"
//#import "MarkupParser.h"
#import "NSAttributedString+Additions.h"
#import "ACSearchDetailController.h"

#define kAutoresizeLimitWidth   222

#define kHighLightPre @"#em#"
#define kHighLightSuf @"$em$"

#define kHighLightColor @"<font color=\"red\">"
#define kNormalColor    @"<font color=\"black\">"

@implementation ACSearchDetailCell

- (void)awakeFromNib
{
    // Initialization code
    [super awakeFromNib];
    _contentLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [_iconImageView.layer setCornerRadius:5.0];
    [_iconImageView.layer setMasksToBounds:YES];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)_setDataMessage:(ACMessage*)msg orNoteSearchResultDict:(NSDictionary*)noteDict{
    
//    ACMessage *message = (ACMessage *)_dataObject;
    
    BOOL        bShowDeleted = NO;
    double      createTime = 0;
    NSString    *content = nil;
    NSString    *entityName = nil;
    NSString    *pUserName = nil;
    NSString    *pUserIcon = nil;
    
    if(msg){
    
        ACUser *user = [ACUserDB getUserFromDBWithUserID:msg.sendUserID];
        
        pUserName   =   user.name;
        pUserIcon   =   user.icon;
        
        content     =   msg.content;
        createTime  =   msg.createTime;
        
        if([msg isKindOfClass:[ACFileMessage class]]&&content.length){
            NSDictionary *contentDic = [content objectFromJSONString];
            content =   contentDic[kName];
            if(msg.messageEnumType == ACMessageEnumType_Image&&
               0==content.length){
                content =   contentDic[kCaption];
            }
        }
        
        bShowDeleted    =   msg.isDeleted;
        entityName      =   msg.topicEntityTitle;
    }
    else{
/*
 {
 "indexType": "note",  //索引类型
 "desp": "#em#nihaoma$em$ ... ", //索引关键字
 "createTime": 1477621463979, //笔记创建时间
 "id": "5812b6d7291ba833a4164233", //noteid
 "user": {
 "name": "gggggggggggggggggggggggggggggggggggggggggggggggggggggggggg liu",
 "fname": "gggggggggggggggggggggggggggggggggggggggggggggggggggggggggg",
 "lname": "liu",
 "icon": "/rest/apis/user/icon/user/57d7aec147be1a018ca5c941?t=1476431286822",
 "id": "57d7aec147be1a018ca5c941",
 "updateTime": 1477621423585,
 "account": "3262238232@qq.com",
 "domain": "glj",
 "account2": "liujie"
 },
 "teid": "580ed6c036e09e9c4ca560c9",  //回话id
 "type": 1,  //笔记类型  1、笔记   10、评论
 "contentType": "text",   //搜索内容类型
 "terminal": "web",   //终端
 "title": "nihao, jsadhfjka ...",  //标题
 "userName": "gggggggggggggggggggggggggggggggggggggggggggggggggggggggggg liu"
 }
 */
        content     =   noteDict[@"desp"];
        createTime  =   [noteDict[@"createTime"] doubleValue];
        entityName  =   noteDict[@"title"];
        
        NSDictionary* pUser =   noteDict[@"user"];
        pUserName = pUser[@"name"];
        pUserIcon = pUser[@"icon"];
    }
    //content

    
    if(nil==content){
        content = @"";
    }
    
    _deletedLabel.hidden = !bShowDeleted;
    if (bShowDeleted){
        [_sessionLabel setFrame_width:190];
    }
    else{
        [_sessionLabel setFrame_width:227];
    }

    
    //单聊显示用户icon和name，组聊显示组icon和组名
    

    [_iconImageView setImageWithIconString:pUserIcon
                          placeholderImage:[UIImage imageNamed:@"personIcon100.png"]
                                 ImageType:ImageType_TopicEntity];
    
    
    //            NSString *showContent = content;//[NSString stringWithFormat:@"%@ From: %@ At Session: %@",content,user.name,entityName];
    _personLabel.text = [NSString stringWithFormat:@"%@:",pUserName];
    _sessionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"From:%@",nil),entityName];
    
    //            showContent = [showContent stringByReplacingOccurrencesOfString:kHighLightPre withString:kHighLightColor];
    //            showContent = [showContent stringByReplacingOccurrencesOfString:kHighLightSuf withString:kNormalColor];
    //            MarkupParser *p = [[MarkupParser alloc]init];
    ////            p.font  =   @"Arial";
    //            p.pointSize = _contentLabel.font.pointSize;
    //            NSAttributedString *attString = [p attrStringFromMarkup:showContent];
    
    NSMutableString* pStringBuffer = [[NSMutableString alloc] init];
    NSRange *attribRangsHead = malloc(sizeof(NSRange)*500);
    NSRange *attribRangsTemp = attribRangsHead;
    
    while(TRUE){
        NSRange nFindBegin = [content rangeOfString:kHighLightPre]; //@"#em#"
        if(0==nFindBegin.length){
            break;
        }
        NSRange nFindEnd =  [content rangeOfString:kHighLightSuf];
        if(0==nFindEnd.length){
            break;
        }
        
        if(nFindBegin.location){
            [pStringBuffer appendString:[content substringToIndex:nFindBegin.location]];
        }
        
        //标记数据
        NSRange nMarkRang = NSMakeRange(nFindBegin.location+nFindBegin.length, nFindEnd.location-(nFindBegin.location+nFindBegin.length));
        
        //取得标记位置
        attribRangsTemp->location = pStringBuffer.length;
        attribRangsTemp->length = nMarkRang.length;
        attribRangsTemp ++;
        
        //添加字符串
        [pStringBuffer appendString:[content substringWithRange:nMarkRang]];
        
        //取得剩下的数据
        content =   [content substringFromIndex:nFindEnd.location+nFindEnd.length];
    };
    [pStringBuffer appendString:content];
    
    
    NSMutableAttributedString *attString =    [[NSMutableAttributedString alloc] initWithString:pStringBuffer];
    
    [attString addAttributes:@{NSFontAttributeName:_contentLabel.font,
                               NSForegroundColorAttributeName:[UIColor blackColor]}
                       range:NSMakeRange(0, content.length)];
    
    NSRange* pRangTemp =    attribRangsHead;
    UIColor* redColor = [UIColor redColor];
    while (pRangTemp<attribRangsTemp) {
        [attString addAttribute:NSForegroundColorAttributeName
                          value:redColor
                          range:*pRangTemp];
        pRangTemp ++;
    }
    free(attribRangsHead);
    
    _dateLable.hidden = NO;
    _dateLable.text =   [[ACDataCenter shareDataCenter] getDateStringWithTimeInterval:createTime / 1000];
    _contentLabel.text = nil; //@"大家好";
    _contentLabel.attributedText =  attString;
    [_contentLabel setNeedsDisplay];
    [_iconImageView setFrame_y:20];
    [_contentLabel setFrame_y:34];
    [_detailImageView setFrame_y:36];
}

-(void)setDataObject:(NSObject *)dataObject superVC:(ACSearchDetailController *)superVC
{
    _superVC = superVC;
    if (_dataObject != dataObject)
    {
        _dateLable.hidden = YES;
        _dataObject = dataObject;
        NSString *imageName = @"personIcon100.png";
        if ([_dataObject isKindOfClass:[ACMessage class]]){
            [self _setDataMessage:(ACMessage*)_dataObject orNoteSearchResultDict:nil];
        }
        else if ([_dataObject isKindOfClass:[NSDictionary class]]){
            [self _setDataMessage:nil orNoteSearchResultDict:(NSDictionary*)_dataObject];
        }
        else if ([_dataObject isKindOfClass:[ACUser class]])
        {
            ACUser *user = (ACUser *)_dataObject;
            _personLabel.hidden = YES;
            _sessionLabel.hidden = YES;
            [_iconImageView setFrame_y:9];
            [_contentLabel setFrame_y:23];
            [_detailImageView setFrame_y:25];
            [_iconImageView setImageWithIconString:user.icon placeholderImage:[UIImage imageNamed:imageName] ImageType:ImageType_UserIcon100];
            
            _contentLabel.text = [NSString stringWithFormat:@"%@",user.name];
            [_deletedLabel setHidden:YES];
        }
        else if ([_dataObject isKindOfClass:[ACUserGroup class]])
        {
            ACUserGroup *usergroup = (ACUserGroup *)_dataObject;
            _personLabel.hidden = YES;
            _sessionLabel.hidden = YES;
            [_iconImageView setFrame_y:9];
            [_contentLabel setFrame_y:23];
            [_detailImageView setFrame_y:25];
            [_iconImageView setImageWithIconString:usergroup.icon placeholderImage:[UIImage imageNamed:imageName] ImageType:ImageType_TopicEntity];
            
            _contentLabel.text = [NSString stringWithFormat:@"%@",usergroup.name];
            [_deletedLabel setHidden:YES];
        }
//        [_contentLabel setAutoresizeWithLimitWidth:kAutoresizeLimitWidth-20];
//        [_contentLabel setFrame_width:_contentLabel.size.width+10];
//        [_contentLabel setFrame_height:_contentLabel.size.height+10];
//        if (_contentLabel.size.height < 45)
//        {
//            [_contentLabel setFrame_height:45];
//        }
//        [_lineView setFrame_y:[_contentLabel getFrame_Bottom]+9];
    }
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [_lineView setFrame_y:self.size.height-1];
    [_lineView setFrame_width:kScreen_Width];
}

+(float)getCellHeightWithDataObject:(NSObject *)dataObject
{
//    NSString *contentString = nil;
    float height = 0;
    if ([dataObject isKindOfClass:[ACMessage class]]||
        [dataObject isKindOfClass:[NSDictionary class]])
    {
        return 91+20;
//        ACMessage *message = (ACMessage *)dataObject;
//        ACUser *user = [ACUserDB getUserFromDBWithUserID:message.sendUserID];
//        
//        //content
//        NSString *content = nil;
//        if (message.messageEnumType == ACMessageEnumType_Text)
//        {
//            content = message.content;
//        }
//        else if (message.messageEnumType == ACMessageEnumType_File)
//        {
//            content = message.content;
//        }
//        
//        NSString *entityName = nil;
//        for (ACTopicEntity *topicEntity in [ACDataCenter shareDataCenter].topicEntityArray)
//        {
//            if ([topicEntity.entityID isEqualToString:message.topicEntityID])
//            {
//                entityName = topicEntity.title;
//            }
//        }
//        contentString = [NSString stringWithFormat:@"%@ From: %@ At Session: %@",content,user.name,entityName];
//        contentString = [contentString stringByReplacingOccurrencesOfString:kHighLightPre withString:kHighLightColor];
//        contentString = [contentString stringByReplacingOccurrencesOfString:kHighLightSuf withString:kNormalColor];
//        MarkupParser *p = [[MarkupParser alloc]init];
//        p.pointSize = 17;
//        NSAttributedString *attString = [p attrStringFromMarkup:contentString];
//        height = [attString getHeightAutoresizeWithLimitWidth:kAutoresizeLimitWidth]+20;
    }
    else if ([dataObject isKindOfClass:[ACUser class]])
    {
//        ACUser *user = (ACUser *)dataObject;
//        
//        contentString = [NSString stringWithFormat:@"%@",user.name,user.groupName];
//        height = [contentString getHeightAutoresizeWithLimitWidth:kAutoresizeLimitWidth font:[UIFont systemFontOfSize:17]]+20;
        return 68;
    }
    else if ([dataObject isKindOfClass:[ACUserGroup class]])
    {
//        ACUserGroup *usergroup = (ACUserGroup *)dataObject;
//        
//        contentString = [NSString stringWithFormat:@"%@",usergroup.name];
//        height = [contentString getHeightAutoresizeWithLimitWidth:kAutoresizeLimitWidth font:[UIFont systemFontOfSize:17]]+30;
        return 68;
    }
    height += 24;
    if (height < 69){
        height = 69;
    }
    return height;
}

@end
