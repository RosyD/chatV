//
//  ACDetailPageCell.m
//  chat
//
//  Created by 王方帅 on 14-6-5.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACContributeVC_ThumbCell.h"
#import "ACAddress.h"
#import "ACContributeViewController.h"

@implementation ACContributeVC_ThumbCell


-(void)setFilePage:(ACNoteContentImageOrVideo *)filePage superVC:(ACContributeViewController *)superVC
{
    _superVC = superVC;
    if (_filePage != filePage)
    {
        _filePage = filePage;
        [_playImageView setHidden:filePage.bIsImage];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSString *filePath = [ACAddress getAddressWithFileName:[_filePage.resourceID stringByAppendingString:@"_s"] fileType:filePage.acFileType isTemp:NO subDirName:nil];
            UIImage *image = [UIImage imageWithContentsOfFile:filePath];
            dispatch_async(dispatch_get_main_queue(), ^{
                _detailImageView.image = image;
            });
        });
    }
}

-(IBAction)deleteButtonTouchUp:(id)sender
{
    [_superVC  removeContent:_filePage];
}

@end
