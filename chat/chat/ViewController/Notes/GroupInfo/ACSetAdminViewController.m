//
//  ACSetAdminViewController.m
//  chat
//
//  Created by Aculearn on 15/4/17.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#import "ACSetAdminViewController.h"
#import "ACContactTableViewCell.h"
#import "ACEntity.h"
#import "ACNetCenter.h"
#import "ACParticipant.h"
#import "ACUrlEntityDB.h"
#import "ACTopicEntityDB.h"

NSString * const kSetAdminParticipantNotifation = @"kSetAdminParticipantNotifation";

#define alertView_tag_Net_Error 1001

@interface ACSetAdminViewController (){
    NSArray*        _adminIDs_old;    //<NSString> userid
    NSMutableArray* _userInfos; //<ACParticipant>
    
    __weak IBOutlet UIActivityIndicatorView*    _activityView;
    __weak IBOutlet UITableView*                _tableViewForUserList;
    __weak IBOutlet UILabel*                    _lableTitle;
}

@end

@implementation ACSetAdminViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if(_transferAdminFinishFunc){
        _lableTitle.text    =   NSLocalizedString(@"Transfer admin", nil);
    }
    else{
        _lableTitle.text    =   NSLocalizedString(@"Set admin", nil);
    }
    
    if (![ACConfigs isPhone5]){
        //需要屏蔽autosize
        [_tableViewForUserList setFrame_height:_tableViewForUserList.size.height-88];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getParticipantInfo:) name:kNetCenterGetParticipantsNotifation object:nil];
    
    _activityView.hidden = YES;
    if([ASIHTTPRequest isValidNetWork]){
        _activityView.hidden = NO;
        [_activityView startAnimating];
        [[ACNetCenter shareNetCenter] getParticipantInfoWithEntity:_entity];
    }
    else{
        [self.view showNetErrorHUD];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc{
    AC_MEM_Dealloc();
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _userInfos.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ACContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACContactTableViewCell"];
    if (!cell){
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACContactTableViewCell" owner:nil options:nil];
        cell = [nib objectAtIndex:0];
    }
    ACParticipant* pUserInfo = _userInfos[indexPath.row];
    [cell setSuperVC_forSetAdmin:self];
    [cell setUser:pUserInfo For_ParticipantGroup:NO];
     
//    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 69;
}

#pragma mark UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    ACContactTableViewCell *cell = (ACContactTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
    [cell setContactSelected];
}

#pragma mark UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView_tag_Net_Error==alertView.tag){
        [self.navigationController popViewControllerAnimated:YES];
    }
}


#pragma mark ----
-(NSArray*)_getAdminIDs{
    //保存原始admin
    NSMutableArray* pRet = [[NSMutableArray alloc] init];
    for(ACParticipant* pParticipantTemp in _userInfos){
        if(pParticipantTemp.isAdmin){
            [pRet addObject:pParticipantTemp.userid];
        }
    }
    return pRet;
}

-(void)getParticipantInfo:(NSNotification *)noti{
    NSDictionary* pDict =   [noti.object objectForKey:_entity.dictFieldName];
    if(![_entity.entityID isEqualToString:[pDict objectForKey:@"id"]]){
        return;
    }
    
    //更新Topic信息,其实在之前就修改了
    //[_entity updateWithDict:pDict];
    
    {
        //participants
        NSMutableArray* pParticipants = [ACParticipant participantArrayWithDicArray:[pDict objectForKey:@"participants"]];
        
        //移除group
        for(NSInteger nNo=0;nNo<pParticipants.count;nNo++){
            ACParticipant* pParticipantTemp =   pParticipants[nNo];
            if(participantType_Group==pParticipantTemp.type){
                [pParticipants removeObjectAtIndex:nNo];
                nNo --;
            }
        }
        
        //移除 myslef
        if(_transferAdminFinishFunc){
//            NSString* myselfID = [ACUser myselfID];
            for(ACParticipant* pParticipantTemp in pParticipants){
                if([ACUser isMySelf:pParticipantTemp.userid]){
                    [pParticipants removeObject:pParticipantTemp];
                    break;
                }
            }
        }

        _userInfos  =   [ACParticipant participantArraySort:pParticipants withAdminIDS:[pDict objectForKey:@"adminUserIds"]];
    }
    
    //保存原始admin
    _adminIDs_old = [self _getAdminIDs];
    
    [_activityView stopAnimating];
    _activityView.hidden = YES;
    _tableViewForUserList.hidden = NO;
    [_tableViewForUserList reloadData];
}



- (IBAction)onBackup:(id)sender {
    BOOL   bNeedSave = NO;
    NSArray* pAdminIDs_new = nil;
    if(_userInfos.count){
        //判断是否需要更新
        pAdminIDs_new = [self _getAdminIDs];
        if(_transferAdminFinishFunc){
            //切换
            if(pAdminIDs_new.count){
                //切换
                bNeedSave = YES;
            }
        }
        else if(![pAdminIDs_new isEqualToArray:_adminIDs_old]){
            //有变化
             bNeedSave = YES;
        }
    }

    if(!bNeedSave){
        //没有取得数据
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    //
    if(_transferAdminFinishFunc){
        _transferAdminFinishFunc(pAdminIDs_new);
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    
/*    NSString* pURL = nil;
    if(EntityType_Topic==_entity.entityType){
        //rest/apis/chat/{topicEntityId}
//        Method: PUT
//        Request: {"auids":["admin user id 1","admin user id2"]}
        pURL    = @"/rest/apis/chat/";
    }
    else{
        //rest/apis/url/{urlEntityId}
//        Method: POST
//        "auids": ["539b26c2e4b02f245641f51c", "539b268ee4b02f245641a730", "539b268ee4b02f245641a730"]
        pURL    = @"/rest/apis/url/";
    }*/
    
    [self.view showProgressHUDWithLabelText:NSLocalizedString(@"Uploading", nil) withAnimated:YES];
    wself_define();
    [ACNetCenter callURL:_entity.requestUrl
                  forPut:EntityType_Topic==_entity.entityType?YES:NO
            withPostData:@{@"type":_entity.mpType,@"auids":pAdminIDs_new}
               withBlock:^(ASIHTTPRequest *request, BOOL bIsFail) {
                  [self.view hideProgressHUDWithAnimated:NO];
                   
                   if(!bIsFail){
                       NSDictionary *responseDic = [[[request.responseData objectFromJSONData] JSONString] objectFromJSONString];
                       int nErrorCode = [[responseDic objectForKey:kCode] intValue];
                       if (ResponseCodeType_Nomal==nErrorCode){
                           //更新
                           /* 不能更新entity，数据会丢失。
                           if(EntityType_Topic==_entity.entityType){
                               ACTopicEntity* pTopicEntify =    (ACTopicEntity*)_entity;
                               [pTopicEntify updateWithTopicDic:[responseDic objectForKey:_entity.dictFieldName]];
                               [ACTopicEntityDB saveTopicEntityToDBWithTopicEntity:pTopicEntify];
                           }
                           else{
                               ACUrlEntity* pUrlEntify =    (ACUrlEntity*)_entity;
                               [pUrlEntify updateEntityWithEventDic:[responseDic objectForKey:_entity.dictFieldName]];
                               [ACUrlEntityDB saveUrlEntityToDBWithUrlEntity:pUrlEntify];
                           }
                           */
                           
                           [ACUtility postNotificationName:kSetAdminParticipantNotifation object:_entity.entityID];
                           
                           [wself.navigationController popViewControllerAnimated:YES];
                           return ;
                       }
                       
                       if(ResponseCodeType_ERROR_AUTHORITYCHANGED_FAILED==nErrorCode){
                           [ACNetCenter ERROR_AUTHORITYCHANGED_FAILED_Error_Func:responseDic];
                           [wself.navigationController popViewControllerAnimated:YES];
                           return;
                       }
                   }
                   
                   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                   message:NSLocalizedString(@"Check_Network", nil)
                                                                  delegate:wself
                                                         cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                         otherButtonTitles:nil, nil];
                   alert.tag    =   alertView_tag_Net_Error;
                   [alert show];
                   
//                   [self.view showNetErrorHUD];
                   
               }];
    
}

@end
