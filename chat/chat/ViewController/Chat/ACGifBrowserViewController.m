//
//  ACGifBrowserViewController.m
//  chat
//
//  Created by 王方帅 on 14-5-25.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACGifBrowserViewController.h"
#import "ACAddress.h"
#import "UINavigationController+Additions.h"
#import "UIImageView+WebCache.h"
#import "UIView+Additions.h"
#import "ACNetCenter.h"

@interface ACGifBrowserViewController ()

@end

@implementation ACGifBrowserViewController

- (void)dealloc
{
    AC_MEM_Dealloc();
    if (_pngImageView)
    {
        [_pngImageView removeObserver:self forKeyPath:@"image"];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (![ACConfigs isPhone5])
    {
        [_contentView setFrame_height:_contentView.size.height-88];
    }
    
//    [_backButton setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateNormal];
    
    NSString *filePath = [UIImageView getStickerSaveAddressWithPath:_stickerMessage.stickerPath withName:_stickerMessage.stickerName];
    
    if ([_stickerMessage.stickerName hasSuffix:@".gif"])
    {
        UIWebView *webView = [[UIWebView alloc] init];
        webView.scrollView.scrollEnabled = NO;
        webView.delegate = self;
        [_contentView addSubview:webView];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
        {
            UIImage *image = [UIImage imageWithContentsOfFile:filePath];
            webView.size = image.size;
            webView.center = CGPointMake(_contentView.size.width/2.0, _contentView.size.height/2.0);
            [webView loadData:[NSData dataWithContentsOfFile:filePath] MIMEType:@"image/gif" textEncodingName:nil baseURL:nil];
        }
        else
        {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
//                [_contentView showProgressHUDWithLabelText:nil withAnimated:NO];
                [_contentView showNetLoadingWithAnimated:NO];
                NSString *url = [NSString stringWithFormat:@"%@/ujs/app/im/res/emoji/%@/%@",[[ACNetCenter shareNetCenter] acucomServer],_stickerMessage.stickerPath,_stickerMessage.stickerName];
                NSData *gifData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
                UIImage *image = [UIImage imageWithData:gifData];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    webView.scrollView.scrollEnabled = NO;
                    webView.size = image.size;
                    webView.center = CGPointMake(_contentView.size.width/2.0, _contentView.size.height/2.0);
                    [webView loadData:gifData MIMEType:@"image/gif" textEncodingName:nil baseURL:nil];
                });
                [gifData writeToFile:filePath atomically:YES];
            });
        }
    }
    else
    {
        _pngImageView = [[UIImageView alloc] init];
        _pngImageView.frame = CGRectZero;
        [_contentView addSubview:_pngImageView];
        [_pngImageView addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];
        [_pngImageView setStickerWithStickerPath:_stickerMessage.stickerPath stickerName:_stickerMessage.stickerName placeholderImage:[UIImage imageNamed:@"image_placeHolder.png"]];
    }
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self initHotspot];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initHotspot];
}

#pragma mark -notification
-(void)hotspotStateChange:(NSNotification *)noti
{
    if (_isOpenHotspot)
    {
        [_contentView setFrame_height:_contentView.size.height-hotsoptHeight];
    }
    else
    {
        [_contentView setFrame_height:_contentView.size.height+hotsoptHeight];
    }
    _pngImageView.center = CGPointMake(_contentView.size.width/2.0, _contentView.size.height/2.0);
}

#pragma mark -UIWebView
-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_contentView hideProgressHUDWithAnimated:NO];
}

#pragma mark -kvo
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _pngImageView && [keyPath isEqualToString:@"image"])
    {
        _pngImageView.size = _pngImageView.image.size;
        _pngImageView.center = CGPointMake(_contentView.size.width/2.0, _contentView.size.height/2.0);
    }
}

#pragma mark -IBAction
-(IBAction)goback:(id)sender
{
    [self.navigationController ACpopViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
