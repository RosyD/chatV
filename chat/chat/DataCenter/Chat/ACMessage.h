//
//  ACMessage.h
//  AcuCom
//
//  Created by 王方帅 on 14-4-10.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define kPath       @"path"
#define kName       @"name"
#define kLength     @"length"
#define kDuration   @"duration"

extern NSString *const ACMessageType_text;
extern NSString *const ACMessageType_location;
extern NSString *const ACMessageType_sticker;
extern NSString *const ACMessageType_audio;
extern NSString *const ACMessageType_image;
extern NSString *const ACMessageType_video;
extern NSString *const ACMessageType_file;
//extern NSString *const notes;
extern NSString *const ACMessageType_wallBoard;


enum ACMessageEnumType
{
    ACMessageEnumType_Text,
    ACMessageEnumType_Location,
    ACMessageEnumType_Sticker,
    ACMessageEnumType_Audio,
    ACMessageEnumType_Image,
    ACMessageEnumType_Video,
    ACMessageEnumType_File,
    
    ACMessageEnumType_WallBoard,
    ACMessageEnumType_System,
    ACMessageEnumType_Videocall,
    ACMessageEnumType_Audiocall,
    
    ACMessageEnumType_ShareLocation,
    
    ACMessageEnumType_Unknow = 1000 //未知类型
};

#define ACMessageEnumType_Unknow_String NSLocalizedString(@"Unsupported message type for current version.", nil)

enum ACMessageDirectionType
{
    ACMessageDirectionType_Send,
    ACMessageDirectionType_Receive,
};

enum ACMessageUploadState
{
    ACMessageUploadState_None = 0,
    ACMessageUploadState_Uploading = 1,
    ACMessageUploadState_Uploaded = 2,
    ACMessageUploadState_UploadFailed = 3,
    ACMessageUploadState_Transmiting = 4,
    ACMessageUploadState_TransmitFailed = 6,
};

#define kSeq        @"seq"
#define kTeid   @"teid"

#define kLo     @"lo"
#define kLa     @"la"
#define kContent    @"content"
#define kDeleted    @"deleted"
#define kTitle      @"title"

#define kTopics     @"topics"
#define kTopic      @"topic"
#define kTes        @"tes"

#define kSmall      @"small"
#define kBig        @"big"

#define kType       @"type"

#define ACMessage_seq_DEF   LONG_MAX //((long)MAXFLOAT)

@class ACTopicEntity;
@class FMResultSet;
@interface ACMessage : NSObject<NSCopying>


@property (nonatomic,strong) NSString   *messageID;
@property (nonatomic,strong) NSString   *topicEntityID;//组ID
@property (nonatomic,strong) NSString   *topicEntityTitle;//已删除组title
@property (nonatomic,strong) NSString   *messageType;
@property (nonatomic) double            createTime;
@property (nonatomic) long              createTimeForYYYYMMDD; //创建时间的年月日，用于比较
@property (nonatomic) int               currentResendCount;
@property (nonatomic) NSTimeInterval    timeForSendFromTCP; //用于检查TCP发送超时的时间
@property (nonatomic) enum ACMessageEnumType        messageEnumType;
@property (nonatomic) CLLocationCoordinate2D        messageLocation;//消息带经纬度
@property (nonatomic) enum ACMessageDirectionType   directionType;//发送还是接收
@property (nonatomic,strong) NSString               *sendUserID;
@property (nonatomic) long                          seq; //编号,缺省是(long)MAXFLOAT 不能直接和MAXFLOAT比较
@property (nonatomic,strong) NSString               *content;
@property (nonatomic) int                           messageUploadState;
@property (nonatomic) BOOL                          isNeedDateShow;//内存中有，数据库不存
//@property (nonatomic) BOOL                          isNeedShowNewMsgFlag; //显示newMsgFlag
@property (nonatomic) BOOL                          isDeleted;
@property (nonatomic,readonly) BOOL                 isTextEnumType; //是文本类型，如Text Videocall Radiocall
@property (nonatomic,readonly) BOOL                 canTransmit; //是否可以转发

+(ACMessage *)getTransmitMsgWithMsg:(ACMessage *)msg withTopicEntityID:(NSString *)topicEntityID;

+(NSString*)getTempMsgID; //取得一个临时使用的MsgID

- (id)initWithTopicDic:(NSDictionary *)topicDic;

//比较自己跟参数message是否是同一天的消息
//-(BOOL)isSameDayWithMessage:(ACMessage *)message;

//通过seq比较，用于排序
-(NSComparisonResult)compare:(ACMessage *)message;

//从数据库resultSet读出消息
+(ACMessage *)getMessageWithFMResultSet:(FMResultSet *)resultSet;

-(NSMutableDictionary *)getDic;

+(enum ACMessageEnumType)getMessageEnumTypeWithMessageType:(NSString *)type;

+(ACMessage *)messageWithDic:(NSDictionary *)dic;

//创建message
+(ACMessage *)createMessageWithMessageType:(NSString *)messageType topicEnitity:(ACTopicEntity *)topicEntity messageContent:(NSString *)content sendMsgID:(NSString *)msgID location:(CLLocation *)location;

-(void)updateWithDic:(NSDictionary *)dic;//发送文本成功后调用更新id、时间、seq

@end

@interface ACTextMessage : ACMessage

@end

@interface ACLocationMessage : ACMessage

@property (nonatomic) CLLocationCoordinate2D    location;

@end

@interface ACStickerMessage : ACMessage

@property (nonatomic,strong) NSString   *stickerPath;
@property (nonatomic,strong) NSString   *stickerName;
@property (nonatomic) int               width;
@property (nonatomic) int               height;

+(NSString *)getStickerPathWithSuitID:(NSString *)suitID withRid:(NSString *)rid;

@end


#define kCaption     @"caption"

@interface ACFileMessage : ACMessage

@property (nonatomic) int               duration;//时间长度
@property (nonatomic) long              length;//文件大小
@property (nonatomic,strong) NSString   *name;
@property (nonatomic,strong) NSString   *resourceID;
@property (nonatomic,strong) NSString   *thumbResourceID;
@property (nonatomic,strong) NSString   *caption; //图片标题
@property (nonatomic) float             progress;
@property (nonatomic) BOOL              isDownloading;
@property (nonatomic) BOOL              isPlaying;
@property (nonatomic,strong) NSArray    *smallSizeArray;//[12, 32]宽度,高度
@property (nonatomic,strong) NSArray    *bigSizeArray;

-(NSMutableDictionary *)getTransmitDic;

@end

@interface ACFileMessageCache : NSObject

@property (nonatomic,strong) NSString   *messageID;
@property (nonatomic) long              seq; //编号
@property (nonatomic) long              length;//文件大小
@property (nonatomic) enum ACMessageEnumType        messageEnumType;     // ACMessageEnumType_Image, ACMessageEnumType_Video,
@property (nonatomic,strong) NSString   *resourceID; //=nil表示没网，没有缓存,只在getACFileMessageCacheFromDBWithTopicEntityID时有效
@property (nonatomic,strong) NSString   *thumbResourceID;


+(ACFileMessageCache *)getFileMessageCacheWithFMResultSet:(FMResultSet *)resultSet;
+(ACFileMessageCache *)getFileMessageCacheWithDict:(NSDictionary *)pDict;
+(ACFileMessageCache *)getFileMessageCacheWithFileMessage:(ACFileMessage*)fileMessage;
-(void)updateContent:(NSDictionary*) pContent;
-(NSString *)getCachedFilePathNameWithTopicEntityID:(NSString *)topicEntityID forThumb:(BOOL)bForThumb;
-(NSString *)getURLWithTopicEntityID:(NSString *)topicEntityID forThumb:(BOOL)bForThumb;

@end
