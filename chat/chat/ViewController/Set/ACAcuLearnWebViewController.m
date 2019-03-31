//
//  ACAcuLearnWebViewController.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-25.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACAcuLearnWebViewController.h"
#import "UINavigationController+Additions.h"
#import "ACNetCenter.h"
#import "UIView+Additions.h"
#import "ACUrlEditViewController.h"

NSString *const kJoinAlertShowSuccessNotification = @"kJoinAlertShowSuccessNotification";

@interface UIWebView (JavaScriptAlert)

- (void)webView:(UIWebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(CGRect)frame;

@end

@implementation UIWebView (JavaScriptAlert)

#define kWebAlert 1233

- (void)webView:(UIWebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(CGRect)frame {
    if ([message isEqualToString:@"error:Please do not miss any one question"])
    {
        AC_ShowTip(NSLocalizedString(@"Please do not miss any one question",nil));
        return;
    }
    if (![ACConfigs shareConfigs].isInWebPage)
    {
        return;
    }
    
    if ([[ACConfigs shareConfigs].webUrlEntityType isEqualToString:cEvent])
    {
        message = NSLocalizedString(@"Welcome to event", nil);
    }
    else if ([[ACConfigs shareConfigs].webUrlEntityType isEqualToString:cSurvey])
    {
        message = NSLocalizedString(@"Thank you for your participation", nil);
    }
    
    UIAlertView* customAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil)
                                                          message:message
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                otherButtonTitles:nil];
    customAlert.tag = kWebAlert;
    [customAlert show];
    
}

- (BOOL)webView:(UIWebView *)sender runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(CGRect)frame
{
    if (![ACConfigs shareConfigs].isInWebPage)
    {
        return NO;
    }
    UIAlertView *confirmDiag = [[UIAlertView alloc] initWithTitle:nil
                                                          message:message
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                otherButtonTitles:NSLocalizedString(@"Cancel", nil), nil];
    
    [confirmDiag show];
    
    
    while (confirmDiag.hidden == NO && confirmDiag.superview != nil)
        
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];
    
    
    return NO;
    
}

+ (NSString*)webScriptNameForSelector:(SEL)selector
{
    if(selector == @selector(clickOnAndroid))
    {
        return @"setABC";
    }
    return nil;
}

-(void)clickOnAndroid
{
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kWebAlert)
    {
        if (buttonIndex == alertView.cancelButtonIndex)
        {
            [ACUtility postNotificationName:kJoinAlertShowSuccessNotification object:nil];
        }
    }
}

@end

@interface ACAcuLearnWebViewController ()

@end

@implementation ACAcuLearnWebViewController

- (void)dealloc
{
    AC_MEM_Dealloc();
    [_mainWebView stopLoading];
    _mainWebView.delegate = nil;
}

- (instancetype)initWithUrlString:(NSString *)urlString
{
    self = [super init];
    if (self) {
        self.urlString = urlString;
        _needAction = YES;
    }
    return self;
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
    

#if defined(ACUtility_Log_UseStringBuffers)||defined(ACUtility_Log_UseFile)
    if(nil==_urlString){
        #ifdef ITLogUserStringBuffers
            NSString* pStr =    ITLogUserStringBuffers_Strings();
        #else
            NSString* pStr = [[NSString alloc] initWithData:[ACUtility LogFile_Load:NO] encoding:NSUTF8StringEncoding];
        #endif
        if(0==pStr.length){
            pStr    =   @"调试信息为空!";
        }
        [_mainWebView loadHTMLString:pStr baseURL:nil];
        [_toolbar setHidden:YES];
        [_mainWebView setFrame_height:_mainWebView.size.height+44];
        return;
    }
#endif
    
    [ACConfigs shareConfigs].isInWebPage = YES;
    // Do any additional setup after loading the view from its nib.
    if (![_urlString.lowercaseString hasPrefix:@"http"])
    {
        self.urlString = [@"http://" stringByAppendingString:_urlString];
    }
    
    [ACConfigs shareConfigs].webUrlEntityType = _urlEntity.mpType;
    
    
    if([_urlEntity.mpType isEqualToString:cSurvey]||
       [_urlEntity.mpType isEqualToString:cEvent]||
       [_urlEntity.mpType isEqualToString:cPage]){
        _onOptionButton.hidden = NO;
    }
    
    if (![ACConfigs isPhone5])
    {
        [_contentView setFrame_height:_contentView.size.height-88];
        [_mainWebView setFrame_height:_mainWebView.size.height-88];
        [_toolbar setFrame_y:_toolbar.origin.y-88];
    }
    
    if (!_needAction)
    {
        [_toolbar setHidden:YES];
        [_mainWebView setFrame_height:_mainWebView.size.height+44];
    }
    
    if (_titleString)
    {
        _titleLabel.text = _titleString;
    }
    

    //    _urlString = @"http://www.163.com";
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_urlString]];
    if(request){
        NSString *cookie = [[NSUserDefaults standardUserDefaults] objectForKey:kCookie];
        [request setAllHTTPHeaderFields:[NSDictionary dictionaryWithObject:cookie forKey:kCookie]];
        [_mainWebView loadRequest:request];
    }
    
//    [_mainWebView loadHTMLString:@"<script language=\"javascript\">alert(\"Hell! UIWebView!\");</script>" baseURL:nil];
    
    
//    [_backButton setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateNormal];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(joinSuccess:) name:kJoinAlertShowSuccessNotification object:nil];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self initHotspot];
///
    if (!_needAction)
    {
        [_toolbar setHidden:YES];
        
        [_mainWebView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(_contentView);
        }];
        [_webSuperView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(_contentView);
        }];
        
        NSLog(@"%@",NSStringFromCGSize(_mainWebView.size));
        NSLog(@"%@",NSStringFromCGSize(_webSuperView.size));
        NSLog(@"%@",NSStringFromCGSize(_contentView.size));
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initHotspot];    
}

#pragma mark -Notification
-(void)hotspotStateChange:(NSNotification *)noti
{
    if (_isOpenHotspot)
    {
        [_mainWebView setFrame_height:_mainWebView.size.height-hotsoptHeight];
        [_contentView setFrame_height:_contentView.size.height-hotsoptHeight];
        [_toolbar setFrame_y:_toolbar.origin.y-hotsoptHeight];
    }
    else
    {
        [_mainWebView setFrame_height:_mainWebView.size.height+hotsoptHeight];
        [_contentView setFrame_height:_contentView.size.height+hotsoptHeight];
        [_toolbar setFrame_y:_toolbar.origin.y+hotsoptHeight];
    }
}

-(void)joinSuccess:(NSNotification *)noti
{
    [self.navigationController ACpopViewControllerAnimated:YES];
}

#pragma mark -WebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [_webSuperView showNetLoadingWithAnimated:NO];
    if (![_mainWebView canGoBack])
    {
        _gobackButton.image = [UIImage imageNamed:@"web_leftArrow_disable.png"];
    }
    else
    {
        _gobackButton.image = [UIImage imageNamed:@"web_leftArrow.png"];
    }
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_webSuperView hideProgressHUDWithAnimated:NO];
    if (![_mainWebView canGoBack])
    {
        _gobackButton.image = [UIImage imageNamed:@"web_leftArrow_disable.png"];
    }
    else
    {
        _gobackButton.image = [UIImage imageNamed:@"web_leftArrow.png"];
    }
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [_webSuperView hideProgressHUDWithAnimated:NO];
    ITLogEX(@"webView didFailLoadWithError %@",error.localizedDescription);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    //判断是否是单击
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        [_contentView showNetLoadingWithAnimated:NO];
    }
    return YES;
}

#pragma mark -IBAction
-(IBAction)goBack:(id)sender
{
    [_mainWebView goBack];
}

-(IBAction)goRefresh:(id)sender
{
    [_mainWebView reload];
}

- (IBAction)onOption:(id)sender {
    ACUrlEditViewController* urlEditVC = [[ACUrlEditViewController alloc] init];
    urlEditVC.urlEntity = _urlEntity;
    [self.navigationController pushViewController:urlEditVC animated:YES];
}

-(IBAction)goback:(id)sender
{
    [ACConfigs shareConfigs].isInWebPage = NO;
    [_mainWebView stopLoading];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.navigationController ACpopViewControllerAnimated:YES];
}
- (IBAction)goSafari:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:_urlString]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
