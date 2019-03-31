//
//  AC_PreViewImages.m
//  PicSelectUI
//
//  Created by Aculearn on 15/10/19.
//  Copyright © 2015年 Aculearn. All rights reserved.
//

#import "ELCAssetTablePicker.h"
#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "AC_PreViewImagesWithCaption.h"
#import "UINavigationController+Additions.h"
#import "UIImage+Additions.h"
#import "AC_ImgsScrollView.h"

#define AC_ThumbButton_OneLine_Count   (AC_PreViewImage_Max_Count/2)   //每行按钮数
#define AC_ThumbButton_Delta           5   //间距
#define AC_Caption_Max_Len             200

extern const CFStringRef kUTTypeImage;


@interface AC_ImageItemPreView : AC_ImgsScrollItem{
    @public
//    int                 nIndexNo;
//    UIImage*            image;
    ELCAsset*           assertItem;
    AC_ThumbButton*     thumbButton;
//    UIScrollView*       showImageView;
}


-(instancetype)initWithELCAsset:(ELCAsset*)assertItem
                      withFrame:(CGRect)frame;
-(instancetype)initWithImg:(UIImage*)img
                      withFrame:(CGRect)frame;
@end



@interface AC_PreViewImagesWithCaption (){
    BOOL        _forCamera_RemoveCallMode; //进入删除最后一个的拍照模式
    UIImage*    _forCamera_FirstImg;
    __weak id<ELCImagePickerControllerDelegate> _forCamera_imagePickerDelegate;
    
    
    NSMutableArray<AC_ImageItemPreView*>* _pShowImageItems;
    CGFloat         _fthumbButtonHightOneLine;    //一行按钮的高度 (width/AC_ThumbButton_OneLine_Count)
//    AC_ImageItem*  _nowFocusItem;
    UIScrollView * _imgPreView;
    UIView      *_imgThumbView;
    
    UITextView  *_captionTextView;
    UILabel*    _lblPlaceholder;
    CGFloat     _textViewMaxHight; //文本最大高度
    CGFloat     _keyboardShowedY; //键盘显示了
    BOOL        _callDeleteOnKeyboardShowed; //显示键盘时，调用过删除
    UITapGestureRecognizer* _preViewTapForKeyboard;
}
@property (strong,nonatomic) AC_ImageItemPreView*  nowFocusItem;
@end

@implementation AC_PreViewImagesWithCaption

AC_MEM_Dealloc_implementation

#define ImageView_Delta 10

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor whiteColor];
    _pShowImageItems          =   [[NSMutableArray alloc] initWithCapacity:10];
    _fthumbButtonHightOneLine =   (self.view.frame.size.width/AC_ThumbButton_OneLine_Count);
    
#if 1
    {
        
       UIToolbar* toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 64-40, self.view.frame.size.width, 40)];
        UIBarButtonItem *fixedButton  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace target: nil action: nil];

        toolBar.items   =   @[
                               [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)  style:UIBarButtonItemStylePlain target:self action:@selector(onCancel:)],
                               
                               fixedButton,
                               
                               [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(onDelete:)],
                               
                               fixedButton,
                               
                               [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send", nil)  style:UIBarButtonItemStylePlain target:self action:@selector(onSend:)]
                               ];
        
        //去掉背景颜色
        [toolBar setBackgroundImage:[UIImage new] forToolbarPosition:UIBarPositionAny  barMetrics:UIBarMetricsDefault];
        [toolBar setShadowImage:[UIImage new]
                  forToolbarPosition:UIToolbarPositionAny];
        [self.view addSubview:toolBar];
    }
#else
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)  style:UIBarButtonItemStylePlain target:self action:@selector(onCancel:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send", nil)  style:UIBarButtonItemStylePlain target:self action:@selector(onSend:)];
        self.navigationItem.titleView   =   self.navigationItem.rightBarButtonItem;
    }
#endif
    
//    ITLogEX(@"%@",self.view);
//    self.view.backgroundColor = [UIColor redColor];
    
    
    //图片预览
    _imgPreView =   [[UIScrollView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, 400)];
    _imgPreView.showsHorizontalScrollIndicator = NO;
    _imgPreView.pagingEnabled = YES;
    [self.view addSubview:_imgPreView];
    
    //缩略图按钮
    _imgThumbView   =   [[UIView alloc] initWithFrame:_imgPreView.frame];
    _imgThumbView.backgroundColor = [UIColor groupTableViewBackgroundColor];

    //头顶上的横线
    {
        UIView* lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
        lineView.backgroundColor = [UIColor lightGrayColor];
        [_imgThumbView addSubview:lineView];
    }
  

    //输入框
    {
        _captionTextView    =   [[UITextView alloc] initWithFrame:CGRectMake(AC_ThumbButton_Delta+1, AC_ThumbButton_Delta, self.view.frame.size.width-AC_ThumbButton_Delta-AC_ThumbButton_Delta, 30)];
    #if TARGET_IPHONE_SIMULATOR
    //    _captionTextView.text = @"点击以添加描述...";
    #endif
        _captionTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        _captionTextView.layer.borderWidth =1.0;
        _captionTextView.layer.cornerRadius =5.0;
    //    _captionTextView.backgroundColor = [UIColor clearColor];
        //_textView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:.3];
    //    _textView.delegate = self;
    //    _textView.contentInset = UIEdgeInsetsMake(0, -2, -4, 0);
        _captionTextView.showsVerticalScrollIndicator = NO;
        _captionTextView.showsHorizontalScrollIndicator = NO;
        _captionTextView.font = [UIFont systemFontOfSize:16.0f];
        _captionTextView.returnKeyType = UIReturnKeyDone;
        _captionTextView.delegate = self;
        
        [_captionTextView setFrame_height:[_captionTextView sizeThatFits:CGSizeMake(_captionTextView.frame.size.width, MAXFLOAT)].height];
        
        [_imgThumbView addSubview:_captionTextView];
        
        CGRect frameTemp =  _captionTextView.frame;
        frameTemp.origin.x += 2;
        _lblPlaceholder = [[UILabel alloc] initWithFrame:frameTemp];
        _lblPlaceholder.font = [UIFont systemFontOfSize:16.0f];
        _lblPlaceholder.text = NSLocalizedString(@"Add caption", nil);
        _lblPlaceholder.textColor =  [UIColor lightGrayColor]; //UIColor_RGB(0, 0x7d, 0xFF); //[UIColor blueColor];
        _lblPlaceholder.backgroundColor = [UIColor clearColor];
        [_imgThumbView addSubview:_lblPlaceholder];
        
        _textViewMaxHight =     3*([@"唐" sizeWithFont:_captionTextView.font].height)+
                                (_captionTextView.contentInset.top
//                                + _captionTextView.contentInset.bottom
                                 + _captionTextView.textContainerInset.top);
//                                + _captionTextView.textContainerInset.bottom);//+self.textview.textContainer.lineFragmentPadding/*top*//*+theTextView.textContainer.lineFragmentPadding*//*there is no bottom padding*/);
        
//        CGSize size = [@"市长管钱，书记管人，市长的腰杆硬不硬就看手里掌握的钱袋子鼓不鼓。李治国自调到沪东市后，尽管市里财政收入还不错，但每天要钱的大小官员依然挤满了办公室，手里的余钱并不够他施展抱负的需要。修高架，要钱；修地铁，要钱；扩建机场，要钱；兴建高新区，要钱……现在来钱最快的途径是什么，卖地！土地财政收入成本低，见效快，是每一位市长考虑的首选。" sizeWithFont:_captionTextView.font];
//        
//        ITLog(@"xx");
    }
    
    
    [self.view addSubview:_imgThumbView];
    
    
    CGFloat fX = ImageView_Delta;
    CGFloat fW = _imgPreView.bounds.size.width-ImageView_Delta-ImageView_Delta;
    CGFloat fH = _imgPreView.bounds.size.height;
    
    
    if(_forCamera_FirstImg){
        AC_ImageItemPreView* pImgItem = [[AC_ImageItemPreView alloc] initWithImg:_forCamera_FirstImg
                                                                       withFrame:CGRectMake(fX, 0, fW, fH)];
        
        [_pShowImageItems addObject:pImgItem];
        [_imgPreView addSubview:pImgItem];
        fX  +=  _imgPreView.bounds.size.width;
        _forCamera_FirstImg = nil;
    }
    else{
        NSInteger nImageCount = _parent.selectedELCAssets.count;
        
    //    [self checkThumbCount:nImageCount];
        for(int i=0;i<nImageCount;i++){
            AC_ImageItemPreView* pImgItem = [[AC_ImageItemPreView alloc] initWithELCAsset:_parent.selectedELCAssets[i] withFrame:CGRectMake(fX, 0, fW, fH)];
            [_pShowImageItems addObject:pImgItem];
            [_imgPreView addSubview:pImgItem];
            fX  +=  _imgPreView.bounds.size.width;
        }
    }
    
    _imgPreView.contentSize = CGSizeMake(fX, fH);
    _imgPreView.minimumZoomScale = 1;
    _imgPreView.maximumZoomScale = 2;
    _imgPreView.delegate = self;
   
    //添加 +
    AC_ImageItemPreView* pItemAdd = [[AC_ImageItemPreView alloc] init];
    [_pShowImageItems addObject:pItemAdd];
    
    for(int i=0;i<_pShowImageItems.count;i++){
        [self _addThumbButtonForIndex:i];
    }
    
    self.nowFocusItem   =   _pShowImageItems.firstObject;
//    _nowFocusItem->thumbButton.selected = YES;
    
    [self _checkThumbViewFrameForButtonChange:YES];
}

-(void)_addThumbButtonForIndex:(NSInteger) nIndex{
    AC_ImageItemPreView* pItem =  _pShowImageItems[nIndex];
    CGFloat fthumbButtonWH = _fthumbButtonHightOneLine-AC_ThumbButton_Delta;
    pItem->thumbButton  =   [[AC_ThumbButton alloc] initWithFrame:CGRectMake(-100, 0, fthumbButtonWH, fthumbButtonWH)];
    //        [pItem->thumbButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    //        [pItem->thumbButton setImage:pItem==pItemAdd?[UIImage imageNamed:@"gr_member_add_icon"]:pItem->assertItem.imageForSend forState:UIControlStateNormal];
    UIImage* pButtonImg = nil;
    BOOL bIsAddButton = nIndex==_pShowImageItems.count-1;
    if(_forCamera_imagePickerDelegate){
        pButtonImg  =   bIsAddButton?[UIImage imageNamed:@"sharemore_video_ios7"]:pItem.image;
    }
    else{
        if(bIsAddButton){
            pButtonImg  =   [UIImage imageNamed:@"gr_member_add_icon"];
        }
        else{
            [pItem->assertItem loadThumbWithBlock:^(UIImage *img) {
                [pItem->thumbButton setImage:img forState:UIControlStateNormal];
            }];
        }
    }
    
    if(pButtonImg){
        [pItem->thumbButton setImage:pButtonImg forState:UIControlStateNormal];
    }
    
    [_imgThumbView addSubview:pItem->thumbButton];
    pItem->thumbButton.tag  =   nIndex;
    [pItem->thumbButton addTarget:self action:@selector(onThumbButton:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    // 键盘高度变化通知
    [nc addObserver:self selector:@selector(keyboardHightChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
//    ITLogEX(@"%@",self.view);
    [self _checkThumbViewFrameForButtonChange:NO];
}

-(void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidAppear:animated];
}


-(void)setNowFocusItem:(AC_ImageItemPreView*)newValue{
    [_captionTextView unmarkText];
    if(_nowFocusItem){
        _nowFocusItem.zoomScale = 1.0;
        _nowFocusItem->thumbButton.selected = NO;
        if(_keyboardShowedY>0){
            //保存改变的文本
            _nowFocusItem->assertItem.caption = _captionTextView.text;
        }
    }
    _nowFocusItem   =   newValue;
    _nowFocusItem->thumbButton.selected = YES;
    if(_captionTextView){
//        _captionTextView.selectedRange = NSMakeRange(0, 0);
        _captionTextView.text   =   _nowFocusItem->assertItem.caption;
        _lblPlaceholder.hidden  =   _keyboardShowedY>0||_nowFocusItem->assertItem.caption.length>0;
        [self _captionTextChanged:YES];
    }
}

- (void)onSend:(id)sender {
    if(_keyboardShowedY>0){
        [_captionTextView unmarkText];
        _nowFocusItem->assertItem.caption = _captionTextView.text;
    }
    
    if(_forCamera_imagePickerDelegate){
        id<ELCImagePickerControllerDelegate> delegate = _forCamera_imagePickerDelegate;
        [_pShowImageItems removeLastObject];
        NSMutableArray *sendImages = [[NSMutableArray alloc] init];
        for(AC_ImageItemPreView* item in _pShowImageItems){
            ELCSelectedImageInfo* temp = [[ELCSelectedImageInfo alloc] init];
            temp.image  =   item.image;
            temp.caption=   item->assertItem.caption;
            [sendImages addObject:temp];
        }
        [self dismissViewControllerAnimated:NO completion:^{
            [delegate elcImagePickerController:nil
                          sendPreviewImgWithCaptions:sendImages];
        }];
        return;
    }
    
    
    ELCAssetTablePicker* parent = _parent; //在IOS7 上，_parent会被设置为nil
    [self dismissViewControllerAnimated:NO completion:nil];
    [parent previewAssetsFinish];
}

-(void)_deleteItem:(AC_ImageItemPreView*) pDelItem{
    pDelItem->assertItem.selected = NO;
    pDelItem->assertItem.caption = nil;
//    pDelItem->assertItem.imageForSend = nil;
    [pDelItem->thumbButton removeFromSuperview];
    [pDelItem removeFromSuperview];
}

- (void)onDelete:(id)sender {
    if(2==_pShowImageItems.count){
        
        if(_forCamera_imagePickerDelegate){
            [self _Camera];
            _forCamera_RemoveCallMode = YES;
            return;
        }
        
        //删除完了
        [self _deleteItem:_pShowImageItems.firstObject];
        [_pShowImageItems removeAllObjects];
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    int nDelNo =   _imgPreView.contentOffset.x/_imgPreView.bounds.size.width;
    AC_ImageItemPreView* pDelItem =   _pShowImageItems[nDelNo];
//    [_parent reloadCellForAssetSelectChange:pDelItem->assertItem];
    [_pShowImageItems removeObjectAtIndex:nDelNo];
    
    [UIView animateWithDuration:0.4 animations:^{
        //删除预览View
        int nIndex =    nDelNo;
        CGRect  ImageFrame = pDelItem.frame;
        CGFloat fX  =    ImageFrame.origin.x;
        CGFloat fH  =   _imgPreView.bounds.size.height;
        pDelItem.frame = CGRectMake(ImageFrame.origin.x, ImageFrame.origin.y-fH, ImageFrame.size.width, ImageFrame.size.height);
        
        _nowFocusItem->thumbButton.hidden = YES;
        if(_pShowImageItems.count>1){
            _nowFocusItem   =   _pShowImageItems[(nIndex==_pShowImageItems.count-1)?nIndex-1:nIndex];
            _nowFocusItem->thumbButton.selected = YES;
        }
        else{
            _nowFocusItem = _pShowImageItems.lastObject;
        }
        
        for(;nIndex<_pShowImageItems.count-1;nIndex++){
            AC_ImageItemPreView* pCheckItem = _pShowImageItems[nIndex];
            pCheckItem->thumbButton.tag =   nIndex;
            ImageFrame.origin.x =   fX;
            pCheckItem.frame = ImageFrame;
            fX += _imgPreView.bounds.size.width;
        }
        _imgPreView.contentSize = CGSizeMake(fX, fH);
        ((AC_ImageItemPreView*)_pShowImageItems.lastObject)->thumbButton.tag =   nIndex;
        //处理Button
        
//        _captionTextView.selectedRange = NSMakeRange(0, 0);
        [_captionTextView unmarkText];
        _captionTextView.text   =   _nowFocusItem->assertItem.caption;
        if(_keyboardShowedY>0){
            _callDeleteOnKeyboardShowed = YES;
            [self _captionTextChanged:YES];
        }
        else{
            [self _checkThumbViewFrameForButtonChange:YES];
        }
        
    } completion:^(BOOL finished) {
        [self _deleteItem:pDelItem];
    }];
}


- (void)onCancel:(id)sender {
//    for(AC_ImageItemPreView* pCheckItem in _pShowImageItems){
//        //清除内存占用
//        pCheckItem->assertItem.imageForSend = nil;
//    }
    if(_forCamera_imagePickerDelegate){
        id<ELCImagePickerControllerDelegate> delegate = _forCamera_imagePickerDelegate;
         [self dismissViewControllerAnimated:NO completion:^{
            [delegate elcImagePickerControllerDidCancel:nil];
        }];
        return;
    }
    
    ELCAssetTablePicker* parent = _parent; //在IOS7 上，_parent会被设置为nil
    [self dismissViewControllerAnimated:NO completion:nil];
    [parent.parent cancelSelectAssert];
}


-(void)onThumbButton:(AC_ThumbButton*)sender{
    if(sender.tag==_pShowImageItems.count-1){
        
        if(_forCamera_imagePickerDelegate){
            [self _Camera];
            return;
        }
        
        //添加
//        [self.navigationController popViewControllerAnimated:YES];
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    AC_ImageItemPreView* pCheckItem = _pShowImageItems[sender.tag];

    //焦点
    if(pCheckItem==_nowFocusItem){
        return;
    }
    
    [UIView animateWithDuration:0.4 animations:^{
        self.nowFocusItem = pCheckItem;
        _imgPreView.contentOffset   =   CGPointMake(sender.tag*_imgPreView.bounds.size.width, 0);
    }];
}

-(void)_checkThumbViewFrameForButtonChange:(BOOL)bButtonChange{
    
    //检查个数，修改各种View的高度
    
    //留白 =  AC_ThumbButton_Delta
    if(_keyboardShowedY>0){
        return;
    }
    
    {
        CGFloat fHightFor_imgThumbView = (_pShowImageItems.count>AC_ThumbButton_OneLine_Count?(_fthumbButtonHightOneLine*2):_fthumbButtonHightOneLine)+1+AC_ThumbButton_Delta+AC_ThumbButton_Delta; //分割线+上下的留白
        
        if(_captionTextView){
            fHightFor_imgThumbView +=    CGRectGetHeight(_captionTextView.frame)+AC_ThumbButton_Delta; //上下留白
            _lblPlaceholder.hidden =    _captionTextView.text.length>0;
        }
        
        CGRect  frameForThumbView = _imgThumbView.frame;
        CGFloat fThumbViewY =    CGRectGetMaxY(self.view.bounds)-fHightFor_imgThumbView;
        if(CGRectGetHeight(frameForThumbView)!=fHightFor_imgThumbView||
           fThumbViewY!=frameForThumbView.origin.y){
            
            //修改ThumbView
            frameForThumbView.origin.y  =   fThumbViewY;
            frameForThumbView.size.height = fHightFor_imgThumbView;
            _imgThumbView.frame =   frameForThumbView;
            
            //修改预览
            frameForThumbView   =   _imgPreView.frame;
            CGFloat fH = frameForThumbView.size.height = _imgThumbView.frame.origin.y-CGRectGetMinY(frameForThumbView);
            _imgPreView.contentSize = CGSizeMake(_imgPreView.contentSize.width, fH);
            _imgPreView.frame   =   frameForThumbView;
            
            for(NSInteger nIndex=0;nIndex<_pShowImageItems.count-1;nIndex++){
                AC_ImageItemPreView* pCheckItem = _pShowImageItems[nIndex];
                frameForThumbView   =   pCheckItem.frame;
                frameForThumbView.size.height   =   fH;
                pCheckItem.frame =   frameForThumbView;
            }
            bButtonChange = YES;
        }
    }
    
    if(!bButtonChange){
        return;
    }

/*
    1、最多10个，两行，每行
    2、最多两行
 */
    
    CGFloat marginX = (_imgThumbView.bounds.size.width - AC_ThumbButton_OneLine_Count * _fthumbButtonHightOneLine) / (AC_ThumbButton_OneLine_Count + 1);
    CGFloat fX = marginX;
    CGFloat fY = _imgThumbView.bounds.size.height-_fthumbButtonHightOneLine-(AC_ThumbButton_Delta/2.0);
    CGFloat fthumbButtonWH = _fthumbButtonHightOneLine-AC_ThumbButton_Delta;
    
    NSInteger nFirstLineButtonCount = _pShowImageItems.count;
    
    if(_pShowImageItems.count>AC_ThumbButton_OneLine_Count){
        //两行
        NSInteger nSecountButtonNo = 0;
        if(_pShowImageItems.count>AC_PreViewImage_Max_Count){
            nSecountButtonNo    =   nFirstLineButtonCount = AC_ThumbButton_OneLine_Count;
        }
        else{
            nSecountButtonNo        =   _pShowImageItems.count-AC_ThumbButton_OneLine_Count;
            nFirstLineButtonCount   =   nSecountButtonNo;
        }
        
        //显示第二行
//        CGFloat fSecoundY = fY+_fthumbButtonHightOneLine;
//        fY -= _fthumbButtonHightOneLine;
        for(;nSecountButtonNo<_pShowImageItems.count;nSecountButtonNo++,fX+=_fthumbButtonHightOneLine){
            AC_ImageItemPreView* pDelItem =   _pShowImageItems[nSecountButtonNo];
            pDelItem->thumbButton.frame =   CGRectMake(fX, fY, fthumbButtonWH, fthumbButtonWH);
        }
        fX = marginX;
        fY -= _fthumbButtonHightOneLine;
    }
    
    //第一行
    for(NSInteger nFirstNo=0;nFirstNo<nFirstLineButtonCount;nFirstNo++,fX+=_fthumbButtonHightOneLine){
        AC_ImageItemPreView* pDelItem =   _pShowImageItems[nFirstNo];
        pDelItem->thumbButton.frame =   CGRectMake(fX, fY, fthumbButtonWH, fthumbButtonWH);
    }
   
/*
    // 搭建界面，九宫格
    // 320 - 3 * 80 = 80 / 4 = 20
    CGFloat marginX = (self.view.bounds.size.width - kColCount * kAppViewW) / (kColCount + 1);
    CGFloat marginY = 10;
    
    for (int i = 0; i < self.appList.count; i++) {
        // 行
        // 0, 1, 2 => 0
        // 3, 4, 5 => 1
        int row = i / kColCount;
        
        // 列
        // 0, 3, 6 => 0
        // 1, 4, 7 => 1
        // 2, 5, 8 => 2
        int col = i % kColCount;
        
        CGFloat x = marginX + col * (marginX + kAppViewW);
        CGFloat y = kStartY + marginY + row * (marginY + kAppViewH);
*/
    
}

#pragma mark UITextViewDelegate
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([text isEqualToString:@"\n"]) {
        _nowFocusItem->assertItem.caption = _captionTextView.text;
        [textView resignFirstResponder];
        return NO;
    }
    
    NSString *temp = [textView.text
                      stringByReplacingCharactersInRange:range
                      withString:text];
    
    if(temp.length>AC_Caption_Max_Len){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil)
                                                            message:NSLocalizedString(@"Can't_Input_More", nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles: nil];
        [alertView show];
        return NO;
    }
    
    return YES;
}
-(void)textViewDidChange:(UITextView *)textView{
    //修改文本高度
//    if(textView.text.length>AC_Caption_Max_Len){
//        textView.text = [textView.text substringToIndex:AC_Caption_Max_Len-1];
//        在中文环境下会出现BUg
//    }
//    _nowFocusItem->assertItem.caption = textView.text;
    [self _captionTextChanged:NO];
}

-(void)_captionTextChanged:(BOOL)bForChangeNowFoucsItem{
    //修改输入框高度，避免超过3行高度

    CGRect frameOld =   _captionTextView.frame;
    CGSize size = [_captionTextView sizeThatFits:CGSizeMake(frameOld.size.width, MAXFLOAT)];
    CGFloat fNewHight = MIN(size.height,_textViewMaxHight);
    if(fNewHight!=frameOld.size.height){
         //改变了高度,不需要动画
        if(_keyboardShowedY>0){
           //显示了键盘，则动画改变文本高度
            [UIView animateWithDuration:0.3 animations:^{
                [_captionTextView setFrame_height:fNewHight];
                if(bForChangeNowFoucsItem){
                    //滚动到最后
                    [_captionTextView scrollRangeToVisible:NSMakeRange(_captionTextView.text.length, 1)];
                }
                [self _captionChangedWithKeyboardRect];
            }];
            return;
        }
        else{
            [_captionTextView setFrame_height:fNewHight];
           [self _checkThumbViewFrameForButtonChange:NO];
        }
    }
}


//http://blog.csdn.net/fengsh998/article/details/45442391
 

-(void)_captionChangedWithKeyboardRect{
    CGRect thumbRect = _imgThumbView.frame;
    thumbRect.origin.y = _keyboardShowedY-CGRectGetMaxY(_captionTextView.frame)-AC_ThumbButton_Delta+1;
    _imgThumbView.frame =   thumbRect;
    
//  实现后有些奇怪
//    [_imgPreView setFrame_height:CGRectGetMinY(thumbRect)-_imgPreView.frame.origin.y];
}


#pragma mark UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{      // called when scroll view grinds to a halt
    if(scrollView==_imgPreView){
        int nDelNo =   _imgPreView.contentOffset.x/_imgPreView.bounds.size.width;
        AC_ImageItemPreView* pDelItem =   _pShowImageItems[nDelNo];
        if(pDelItem!=_nowFocusItem){
            self.nowFocusItem = pDelItem;
            
//            for (UIScrollView *s in scrollView.subviews){
//                if ([s isKindOfClass:[UIScrollView class]]){
//                    [s setZoomScale:1.0];
//                    //scrollView每滑动一次将要出现的图片较正常时候图片的倍数（将要出现的图片显示的倍数）
//                }
//            }

        }
    }
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
//{
//    if(interfaceOrientation ==UIInterfaceOrientationPortrait||interfaceOrientation ==UIInterfaceOrientationPortraitUpsideDown)
//    {
//        return YES;
//    }
//    return NO;
//}

#pragma mark -UIImagePickerControllerDelegate

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if(_forCamera_RemoveCallMode){
        //放弃
        [picker ACdismissViewControllerAnimated:NO completion:nil];
        [self onCancel:nil];
        return;
    }
    
    [picker ACdismissViewControllerAnimated:YES completion:nil];
}
//extern const CFStringRef kUTTypeImage;

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //预览并发送
//    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    UIImage* pImg = [info objectForKey:UIImagePickerControllerOriginalImage];
        //         UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    UIImageWriteToSavedPhotosAlbum(pImg, self, nil, nil); //保存图片
    
    if(_forCamera_RemoveCallMode){
        //删除拍照模式
        NSAssert(_pShowImageItems.count==2,@"_pShowImageItems.count==2");
        AC_ImageItemPreView* pImgItem = _pShowImageItems.firstObject;
        pImgItem.image =    pImg;
        [pImgItem->thumbButton setImage:pImg forState:UIControlStateNormal];
        [picker ACdismissViewControllerAnimated:YES completion:nil];
        return;
    }
    

    NSInteger nIndex =  _pShowImageItems.count-1;
    
    CGFloat fX = nIndex*_imgPreView.bounds.size.width+ImageView_Delta;
    CGFloat fW = _imgPreView.bounds.size.width-ImageView_Delta-ImageView_Delta;
    CGFloat fH = _imgPreView.bounds.size.height;
    
    AC_ImageItemPreView* pImgItem = [[AC_ImageItemPreView alloc] initWithImg:pImg
                                                                   withFrame:CGRectMake(fX, 0, fW, fH)];
    
    [_pShowImageItems insertObject:pImgItem atIndex:nIndex];
    [_imgPreView addSubview:pImgItem];
    [self _addThumbButtonForIndex:nIndex];
    _imgPreView.contentSize = CGSizeMake(fX+_imgPreView.bounds.size.width, fH);
    ((AC_ImageItemPreView*)_pShowImageItems.lastObject)->thumbButton.tag = _pShowImageItems.count-1;
    
    [self _checkThumbViewFrameForButtonChange:YES];
    
    _imgPreView.contentOffset = CGPointMake(fX, 0);
    self.nowFocusItem = pImgItem;
    
    [picker ACdismissViewControllerAnimated:YES completion:nil];
}

+(void)showPreviewWithCaptionForCameraWithDelegate:(id<ELCImagePickerControllerDelegate>) imagePickerDelegateForCamera
                                withImg:(UIImage*)firstImg
                               fromView:(UIViewController*)pVC
{
    AC_PreViewImagesWithCaption* pPreview = [[AC_PreViewImagesWithCaption alloc] initWithNibName:nil bundle:nil];
    AC_MEM_Alloc(pPreview);
    pPreview->_forCamera_imagePickerDelegate = imagePickerDelegateForCamera;
    pPreview->_forCamera_FirstImg = firstImg;
    [pVC ACpresentViewController:pPreview animated:YES completion:nil];
}

-(void)_Camera{
    _forCamera_RemoveCallMode = NO;
    [self selectImageWithUIImagePickerController_Delegate:self forCamera:YES];
    /*
    UIImagePickerController *imagePC = [[UIImagePickerController alloc] init];
    imagePC.delegate = self;
    imagePC.videoQuality = UIImagePickerControllerQualityType640x480;
    imagePC.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePC.mediaTypes = @[(__bridge NSString *)kUTTypeImage];
    [self ACpresentViewController:imagePC animated:YES completion:nil];*/
}



#pragma mark Responding to keyboard events

-(void)_keyboardShowOrHide:(NSNotification *)notification forShow:(int)bShow{
    
    NSDictionary *userInfo = [notification userInfo];
    
    // Shrink view's inset by the keyboard's height, and scroll to show the text field/view being edited
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];
    
    if(bShow){
        
        // Get the origin of the keyboard when it's displayed.
        NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
        
        // Get the top of the keyboard as the y coordinate of its origin in self's view's coordinate system. The bottom of the text view's frame should align with the top of the keyboard's final position.
        _keyboardShowedY = CGRectGetMinY([aValue CGRectValue]);

        
        if(1==bShow){
            //第一次显示
            _callDeleteOnKeyboardShowed =   NO;
            _lblPlaceholder.hidden = YES;
        }
        //高度变化
        [self _captionChangedWithKeyboardRect];
    }
    else{
        for(AC_ImageItemPreView* item in _pShowImageItems){
            item->thumbButton.hidden =  NO;
        }
        _keyboardShowedY = 0;
        _nowFocusItem->assertItem.caption = _captionTextView.text;
        if(_nowFocusItem->assertItem.caption.length){
            //滚动到顶部
            [_captionTextView scrollRangeToVisible:NSMakeRange(0, 1)];
        }
        [self _checkThumbViewFrameForButtonChange:_callDeleteOnKeyboardShowed];
    }
    [UIView commitAnimations];
}

-(void)keyboardDidShow:(NSNotification *)notification{
    for(AC_ImageItemPreView* item in _pShowImageItems){
        item->thumbButton.hidden =  YES;
    }
}

- (void)keyboardWillShow:(NSNotification *)notification {
    
    if(nil==_preViewTapForKeyboard){
        _preViewTapForKeyboard = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_keyboardHideForUser)];
    }
    [_imgPreView addGestureRecognizer:_preViewTapForKeyboard];
    [self _keyboardShowOrHide:notification forShow:1];
}

-(void)keyboardHightChange:(NSNotification *)notification{
    [self _keyboardShowOrHide:notification forShow:2];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [_imgPreView removeGestureRecognizer:_preViewTapForKeyboard];
    [self _keyboardShowOrHide:notification forShow:0];
}

-(void)_keyboardHideForUser{
    [_captionTextView resignFirstResponder];
}


@end


@implementation AC_ImageItemPreView
-(instancetype)initWithELCAsset:(ELCAsset*)assert_Item
                      withFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        assertItem  =   assert_Item;
//        self.image  =   assert_Item.imageForSend;
        self.image = assert_Item.fullScreenImageNoCache;
    }
    return self;
}

-(instancetype)initWithImg:(UIImage*)img
                      withFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        //        self.image  =   assert_Item.imageForSend;
        assertItem = [ELCAsset new];
        self.image = img;
    }
    return self;
}

@end

@implementation AC_ThumbButton


-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    self.adjustsImageWhenHighlighted = NO;
    //    self.contentEdgeInsets = UIEdgeInsetsMake(1,1,1,1);
    [self.layer setMasksToBounds:YES];
    [self.layer setBorderWidth:2.0];
    [self.layer setCornerRadius:5];
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    if(self.isSelected||self.isHighlighted){
        // General Declarations
        [self.layer setBorderColor:UIColor_RGB(0, 0x7d, 0xFF).CGColor];
        
        //        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        //        UIBezierPath *roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) cornerRadius: 5];
        //        // Use the bezier as a clipping path
        //        [roundedRectanglePath addClip];
        //
        //        UIColor* borderColor = [UIColor blueColor];
        //
        //        [borderColor setStroke];
        //        roundedRectanglePath.lineWidth = 2;
        //        [roundedRectanglePath stroke];
        //
        //        // Cleanup
        //        CGColorSpaceRelease(colorSpace);
    }
    else{
        [self.layer setBorderColor:[UIColor whiteColor].CGColor];
    }
}

-(void)setHighlighted:(BOOL)highlighted{
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}


@end
