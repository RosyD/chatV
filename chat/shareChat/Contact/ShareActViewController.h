//
//  ShareActViewController.h
//  ShareExtensionDemo
//
//  Created by vimfung on 16/6/27.
//  Copyright © 2016年 vimfung. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACTopicEntity.h"

@interface ShareActViewController : UIViewController
{
    NSMutableArray              *_dataSourceArray;
    UITableView                 *_tableView;
}

/**
 *  选中时触发
 *
 *  @param handler 事件处理器
 */
//- (void)onSelected:(void(^)(NSIndexPath *indexPath))handler;
- (void)onSelected:(void(^)(NSString *title,ACTopicEntity* topicEntity))handler;
@end
