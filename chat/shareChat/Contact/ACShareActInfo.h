//
//  ACShareActInfo.h
//  chat
//
//  Created by 李朝霞 on 2017/5/8.
//  Copyright © 2017年 李朝霞. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ACShareActInfo : NSObject

/**
 *  图标地址
 */
@property (nonatomic, copy) NSString *icon;
/**
 *  app名字
 */
@property (nonatomic, copy) NSString *name;

/**
 *  当前模型对像的image
 */
@property (nonatomic, strong) UIImage *image;


@end
