//
//  ShareActViewController.m
//  ShareExtensionDemo
//
//  Created by vimfung on 16/6/27.
//  Copyright © 2016年 vimfung. All rights reserved.
//

#import "ShareActViewController.h"
#import "ACDBManager.h"
#import "ACDateCenter.h"
#import "ACShareActViewCell.h"
#import "ACTopicEntity.h"
#import "ACUser.h"
#import "ACUserDB.h"
#import "ACShareActInfo.h"

#import "UIView+Additions.h"
#import "NSString+path.h"

#define kAclSid         @"aclsid"
#define kS              @"s"
#define kAclDomain      @"acldomain"
#define kUser           @"user"
#define kUserID         @"userid"
#define kAclTerminal    @"aclterminal"
#define kCid            @"cid"

static NSString *boundary=@"IOSShareFormPhoto3545dfrI7e4W6lvvL2BmdLA";
//1.定义一个cell标识
static NSString *ID = @"cell";

@interface ShareActViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) void (^selectedHandler) ();

/**
 *  图片缓存的字典 <key: 图片地址, value: 图片>;
 */
@property (nonatomic, strong) NSMutableDictionary *imageCache;



@end

@implementation ShareActViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _dataSourceArray = [NSMutableArray array];
    _dataSourceArray = [ACDateCenter getTopicEntityListFromDB];
    NSLog(@"%lu",(unsigned long)_dataSourceArray.count);
    

    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
    [_tableView registerNib:[UINib nibWithNibName:@"ACShareActViewCell" bundle:nil] forCellReuseIdentifier:ID];
    
    [self.view addSubview:_tableView];
    

}



- (void)onSelected:(void(^)(NSString *title,ACTopicEntity* topicEntity))handler
//- (void)onSelected:(void(^)(NSIndexPath *indexPath))handler

{
    self.selectedHandler = handler;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataSourceArray.count;
}




- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACShareActViewCell  *cell = [tableView dequeueReusableCellWithIdentifier:ID forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    
    ACTopicEntity* topicEntity = [[ACTopicEntity alloc]init];
    topicEntity = _dataSourceArray[indexPath.row];
   
    ACShareActInfo* info = [[ACShareActInfo alloc]init];
    
    if ([topicEntity.title isEqual:@""])
    {
//        单人聊天
        ACUser *user = [ACUserDB getUserFromDBWithUserID:topicEntity.singleChatUserID];
        cell.title.text = user.name;

        if (user.icon == nil || [user.icon isEqual:@""]) {
//            cell.imageView.image = [UIImage imageNamed:@"icon_singlechat"];
            cell.iconImage.image = [UIImage imageNamed:@"icon_singlechat"];
        }else
        {
            info.image = self.imageCache[user.icon];
            
            if (info.image != nil) {
//                从缓存获取
                cell.iconImage.image = info.image ;
            }else
            {
//                // 读取沙盒中是否有图片
//                // 确定沙盒的路
//                NSString *cachePath = [user.icon appendCachePath];
//                // 读取图片
//                info.image = [UIImage imageWithContentsOfFile:cachePath];
//                
//                if (info.image != nil) {
////                从沙盒获取
//                    cell.imageView.image = info.image ;
////                    存入缓存
//                    [self.imageCache setObject:info.image forKey:user.icon];
//                    
//                }else
//                {
//                    从网络获取
                    [self getIconImageWithIconSreing:user.icon withIndexpath:indexPath];
//                }
                
            }

        }
        
    }else
    {
//        多人聊天
        cell.title.text = topicEntity.title;

        if (topicEntity.icon == nil || [topicEntity.icon isEqual: @""]) {
            
//            cell.imageView.image = [UIImage imageNamed:@"icon_groupchat"];
            cell.iconImage.image = [UIImage imageNamed:@"icon_groupchat"] ;
          
        }else
        {
            info.image = self.imageCache[topicEntity.icon];
            
            if (info.image != nil) {
                cell.iconImage.image = info.image;
            }else
            {
//                // 读取沙盒中是否有图片
//                // 确定沙盒的路
//                NSString *cachePath = [topicEntity.icon appendCachePath];
//                // 读取图片
//                info.image = [UIImage imageWithContentsOfFile:cachePath];
//                
//                if (info.image != nil) {
////                从沙盒获取
//                    cell.imageView.image = info.image ;
//                    
////                    存入缓存
//                    [self.imageCache setObject:info.image forKey:topicEntity.icon];
//                    
//                }else
//                {
//                    从网络获取
                    [self getIconImageWithIconSreing:topicEntity.icon withIndexpath:indexPath];

//                }
            }
        }

    }
    
    
    return cell;
}

- (NSMutableURLRequest*)getHeaderWithRequest:(NSMutableURLRequest*) request
{
    ///AppG
    NSUserDefaults *defaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.lfglkh.shared--Test"];
    // 5.设置请求头：这次请求体的数据不再是普通的参数，而是一个JSON数据
    //    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary] forHTTPHeaderField:@"Content-Type"];
//    [request setValue:[NSString stringWithFormat:@"%d", (int)nLength] forHTTPHeaderField:@"Content-Length"];
    
    [request addValue:@"ios" forHTTPHeaderField:@"aclterminal"];
    
    NSString *userID = [defaults objectForKey:kUserID];
    [request addValue:userID forHTTPHeaderField:@"aclaccount"];
    
    NSString *aclDomain = [defaults objectForKey:kAclDomain];
    [request addValue: aclDomain forHTTPHeaderField:@"acldomain"];
    
    NSString *aclSid = [defaults objectForKey:kAclSid];
    [request addValue:aclSid forHTTPHeaderField:@"aclsid"];
    
    NSString *s = [defaults objectForKey:kS];
    [request addValue:s forHTTPHeaderField:@"s"];
    
    return request;
}

//从网络获取图片
- (void)getIconImageWithIconSreing:(NSString*)iconString withIndexpath:(NSIndexPath*)indexpath
{
    ///AppG。
//    https://acucom1.aculearn.com/rest/apis/user/icon/urlentity/59086e0ab0a7c32d296be657?t=1493724682532&w=100&h=100

    
    if (iconString != nil) {
        //GCD异步实现
        dispatch_queue_t q1 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        dispatch_async(q1, ^{
            //1.创建会话对象
            //网络配置
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            
            //网络会话
            NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
            
            
            //2/url
            ///AppG
            NSUserDefaults *defaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.lfglkh.shared--Test"];
            NSString* appString = [defaults objectForKey:@"appString"];
            
//            NSString* string  = @"https://acucom1.aculearn.com/rest/apis/user/icon/urlentity/59086e0ab0a7c32d296be657?t=1493724682532&w=38&h=38";
            NSString* string = [NSString stringWithFormat:@"%@%@&w=38&h=38",appString,iconString];
            
            NSURL* iconUrl = [NSURL URLWithString:string];
            
            //3.创建可变的请求对象
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:iconUrl];
            
            //4.修改请求方法为POST
            //        request.HTTPMethod = @"GET";
            [request setHTTPMethod:@"GET"];
            
            //5.获取请求头
            request = [self getHeaderWithRequest:request];
            
            //6.根据会话对象创建一个Task(发送请求）
            NSURLSessionDataTask *sessionTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                
                if (error) {
                    
                    NSLog(@"请求失败... %@",error);
                    
                }else{
                    
                    
                    UIImage* image = [UIImage imageWithData:data];
                    
                    UIImage* scaleImage = [self scaleToSize:image size:CGSizeMake(38, 38)];
                    
                    // 解析成功，处理数据，通过GCD获取主队列，在主线程中刷新界面。
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        // 将图片缓存到字典中
                        [self.imageCache setObject:scaleImage forKey:iconString];
//                        // 保存图片到沙盒
//                        NSData* imageData = UIImagePNGRepresentation(scaleImage);
//                        [imageData writeToFile:[iconString appendCachePath] atomically:true];
                        
                        // 刷新界面....
                        [_tableView reloadRowsAtIndexPaths:@[indexpath] withRowAnimation:UITableViewRowAnimationNone];
                        
                    });
                    
                }
            }];
            
            //开始任务
            [sessionTask resume];
            
        });

    }
    
}


//压缩图片
- (UIImage *)scaleToSize:(UIImage *)img size:(CGSize)size{
    
    // 设置成为当前正在使用的context
    UIGraphicsBeginImageContext(size);
    // 绘制改变大小的图片
    [img drawInRect:CGRectMake(0, 0, size.width, size.height)];
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    
    UIImage* imageEnd = [self imageWithIconName:scaledImage borderImage:nil border:0];
    // 返回新的改变大小后的图片
    return imageEnd;
}

//将图片剪切成圆形
- (UIImage*)imageWithIconName:(UIImage *)image borderImage:(NSString *)borderImage border:(int)border{
    
    //边框图片
    UIImage * borderImg = [UIImage imageNamed:borderImage];
    //
    CGSize size = CGSizeMake(image.size.width + border, image.size.height + border);
    
    //创建图片上下文
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    
    //绘制边框的圆
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddEllipseInRect(context, CGRectMake(0, 0, size.width, size.height));
    
    //剪切可视范围
    CGContextClip(context);
    
    //绘制边框图片
    [borderImg drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    //设置头像frame
    CGFloat iconX = border / 2;
    CGFloat iconY = border / 2;
    CGFloat iconW = image.size.width;
    CGFloat iconH = image.size.height;
    
    //绘制圆形头像范围
    CGContextAddEllipseInRect(context, CGRectMake(iconX, iconY, iconW, iconH));
    
    //剪切可视范围
    CGContextClip(context);
    
    //绘制头像
    [image drawInRect:CGRectMake(iconX, iconY, iconW, iconH)];
    
    //取出整个图片上下文的图片
    UIImage *iconImage = UIGraphicsGetImageFromCurrentImageContext();
    
    return iconImage;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* actTitle ;
    
    if (self.selectedHandler)
    {
        ACTopicEntity* topicEntity = [[ACTopicEntity alloc]init];
        topicEntity = _dataSourceArray[indexPath.row];
        
        
        actTitle = topicEntity.title;
        
        
        if ([topicEntity.title isEqual:@""])
        {
            ACUser *user = [ACUserDB getUserFromDBWithUserID:topicEntity.singleChatUserID];
            actTitle = user.name;
        }
        
        
        self.selectedHandler (actTitle,topicEntity);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    // 1. 清除掉内存中的image
    //    for (int i=0; i<self.appInfos.count; i++) {
    //        HMAppInfo *info = self.appInfos[i];
    //        info.image = nil;
    //    }
    [self.imageCache removeAllObjects];
    
    
}


#pragma mark - 懒加载

// 图片缓存的字典
- (NSMutableDictionary *)imageCache {
    if (_imageCache == nil) {
        _imageCache = [NSMutableDictionary dictionary];
    }
    return _imageCache;
}



@end
