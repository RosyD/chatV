//
//  ACUtility.m
//  chat
//
//  Created by Aculearn on 14/12/31.
//  Copyright (c) 2014年 Aculearn. All rights reserved.
//

#import "ACUtility.h"
#import <AVFoundation/AVFoundation.h>
#import "NSString+Additions.h"


void AC_ShowTipFunc(NSString*pTitle,NSString* pTip){
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:pTitle message:pTip delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
    [alert show];
}

@interface ACTipLable : UILabel
@end

static ACTipLable*  g__goubleTipLable = nil;
@implementation ACTipLable

-(void)hideTip{
    [self removeFromSuperview];
    g__goubleTipLable = nil;
}

@end

@implementation ACUtility

+(void)ShowTip:(NSString*)pTip withTitle:(NSString*)pTitle{
    AC_ShowTipFunc(pTitle,pTip);
}

+(void)showTip:(NSString*)pTip{
    [self showTip:pTip dalay:1.5];
}

+(void)showTip:(NSString*)pTip dalay:(CGFloat)delay{
    if(g__goubleTipLable){
        [NSObject cancelPreviousPerformRequestsWithTarget:g__goubleTipLable];
        [g__goubleTipLable hideTip];
    }
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    UIFont* pFont = [UIFont systemFontOfSize:15];
    CGSize showSize =   [pTip getAutoSizeWithLimitWidth:screenSize.width andLimitHight:MAXFLOAT font:pFont];
    showSize.width  +=  10;
    showSize.height +=  4;
    ACTipLable *label = [[ACTipLable alloc] initWithFrame:CGRectMake((screenSize.width-showSize.width)/2, screenSize.height/2, showSize.width, showSize.height)];
    label.text = pTip;
    label.backgroundColor = [UIColor darkGrayColor];
    label.textColor = [UIColor whiteColor];
    label.numberOfLines = 0;
    label.font = pFont;
    label.textAlignment = NSTextAlignmentCenter;
    [label setRectRound:5];
    
    g__goubleTipLable   =   label;
    [[[UIApplication sharedApplication].delegate window] addSubview:label];
    
    [label performSelector:@selector(hideTip)
                withObject:nil
                afterDelay:delay];
}

+(UILabel*)lableCenterWithColor:(UIColor*)txtColor fontSize:(CGFloat)fontSize  andText:(NSString*)pText{
    UILabel* pLable     =   [[UILabel alloc] init];
    pLable.textColor    =   txtColor;
    pLable.textAlignment=   NSTextAlignmentCenter;
    pLable.font         =   [UIFont systemFontOfSize:fontSize];
    pLable.text         =   pText;
    return pLable;
}

+(UIButton*)buttonWithTarget:(id)target action:(SEL)action withTextOrImg:(NSObject*)textOrImg{
    UIButton* pButton = [[UIButton alloc] init];
    
    if(textOrImg){
        if([textOrImg isKindOfClass:[UIImage class]]){
            [pButton setImage:(UIImage*)textOrImg forState:UIControlStateNormal];
        }
        else{
            [pButton setNomalText:(NSString*)textOrImg];
        }
    }
    [pButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return pButton;
}
+(UIButton*)buttonWithTarget:(id)target action:(SEL)action withText:(NSString*)pText{
    return [self buttonWithTarget:target action:action withTextOrImg:pText];
}
+(UIButton*)buttonWithTarget:(id)target action:(SEL)action withImg:(NSString*)imgName{
    return [self buttonWithTarget:target action:action withTextOrImg:[UIImage imageNamed:imgName]];
}


+(NSString*)getOEMStringFromAbout:(NSString*)pKey{
    NSString* pRet = NSLocalizedStringFromTable(pKey,@"about",nil);
    if([pRet isEqualToString:pKey]){
        pRet = NSLocalizedString(pKey,nil);
    }
    return pRet;
}

+(int)getValueWithName:(NSString*)pName fromDict:(NSDictionary *)dicPerm andDefault:(int)nDefault{
    id object = [dicPerm objectForKey:pName];
    return object?([object intValue]):nDefault;
}

+(CGFloat)getVideoDuration:(NSURL*) URL
{
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:URL options:opts];
    float second = 0;
    second = urlAsset.duration.value/urlAsset.duration.timescale;
    return second;
}

+(NSDate*)nowLocalDate{ //取得当前本地日期
    NSDate *date = [NSDate date]; //取得的时GTM时间
    
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate: date];
    
    return [date  dateByAddingTimeInterval: interval]; //返回当前时区的时间
    
}

+(int)scrollViewScrollStat:(UIScrollView*) pScrollView{ //返回ScrollView_ScrollStat_*
    //main_tableView 滚动状态
    CGRect bounds = pScrollView.bounds;
    CGSize size = pScrollView.contentSize;
    
    if(size.height<=bounds.size.height){
        //显示了全部
//        ITLogEX(@"显示全部");
        return ScrollView_ScrollStat_Showed_All;
    }
    
    CGPoint offset = pScrollView.contentOffset;
    if(offset.y<5){
//        NSLog(@"到头");

        return  ScrollView_ScrollStat_Showed_Head;
    }
    
    if(offset.y+bounds.size.height>=(size.height-10)){
//        NSLog(@"到尾");

        return ScrollView_ScrollStat_Showed_Tail;
    }
//    ITLogEX(@"%f,%f 中间",offset.y+bounds.size.height,size.height);
    return  ScrollView_ScrollStat_Showed_Center;
}

//{
//    UILocalNotification *notification = [[UILocalNotification alloc] init];
//    notification.alertBody = content;
//    notification.alertAction = action;
//    notification.soundName = UILocalNotificationDefaultSoundName;
//    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
//
//}
+(BOOL)checkVideo:(NSURL*)URL Deuration:(CGFloat)dure{
    if([ACUtility getVideoDuration:URL]>dure){
        //提示错误
        [ACUtility ShowTip:[NSString stringWithFormat:NSLocalizedString(@"Please select the video less than %d seconds", nil),(int)dure] withTitle:nil];
        return YES;
    }
    return NO;
}

+(long)getFileSizeWithPath:(NSString *)path{
    NSError *error = nil;
    NSDictionary *dic = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
    if (error){
        return 0;
    }
    return [dic fileSize];
}


+(long)dir_size:(NSString*)pDirPath{ //目录大小
    long size = 0;
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:pDirPath];
    for (NSString *fileName in fileEnumerator){
        NSString *filePath = [pDirPath stringByAppendingPathComponent:fileName];
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        size += [attrs fileSize];
    }
    return size;
}

+(int)dir_fileCount:(NSString*)pDirPath{ //目录文件数
    int count = 0;
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:pDirPath];
    for (NSString *fileName in fileEnumerator){
        count += 1;
    }
    
    return count;
}

+(void)dir_clear:(NSString*)pDirPath{ //目录清空
    [[NSFileManager defaultManager] removeItemAtPath:pDirPath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:pDirPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
}
+(void)dir_clear:(NSString*)pDirPath forDay:(int)nDays{ //按时间清除目录
    if(nDays<=0){
        [self dir_clear:pDirPath];
        return;
    }
    //    NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-cacheMaxCacheAge];
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-60*60*24*nDays];
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:pDirPath];
    for (NSString *fileName in fileEnumerator){
        NSString *filePath = [pDirPath stringByAppendingPathComponent:fileName];
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        if ([[[attrs fileModificationDate] laterDate:expirationDate] isEqualToDate:expirationDate]){
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
    }
}

+(void)postNotificationName:(NSString *)aName object:(id)anObject{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:aName object:anObject userInfo:nil];
    });
}

+ (BOOL)isHeadsetPluggedIn{ //戴在头上的耳机或听筒
    
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs])
    {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
    }
    return NO;
#endif
}

+(UIImage*)thumbFromMovieURL:(NSURL*)pURL{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:pURL options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(1.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return thumb;
    
/*
 需要添加AVFoundation和CoreMedia.framework
 另外一种那个方法
 
 
 MPMoviePlayerController *moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:videoURL]; moviePlayer.shouldAutoplay = NO;
 UIImage *thumbnail = [moviePlayer thumbnailImageAtTime:time timeOption:MPMovieTimeOptionNearestKeyFrame];
 //这个也一样
 
 +(UIImage *)fFirstVideoFrame:(NSString *)path
 {
 MPMoviePlayerController *mp = [[MPMoviePlayerController alloc]
 initWithContentURL:[NSURL fileURLWithPath:path]];
 UIImage *img = [mp thumbnailImageAtTime:0.0
 timeOption:MPMovieTimeOptionNearestKeyFrame];
 [mp stop];
 [mp release];
 return img;
 }
 */
    
}

#define ACUtility_LogFilePath   [NSTemporaryDirectory() stringByAppendingPathComponent:@"AcuCom.log"]

+(void)LogFile_Swich{
    NSString *logPath   =   ACUtility_LogFilePath;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
//    printf("%s\n",logPath.UTF8String);

    if ([fileManager fileExistsAtPath:logPath]&&
        [[fileManager attributesOfItemAtPath:logPath error:nil] fileSize]>5*1024*1024){
        [fileManager removeItemAtPath:logPath error:nil];
    }
    
    freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
}


+(NSData*)LogFile_Load:(BOOL)bClear{
    NSString *logPath   =   ACUtility_LogFilePath;
    fclose(stderr);
    NSData* pRet = [NSData dataWithContentsOfFile:logPath];
    if(bClear){
        [[NSFileManager defaultManager] removeItemAtPath:logPath error:nil];
    }
    freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
    return pRet;
}




static  NSDateFormatter*    g__NowTimeFormater = nil;

static  const char* _getSrcFileName(const char* pSourcePath){
    const char* pFileName = strrchr(pSourcePath, '/');
    if(pFileName){
        return pFileName+1;
    }
    return pSourcePath;
}

+(NSString*) ITLogFormatWithSrcFile:(const char*)pSourcePath andLineNo:(int)nLineNo andCmd:(NSString*)sel{
    if(nil==g__NowTimeFormater){
        g__NowTimeFormater = [[NSDateFormatter alloc] init];
        [g__NowTimeFormater setDateFormat:@"MM-dd hh:mm:ss.SSS"];
    }

    return [NSString stringWithFormat:@"%@ %@(%s:%d)",[g__NowTimeFormater stringFromDate:[NSDate date]],sel,_getSrcFileName(pSourcePath),nLineNo];
}


#ifdef ACUtility_Log_UseStringBuffers
//使用日志缓冲区
NSMutableString*    g___Log_UseStringBuffers = nil;
+(void)  ITLogUserStringBuffers_Add:(NSString*) pStr{
    if(nil==g___Log_UseStringBuffers){
        g___Log_UseStringBuffers = [[NSMutableString alloc] initWithCapacity:1024*1024];
    }
    [g___Log_UseStringBuffers appendFormat:@"%@\n",pStr];
}
void        ITLogUserStringBuffers_Clear(){
    [g___Log_UseStringBuffers setString:@""];
}
NSString*   ITLogUserStringBuffers_Strings(){
    return g___Log_UseStringBuffers;
}
#endif

static int _loadFileIconFunc(const char* pExt,const char** pExts){
    int nRet = 0;
    while(*pExts){
        if(0==strcmp(pExt, *pExts)){
            return nRet;
        }
        pExts ++;
        nRet ++;
    }
    return -1;
}

+(UIImage*) loadFileIcon:(NSString*)fileName{
    return [self loadFileExtIcon:fileName.pathExtension];
}

static const char* media_ext[]={"asf","avi","wm","wmp","wmv","ram","rm","rmvb","rp","rpm","rt","smi","smil","m1v","m2v","m2p","m2t","m2ts","mp2v","mpe","mpeg","mpg","mpv2","pss","pva","tp","tpr","ts","m4b","m4p","m4v","mp4","mpeg4","3g2","3gp","3gp2","3gpp","mov","qt","f4v","flv","hlv","swf","ifo","vob","amv","bik",
    "csf","divx","evo","ivm","mkv","mod","mts","ogm","pmp","scm","tod","vp6","webm","xlmv","aac","ac3","amr","ape","cda","dts","flac","m1a","m2a","m4a","mid","midi","mka","mp2","mp3","mpa","ogg","ra","tak","tta","wav","wma","wv","asx","cue","kpl","m3u","pls","qpl","smpl","ass","srt","ssa","dat",NULL};

+(BOOL)     fileExtIsMedia:(NSString*)ext{
    return _loadFileIconFunc(ext.lowercaseString.UTF8String,media_ext)>=0;
}

+(UIImage*) loadFileExtIcon:(NSString*)ext{
    static const char*  office_ext[] = {"doc","docx","docm","dotx","dotm",NULL};
    static const char*  ppts_ext[] = {"ppt","pptx","pptm","ppsx","ppsm","potx","potm","ppam",NULL};
    static const char*  excels_ext[] = {"xls","xlsx","xlsm","xltx","xltm","xlsb","xlam",NULL};
    static const char*  zip_ext[] = {"rar","zip","tar","gz",NULL};
    static const char*  img_ext[]={"jpg","gif","png","jpg","jpeg","tif","bmp",NULL};
    
    NSString* pRetIconName = @"file_icon_normal";
    ext = ext.lowercaseString;
    if(ext.length>0){
        const char* pFileEx = ext.UTF8String;
        if(_loadFileIconFunc(pFileEx,media_ext)>=0){
            pRetIconName = @"file_icon_media";
        }
        else if(_loadFileIconFunc(pFileEx,office_ext)>=0){
            pRetIconName = @"file_icon_doc";
        }
        else if(_loadFileIconFunc(pFileEx,ppts_ext)>=0){
            pRetIconName = @"file_icon_ppt";
        }
        else if(_loadFileIconFunc(pFileEx,excels_ext)>=0){
            pRetIconName = @"file_icon_xls";
        }
        else if(_loadFileIconFunc(pFileEx,zip_ext)>=0){
            pRetIconName = @"file_icon_rar";
        }
        else if(_loadFileIconFunc(pFileEx,img_ext)>=0){
            pRetIconName = @"file_icon_pic";
        }
        else{
            static const char*  other_ext[]= {"html","htm","chm","txt","pdf","vcf",NULL};

            int nOther = _loadFileIconFunc(pFileEx,other_ext);
            if(nOther>=0){
                if(nOther<2){ //0,1
                    pRetIconName = @"file_icon_html";
                }
                else if(2==nOther){
                    pRetIconName = @"file_icon_chm";
                }
                else if(3==nOther){
                    pRetIconName = @"file_icon_plaintext";
                }
                else if(4==nOther){
                    pRetIconName = @"file_icon_pdf";
                }
                else if(5==nOther){
                    pRetIconName = @"file_icon_vcf";
                }
            }
        }
    }
    
//    file_icon_download
//    file_icon_onenote
    return [UIImage imageNamed:pRetIconName];
}

/*
 public static void setImageViewByFileExtension (ImageView iv, String extension) {
 String[] mediaExtensions = new String[] {"asf","avi","wm","wmp","wmv","ram","rm","rmvb","rp","rpm","rt","smi","smil","m1v","m2v","m2p","m2t","m2ts","mp2v","mpe","mpeg","mpg","mpv2","pss","pva","tp","tpr","ts","m4b","m4p","m4v","mp4","mpeg4","3g2","3gp","3gp2","3gpp","mov","qt","f4v","flv","hlv","swf","ifo","vob","amv","bik",
 "csf","divx","evo","ivm","mkv","mod","mts","ogm","pmp","scm","tod","vp6","webm","xlmv","aac","ac3","amr","ape","cda","dts","flac","m1a","m2a","m4a","mid","midi","mka","mp2","mp3","mpa","ogg","ra","tak","tta","wav","wma","wv","asx","cue","kpl","m3u","pls","qpl","smpl","ass","srt","ssa","dat"};
 
 List<String> mediaExLists = Arrays.asList(mediaExtensions);
 String[] words = new String[] {"doc","docx","docm","dotx","dotm"};
 List<String> wordList = Arrays.asList(words);
 String[] ppts = new String[] {"ppt","pptx","pptm","ppsx","ppsm","potx","potm","ppam"};
 List<String> pptList = Arrays.asList(ppts);
 String[] excels = new String[] {"xls","xlsx","xlsm","xltx","xltm","xlsb","xlam"};
 List<String> excelList = Arrays.asList(excels);
 
 if (extension.equalsIgnoreCase("html") || extension.equalsIgnoreCase("htm")) {
 iv.setImageResource(R.drawable.file_icon_html);
 } else if (extension.equalsIgnoreCase("chm")) {
 iv.setImageResource(R.drawable.file_icon_chm);
 } else if (wordList.contains(extension)) {
 iv.setImageResource(R.drawable.file_icon_doc);
 } else if (excelList.contains(extension)) {
 iv.setImageResource(R.drawable.file_icon_xls);
 } else if (pptList.contains(extension)) {
 iv.setImageResource(R.drawable.file_icon_ppt);
 } else if (extension.equalsIgnoreCase("rar") || extension.equalsIgnoreCase("zip") || extension.equalsIgnoreCase("tar") || extension.equalsIgnoreCase("gz")) {
 iv.setImageResource(R.drawable.file_icon_rar);
 } else if (extension.equalsIgnoreCase("txt")) {
 iv.setImageResource(R.drawable.file_icon_plaintext);
 } else if (extension.equalsIgnoreCase("jpg") || extension.equalsIgnoreCase("gif") || extension.equalsIgnoreCase("png") || extension.equalsIgnoreCase("jpg") || extension.equalsIgnoreCase("jpeg") || extension.equalsIgnoreCase("tif") || extension.equalsIgnoreCase("bmp")) {
 iv.setImageResource(R.drawable.file_icon_pic);
 } else if (mediaExLists.contains(extension)) {
 iv.setImageResource(R.drawable.file_icon_media);
 } else if (extension.equalsIgnoreCase("pdf")) {
 iv.setImageResource(R.drawable.file_icon_pdf);
 } else if(extension.equals("vcf")) {
 iv.setImageResource(R.drawable.file_icon_vcf);
 } else {
 iv.setImageResource(R.drawable.file_icon_normal);
 }
 }
 */



@end


#ifdef ACUtility_Need_Log


@implementation  ACUtility(Mem_Debug)
//检查内存泄露
static  NSMutableDictionary* g__pMemDebugDict = nil;
static  int                  g__nMemAllocCount = 0;
static  u_long               g__nMemAllocIndex = 0;
static  NSDateFormatter*     g__pMemTimeFormater = nil;




+(void)MemDebug_Alloc_WithSrcFile:(const char*)pSourcePath andLineNo:(int)nLineNo withOBJ:(NSObject*)the_obj{
    const char* pClassName =    object_getClassName(the_obj);
    if(NULL==pClassName){
        return;
    }
    NSString* className = @(pClassName);
    
    if(nil==g__pMemDebugDict){
        g__pMemDebugDict = [[NSMutableDictionary alloc] initWithCapacity:100];
        g__pMemTimeFormater = [[NSDateFormatter alloc] init];
        [g__pMemTimeFormater setDateFormat:@"hh:mm:ss.SSS"];
    }
    
    @synchronized (g__pMemDebugDict) {
        pSourcePath =   _getSrcFileName(pSourcePath);
        
        NSMutableDictionary* pItems = g__pMemDebugDict[className];
        if(nil==pItems){
            pItems  =   [[NSMutableDictionary alloc] initWithCapacity:10];
            g__pMemDebugDict[className] =  pItems;
        }
        //g__nMemAllocIndex
        pItems[[NSString stringWithFormat:@"%p",the_obj]] = [NSString stringWithFormat:@"%s:%d %@ %ld",pSourcePath,nLineNo,[g__pMemTimeFormater stringFromDate:[NSDate date]],g__nMemAllocIndex];
        g__nMemAllocIndex ++;
    }
}

+(void)MemDebug_Dealloc_WithSrcFile:(const char*)pSourcePath andLineNo:(int)nLineNo withOBJ:(NSObject*)the_obj{
    const char* pClassName =    object_getClassName(the_obj);
    if(NULL==pClassName){
        return;
    }
    NSString* className = @(pClassName);
    
    @synchronized (g__pMemDebugDict) {
        NSMutableDictionary* pItems = g__pMemDebugDict[className];
        if(pItems){
            [pItems removeObjectForKey:[NSString stringWithFormat:@"%p",the_obj]];
            if(0==pItems.count){
                [g__pMemDebugDict removeObjectForKey:className];
            }
            return;
        }
        AC_NSLog(@"%@ dealloc error %s:%d",className,_getSrcFileName(pSourcePath),nLineNo);
    }
    
}

+(NSString*)MemDebug_AllocInfo{
    NSMutableString* pStringBuffer = [[NSMutableString alloc] initWithCapacity:1024];
    [g__pMemDebugDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString* pClassName = key;
        NSMutableDictionary* pItems = obj;
        
        [pStringBuffer appendFormat:@"%@ (%d)\n",pClassName,(int)pItems.count];
        [pItems enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key2, id  _Nonnull obj2, BOOL * _Nonnull stop2) {
            [pStringBuffer appendFormat:@"     %@ %@\n",(NSString*)key2,(NSString*)obj2];
        }];
    }];
    return pStringBuffer;
}
+(void)MemDebug_Check:(BOOL)bCheck{
    
    //延时执行
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    
        @synchronized (g__pMemDebugDict) {
            __block int nCount = 0;
            [g__pMemDebugDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop){
                nCount += ((NSMutableDictionary*)obj).count;
            }];
            
            if(nCount==g__nMemAllocCount&&bCheck){
                //在数量上没有改变
                return;
            }
            
            g__nMemAllocCount   =   nCount;
            
            if(0==g__pMemDebugDict.count){
                AC_NSLog(@"\n\n...........Mem Debug (0)..............\n\n");
                return;
            }

            AC_NSLog(@"\n\n...........Mem Debug..............");
            
            AC_NSLog(@"%@",[self MemDebug_AllocInfo]);
            
            AC_NSLog(@"...........Mem Debug..............\n\n");
        }

//    });
    
}

@end

#endif


#ifdef Enum_2_Str_ITEM_DEF

const char* Enum_2_Str_FindItemFunc(int nEnum_Value,struct Enum_2_Str_ITEM* pEnum2StrItemsHead){
    while(pEnum2StrItemsHead->pTypeName){
        if(pEnum2StrItemsHead->enum_value==nEnum_Value){
            return pEnum2StrItemsHead->pTypeName;
        }
        pEnum2StrItemsHead ++;
    }
    return "...............................出现错误啦........................";
}
#endif
