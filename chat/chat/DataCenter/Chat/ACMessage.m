//
//  ACMessage.m
//  AcuCom
//
//  Created by 王方帅 on 14-4-10.
//  Copyright (c) 2014年 aculearn. All rights reserved.
//

#import "ACMessage.h"
#import "ACUser.h"
#import "ACNetCenter.h"
#import "ACUserDB.h"
#import "ACMessageEvent.h"
#import "ACAddress.h"
#import "ACEntity.h"
#import <AVFoundation/AVFoundation.h>
#import "FMResultSet.h"
#import "JSONKit.h"
#import "ACMessageDB.h"
#import "ACNoteMessage.h"
#import "ACLBSCenter.h"
#import "SDImageCache.h"

NSString *const ACMessageType_text = @"text";
NSString *const ACMessageType_location = @"location";
NSString *const ACMessageType_sticker = @"sticker";
NSString *const ACMessageType_audio = @"audio";
NSString *const ACMessageType_image = @"image";
NSString *const ACMessageType_video = @"video";
NSString *const ACMessageType_file = @"file";
//NSString *const notes = @"notes";
NSString *const ACMessageType_wallBoard = @"wallBoard";
NSString *const ACMessageType_system = @"system";
NSString *const ACMessageType_videocall = @"videocall";
NSString *const ACMessageType_audiocall = @"audiocall";

#define kType   @"type"
#define kImage  @"image"

#define kLongitude  @"longitude"
#define kLatitude   @"latitude"

#define kID         @"id"
#define kContentType        @"contentType"

#define kUser       @"user"

#define kDuration   @"duration"
#define kRid        @"rid"
#define kTrid       @"trid"
#define kCreateTime @"createTime"
#define kTime       @"time"
#define kFrom       @"from"   //"system" "android" "web" "pcweb" "ios"


@implementation ACMessage
@synthesize content = _content;

- (NSString *)description
{
    return [NSString stringWithFormat:@"messageID:%@ topicEntityID:%@ type:%@ content:\"%@\"", _messageID,_topicEntityID, _messageType,
                    [_content isKindOfClass:[NSString class]]?_content:@""];
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isNeedDateShow = NO;
    }
    return self;
}

- (id)initWithTopicDic:(NSDictionary *)topicDic
{
    self = [super init];
    if (self) {
        self.messageID = [topicDic objectForKey:kID];
        self.topicEntityID = [topicDic objectForKey:kTeid];
        self.messageType = [topicDic objectForKey:kContentType];
        self.messageEnumType = [ACMessage getMessageEnumTypeWithMessageType:_messageType];
        if ([topicDic objectForKey:kLa] && [topicDic objectForKey:kLo])
        {
            self.messageLocation = CLLocationCoordinate2DMake([[topicDic objectForKey:kLa] doubleValue], [[topicDic objectForKey:kLo] doubleValue]);
        }
        else
        {
            self.messageLocation = CLLocationCoordinate2DMake(0, 0);
        }
        
        NSDictionary *userDic = [topicDic objectForKey:kUser];
        ACUser *user = [[ACUser alloc] init];
        [user setUserDic:userDic];
        [ACUserDB saveUserToDBWithUser:user];
        if ([ACUser isMySelf:user.userid])
        {
            self.directionType = ACMessageDirectionType_Send;
            self.messageUploadState = ACMessageUploadState_Uploaded;
        }
        else
        {
            self.directionType = ACMessageDirectionType_Receive;
            self.messageUploadState = ACMessageUploadState_None;
        }
        self.sendUserID = user.userid;
        self.seq = [[topicDic objectForKey:kSeq] longValue];
        self.createTime = [[topicDic objectForKey:kCreateTime] doubleValue];
        NSString *content = [topicDic objectForKey:kContent];
        if ([content isKindOfClass:[NSDictionary class]])
        {
            content = [(NSDictionary *)content JSONString];
        }
        self.content = content;
        self.isNeedDateShow = NO;
        self.currentResendCount = 0;
        self.isDeleted = [topicDic objectForKey:kDeleted];
        self.topicEntityTitle = [topicDic objectForKey:kTitle];
//        self.msg_from   = [topicDic objectForKey:kFrom];
//        self.isSysMsg    = [@"system" isEqualToString:self.msg_from];
    }
    return self;
}

//@property (nonatomic,strong) NSString   *messageID;
//@property (nonatomic,strong) NSString   *topicEntityID;//组ID
//@property (nonatomic,strong) NSString   *messageType;
//@property (nonatomic) long              createTime;
//@property (nonatomic) enum ACMessageEnumType        messageEnumType;
//@property (nonatomic) CLLocationCoordinate2D        messageLocation;//消息带经纬度
//@property (nonatomic) enum ACMessageDirectionType   directionType;//发送还是接收
//@property (nonatomic) NSString          *sendUserID;
//@property (nonatomic) long              seq;
//@property (nonatomic) NSString          *content;
//@property (nonatomic) int               messageUploadState;
//@property (nonatomic) BOOL              isNeedDateShow;//

-(ACMessage *)copyWithZone:(NSZone *)zone
{
    ACMessage *msg = [[[self class] allocWithZone:zone] init];
    msg.messageID = [_messageID copy];
    msg.topicEntityID = [_topicEntityID copy];
    msg.messageType = [_messageType copy];
    msg.createTime = _createTime;
    msg.messageEnumType = _messageEnumType;
    msg.messageLocation = _messageLocation;
    msg.directionType = _directionType;
    msg.sendUserID = [_sendUserID copy];
    msg.seq = _seq;
    msg.content = [_content copy];
    msg.messageUploadState = _messageUploadState;
    msg.isNeedDateShow = _isNeedDateShow;
    return msg;
}

+(ACMessage *)getTransmitMsgWithMsg:(ACMessage *)msg withTopicEntityID:(NSString *)topicEntityID
{
    ACMessage *transmitMsg = [msg copy];
    transmitMsg.topicEntityID = topicEntityID;
    transmitMsg.createTime = [[NSDate date] timeIntervalSince1970]*1000;
    transmitMsg.messageID  =   [NSString stringWithFormat:@"%.0f",transmitMsg.createTime];
    transmitMsg.sendUserID = [ACUser myselfUserID];
    transmitMsg.messageUploadState = ACMessageUploadState_Transmiting;
    transmitMsg.seq = ACMessage_seq_DEF;
    transmitMsg.directionType = ACMessageDirectionType_Send;
//    ITLogEX(@"%@",transmitMsg.messageID);
    return transmitMsg;
}

+(NSString*)getTempMsgID{
    return [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]*1000];
}

-(NSString *)messageID{
    return _messageID?_messageID:@"";
}

-(BOOL)isTextEnumType{
    return  _messageEnumType == ACMessageEnumType_Text||
            _messageEnumType == ACMessageEnumType_Videocall||
            _messageEnumType == ACMessageEnumType_Audiocall||
            _messageEnumType == ACMessageEnumType_Unknow||
            _messageEnumType == ACMessageEnumType_ShareLocation;
}

-(BOOL)canTransmit{
    return !(ACMessageEnumType_Videocall==_messageEnumType||
             ACMessageEnumType_Audiocall==_messageEnumType||
             ACMessageEnumType_Unknow==_messageEnumType||
             ACMessageEnumType_ShareLocation==_messageEnumType);
}

-(NSString *)topicEntityID{
    return _topicEntityID?_topicEntityID:@"";
}

-(NSString *)messageType
{
    return _messageType?_messageType:@"";
}

-(NSString *)sendUserID
{
    return _sendUserID?_sendUserID:@"";
}

-(NSString *)content
{
    return _content?_content:@"";
}

-(void)setCreateTime:(double)createTime {
    _createTime =   createTime;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *cps1 = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[NSDate dateWithTimeIntervalSince1970:createTime/1000]];
    _createTimeForYYYYMMDD = cps1.year*10000L+cps1.month*100+cps1.day;
}

////比较自己跟参数message是否是同一天的消息
//-(BOOL)isSameDayWithMessage:(ACMessage *)message
//{
//    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
//    NSUInteger flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
//    NSDateComponents *cps1 = [calendar components:flags fromDate:[NSDate dateWithTimeIntervalSince1970:message.createTime/1000]];
//    NSDateComponents *cps2 = [calendar components:flags fromDate:[NSDate dateWithTimeIntervalSince1970:self.createTime/1000]];
//    if (cps1.year == cps2.year && cps1.month == cps2.month && cps1.day == cps2.day)
//    {
//        return YES;
//    }
//    else
//    {
//        return NO;
//    }
//}

-(NSComparisonResult)compare:(ACMessage *)message{
    if (_seq > message.seq){
        return (NSComparisonResult)NSOrderedDescending;
    }

    if (_seq < message.seq){
        return (NSComparisonResult)NSOrderedAscending;
    }

    return (NSComparisonResult)NSOrderedSame;
}


-(void)setContent:(NSString *)content
{
    if (![_content isEqualToString:content])
    {
        _content = content;
        switch (self.messageEnumType)
        {
//            case ACMessageEnumType_Text:
//            case ACMessageEnumType_System:
//            case ACMessageEnumType_ShareLocation:
//            case ACMessageEnumType_Videocall:
//            case ACMessageEnumType_Audiocall:
//            {
//            }
//                break;
            case ACMessageEnumType_Location:
            {
                ACLocationMessage *msg = (ACLocationMessage *)self;
                NSDictionary *contentDic = [content objectFromJSONString];
                NSString *latitude = [contentDic objectForKey:kLatitude];
                NSString *longitude = [contentDic objectForKey:kLongitude];
                if (latitude && longitude)
                {
                    msg.location = CLLocationCoordinate2DMake([latitude doubleValue], [longitude doubleValue]);
                }
            }
                break;
            case ACMessageEnumType_Sticker:
            {
                ACStickerMessage *msg = (ACStickerMessage *)self;
                NSDictionary *contentDic = [content objectFromJSONString];
                
                NSString *suitID = [contentDic objectForKey:kSuitID];
                NSString *rid = [contentDic objectForKey:kRid];
                NSString *stickerPath = [contentDic objectForKey:kPath];
                if (!stickerPath && suitID && rid)
                {
                    stickerPath = [ACStickerMessage getStickerPathWithSuitID:suitID withRid:rid];
                }
                
                if (stickerPath)
                {
                    msg.stickerPath = stickerPath;
                }
                
                NSString *stickerName = [contentDic objectForKey:kName];
                if (stickerName)
                {
                    msg.stickerName = stickerName;
                }
                
                int width = [[contentDic objectForKey:KWidth] intValue];
                if (width)
                {
                    msg.width = width;
                }
                
                int height = [[contentDic objectForKey:KHeight] intValue];
                if (height)
                {
                    msg.height = height;
                }
            }
                break;
            case ACMessageEnumType_Audio:
            case ACMessageEnumType_Image:
            case ACMessageEnumType_Video:
            case ACMessageEnumType_File:
            {
                ACFileMessage *msg = (ACFileMessage *)self;
                NSDictionary *contentDic = [content objectFromJSONString];
                
                NSNumber *duration = [contentDic objectForKey:kDuration];
                if (duration)
                {
                    msg.duration = [duration intValue];
                }
                
                NSNumber *length = [contentDic objectForKey:kLength];
                if (length)
                {
                    msg.length = [length longValue];
                }
                
                msg.name =  contentDic[kName];
                msg.resourceID =    contentDic[kRid];
                msg.thumbResourceID =   contentDic[kTrid];
                msg.smallSizeArray  =   contentDic[kSmall];
                msg.bigSizeArray    =   contentDic[kBig];
 
                
//                NSString *name = [contentDic objectForKey:kName];
//                if (name)
//                {
//                    msg.name = name;
//                }
                
//                NSString *resourceID = [contentDic objectForKey:kRid];
//                if (resourceID)//资源
//                {
//                    msg.resourceID = resourceID;
//                }
                
//                NSString *thumbResourceID = [contentDic objectForKey:kTrid];
//                if (thumbResourceID)//缩略图
//                {
//                    msg.thumbResourceID = thumbResourceID;
//                }
//                
//                NSArray *smallSizeArray = [contentDic objectForKey:kSmall];
//                if (smallSizeArray)//缩略图
//                {
//                    msg.smallSizeArray = smallSizeArray;
//                }
//                
//                NSArray *bigSizeArray = [contentDic objectForKey:kBig];
//                if (bigSizeArray)//缩略图
//                {
//                    msg.bigSizeArray = bigSizeArray;
//                }
                
                if(ACMessageEnumType_Image==self.messageEnumType){
                    msg.caption =   contentDic[kCaption];
                }
            }
                break;
            case ACMessageEnumType_WallBoard:
            {
                [(ACWallBoard_Message *)self setContentFromDict:[content objectFromJSONString]];
                
        /*WB
                NSDictionary *contentDic = [content objectFromJSONString];

                NSString *categoryID = [[contentDic objectForKey:kTopic] objectForKey:kCat];
                msg.categoryID = categoryID;
                
                NSArray *pageArray = [contentDic objectForKey:kPage];
                msg.multiArray = [NSMutableArray arrayWithCapacity:[pageArray count]];
                for (NSDictionary *dic in pageArray)
                {
                    NSString *type = [dic objectForKey:kType];
                    if ([type isEqualToString:kDescripation])
                    {
                        msg.desp = [dic objectForKey:kText];
                    }
                    else if ([type isEqualToString:kLocation])
                    {
                        msg.location = CLLocationCoordinate2DMake([[dic objectForKey:kLa] doubleValue], [[dic objectForKey:kLo] doubleValue]);
                        msg.address = [dic objectForKey:kAddress];
                    }
                    else if ([type isEqualToString:kImage] || [type isEqualToString:kVideo])
                    {
                        ACWallBoardFilePage *page = [[ACWallBoardFilePage alloc] init];
                        page.type = type;
                        NSString *src = [dic objectForKey:kSrc];
                        if ([src length] > 2)
                        {
                            page.resourceID = [src substringWithRange:NSMakeRange(1, [src length]-2)];
                        }
                        
                        NSString *thumb = [dic objectForKey:kThumb];
                        if ([thumb length] > 2)
                        {
                            page.thumbResourceID = [thumb substringWithRange:NSMakeRange(1, [thumb length]-2)];
                        }
                        NSNumber *height = [dic objectForKey:kHeight];
                        if (height)
                        {
                            page.height = [height floatValue];
                        }
                        
                        [msg.multiArray addObject:page];
                    }
                }*/
            }
                break;
            default:
                break;
        }
    }
}

-(void)updateWithDic:(NSDictionary *)dic
{
    NSString *sourceMsgID = _messageID;
    self.messageID = [dic objectForKey:kID];
    [ACMessageDB updateMessageIDWithSourceMessageID:sourceMsgID targetMsgID:_messageID];
    
    self.seq = [[dic objectForKey:kSeq] longValue];
    if ([dic objectForKey:kCreateTime])
    {
        self.createTime = [[dic objectForKey:kCreateTime] doubleValue];
    }
    else
    {
        self.createTime = [[dic objectForKey:kTime] doubleValue];
    }
    
    self.messageUploadState = ACMessageUploadState_Uploaded;
    
    NSString *content = [dic objectForKey:kContent];
    if (content)
    {
        self.content = [content JSONString];
    }
    
    [ACMessageEvent updateTopicEntity:nil LastInfoWithMessage:self hadRead:YES];
}

+(enum ACMessageEnumType)getMessageEnumTypeWithMessageType:(NSString *)type
{
    if ([type isEqualToString:ACMessageType_text])
    {
        return ACMessageEnumType_Text;
    }
    if ([type isEqualToString:ACMessageType_location])
    {
        return ACMessageEnumType_Location;
    }
    if ([type isEqualToString:ACMessageType_sticker])
    {
        return ACMessageEnumType_Sticker;
    }
    if ([type isEqualToString:ACMessageType_image])
    {
        return ACMessageEnumType_Image;
    }
    if ([type isEqualToString:ACMessageType_audio])
    {
        return ACMessageEnumType_Audio;
    }
    if ([type isEqualToString:ACMessageType_video])
    {
        return ACMessageEnumType_Video;
    }
    if ([type isEqualToString:ACMessageType_file])
    {
        return ACMessageEnumType_File;
    }
    if ([type isEqualToString:ACMessageType_wallBoard])
    {
        return ACMessageEnumType_WallBoard;
    }
    
    if([type isEqualToString:ACMessageType_system]){
        return ACMessageEnumType_System;
    }
    
    if([type isEqualToString:ACMessageType_videocall]){
        return ACMessageEnumType_Videocall;
    }

    if([type isEqualToString:ACMessageType_audiocall]){
        return ACMessageEnumType_Audiocall;
    }
    if([type isEqualToString:@"sharelocation"]){
        return ACMessageEnumType_ShareLocation;
    }
    
    
    return ACMessageEnumType_Unknow;
}

+(ACMessage *)createMessageWithMessageType:(NSString *)messageType topicEnitity:(ACTopicEntity *)topicEntity messageContent:(NSString *)content sendMsgID:(NSString *)msgID location:(CLLocation *)location
{
    enum ACMessageEnumType type = [ACMessage getMessageEnumTypeWithMessageType:messageType];
    //创建ACMessage对象
    __autoreleasing ACMessage *message = nil;
    NSMutableDictionary *contentDic = [NSMutableDictionary dictionary];
    switch (type)
    {
            
        case ACMessageEnumType_Text:
        case ACMessageEnumType_System:
        case ACMessageEnumType_Videocall:
        case ACMessageEnumType_Audiocall:
        {
            message = [[ACTextMessage alloc] init];
        }
            break;
        case ACMessageEnumType_Location:
        {
            message = [[ACLocationMessage alloc] init];
            [contentDic setObject:[NSNumber numberWithDouble:location.coordinate.latitude] forKey:kLatitude];
            [contentDic setObject:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:kLongitude];
        }
            break;
        case ACMessageEnumType_Audio:
        {
            message = [[ACFileMessage alloc] init];
            NSDictionary *dic = [content objectFromJSONString];
            for (NSString *key in [dic allKeys])
            {
                [contentDic setObject:[dic objectForKey:key] forKey:key];
            }
            [contentDic setObject:@"audio.wav" forKey:kName];
        }
            break;
        case ACMessageEnumType_Image:
        {
            message = [[ACFileMessage alloc] init];
            NSDictionary *dic = [content objectFromJSONString];
            for (NSString *key in [dic allKeys])
            {
                [contentDic setObject:[dic objectForKey:key] forKey:key];
            }
            [contentDic setObject:@"image.jpg" forKey:kName];
        }
            break;
        case ACMessageEnumType_Sticker:
        {
            message = [[ACStickerMessage alloc] init];
        }
            break;
        case ACMessageEnumType_Video:
        {
            message = [[ACFileMessage alloc] init];
            NSString *firstPath = [ACAddress getAddressWithFileName:msgID fileType:ACFile_Type_VideoFile isTemp:NO subDirName:nil];
            AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:firstPath] options:nil];
            int second = (int)(urlAsset.duration.value / urlAsset.duration.timescale);
            [contentDic setObject:[NSNumber numberWithInt:second] forKey:kDuration];
            
            NSDictionary *dic = [content objectFromJSONString];
            for (NSString *key in [dic allKeys])
            {
                [contentDic setObject:[dic objectForKey:key] forKey:key];
            }
            [contentDic setObject:@"video.mp4" forKey:kName];
        }
            break;
        case ACMessageEnumType_File:
        {
            message = [[ACFileMessage alloc] init];
        }
            break;
        case ACMessageEnumType_WallBoard:
        {
                message = [[ACWallBoard_Message alloc] init];
        }
            break;
        default:
            break;
    }
    
    message.topicEntityID = topicEntity.entityID;
    message.messageType = messageType;
    message.messageEnumType = [ACMessage getMessageEnumTypeWithMessageType:messageType];
    
    if (topicEntity.topicPerm.reportLocation == ACTopicPermission_ReportLocation_Allow &&
//        [[ACLBSCenter shareLBSCenter] userAllowLocation])
        [ACLBSCenter userAllowLocation])
    {
        message.messageLocation = [ACConfigs shareConfigs].location;
    }
    message.directionType = ACMessageDirectionType_Send;
    message.sendUserID = [ACUser myselfUserID];
    message.createTime = [[NSDate date] timeIntervalSince1970]*1000;

    message.messageID = msgID.length?msgID:[ACMessage getTempMsgID];//[NSString stringWithFormat:@"%.0f",message.createTime];
    if ([message isKindOfClass:[ACFileMessage class]])
    {
        ACFileMessage *msg = (ACFileMessage *)message;
        msg.resourceID = message.messageID;
        msg.thumbResourceID = [message.messageID stringByAppendingString:@"_s"];
        [contentDic setObject:msg.resourceID forKey:kRid];
        [contentDic setObject:msg.thumbResourceID forKey:kTrid];
    }
    if ([contentDic count] > 0)
    {
        content = [contentDic JSONString];
    }
    message.content = content;

    message.seq = ACMessage_seq_DEF;
//    
//    for(int i=0;i<100;i++){
//        long lTemp = MAXFLOAT;
//        NSLog(@"%ld %ld",lTemp,(long)MAXFLOAT);
//        lTemp;
//    }
    
//  ITLogEX(@"%ld %ld %ld",message.seq,ACMessage_seq_DEF,LONG_MAX);
    message.messageUploadState = ACMessageUploadState_Uploading;
    return message;
}

//用于创建时上传数据，这时content中还没有数据
-(NSMutableDictionary *)getDic
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:_topicEntityID,kTeid,_messageType,kType, nil];
    [dic setObject:_messageID forKey:@"cid"];
    if (_messageLocation.latitude && _messageLocation.longitude)
    {
        [dic setObject:[NSNumber numberWithDouble:_messageLocation.latitude] forKey:kLa];
        [dic setObject:[NSNumber numberWithDouble:_messageLocation.longitude] forKey:kLo];
    }
    return dic;
}

+(ACMessage *)messageWithDic:(NSDictionary *)dic
{
    __autoreleasing ACMessage *message = nil;
    NSString *type = [dic objectForKey:kContentType];
    enum ACMessageEnumType enumType = [self getMessageEnumTypeWithMessageType:type];
    switch (enumType)
    {
        case ACMessageEnumType_Text:
        case ACMessageEnumType_System:
        case ACMessageEnumType_ShareLocation:
        case ACMessageEnumType_Videocall:
        case ACMessageEnumType_Audiocall:
        {
            message = [[ACTextMessage alloc] initWithTopicDic:dic];
        }
            break;
        case ACMessageEnumType_Sticker:
        {
            message = [[ACStickerMessage alloc] initWithTopicDic:dic];
        }
            break;
        case ACMessageEnumType_Location:
        {
            message = [[ACLocationMessage alloc] initWithTopicDic:dic];
        }
            break;
        case ACMessageEnumType_Image:
        case ACMessageEnumType_Audio:
        case ACMessageEnumType_Video:
        case ACMessageEnumType_File:
        {
            message = [[ACFileMessage alloc] initWithTopicDic:dic];
        }
            break;
        default:
            break;
    }
    return message;
}

+(ACMessage *)getMessageWithFMResultSet:(FMResultSet *)resultSet
{
    enum ACMessageEnumType messageEnumType = [resultSet intForColumn:@"messageEnumType"];
    
    __autoreleasing ACMessage *message = nil;
    switch (messageEnumType)
    {
            
        case ACMessageEnumType_Text:
        case ACMessageEnumType_System:
        case ACMessageEnumType_ShareLocation:
        case ACMessageEnumType_Videocall:
        case ACMessageEnumType_Audiocall:
        {
            message = [[ACTextMessage alloc] init];
        }
            break;
        case ACMessageEnumType_Location:
        {
            message = [[ACLocationMessage alloc] init];
        }
            break;
        case ACMessageEnumType_Sticker:
        {
            message = [[ACStickerMessage alloc] init];
        }
            break;
        case ACMessageEnumType_Audio:
        case ACMessageEnumType_Image:
        case ACMessageEnumType_Video:
        case ACMessageEnumType_File:
        {
            message = [[ACFileMessage alloc] init];
        }
            break;
        case ACMessageEnumType_WallBoard:
        {
            message = [[ACWallBoard_Message alloc] init];
        }
            break;
        default:
        {
            message = [[ACMessage alloc] init];
        }
            break;
    }
    message.messageID = [resultSet stringForColumn:@"messageID"];
    message.topicEntityID = [resultSet stringForColumn:@"topicEntityID"];
    message.messageType = [resultSet stringForColumn:@"messageType"];
    message.createTime = [resultSet doubleForColumn:@"createTime"];
    message.messageEnumType = messageEnumType; //[resultSet intForColumn:@"messageEnumType"];
    message.messageLocation = CLLocationCoordinate2DMake([resultSet doubleForColumn:@"messageLatitude"], [resultSet doubleForColumn:@"messageLongitude"]);
    message.directionType = [resultSet intForColumn:@"directionType"];
    message.sendUserID = [resultSet stringForColumn:@"sendUserID"];
    message.seq = [resultSet longForColumn:@"seq"];
    message.content = [resultSet stringForColumn:@"content"];
    message.messageUploadState = [resultSet intForColumn:@"messageUploadState"];
//    message.msg_from    = [resultSet stringForColumn:@"msg_from"];
//    message.isSysMsg    = [@"system" isEqualToString:message.msg_from];
    return message;
}

@end

@implementation ACTextMessage

-(NSMutableDictionary *)getDic
{
    NSMutableDictionary *dic = [super getDic];
    [dic setObject:self.content forKey:kContent];
    return dic;
}

@end

@implementation ACLocationMessage

-(NSMutableDictionary *)getDic
{
    NSMutableDictionary *dic = [super getDic];
    NSDictionary *content = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:self.location.latitude],kLatitude,[NSNumber numberWithDouble:self.location.longitude],kLongitude, nil];
    [dic setObject:content forKey:kContent];
    return dic;
}

@end

@implementation ACStickerMessage

-(NSMutableDictionary *)getDic
{
    NSString *suitID = nil;
    NSString *rid = nil;
    NSArray *array = [self.stickerPath componentsSeparatedByString:@"/rest/apis/sticker/"];
    if ([array count] == 2)
    {
        NSString *string = [array objectAtIndex:1];
        array = [string componentsSeparatedByString:@"/image/"];
        if ([array count] == 2)
        {
            suitID = [array objectAtIndex:0];
            rid = [array objectAtIndex:1];
        }
    }
    
    NSMutableDictionary *dic = [super getDic];
    NSDictionary *content = [NSDictionary dictionaryWithObjectsAndKeys:self.stickerPath,kPath,self.stickerName,kName,[NSNumber numberWithInt:self.width],KWidth,[NSNumber numberWithInt:self.height],KHeight,suitID,kSuitID,rid,kRid, nil];
    [dic setObject:content forKey:kContent];
    [dic setObject:self.topicEntityID forKey:kTeid];
    [dic setObject:ACMessageType_sticker forKey:kType];
    
    return dic;
}

+(NSString *)getStickerPathWithSuitID:(NSString *)suitID withRid:(NSString *)rid
{
    return [NSString stringWithFormat:@"/rest/apis/sticker/%@/image/%@",suitID,rid];
}

@end

@implementation ACFileMessage


#ifdef ACUtility_Need_Log
//-(void)dealloc{
//    ITLog(@"");
//}
#endif

-(NSMutableDictionary *)getDic
{
    NSMutableDictionary *dic = [super getDic];
    NSMutableDictionary *contentDic = [NSMutableDictionary dictionaryWithDictionary:[self.content objectFromJSONString]];
    [contentDic setObject:[NSString stringWithFormat:@"{%@}",[contentDic objectForKey:kRid]] forKey:kRid];
    if (self.messageEnumType != ACMessageEnumType_Audio)
    {
        [contentDic setObject:[NSString stringWithFormat:@"{%@}",[contentDic objectForKey:kTrid]] forKey:kTrid];
        if(ACMessageEnumType_Image==self.messageEnumType&&
           _caption.length){
            [contentDic setObject:[NSString stringWithFormat:@"%@",_caption] forKey:kCaption];
        }
    }
    
    [dic setObject:contentDic forKey:kContent];
    return dic;
}

-(NSMutableDictionary *)getTransmitDic
{
    NSMutableDictionary *dic = [super getDic];
    NSMutableDictionary *contentDic = [NSMutableDictionary dictionaryWithDictionary:[self.content objectFromJSONString]];
    [contentDic setObject:[NSString stringWithFormat:@"%@",[contentDic objectForKey:kRid]] forKey:kRid];
    if (self.messageEnumType != ACMessageEnumType_Audio)
    {
        [contentDic setObject:[NSString stringWithFormat:@"%@",[contentDic objectForKey:kTrid]] forKey:kTrid];
        if(ACMessageEnumType_Image==self.messageEnumType&&
           _caption.length){
            [contentDic setObject:_caption forKey:kCaption];
        }
    }
    [dic setObject:contentDic forKey:kContent];
    return dic;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.progress = 0;
        self.isDownloading = NO;
        self.isPlaying = NO;
    }
    return self;
}

- (instancetype)initWithTopicDic:(NSDictionary *)topicDic
{
    self = [super initWithTopicDic:topicDic];
    if (self) {
        self.progress = 0;
        self.isDownloading = NO;
        self.isPlaying = NO;
    }
    return self;
}

-(void)setProgress:(float)progress
{
    _progress = progress;
    
}

@end


@implementation ACFileMessageCache

+(ACFileMessageCache *)getFileMessageCacheWithFMResultSet:(FMResultSet *)resultSet{

    ACFileMessageCache* message = [[ACFileMessageCache alloc] init];
    message.messageID = [resultSet stringForColumn:@"messageID"];
    message.messageEnumType = (enum ACMessageEnumType)[resultSet intForColumn:@"messageEnumType"];
    message.seq         = [resultSet longForColumn:@"seq"];
    message.length      =   [resultSet longForColumn:@"length"];
    message.resourceID  =    [resultSet stringForColumn:@"resourceID"];
//    message.thumbResourceID  =    [resultSet stringForColumn:@"thumbResourceID"]; //暂不使用
    return message;
}

+(ACFileMessageCache *)getFileMessageCacheWithDict:(NSDictionary *)pDict{
    ACFileMessageCache* message = [[ACFileMessageCache alloc] init];
    message.messageID = [pDict objectForKey:kID];
    message.messageEnumType = [ACMessage getMessageEnumTypeWithMessageType:[pDict objectForKey:kContentType]];
    message.seq         = [[pDict objectForKey:kSeq] longValue];
    [message updateContent:[pDict objectForKey:kContent]];
    return message;
}

+(ACFileMessageCache *)getFileMessageCacheWithFileMessage:(ACFileMessage*)fileMessage{
    ACFileMessageCache* pTemp = [[ACFileMessageCache alloc] init];
    pTemp.messageID = fileMessage.messageID;
    pTemp.seq = fileMessage.seq; //编号
    pTemp.messageEnumType = fileMessage.messageEnumType;     // ACMessageEnumType_Image, ACMessageEnumType_Video,
    pTemp.length = fileMessage.length;
    pTemp.resourceID = fileMessage.resourceID;
    pTemp.thumbResourceID = fileMessage.thumbResourceID;
    return pTemp;
}

-(void)updateContent:(NSDictionary*) pContent{
    _length      =[[pContent objectForKey:kLength] longValue];
    _resourceID  =    [pContent objectForKey:kRid];
    _thumbResourceID  =    [pContent objectForKey:kTrid];;
}

-(NSString *)getCachedFilePathNameWithTopicEntityID:(NSString *)topicEntityID forThumb:(BOOL)bForThumb{
    NSString *filePath = [ACAddress getAddressWithFileName:bForThumb?_thumbResourceID:_resourceID fileType:ACFile_Type_ImageFile isTemp:NO subDirName:nil];
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        return filePath;
    }
    NSString *urlStr = [self getURLWithTopicEntityID:topicEntityID forThumb:bForThumb];
    filePath = [[SDImageCache sharedImageCache] cachePathForKey:urlStr];
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        return filePath;
    }
    return nil;
}

-(NSString *)getURLWithTopicEntityID:(NSString *)topicEntityID forThumb:(BOOL)bForThumb{

    if(bForThumb){
        return [NSString stringWithFormat:@"%@/rest/apis/chat/%@/topic/%@/upload/%@",[[ACNetCenter shareNetCenter] acucomServer],topicEntityID,_messageID,_thumbResourceID];
    }

    return [ACNetCenter getdownloadURL:[[ACNetCenter shareNetCenter] getUrlWithEntityID:topicEntityID messageID:_messageID resourceID:_resourceID] withFileLength:_length];
    ;
}



@end
