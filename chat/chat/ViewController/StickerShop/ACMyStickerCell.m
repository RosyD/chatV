//
//  ACMyStickerCell.m
//  chat
//
//  Created by 王方帅 on 14-8-20.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACMyStickerCell.h"
#import "UIImageView+WebCache.h"
#import "ACAddress.h"
#import "ACMyStickerController.h"
#import "ACNetCenter.h"

@implementation ACMyStickerCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    _progressView = [[MCProgressBarView alloc] initWithFrame:CGRectMake(0, 0, 57, 20) backgroundImage:[[UIImage imageNamed:@"EmotionProgressBg.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:10] foregroundImage:[[UIImage imageNamed:@"EmotionProgressTip.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:10]];
    [self.contentView addSubview:_progressView];
    _progressView.hidden = YES;
    [_progressView setCenter:_downloadButton.center];
}

-(void)setSuit:(ACSuit *)suit superVC:(ACMyStickerController *)superVC
{
    if (_suit != suit)
    {
        if (_suit)
        {
            [_suit removeObserver:self forKeyPath:kProgress];
        }
        _suit = suit;
        [_suit addObserver:self forKeyPath:kProgress options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
        _suit = suit;
        _superVC = superVC;
        _titleLabel.text = suit.suitName;
        [_iconImageView setStickerWithResourceId:suit.thumbnail placeholderImage:nil];
        
    }
    NSString *suitPath = [ACAddress getAddressWithFileName:_suit.suitID fileType:ACFile_Type_AddStickerSuitToMyStickersAndDownload isTemp:NO subDirName:_suit.suitID];
    BOOL isDownloaded = [[NSFileManager defaultManager] fileExistsAtPath:suitPath];
    NSArray * array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:suitPath error:nil];
    if ([array count] > 0)
    {
        isDownloaded = YES;
    }
    else
    {
        isDownloaded = NO;
    }
    if (isDownloaded)
    {
        [self isDeleteButton:YES];
    }
    else
    {
        [self isDeleteButton:NO];
    }
    if (_suit.progress == -1 || _suit.progress == 1)
    {
        _progressView.hidden = YES;
        _downloadButton.hidden = NO;
    }
    else
    {
        _progressView.hidden = NO;
        _downloadButton.hidden = YES;
    }
    
    ACSuit *suitTmp = [[ACNetCenter shareNetCenter].suitDownloadDic objectForKey:suit.suitID];
    if (suitTmp)
    {
        _downloadButton.hidden = YES;
        _progressView.hidden = NO;
        _progressView.progress = suitTmp.progress;
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _suit && [keyPath isEqualToString:kProgress])
    {
        _progressView.progress = _suit.progress;
        if (_suit.progress == 1)
        {
            _progressView.hidden = YES;
            _downloadButton.hidden = NO;
            [self isDeleteButton:YES];
        }
    }
}

-(void)progressUpdate:(float)progress
{
    _progressView.progress = progress;
    if (_suit.progress == 1)
    {
        _progressView.hidden = YES;
        _downloadButton.hidden = NO;
        [self isDeleteButton:YES];
    }
}

-(void)isDeleteButton:(BOOL)isDelete
{
    _isDelete = isDelete;
    if (isDelete)
    {
        [_downloadButton setBackgroundImage:[[UIImage imageNamed:@"fts_gray_btn.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:15] forState:UIControlStateNormal];
        [_downloadButton setBackgroundImage:[[UIImage imageNamed:@"fts_gray_btn_HL.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:15] forState:UIControlStateHighlighted];
        [_downloadButton setImage:nil forState:UIControlStateNormal];
        [_downloadButton setImage:nil forState:UIControlStateHighlighted];
        [_downloadButton setTitle:NSLocalizedString(@"Delete", nil) forState:UIControlStateNormal];
    }
    else
    {
        [_downloadButton setBackgroundImage:[[UIImage imageNamed:@"fts_green_btn.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:15] forState:UIControlStateNormal];
        [_downloadButton setBackgroundImage:[[UIImage imageNamed:@"fts_green_btn_HL.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:15] forState:UIControlStateHighlighted];
        [_downloadButton setImage:[UIImage imageNamed:@"EmotionDownload.png"] forState:UIControlStateNormal];
        [_downloadButton setImage:[UIImage imageNamed:@"EmotionDownloadHL.png"] forState:UIControlStateHighlighted];
        [_downloadButton setTitle:nil forState:UIControlStateNormal];
        
    }
}

#pragma mark -IBAction
-(IBAction)downloadButtonTouchUp:(id)sender
{
    if (_isDelete)
    {
        NSString *suitPath = [ACAddress getAddressWithFileName:_suit.suitID fileType:ACFile_Type_AddStickerSuitToMyStickersAndDownload isTemp:NO subDirName:_suit.suitID];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:suitPath])
        {
            [fileManager removeItemAtPath:suitPath error:nil];
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSArray *suits = [defaults objectForKey:kDownloadSuitList];
            NSMutableArray *downloadSuits = [NSMutableArray arrayWithArray:suits];
            [downloadSuits removeObject:_suit.suitID];
            [defaults setObject:downloadSuits forKey:kDownloadSuitList];
            [defaults synchronize];
            [ACUtility postNotificationName:kNetCenterSuitDeleteNotifation object:_suit];
            
            [_superVC reloadData];
        }
//        [_superVC removeSuit:_suit];
    }
    else
    {
        _progressView.hidden = NO;
        _downloadButton.hidden = YES;
        [_progressView setCenter:_downloadButton.center];
        [_superVC downloadSuitWithSuit:_suit];
    }
}

-(void)isEditing:(BOOL)isEditing
{
    if (isEditing)
    {
        _downloadButton.hidden = YES;
    }
}

@end
