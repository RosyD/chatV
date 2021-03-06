/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"
#import "SDWebImageManagerDelegate.h"
#import "SDWebImageManager.h"

/**
 * Integrates SDWebImage async downloading and caching of remote images with UIImageView.
 *
 * Usage with a UITableViewCell sub-class:
 *
 * 	#import <SDWebImage/UIImageView+WebCache.h>
 * 	
 * 	...
 * 	
 * 	- (UITableViewCell *)tableView:(UITableView *)tableView
 * 	         cellForRowAtIndexPath:(NSIndexPath *)indexPath
 * 	{
 * 	    static NSString *MyIdentifier = @"MyIdentifier";
 * 	
 * 	    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
 * 	
 * 	    if (cell == nil)
 * 	    {
 * 	        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
 * 	                                       reuseIdentifier:MyIdentifier] autorelease];
 * 	    }
 * 	
 * 	    // Here we use the provided setImageWithURL: method to load the web image
 * 	    // Ensure you use a placeholder image otherwise cells will be initialized with no image
 * 	    [cell.imageView setImageWithURL:[NSURL URLWithString:@"http://example.com/image.jpg"]
 * 	                   placeholderImage:[UIImage imageNamed:@"placeholder"]];
 * 	
 * 	    cell.textLabel.text = @"My Text";
 * 	    return cell;
 * 	}
 * 	
 */

enum ImageType
{
    ImageType_Define,
    ImageType_TopicEntity,
    ImageType_UrlEntity,
    ImageType_ParticipantIcon,
    ImageType_UserIcon100,
    ImageType_UserIcon200,
    ImageType_UserIcon1000,
    ImageType_ImageMessage,
};


@interface UIImageView (WebCache) <SDWebImageManagerDelegate>

+(NSString *)getStickerSaveAddressWithPath:(NSString *)path withName:(NSString *)name;

-(void)setStickerWithStickerPath:(NSString *)path stickerName:(NSString *)name placeholderImage:(UIImage *)placeholderImage;

-(void)setStickerWithResourceId:(NSString *)resourceId placeholderImage:(UIImage *)placeholderImage;

-(void)setImageWithIconString:(NSString *)iconString placeholderImage:(UIImage *)placeholder ImageType:(enum ImageType)type;

+(NSString*)getIconInfoWithIconString:(NSString *)iconString ImageType:(enum ImageType)type isURL:(BOOL*)pIsURL;


//chat Image和video格式缩略图下载
-(void)setImageWithEntityID:(NSString *)entityID withMsgID:(NSString *)msgID thumbRid:(NSString *)thumbRid placeholderImage:(UIImage *)placeholder;

//设置NoteMessage的thumb
//-(void)setNoteThumbImageWithNoteMsgID:(NSString*)noteMsgId thumbRid:(NSString *)thumbRid  placeholderImage:(UIImage *)placeholder
;

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder imageName:(NSString *)imageName imageType:(enum ImageType)imageType;

-(void)setImageWithLatitude:(double)latitude withLongitude:(double)longitude placeholderImage:(UIImage *)placeholder;
/**
 * Set the imageView `image` with an `url`.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url for the image.
 */
- (void)setImageWithURL:(NSURL *)url;

/**
 * Set the imageView `image` with an `url` and a placeholder.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url for the image.
 * @param placeholder The image to be set initially, until the image request finishes.
 * @see setImageWithURL:placeholderImage:options:
 */
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder;

/**
 * Set the imageView `image` with an `url`, placeholder and custom options.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url for the image.
 * @param placeholder The image to be set initially, until the image request finishes.
 * @param options The options to use when downloading the image. @see SDWebImageOptions for the possible values.
 */
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(enum SDWebImageOptions)options;

#if NS_BLOCKS_AVAILABLE
/**
 * Set the imageView `image` with an `url`.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url for the image.
 * @param success A block to be executed when the image request succeed This block has no return value and takes the retrieved image as argument.
 * @param failure A block object to be executed when the image request failed. This block has no return value and takes the error object describing the network or parsing error that occurred (may be nil).
 */
- (void)setImageWithURL:(NSURL *)url success:(void (^)(UIImage *image))success failure:(void (^)(NSError *error))failure;

/**
 * Set the imageView `image` with an `url`, placeholder.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url for the image.
 * @param placeholder The image to be set initially, until the image request finishes.
 * @param success A block to be executed when the image request succeed This block has no return value and takes the retrieved image as argument.
 * @param failure A block object to be executed when the image request failed. This block has no return value and takes the error object describing the network or parsing error that occurred (may be nil).
 */
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder success:(void (^)(UIImage *image))success failure:(void (^)(NSError *error))failure;

/**
 * Set the imageView `image` with an `url`, placeholder and custom options.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url for the image.
 * @param placeholder The image to be set initially, until the image request finishes.
 * @param options The options to use when downloading the image. @see SDWebImageOptions for the possible values.
 * @param success A block to be executed when the image request succeed This block has no return value and takes the retrieved image as argument.
 * @param failure A block object to be executed when the image request failed. This block has no return value and takes the error object describing the network or parsing error that occurred (may be nil).
 */
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(enum SDWebImageOptions)options success:(void (^)(UIImage *image))success failure:(void (^)(NSError *error))failure;
#endif

/**
 * Cancel the current download
 */
- (void)cancelCurrentImageLoad;

@end
