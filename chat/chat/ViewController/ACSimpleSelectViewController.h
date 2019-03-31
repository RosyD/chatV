//
//  ACSimpleSelectViewController.h
//  chat
//
//  Created by Aculearn on 15/4/15.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef void (^ACSimpleSelectViewControllerOnExit)(NSArray* selectedNos,NSInteger nSelectedNo);
//选中的编号,单选


@interface ACSimpleSelectViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>

//多选
+(void)showSelects:(NSArray*)pSelectInfos withDefaults:(NSArray*) selectedNos fromParentVC:(UIViewController*) pParentVC  withTitle:(NSString*)pTitle withExitBlock:(ACSimpleSelectViewControllerOnExit) pFunc;

//单选
+(void)showSelects:(NSArray*)pSelectInfos withDefaultNo:(NSInteger) selectedNo fromParentVC:(UIViewController*) pParentVC  withTitle:(NSString*)pTitle withExitBlock:(ACSimpleSelectViewControllerOnExit) pFunc;

@end
