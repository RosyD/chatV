//
//  AC_ScrollPreViewController.m
//  chat
//
//  Created by Aculearn on 15/12/9.
//  Copyright © 2015年 Aculearn. All rights reserved.
//

#import "AC_ScrollPreViewController.h"
#import "ELCAssetTablePicker.h"
#import "ELCAsset.h"
#import "UIImage+Additions.h"
#import "AC_ImgsScrollView.h"
#import "AC_PreViewImagesWithCaption.h"


#define bottomBgView_Hight  44
#define selectButton_Hight  (bottomBgView_Hight-2*2)

@interface AC_ScrollPreViewController ()<AC_ImgsScrollViewDelegate>{
    AC_ImgsScrollView*  _scrollView;
    UIView*             _bottomBgView;
    UIButton*           _selectButton;
    __weak ELCAssetTablePicker* _parent;
    ELCAssetCacheManger *_fullScreenCachingManger;

}
@end

@implementation AC_ScrollPreViewController

-(instancetype)initPreVCWithParent:(ELCAssetTablePicker*)parent{
    self = [super init];
    if(self){
        _parent =   parent;
        if(parent.phAssetGroup){
            _fullScreenCachingManger = [[ELCAssetCacheManger alloc] initWithAssets:parent.elcAssets andWinSize:10 forImgType:ELCAssetLoad_FullScreen];
        }
    }
    return self;
}

AC_MEM_Dealloc_implementation

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
//    NSLog(@"%@",NSStringFromCGRect(self.view.frame));
    _scrollView =   [[AC_ImgsScrollView alloc] initWithFrame:self.view.bounds];
    AC_MEM_Alloc(_scrollView);
    [self.view addSubview:_scrollView];
    
    UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doSelectFinish)];
    [self.navigationItem setRightBarButtonItem:doneButtonItem];

    
    CGRect bounds = self.view.bounds;
    _bottomBgView = [[UIView alloc] initWithFrame:CGRectMake(0, bounds.size.height-bottomBgView_Hight, bounds.size.width, bottomBgView_Hight)];
    _bottomBgView.backgroundColor =  UIColor_RGB(0xE0, 0xDD, 0xD8);
    _bottomBgView.alpha =   0.8;
    
    
    bounds  =   _bottomBgView.bounds;
    _selectButton = [[UIButton alloc] initWithFrame:CGRectMake(bounds.size.width-selectButton_Hight-10, (bottomBgView_Hight-selectButton_Hight)/2, selectButton_Hight, selectButton_Hight)];
    [_selectButton setImage:[UIImage imageNamed:@"FriendsSendsPicturesSelectBigNIcon_ios7"] forState:UIControlStateNormal];
    [_selectButton setImage:[UIImage imageNamed:@"FriendsSendsPicturesSelectBigYIcon_ios7"] forState:UIControlStateSelected];
    [_selectButton addTarget:self action:@selector(onSelectButton) forControlEvents:UIControlEventTouchUpInside];

    [_bottomBgView addSubview:_selectButton];
    [self.view addSubview:_bottomBgView];

    //必须放在button后面
    [_scrollView setDelegate:self withFirstNo:_nFistShowImgNo];
//    [_parent showSelectedTitleWithVC:self];

//    UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_selectButton];
//    self.navigationItem.rightBarButtonItem = doneButtonItem;
//    [self setBottomView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    ELCAsset *asset = (ELCAsset*)_parent.elcAssets[_scrollView.curImgNo];
    _selectButton.selected  =   asset.selected;
    [_parent showSelectedTitleWithVC:self];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    _scrollView.frame = self.view.bounds;
    _bottomBgView.frame = CGRectMake(0, self.view.bounds.size.height-bottomBgView_Hight, self.view.bounds.size.width, bottomBgView_Hight);
}

-(void)onSelectButton{
     ELCAsset *asset = (ELCAsset*)_parent.elcAssets[_scrollView.curImgNo];
     asset.selected = !asset.selected;
     _selectButton.selected  =   asset.selected;
    [_parent showSelectedTitleWithVC:self];
//    [_parent reloadCellForAssetSelectChange:asset];
}


-(void)doSelectFinish{
//    [self.navigationController popViewControllerAnimated:YES];
    [_parent doSelectFinishWithVC:self];
    
    /*
    NSMutableArray *selectedAssetsImages = [[NSMutableArray alloc] init];
    for (ELCAsset *elcAsset in _parent.elcAssets) {
        if ([elcAsset selected]) {
            [selectedAssetsImages addObject:elcAsset];
        }
    }
    [self.view showProgressHUD];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        AC_PreViewImages* pPreview = [[AC_PreViewImages alloc] initWithNibName:nil bundle:nil];
        pPreview.parent = _parent;
        pPreview.selectedAssets =   selectedAssetsImages;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_parent presentViewController:pPreview animated:YES completion:nil];
            [self.view hideProgressHUDWithAnimated:NO];
            [self.navigationController popViewControllerAnimated:NO];
        });
    });*/
}

#pragma mark AC_ImgsScrollViewDelegate

-(NSInteger)AC_image_count{
    return _parent.elcAssets.count;
}


-(void)AC_image_AtIndex:(NSInteger)nIndex withBlock:(ELCAsset_LoadImgBlock)block{
    if(_fullScreenCachingManger){
        [_fullScreenCachingManger loadImgNo:nIndex
                                  withBlock:block];
    }
    else{
        block([((ELCAsset*)_parent.elcAssets[nIndex]) loadImgForALAsset:ELCAssetLoad_FullScreen]);
    }
}


-(void)AC_image_FocusAtIndex:(NSInteger)nIndex forNext:(BOOL)bNext{
    _selectButton.selected = ((ELCAsset*)_parent.elcAssets[nIndex]).selected;
    
    //检查缓存
    [_fullScreenCachingManger cacheCheck:nIndex forNext:bNext];
}

-(void)AC_image_Unuse_AtIndex:(NSInteger)nIndex{
//    ((ELCAsset*)_parent.elcAssets[nIndex]).imageForSend = nil;
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
