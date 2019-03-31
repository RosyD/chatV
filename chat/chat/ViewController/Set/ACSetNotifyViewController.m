//
//  ACSetViewController.m
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-28.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACSetNotifyViewController.h"
#import "ACConfigs.h"
#import "ACNetCenter.h"
#import "JSONKit.h"
#import "UINavigationController+Additions.h"


@interface ACSetNotifyViewController (){
    
    __weak IBOutlet UIView         *_contentView;
    __weak IBOutlet UILabel        *_titleLabel;

    __weak IBOutlet UILabel        *_notifyLabel;
    __weak IBOutlet UISwitch       *_notifySwitch;//
    
    __weak IBOutlet UIView       *_vibarteBkView;//新消息震动
    __weak IBOutlet UILabel        *_vibarteLabel;
    __weak IBOutlet UISwitch       *_vibarteSwitch;//
    
    __weak IBOutlet UIView       *_soundBkView;//新消息声音
    __weak IBOutlet UILabel        *_soundLabel;
    __weak IBOutlet UISwitch       *_soundSwitch;//
    
    __weak IBOutlet UIView       *_bannerBkView;//新消息声音
    __weak IBOutlet UILabel        *_bannerLabel;
    __weak IBOutlet UISwitch       *_bannerSwitch;//
    
    __weak IBOutlet UIView       *_commentBkView;//新消息声音
    __weak IBOutlet UILabel        *_commentLabel;
    __weak IBOutlet UISwitch       *_commentSwitch;//
    
}

@end

@implementation ACSetNotifyViewController

AC_MEM_Dealloc_implementation


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    [self _initSwitch:_soundSwitch];
    [self _initSwitch:_vibarteSwitch];
    [self _initSwitch:_bannerSwitch];
    [self _initSwitch:_commentSwitch];
    [self _initSwitch:_notifySwitch];

    _soundLabel.text    =   NSLocalizedString(@"In-App Sound", nil);
    _vibarteLabel.text  =   NSLocalizedString(@"In-App Vibrate", nil);
    _bannerLabel.text   =   NSLocalizedString(@"In-App Banner", nil);
    _commentLabel.text  =   NSLocalizedString(@"Note Comment Banner", nil);
    _notifyLabel.text   =   _titleLabel.text =  NSLocalizedString(@"Notification", nil);
    [self _notifyButtonHideOrShow];
    
    if (![ACConfigs isPhone5]){
        [_contentView setFrame_height:_contentView.size.height-88];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
}

-(int)_nameCfgForSwitch:(UISwitch*)pSwitch{
    if(pSwitch==_soundSwitch){
        return NotificationCfg_SoundOn;
    }
    if(pSwitch==_vibarteSwitch){
        return NotificationCfg_VibarteOn;
    }
    if(pSwitch==_bannerSwitch){
        return NotificationCfg_BannerOn;
    }
    if(pSwitch==_commentSwitch){
        return NotificationCfg_CommentBannerOn;
    }
    if(pSwitch==_notifySwitch){
        return NotificationCfg_ON;
    }
    return 0x1000000;
}

-(void)_initSwitch:(UISwitch*)pSwitch{
    pSwitch.on = [ACConfigs notificationCfgIsOn:[self _nameCfgForSwitch:pSwitch]];
}


#pragma mark -Notification

-(void)hotspotStateChange:(NSNotification *)noti
{
    if (_isOpenHotspot){
        [_contentView setFrame_height:_contentView.size.height-hotsoptHeight];
    }
    else{
        [_contentView setFrame_height:_contentView.size.height+hotsoptHeight];
    }
}

#pragma mark -IBAction

-(IBAction)goback:(id)sender{
    [self.navigationController ACpopViewControllerAnimated:YES];
}

-(IBAction)buttonTouchUp:(UIButton*)sender{
    UIView* superVC =   sender.superview;
    UISwitch* pSwitch = _notifySwitch;
    if(superVC==_vibarteBkView){
        pSwitch = _vibarteSwitch;
    }
    else if(superVC==_soundBkView){
        pSwitch = _soundSwitch;
    }
    else if(superVC==_bannerBkView){
        pSwitch = _bannerSwitch;
    }
    else if(superVC==_commentBkView){
        pSwitch = _commentSwitch;
    }
    [pSwitch setOn:!pSwitch.on animated:YES];
    [self switchValueChange:pSwitch];
    
//    _vibarteBkView
//    _soundBkView
//    _bannerBkView
//    _commentBkView
    
       
//       _notifySwitch;//
//       _vibarteSwitch;//
//      _soundSwitch;//
//       _bannerSwitch;//
//       _commentSwitch;//

}

-(void)_switchValueChangeResponse:(ASIHTTPRequest *)request failed:(BOOL) bIsFail with:(UISwitch*)sender{
    [_contentView hideProgressHUDWithAnimated:YES];
    
    //        ?t=0 全局
    //        ?t=1 Commnet
    //        POST: ?t=0|1&v=true|false
    //
    
    if(!bIsFail){
        NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
        ITLog(responseDic);
        if(ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]){
            [ACConfigs notificationCfgSave:[self _nameCfgForSwitch:sender] forSave:sender.on];
            if(_notifySwitch==sender){
                [self _notifyButtonHideOrShow];
            }
            return;
        }
    }
    
    //恢复
    [self _initSwitch:sender];
    [_contentView showNetErrorHUD];
}

-(IBAction)switchValueChange:(UISwitch*)sender{
    if(_notifySwitch==sender||_commentSwitch==sender){
        
        NSString* pURL = [NSString stringWithFormat:@"%@/rest/apis/chat/notification?t=%d&v=%@",[ACNetCenter shareNetCenter].acucomServer,_notifySwitch==sender?0:1,sender.on?@"true":@"false"];
        
        [_contentView showProgressHUD];
        wself_define();
        [ACNetCenter callURL:pURL forPut:NO withPostData:nil withBlock:^(ASIHTTPRequest *request, BOOL bIsFail) {
            [wself _switchValueChangeResponse:request failed:false with:sender];
        }];
        return;
    }
    
    [ACConfigs notificationCfgSave:[self _nameCfgForSwitch:sender] forSave:sender.on];
}

-(void)_notifyButtonHideOrShow{
    _vibarteBkView.hidden   =
    _soundBkView.hidden =
    _bannerBkView.hidden =
    _commentBkView.hidden= !_notifySwitch.on;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




@end
