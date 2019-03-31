//
//  ACTransmitViewController.m
//  AcuCom
//
//  Created by 王方帅 on 14-5-20.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACTransmitViewController.h"
//#import "ACTransmitTableViewCell.h"
#import "ACEntity.h"
#import "ACChatNetCenter.h"
#import "ACNetCenter.h"
#import "ACChatMessageViewController.h"
#import "ACDataCenter.h"
#import "UINavigationController+Additions.h"
#import "ACChooseContactViewController.h"
#import "ACUser.h"
#import "ACUserDB.h"
#import "UIView+Additions.h"
#import "ACChatMessageViewController+Board.h"
#import "ACEntityCell.h"

#define kAlertTag   43538

@interface ACTransmitViewController ()

@end

@implementation ACTransmitViewController

AC_MEM_Dealloc_implementation


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


+(instancetype) newForTransimitMessages:(NSArray*)pMsgs{
    ACTransmitViewController* pRet = [[ACTransmitViewController alloc] init];
    AC_MEM_Alloc(pRet);
    pRet->_transmitMessages_Or_sendFilePaths = pMsgs;
    pRet->_viewType = ACTransmitViewController_For_Transmit;
    return pRet;
}
+(instancetype) newForVideoCall:(BOOL)bForVideoCall withSuperVC:(UIViewController*)superVC{
    ACTransmitViewController *transmitVC = [[ACTransmitViewController alloc] init];
    AC_MEM_Alloc(transmitVC);
    transmitVC->_viewType    =  bForVideoCall?ACTransmitViewController_For_VideoCall:ACTransmitViewController_For_AudioCall;
    transmitVC->_superVCForVideoCall =  superVC;
    return transmitVC;
}

+(instancetype) newForSendFiles:(NSArray*)filePaths{
    ACTransmitViewController* pRet = [[ACTransmitViewController alloc] init];
    AC_MEM_Alloc(pRet);
    pRet->_transmitMessages_Or_sendFilePaths       =   filePaths;
    pRet->_viewType   =  ACTransmitViewController_For_SendFile;
    return pRet;
}

-(BOOL)isForVideoAudioCall{
    return ACTransmitViewController_For_VideoCall==_viewType||
    ACTransmitViewController_For_AudioCall==_viewType;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _dataSourceArray = [NSMutableArray array];
    for (int i = 0; i < [[ACDataCenter shareDataCenter].topicEntityArray count]; i++)
    {
        ACTopicEntity *topicEntity = [[ACDataCenter shareDataCenter].topicEntityArray objectAtIndex:i];
        if (topicEntity.topicPerm.reply != ACTopicPermission_Reply_Deny)
        {
            [_dataSourceArray addObject:topicEntity];
        }
    }
    
    if (![ACConfigs isPhone5])
    {
        [_mainTableView setFrame_height:_mainTableView.size.height-88];
    }
    
    _mainTableView.tableHeaderView = _tableHeaderView;
    
    {
        NSString* pTitle = nil;
        if(ACTransmitViewController_For_Transmit==_viewType){
            pTitle  =   NSLocalizedString(@"Forward", nil);
        }
        else if(ACTransmitViewController_For_VideoCall==_viewType){
            pTitle  =   NSLocalizedString(@"Video Call", nil);
        }
        else if(ACTransmitViewController_For_AudioCall==_viewType){
            pTitle  =   NSLocalizedString(@"Audio Call", nil);
        }
        else if(ACTransmitViewController_For_SendFile==_viewType){
            pTitle  =   NSLocalizedString(@"Send File", nil);
        }
        _titleLabel.text =  pTitle;
    }

    _nearestLabel.text = NSLocalizedString(@"Recent chats", nil);
    [_createNewChatButton setTitle:NSLocalizedString(@"Create_New_Chat", nil) forState:UIControlStateNormal];
//    [_gobackButton setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateNormal];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(createGroupSucc:) name:kNetCenterCreateGroupChatNotifation object:nil];
    [nc addObserver:self selector:@selector(UpdateTopicEntityInfo:) name:kNetCenterUpdateTopicEntityInfoNotifation object:nil];
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
    _isHadTransmit = NO;
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

#pragma mark -Notification
-(void)hotspotStateChange:(NSNotification *)noti
{
    if (_isOpenHotspot)
    {
        [_mainTableView setFrame_height:_mainTableView.size.height-hotsoptHeight];
    }
    else
    {
        [_mainTableView setFrame_height:_mainTableView.size.height+hotsoptHeight];
    }
}

-(void)createGroupSucc:(NSNotification *)noti
{
    ACTopicEntity *topicEntity = noti.object;
    if(self.isForVideoAudioCall){
        //处理Call
        [self.navigationController ACpopToRootViewControllerAnimated:YES];
        [ACChatMessageViewController callTopic:topicEntity
                                  forVideoCall:ACTransmitViewController_For_VideoCall==_viewType
                          withParentController:_superVCForVideoCall];
        return;
    }
    
    _selectTopicEntity = topicEntity;
    [self showAlertTransmitToTopicEntity:topicEntity];
    [_mainTableView reloadData];
}

-(void)UpdateTopicEntityInfo:(NSNotification *)noti
{
    [_mainTableView reloadData];
}

#pragma mark -IBAction
-(IBAction)goback:(id)sender
{
    [self.navigationController ACpopViewControllerAnimated:YES];
}

-(IBAction)createNewChat:(id)sender
{
    ACChooseContactViewController *chooseContactVC = [[ACChooseContactViewController alloc] init];
    AC_MEM_Alloc(chooseContactVC);
    chooseContactVC.cancelToViewController = self;
    chooseContactVC.chooseContactType = ChooseContactType_Root;
    chooseContactVC.addParticipant = ACAddParticipantType_New;
    chooseContactVC.transmitVC = self;
    [chooseContactVC setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:chooseContactVC animated:YES];
}

-(void)showAlertTransmitToTopicEntity:(ACTopicEntity *)topicEntity
{
    if (!_isHadTransmit)
    {
        _isHadTransmit = YES;
    }
    else
    {
        return;
    }
    
    NSString *transmit = nil;
    if ([topicEntity.title length] > 0)
    {
        transmit = topicEntity.title;
    }
    else if([topicEntity.relateTeID length] > 0)
    {
        ACUser *user = [ACUserDB getUserFromDBWithUserID:topicEntity.relateChatUserID];
        transmit = user.name;
    }
    else
    {
        ACUser *user = [ACUserDB getUserFromDBWithUserID:topicEntity.singleChatUserID];
        transmit = user.name;
    }
    
    
    NSString* pTitle = nil;
    if(ACTransmitViewController_For_VideoCall==_viewType||
            ACTransmitViewController_For_AudioCall==_viewType){
        pTitle  =   NSLocalizedString(@"Call To", nil);
    }
    else if(ACTransmitViewController_For_SendFile==_viewType){
        pTitle  =   NSLocalizedString(@"Send To", nil);
    }
    else{
//        if(ACTransmitViewController_For_Transmit==_viewType){
        pTitle  =   NSLocalizedString(@"Forward to", nil);
    }
    
    NSString *message = [NSString stringWithFormat:@"%@ %@?",pTitle,transmit];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:message delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    alert.tag = kAlertTag;
    [alert show];
}

#pragma mark -tableViewDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_dataSourceArray count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACEntityCell *cell =    [ACEntityCell cellForTableView:tableView];

//    ACTransmitTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACTransmitTableViewCell"];
//    if (!cell)
//    {
//        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACTransmitTableViewCell" owner:nil options:nil];
//        cell = [nib objectAtIndex:0];
//    }

    [cell setEntityForTransmit:[_dataSourceArray objectAtIndex:indexPath.row]];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ACEntityCell_Hight;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACTopicEntity *topicEntity = [_dataSourceArray objectAtIndex:indexPath.row];
    _selectTopicEntity = topicEntity;
    [self showAlertTransmitToTopicEntity:topicEntity];
}

#pragma mark alertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kAlertTag)
    {
        if (buttonIndex == alertView.firstOtherButtonIndex)
        {
            if(self.isForVideoAudioCall){
                
                [self.navigationController ACpopViewControllerAnimated:NO];
                [ACChatMessageViewController callTopic:_selectTopicEntity
                                          forVideoCall:ACTransmitViewController_For_VideoCall==_viewType
                                  withParentController:_superVCForVideoCall];
                return;
            }
            
            
            [self.view showProgressHUDWithLabelText:NSLocalizedString(@"Preparing", nil) withAnimated:YES];
            

            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                if(ACTransmitViewController_For_Transmit==_viewType){
                    NSMutableArray* pMsgs = [[NSMutableArray alloc] initWithCapacity:_transmitMessages_Or_sendFilePaths.count];
                    for(ACMessage* msg in _transmitMessages_Or_sendFilePaths){
                        [pMsgs addObject:[ACMessage getTransmitMsgWithMsg:msg withTopicEntityID:_selectTopicEntity.entityID]];
                        if(_transmitMessages_Or_sendFilePaths.count>1){
                            [NSThread sleepForTimeInterval:0.1];
                        }
                    }
                    _transmitMessages_Or_sendFilePaths =    pMsgs;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.view hideProgressHUDWithAnimated:YES];
                    ACChatMessageViewController *chatMessageVC = [[ACChatMessageViewController alloc] initWithSuperVC:self withTopicEntity:_selectTopicEntity];
                    AC_MEM_Alloc(chatMessageVC);
                    //            chatMessageVC.topicEntity = _selectTopicEntity;
                    chatMessageVC.transmitMessages_Or_sendFilePaths = _transmitMessages_Or_sendFilePaths;
                    //            [chatMessageVC preloadDB];
                    [chatMessageVC setHidesBottomBarWhenPushed:YES];
                    [self.navigationController pushViewController:chatMessageVC animated:YES];
                });
            });
        }
        else{
            _isHadTransmit = NO;
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
