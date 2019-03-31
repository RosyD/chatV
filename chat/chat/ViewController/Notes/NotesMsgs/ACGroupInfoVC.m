//
//  ACGroupInfoVC.m
//  chat
//
//  Created by Aculearn on 15/1/13.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#import "ACGroupInfoVC.h"
#import "ACGroupInfoVCCell.h"
#import "ACGroupInfoView_Header.h"
#import "ACNetCenter.h"
#import "UIView+Additions.h"
#import "UIImageView+WebCache.h"
#import "ACParticipant.h"
#import "ACChooseContactViewController.h"
#import "ACParticipantInfoViewController.h"
#import "UINavigationController+Additions.h"
#import "ACUserDB.h"
#import "ACUser.h"
#import "ACTopicEntityDB.h"
#import "ACSetAdminViewController.h"

@interface ACGroupInfoVC (){
    
    __weak IBOutlet UICollectionView *_membersCollectionView;
    __weak IBOutlet UIActivityIndicatorView    *_activityView;
    __weak ACGroupInfoView_Header*  _header;
    int             _nShowAddMember;
    BOOL            _canEditMember;
    BOOL            _bEditMembering; //正在编辑
    BOOL            _bYou_can_not_see_other_users_in_this_session_Showed;
    NSMutableArray* _pSourceArray; //<ACParticipant>
    __weak  ACUrlEntity*    _urlEntity_Temp;
    __weak  ACTopicEntity*  _topicEntity_Temp;
}

@end

@implementation ACGroupInfoVC

-(void)dealloc{
    AC_MEM_Dealloc();
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    ///
    [_membersCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.offset(kScreen_Width);
    }];
    
    [_membersCollectionView registerNib:[UINib nibWithNibName:@"ACGroupInfoVCCell"
                                                          bundle:nil]
             forCellWithReuseIdentifier:@"ACGroupInfoVC__Cell_ID"];

    [_membersCollectionView registerNib:[UINib nibWithNibName:@"ACGroupInfoView_Header" bundle:nil]
             forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                    withReuseIdentifier:@"ACGroupInfoVC__Header_ID"];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(getParticipantInfo:) name:kNetCenterGetParticipantsNotifation object:nil];
    [nc addObserver:self selector:@selector(addParticipant:) name:kNetCenterAddParticipantNotifation object:nil];
    [nc addObserver:self selector:@selector(setAdminParticipant:) name:kSetAdminParticipantNotifation object:nil];
    [nc addObserver:self selector:@selector(errorAuthorityChangedFailed_1248:) name:kNetCenterErrorAuthorityChangedFailed_1248 object:nil];
    
    
    
    /*
    NSString *title = nil;
    if ([_topicEntity.title length] > 0)
    {
        title = _topicEntity.title;
    }
    else if([_topicEntity.relateTeID length] > 0)
    {
        title = [ACUserDB getUserFromDBWithUserID:_topicEntity.relateChatUserID].name;
    }
    else
    {
        title = [ACUserDB getUserFromDBWithUserID:_topicEntity.singleChatUserID].name;
    }*/
    
 //
//    if (_topicEntity.perm.show == ACTopicPermission_ShowParticipants_Deny)
//    {
//
//    }
    
//    if (![ASIHTTPRequest isValidNetWork])
//    {
////        [_contentView showProgressHUDNoActivityWithLabelText:NSLocalizedString(@"Network_Failed", nil) withAfterDelayHide:1.2];
//    }
    
    if([_entity isKindOfClass:[ACUrlEntity class]]){
        _urlEntity_Temp =    (ACUrlEntity*)_entity;
    }
    else{
        _topicEntity_Temp    =   (ACTopicEntity*)_entity;
    }
    
    _activityView.hidden = YES; //暂不使用,隐藏它
    [self refreshMemberOrPerm]; //加载Member
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)didMoveToParentViewController:(UIViewController *)parent{
    [super didMoveToParentViewController:parent];
    int nHight =    self.view.bounds.size.height;
    [_membersCollectionView setFrame_height:nHight];
    [_activityView setFrame_y:(nHight-_activityView.size.height)/2];
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if(_bEditMembering){
        [self onMemberEdit:_header.groupEditButton];
    }
}

-(void)showMemberCount{
    _header.memberCountLable.text = [NSString stringWithFormat:NSLocalizedString(@"MemberCount", nil),@(_pSourceArray.count)];
}

-(void)refreshMemberOrPerm{
    //刷新信息
    if(![ASIHTTPRequest isValidNetWork]){
        [self.view showNetErrorHUD];
        return;
    }
    
    [self.view showNetLoadingWithAnimated:YES];
    [[ACNetCenter shareNetCenter] getParticipantInfoWithEntity:_entity];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark -- UICollectionViewDataSource

-(ACParticipant*) _getParticipantFromIndexPath:(NSIndexPath *)indexPath{
    if(_nShowAddMember){
        if(indexPath.row){
            return  _pSourceArray[indexPath.row-_nShowAddMember];
        }
    }
    else{
        return _pSourceArray[indexPath.row];
    }
    return nil;
}

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section{
    return _nShowAddMember+_pSourceArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    ACGroupInfoVCCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"ACGroupInfoVC__Cell_ID" forIndexPath:indexPath];
    ACParticipant *participant = [self _getParticipantFromIndexPath:indexPath];
 
    BOOL bDelButtonShow = NO;
    if(participant){
        cell.userNameLable.text = participant.name;
        cell.userNameLable.textColor = [UIColor blackColor];
        cell.userNameLable.font =   [UIFont systemFontOfSize:16];
        
//        UIImage* pDefImage = [UIImage imageNamed:@"personIcon100.png"];
        if(participantType_User==participant.type){
            [cell.userIconImageView setImageWithIconString:participant.icon placeholderImage:[UIImage imageNamed:@"icon_singlechat.png"] ImageType:ImageType_TopicEntity];
            if(participant.isAdmin){
                cell.userNameLable.textColor = [UIColor blueColor];
                cell.userNameLable.font =   [UIFont boldSystemFontOfSize:16];
            }
        }
        else{
            [cell.userIconImageView setImageWithIconString:participant.icon placeholderImage:[UIImage imageNamed:@"icon_groupchat.png"] ImageType:ImageType_TopicEntity];
        }
        
        
        if(_bEditMembering&&
           (!participant.isAdmin)&&
           (!participant.isMyself)&&
           (!participant.isJoinedUsersGroup)&&
           !(participantType_User==participant.type&& //自己
             participant.isMyself)){
            //判断是否是自己或Admin
            bDelButtonShow = YES;
        }
    }
    else{
        cell.buttonDel.hidden = YES;
        cell.userNameLable.text = @"";
        cell.userIconImageView.image = [UIImage imageNamed:@"gr_member_add_icon"];
    }
    
    cell.pSuperVC = self;
    [cell buttonDelShow:bDelButtonShow];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    
    if([kind isEqual:UICollectionElementKindSectionHeader]){
        
        _header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"ACGroupInfoVC__Header_ID" forIndexPath:indexPath];
        [self showMemberCount];
        _header.groupEditButton.hidden = !_canEditMember;
        [_header.groupEditButton addTarget:self action:@selector(onMemberEdit:) forControlEvents:UIControlEventTouchUpInside];
        return _header;
    }
    
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(self.view.frame.size.width, 50);
}


-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    ACParticipant *participant = [self _getParticipantFromIndexPath:indexPath];

    if(participant){
        if (participant.type == participantType_Group)
        {
            ACChooseContactViewController *chooseContactVC = [[ACChooseContactViewController alloc] init];
            AC_MEM_Alloc(chooseContactVC);
            chooseContactVC.addParticipant = ACAddParticipantType_New;
            chooseContactVC.chooseContactType = ChooseContactType_ParticipantGroup;
            chooseContactVC.groupID = participant.userid;
//            chooseContactVC.singleChatCurrentUserID = _topicEntity.singleChatUserID;
            chooseContactVC.name = participant.name;
            chooseContactVC.isForJoinedUsersGroup = participant.isJoinedUsersGroup;
            [self.navigationController pushViewController:chooseContactVC animated:YES];
            return;
        }
        
        if(_topicEntity_Temp&&_topicEntity_Temp.topicPerm.profile != ACTopicPermission_ParticipantProfile_Allow){
            return;
        }
        
        ACParticipantInfoViewController *participantInfoVC = [[ACParticipantInfoViewController alloc] initWithUser:participant];
        participantInfoVC.topicEntity = _topicEntity_Temp;
        AC_MEM_Alloc(participantInfoVC);
        [self.navigationController pushViewController:participantInfoVC animated:YES];
        return;
    }
    
    //添加
    ACChooseContactViewController *chooseContactVC = [[ACChooseContactViewController alloc] init];
    AC_MEM_Alloc(chooseContactVC);
    chooseContactVC.cancelToViewController = _superVC;
    chooseContactVC.chooseContactType = ChooseContactType_Root;
    chooseContactVC.addParticipant = ACAddParticipantType_AddToCurrent;
//    chooseContactVC.addPaticipantGroupID = _entity.entityID;
    chooseContactVC.addPaticipantEntity =   _entity;
    if(_topicEntity_Temp){
        if(ACPerm_Topic_ADDPARTICIPANTS_TONEWGROUP==_topicEntity_Temp.topicPerm.addParticipants){
            chooseContactVC.addParticipant = ACAddParticipantType_SingleChatAddToNew;
        }
        chooseContactVC.singleChatCurrentUserID = _topicEntity_Temp.singleChatUserID;
    }
    [self.navigationController pushViewController:chooseContactVC animated:YES];
}

#pragma mark -notification

-(void)errorAuthorityChangedFailed_1248:(NSNotification *)noti{
     [self refreshMemberOrPerm];
}

-(void)addParticipant:(NSNotification *)noti{    //添加成功暂时先重新刷一下列表
    [self refreshMemberOrPerm];
}

-(void)setAdminParticipant:(NSNotification *)noti{
    [self refreshMemberOrPerm];
}


-(void)getParticipantInfo:(NSNotification *)noti{
//    NSString* pPermStringOld = _entity.permString;
    NSDictionary* pDicts = [noti.object objectForKey:_entity.dictFieldName];
    [self.view hideProgressHUDWithAnimated:YES];
    if(![_entity.entityID isEqualToString:pDicts[@"id"]]){
        return;
    }
    
    //更新Topic信息
    [_entity updateWithDict:pDicts];
    
    _nShowAddMember = 0;
    
    if(_entity.perm.canViewParticipants){
         //是否可显示参与者列表
        _pSourceArray = [ACParticipant participantArraySort:[ACParticipant participantArrayWithDicArray:pDicts[@"participants"]]
                                               withAdminIDS:pDicts[@"adminUserIds"]];
        
        if(_entity.perm.canAddParticipants){
            //是否可添加参与者
            _nShowAddMember = 1;
        }
        else if(_topicEntity_Temp&&
                ACPerm_Topic_ADDPARTICIPANTS_TONEWGROUP==_topicEntity_Temp.topicPerm.addParticipants){
            _nShowAddMember = 1;
        }
        
        //删除参与者
        _canEditMember  = _entity.perm.canDelParticipants;
        
        if(_header){
            [self showMemberCount];
            _header.groupEditButton.hidden = !_canEditMember;
        }
        if(!_canEditMember){
            _bEditMembering = NO;
        }
        _bYou_can_not_see_other_users_in_this_session_Showed = NO;
    }
    else{
        _bEditMembering =   NO;
        _pSourceArray   =   nil;
        if(_header){
            _header.groupEditButton.hidden  =   YES;
            _header.memberCountLable.hidden =   YES;
        }
        
        if(!_bYou_can_not_see_other_users_in_this_session_Showed){
            AC_ShowTip(NSLocalizedString(@"You can not see other users in this session.",nil));
            _bYou_can_not_see_other_users_in_this_session_Showed = YES;
        }
    }
    
    if(_membersCollectionView.hidden){
//        [_activityView stopAnimating];
//        _activityView.hidden = YES;
        _membersCollectionView.hidden = NO;
    }
    
    [_membersCollectionView reloadData];
}


#pragma mark --Action
-(void)onMemberEdit:(UIButton*)pButton{
    _bEditMembering = !_bEditMembering;
    [pButton setTitle:_bEditMembering?NSLocalizedString(@"MemberEditEnd",nil):NSLocalizedString(@"MemberEdit", nil) forState:UIControlStateNormal];
    [_membersCollectionView reloadData];
}

-(void)deleteCell:(UICollectionViewCell*)pCell{
    
    NSIndexPath* indexPath = [_membersCollectionView indexPathForCell:pCell];
    if(nil==indexPath){
        return;
    }
    
    ACParticipant *participant = [self _getParticipantFromIndexPath:indexPath];
    
    [self.view showNetLoadingWithAnimated:NO];
    
    wself_define();
    callURL_block pCallURL_Block = ^(ASIHTTPRequest *request, BOOL bIsFail) {
   
        [wself.view hideProgressHUDWithAnimated:NO];
        if(!bIsFail){
            NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
            ITLog(responseDic);
            int nErrorCode = [[responseDic objectForKey:kCode] intValue];
            if(ResponseCodeType_Nomal==nErrorCode){
                sself_define();
                if(sself){
                    [sself->_pSourceArray removeObjectAtIndex:indexPath.row-sself->_nShowAddMember];
                    [sself->_membersCollectionView  deleteItemsAtIndexPaths:@[indexPath]];
                    [wself showMemberCount];
                }
            }
            else if(ResponseCodeType_ERROR_AUTHORITYCHANGED_FAILED==nErrorCode){
                [ACNetCenter ERROR_AUTHORITYCHANGED_FAILED_Error_Func:responseDic];
            }
        }
    };
    
    if(_topicEntity_Temp){
        NSString* pURL = [NSString stringWithFormat:@"%@/participant/%@/%@",_entity.requestUrl,
                          participantType_User==participant.type?@"user":@"usergroup",
                          participant.userid];
        
        [ACNetCenter callURL:pURL forMethodDelete:YES withBlock:pCallURL_Block];
        return;
    }
    
    NSDictionary *postDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:_entity.mpType,@"type",@[participant.userid],participantType_User==participant.type?@"ru":@"rug", nil];
    [ACNetCenter callURL:_entity.requestUrl forPut:NO withPostData:postDic withBlock:pCallURL_Block];
    
}



@end

