//
//  ACAddress.m
//  AcuCom
//
//  Created by wfs-aculearn on 14-3-27.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACAddress.h"
#import "ACMessage.h"


#ifdef Enum_2_Str_ITEM_DEF

static struct   Enum_2_Str_ITEM    g__TheACFile_TypeS[] = {
    Enum_2_Str_ITEM_DEF(ACFile_Type_LoginJson),
    Enum_2_Str_ITEM_DEF(ACFile_Type_SecondLoginJson),
    Enum_2_Str_ITEM_DEF(ACFile_Type_Logout),
    Enum_2_Str_ITEM_DEF(ACFile_Type_LoopInquire),
    Enum_2_Str_ITEM_DEF(ACFile_Type_SyncData),
    Enum_2_Str_ITEM_DEF(ACFile_Type_Database),
    Enum_2_Str_ITEM_DEF(ACFile_Type_GetContactPersonRootList),
    Enum_2_Str_ITEM_DEF(ACFile_Type_GetContactPersonSubGroupList),
    Enum_2_Str_ITEM_DEF(ACFile_Type_GetContactPersonSinglePersonList),
    Enum_2_Str_ITEM_DEF(ACFile_Type_GetContactPersonSearchList),
    Enum_2_Str_ITEM_DEF(ACFile_Type_CreateGroupChat),
    Enum_2_Str_ITEM_DEF(ACFile_Type_GetChatMessage),
    Enum_2_Str_ITEM_DEF(ACFile_Type_SendHasBeenReadTopic),
    Enum_2_Str_ITEM_DEF(ACFile_Type_SendText),
    Enum_2_Str_ITEM_DEF(ACFile_Type_SendLocation),
    Enum_2_Str_ITEM_DEF(ACFile_Type_SendSticker),
    Enum_2_Str_ITEM_DEF(ACFile_Type_SendImage_Json),
    Enum_2_Str_ITEM_DEF(ACFile_Type_SendAudio_Json),
    Enum_2_Str_ITEM_DEF(ACFile_Type_SendVideo_Json),
    Enum_2_Str_ITEM_DEF(ACFile_Type_TransmitMsg),
    Enum_2_Str_ITEM_DEF(ACFile_Type_AudioFile),
    Enum_2_Str_ITEM_DEF(ACFile_Type_VideoFile),
    Enum_2_Str_ITEM_DEF(ACFile_Type_VideoThumbFile),
    Enum_2_Str_ITEM_DEF(ACFile_Type_ImageFile),
    Enum_2_Str_ITEM_DEF(ACFile_Type_StickerFile),
    Enum_2_Str_ITEM_DEF(ACFile_Type_File),
    Enum_2_Str_ITEM_DEF(ACFile_Type_GetParticipant_Json),
    Enum_2_Str_ITEM_DEF(ACFile_Type_AddParticipant_Json),
    Enum_2_Str_ITEM_DEF(ACFile_Type_GetReadCount_Json),
    Enum_2_Str_ITEM_DEF(ACFile_Type_GetSingleReadSeq_Json),
    Enum_2_Str_ITEM_DEF(ACFile_Type_GetHadReadList_Json),
    Enum_2_Str_ITEM_DEF(ACFile_Type_StickerDir_Json),
    Enum_2_Str_ITEM_DEF(ACFile_Type_StickerThumbnail),
    Enum_2_Str_ITEM_DEF(ACFile_Type_StickerZip),
    Enum_2_Str_ITEM_DEF(ACFile_Type_DeleteLoopInquire),
    Enum_2_Str_ITEM_DEF(ACFile_Type_LocationAlert),
//    Enum_2_Str_ITEM_DEF(ACFile_Type_LocationScan),
    Enum_2_Str_ITEM_DEF(ACFile_Type_WallboardPhoto),
    Enum_2_Str_ITEM_DEF(ACFile_Type_WallboardVideo),
    Enum_2_Str_ITEM_DEF(ACFile_Type_WallboardVideoThumb),
    Enum_2_Str_ITEM_DEF(ACFile_Type_SendNoteOrWallboard),
    Enum_2_Str_ITEM_DEF(ACFile_Type_SearchMessage),
    Enum_2_Str_ITEM_DEF(ACFile_Type_SearchUser),
    Enum_2_Str_ITEM_DEF(ACFile_Type_SearchUserGroup),
//    Enum_2_Str_ITEM_DEF(ACFile_Type_SearchHighLight),
    Enum_2_Str_ITEM_DEF(ACFile_Type_SearchCount),
    Enum_2_Str_ITEM_DEF(ACFile_Type_ChangePassword),
    Enum_2_Str_ITEM_DEF(ACFile_Type_GetCategories),
    Enum_2_Str_ITEM_DEF(ACFile_Type_GetSuitsOfCategory),
    Enum_2_Str_ITEM_DEF(ACFile_Type_GetUserOwnStickers),
    Enum_2_Str_ITEM_DEF(ACFile_Type_RemoveUserOwnSticker),
    Enum_2_Str_ITEM_DEF(ACFile_Type_AddStickerSuitToMyStickersAndDownload),
    Enum_2_Str_ITEM_DEF(ACFile_Type_DownloadSuit),
    Enum_2_Str_ITEM_DEF(ACFile_Type_DownloadSticker),
    Enum_2_Str_ITEM_DEF(ACFile_Type_GetAllSuits),
    Enum_2_Str_ITEM_DEF(ACFile_Type_GetSuitInfo),
    Enum_2_Str_ITEM_DEF(ACFile_Type_SendFile_Json),
    
    Enum_2_Str_ITEM_DEF_END()
};


const char* ACFile_Type_Name(enum ACFile_Type type){
    return Enum_2_Str_FindItemFunc(type,g__TheACFile_TypeS);
}
#endif


@implementation ACAddress

//得到fileMsg的资源地址，用于转发时获取length
+(NSString *)getFileMsgAddressWithFileMsg:(ACFileMessage *)fileMsg
{
    enum ACFile_Type fileType = 0;
    switch (fileMsg.messageEnumType)
    {
        case ACMessageEnumType_Audio:
        {
            fileType = ACFile_Type_AudioFile;
        }
            break;
        case ACMessageEnumType_Image:
        {
            fileType = ACFile_Type_ImageFile;
        }
            break;
        case ACMessageEnumType_Video:
        {
            fileType = ACFile_Type_VideoFile;
        }
            break;
        case ACMessageEnumType_File:
        {
            fileType = ACFile_Type_File;
        }
            break;
            
        default:
            break;
    }
    NSString *filePath = [ACAddress getAddressWithFileName:fileMsg.resourceID fileType:fileType isTemp:NO subDirName:nil];
    return filePath;
}

+(NSString *)getAddressWithFileName:(NSString *)fileName fileType:(enum ACFile_Type)fileType isTemp:(BOOL)isTemp subDirName:(NSString *)subDirName
{
    if (isTemp)
    {
        if (subDirName)
        {
            return [NSString stringWithFormat:@"%@%@%@",NSTemporaryDirectory(),subDirName,fileName];
        }
        else
        {
            return [NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(),fileName];
        }
    }
    else
    {
        switch (fileType)
        {
            case 1110:
            case ACFile_Type_LocationSharing_Member_Icon:
                return [NSString stringWithFormat:@"%@/%@",kImageTempPath,fileName];
                break;
            case ACFile_Type_ImageFile:
            {
                if (![[NSFileManager defaultManager] fileExistsAtPath:kImageForeverPath])
                {
                    [[NSFileManager defaultManager] createDirectoryAtPath:kImageForeverPath withIntermediateDirectories:YES attributes:nil error:nil];
                }
                return [NSString stringWithFormat:@"%@/%@.jpg",kImageForeverPath,fileName];
            }
                break;
            case ACFile_Type_SendText:
            case ACFile_Type_SendLocation:
            case ACFile_Type_SendSticker:
            case ACFile_Type_SendImage_Json:
            case ACFile_Type_SendAudio_Json:
            case ACFile_Type_SendVideo_Json:
            case ACFile_Type_SendFile_Json:
            {
                if (![[NSFileManager defaultManager] fileExistsAtPath:kJsonTempPath])
                {
                    [[NSFileManager defaultManager] createDirectoryAtPath:kJsonTempPath withIntermediateDirectories:YES attributes:nil error:nil];
                }
                return [NSString stringWithFormat:@"%@/%@",kJsonTempPath,fileName];
            }
                break;
            case ACFile_Type_LoginJson:
            case ACFile_Type_LoopInquire:
            case ACFile_Type_GetContactPersonRootList:
            case ACFile_Type_GetContactPersonSubGroupList:
            case ACFile_Type_GetContactPersonSinglePersonList:
            case ACFile_Type_GetContactPersonSearchList:
            case ACFile_Type_SecondLoginJson:
            case ACFile_Type_GetParticipant_Json:
            case ACFile_Type_SyncData:
//            case ACFile_Type_Note_List_Json:
            {
                if (![[NSFileManager defaultManager] fileExistsAtPath:kJsonForeverPath])
                {
                    [[NSFileManager defaultManager] createDirectoryAtPath:kJsonForeverPath withIntermediateDirectories:YES attributes:nil error:nil];
                }
                return [NSString stringWithFormat:@"%@/%@",kJsonForeverPath,fileName];
            }
                break;
            case ACFile_Type_Database:
            {
                return [NSString stringWithFormat:@"%@/%@",kLibraryPath,fileName];
            }
                break;
            case ACFile_Type_AudioFile:
            {
                if (![[NSFileManager defaultManager] fileExistsAtPath:kAudioPath])
                {
                    [[NSFileManager defaultManager] createDirectoryAtPath:kAudioPath withIntermediateDirectories:YES attributes:nil error:nil];
                }
                return [NSString stringWithFormat:@"%@/%@.wav",kAudioPath,fileName];
            }
                break;
            case ACFile_Type_VideoFile:
            case ACFile_Type_VideoThumbFile:
            {
                if (![[NSFileManager defaultManager] fileExistsAtPath:kVideoPath])
                {
                    [[NSFileManager defaultManager] createDirectoryAtPath:kVideoPath withIntermediateDirectories:YES attributes:nil error:nil];
                }
                if (fileType == ACFile_Type_VideoFile)
                {
                    return [NSString stringWithFormat:@"%@/%@.mp4",kVideoPath,fileName];
                }
                else if (fileType == ACFile_Type_VideoThumbFile)
                {
                    return [NSString stringWithFormat:@"%@/%@.jpg",kVideoPath,fileName];
                }
            }
                break;
            case ACFile_Type_File:
            {
                if (![[NSFileManager defaultManager] fileExistsAtPath:kFilePath])
                {
                    [[NSFileManager defaultManager] createDirectoryAtPath:kFilePath withIntermediateDirectories:YES attributes:nil error:nil];
                }
//                ITLogEX_If(subDirName!=nil,@"File \"%@\" No Ext",fileName);
//                return [NSString stringWithFormat:@"%@/%@.%@",kFilePath,fileName,subDirName];
                return [NSString stringWithFormat:@"%@/%@.%@",kFilePath,fileName,subDirName];
            }
                break;
            case ACFile_Type_StickerDir_Json:
            {
                if (![[NSFileManager defaultManager] fileExistsAtPath:kStickerForeverPath])
                {
                    [[NSFileManager defaultManager] createDirectoryAtPath:kStickerForeverPath withIntermediateDirectories:YES attributes:nil error:nil];
                }
                return [NSString stringWithFormat:@"%@/%@",kStickerForeverPath,fileName];
            }
                break;
            case ACFile_Type_StickerThumbnail:
            case ACFile_Type_StickerZip:
            case ACFile_Type_StickerFile:
            case ACFile_Type_DownloadSticker:
            {
                NSString *subPath = [kStickerForeverPath stringByAppendingFormat:@"/%@",subDirName];
                if (![[NSFileManager defaultManager] fileExistsAtPath:subPath])
                {
                    [[NSFileManager defaultManager] createDirectoryAtPath:subPath withIntermediateDirectories:YES attributes:nil error:nil];
                }
                if (fileName)
                {
                    return [NSString stringWithFormat:@"%@/%@",subPath,fileName];
                }
                else
                {
                    return subPath;
                }
            }
                break;
            case ACFile_Type_AddStickerSuitToMyStickersAndDownload:
            case ACFile_Type_DownloadSuit:
            {
                NSString *subPath = kStickerForeverPath;
                if (![[NSFileManager defaultManager] fileExistsAtPath:subPath])
                {
                    [[NSFileManager defaultManager] createDirectoryAtPath:subPath withIntermediateDirectories:YES attributes:nil error:nil];
                }
                if (fileName)
                {
                    return [NSString stringWithFormat:@"%@/%@",subPath,fileName];
                }
                else
                {
                    return subPath;
                }
            }
                break;
            case ACFile_Type_GetSuitInfo:
            {
                NSString *subPath = kStickerForeverPath;
                if (![[NSFileManager defaultManager] fileExistsAtPath:subPath])
                {
                    [[NSFileManager defaultManager] createDirectoryAtPath:subPath withIntermediateDirectories:YES attributes:nil error:nil];
                }
                if (fileName)
                {
                    return [NSString stringWithFormat:@"%@/%@.json",subPath,fileName];
                }
                else
                {
                    return subPath;
                }
            }
                break;
            case ACFile_Type_WallboardPhoto:
            {
                if (![[NSFileManager defaultManager] fileExistsAtPath:kWallboardPhotoForeverPath])
                {
                    [[NSFileManager defaultManager] createDirectoryAtPath:kWallboardPhotoForeverPath withIntermediateDirectories:YES attributes:nil error:nil];
                }
                return [NSString stringWithFormat:@"%@/%@.jpg",kWallboardPhotoForeverPath,fileName];
            }
                break;
            case ACFile_Type_WallboardVideo:
            {
                if (![[NSFileManager defaultManager] fileExistsAtPath:kWallboardVideoForeverPath])
                {
                    [[NSFileManager defaultManager] createDirectoryAtPath:kWallboardVideoForeverPath withIntermediateDirectories:YES attributes:nil error:nil];
                }
                return [NSString stringWithFormat:@"%@/%@.mp4",kWallboardVideoForeverPath,fileName];
            }
                break;
            case ACFile_Type_WallboardVideoThumb:
            {
                if (![[NSFileManager defaultManager] fileExistsAtPath:kWallboardVideoForeverPath])
                {
                    [[NSFileManager defaultManager] createDirectoryAtPath:kWallboardVideoForeverPath withIntermediateDirectories:YES attributes:nil error:nil];
                }
                return [NSString stringWithFormat:@"%@/%@.jpg",kWallboardVideoForeverPath,fileName];
            }
                break;
            default:
                break;
        }
    }
    return @"";
}

@end
