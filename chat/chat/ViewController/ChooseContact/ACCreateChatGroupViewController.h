//
//  ACCreateChatGroupViewController.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-8.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "POPDTableView.h"

enum sectionType
{
    sectionType_Normal,
    sectionType_Destruct,
    sectionType_Boardcast,
};

enum rowType
{
    rowType_NotAllow = 1,
    rowType_DisplayLocation,
};

@class ACChooseContactViewController;
@class ACTransmitViewController;
@interface ACCreateChatGroupViewController : UIViewController<UITextFieldDelegate>
{
    __weak IBOutlet UITextField    *_groupNameTextField;
    
    __weak IBOutlet UILabel        *_titleLabel;
    
    __weak IBOutlet UIButton       *_createButton;
    __weak IBOutlet UIButton       *_backButton;
    __weak IBOutlet UIView         *_contentView;
//    IBOutlet POPDTableView  *_popdTableView;
    
    __weak IBOutlet UIButton       *_freeChatButton;
    __weak IBOutlet UIButton       *_freeChatSelectButton;
    __weak IBOutlet UIButton       *_displayLocationButton;
    __weak IBOutlet UIButton       *_displayLocationSelectButton;
    
    __weak IBOutlet UIButton       *_replyBoardcastButton;
    __weak IBOutlet UIButton       *_replyBoardcastSelectButton;
    
    __weak IBOutlet UIButton       *_normalButton;
    __weak IBOutlet UIButton       *_normalSelectButton;
    __weak IBOutlet UIButton       *_destructButton;
    __weak IBOutlet UIButton       *_destructSelectButton;
    __weak IBOutlet UIButton       *_boardcastButton;
    __weak IBOutlet UIButton       *_boardcastSelectButton;
    enum sectionType        _selectType;
    __weak IBOutlet UIView         *_normalMultiView;
    __weak IBOutlet UIView         *_boardcastMultiView;
    
    __weak IBOutlet UILabel *_nomalLable;
    __weak IBOutlet UILabel *_secretChatLable;
    __weak IBOutlet UILabel *_broadcasetLable;
    __weak IBOutlet UILabel *_dontAllowIndividualChatLable;
    
    __weak IBOutlet UILabel *_allowReplyToBoradcastLable;
    __weak IBOutlet UILabel *_displayLocationLable;
}

//@property (nonatomic,weak) ACChooseContactViewController *superVC;

@property (nonatomic,weak) ACTransmitViewController      *transmitVC;
@property (nonatomic) BOOL                      isOpenHotspot;
//@property (nonatomic,strong) NSString           *placeholder;

-(void)prepareSelectedUsers:(NSArray*) selectedUserArray
              andUserGroups:(NSArray*)selectedUserGroupArray
         withAddParticipant:(int)addParticipant;
-(void)createTopicEntityWithNoShowVC; //不显示ACCreateChatGroupViewController的状态下创建对话

@end
