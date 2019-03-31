//
//  ACAddress.h
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-27.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACConfigs.h"

#define kIcon_200_200 @"icon_200_200"
#define kIcon_100_100 @"icon_100_100"
#define kIcon_1000_1000 @"icon_1000_1000"


#define kLibraryPath [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0]

#define kCachesPath [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define kCache_Temp_Path_Func(p___Name)  [kCachesPath stringByAppendingPathComponent:p___Name]

// 图片
#define kImageTempPath_Name @"ImageTempCache"
#define kImageTempPath  kCache_Temp_Path_Func(kImageTempPath_Name)


#define kImageForeverPath_Name  @"ImageForeverCache"
#define kImageForeverPath kCache_Temp_Path_Func(kImageForeverPath_Name)

//Sticker
#define kStickerForeverPath_Name    @"StickerForeverCache"
#define kStickerForeverPath kCache_Temp_Path_Func(kStickerForeverPath_Name)

// json
#define kJsonTempPath_Name  @"JsonTempCache"
#define kJsonTempPath kCache_Temp_Path_Func(kJsonTempPath_Name)

#define kJsonForeverPath_Name    @"JsonForeverCache"
#define kJsonForeverPath kCache_Temp_Path_Func(kJsonForeverPath_Name)


//语音
#define kAudioPath_Name @"AudioCache"
#define kAudioPath kCache_Temp_Path_Func(kAudioPath_Name)

//视频
#define kVideoPath_Name @"VideoCache"
#define kVideoPath kCache_Temp_Path_Func(kVideoPath_Name)

//文件
#define kFilePath_Name  @"FileCache"
#define kFilePath kCache_Temp_Path_Func(kFilePath_Name)

//WallboardPhoto
#define kWallboardPhotoForeverPath_Name @"WallboardPhotoForeverCache"
#define kWallboardPhotoForeverPath kCache_Temp_Path_Func(kWallboardPhotoForeverPath_Name)

//WallboardVideo
#define kWallboardVideoForeverPath_Name @"WallboardVideoForeverCache"
#define kWallboardVideoForeverPath kCache_Temp_Path_Func(kWallboardVideoForeverPath_Name)

enum ACFile_Type
{
    ACFile_Type_LoginJson = 1,
    ACFile_Type_SecondLoginJson,
    ACFile_Type_Logout,
    ACFile_Type_LoopInquire,
    ACFile_Type_SyncData,
    ACFile_Type_Database,
    ACFile_Type_GetContactPersonRootList,
    ACFile_Type_GetContactPersonSubGroupList,
    ACFile_Type_GetContactPersonSinglePersonList,
    ACFile_Type_GetContactPersonSearchList,
    ACFile_Type_CreateGroupChat,
    ACFile_Type_GetChatMessage,
    ACFile_Type_SendHasBeenReadTopic,
    ACFile_Type_SendText,
    ACFile_Type_SendLocation,
    ACFile_Type_SendSticker,//16,
    ACFile_Type_SendImage_Json,//17,
    ACFile_Type_SendAudio_Json,
    ACFile_Type_SendVideo_Json,//19,
    ACFile_Type_TransmitMsg, //20,
    ACFile_Type_AudioFile,
    ACFile_Type_VideoFile,
    ACFile_Type_VideoThumbFile,
    ACFile_Type_ImageFile,
    ACFile_Type_StickerFile,
    ACFile_Type_File,
    ACFile_Type_GetParticipant_Json,
    ACFile_Type_AddParticipant_Json,
    ACFile_Type_GetReadCount_Json,
    ACFile_Type_GetSingleReadSeq_Json,
    ACFile_Type_GetHadReadList_Json,
    ACFile_Type_StickerDir_Json, //32,
    ACFile_Type_StickerThumbnail,
    ACFile_Type_StickerZip,
    ACFile_Type_DeleteLoopInquire, //35
    ACFile_Type_LocationAlert,
//    ACFile_Type_LocationScan,
    ACFile_Type_WallboardPhoto,
    ACFile_Type_WallboardVideo,
    ACFile_Type_WallboardVideoThumb, //40
    ACFile_Type_SendNoteOrWallboard,
    ACFile_Type_SearchMessage,
    ACFile_Type_SearchNote,
    ACFile_Type_SearchUser,
    ACFile_Type_SearchUserGroup, //45
//    ACFile_Type_SearchHighLight,
    ACFile_Type_SearchCount,
    ACFile_Type_ChangePassword,
    ACFile_Type_GetCategories,
    ACFile_Type_GetSuitsOfCategory,
    ACFile_Type_GetUserOwnStickers,
    ACFile_Type_RemoveUserOwnSticker,
    ACFile_Type_AddStickerSuitToMyStickersAndDownload,
    ACFile_Type_DownloadSuit,
    ACFile_Type_DownloadSticker,
    ACFile_Type_GetAllSuits,
    ACFile_Type_GetSuitInfo,
    ACFile_Type_SendFile_Json,
    
    ACFile_Type_LocationSharing_Member_Icon, //程序内部使用
    
//    ACFile_Type_Note_List_Json,
//    ACFile_Type_NoteComment_List_Json,
//    ACFile_Type_Note_SendComment,
};

@class ACFileMessage;
@interface ACAddress : NSObject

//得到fileMsg的资源地址，用于转发时获取length
+(NSString *)getFileMsgAddressWithFileMsg:(ACFileMessage *)fileMsg;

+(NSString *)getAddressWithFileName:(NSString *)fileName fileType:(enum ACFile_Type)fileType isTemp:(BOOL)isTemp subDirName:(NSString *)subDirName;

@end

#ifdef Enum_2_Str_ITEM_DEF
const char* ACFile_Type_Name(enum ACFile_Type type);
#endif
