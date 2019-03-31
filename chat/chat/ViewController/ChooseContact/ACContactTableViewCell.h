//
//  ACContactTableViewCell.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-4.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACUser.h"

enum ContactCellType
{
    ContactCellType_UserGroup,
    ContactCellType_User,
};

@class ACChooseContactViewController;
@class ACSetAdminViewController;
@interface ACContactTableViewCell : UITableViewCell
{
    __weak IBOutlet UIButton       *_selectedButton;
    __weak IBOutlet UIImageView    *_iconImageView;
    __weak IBOutlet UILabel        *_nameLabel;
    __weak IBOutlet UIImageView    *_moreImageView;
    __weak ACChooseContactViewController *_superVC_forChooseContact;
    __weak ACSetAdminViewController*   _superVC_forSetAdmin;
    enum ContactCellType    _type;
    __weak IBOutlet UIImageView    *_roundedCornerImageView;
}

@property (nonatomic,strong) ACUserGroup    *userGroup1;
@property (nonatomic,strong) ACUser         *user1;

-(void)setUser:(ACUser *)user For_ParticipantGroup:(BOOL)b_ParticipantGroup;

-(void)setUserGroup:(ACUserGroup *)userGroup For_ParticipantGroup:(BOOL)b_ParticipantGroup;

-(void)setSuperVC_forChooseContact:(ACChooseContactViewController *)superVC;
-(void)setSuperVC_forSetAdmin:(ACSetAdminViewController *)superVC;

//-(void)setContactSelected:(BOOL)selected;

//点击选中状态取反
-(void)setContactSelected;

-(void)setPreview;

@end
