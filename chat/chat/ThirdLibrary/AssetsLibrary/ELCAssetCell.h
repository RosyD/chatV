//
//  AssetCell.h
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ELCAssetTablePicker;
@interface ELCAssetCell : UITableViewCell

@property (nonatomic, assign) BOOL alignmentLeft;
@property (nonatomic, weak) ELCAssetTablePicker* superAssetTablePicker;
//@property (nonatomic, assign) BOOL notAllowTap; //txb 不允许点击选择

- (void)setAssets:(NSArray *)assets;

@end
