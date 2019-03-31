//
//  ACChangeIconVC_Base.h
//  chat
//
//  Created by Aculearn on 15/2/12.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPGrowingTextView.h"


#define kIsSaveAlertTag 34232

@interface ACChangeIconVC_Base : UIViewController<UIActionSheetDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIAlertViewDelegate>

@property (nonatomic,strong) NSArray    *iconPathArray;
@property (nonatomic)       BOOL        isPushedViewController;

-(void)onSelectedImage:(UIImage*)originalImage;
-(void)onUploadIconSuccess:(NSDictionary*)responseData;
-(BOOL)isNeedSave;
-(void)onSaveFunc;
-(void)onCallDelOrPreViewFunc:(BOOL)bCallDel;   //需要实现Preview功能


-(void)onCallSave;
-(void)onCallGoback;
-(void)selectIconFunc:(BOOL)bShowDelAndPrewView;
-(void)uploadIconInfo:(NSDictionary*)pPostInfo
         iconFileInfo:(NSDictionary*)iconFileInfo
              withURL:(NSString*)pURL
                  forPost:(BOOL)bForPost;
@end
