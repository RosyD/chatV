//
//  ACNoteSearchResultVC.h
//  chat
//
//  Created by Aculearn on 16/11/1.
//  Copyright © 2016年 Aculearn. All rights reserved.
//


#import "ACNoteListVC_Base.h"

@interface ACNoteSearchResultVC : ACNoteListVC_Base

@property (weak, nonatomic) IBOutlet UIView *contentView;

+(void)showSearchResult:(NSDictionary*)pSearchResult
         withSearchText:(NSString*)pSearchText
              inSuperVC:(UIViewController*)pSuperVC;
@end
