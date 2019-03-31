//
//  ACChangeIconVC_Base.m
//  chat
//
//  Created by Aculearn on 15/2/12.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#import "ACChangeIconVC_Base.h"
#import "ACNetCenter.h"
#import "ASIFormDataRequest.h"
#import "JSONKit.h"
#import "UINavigationController+Additions.h"


#define kSelectIconActionSheetTag  23212

@interface ACChangeIconVC_Base (){
    BOOL    _isNeedDismiss;
    BOOL    _bShowDelAndPrewViewOnCallSelectIconFunc;
}

@end

@implementation ACChangeIconVC_Base

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark -actionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == kSelectIconActionSheetTag)
    {
        NSInteger CameraOrGalleryFirstButtonIndex = actionSheet.firstOtherButtonIndex;
        if(_bShowDelAndPrewViewOnCallSelectIconFunc){
            if(buttonIndex==actionSheet.firstOtherButtonIndex){
                [self onCallDelOrPreViewFunc:NO];
                return;
            }
            
            CameraOrGalleryFirstButtonIndex ++;
        }
        
        
        //first拍照 second相册
        if (buttonIndex == CameraOrGalleryFirstButtonIndex)
        {
//            [self selectImageWithUIImagePickerController_Delegate:self forCamera:YES];
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
                UIImagePickerController *imagePC = [[UIImagePickerController alloc] init];
                imagePC.delegate = self;
                imagePC.allowsEditing = YES; //需要编辑功能 
//                imagePC.videoQuality = UIImagePickerControllerQualityTypeIFrame1280x720;
                imagePC.sourceType = UIImagePickerControllerSourceTypeCamera;
                [self ACpresentViewController:imagePC animated:YES completion:nil];
            }
            return;
        }
        
        if (buttonIndex == CameraOrGalleryFirstButtonIndex + 1)
        {
            //需要编辑功能
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]){
                UIImagePickerController *imagePC = [[UIImagePickerController alloc] init];
                imagePC.delegate = self;
                imagePC.allowsEditing = YES;
//                imagePC.mediaTypes =[UIImagePickerController availableMediaTypesForSourceType:imagePC.sourceType];
//                imagePC.videoQuality = UIImagePickerControllerQualityTypeIFrame1280x720;
                imagePC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                [self ACpresentViewController:imagePC animated:YES completion:nil];
            }
            return;
        }
        
        if (_bShowDelAndPrewViewOnCallSelectIconFunc&&
            buttonIndex == (CameraOrGalleryFirstButtonIndex + 2)){
            [self onCallDelOrPreViewFunc:YES];
        }
    }
}

-(void)dismiss{
    if(_isPushedViewController){
        [self.navigationController ACpopViewControllerAnimated:YES];
    }
    else{
//        ITLog(@"TXB");
        [self ACdismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark -UIImagePickerControllerDelegate
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker ACdismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker ACdismissViewControllerAnimated:YES completion:nil];
    
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self onSelectedImage:[info objectForKey:UIImagePickerControllerEditedImage]];
//    });
}

-(void)selectIconFunc:(BOOL)bShowDelAndPrewView{
    
    _bShowDelAndPrewViewOnCallSelectIconFunc =  bShowDelAndPrewView;
    UIActionSheet *sheet = nil;
    if(bShowDelAndPrewView){
          sheet = [[UIActionSheet alloc] initWithTitle:nil
                                            delegate:self
                                   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                              destructiveButtonTitle:nil
                                   otherButtonTitles:NSLocalizedString(@"Preview", nil),NSLocalizedString(@"Camera", nil),
                 NSLocalizedString(@"Gallery", nil), NSLocalizedString(@"Delete", nil),nil];
    }
    else{
        sheet = [[UIActionSheet alloc] initWithTitle:nil
                                            delegate:self
                                   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                              destructiveButtonTitle:nil
                                   otherButtonTitles:NSLocalizedString(@"Camera", nil),NSLocalizedString(@"Gallery", nil), nil];
        
    }
    
    sheet.tag  = kSelectIconActionSheetTag;
    [sheet showInView:self.view];
}

-(void)onCallSave{
    
    if ([self isNeedSave]){
        [self onSaveFunc];
    }
    else{
         [self.view showProgressHUDSuccessWithLabelText:NSLocalizedString(@"Save Success", nil) withAfterDelayHide:1.0];
    }
}

-(void)onCallGoback{
    if ([self isNeedSave])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil)
                                                        message:NSLocalizedString(@"InfoModify_After_Save_Exit", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"Save", nil), nil];
        alert.tag = kIsSaveAlertTag;
        [alert show];
    }
    else{
        [self dismiss];
    }
}

#pragma mark -alertView
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kIsSaveAlertTag)
    {
        if (buttonIndex == alertView.firstOtherButtonIndex)
        {
            _isNeedDismiss = YES;
            [self onSaveFunc];
        }
        else if (buttonIndex == alertView.cancelButtonIndex)
        {
            [self dismiss];
        }
    }
}



#pragma mark - uploadFuncNetwork


-(void)uploadIconInfo:(NSDictionary*)pPostInfo iconFileInfo:(NSDictionary*)iconFileInfo withURL:(NSString*)pURL forPost:(BOOL)bForPost{
    [self.view showProgressHUDWithLabelText:NSLocalizedString(@"Uploading", nil) withAnimated:YES];

    wself_define();
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        ASIFormDataRequest *dataRequest = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:pURL]];
        [dataRequest setValidatesSecureCertificate:NO];
        [dataRequest setPostFormat:ASIMultipartFormDataPostFormat];
        
        //Post
        {
            NSArray* pKeys =    pPostInfo.allKeys;
            for(NSString* pKey in pKeys){
                [dataRequest setPostValue:[(NSDictionary*)[pPostInfo objectForKey:pKey] JSONString] forKey:pKey];
            }
        }
        
        
/*        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (![name isEqualToString:[defaults objectForKey:kName]])
        {
            [dic setObject:name forKey:kName];
        }
        if (![description isEqualToString:[defaults objectForKey:kDescription]])
        {
            [dic setObject:description forKey:kDescription];
        }
        [dataRequest setPostValue:[dic JSONString] forKey:@"user"];
 */
        
        {
            NSArray* pKeys =    iconFileInfo.allKeys;
            for(NSString* pKey in pKeys){
                [dataRequest setFile:(NSString*)[iconFileInfo objectForKey:pKey] forKey:pKey];
            }
        }
        [dataRequest setRequestMethod:[[ACNetCenter shareNetCenter] getRequestMethodWithType:bForPost?requestMethodType_Post:requestMethodType_Put]];
        [dataRequest setRequestHeaders:[[ACNetCenter shareNetCenter] getRequestHeader]];
        [dataRequest setTimeOutSeconds:240];
        dataRequest.useCookiePersistence = YES;
        __strong ASIFormDataRequest *dataRequestTmp = dataRequest;
        [dataRequest setCompletionBlock:^{
            [wself.view hideProgressHUDWithAnimated:NO];
            
            if(HttpCodeType_Success!=dataRequestTmp.responseStatusCode){
                ITLogEX(@"http error %d",dataRequestTmp.responseStatusCode);
                return;
            }
            
            NSDictionary *responseDic = [[dataRequestTmp responseData] objectFromJSONData];
            ITLog(responseDic);
            int nErrorCode = [[responseDic objectForKey:kCode] intValue];
            if(ResponseCodeType_Nomal==nErrorCode){
                [wself onUploadIconSuccess:responseDic];
                ///
                if (_isNeedDismiss){
                    [wself dismiss];
                }
                else{
                    AC_ShowTip(NSLocalizedString(@"Save Success", nil));
                }
            }
            else if(ResponseCodeType_ERROR_AUTHORITYCHANGED_FAILED==nErrorCode){
                [ACNetCenter ERROR_AUTHORITYCHANGED_FAILED_Error_Func:responseDic];
            }
        }];
        
        [dataRequest setFailedBlock:^{
            [wself.view showNetErrorHUD];
            ITLog(@"失败,网络错误");
        }];
        [dataRequest startAsynchronous];
    });
}





@end
