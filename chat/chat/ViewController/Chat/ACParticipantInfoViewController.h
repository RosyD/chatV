//
//  ACParticipantInfoViewController.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-22.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACUser.h"
#import "ACEntity.h"


#define User_MoreProfile_Y_Delta     8   //间隔
#define User_MoreProfile_Name_X      10
#define User_MoreProfile_Name_Width  70
#define User_MoreProfile_Item_X      (User_MoreProfile_Name_X+User_MoreProfile_Name_Width+5)

@interface ACParticipantInfoViewController : UIViewController
{
    __weak IBOutlet UIScrollView       *_contentView;

    //Icon Name
    __weak IBOutlet UIView             *_iconNameView;
    __weak IBOutlet UIButton           *_iconNameButton;
    __weak IBOutlet UIImageView        *_iconImageView;
    __weak IBOutlet UILabel            *_nameLabel;
    __weak IBOutlet UILabel            *_accountLabel;
    __weak IBOutlet UIImageView *_moreProfileImageView;
    



    __weak IBOutlet UIButton           *_backButton;
    __weak IBOutlet UIButton           *_sendMessageButton;

    __weak IBOutlet UILabel *_titleLable;
}

@property (nonatomic,strong) ACUser         *user;
@property (nonatomic,strong) ACTopicEntity  *topicEntity;
@property (nonatomic) BOOL                  isOpenHotspot;

- (instancetype)initWithUserID:(NSString *)userID;
- (instancetype)initWithUser:(ACUser *)user;

//取得用户信息的标题
+(NSString*)userProfileTitleWithItem:(NSString*)pItemName;
+(void)loadUser:(NSString*)pUsrID ProfileFromView:(UIViewController*)pVC withBlock:(void (^)(NSDictionary* pUserProInfo)) pFunc;
//加载用户信息 pFunc(nil)表示失败


@end
