//
//  AcuStartSessionCancelParam.h
//  chat
//
//  Created by Aculearn on 15-3-12.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AcuStartSessionCancelParam : NSObject

@property (nonatomic, assign) BOOL sessionCanceledInside;
@property (nonatomic, assign) BOOL sessionCanceledOutside;
@property (nonatomic, assign) BOOL sessionCanceled;
@property (nonatomic, assign) BOOL sessionCanceledCommandSended;

+ (instancetype)sharedInstance;

@end
