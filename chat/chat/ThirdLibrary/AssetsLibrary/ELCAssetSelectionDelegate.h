//
//  ELCAssetSelectionDelegate.h
//  ELCImagePickerDemo
//
//  Created by JN on 9/6/12.
//  Copyright (c) 2012 ELC Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ELCAsset;

@protocol ELCAssetSelectionDelegate <NSObject>

- (void)selectedAssets:(NSArray *)assets; //选择结束
- (void)cancelSelectAssert; //放弃选择
- (BOOL)needSendPreview; //需要预览发送
- (NSUInteger)selectMaximumImagesCount;

- (BOOL)shouldSelectAsset:(ELCAsset *)asset previousCount:(NSUInteger)previousCount;
- (BOOL)shouldDeselectAsset:(ELCAsset *)asset previousCount:(NSUInteger)previousCount;

@end
