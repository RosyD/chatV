//
//  ACSearchCell.m
//  chat
//
//  Created by 王方帅 on 14-7-11.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACSearchCell.h"
#import "ACSearchController.h"

@implementation ACSearchCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    [_iconImageView.layer setCornerRadius:5.0];
    [_iconImageView.layer setMasksToBounds:YES];
    

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)_setSearchCountType:(enum SearchCountType)searchCountType withCount:(int)nCount superVC:(ACSearchController *)superVC {
    _superVC = superVC;
    _searchCountType = searchCountType;
    if (_searchCountType == SearchCountType_Topic)
    {
        _iconImageView.image = [UIImage imageNamed:@"chat.png"];
        _contentLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Message found: %d",nil),superVC?[[superVC.searchCountDic objectForKey:kTopicTotal] intValue]:nCount];
    }
    else if (_searchCountType == SearchCountType_User)
    {
        _iconImageView.image = [UIImage imageNamed:@"icon_singlechat.png"];
        _contentLabel.text = [NSString stringWithFormat:NSLocalizedString(@"User name found: %d",nil),superVC?[[superVC.searchCountDic objectForKey:kUserTotal] intValue]:nCount];
    }
    else if (_searchCountType == SearchCountType_AccountUser)
    {
        _iconImageView.image = [UIImage imageNamed:@"icon_singlechat.png"];
        _contentLabel.text = [NSString stringWithFormat:NSLocalizedString(@"User account found: %d",nil),superVC?[[superVC.searchCountDic objectForKey:kAccountTotal] intValue]:nCount];
    }
    else if (_searchCountType == SearchCountType_UserGroup)
    {
        _iconImageView.image = [UIImage imageNamed:@"icon_groupchat.png"];
        _contentLabel.text = [NSString stringWithFormat:NSLocalizedString(@"User group found: %d",nil),superVC?[[superVC.searchCountDic objectForKey:kUserGroupTotal] intValue]:nCount];
    }
    else if (_searchCountType == SearchCountType_Note)
    {
        _iconImageView.image = [UIImage imageNamed:@"icon_note.png"];
        _contentLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Note found: %d",nil),superVC?[[superVC.searchCountDic objectForKey:kNoteTotal] intValue]:nCount];
    }
}

-(void)setSearchCountType:(enum SearchCountType)searchCountType withCount:(int)nCount{
    [self _setSearchCountType:searchCountType withCount:nCount superVC:nil];
}

-(void)setSearchCountType:(enum SearchCountType)searchCountType superVC:(ACSearchController *)superVC
{
    [self _setSearchCountType:searchCountType withCount:0 superVC:superVC];
}

@end
