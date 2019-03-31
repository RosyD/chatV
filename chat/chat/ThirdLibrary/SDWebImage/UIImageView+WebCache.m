/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+WebCache.h"
#import "ACNetCenter.h"
#import "ACConfigs.h"
#import "ACAddress.h"
#import "UIImage+Additions.h"
#import "UIView+Additions.h"
#import "NSString+Additions.h"

@implementation UIImageView (WebCache)

+(NSString *)getStickerSaveAddressWithPath:(NSString *)path withName:(NSString *)name
{
    NSString *title = [path stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    NSString *saveAddress = [ACAddress getAddressWithFileName:name fileType:ACFile_Type_StickerZip isTemp:NO subDirName:title];
    return saveAddress;
}

-(void)setStickerWithStickerPath:(NSString *)path stickerName:(NSString *)name placeholderImage:(UIImage *)placeholderImage
{
    //已经下载直接从本地取
    NSString *saveAddress = [UIImageView getStickerSaveAddressWithPath:path withName:name];
    if ([[NSFileManager defaultManager] fileExistsAtPath:saveAddress])
    {
        self.image = [UIImage imageWithContentsOfFile:saveAddress];
    }
    else
    {
        NSString *url = [NSString stringWithFormat:@"%@/ujs/app/im/res/emoji/%@/%@",[[ACNetCenter shareNetCenter] acucomServer],path,name];
        [self setImageWithURL:[NSURL URLWithString:url] placeholderImage:placeholderImage imageName:nil imageType:ImageType_Define];
    }
}

-(void)setStickerWithResourceId:(NSString *)resourceId placeholderImage:(UIImage *)placeholderImage
{
//    //已经下载直接从本地取
//    NSString *saveAddress = [UIImageView getStickerSaveAddressWithPath:path withName:name];
//    if ([[NSFileManager defaultManager] fileExistsAtPath:saveAddress])
//    {
//        self.image = [UIImage imageWithContentsOfFile:saveAddress];
//    }
//    else
    {
        NSString *url = [NSString stringWithFormat:@"%@/rest/apis/sticker/suitID/image/%@",[[ACNetCenter shareNetCenter] acucomServer],resourceId];
        [self setImageWithURL:[NSURL URLWithString:url] placeholderImage:placeholderImage imageName:nil imageType:ImageType_Define];
    }
}

+(NSString*)getIconInfoWithIconString:(NSString *)iconString ImageType:(enum ImageType)type isURL:(BOOL*)pIsURL{
    //如果是找自己的icon,我可以先看看本地有没有保存,有得话直接用,没有从网上下载
//    NSString* pOwnIcon = [[NSUserDefaults standardUserDefaults] objectForKey:kIcon];
    if(0==iconString.length){
        return nil;
    }
    if ([iconString isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:kIcon]]){
        NSString *imagePath = nil;
        if (type == ImageType_UserIcon200){
            imagePath = [ACAddress getAddressWithFileName:kIcon_200_200 fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
        }
        else if (type == ImageType_UserIcon100){
            imagePath = [ACAddress getAddressWithFileName:kIcon_100_100 fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
        }
        else if(type == ImageType_UserIcon1000){
            imagePath = [ACAddress getAddressWithFileName:kIcon_1000_1000 fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]){
            return imagePath;
        }
    }
    
    *pIsURL = YES;

    if([[iconString lowercaseString] startWith:@"http://"]){
        return iconString;
    }
    
    NSString *acucomServer = [[ACNetCenter shareNetCenter] acucomServer];
    if(nil==acucomServer){
        return nil;
    }
    
    switch (type)
    {
        case ImageType_TopicEntity:
        case ImageType_ParticipantIcon:
        {
            return  [NSString stringWithFormat:@"%@%@&w=%d&h=%d",acucomServer,iconString,100,100];
        }
            break;
        case ImageType_UrlEntity:
        {
            return [NSString stringWithFormat:@"%@%@&w=%d&h=%d",acucomServer,iconString,100,100];
        }
            break;
        case ImageType_UserIcon100:
        {
            return [NSString stringWithFormat:@"%@%@&w=%d&h=%d",acucomServer,iconString,100,100];
        }
            break;
        case ImageType_UserIcon200:
        {
            return [NSString stringWithFormat:@"%@%@&w=%d&h=%d",acucomServer,iconString,200,200];
        }
            break;
        case ImageType_UserIcon1000:
        {
            return [NSString stringWithFormat:@"%@%@&w=%d&h=%d",acucomServer,iconString,1000,1000];
        }
            break;
        default:
            break;
    }
    
    return nil;
}

-(void)setImageWithIconString:(NSString *)iconString placeholderImage:(UIImage *)placeholder ImageType:(enum ImageType)type
{
    BOOL bIsURL = NO;
    NSString* pIconInfo = [UIImageView getIconInfoWithIconString:iconString ImageType:type isURL:&bIsURL];
    
    NSLog(@"%@",pIconInfo);
    if(nil==pIconInfo){
        self.image =  placeholder;
        return;
    }
    
    if(bIsURL){
      [self setImageWithURL:[NSURL URLWithString:pIconInfo] placeholderImage:placeholder imageName:nil imageType:type];
    }
    else{
        self.image = [UIImage imageWithContentsOfFile:pIconInfo];
    }
    
/*
    //如果是找自己的icon,我可以先看看本地有没有保存,有得话直接用,没有从网上下载
    if ([iconString isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:kIcon]])
    {
        NSString *imagePath = nil;
        if (type == ImageType_UserIcon200)
        {
            imagePath = [ACAddress getAddressWithFileName:kIcon_200_200 fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
        }
        else if (type == ImageType_UserIcon100)
        {
            imagePath = [ACAddress getAddressWithFileName:kIcon_100_100 fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
        }
        else if(type == ImageType_UserIcon1000){
            imagePath = [ACAddress getAddressWithFileName:kIcon_1000_1000 fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath])
        {
            self.image = [UIImage imageWithContentsOfFile:imagePath];
            return;
        }
    }
    NSString *acIconUrl = @"";
    if([iconString startWith:@"http://"]){
        acIconUrl = iconString;
    }
    else{
        switch (type)
        {
            case ImageType_TopicEntity:
            case ImageType_ParticipantIcon:
            {
                acIconUrl = [NSString stringWithFormat:@"%@%@&w=%d&h=%d",[[ACNetCenter shareNetCenter] acucomServer],iconString,100,100];
            }
                break;
            case ImageType_UrlEntity:
            {
                acIconUrl = [NSString stringWithFormat:@"%@%@&w=%d&h=%d",[[ACNetCenter shareNetCenter] acucomServer],iconString,100,100];
            }
                break;
            case ImageType_UserIcon100:
            {
                acIconUrl = [NSString stringWithFormat:@"%@%@&w=%d&h=%d",[[ACNetCenter shareNetCenter] acucomServer],iconString,100,100];
            }
                break;
            case ImageType_UserIcon200:
            {
                acIconUrl = [NSString stringWithFormat:@"%@%@&w=%d&h=%d",[[ACNetCenter shareNetCenter] acucomServer],iconString,200,200];
            }
                break;
            case ImageType_UserIcon1000:
            {
                acIconUrl = [NSString stringWithFormat:@"%@%@&w=%d&h=%d",[[ACNetCenter shareNetCenter] acucomServer],iconString,1000,1000];
            }
                break;
            default:
                break;
        }
    }
    [self setImageWithURL:[NSURL acIconUrl] placeholderImage:placeholder imageName:nil imageType:type];
 */
}

-(void)setImageWithEntityID:(NSString *)entityID withMsgID:(NSString *)msgID thumbRid:(NSString *)thumbRid placeholderImage:(UIImage *)placeholder
{
    NSString *url = [NSString stringWithFormat:@"%@/topic/%@/upload/%@",[ACNetCenter urlHead_ChatWithTopicID:entityID],msgID,thumbRid];
    [self setImageWithURL:[NSURL URLWithString:url] placeholderImage:placeholder imageName:thumbRid imageType:ImageType_ImageMessage];
}

//设置NoteMessage的thumb
/*TXB Nouse
-(void)setNoteThumbImageWithNoteMsgID:(NSString*)noteMsgId thumbRid:(NSString *)thumbRid  placeholderImage:(UIImage *)placeholder
{
    NSString *url = [NSString stringWithFormat:@"%@/rest/apis/note/%@/upload/%@",[[ACNetCenter shareNetCenter] acucomServer],noteMsgId,thumbRid];
    [self setImageWithURL:[NSURL URLWithString:url] placeholderImage:placeholder imageName:thumbRid imageType:ImageType_ImageMessage];
}*/


-(void)setImageWithLatitude:(double)latitude withLongitude:(double)longitude placeholderImage:(UIImage *)placeholder
{
    NSString *url = [NSString stringWithFormat:@"http://maps.google.com/maps/api/staticmap?center=%lf,%lf&format=jpg&maptype=roadmap&markers=%lf,%lf&zoom=13&size=100x130&sensor=false&key=%@",latitude,longitude,latitude,longitude,kGoogleSearchKey];
    [self setImageWithURL:[NSURL URLWithString:url] placeholderImage:placeholder imageName:nil imageType:ImageType_Define];
}

- (void)setImageWithURL:(NSURL *)url imageName:(NSString *)imageName imageType:(enum ImageType)imageType
{
    [self setImageWithURL:url placeholderImage:nil imageName:imageName imageType:imageType];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder imageName:(NSString *)imageName imageType:(enum ImageType)imageType
{
    [self setImageWithURL:url placeholderImage:placeholder options:(SDWebImageOptions)0 imageName:imageName imageType:imageType];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options imageName:(NSString *)imageName imageType:(enum ImageType)imageType
{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];

    // Remove in progress downloader from queue
    [manager cancelForDelegate:self];

    self.image = placeholder;

    if (url)
    {
        [manager downloadWithURL:url delegate:self options:options imageName:imageName imageType:imageType];
    }
}

//#if NS_BLOCKS_AVAILABLE
//- (void)setImageWithURL:(NSURL *)url success:(void (^)(UIImage *image))success failure:(void (^)(NSError *error))failure;
//{
//    [self setImageWithURL:url placeholderImage:nil success:success failure:failure];
//}
//
//- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder success:(void (^)(UIImage *image))success failure:(void (^)(NSError *error))failure;
//{
//    [self setImageWithURL:url placeholderImage:placeholder options:(SDWebImageOptions)0 success:success failure:failure];
//}
//
//- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options success:(void (^)(UIImage *image))success failure:(void (^)(NSError *error))failure;
//{
//    SDWebImageManager *manager = [SDWebImageManager sharedManager];
//
//    // Remove in progress downloader from queue
//    [manager cancelForDelegate:self];
//
//    self.image = placeholder;
//
//    if (url)
//    {
//        [manager downloadWithURL:url delegate:self options:options success:success failure:failure];
//    }
//}
//#endif

- (void)cancelCurrentImageLoad
{
    [[SDWebImageManager sharedManager] cancelForDelegate:self];
}

- (void)webImageManager:(SDWebImageManager *)imageManager didProgressWithPartialImage:(UIImage *)image forURL:(NSURL *)url
{
    self.image = image;
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        UIImage *scaledImage = [image imageBlackBackGroundToSize:CGSizeMake(self.size.width*2, self.size.height*2)];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            self.image = scaledImage;
//        });
//    });
}

- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image
{
    self.image = image;
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        UIImage *scaledImage = [image imageBlackBackGroundToSize:CGSizeMake(self.size.width*2, self.size.height*2)];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            self.image = scaledImage;
//        });
//    });
}

@end
