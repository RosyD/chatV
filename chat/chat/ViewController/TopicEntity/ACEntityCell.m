//
//  ACEntityCell.m
//  AcuCom
//
//  Created by wfs-aculearn on 14-4-2.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACEntityCell.h"
#import "UIImageView+WebCache.h"
#import "NSDate+Additions.h"
#import "UIView+Additions.h"
#import "ACUser.h"
#import "ACUserDB.h"
#import "ACTopicEntityDB.h"
#import "ACChatViewController.h"
#import "ACRootTableViewCell.h"
#import "ACMessage.h"
#import "ACNetCenter.h"
#import "ACUrlEditViewController.h"
#import "ACDataCenter.h"


#define kAlertViewTag_Delete_group    32323   //删除
#define kAlertViewTag_Delete_Sigle_chat 32324
#define kAlertViewTag_Delete_lastadmin  32325 //


#define LongPressFuncType_Delete        0x01    //长按显示删除
#define LongPressFuncType_Link_Edit     0x02    //link Edit
#define LongPressFuncType_Topic_Alert   0x04


@implementation ACEntityCell

+(instancetype)cellForTableView:(UITableView *)tableView{
    ACEntityCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACEntityCell"];
    if (!cell){
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACEntityCell" owner:nil options:nil];
        cell = [nib objectAtIndex:0];
    }
    return cell;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [_unReadNumButton setBackgroundImage:[[UIImage imageNamed:@"unread_num_bg.png"] stretchableImageWithLeftCapWidth:9 topCapHeight:10] forState:UIControlStateNormal];
//    [_iconImageView.layer setMasksToBounds:YES];
//    [_iconImageView.layer setCornerRadius:5.0];
    
    [_lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.offset(0);
        make.bottom.offset(-1);
        make.height.offset(1);
    }];
    
    [_iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(1);
        make.height.width.offset(64);
        make.centerY.offset(0);
    }];
    
    [_contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(67);
        make.top.offset(52);
        make.height.offset(18);
        make.width.offset(kScreen_Width - 67 - 55);
    }];
    
    [_urlEntityTypeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.offset(1);
        make.centerY.equalTo(_contentLabel);
        make.height.offset(18);
        make.width.offset(50);
    }];

    //_namelabel  width 110 是指——timeLabel的大小和间隔的大小
//    CGFloat n = kScreen_Width - 64 - 112;
    [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(67);
        make.top.offset(13);
        make.height.offset(20);
        make.width.offset(kScreen_Width - 64 - 115);
    }];
    
    [_timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.offset(-2);
        make.top.offset(13);
    }];
    
    
}

-(void)setEntityForTransmit:(ACBaseEntity *)entity{
    [self setEntity:entity superVC:nil];
}

-(void)setEntity:(ACBaseEntity *)entity superVC:(ACChatViewController *)superVC{
    _entity = entity;
    _superVC = superVC;
//    _entityType = entityType;
    _topicEntity = nil;
    _urlEntity = nil;
    
    self.backgroundView = nil;
    self.selectedBackgroundView = nil;
    
    if (entity.entityType == EntityType_Topic)
    {
        _topicEntity = (ACTopicEntity *)_entity;
        
        if(_superVC&&_topicEntity.isToped){
            //d4d3d8
            self.backgroundView = [[UIView alloc]init];
            self.backgroundView.backgroundColor= UIColor_RGB(0xd3,0xd3,0xd8);

            self.selectedBackgroundView=[[UIView alloc]init];
            self.selectedBackgroundView.backgroundColor= UIColor_RGB(0xc3,0xc3,0xc4);
        }
        
        [self topicSetting];
    }
    else
    {
        _urlEntity = (ACUrlEntity *)_entity;
        [self urlSetting];
    }
}

-(void)_setLongPressWithPrem:(ACPermission*)pPerm{
    if(nil==_superVC){
        return;
    }
    for (UIGestureRecognizer *ges in self.contentView.gestureRecognizers)
    {
        [self.contentView removeGestureRecognizer:ges];
    }
    
    _nLongPressFuncType =   0;
    
    if(_topicEntity){
        if([_topicEntity.mpType isEqualToString:cWallboard]){
            return;
        }
        _nLongPressFuncType |=  LongPressFuncType_Topic_Alert;
    }
    else{
        if([_urlEntity.mpType isEqualToString:cLink]&&
            (_urlEntity.perm.canUpdateInfo||_urlEntity.perm.canViewParticipants)){
            _nLongPressFuncType |=  LongPressFuncType_Link_Edit;
        }
    }
    
    if(pPerm.canDeleteSession&&ChatType_Define==_superVC.chatType){
        _nLongPressFuncType |=  LongPressFuncType_Delete;
    }
  
    if(0==_nLongPressFuncType){
        return;
    }
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)];
    [self.contentView addGestureRecognizer:longPress];
}

-(void)topicSetting
{
    
#if 0
    BOOL bIconViewToCircle = YES;

    
//    [_nameLabel setFrame_y:14];
    if ([_topicEntity.mpType isEqualToString:cWallboard])
    {
        bIconViewToCircle = NO;
        _iconImageView.image = [UIImage imageNamed:@"wallboard.png"];
        _nameLabel.text = _topicEntity.title;
//        [_nameLabel setFrame_y:24];
    }
    //单聊显示用户icon和name，组聊显示组icon和组名
    else if ([_topicEntity.mpType isEqualToString:cSingleChat])
    {
        ACUser *user = [ACUserDB getUserFromDBWithUserID:_topicEntity.singleChatUserID];
        
        //组icon
        NSString *imageName = @"icon_singlechat.png";
        if (user.icon)
        {
            [_iconImageView setImageWithIconString:user.icon
                                  placeholderImage:[UIImage imageNamed:imageName]
                                              ImageType:ImageType_TopicEntity];
        }
        else
        {
            bIconViewToCircle = NO;
            _iconImageView.image = [UIImage imageNamed:imageName];
        }
        _nameLabel.text = user.name;
//        if ([user.name isEqualToString:@"win8"])
//        {
//            
//        }
    }
    else
    {
        //组icon
        NSString *imageName = @"icon_groupchat.png";
        if (_topicEntity.icon)
        {
            if ([_topicEntity.mpType isEqualToString:cLocationAlert])
            {
                bIconViewToCircle = NO;
                [_iconImageView setImage:[UIImage imageNamed:@"LocationAlert.png"]];
            }
            else
            {
                [_iconImageView setImageWithIconString:_topicEntity.icon
                                      placeholderImage:[UIImage imageNamed:imageName]
                                                  ImageType:ImageType_TopicEntity];
            }
        }
        else
        {
            bIconViewToCircle = NO;
            _iconImageView.image = [UIImage imageNamed:imageName];
        }
        
        //组名
        _nameLabel.text = _topicEntity.title;
        if ([_topicEntity.title isEqualToString:@"dfghooighjkkkhfdhjkjgffddhbnvxswyuijgcvbjifdhjbgxtkkjbkjgdsewetuippigjvzvnjgfhjjgddtuewtipknxf"])
        {
            
        }
        //$$
        if(_topicEntity.relateTeID != nil && _topicEntity.relateTeID.length > 0) // 特殊会话
        {
            ACUser *user = [ACUserDB getUserFromDBWithUserID:_topicEntity.relateChatUserID];
            
            //组icon
            NSString *imageName = @"icon_groupchat.png";
            if (user.icon)
            {
                [_iconImageView setImageWithIconString:user.icon
                                      placeholderImage:[UIImage imageNamed:imageName]
                                                  type:ImageType_TopicEntity];
            }
            else
            {
                bIconViewToCircle = NO;
                _iconImageView.image = [UIImage imageNamed:imageName];
            }
            _nameLabel.text = user.name;
        }
    }
    
    if(bIconViewToCircle){
        [_iconImageView setToCircle];
    }
    else{
        [_iconImageView setRectRound:5];
    }
#else
    _nameLabel.text = [_topicEntity getShowTitleAndSetIcon:_iconImageView andCanEditForGroupInfoOption:NULL];
#endif
    
///    float width = 200;
//    [_nameLabel setSingleRowAutosizeLimitWidth:width];
//    [_nameLabel setFrame_width:width];
    [_nameLabel setLineBreakMode:NSLineBreakByTruncatingTail];
    
    if (_nameLabel.size.width < (kScreen_Width - 64 - 115)) {
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.offset(kScreen_Width - 64 - 115);
        }];
        [_nameLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            
        }];
    }
    
    
    
    if ([_topicEntity.mpType isEqualToString:cWallboard])
    {
        if (_topicEntity.lastestMessageTime == 0){
            _topicEntity.lastestMessageTime = _topicEntity.updateTime;
        }
        
        if (_topicEntity.lastestMessageTime == 0){
            _topicEntity.lastestMessageTime = _topicEntity.createTime;
        }
    }
    
    //时间显示
    NSDate *date = nil;
    if (_topicEntity.lastestMessageTime)
    {
        date = [NSDate dateWithTimeIntervalSince1970:_topicEntity.lastestMessageTime/1000];
    }
    else if (_topicEntity.updateTime)
    {
        date = [NSDate dateWithTimeIntervalSince1970:_topicEntity.updateTime/1000];
    }
    
    _timeLabel.text = [NSDate stringForRecentDate:date];
    [_timeLabel setAutoresizeWithLimitWidth:100];
//    [_timeLabel setFrame_x:313-_timeLabel.size.width];
//    [_timeLabel setFrame_x:kScreen_Width - _timeLabel.size.width - 2];
    UIView *currentView = [self resetLocationAndDestruct];
///    if (_timeLabel.origin.x < [currentView getFrame_right]+2)
        if (_timeLabel.origin.x < [currentView getFrame_right]+5)
    {
        [self rightToLeftResetNameLabelLimitWidth:_timeLabel.origin.x - 5];
    }
    
    //阅后即焚
    [_contentLabel setHidden:NO];
    if (_topicEntity.topicPerm.destruct == ACTopicPermission_DestructMessage_Allow)
    {
//        int unReadNum = (int)(_topicEntity.lastestSequence - _topicEntity.currentSequence);
//        if (unReadNum == 0)
//        {
//            [_contentLabel setHidden:YES];
//        }
        _contentLabel.text =    NSLocalizedString(@"Secret chat", nil);
    }
    else{
        _contentLabel.text = _topicEntity.lastestTextMessage;
    }
    
    [self _setLongPressWithPrem:_topicEntity.perm];
    
    /*TXB
    //权限操作
    switch (_topicEntity.perm.del) {
        case ACTopicPermission_Delete_Deny:
        {
            for (UIGestureRecognizer *ges in self.gestureRecognizers)
            {
                [self.contentView removeGestureRecognizer:ges];
            }
        }
            break;
        case ACTopicPermission_Delete_LeaveGroup:
        case ACTopicPermission_Delete_CacheOnly:
        {
            for (UIGestureRecognizer *ges in self.gestureRecognizers)
            {
                [self.contentView removeGestureRecognizer:ges];
            }
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(deleteSession:)];
            [self.contentView addGestureRecognizer:longPress];
        }
            break;
        case ACTopicPermission_Delete_Terminate:
        {
            for (UIGestureRecognizer *ges in self.gestureRecognizers)
            {
                [self.contentView removeGestureRecognizer:ges];
            }
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(deleteGroup:)];
            [self.contentView addGestureRecognizer:longPress];
        }
            break;
        default:
            break;
    }
    if ([_topicEntity.title isEqualToString:@"win8"])
    {
        
    }*/
    
    //详细
    

    //未读数显示
    int unReadNum = (int)(_topicEntity.lastestSequence - _topicEntity.currentSequence);
    if (_superVC&&unReadNum>0)
    {
        [_unReadNumButton setHidden:NO];
        [_unReadNumButton setTitle:unReadNum>99?@"99+":[NSString stringWithFormat:@"%d",unReadNum] forState:UIControlStateNormal];
        if (unReadNum >= 100)
        {
            
            /// [_unReadNumButton setFrame_width:32];99+变省略号
            [_unReadNumButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.offset(45);
                make.right.offset(-3);
                make.centerY.equalTo(_contentLabel);
                make.height.offset(25);
            }];
            //            [_unReadNumButton setFrame_x:283];
        }
        else if (unReadNum >= 10)
        {
            ///[_unReadNumButton setFrame_width:25];
            [_unReadNumButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.offset(35);
                make.right.offset(-3);
                make.centerY.equalTo(_contentLabel);
                make.height.offset(25);
            }];
            //            [_unReadNumButton setFrame_x:287];
        }
        else
        {
            /// [_unReadNumButton setFrame_width:20];
            
            [_unReadNumButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.offset(25);
                make.right.offset(-3);
                make.centerY.equalTo(_contentLabel);
                make.height.offset(25);
            }];
            //            [_unReadNumButton setFrame_x:292];
        }
//        [_contentLabel setFrame_width:_unReadNumButton.origin.x-_contentLabel.origin.x];
    }
    else
    {
        [_unReadNumButton setHidden:YES];
//        [_contentLabel setFrame_width:237];
    }
    
    [_urlEntityTypeLabel setHidden:YES];
    if ([_topicEntity.mpType isEqualToString:cWallboard])
    {
        _contentLabel.hidden = YES;
        _unReadNumButton.hidden = YES;
    }
    
    if (_superVC&&[_superVC.searchKey length] > 0)
    {
        [_searchNameLabel setHidden:NO];
        [_nameLabel setHidden:YES];
        [self setHighLight];
    }
    else
    {
        [_searchNameLabel setHidden:YES];
        [_nameLabel setHidden:NO];
    }
}



//从左到右设置location和destruct
-(UIView *)resetLocationAndDestruct
{
    UIView *currentView = _nameLabel;
    
    [_nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(67);
        make.top.offset(13);
        make.height.offset(20);
//        make.width.offset(kScreen_Width - 64 - 112 - 53);

    }];
    
    if (_topicEntity.topicPerm.reportLocation == ACTopicPermission_ReportLocation_Deny)
    {
        _locationImageView.hidden = YES;
    }
    else
    {
        _locationImageView.hidden = NO;
        ///[_locationImageView setFrame_x:[currentView getFrame_right]+2];
        [_locationImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(currentView.mas_right).offset(1);
            make.centerY.equalTo(_nameLabel);
            make.width.height.offset(20);
        }];
        currentView = _locationImageView;
    }
    
    
    if (_topicEntity.topicPerm.destruct == ACTopicPermission_DestructMessage_Deny)
    {
        _destructImageView.hidden = YES;
    }
    else
    {
        _destructImageView.hidden = NO;
        /// [_destructImageView setFrame_x:[currentView getFrame_right]+2];

        [_destructImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(currentView.mas_right).offset(1);
            make.centerY.equalTo(currentView);
            make.width.height.offset(20);
        }];
        currentView = _destructImageView;
    }
    
    if(_topicEntity.isTurnOffAlerts){
        _muteFlagImageView.hidden = NO;
        ///[_muteFlagImageView setFrame_x:[currentView getFrame_right]+2];
        [_muteFlagImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(currentView.mas_right).offset(1);
            make.centerY.equalTo(currentView);
            make.width.height.offset(12);
        }];
        
        currentView = _muteFlagImageView;
    }
    else{
        _muteFlagImageView.hidden = YES;
    }
    
    if (currentView == _nameLabel) {
//        [_nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
//            make.left.offset(67);
//            make.top.offset(13);
//            make.height.offset(20);
//            make.width.offset(kScreen_Width - 64 - 112);
//            
//        }];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.offset(67);
            make.top.offset(13);
            make.height.offset(20);
            if (_nameLabel.size.width > kScreen_Width - 64 - 115) {
                make.width.offset(kScreen_Width - 64 - 115);
            }
            
        }];
    }
    
    return currentView;
}


//从右到左
-(UIView *)rightToLeftResetNameLabelLimitWidth:(float)width
{
    UIView *currentView = _timeLabel;
    
    if(_topicEntity.isTurnOffAlerts){
//       [_muteFlagImageView setFrame_x:currentView.origin.x-2-_muteFlagImageView.size.width];
        [_muteFlagImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(_nameLabel);
//            make.left.offset(currentView.origin.x-2-_muteFlagImageView.size.width);
             make.width.height.offset(13);
            make.left.equalTo(currentView).offset(-2-_muteFlagImageView.size.width);
           
        }];
        
        currentView = _muteFlagImageView;
    }

    if (_topicEntity.topicPerm.destruct != ACTopicPermission_DestructMessage_Deny)
    {
//        /[_destructImageView setFrame_x:currentView.origin.x-2-_destructImageView.size.width];
        [_destructImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(_nameLabel);
//            make.left.offset(currentView.origin.x-2-_destructImageView.size.width);
             make.width.height.offset(20);
            make.left.equalTo(currentView).offset(-2-_destructImageView.size.width);
        }];
        
        currentView = _destructImageView;
    }
    if (_topicEntity.topicPerm.reportLocation != ACTopicPermission_ReportLocation_Deny)
    {
//        /[_locationImageView setFrame_x:currentView.origin.x-2-_locationImageView.size.width];
        [_locationImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(_nameLabel);
//            make.left.offset(currentView.origin.x-2-_locationImageView.size.width);
            make.width.height.offset(20);
            make.left.equalTo(currentView).offset(-2-_locationImageView.size.width);
        }];
        
        currentView = _locationImageView;
    }
    
//    [_nameLabel setFrame_width:currentView.origin.x-2-_nameLabel.origin.x];

    
    CGFloat n = currentView.origin.x- 2 -_nameLabel.origin.x;
    NSLog(@"_nameLabel  width \n %f",n);
    NSLog(@"_nameLabel.origin.x \n %f",_nameLabel.origin.x);
    NSLog(@"currentView.origin.x \n %f",currentView.origin.x);
     NSLog(@"time.origin.x \n %f",_timeLabel.origin.x);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

    });
    [_nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(67);
        make.top.offset(13);
        make.height.offset(20);
        make.width.offset(n);
//        make.width.offset(kScreen_Width - 64 - 112 - 53);
    }];
    [_nameLabel updateConstraintsIfNeeded];
    
    return currentView;
}

-(void)urlSetting
{
    //组icon
    UIImage *image = nil;
    if ([_urlEntity.mpType isEqualToString:cEvent])
    {
        image = [UIImage imageNamed:@"icon_event.png"];
        [_urlEntityTypeLabel setText:NSLocalizedString(@"Event", nil)];
    }
    else if ([_urlEntity.mpType isEqualToString:cSurvey])
    {
        image = [UIImage imageNamed:@"icon_survey.png"];
        [_urlEntityTypeLabel setText:NSLocalizedString(@"Survey", nil)];
    }
    else if ([_urlEntity.mpType isEqualToString:cLink])
    {
        image = [UIImage imageNamed:@"icon_link.png"];
        [_urlEntityTypeLabel setText:NSLocalizedString(@"Link", nil)];
    }
    else if ([_urlEntity.mpType isEqualToString:cPage])
    {
        image = [UIImage imageNamed:@"icon_page.png"];
        [_urlEntityTypeLabel setText:NSLocalizedString(@"Webpage", nil)];
    }
    if (_urlEntity.icon)
    {
        [_iconImageView setToCircle];
        [_iconImageView setImageWithIconString:_urlEntity.icon placeholderImage:image ImageType:ImageType_UrlEntity];
    }
    else
    {
        [_iconImageView setRectRound:5];
        _iconImageView.image = image;
    }
    _nameLabel.text = _urlEntity.title;
    
//   [_nameLabel setSingleRowAutosizeLimitWidth:182];
    [_nameLabel setLineBreakMode:NSLineBreakByTruncatingTail];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_urlEntity.updateTime/1000];
    _timeLabel.text = [NSDate stringForRecentDate:date];
    [_timeLabel setAutoresizeWithLimitWidth:100];
    [_timeLabel setFrame_x:313-_timeLabel.size.width];
    
//    [_nameLabel setFrame_width:_timeLabel.origin.x-_nameLabel.origin.x-5];
    [_nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(67);
        make.top.offset(13);
        make.height.offset(20);
        if (_nameLabel.size.width > kScreen_Width - 64 - 115) {
            make.width.offset(kScreen_Width - 64 - 115);
        }
    }];

/*TXB
    //权限操作
    switch (_urlEntity.perm.del) {
        case ACTopicPermission_Delete_Deny:
        {
            for (UIGestureRecognizer *ges in self.gestureRecognizers)
            {
                [self.contentView removeGestureRecognizer:ges];
            }
        }
            break;
        case ACUrlPermission_Delete_Allow:
        {
            for (UIGestureRecognizer *ges in self.gestureRecognizers)
            {
                [self.contentView removeGestureRecognizer:ges];
            }
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(deleteSession:)];
            [self.contentView addGestureRecognizer:longPress];
        }
            break;
        case ACUrlPermission_Delete_Terminate:
        {
            for (UIGestureRecognizer *ges in self.gestureRecognizers)
            {
                [self.contentView removeGestureRecognizer:ges];
            }
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(deleteGroup:)];
            [self.contentView addGestureRecognizer:longPress];
        }
            break;
        default:
            break;
    }*/
    [self _setLongPressWithPrem:_urlEntity.perm];
    
    //详细
    ACUser *user = [ACUserDB getUserFromDBWithUserID:_urlEntity.createUserID];
    if (_superVC&&_superVC.chatListType == ACCenterViewControllerType_All)
    {
        _contentLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Created by %@", nil),user.name];
    }
    else
    {
        _contentLabel.text = user.name;
    }
//    [_contentLabel setFrame_width:190];
    
    [_unReadNumButton setHidden:YES];
    [_locationImageView setHidden:YES];
    [_destructImageView setHidden:YES];
    _muteFlagImageView.hidden = YES;

    [_urlEntityTypeLabel setHidden:NO];
    
    if (_superVC&&[_superVC.searchKey length] > 0)
    {
        [_searchNameLabel setHidden:NO];
        [_nameLabel setHidden:YES];
        [self setHighLight];
    }
    else
    {
        [_searchNameLabel setHidden:YES];
        [_nameLabel setHidden:NO];
    }
}

-(void)setHighLight
{
    if ([_superVC.searchKey length] > 0)
    {
        if (!_searchNameLabel)
        {
            _searchNameLabel = [[UILabel  alloc] initWithFrame:_nameLabel.frame];
//            _searchNameLabel = [[AttributedLabel alloc] initWithFrame:_nameLabel.frame];
            [self.contentView addSubview:_searchNameLabel];
        }
        else
        {
            [_searchNameLabel setFrame:_nameLabel.frame];
        }
        [_searchNameLabel setHidden:NO];
        
        NSMutableAttributedString* pStr = [[NSMutableAttributedString alloc] initWithString:_nameLabel.text];
        [pStr addAttributes:@{NSFontAttributeName:_nameLabel.font,NSForegroundColorAttributeName:[UIColor blackColor]} range:NSMakeRange(0, _nameLabel.text.length)];
        
        NSString *content = [_nameLabel.text lowercaseString];
        
        NSString *highLightString = [_superVC.searchKey lowercaseString];
        NSUInteger len = [highLightString length];
        NSArray *array = [content componentsSeparatedByString:highLightString];
        if ([array count] > 1)
        {
            UIColor* redColor = [UIColor redColor];
            NSUInteger loc = [[array objectAtIndex:0] length];
            [pStr addAttribute:NSForegroundColorAttributeName value:redColor range:NSMakeRange(loc, len)];
            loc += len;
            for (int i = 2; i < [array count]; i++)
            {
                loc += [[array objectAtIndex:i-1] length];
                [pStr addAttribute:NSForegroundColorAttributeName value:redColor range:NSMakeRange(loc, len)];
                loc += len;
            }
        }
        
        _searchNameLabel.attributedText = pStr;
        
        /*
//        [_searchNameLabel setAutoresizeWithLimitWidth:_searchNameLabel.size.width];
//        _searchNameLabel.topOffset = 2;
        _searchNameLabel.isNeedLineBreakMode = YES;
        [_searchNameLabel setColor:[UIColor blackColor] fromIndex:0 length:[_nameLabel.text length]];
        NSString *content = [_nameLabel.text lowercaseString];
        
        NSString *highLightString = [_superVC.searchKey lowercaseString];
        NSUInteger len = [highLightString length];
        NSArray *array = [content componentsSeparatedByString:highLightString];
        if ([array count] > 0)
        {
            NSUInteger loc = [[array objectAtIndex:0] length];
            [_searchNameLabel setColor:[UIColor redColor] fromIndex:loc length:len];
            loc += len;
            for (int i = 2; i < [array count]; i++)
            {
                loc += [[array objectAtIndex:i-1] length];
                [_searchNameLabel setColor:[UIColor redColor] fromIndex:loc length:len];
                loc += len;
            }
        }*/
        [_searchNameLabel setNeedsDisplay];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex==alertView.cancelButtonIndex){
        return;
    }
    
    if(kAlertViewTag_Delete_Sigle_chat==alertView.tag||kAlertViewTag_Delete_group==alertView.tag){
        [_superVC deleteEntity:_entity forTerminate:NO];
        return;
    }
    
    if(kAlertViewTag_Delete_lastadmin==alertView.tag){
        if (buttonIndex == alertView.firstOtherButtonIndex){
            //Transfer
            [_superVC transferAdmin:_entity];
            return;
        }
        
        [_superVC deleteEntity:_entity forTerminate:YES];
        return;
    }
    
//        if (buttonIndex == alertView.firstOtherButtonIndex)
//        {
//            if(ACTopicPermission_Delete_Deny==_topicEntity.perm.del){
//                if([_topicEntity.mpType isEqualToString:cWallboard]){
//                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalized String(@"Prompt", nil)
//                                                                    message:NSLocalized String(@"Delete_Can_not_Prompt", nil)
//                                                                   delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
//                    [alert show];
//                    return;
//                }
//            }
//            
//            if (_entityType == EntityType_Topic)
//            {
//                [_superVC deleteEntity:_topicEntity entityType:_entityType];
//            }
//            else
//            {
//                [_superVC deleteEntity:_urlEntity entityType:_entityType];
//            }
//        }
//    }
}

#pragma mark -actionSheetDelegate

-(void)_deleteSession:(BOOL)isAdmin{
    //直接删除
    NSString* pTitle = nil;
    
    if(_topicEntity){
        pTitle   =   _topicEntity.showTitle;
    }
    else{
        pTitle   =   _urlEntity.title;
    }

    NSString *pMessage = isAdmin?[NSString stringWithFormat:NSLocalizedString(@"Delete_Group_Will_Delete_For_admin", nil),pTitle]:
            [NSString stringWithFormat:NSLocalizedString(@"Delete_Group_Will_Delete_For_Nomal", nil),pTitle];


    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil)
                                                    message:pMessage
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                          otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    alert.tag = kAlertViewTag_Delete_group;
    [alert show];
}

#define actionSheet_Button_top_on      1
#define actionSheet_Button_top_off     2
#define actionSheet_Button_Alert       3
#define actionSheet_Button_LinkEdit    4
#define actionSheet_Button_Del         5

static  uint8_t g_actionSheetButtonID[4];
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex==actionSheet.cancelButtonIndex){
        return;
    }
    
    uint8_t  nButtonType =  g_actionSheetButtonID[buttonIndex-1]; //cancel按钮是0
    
    if(actionSheet_Button_top_on==nButtonType||actionSheet_Button_top_off==nButtonType){
        //置顶
        if(actionSheet_Button_top_on==nButtonType){
            [[ACDataCenter shareDataCenter] entityTops_Set:_entity];
        }
        else{
            [[ACDataCenter shareDataCenter] entityTops_Clear:_entity];
        }
        [_superVC reloadEntity];
        return;
    }
    
    if(actionSheet_Button_Alert==nButtonType){
        [_superVC changeIsTurnOffAlertsAndSendToServerForEntity:_topicEntity];
        return;
    }
    
    if(actionSheet_Button_LinkEdit==nButtonType){
        ACUrlEditViewController* urlEditVC = [[ACUrlEditViewController alloc] init];
        urlEditVC.urlEntity = _urlEntity;
        [_superVC.navigationController pushViewController:urlEditVC animated:YES];
        return;
    }
    
    //以下处理删除
    
    //单聊直接删除
    if(_topicEntity&&[_topicEntity.mpType isEqualToString:cSingleChat]){
        NSString* pTitle = [_topicEntity getShowTitleAndSetIcon:nil andCanEditForGroupInfoOption:NULL];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil)
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"Delete_Chat_Will_Delete_For_Nomal", nil),pTitle]
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        alert.tag = kAlertViewTag_Delete_Sigle_chat;
        [alert show];
        return;
    }
    
//    if(!(_entity.perm.needCheckLastAdmin)){
//        [self _deleteSession:NO];
//        return;
//    }
    
    //判断当前用户是否最后一个admin
    NSString* pURL = nil;
    if(EntityType_Topic==_entity.entityType){
        //rest/apis/chat/{topicEntityId}/lastadmin
        //        Method: GET
        pURL    = @"/rest/apis/chat/";
    }
    else{
        //rest/apis/url/{urlEntityId}/lastadmin
        //        Method: GET
        pURL    = @"/rest/apis/url/";
    }
    
    
    
    [_superVC.view showProgressHUDWithLabelText:NSLocalizedString(@"Preparing", nil) withAnimated:YES];
    wself_define();
    [ACNetCenter callURL:[NSString stringWithFormat:@"%@%@%@/lastadmin",[ACNetCenter shareNetCenter].acucomServer,pURL,_entity.entityID]
                  forMethodDelete:NO
               withBlock:^(ASIHTTPRequest *request, BOOL bIsFail) {
                   sself_define();
                   if(nil==sself){
                       return;
                   }
                   
                   [sself->_superVC.view hideProgressHUDWithAnimated:NO];
                   
                   if(!bIsFail){
                       NSDictionary *responseDic = [[[request.responseData objectFromJSONData] JSONString] objectFromJSONString];
                       if (ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]){
                           
                           if([[responseDic objectForKey:@"lastAdmin"] boolValue]){
                               //最后一个
                               NSString* entifyType = nil;
                               
                               if(sself->_urlEntity){
                                   NSString*    mpType =    sself->_urlEntity.mpType;
                                   if([mpType isEqualToString:cLink]){ //survey
                                       entifyType = NSLocalizedString(@"Link", nil); //link
                                   }
                                   else if([mpType isEqualToString:cSurvey]){ //survey
                                       entifyType = NSLocalizedString(@"Survey", nil);
                                   }
                                   else if([mpType isEqualToString:cEvent]){ //event
                                       entifyType = NSLocalizedString(@"Event", nil);
                                   }
                                   else if ([mpType isEqualToString:cPage]){ //web
                                       entifyType = NSLocalizedString(@"Webpage", nil);
                                   }
                                   else {
                                       return;
                                   }
                               }
                               else{
                                   entifyType = NSLocalizedString(@"Chat", nil); //chat
                               }
                               //"You are the only admin in this %@. \nTransfer admin and leave OR Delete this %@ now.";

                               UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil)
                                                                               message:[NSString stringWithFormat:NSLocalizedString(@"Entity_lastadmin_delete_format", nil),entifyType,entifyType]
                                                                              delegate:wself
                                                                     cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                                     otherButtonTitles:NSLocalizedString(@"Entity_lastadmin_Transfer", nil), NSLocalizedString(@"Entity_lastadmin_Dismiss", nil),nil];
                               alert.tag = kAlertViewTag_Delete_lastadmin;
                               [alert show];
                               return;
                           }
                           
                           //直接删除,不管是否是管理员
                           [wself _deleteSession:_entity.isAdmin];
                           return ;
                       }
                   }
                   [sself->_superVC.view showNetErrorHUD];
               }];
}

-(void)onLongPress:(UIGestureRecognizer *)ges{
    
    if (ges.state == UIGestureRecognizerStateBegan){
        
        
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:nil];
        // 逐个添加按钮（比如可以是数组循环）
        
        int nButtonNo = 0;
        if(LongPressFuncType_Topic_Alert&_nLongPressFuncType){
            [sheet addButtonWithTitle:_entity.isToped?NSLocalizedString(@"Undo always on top", nil):NSLocalizedString(@"Always on top", nil)];
            g_actionSheetButtonID[0] =  _entity.isToped?actionSheet_Button_top_off:actionSheet_Button_top_on;
            [sheet addButtonWithTitle:_topicEntity.isTurnOffAlerts?NSLocalizedString(@"Turn on alert", nil):NSLocalizedString(@"Turn off alert", nil)];
            g_actionSheetButtonID[1] =  actionSheet_Button_Alert;
            
            nButtonNo = 2;
        }
        else if(LongPressFuncType_Link_Edit&_nLongPressFuncType){
            [sheet addButtonWithTitle:NSLocalizedString(@"Edit", nil)];
            g_actionSheetButtonID[0] = actionSheet_Button_LinkEdit;
            
            nButtonNo = 1;
        }
        
        if(LongPressFuncType_Delete&_nLongPressFuncType){
            g_actionSheetButtonID[nButtonNo] = actionSheet_Button_Del;
            [sheet addButtonWithTitle:NSLocalizedString(@"Delete", nil)];
        }
        
        [sheet showInView:_superVC.view];
    }
}


@end
