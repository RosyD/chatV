//
//  ACTableViewVC_Base.m
//  chat
//
//  Created by Aculearn on 14/12/25.
//  Copyright (c) 2014年 Aculearn. All rights reserved.
//

#import "ACTableViewVC_Base.h"
#import "MJRefresh.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UINavigationController+Additions.h"
#import "ACVideoCall.h"

@interface ACTableViewVC_Base (){
//    __weak UIView                     *_tableHeaderView;
    __weak UIActivityIndicatorView    *_activityView;
    
//    MPMoviePlayerViewController     *_moviePlayerVC;
    ACNoteMessage                   *_photoBrowserMessage;
    NSString                        *_currentVideoPath;
}

@end

@implementation ACTableViewVC_Base

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mainTableView.delegate =   self;
    self.mainTableView.dataSource = self;
    
    _nRefreshType   =   ACTableViewVC_Base_RefreshType_Init;

    wself_define();
    if(!_bNotNeedRefreshHead){
        //添加上面的刷新
        [self.mainTableView addHeaderWithCallback:^{
            wself.nRefreshType   =   ACTableViewVC_Base_RefreshType_Head;
            [wself LoadDataFunc];
        }];
    }
    
    //下面的刷新
    [self.mainTableView addFooterWithCallback:^{
        wself.nRefreshType   =   ACTableViewVC_Base_RefreshType_Tail;
        [wself LoadDataFunc];
    }];
    
    //http://www.cnblogs.com/dev1024/p/5889865.html
    //IOS 10的问题
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    NSInteger nWidth =  [UIScreen mainScreen].bounds.size.width;
    UIView* _tableHeaderView    =   [[UIView alloc] initWithFrame:CGRectMake(0, 0,nWidth, 20)];
    UIActivityIndicatorView* activityView       =   [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((nWidth-20)/2, 0,20, 20)];
    activityView.activityIndicatorViewStyle  =UIActivityIndicatorViewStyleGray;
    [_tableHeaderView addSubview:activityView];
    self.mainTableView.tableHeaderView = _tableHeaderView;
    [activityView startAnimating];
    
    _activityView   =   activityView;
    _nRefreshType   =   ACTableViewVC_Base_RefreshType_Init;

    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


-(void)scrollToIndex:(NSInteger)nIndex animated:(BOOL)animated{
    [self.mainTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:nIndex inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:animated];
}

-(void)refreshFocus{
    _nRefreshType   =   ACTableViewVC_Base_RefreshType_Focus;
    [self.view showProgressHUD];
    [self LoadDataFunc];
}

-(void)LoadDataFuncEnd_WithCount:(NSInteger)nLoadCount{
    
    [self.view hideProgressHUDWithAnimated:NO];
    
    ACTableViewVC_Base_RefreshType nRefreshType =   _nRefreshType;
    _nRefreshType   =   ACTableViewVC_Base_RefreshType_Nouse;
    
    if(ACTableViewVC_Base_RefreshType_Init==nRefreshType){
        //初始化
        [_activityView stopAnimating];
        [_activityView removeFromSuperview];
        _activityView       =   nil;
        self.mainTableView.tableHeaderView = nil;
        [self.mainTableView reloadData];
        return;
    }
    
    //停止动画

    if(ACTableViewVC_Base_RefreshType_Head==nRefreshType){
        [self.mainTableView headerEndRefreshing];
    }
    else if(ACTableViewVC_Base_RefreshType_Tail==nRefreshType){
        [self.mainTableView footerEndRefreshing];
    }
    
    [self.mainTableView reloadData];
    if(ACTableViewVC_Base_RefreshType_Head==_nRefreshType){
        [self scrollToIndex:0 animated:YES];
    }
    
    /*
    if(ACTableViewVC_Base_RefreshType_Head==_nRefreshType){
        [self.mainTableView reloadData];
        [self scrollToIndex:0 animated:YES];
    }
    else if(nLoadCount){
        //刷新数据
        [self.mainTableView reloadData];
    }*/
}

-(void)imageOrVideoTapWithNoteMessage:(ACNoteMessage *)noteMessage forIndex:(int)index{
    ACNoteContentImageOrVideo *page = [noteMessage.imgs_Videos_List objectAtIndex:index];
    if(page.bIsImage){
        MWPhotoBrowser* _photoBrowser = [[MWPhotoBrowser alloc] initWithDelegate:self browserType:BrowserType_DefineBrowser];
        _photoBrowserMessage    =   noteMessage;
        [_photoBrowser setInitialPageIndex:index];  //initIndex要在_photoArray之后执行
        _photoBrowser.displayActionButton = YES;
        UINavigationController *navC = [[UINavigationController alloc] initWithRootViewController:_photoBrowser];
        [self ACpresentViewController:navC animated:YES completion:nil];
        
        return;
    }
    
    //播放视频
    _currentVideoPath = page.resourceFilePath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:_currentVideoPath]){
        
        if([ACVideoCall inVideoCallAndShowTip]){
            return;
        }
        
        MPMoviePlayerViewController* _moviePlayerVC = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:_currentVideoPath]];
        [_moviePlayerVC.moviePlayer shouldAutoplay];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
        [nc addObserver:self
               selector:@selector(videoHasFinishedPlaying:)
                   name:MPMoviePlayerPlaybackDidFinishNotification
                 object:nil];

        
        [self ACpresentMoviePlayerViewControllerAnimated:_moviePlayerVC];
    }
}


#pragma mark -notification
- (void)videoHasFinishedPlaying:(NSNotification *)paramNotification{
    /* Find out what the reason was for the player to stop */
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    NSNumber *reason =
    [paramNotification.userInfo
     valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    if (reason != nil){
        NSInteger reasonAsInteger = [reason integerValue];
        switch (reasonAsInteger){
            case MPMovieFinishReasonPlaybackEnded:{
                /* The movie ended normally */
                break; }
            case MPMovieFinishReasonPlaybackError:{
                /* An error happened and the movie ended */
                [[NSFileManager defaultManager] removeItemAtPath:_currentVideoPath error:nil];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"Movie_Play_Fail", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
                [alert show];
                break;
            }
            case MPMovieFinishReasonUserExited:{
                /* The user exited the player */
                break;
            }
        }
        NSLog(@"Finish Reason = %ld", (long)reasonAsInteger);
    } /* if (reason != nil){ */
}


#pragma mark -photoBrowser


- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser{
    return [_photoBrowserMessage.imageList count];
}

- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    ACNoteContentImageOrVideo *page = [_photoBrowserMessage.imageList objectAtIndex:index];
    NSString *filePath = page.resourceFilePath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        MWPhoto *photo = [MWPhoto photoWithFilePath:filePath];
        return photo;
    }
    MWPhoto *photo = [MWPhoto photoWithURL:[page getResourceURLForThumb:NO withNoteMessage:_photoBrowserMessage]];
    return photo;
}



@end
