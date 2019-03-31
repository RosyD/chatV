//
//  ACStickerPackageCell.m
//  chat
//
//  Created by 王方帅 on 14-8-14.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACStickerPackageCell.h"
#import "ACStickerGalleryController.h"
#import "UIImageView+WebCache.h"
#import "ACAddress.h"
#import "ACNetCenter.h"

@implementation ACStickerPackageCell

- (void)dealloc
{
    [_suit removeObserver:self forKeyPath:kProgress];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    _progressView = [[MCProgressBarView alloc] initWithFrame:CGRectMake(0, 0, 57, 20) backgroundImage:[[UIImage imageNamed:@"EmotionProgressBg.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:10] foregroundImage:[[UIImage imageNamed:@"EmotionProgressTip.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:10]];
    [self.contentView addSubview:_progressView];
    _progressView.hidden = YES;
    [_progressView setCenter:_downloadButton.center];
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
            [self setIsDownloaded:YES];
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
        [self setIsDownloaded:YES];
    }
}

-(void)setSuit:(ACSuit *)suit superVC:(ACStickerGalleryController *)superVC
{
    if (_suit != suit)
    {
        if (_suit)
        {
            [_suit removeObserver:self forKeyPath:kProgress];
        }
        _suit = suit;
        [_suit addObserver:self forKeyPath:kProgress options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
        _superVC = superVC;
        _titleLabel.text = suit.suitName;
        _descLabel.text = suit.desc;
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
        [self setIsDownloaded:YES];
    }
    else
    {
        [self setIsDownloaded:NO];
    }
    
    ACSuit *suitTmp = [[ACNetCenter shareNetCenter].suitDownloadDic objectForKey:suit.suitID];
    if (suitTmp)
    {
        _downloadButton.hidden = YES;
        _progressView.hidden = NO;
        _progressView.progress = suitTmp.progress;
    }
}

-(void)setIsDownloaded:(BOOL)isDownloaded
{
    if (_suit.progress == -1 || _suit.progress == 1)
    {
        _progressView.hidden = YES;
        [_downloadButton setHidden:NO];
    }
    else
    {
        _progressView.hidden = NO;
        [_downloadButton setHidden:YES];
    }
    if (isDownloaded)
    {
        [_downloadButton setBackgroundImage:nil forState:UIControlStateNormal];
        [_downloadButton setBackgroundImage:nil forState:UIControlStateHighlighted];
        [_downloadButton setImage:[UIImage imageNamed:@"EmotionDownloadComplete.png"] forState:UIControlStateNormal];
        [_downloadButton setImage:nil forState:UIControlStateHighlighted];
        [_downloadButton setUserInteractionEnabled:NO];
    }
    else
    {
        [_downloadButton setBackgroundImage:[[UIImage imageNamed:@"fts_green_btn.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:15] forState:UIControlStateNormal];
        [_downloadButton setBackgroundImage:[[UIImage imageNamed:@"fts_green_btn_HL.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:15] forState:UIControlStateHighlighted];
        [_downloadButton setImage:[UIImage imageNamed:@"EmotionDownload.png"] forState:UIControlStateNormal];
        [_downloadButton setImage:[UIImage imageNamed:@"EmotionDownloadHL.png"] forState:UIControlStateHighlighted];
        [_downloadButton setUserInteractionEnabled:YES];
    }
}

-(IBAction)downloadSuit:(id)sender
{
    _progressView.hidden = NO;
    _downloadButton.hidden = YES;
    _progressView.center = _downloadButton.center;
    [_superVC downloadSuitWithSuit:_suit];
}

@end
