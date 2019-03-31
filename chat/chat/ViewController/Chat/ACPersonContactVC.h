//
//  PersonInfoVC.h
//  TestForContens
//
//  Created by Aculearn on 14/12/9.
//  Copyright (c) 2014年 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>

@class ACPersonContactVC;
@protocol ACPersonContactVC_Delegate <NSObject>

-(void)ACPersonContactOnDone:(ACPersonContactVC*)pVC;
//调用 [self.navigationController popViewControllerAnimated:YES]; 关闭

@end


@interface ACPersonContactVC : UITableViewController

@property (strong,nonatomic,readonly,getter=getPersonName) NSString* PersonName;

+(id)   ACPersonContactVCWithPersonRecord:(ABRecordRef)person andDelegate:(id<ACPersonContactVC_Delegate>) delegate;
-(void) saveVcfFile:(NSString*)pFilePathName;


@end
