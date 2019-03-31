//
//  ShareViewController.m
//  shareChat
//
//  Created by 李朝霞 on 2017/2/10.
//  Copyright © 2017年 ___FULLUSERNAME___. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "ShareViewController.h"
#import "ShareActViewController.h"
#import "ACTopicEntity.h"
#import "ACAddress.h"
#import "UIImage+Additions.h"
#import "ACPicSendController.h"

#import <UIKit/UIKit.h>

#define kAclSid         @"aclsid"
#define kS              @"s"
#define kAclDomain      @"acldomain"
#define kUser           @"user"
#define kUserID         @"userid"
#define kAclTerminal    @"aclterminal"
#define kCid            @"cid"

//弱引用
#define  WEAK_REPLACE(name,weakReplace) __weak __typeof(&*name)weakReplace = name



@interface ShareViewController ()<NSURLSessionDelegate,UITextViewDelegate>

@property(nonatomic,strong)ACTopicEntity* topicEnitity;

@property (nonatomic,strong) NSString *cancelID;//通道ID,多线程调用时可区分是否同一设备

@property (assign,nonatomic)CGFloat flag;

@end

@implementation ShareViewController

static NSString *boundary=@"IOSShareFormPhoto3545dfrI7e4W6lvvL2BmdLA";

- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    return YES;
}

- (void)viewDidLoad
{
    ///AppG
    NSUserDefaults *defaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.lfglkh.shared--Test"];
    
    //    NSString *userID = [defaults objectForKey:kUserID];
    
    if ([defaults objectForKey:kUserID] == nil ) {
        
        [self showAlertWithName:@"Please Login"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self cancel];
            
        });
    }
    
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (textView.text.length >= 250 && text.length > 0) {
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (textView.text.length > 250) {
        
        textView.text = [textView.text substringToIndex:250];
        
    }
}

- (NSMutableURLRequest*)getHeaderWithRequest:(NSMutableURLRequest*) request withLength:(NSInteger)nLength
{
    ///AppG
    NSUserDefaults *defaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.lfglkh.shared--Test"];
    // 5.设置请求头：这次请求体的数据不再是普通的参数，而是一个JSON数据
    //    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary] forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", (int)nLength] forHTTPHeaderField:@"Content-Length"];
    
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


-(void)_topic_data:(NSDictionary*)topic toBuffer:(NSMutableData*)pBuffer{
    NSMutableString *myString=[NSMutableString stringWithFormat:@"--%@\r\n", boundary];
    //2. Content-Disposition: form-data; name="uploadFile"; filename="001.png"\r\n  // 这里注明服务器接收图片的参数（类似于接收用户名的userName）及服务器上保存图片的文件名
    [myString appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"topic\"\r\n\r\n"]];
    
    
    NSData* json = [NSJSONSerialization dataWithJSONObject:topic options:NSJSONWritingPrettyPrinted error:nil];
    [myString appendString:[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]];
    
    NSLog(@"%@",myString);
    
    [pBuffer appendData:[myString dataUsingEncoding:NSUTF8StringEncoding]];
}

-(NSData*)_img:(UIImage*)pImg  withID:(NSString*)pID andGetFileSize:(NSInteger*)pFileSize andGetImgSize:(CGSize*)pImgSize{
    NSMutableData* pBuffer = [[NSMutableData alloc] initWithLength:1024*1024*1];
    NSFileManager* fileMag = [NSFileManager defaultManager];
    NSString* pTempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.jpg"];
    [fileMag removeItemAtPath:pTempFilePath error:nil];
    [UIImageJPEGRepresentation(pImg, 0.75) writeToFile:pTempFilePath atomically:YES];
    NSData* pImgData = [NSData dataWithContentsOfFile:pTempFilePath];
    [fileMag removeItemAtPath:pTempFilePath error:nil];
    
    *pFileSize = pImgData.length;
    *pImgSize  = pImg.size;
    
    
    NSMutableString* secondString = [NSMutableString stringWithFormat:@"\r\n--%@\r\n", boundary];
    
    //                    [firstString appendString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
    //2. Content-Disposition: form-data; name="uploadFile"; filename="001.png"\r\n  // 这里注明服务器接收图片的参数（类似于接收用户名的userName）及服务器上保存图片的文件名
    [secondString appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"image.jpg\"\r\n",pID]];
    
    //3. Content-Type:image/png \r\n  // 图片类型为png
    [secondString appendString:[NSString stringWithFormat:@"Content-Type:image/jpeg\r\n\r\n"]];
    //                //4. Content-Transfer-Encoding: binary\r\n\r\n  // 编码方式
    //[secondString appendString:@"Content-Transfer-Encoding: binary\r\n\r\n"];
    
    NSLog(@"%@",secondString);
    
    //转换成为二进制数据
    [pBuffer appendData:[secondString dataUsingEncoding:NSUTF8StringEncoding]];
    
    //加入图片
    [pBuffer appendData:pImgData];
    
    return pBuffer;
}

-(void)_end_data_flag_toBuffer:(NSMutableData*)pBuffer{
    NSString* myString = [NSString stringWithFormat:@"\r\n--%@--",boundary];
    NSLog(@"%@",myString);
    [pBuffer appendData:[myString dataUsingEncoding:NSUTF8StringEncoding]];
}

-(NSMutableData*)_getPostDataFromImg:(NSURL *)urlimage withEntityId:(NSString*)entityId{
    
    NSMutableData* pRet = [[NSMutableData alloc] initWithLength:2*1024*1024];
    
    double creatTime = [[NSDate date] timeIntervalSince1970]*1000;
    NSString* rid  =   [NSString stringWithFormat:@"%.0f",creatTime];
    NSString* trid =  [rid stringByAppendingString:@"_s"];
    NSString* cid = [NSString stringWithFormat:@"%.0f",creatTime];
    
    NSString* nrid = [NSString stringWithFormat:@"{%.0f}",creatTime];
    NSString* ntrid =  [NSString stringWithFormat:@"{%.0f_s}",creatTime];
    
    NSInteger nImgFileSize,nImgS_FileSize;
    CGSize imgSize;
    CGSize imgS_Size;
    
    //对itemProvider夹带着的图片进行解析
    UIImage *image=[UIImage imageWithData:[NSData dataWithContentsOfURL:urlimage]];
    NSData* pImgData = [self _img:[image imageScaledToBigFixedSize:CGSizeMake(2000, 2000)]
                           withID:rid
                   andGetFileSize:&nImgFileSize
                    andGetImgSize:&imgSize];
    
    NSData* pImgS_Data = [self _img:[image imageScaledToBigFixedSize:CGSizeMake(320, 320)]
                             withID:trid
                     andGetFileSize:&nImgS_FileSize
                      andGetImgSize:&imgS_Size];
    /*
     {
     cid = 1493175621226;
     content =     {
     big =         (
     2000,
     1329
     );
     length = 428705;
     name = "image.jpg";
     rid = "{1493175621226}";
     small =         (
     415,
     414
     );
     trid = "{1493175621226_s}";
     };
     teid = cd8f327d7c84103fd6302407cc76c1af;
     type = image;
     }
     */
    
    NSDictionary* orderInfo = @ {
        
        @"teid" : entityId,
        @"type" : @"image",
        @"cid"  : cid,
        @"content" : @{
                       @"rid" : nrid,
                       @"trid" : ntrid,
                       @"length" : @(nImgFileSize),
                       @"big" :@[
                               @(imgSize.width),
                               @(imgSize.height)
                               ],
                       @"small" :@[
                               @(imgS_Size.width),
                               @(imgS_Size.height)
                               ],
                       @"name":@"image.jpg"
                       }
    };
    
    [self _topic_data:orderInfo toBuffer:pRet];
    [pRet appendData:pImgData];
    [pRet appendData:pImgS_Data];
    [self _end_data_flag_toBuffer:pRet];
    
    return pRet;
}


- (void)didSelectPost {
    
    //获取inputItems，在这里itemProvider是你要分享的图片
    NSExtensionItem *firstItem = self.extensionContext.inputItems.firstObject;
    NSArray* attachs = firstItem.attachments;
    
    if (self.topicEnitity.entityID != nil){
        
        //        发送文字
        if (self.textView.text != nil && ![self.textView.text  isEqual: @""]) {
            
            [self sendMessage];
            
        }
        
        
        NSItemProvider *itemProvider;
        if (firstItem) {
            //        itemProvider = firstItem.attachments.firstObject;
            //        取得多张图片的数组
            //        发送每张图片
            for (int i = 0; i<attachs.count; i++) {
                
                itemProvider = attachs[i];
                
                //这里的kUTTypeImage代指@"public.image"，也就是从相册获取的图片类型
                //这里的kUTTypeURL代指网站链接，如在Safari中打开，则应该拷贝保存当前网页的链接
                if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
                    [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        if (!error) {
                            //对itemProvider夹带着的URL进行解析
                            NSURL *url = (NSURL *)item;
                            [UIPasteboard generalPasteboard].URL = url;
                        }
                    }];
                    
                }else if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
                    [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        if (!error) {
                            
                            
                            NSData* pPostData = [self _getPostDataFromImg:(NSURL*)item withEntityId:self.topicEnitity.entityID];
                            
                            
                            //GCD异步实现
                            dispatch_queue_t q1 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                            
                            dispatch_async(q1, ^{
                                
                                ///AppG
                                NSUserDefaults *defaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.lfglkh.shared--Test"];
                                
                                //1.创建会话对象
                                //                                NSURLSession *session = [NSURLSession sharedSession];
                                ///S
                                NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
                                
                                
                                NSString * const acSendImageMessageUrl = [NSString stringWithFormat:@"%@/%@/uploadex",[defaults objectForKey:@"urlString"],self.topicEnitity.entityID];
                                //        NSString * const acSendImageMessageUrl = @"https://acucom2.aculearn.com/rest/apis/chat/a6e6648c960a35aecec3ec100df2dca8/uploadex";
                                
                                NSURL* url = [NSURL URLWithString:acSendImageMessageUrl];
                                
                                //                            NSURL* url1 = [NSURL URLWithString:@"https://acucom2.aculearn.com/rest/apis/chat/topic"];
                                
                                //3.创建可变的请求对象
                                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
                                
                                
                                //4.修改请求方法为POST
                                request.HTTPMethod = @"POST";
                                
                                //获取请求头
                                request = [self getHeaderWithRequest:request withLength:pPostData.length];
                                
                                
                                //        HTTPBody 赋值
                                request.HTTPBody = pPostData;
                                
                                //6.根据会话对象创建一个Task(发送请求）
                                
                                NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                    NSURLResponse* res = (NSHTTPURLResponse *)response;
                                    
                                    NSLog(@"%f",[pPostData length] * 1.0f);
                                    
                                    //解析拿到的响应数据
                                    NSLog(@"%@\n%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding],res);
                                    //8.解析数据
                                    
                                    if( data==nil){
                                        
                                        NSLog(@"网络繁忙！稍后再试");
                                        
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            
                                            [self showAlertWithName:@"Please Check the Network"];
                                            
                                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                
                                                [self cancel];
                                                
                                            });

                                            
                                        });
                                        
                                        //                                    return ;
                                    }else{
                                        NSDictionary *dict =  [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                                        NSString *error =  dict[@"error"];
                                        if (error) {
                                            NSLog(@"errpr \n%@",error);
                                            
                                        }else{
                                         
                                            if (i == attachs.count - 1)
                                            {
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    NSString *success = dict[@"success"];
                                                    NSLog(@"success \n %@",success);
                                                    [self showAlertWithName:@"Send Success"];
                     
                                                });
                                                
                                                
                                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                    
                                                    if (_flag == 1) {
                                                        
                                                        [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                                                        
                                                    }
    
                                                    
                                                });
                                                
                                            }
                                        
                                        }
                                    }
                                    
                                }];
                                
                                //7.执行任务
                                [dataTask resume];
                                
                            });
                        }
                    }];
                }
            }
        }
    }
    else
    {
        [self showAlertWithName:@"Please select contact!"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self cancel];
            
        });
    }
    
//        [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];

    ACPicSendController* picCon = [[ACPicSendController alloc]init];
    NSString* nameTitle = [NSString stringWithFormat:NSLocalizedString(@"Picture quantity: %lu ", nil),(unsigned long)attachs.count];
    picCon.picnum = nameTitle;
    picCon.shareVc = self;
    picCon.picn = (int)attachs.count;
    
    [self presentViewController:picCon animated:YES completion:nil];
    
}

#pragma mark - NSURLSessionDataDelegate

/**
 *  发送数据的时候会回高过个方法
 *
 *  @param session                  当前使用的session
 *  @param task                     当前的任务
 *  @param bytesSent                本次发送的字节大小
 *  @param totalBytesSent           总共已发送的字节大小
 *  @param totalBytesExpectedToSend 总共需要发送的字节大小
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    
    //    NSLog(@"%@",task.response);
    //     NSLog(@"%@",task.currentRequest);
    
    float progress = (float)totalBytesSent / totalBytesExpectedToSend;
    NSLog(@"%f", progress);
    //创建一个消息对象
    NSNotification * notice = [NSNotification notificationWithName:@"progress" object:nil userInfo:@{@"1":@(1.0*progress)}];
    //发送消息
    [[NSNotificationCenter defaultCenter]postNotification:notice];
    
    if (progress == 1) {
        _flag = 1;
    }else
    {
        _flag = 0;
    }
    
}



/**
 *  弹框提示
 */
- (void)showAlertWithName:(NSString*)name{
    //    @"Please select contact!"
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(name, nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    
}



-(void)sendMessage
{
    NSString* ss = self.textView.text;
    
    ///AppG
    NSUserDefaults *defaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.lfglkh.shared--Test"];
    
    //1.创建会话对象
    NSURLSession *session = [NSURLSession sharedSession];
    
    //    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    
    NSString * const messageUrl = [NSString stringWithFormat:@"%@/topic",[defaults objectForKey:@"urlString"]];
    
    NSURL* url = [NSURL URLWithString:messageUrl];
    
    //3.创建可变的请求对象
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    
    //4.修改请求方法为POST
    request.HTTPMethod = @"POST";
    
    //获取请求头
    request = [self getHeaderWithRequest:request withLength:ss.length];
    
    //    请求体设置
    double creatTime = [[NSDate date] timeIntervalSince1970]*1000;
    NSString* cid = [NSString stringWithFormat:@"%.0f",creatTime];
    NSDictionary* orderInfo = @ {
        
        @"teid" : self.topicEnitity.entityID,
        @"type" : @"text",
        @"cid"  : cid,
        @"content" : ss
    };
    
    NSData* json = [NSJSONSerialization dataWithJSONObject:orderInfo options:NSJSONWritingPrettyPrinted error:nil];
    
    request.HTTPBody = json;
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
    
    //7.执行任务
    [dataTask resume];
    
}



- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    
    //创建公开权限配置项
    SLComposeSheetConfigurationItem *actItem = [[SLComposeSheetConfigurationItem alloc] init];
    
    WEAK_REPLACE(actItem, weakReplace);
    actItem.title = NSLocalizedString(@"Contact", nil);
    
    //    actItem.value = _value;
    
    actItem.tapHandler = ^{
        
        //获取inputItems，在这里itemProvider是你要分享的图片
        NSExtensionItem *firstItem = self.extensionContext.inputItems.firstObject;
        
        NSLog(@"%@",firstItem.userInfo);
        
        //设置分享权限时弹出选择界面
        ShareActViewController *actVC = [[ShareActViewController alloc] init];
        [self pushConfigurationViewController:actVC];
        
        [actVC onSelected:^(NSString *title,ACTopicEntity* topicEntity) {
            self.topicEnitity = topicEntity;
            //当选择完成时退出选择界面并刷新配置项。
            weakReplace.value = title;
            
            [self popConfigurationViewController];
            
        }];
        
    };
    actItem.value = nil;
    
    return @[actItem];
}

@end
