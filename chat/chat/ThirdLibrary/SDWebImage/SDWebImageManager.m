/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageManager.h"
#import "SDImageCache.h"
#import "SDWebImageDownloader.h"
#import <objc/message.h>
#import "UIImageView+WebCache.h"
#import "UIImage+Additions.h"

#if NS_BLOCKS_AVAILABLE
typedef void(^SuccessBlock)(UIImage *image);
typedef void(^FailureBlock)(NSError *error);
#endif

static SDWebImageManager *instance;

@implementation SDWebImageManager

#if NS_BLOCKS_AVAILABLE
@synthesize cacheKeyFilter;
#endif

- (id)init
{
    if ((self = [super init]))
    {
        downloadDelegates = [[NSMutableArray alloc] init];
        downloaders = [[NSMutableArray alloc] init];
        cacheDelegates = [[NSMutableArray alloc] init];
        cacheURLs = [[NSMutableArray alloc] init];
        downloaderForURL = [[NSMutableDictionary alloc] init];
        failedURLs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    SDWISafeRelease(downloadDelegates);
    SDWISafeRelease(downloaders);
    SDWISafeRelease(cacheDelegates);
    SDWISafeRelease(cacheURLs);
    SDWISafeRelease(downloaderForURL);
    SDWISafeRelease(failedURLs);
    SDWISuperDealoc;
}


+ (id)sharedManager
{
    if (instance == nil)
    {
        instance = [[SDWebImageManager alloc] init];
    }

    return instance;
}

- (NSString *)cacheKeyForURL:(NSURL *)url
{
#if NS_BLOCKS_AVAILABLE
    if (self.cacheKeyFilter)
    {
        return self.cacheKeyFilter(url);
    }
    else
    {
        return [url absoluteString];
    }
#else
    return [url absoluteString];
#endif
}

/*
 * @deprecated
 */
- (UIImage *)imageWithURL:(NSURL *)url
{
    return [[SDImageCache sharedImageCache] imageFromKey:[self cacheKeyForURL:url]];
}

/*
 * @deprecated
 */
- (void)downloadWithURL:(NSURL *)url delegate:(id<SDWebImageManagerDelegate>)delegate retryFailed:(BOOL)retryFailed
{
    [self downloadWithURL:url delegate:delegate options:(SDWebImageOptions)(retryFailed ? SDWebImageRetryFailed : 0)];
}

/*
 * @deprecated
 */
- (void)downloadWithURL:(NSURL *)url delegate:(id<SDWebImageManagerDelegate>)delegate retryFailed:(BOOL)retryFailed lowPriority:(BOOL)lowPriority
{
    SDWebImageOptions options = (SDWebImageOptions)0;
    if (retryFailed) options = (SDWebImageOptions)(SDWebImageRetryFailed | (int)options);
    if (lowPriority) options = (SDWebImageOptions)(SDWebImageLowPriority | (int)options);
    [self downloadWithURL:url delegate:delegate options:options];
}

- (void)downloadWithURL:(NSURL *)url delegate:(id<SDWebImageManagerDelegate>)delegate
{
    [self downloadWithURL:url delegate:delegate options:(SDWebImageOptions)0];
}

- (void)downloadWithURL:(NSURL *)url delegate:(id<SDWebImageManagerDelegate>)delegate options:(SDWebImageOptions)options
{
    [self downloadWithURL:url delegate:delegate options:options userInfo:nil];
}

- (void)downloadWithURL:(NSURL *)url delegate:(id<SDWebImageManagerDelegate>)delegate options:(SDWebImageOptions)options imageName:(NSString *)imageName imageType:(enum ImageType)imageType
{
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:delegate, @"delegate",
                          url, @"url",
                          [NSNumber numberWithInt:options], @"options",
                          ([imageName length] > 0?imageName:@""),@"imageName",
                          nil];
    [self downloadWithURL:url delegate:delegate options:options userInfo:info imageName:imageName imageType:imageType];
}

- (void)downloadWithURL:(NSURL *)url delegate:(id<SDWebImageManagerDelegate>)delegate options:(SDWebImageOptions)options userInfo:(NSDictionary *)userInfo imageName:(NSString *)imageName imageType:(enum ImageType)imageType
{
    if ([url isKindOfClass:NSString.class])
    {
        url = [NSURL URLWithString:(NSString *)url];
    }
    
    if (!url || !delegate || (!(options & SDWebImageRetryFailed) && [failedURLs containsObject:url]))
    {
        return;
    }
    
    // Check the on-disk cache async so we don't block the main thread
    [cacheDelegates addObject:delegate];
    [cacheURLs addObject:url];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          delegate, @"delegate",
                          url, @"url",
                          [NSNumber numberWithInt:options], @"options",
                          userInfo ? userInfo : [NSNull null], @"userInfo",
                          [NSNumber numberWithInt:imageType], kImageType,
                          nil];
    [[SDImageCache sharedImageCache] queryDiskCacheForKey:[imageName length]>0?imageName:[self cacheKeyForURL:url] delegate:self userInfo:info];
}

- (void)downloadWithURL:(NSURL *)url delegate:(id<SDWebImageManagerDelegate>)delegate options:(SDWebImageOptions)options userInfo:(NSDictionary *)userInfo
{
    [self downloadWithURL:url delegate:delegate options:options userInfo:userInfo imageName:nil imageType:ImageType_Define];
//    // Very common mistake is to send the URL using NSString object instead of NSURL. For some strange reason, XCode won't
//    // throw any warning for this type mismatch. Here we failsafe this error by allowing URLs to be passed as NSString.
//    if ([url isKindOfClass:NSString.class])
//    {
//        url = [NSURL URLWithString:(NSString *)url];
//    }
//
//    if (!url || !delegate || (!(options & SDWebImageRetryFailed) && [failedURLs containsObject:url]))
//    {
//        return;
//    }
//
//    // Check the on-disk cache async so we don't block the main thread
//    [cacheDelegates addObject:delegate];
//    [cacheURLs addObject:url];
//    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
//                          delegate, @"delegate",
//                          url, @"url",
//                          [NSNumber numberWithInt:options], @"options",
//                          userInfo ? userInfo : [NSNull null], @"userInfo",
//                          nil];
//    [[SDImageCache sharedImageCache] queryDiskCacheForKey:[self cacheKeyForURL:url] delegate:self userInfo:info];
}

#if NS_BLOCKS_AVAILABLE
- (void)downloadWithURL:(NSURL *)url delegate:(id)delegate options:(SDWebImageOptions)options success:(void (^)(UIImage *image))success failure:(void (^)(NSError *error))failure
{
    [self downloadWithURL:url delegate:delegate options:options userInfo:nil success:success failure:failure];
}

- (void)downloadWithURL:(NSURL *)url delegate:(id)delegate options:(SDWebImageOptions)options userInfo:(NSDictionary *)userInfo success:(void (^)(UIImage *image))success failure:(void (^)(NSError *error))failure
{
    // repeated logic from above due to requirement for backwards compatability for iOS versions without blocks
    
    // Very common mistake is to send the URL using NSString object instead of NSURL. For some strange reason, XCode won't
    // throw any warning for this type mismatch. Here we failsafe this error by allowing URLs to be passed as NSString.
    if ([url isKindOfClass:NSString.class])
    {
        url = [NSURL URLWithString:(NSString *)url];
    }
    
    if (!url || !delegate || (!(options & SDWebImageRetryFailed) && [failedURLs containsObject:url]))
    {
        return;
    }
    
    // Check the on-disk cache async so we don't block the main thread
    [cacheDelegates addObject:delegate];
    [cacheURLs addObject:url];
    SuccessBlock successCopy = [success copy];
    FailureBlock failureCopy = [failure copy];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          delegate, @"delegate",
                          url, @"url",
                          [NSNumber numberWithInt:options], @"options",
                          userInfo ? userInfo : [NSNull null], @"userInfo",
                          successCopy, @"success",
                          failureCopy, @"failure",
                          nil];
    SDWIRelease(successCopy);
    SDWIRelease(failureCopy);
    [[SDImageCache sharedImageCache] queryDiskCacheForKey:[self cacheKeyForURL:url] delegate:self userInfo:info];
}
#endif

- (void)cancelForDelegate:(id<SDWebImageManagerDelegate>)delegate
{
    NSUInteger idx;
    while ((idx = [cacheDelegates indexOfObjectIdenticalTo:delegate]) != NSNotFound)
    {
        [cacheDelegates removeObjectAtIndex:idx];
        [cacheURLs removeObjectAtIndex:idx];
    }

    while ((idx = [downloadDelegates indexOfObjectIdenticalTo:delegate]) != NSNotFound)
    {
        SDWebImageDownloader *downloader = SDWIReturnRetained([downloaders objectAtIndex:idx]);

        [downloadDelegates removeObjectAtIndex:idx];
        [downloaders removeObjectAtIndex:idx];

        if (![downloaders containsObject:downloader])
        {
            // No more delegate are waiting for this download, cancel it
            [downloader cancel];
            [downloaderForURL removeObjectForKey:downloader.url];
        }

        SDWIRelease(downloader);
    }
}

#pragma mark SDImageCacheDelegate

- (NSUInteger)indexOfDelegate:(id<SDWebImageManagerDelegate>)delegate waitingForURL:(NSURL *)url
{
    // Do a linear search, simple (even if inefficient)
    NSUInteger idx;
    for (idx = 0; idx < [cacheDelegates count]; idx++)
    {
        if ([cacheDelegates objectAtIndex:idx] == delegate && [[cacheURLs objectAtIndex:idx] isEqual:url])
        {
            return idx;
        }
    }
    return NSNotFound;
}

- (void)imageCache:(SDImageCache *)imageCache didFindImage:(UIImage *)image forKey:(NSString *)key userInfo:(NSDictionary *)info
{
    NSURL *url = [info objectForKey:@"url"];
    id<SDWebImageManagerDelegate> delegate = [info objectForKey:@"delegate"];

    NSUInteger idx = [self indexOfDelegate:delegate waitingForURL:url];
    if (idx == NSNotFound)
    {
        // Request has since been canceled
        return;
    }

    if ([delegate respondsToSelector:@selector(webImageManager:didFinishWithImage:)])
    {
        [delegate performSelector:@selector(webImageManager:didFinishWithImage:) withObject:self withObject:image];
    }
    if ([delegate respondsToSelector:@selector(webImageManager:didFinishWithImage:forURL:)])
    {
        objc_msgSend(delegate, @selector(webImageManager:didFinishWithImage:forURL:), self, image, url);
    }
    if ([delegate respondsToSelector:@selector(webImageManager:didFinishWithImage:forURL:userInfo:)])
    {
        NSDictionary *userInfo = [info objectForKey:@"userInfo"];
        if ([userInfo isKindOfClass:NSNull.class])
        {
            userInfo = nil;
        }
        
        //http://my.oschina.net/vimfung/blog/341119
        //调用objc_msgSend方法在64位下崩溃解决方法
        //https://developer.apple.com/library/ios/documentation/General/Conceptual/CocoaTouch64BitGuide/ConvertingYourAppto64-Bit/ConvertingYourAppto64-Bit.html
        int (*action)(id, SEL, id,id,id,id) = (int (*)(id, SEL, id,id,id,id)) objc_msgSend;
        action(delegate, @selector(webImageManager:didFinishWithImage:forURL:userInfo:), self, image, url, userInfo);
        
//        objc_msgSend(delegate, @selector(webImageManager:didFinishWithImage:forURL:userInfo:), self, image, url, userInfo);
    }
#if NS_BLOCKS_AVAILABLE
    if ([info objectForKey:@"success"])
    {
        SuccessBlock success = [info objectForKey:@"success"];
        success(image);
    }
#endif

    [cacheDelegates removeObjectAtIndex:idx];
    [cacheURLs removeObjectAtIndex:idx];
}

- (void)imageCache:(SDImageCache *)imageCache didNotFindImageForKey:(NSString *)key userInfo:(NSDictionary *)info
{
    NSURL *url = [info objectForKey:@"url"];
    id<SDWebImageManagerDelegate> delegate = [info objectForKey:@"delegate"];
    SDWebImageOptions options = (SDWebImageOptions)[[info objectForKey:@"options"] intValue];

    NSUInteger idx = [self indexOfDelegate:delegate waitingForURL:url];
    if (idx == NSNotFound)
    {
        // Request has since been canceled
        return;
    }

    [cacheDelegates removeObjectAtIndex:idx];
    [cacheURLs removeObjectAtIndex:idx];

    // Share the same downloader for identical URLs so we don't download the same URL several times
    SDWebImageDownloader *downloader = [downloaderForURL objectForKey:url];

    if (!downloader)
    {
        downloader = [SDWebImageDownloader downloaderWithURL:url delegate:self userInfo:info lowPriority:(options & SDWebImageLowPriority) imageName:[[info objectForKey:@"userInfo"] objectForKey:@"imageName"]];
        [downloaderForURL setObject:downloader forKey:url];
    }
    else
    {
        // Reuse shared downloader
        downloader.userInfo = info; // TOFIX: here we overload previous userInfo
        downloader.lowPriority = (options & SDWebImageLowPriority);
    }

    if ((options & SDWebImageProgressiveDownload) && !downloader.progressive)
    {
        // Turn progressive download support on demand
        downloader.progressive = YES;
    }

    [downloadDelegates addObject:delegate];
    [downloaders addObject:downloader];
}

#pragma mark SDWebImageDownloaderDelegate

- (void)imageDownloader:(SDWebImageDownloader *)downloader didUpdatePartialImage:(UIImage *)image
{
    // Notify all the downloadDelegates with this downloader
    for (NSInteger idx = (NSInteger)[downloaders count] - 1; idx >= 0; idx--)
    {
        NSUInteger uidx = (NSUInteger)idx;
        SDWebImageDownloader *aDownloader = [downloaders objectAtIndex:uidx];
        if (aDownloader == downloader)
        {
            id<SDWebImageManagerDelegate> delegate = [downloadDelegates objectAtIndex:uidx];
            SDWIRetain(delegate);
            SDWIAutorelease(delegate);

            if ([delegate respondsToSelector:@selector(webImageManager:didProgressWithPartialImage:forURL:)])
            {
                objc_msgSend(delegate, @selector(webImageManager:didProgressWithPartialImage:forURL:), self, image, downloader.url);
            }
            if ([delegate respondsToSelector:@selector(webImageManager:didProgressWithPartialImage:forURL:userInfo:)])
            {
                NSDictionary *userInfo = [downloader.userInfo objectForKey:@"userInfo"];
                if ([userInfo isKindOfClass:NSNull.class])
                {
                    userInfo = nil;
                }
                objc_msgSend(delegate, @selector(webImageManager:didProgressWithPartialImage:forURL:userInfo:), self, image, downloader.url, userInfo);
            }
        }
    }
}

- (void)imageDownloader:(SDWebImageDownloader *)downloader didFinishWithImage:(UIImage *)image
{
    SDWIRetain(downloader);
    SDWebImageOptions options = (SDWebImageOptions)[[downloader.userInfo objectForKey:@"options"] intValue];

    // Notify all the downloadDelegates with this downloader
    for (NSInteger idx = (NSInteger)[downloaders count] - 1; idx >= 0; idx--)
    {
        NSUInteger uidx = (NSUInteger)idx;
        SDWebImageDownloader *aDownloader = [downloaders objectAtIndex:uidx];
        if (aDownloader == downloader)
        {
            id<SDWebImageManagerDelegate> delegate = [downloadDelegates objectAtIndex:uidx];
            SDWIRetain(delegate);
            SDWIAutorelease(delegate);

            if (image)
            {
                if ([delegate respondsToSelector:@selector(webImageManager:didFinishWithImage:)])
                {
                    [delegate performSelector:@selector(webImageManager:didFinishWithImage:) withObject:self withObject:image];
                }
                if ([delegate respondsToSelector:@selector(webImageManager:didFinishWithImage:forURL:)])
                {
                    objc_msgSend(delegate, @selector(webImageManager:didFinishWithImage:forURL:), self, image, downloader.url);
                }
                if ([delegate respondsToSelector:@selector(webImageManager:didFinishWithImage:forURL:userInfo:)])
                {
                    NSDictionary *userInfo = [downloader.userInfo objectForKey:@"userInfo"];
                    if ([userInfo isKindOfClass:NSNull.class])
                    {
                        userInfo = nil;
                    }
                    
                    void (*action)(id, SEL, id,id,id,id) = (void (*)(id, SEL, id,id,id,id)) objc_msgSend;
                    action(delegate, @selector(webImageManager:didFinishWithImage:forURL:userInfo:), self, image, downloader.url, userInfo);

//                    objc_msgSend(delegate, @selector(webImageManager:didFinishWithImage:forURL:userInfo:), self, image, downloader.url, userInfo);
                }
#if NS_BLOCKS_AVAILABLE
                if ([downloader.userInfo objectForKey:@"success"])
                {
                    SuccessBlock success = [downloader.userInfo objectForKey:@"success"];
                    success(image);
                }
#endif
            }
            else
            {
                if ([delegate respondsToSelector:@selector(webImageManager:didFailWithError:)])
                {
                    [delegate performSelector:@selector(webImageManager:didFailWithError:) withObject:self withObject:nil];
                }
                if ([delegate respondsToSelector:@selector(webImageManager:didFailWithError:forURL:)])
                {
                    objc_msgSend(delegate, @selector(webImageManager:didFailWithError:forURL:), self, nil, downloader.url);
                }
                if ([delegate respondsToSelector:@selector(webImageManager:didFailWithError:forURL:userInfo:)])
                {
                    NSDictionary *userInfo = [downloader.userInfo objectForKey:@"userInfo"];
                    if ([userInfo isKindOfClass:NSNull.class])
                    {
                        userInfo = nil;
                    }
                    objc_msgSend(delegate, @selector(webImageManager:didFailWithError:forURL:userInfo:), self, nil, downloader.url, userInfo);
                }
#if NS_BLOCKS_AVAILABLE
                if ([downloader.userInfo objectForKey:@"failure"])
                {
                    FailureBlock failure = [downloader.userInfo objectForKey:@"failure"];
                    failure(nil);
                }
#endif
            }

            [downloaders removeObjectAtIndex:uidx];
            [downloadDelegates removeObjectAtIndex:uidx];
        }
    }

    if (image)
    {
//        //test//
//        NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/aaa.jpg"];
//        [UIImageJPEGRepresentation(image, 1) writeToFile:path atomically:YES];
//        enum ImageType imageType = [[downloader.userInfo objectForKey:kImageType] intValue];
//        switch (imageType)
//        {
//            case ImageType_TopicEntity:
//            case ImageType_ParticipantIcon://50
//            {
//                image = [image imageBlackBackGroundToSize:CGSizeMake(100, 100)];
//            }
//                break;
//            case ImageType_UrlEntity://60
//            {
//                image = [image imageBlackBackGroundToSize:CGSizeMake(100, 100)];
//            }
//                break;
//            case ImageType_UserIcon100://100
//            {
//                image = [image imageBlackBackGroundToSize:CGSizeMake(100, 100)];
//            }
//                break;
//            case ImageType_UserIcon200://200
//            {
//                image = [image imageBlackBackGroundToSize:CGSizeMake(200, 200)];
//            }
//                break;
//                
//            default:
//                break;
//        }
//        path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/ddd.jpg"];
//        [UIImageJPEGRepresentation(image, 1) writeToFile:path atomically:YES];
        // Store the image in the cache
        [[SDImageCache sharedImageCache] storeImage:image
                                          imageData:downloader.imageData
                                             forKey:[downloader.imageName length]>0?downloader.imageName:[self cacheKeyForURL:downloader.url]
                                             toDisk:!(options & SDWebImageCacheMemoryOnly)];
    }
    else if (!(options & SDWebImageRetryFailed))
    {
        // The image can't be downloaded from this URL, mark the URL as failed so we won't try and fail again and again
        // (do this only if SDWebImageRetryFailed isn't activated)
        [failedURLs addObject:downloader.url];
    }


    // Release the downloader
    [downloaderForURL removeObjectForKey:downloader.url];
    SDWIRelease(downloader);
}

- (void)imageDownloader:(SDWebImageDownloader *)downloader didFailWithError:(NSError *)error;
{
    SDWIRetain(downloader);

    // Notify all the downloadDelegates with this downloader
    for (NSInteger idx = (NSInteger)[downloaders count] - 1; idx >= 0; idx--)
    {
        NSUInteger uidx = (NSUInteger)idx;
        SDWebImageDownloader *aDownloader = [downloaders objectAtIndex:uidx];
        if (aDownloader == downloader)
        {
            id<SDWebImageManagerDelegate> delegate = [downloadDelegates objectAtIndex:uidx];
            SDWIRetain(delegate);
            SDWIAutorelease(delegate);

            if ([delegate respondsToSelector:@selector(webImageManager:didFailWithError:)])
            {
                [delegate performSelector:@selector(webImageManager:didFailWithError:) withObject:self withObject:error];
            }
            if ([delegate respondsToSelector:@selector(webImageManager:didFailWithError:forURL:)])
            {
                objc_msgSend(delegate, @selector(webImageManager:didFailWithError:forURL:), self, error, downloader.url);
            }
            if ([delegate respondsToSelector:@selector(webImageManager:didFailWithError:forURL:userInfo:)])
            {
                NSDictionary *userInfo = [downloader.userInfo objectForKey:@"userInfo"];
                if ([userInfo isKindOfClass:NSNull.class])
                {
                    userInfo = nil;
                }
                objc_msgSend(delegate, @selector(webImageManager:didFailWithError:forURL:userInfo:), self, error, downloader.url, userInfo);
            }
#if NS_BLOCKS_AVAILABLE
            if ([downloader.userInfo objectForKey:@"failure"])
            {
                FailureBlock failure = [downloader.userInfo objectForKey:@"failure"];
                failure(error);
            }
#endif

            [downloaders removeObjectAtIndex:uidx];
            [downloadDelegates removeObjectAtIndex:uidx];
        }
    }

    // Release the downloader
    [downloaderForURL removeObjectForKey:downloader.url];
    SDWIRelease(downloader);
}

@end
