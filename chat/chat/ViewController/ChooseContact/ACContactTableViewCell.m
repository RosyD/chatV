//
//  ACContactTableViewCell.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-4.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACContactTableViewCell.h"
#import "ACUser.h"
#import "UIImageView+WebCache.h"
#import "ACChooseContactViewController.h"
#import "UIView+Additions.h"
#import "ACParticipantInfoViewController.h"
#import "ACSetAdminViewController.h"
#import "ACParticipant.h"

@implementation ACContactTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
//    [_iconImageView.layer setCornerRadius:5.0];
//    [_iconImageView.layer setMasksToBounds:YES];
    [_iconImageView setToCircle];
}

-(void)setUserGroup:(ACUserGroup *)userGroup  For_ParticipantGroup:(BOOL)b_ParticipantGroup
{
    _type = ContactCellType_UserGroup;
    self.userGroup1 = userGroup;
    self.user1 = nil;
    _nameLabel.text = userGroup.name;
    [_nameLabel setFrame_width:180];
    
    UIImage *pPlaceholderImage = nil;
    BOOL    bSelectHiden = NO;
    if(userGroup.cr){
        bSelectHiden = YES;
        pPlaceholderImage   =   [UIImage imageNamed:@"Handshake.png"];
    }
    else{
        bSelectHiden = NO;
        pPlaceholderImage   =   [UIImage imageNamed:@"icon_groupchat.png"];
    }
    
    [_iconImageView setImageWithIconString:userGroup.icon placeholderImage:pPlaceholderImage ImageType:ImageType_TopicEntity];
    [_moreImageView setHidden:NO];
//    [_roundedCornerImageView setHidden:YES];
    //设置是否选中
    if(!b_ParticipantGroup){
        _selectedButton.hidden = bSelectHiden;
        [self setLoadSelect];
    }
//    [self setContactSelected:[_superVC.selectedUserGroupArray containsObject:_userGroup1]];
}

-(void)setUser:(ACUser *)user  For_ParticipantGroup:(BOOL)b_ParticipantGroup
{
    _type = ContactCellType_User;
    self.user1 = user;
    self.userGroup1 = nil;
    _nameLabel.text = user.name;
    [_nameLabel setFrame_width:210];
    [_iconImageView setImageWithIconString:user.icon placeholderImage:[UIImage imageNamed:@"icon_singlechat.png"] ImageType:ImageType_TopicEntity];
    [_moreImageView setHidden:YES];
    
    if(!b_ParticipantGroup){
        _selectedButton.hidden = NO;
        //设置是否选中
        [self setLoadSelect];
    }
    
    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userIconImageViewTap:)];
    _iconImageView.userInteractionEnabled = YES;
    [_iconImageView addGestureRecognizer:tap2];
//    [_roundedCornerImageView setHidden:NO];
//    [self setContactSelected:[_superVC.selectedUserArray containsObject:_user1]];
}

-(void)setPreview
{
    [_selectedButton setHidden:YES];
    [_iconImageView setFrame_x:_iconImageView.origin.x-20];
    [_nameLabel setFrame_x:_nameLabel.origin.x-20];
    [_nameLabel setFrame_width:180];
    if (!_roundedCornerImageView.hidden)
    {
        [_roundedCornerImageView setFrame:_iconImageView.frame];
    }
}

-(void)setSuperVC_forChooseContact:(ACChooseContactViewController *)superVC{
    _superVC_forChooseContact = superVC;
}
-(void)setSuperVC_forSetAdmin:(ACSetAdminViewController *)superVC{
    _superVC_forSetAdmin = superVC;
}

//点击选中状态取反
-(void)setContactSelected
{
    if(_superVC_forChooseContact){
    
        if (_userGroup1)
        {
            ACUserGroup *tmp = nil;
            for (ACUserGroup *userGroup in _superVC_forChooseContact.selectedUserGroupArray)
            {
                if ([userGroup.groupID isEqualToString:_userGroup1.groupID])
                {
                    tmp = userGroup;
                    break;
                }
            }
            if (tmp)
            {
                [_superVC_forChooseContact.selectedUserGroupArray removeObject:tmp];
            }
            else
            {
                [_superVC_forChooseContact.selectedUserGroupArray addObject:_userGroup1];
            }
            _selectedButton.selected = (tmp == nil);
        }
        else if (_user1)
        {
            if(_user1.isMyself){
                [ACUtility ShowTip:NSLocalizedString(@"You can not chat with yourself.", nil) withTitle:nil];
                return;
            }

            ACUser *tmp = nil;
            for (ACUser *user in _superVC_forChooseContact.selectedUserArray)
            {
                if ([user.userid isEqualToString:_user1.userid])
                {
                    tmp = user;
                    break;
                }
            }
            if (tmp)
            {
                [_superVC_forChooseContact.selectedUserArray removeObject:tmp];
            }
            else
            {
                [_superVC_forChooseContact.selectedUserArray addObject:_user1];
            }
            _selectedButton.selected = (tmp == nil);
        }
    }
    else if(_superVC_forSetAdmin){
        ACParticipant* pUser = (ACParticipant*)_user1;
        if(pUser.isAdmin&&pUser.isMyself){
            [ACUtility ShowTip:NSLocalizedString(@"You can not cancel the authority by yourself.", nil) withTitle:nil];
            return;
        }
        pUser.isAdmin = !pUser.isAdmin;
        _selectedButton.selected = pUser.isAdmin;
    }
}

//load选中状态
-(void)setLoadSelect
{
    if(_superVC_forChooseContact){
        if (_userGroup1)
        {
            ACUserGroup *tmp = nil;
            for (ACUserGroup *userGroup in _superVC_forChooseContact.selectedUserGroupArray)
            {
                if ([userGroup.groupID isEqualToString:_userGroup1.groupID])
                {
                    tmp = userGroup;
                    break;
                }
            }
            _selectedButton.selected = !(tmp == nil);
        }
        else if (_user1)
        {
            ACUser *tmp = nil;
            for (ACUser *user in _superVC_forChooseContact.selectedUserArray)
            {
                if ([user.userid isEqualToString:_user1.userid])
                {
                    tmp = user;
                    break;
                }
            }
            _selectedButton.selected = !(tmp == nil);
        }
    }
    else if(_superVC_forSetAdmin){
        _selectedButton.selected = ((ACParticipant*)_user1).isAdmin;
    }
}

-(IBAction)selectButonTouchUp:(id)sender
{
    [self setContactSelected];
    if(_superVC_forChooseContact){
        [_superVC_forChooseContact selectedCountUpdate];
    }
}


-(void)userIconImageViewTap:(UITapGestureRecognizer *)tap
{
    ACParticipantInfoViewController *participantInfoVC = [[ACParticipantInfoViewController alloc] initWithUser:_user1];
    UIViewController* pSuperVC = _superVC_forChooseContact?_superVC_forChooseContact:_superVC_forSetAdmin;
    AC_MEM_Alloc(participantInfoVC);
    [pSuperVC.navigationController pushViewController:participantInfoVC animated:YES];
}

@end
