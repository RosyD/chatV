//
//  ACGroupInfoOptionVC.m
//  chat
//
//  Created by Aculearn on 15/2/11.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#import "ACGroupInfoOptionVC.h"
#import "ACNetCenter.h"
#import "UINavigationController+Additions.h"
#import "ACNetCenter.h"
#import "ACTopicEntityDB.h"
#import "ACEntity.h"
#import "UIImageView+WebCache.h"
#import "ACUserDB.h"
#import "JSONKit.h"
#import "UIImageView+WebCache.h"
#import "UIImage+Additions.h"
#import "UIView+Additions.h"
#import "ACAddress.h"
#import "ACDataCenter.h"
#import "ACSetAdminViewController.h"
#import "ACUrlEntityDB.h"

@interface ACGroupInfoOptionVC (){
    NSString*               _pOldTitle;
    NSString*               _pOldURL;
    BOOL                    _bTitleChanged;
    ACTopicEntity           *_topicEntity_Temp;
    ACUrlEntity             *_urlEntity_Temp;
}
@property (weak, nonatomic) IBOutlet UILabel *turnOffAlertsLabel;
@property (weak, nonatomic) IBOutlet UIButton *turnOffAlertsButton;
@property (weak, nonatomic) IBOutlet UITextView *groupTitleTextView;
@property (weak, nonatomic) IBOutlet UIImageView *groupIconImageView;
@property (weak, nonatomic) IBOutlet UIImageView *groupIconFlagImageView;
@property (weak, nonatomic) IBOutlet UIButton *groupIconButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLable;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *setAdminButton;
@property (weak, nonatomic) IBOutlet UILabel *setAdminLable;
@property (weak, nonatomic) IBOutlet UIImageView *setAdminImage;
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (weak, nonatomic) IBOutlet UIButton *turnOffAlertButton;

@end

@implementation ACGroupInfoOptionVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (_entity.entityType == EntityType_Topic){
        _topicEntity_Temp = (ACTopicEntity *)_entity;
        [_turnOffAlertsLabel setText:NSLocalizedString(@"Turn off alert", nil)];
        _turnOffAlertsButton.selected = _topicEntity_Temp.isTurnOffAlerts;
    }
    else{
        _urlEntity_Temp = (ACUrlEntity *)_entity;
        _turnOffAlertsLabel.hidden = YES;
        _turnOffAlertsButton.hidden = YES;
    }
    
    [self setFunctionForPerm];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentViewTap)];
    [self.view addGestureRecognizer:tap];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(getParticipantInfo:) name:kNetCenterGetParticipantsNotifation object:nil];
    [nc addObserver:self selector:@selector(errorAuthorityChangedFailed_1248:) name:kNetCenterErrorAuthorityChangedFailed_1248 object:nil];
    [nc addObserver:self selector:@selector(topicEntityTurnOffAlertsChangedNotify:) name:kACTopicEntityTurnOffAlertsNotifation object:nil];


    [self refreshMemberOrPerm];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc{
    AC_MEM_Dealloc();
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)setFunctionForPerm{
    
    BOOL bCanEdit;
    _pOldTitle  =   [_entity getShowTitleAndSetIcon:_groupIconImageView  andCanEditForGroupInfoOption:&bCanEdit];
    
    _groupTitleTextView.text =  _pOldTitle;
    _titleLable.text        =   _pOldTitle;
    _setAdminLable.text    =   NSLocalizedString(@"Set admin", nil);
    
    if(bCanEdit){
        _groupTitleTextView.delegate= self;
        _groupIconButton.hidden     =   NO;
        _setAdminButton.enabled     =   _entity.perm.canAddAdmins;
        
        if(_urlEntity_Temp){
            if([_urlEntity_Temp.mpType isEqualToString:cLink]){
                _urlTextField.hidden    =   NO;
                _urlTextField.text      =   _pOldURL = _urlEntity_Temp.url;
                _urlTextField.delegate  =   self;
            }
            else{
                _turnOffAlertButton.hidden = YES;
                [_setAdminButton setBackgroundImage:[UIImage imageNamed:@"it_contact_detail_item.png"] forState:UIControlStateNormal];
            }
        }
        
    }
    else{
        _groupTitleTextView.delegate = nil;
        _saveButton.hidden = YES;
        _turnOffAlertButton.hidden = YES;
        _groupIconButton.hidden     = YES;
        _groupTitleTextView.editable = NO;
        _groupIconFlagImageView.hidden = YES;
        
        if(_entity.perm.canAddAdmins){
            [_setAdminButton setBackgroundImage:[UIImage imageNamed:@"it_contact_detail_item.png"] forState:UIControlStateNormal];
        }
        else{
            _setAdminButton.hidden = YES;
            _setAdminLable.hidden = YES;
            _setAdminImage.hidden = YES;
        }        
    }
}

#pragma mark --Action

-(void)contentViewTap{
    [_groupTitleTextView resignFirstResponder];
}

-(IBAction)onChangeIcon:(id)sender{
    [_groupTitleTextView resignFirstResponder];
    [self selectIconFunc:NO];
//    if(_groupTitleTextView.editable){
//    }
//    else{
//        [self MWPhotoBrowser_ShowUserIcon1000:_user.icon];
//    }
}


-(IBAction)onSave:(id)sender{
    [_groupTitleTextView resignFirstResponder];
    [self onCallSave];
}

-(IBAction)goback:(id)sender{
    [_groupTitleTextView resignFirstResponder];
    [self onCallGoback];
}

-(IBAction)turnOffAlerts:(id)sender
{
    [_topicEntity_Temp changeIsTurnOffAlertsAndSendToServer:!_turnOffAlertsButton.selected
                                                   withView:self.view];
}

- (IBAction)onSetAdmin:(id)sender {
    ACSetAdminViewController* pSetAdminVC = [[ACSetAdminViewController alloc] init];
    pSetAdminVC.entity = _entity;
    [self.navigationController pushViewController:pSetAdminVC animated:YES];
}


#pragma mark -notification

-(void)refreshMemberOrPerm{
    //刷新信息
    if(![ASIHTTPRequest isValidNetWork]){
        [self.view showNetErrorHUD];
        return;
    }
    
    [self.view showNetLoadingWithAnimated:YES];
    [[ACNetCenter shareNetCenter] getParticipantInfoWithEntity:_entity];
}


-(void)errorAuthorityChangedFailed_1248:(NSNotification *)noti{
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
    
    //设置功能信息
    [self setFunctionForPerm];
}

-(void)topicEntityTurnOffAlertsChangedNotify:(NSNotification *)noti{
    [_turnOffAlertsButton setSelected:_topicEntity_Temp.isTurnOffAlerts];
}

#pragma mark -ACChangeIconVC_Base


-(BOOL)isNeedSave{
    if(_saveButton.hidden){
        //不需要保存
        _bTitleChanged = NO;
        return NO;
    }
    
    if(!_urlTextField.isHidden){
        NSString* pURL =    _urlTextField.text;
        if(![pURL isEqualToString:_pOldURL]){
            return YES;
        }
    }
    
    return  self.iconPathArray.count||
            (![_pOldTitle isEqualToString:_groupTitleTextView.text]);
}

-(void)onSaveFunc{
    
    NSString* groupTitle = _groupTitleTextView.text;
    if(0==groupTitle.length){
        _groupTitleTextView.text =  _pOldTitle;
//        [_groupTitleTextView becomeFirstResponder];
        return;
    }
    
    
    _bTitleChanged = NO;
    BOOL bForPost = NO;
    NSMutableDictionary *dictPostValue = [NSMutableDictionary dictionary];
    [dictPostValue setValue:_entity.mpType forKey:@"type"];
    
    if(_urlEntity_Temp){
        bForPost = YES;
        if(!_urlTextField.isHidden){
            NSString* pURL =    _urlTextField.text;
            if(![pURL isEqualToString:_pOldURL]){
                [dictPostValue setValue:pURL forKey:@"url"];
            }
        }
    }
    
    if(![_pOldTitle isEqualToString:groupTitle]){
        _bTitleChanged = YES;
        [dictPostValue setValue:groupTitle forKey:@"title"];
    }
    
    NSDictionary* dictFile = nil;
    if (2==self.iconPathArray.count){
        dictFile = @{@"icon_200_200":self.iconPathArray[0],
                     @"icon_60_60":self.iconPathArray[1]};
    }
    
    NSDictionary* pPostInfo = nil;
    if(_topicEntity_Temp){
        pPostInfo   =   @{@"chat":dictPostValue};
    }
    else{
        pPostInfo   =   @{@"url":dictPostValue};
    }
    
    [self uploadIconInfo:pPostInfo
            iconFileInfo:dictFile
                 withURL:_entity.requestUrl
                 forPost:bForPost];
    
    
    /*        [self savePersonInfoWithIconPathArray:self.iconPathArray
     withName:_nameTextField.text
     withDescription:_textView.text
     account:@""];*/
}


-(void)onSelectedImage:(UIImage*)originalImage{
    
    UIImage *icon60Image = [originalImage imageScaledInterceptToSize:CGSizeMake(60, 60)];
    NSString *icon60ImagePath = [ACAddress getAddressWithFileName:kIcon_100_100 fileType:ACFile_Type_ImageFile isTemp:YES subDirName:nil];
    [UIImageJPEGRepresentation(icon60Image, 0.75) writeToFile:icon60ImagePath atomically:YES];
    
    UIImage *icon200Image = [originalImage imageScaledInterceptToSize:CGSizeMake(200, 200)];
    NSString *icon200ImagePath = [ACAddress getAddressWithFileName:kIcon_200_200 fileType:ACFile_Type_ImageFile isTemp:YES subDirName:nil];
    [UIImageJPEGRepresentation(icon200Image, 0.75) writeToFile:icon200ImagePath atomically:YES];
    
    self.iconPathArray = [NSArray arrayWithObjects:icon200ImagePath,icon60ImagePath, nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        _groupIconImageView.image = icon200Image;
    });
}

-(void)onUploadIconSuccess:(NSDictionary*)responseDic{
    if(_topicEntity_Temp){
        [_topicEntity_Temp updateEntityForOptionWithEventDic:responseDic];
        [ACTopicEntityDB saveTopicEntityToDBWithTopicEntity:_topicEntity_Temp];
    }
    else{
        [_urlEntity_Temp updateEntityWithEventDic:[responseDic objectForKey:_urlEntity_Temp.dictFieldName]];
        [ACUrlEntityDB saveUrlEntityToDBWithUrlEntity:_urlEntity_Temp];
        if(!_urlTextField.isHidden){
            _pOldURL    =   _urlEntity_Temp.url;
        }
    }
    self.iconPathArray  =   nil;
    if(_bTitleChanged){
        _pOldTitle          =   _groupTitleTextView.text;
        _titleLable.text    =   _pOldTitle;
        [ACUtility postNotificationName:kDataCenterTopicInfoChangedNotifation object:nil];
    }
}

#pragma mark UITextFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark UITextViewDelegate

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString*)text
{
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

@end
