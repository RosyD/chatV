//
//  ACTableViewVC_Base.h
//  chat
//
//  Created by Aculearn on 14/12/25.
//  Copyright (c) 2014年 Aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWPhotoBrowser.h"
#import "ACNoteMessage.h"

typedef enum _ACTableViewVC_Base_RefreshType{
    ACTableViewVC_Base_RefreshType_Nouse,
    ACTableViewVC_Base_RefreshType_Init,    //初始化刷新
    ACTableViewVC_Base_RefreshType_Head,    //头部刷新
    ACTableViewVC_Base_RefreshType_Tail,    //尾部刷新
    ACTableViewVC_Base_RefreshType_Focus,   //强制刷新
}ACTableViewVC_Base_RefreshType;

@interface ACTableViewVC_Base : UIViewController<UITableViewDataSource,UITableViewDelegate,MWPhotoBrowserDelegate>

@property (weak,nonatomic)  IBOutlet UITableView    *mainTableView;
@property (nonatomic)       BOOL                     isOpenHotspot;
@property (nonatomic)       BOOL                     bNotNeedRefreshHead; //不需要头部刷新
@property (nonatomic)       ACTableViewVC_Base_RefreshType  nRefreshType; //刷新类型

//点击了图片，点击了视频
-(void)imageOrVideoTapWithNoteMessage:(ACNoteMessage *)noteMessage forIndex:(int)index;

//滚动到指定页
-(void)scrollToIndex:(NSInteger)nIndex animated:(BOOL)animated;

-(void)refreshFocus; //强制刷新加载

-(void)LoadDataFunc; //加载更多,头或尾,被ACTableViewVC_Base调用
-(void)LoadDataFuncEnd_WithCount:(NSInteger)nLoadCount; //加载结束


@end
