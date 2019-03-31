//
//  ACCreateChatGroupViewController.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-8.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACCreateChatGroupViewController.h"
#import "ACNetCenter.h"
#import "ACEntity.h"
#import "ACChooseContactViewController.h"
#import "UINavigationController+Additions.h"
#import "ACChatMessageViewController.h"
#import "ACConfigs.h"
#import "UIView+Additions.h"
#import "ACTransmitViewController.h"
#import "ACUser.h"

static NSString *kheader = @"menuSectionHeader";
static NSString *ksubSection = @"menuSubSection";

@interface ACCreateChatGroupViewController (){
    __weak  NSArray     *_selectedUserGroupArray;
    __weak  NSArray     *_selectedUserArray;
    NSString    *_createTitle;
    int         _addParticipant;
}

@end

@implementation ACCreateChatGroupViewController


AC_MEM_Dealloc_implementation


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)prepareSelectedUsers:(NSArray*) selectedUserArray
              andUserGroups:(NSArray*)selectedUserGroupArray
         withAddParticipant:(int)addParticipant{
    _selectedUserGroupArray =   selectedUserGroupArray;
    _selectedUserArray      =   selectedUserArray;
    _addParticipant         =   addParticipant; //好像没有使用
    
    int count = 0;
    int currentCount = (int)([_selectedUserGroupArray count]+[_selectedUserArray count]);
    int maxCount = currentCount>2?2:currentCount;
    NSString *placeholder = @"";
    for (ACUserGroup *userGroup in _selectedUserGroupArray)
    {
        placeholder = [placeholder stringByAppendingString:userGroup.name];
        count++;
        if (count == maxCount)
        {
            if (currentCount > 2)
            {
                placeholder = [placeholder stringByAppendingString:@"..."];
            }
            break;
        }
        else
        {
            placeholder = [placeholder stringByAppendingString:@","];
        }
    }
    if (count < maxCount)
    {
        for (ACUser *user in _selectedUserArray)
        {
            placeholder = [placeholder stringByAppendingFormat:@"%@",user.name];
            count++;
            if (count == maxCount)
            {
                if (currentCount > 2)
                {
                    placeholder = [placeholder stringByAppendingString:@"..."];
                }
                break;
            }
            else
            {
                placeholder = [placeholder stringByAppendingString:@","];
            }
        }
    }
    _createTitle =  placeholder;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recvCreateGroupSucc:) name:kNetCenterCreateGroupChatNotifation object:nil];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
    _titleLabel.text= NSLocalizedString(@"Create Chat Room", nil);
    _nomalLable.text = NSLocalizedString(@"Normal chat", nil);
    _secretChatLable.text= NSLocalizedString(@"Secret chat", nil);
    _broadcasetLable.text= NSLocalizedString(@"Broadcast", nil);
    _dontAllowIndividualChatLable.text= NSLocalizedString(@"Do not allow individual chat", nil);
    _allowReplyToBoradcastLable.text = NSLocalizedString(@"Allow reply to broadcast", nil);
    
    _displayLocationLable.text= NSLocalizedString(@"Display Location", nil);
    
    
//    self.placeholder = [_superVC getDefaultGroupTitle];
    
    _groupNameTextField.placeholder = _createTitle;
    

    [_createButton setNomalText:NSLocalizedString(@"Create", nil)];
//    [_backButton setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateNormal];
    
    if (![ACConfigs isPhone5])
    {
        [_contentView setFrame_height:_contentView.size.height-88];
    }
    [self popTableInit];
    _selectType = sectionType_Normal;
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self initHotspot];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initHotspot];
}

-(void)popTableInit
{
//    NSArray *sucSectionsA = [NSArray arrayWithObjects:@"Don't allow free chat in members",@"Display Location", nil];
//    NSArray *sucSectionsB = [NSArray arrayWithObjects:@"Don't allow free chat in members",@"Display Location", nil];
//    NSArray *sucSectionsC = [NSArray arrayWithObjects:@"Don't allow free chat in members", nil];
//    
//    NSDictionary *sectionA = [NSDictionary dictionaryWithObjectsAndKeys:
//                              @"Normal", kheader,
//                              sucSectionsA, ksubSection,
//                              nil];
//    
//    NSDictionary *sectionB = [NSDictionary dictionaryWithObjectsAndKeys:
//                              @"Destruct", kheader,
//                              sucSectionsB, ksubSection,
//                              nil];
//    
//    NSDictionary *sectionC = [NSDictionary dictionaryWithObjectsAndKeys:
//                              @"Boardcast", kheader,
//                              sucSectionsC, ksubSection,
//                              nil];
//    
//    NSArray *menu = [NSArray arrayWithObjects:sectionA,sectionB,sectionC, nil];
//    _popdTableView.popdDelegate = self;
//    [_popdTableView setMenuSections:menu];
//    [_popdTableView.layer setCornerRadius:5.0];
//    [_popdTableView.layer setMasksToBounds:YES];
}

//#pragma mark -POPDDelegate
//-(void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    
//}

-(void)recvCreateGroupSucc:(NSNotification *)noti
{
    if ([ACNetCenter shareNetCenter].createTopicEntityVC == self)
    {
        if (_transmitVC != nil)
        {
            [self.navigationController ACpopToViewController:_transmitVC animated:YES];
        }
        else
        {
            [_contentView hideProgressHUDWithAnimated:NO];
            ACChatMessageViewController *chatMessageVC = [[ACChatMessageViewController alloc] initWithSuperVC:self withTopicEntity: noti.object];
//            chatMessageVC.topicEntity = noti.object;
//            [chatMessageVC preloadDB];
            AC_MEM_Alloc(chatMessageVC);
            UINavigationController *navC = self.navigationController;
            [navC ACpopToRootViewControllerAnimated:NO];
            [navC pushViewController:chatMessageVC animated:YES];
        }
    }
}


-(void)resetButtonUnselected
{
    switch (_selectType)
    {
        case sectionType_Normal:
        {
            [_normalSelectButton setSelected:YES];
            [_destructSelectButton setSelected:NO];
            [_boardcastSelectButton setSelected:NO];
        }
            break;
        case sectionType_Destruct:
        {
            [_normalSelectButton setSelected:NO];
            [_destructSelectButton setSelected:YES];
            [_boardcastSelectButton setSelected:NO];
        }
            break;
        case sectionType_Boardcast:
        {
            [_normalSelectButton setSelected:NO];
            [_destructSelectButton setSelected:NO];
            [_boardcastSelectButton setSelected:YES];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark -IBAction
-(IBAction)freeChatButtonTouchUp:(id)sender
{
    [_freeChatSelectButton setSelected:!_freeChatSelectButton.selected];
}

-(IBAction)displayLocationButtonTouchUp:(id)sender
{
    [_displayLocationSelectButton setSelected:!_displayLocationSelectButton.selected];
}

-(IBAction)freeChatSelectButtonTouchUp:(id)sender
{
    [_freeChatSelectButton setSelected:!_freeChatSelectButton.selected];
}

-(IBAction)displayLocationSelectButton:(id)sender
{
    [_displayLocationSelectButton setSelected:!_displayLocationSelectButton.selected];
}

-(IBAction)allowReplyToBoardcastButton:(id)sender
{
    [_replyBoardcastSelectButton setSelected:!_replyBoardcastSelectButton.selected];
}

-(IBAction)normalButtonTouchUp:(UIButton *)sender
{
    
//    [sender setBackgroundColor:CELLSELECTED];
    _selectType = sectionType_Normal;
    [self resetButtonUnselected];
    _normalMultiView.hidden = NO;
    _boardcastMultiView.hidden = YES;
}

-(IBAction)destructButtonTouchUp:(UIButton *)sender
{
    
//    [sender setBackgroundColor:CELLSELECTED];
    _selectType = sectionType_Destruct;
    [self resetButtonUnselected];
    _normalMultiView.hidden = NO;
    _boardcastMultiView.hidden = YES;
}

-(IBAction)boardcaseButtonTouchUp:(UIButton *)sender
{
//    [sender setBackgroundColor:CELLSELECTED];
    _selectType = sectionType_Boardcast;
    [self resetButtonUnselected];
    _normalMultiView.hidden = YES;
    _boardcastMultiView.hidden = NO;
}

-(void)_createTopicEntity:(BOOL)vcShowed{
    
    NSDictionary *exMap = nil;
    NSString *title = nil;
    if(vcShowed){
        title = [_groupNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
        [_contentView showNetLoadingWithAnimated:NO];
        //    [_contentView showProgressHUDWithLabelText:nil withAnimated:NO];
        if (title.length == 0){
            title = _createTitle; //_placeholder;
        }
        [ACNetCenter shareNetCenter].createTopicEntityVC = self;
    }
    else{
        [ACNetCenter shareNetCenter].createTopicEntityVC = nil;
        title   =   _createTitle; //[_superVC getDefaultGroupTitle];
    }
    
    {
        BOOL allowBroadcast = NO,allowDelete = NO,allowDestruct = NO,allowLocation = NO,/*allowReplyAdmin = NO,*/allowUserInfo = NO,allowDismiss = NO,allowChat = NO,allowParticipant = YES;
        
        
        
        //    NSArray *popdSelectedArray = [_popdTableView.selectedIndexDic allKeys];
        //    NSInteger section = 0;
        //    NSInteger row = 0;
        //
        //    if ([popdSelectedArray count] == 0)
        //    {
        //        for (int i = 0; i < [_popdTableView.showingArray count]; i++)
        //        {
        //            BOOL bo = [[_popdTableView.showingArray objectAtIndex:i] boolValue];
        //            if (bo)
        //            {
        //                section = i;
        //                break;
        //            }
        //        }
        //    }
        //    else
        //    {
        //        section = ((NSIndexPath *)[popdSelectedArray lastObject]).section;
        //        row = ((NSIndexPath *)[popdSelectedArray lastObject]).row;
        //    }
        
        if(vcShowed){
            if (_selectType == sectionType_Boardcast)
            {
                allowChat = _replyBoardcastSelectButton.selected;
            }
            else
            {
                allowChat = !_freeChatSelectButton.selected;
                allowLocation = _displayLocationSelectButton.selected;
            }
            
            switch (_selectType)
            {
                case sectionType_Destruct:
                {
                    allowDestruct = YES;
                }
                    break;
                case sectionType_Boardcast:
                {
                    allowBroadcast = YES;
                }
                    break;
                    
                default:
                    break;
            }
        }
        exMap = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithBool:allowBroadcast],@"allowBroadcast",
                               [NSNumber numberWithBool:allowDelete],@"allowDelete",
                               [NSNumber numberWithBool:allowLocation],@"allowLocation",
                               [NSNumber numberWithBool:allowUserInfo],@"allowUserInfo",
                               [NSNumber numberWithBool:allowParticipant],@"allowParticipant",
                               [NSNumber numberWithBool:allowChat],@"allowChat",
                               [NSNumber numberWithBool:allowDismiss],@"allowDismiss",
                               [NSNumber numberWithBool:allowDestruct],@"allowDestruct",
                               nil];
    }
    
    NSMutableArray *selectedUserArray = [NSMutableArray arrayWithCapacity:[_selectedUserArray count]];
    for (ACUser *user in _selectedUserArray){
        [selectedUserArray addObject:user.userid];
    }
    
    NSMutableArray *selectedUserGroupArray = [NSMutableArray arrayWithCapacity:[_selectedUserGroupArray count]];
    for (ACUserGroup *userGroup in _selectedUserGroupArray){
        [selectedUserGroupArray addObject:userGroup.groupID];
    }
    
    [[ACNetCenter shareNetCenter] createTopicEntityWithChatType:cAdminChat
                                                      withTitle:title
                                               withGroupIDArray:selectedUserGroupArray
                                                withUserIDArray:selectedUserArray
                                                          exMap:exMap];

}


-(void)createTopicEntityWithNoShowVC{
    [self _createTopicEntity:NO];
}

-(IBAction)create:(id)sender
{
    [self _createTopicEntity:YES];
}

-(IBAction)goback:(id)sender
{
    [self.navigationController ACpopViewControllerAnimated:YES];
}

#pragma mark -textFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
