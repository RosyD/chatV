//
//  ACFileBrowserViewController.m
//  chat
//
//  Created by 王方帅 on 14-5-27.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACFileBrowserViewController.h"
#import "ACAddress.h"
#import "UINavigationController+Additions.h"
#import "UIView+Additions.h"
#import "ACNetCenter.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface ACFileBrowserViewController ()

@end

@implementation ACFileBrowserViewController


AC_MEM_Dealloc_implementation


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
    
    NSString *extension = [[[_fileMsg name] componentsSeparatedByString:@"."] lastObject];
    NSString *filePath = [ACAddress getAddressWithFileName:((ACFileMessage *)_fileMsg).resourceID fileType:ACFile_Type_File isTemp:NO subDirName:extension];
    if ([QLPreviewController canPreviewItem:[NSURL fileURLWithPath:filePath]])
    {
        QLPreviewController* preview = [[QLPreviewController alloc] init];
        
        preview.dataSource = self;
        preview.delegate = self;
        [self addChildViewController:preview];//*view controller containment
        //set the frame from the parent view
        CGFloat w= _contentView.frame.size.width;
        CGFloat h= _contentView.frame.size.height;
        preview.view.frame = CGRectMake(0, 0,w, h);
        [_contentView addSubview:preview.view];
        [preview didMoveToParentViewController:self];
        self.previewController = preview;
        [_cannotOpenShowView setHidden:YES];
    }
    else
    {
        [_cannotOpenShowView setHidden:NO];
    }
    
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(hotspotStateChange:) name:kHotspotOpenStateChangeNotification object:nil];
    _nameLabel.text = _fileMsg.name;
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

#pragma mark -delegate
#pragma mark -QLPreviewControllerDataSource
- (NSInteger) numberOfPreviewItemsInPreviewController: (QLPreviewController *) controller
{
    return 1;
}

- (id <QLPreviewItem>)previewController: (QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    NSString *extension = [[[_fileMsg name] componentsSeparatedByString:@"."] lastObject];
    NSString *filePath = [ACAddress getAddressWithFileName:((ACFileMessage *)_fileMsg).resourceID fileType:ACFile_Type_File isTemp:NO subDirName:extension];
    return [NSURL fileURLWithPath:filePath];
}

#pragma mark -IBAction
-(IBAction)openInOtherApps:(id)sender
{
    NSString *extension = [[[_fileMsg name] componentsSeparatedByString:@"."] lastObject];
    NSString *filePath = [ACAddress getAddressWithFileName:((ACFileMessage *)_fileMsg).resourceID fileType:ACFile_Type_File isTemp:NO subDirName:extension];
    self.docController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:filePath]];
    _docController.delegate = self;
    [_docController presentOptionsMenuFromRect:CGRectMake(0, 0, 100, 100) inView:_contentView animated:YES];
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
    CGFloat w= _contentView.frame.size.width;
    CGFloat h= _contentView.frame.size.height;
    _previewController.view.frame = CGRectMake(0, 0,w, h);
}

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
