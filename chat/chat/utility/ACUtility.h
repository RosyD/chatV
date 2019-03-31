//
//  ACUtility.h
//  chat
//
//  Created by Aculearn on 14/12/31.
//  Copyright (c) 2014年 Aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
//#if TARGET_IPHONE_SIMULATOR
//显示提示信息 "ok"

#define wself_define()   __weak typeof(self) wself = self
#define sself_define()   __strong typeof(wself) sself = wself

void    AC_ShowTipFunc(NSString*pTitle,NSString* pTip);

#define AC_ShowTip(p______Tip)  AC_ShowTipFunc(nil,(p______Tip))

#define UIColor_RGBA(R, G, B, A) [UIColor colorWithRed:((R) / 255.0f) green:((G) / 255.0f) blue:((B) / 255.0f) alpha:A]
#define UIColor_RGB(R, G, B) UIColor_RGBA(R,G,B,1.0f)

//取得并检查NSDictionary
#define NSDictionary_getAndCheckValueString(p_____ValueName,p___NSDictionary,p____FieldName) {NSString* pTempStr = [p___NSDictionary objectForKey:p____FieldName]; if(pTempStr){  p_____ValueName  =   pTempStr;}}


#define NSDictionary_getAndCheckValueDouble(p_____ValueName,p___NSDictionary,p____FieldName) {NSNumber* pTempStr = [p___NSDictionary objectForKey:p____FieldName]; if(pTempStr){  p_____ValueName  =   [pTempStr doubleValue];}}

#define NSDictionary_getAndCheckValueLong(p_____ValueName,p___NSDictionary,p____FieldName) {NSNumber* pTempStr = [p___NSDictionary objectForKey:p____FieldName]; if(pTempStr){  p_____ValueName  =   [pTempStr longValue];}}

#define NSDictionary_getAndCheckValueBool(p_____ValueName,p___NSDictionary,p____FieldName) {NSNumber* pTempStr = [p___NSDictionary objectForKey:p____FieldName]; if(pTempStr){  p_____ValueName  =   [pTempStr boolValue];}}


#define ScrollView_ScrollStat_Showed_Center  0   //显示中间，无头无尾
#define ScrollView_ScrollStat_Showed_Head    1   //显示了头
#define ScrollView_ScrollStat_Showed_Tail    2   //显示了尾
#define ScrollView_ScrollStat_Showed_All     (ScrollView_ScrollStat_Showed_Head|ScrollView_ScrollStat_Showed_Tail)

@interface ACUtility : NSObject

+(void)ShowTip:(NSString*)pTip withTitle:(NSString*)pTitle;

+(void)showTip:(NSString*)pTip;
+(void)showTip:(NSString*)pTip dalay:(CGFloat)delay;

+ (BOOL)isHeadsetPluggedIn; //戴在头上的耳机或听筒

+(UIImage*)thumbFromMovieURL:(NSURL*)pURL;
+(CGFloat)getVideoDuration:(NSURL*)URL;
+(BOOL)checkVideo:(NSURL*)URL Deuration:(CGFloat)dure; //>dure返回YES,<dure返回NO
+(int)getValueWithName:(NSString*)pName fromDict:(NSDictionary *)dicPerm andDefault:(int)nDefault;
+(NSString*)getOEMStringFromAbout:(NSString*)pKey;

+(NSDate*)nowLocalDate; //取得当前日期
+(int)scrollViewScrollStat:(UIScrollView*) pScrollView; //返回ScrollView_ScrollStat_*

+(long)getFileSizeWithPath:(NSString *)path;

+(void)LogFile_Swich;
+(NSData*)LogFile_Load:(BOOL)bClear;

+(void)  ITLogUserStringBuffers_Add:(NSString*)pStr;
+(NSString*) ITLogFormatWithSrcFile:(const char*)pSourcePath andLineNo:(int)nLineNo andCmd:(NSString*)sel;

+(UIImage*) loadFileIcon:(NSString*)fileName;
+(UIImage*) loadFileExtIcon:(NSString*)ext;
+(BOOL)     fileExtIsMedia:(NSString*)ext;


+(long)dir_size:(NSString*)pDirPath; //目录大小
+(int)dir_fileCount:(NSString*)pDirPath; //目录文件数
+(void)dir_clear:(NSString*)pDirPath; //目录清空
+(void)dir_clear:(NSString*)pDirPath forDay:(int)nDays; //按时间清除目录


+(UILabel*)lableCenterWithColor:(UIColor*)txtColor fontSize:(CGFloat)fontSize andText:(NSString*)pText;
+(UIButton*)buttonWithTarget:(id)target action:(SEL)action withTextOrImg:(NSObject*)textOrImg;
+(UIButton*)buttonWithTarget:(id)target action:(SEL)action withText:(NSString*)pText;
+(UIButton*)buttonWithTarget:(id)target action:(SEL)action withImg:(NSString*)imgName;

+(void)postNotificationName:(NSString *)aName object:(id)anObject;
@end

//@interface ACTipView : UIView


//@end

#if DEBUG
    //#define ACUtility_Log_UseStringBuffers  //使用日志缓冲区
    #define ACUtility_Log_UseFile           
    //使用文件日志系统,就不会向控制台输出了,必要时请注销main.m内的[ACUtility LogFile_Swich]

#else
//    #define  ACUtility_Log_UseStringBuffers
//    #define  ACUtility_Log_UseFile //G-Chat如果是测试，需要打开Debug
//    发行版不需要 ACUtility_Log_UseFile AcuCom打包版本已经定义了 ACUtility_Log_UseFile

//#error 不能发布，这个版本是为了修改融合webRTC最小化在屏幕上

#endif


#if TARGET_IPHONE_SIMULATOR
//模拟器不需要
    #undef ACUtility_Log_UseFile
    #undef ACUtility_Log_UseStringBuffers
#else

#endif

#define AC_LogString_Head   [ACUtility ITLogFormatWithSrcFile:__FILE__ andLineNo:__LINE__ andCmd:NSStringFromSelector(_cmd)]

//#define ACUtility_Log_Out_Format_String @"%@(%@): %@"
#define ACUtility_Log_Out_Format_String @"%@:\t %@"
#ifdef ACUtility_Log_UseStringBuffers
    //使用日志缓冲区
    void        ITLogUserStringBuffers_Clear();
    NSString*   ITLogUserStringBuffers_Strings();
    #define ITLog(STRLOG)           [ACUtility ITLogUserStringBuffers_Add:[NSString stringWithFormat:ACUtility_Log_Out_Format_String, AC_LogString_Head, STRLOG]]
    #define ITLogEX(format, ...)    [ACUtility  ITLogUserStringBuffers_Add:[NSString stringWithFormat:ACUtility_Log_Out_Format_String, AC_LogString_Head, [NSString stringWithFormat:format,## __VA_ARGS__]]]
    #undef ACUtility_Log_UseFile
#endif

#if DEBUG||defined(ACUtility_Log_UseFile)
    /*
     Xcode8 中 IOS10真机屏蔽了NSLog
     隐藏一些烦人的Log信息，就是设置 OS_ACTIVITY_MODE = disable，
     */


//#define NSSLog(FORMAT, ...) fprintf(stderr,"%s:%d\t%s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

//    #if TARGET_IPHONE_SIMULATOR
//        #define AC_NSLog    NSLog
//    #else
        #define AC_NSLog(FORMAT, ...)   fprintf(stderr,"%s\n",[[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String])
//    #endif

    //使用文件日志系统
    #define ITLog(STRLOG)          AC_NSLog(ACUtility_Log_Out_Format_String, AC_LogString_Head, STRLOG)
    #define ITLogEX(format,...)    AC_NSLog(ACUtility_Log_Out_Format_String, AC_LogString_Head, [NSString stringWithFormat:format,## __VA_ARGS__])
    #define ITLogEX_Simple(format,...) AC_NSLog(@"%@",[NSString stringWithFormat:format,## __VA_ARGS__])
    #define ITLogEX_If(if_____check,format,...) if(if_____check){AC_NSLog(ACUtility_Log_Out_Format_String, AC_LogString_Head, [NSString stringWithFormat:format,## __VA_ARGS__]);}
#endif

#ifndef ITLog
    //并没有定义输出
    #define ITLog(STRLOG)
    #define ITLogEX(format,...)
    #define ITLogEX_Simple(format,...)
    #define ITLogEX_If(if_____check,format,...)
#endif


//NSLog(@"%@",[NSThread callStackSymbols]);

#if DEBUG||defined(ACUtility_Log_UseStringBuffers)||defined(ACUtility_Log_UseFile)
    //将Enum定义为文本,方便输出
    struct Enum_2_Str_ITEM {
        int             enum_value;
        const char*     pTypeName;
    };
    #define Enum_2_Str_ITEM_DEF(the____Type)   {the____Type,#the____Type}
    #define Enum_2_Str_ITEM_DEF_END()           {0,NULL}
    const char* Enum_2_Str_FindItemFunc(int nEnum_Value,struct Enum_2_Str_ITEM* pEnum2StrItemsHead);

    #define ACUtility_Need_Log      //需要输出日志

#endif

#ifdef ACUtility_Need_Log

@interface ACUtility(Mem_Debug)
//检查内存泄露
+(void)MemDebug_Alloc_WithSrcFile:(const char*)pSourcePath andLineNo:(int)nLineNo withOBJ:(NSObject*)the_obj;
+(void)MemDebug_Dealloc_WithSrcFile:(const char*)pSourcePath andLineNo:(int)nLineNo withOBJ:(NSObject*)the_obj;
+(void)MemDebug_Check:(BOOL)bCheck;
+(NSString*)MemDebug_AllocInfo;
@end

#define AC_MEM_Alloc(p__OBJ)    [ACUtility MemDebug_Alloc_WithSrcFile:__FILE__ andLineNo:__LINE__ withOBJ:p__OBJ]
#define AC_MEM_Dealloc()        [ACUtility MemDebug_Dealloc_WithSrcFile:__FILE__ andLineNo:__LINE__ withOBJ:self]
#define AC_MEM_Dealloc_implementation    -(void)dealloc{AC_MEM_Dealloc();}
#define AC_MEM_Check(b__Check)          [ACUtility  MemDebug_Check:b__Check]
#else
    #define AC_MEM_Alloc(p__OBJ)
    #define AC_MEM_Dealloc()
    #define AC_MEM_Dealloc_implementation
    #define AC_MEM_Check(b__Check)
#endif



