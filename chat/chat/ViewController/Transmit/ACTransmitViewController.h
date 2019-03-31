//
//  ACTransmitViewController.h
//  AcuCom
//
//  Created by 王方帅 on 14-5-20.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACMessage.h"

enum ACTransmitViewController_Type{
    ACTransmitViewController_For_Transmit,
    ACTransmitViewController_For_VideoCall,
    ACTransmitViewController_For_AudioCall,
    ACTransmitViewController_For_SendFile,
};

@interface ACTransmitViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate>
{
    __weak IBOutlet UITableView        *_mainTableView;
    __weak IBOutlet UILabel            *_titleLabel;
    __weak IBOutlet UIButton           *_createNewChatButton;
    __weak IBOutlet UILabel            *_nearestLabel;
    __weak IBOutlet UIButton           *_gobackButton;
    __weak IBOutlet UIView             *_tableHeaderView;
    
    
    ACTopicEntity               *_selectTopicEntity;
    NSMutableArray              *_dataSourceArray;
    __weak  UIViewController    *_superVCForVideoCall;
    enum ACTransmitViewController_Type  _viewType;
    BOOL                                _isHadTransmit;
    NSArray                             *_transmitMessages_Or_sendFilePaths;
}

@property (nonatomic) BOOL                      isOpenHotspot;
@property (nonatomic,readonly) BOOL             isForVideoAudioCall;

+(instancetype) newForTransimitMessages:(NSArray*)pMsgs;
+(instancetype) newForVideoCall:(BOOL)bForVideoCall withSuperVC:(UIViewController*)superVC;
+(instancetype) newForSendFiles:(NSArray*)filePaths;


@end
