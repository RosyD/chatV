//
//  ACNetCenterTcp.m
//  chat
//
//  Created by Aculearn on 15/11/27.
//  Copyright © 2015年 Aculearn. All rights reserved.
//

#import "ACNetCenter.h"
#import "ACNetCenter+loopInquire.h"
#import "NSStream+StreamsToHost.h"
#import "NSString+Additions.h"
#import "NSDate+Additions.h"
#import "ACTopicEntityEvent.h"
#import "ACMessageDB.h"
#import "ACEntity.h"
#import "ACMessage.h"
#import "ACAppDelegate.h"
#import "ACReadCountDB.h"
#import "ACReadSeqDB.h"
#import "ACDataCenter.h"
#import "NSString+Additions.h"


//#include "ACTCP_client_app.h"

enum ACTCP_STAT{
    ACTCP_STAT_CONNECTED    =   0,
    ACTCP_STAT_CONNECT_FAILED = -1,
    ACTCP_STAT_DISCONNECT = -2
};

//#define ACNetCenter_loopInquireTcpTick_Need //TCP需要心跳
#define ACNetCenter_loopInquireTcpOnly      //只使用TCP

#ifdef ACNetCenter_loopInquireTcpOnly
//    #define ACNetCenter_UseACTCP_client_app //使用ACTCP_client_app
//    #define ACNetCenter_UseGCDAsyncSocket   //使用GCDAsyncSocket
//    #define ACNetCenter_UseNSOutputStream   //使用 NSOutputStream
//    #define ACNetCenter_BSD_Socket //使用 BSD

    #define ACNetCenter_UseWebSocket
#endif

#define loopInquireTcpSocket_Data_Tag_Init  1   //初始化
#define loopInquireTcpSocket_Data_Tag_Sync  1   //同步
#define loopInquireTcpSocket_Data_Tag_Read  1   //读取服务器信息
#define loopInquireTcpSocket_Data_Tag_Tick  1   //心跳


static int  g_LoopInquire_ConnectCount = 0; //连接次数或心跳次数
static BOOL g_LoopInquire_SendingData = NO; //是否正在发送数据
static BOOL g_LoopInquire_IsCloseByUser = NO; //是否是主动关闭

#ifdef ACNetCenter_UseACTCP_client_app
    #define ACNetCenter_UseGCD_Timer
#elif defined(ACNetCenter_UseGCDAsyncSocket)
    static GCDAsyncSocket*    g_loopInquireTcpSocket = nil; //TCP套接口

#ifdef ACUtility_Need_Log
    #define ACNetCenter_UseGCDAsyncSocket_ECHO
#endif
    #define ACNetCenter_UseGCD_Timer
//    #define ACNetCenter_CheckTick_In_CheckRecvData  //需要在读数据中检查超时，主要针对没有定时发送Tick

    #ifdef  ACNetCenter_UseGCD_Timer
        #define GCDAsyncSocket_readDataWithTimeout -1L
    #else
        #define GCDAsyncSocket_readDataWithTimeout  _loopInquireTcpTickTimeS
    #endif
#elif defined(ACNetCenter_UseWebSocket)

    static  SRWebSocket*        g_loopInquireWebSocket = nil;

    #define ACNetCenter_UseGCD_Timer

#elif defined(ACNetCenter_UseNSOutputStream)
    static NSThread        *g_loopInquireThread = nil;
#elif defined(ACNetCenter_BSD_Socket)
    #define ACNetCenter_UseGCD_Timer
#endif

#ifdef ACNetCenter_UseGCD_Timer
    dispatch_source_t       g_loopInquireTcpGCDTimer = NULL;
#endif

#ifdef  ACNetCenter_UseGCDAsyncSocket_ECHO
    static GCDAsyncSocket*    g_tcpSocketECHO = nil;
#endif



@implementation ACNetCenter(loopInquire)


-(void)_loopInquireTcp_SendDict:(NSDictionary *)postDic{
//    ITLogEX(@"TCP Send:%@",postDic);
    //加密
    g_LoopInquire_SendingData = YES;
#ifdef ACNetCenter_UseWebSocket
    //自己发送，不加密
    [g_loopInquireWebSocket send:[postDic JSONString]];
    [g_loopInquireWebSocket sendString:[postDic JSONString] error:nil];
//     NSData *pSendData = [NSJSONSerialization dataWithJSONObject:postDic options:NSJSONWritingPrettyPrinted error:nil];
#else
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:postDic options:NSJSONWritingPrettyPrinted error:nil];
    NSData* pAES_Data = [jsonData AES256ParmEncryptWithKey:_loopInquireTcpPWD];
    //base64
    NSString* pBase64_Str = [pAES_Data base64EncodedStringWithOptions:0];
    //        ITLogEX(@"%@",pBase64_Str);
    NSMutableData* pSendData = [[NSMutableData alloc] initWithData:[pBase64_Str dataUsingEncoding:NSUTF8StringEncoding]];
    [pSendData appendData:_loopInquireTcpPkgEnd];
    //    [pSendData appendBytes:"\n" length:1];
    [self _loopInquireTcp_SendData:pSendData];
#endif
    
}

-(void)_loopInquireTcp_SendTick{
#ifdef ACNetCenter_UseGCD_Timer
    if(g_LoopInquire_ConnectCount)
#endif
    {
        [self _loopInquireTcp_SendDict:@{@"ping" : @(g_LoopInquire_ConnectCount)}];
#ifdef  ACNetCenter_UseGCDAsyncSocket_ECHO
        NSString* pInfo = [NSString stringWithFormat:@"echo %d",g_LoopInquire_ConnectCount];
        [g_tcpSocketECHO writeData:[pInfo dataUsingEncoding:NSUTF8StringEncoding] withTimeout:3 tag:0];
#endif
        
    }
    g_LoopInquire_ConnectCount ++;
}

-(void)_loopInquireTcp_SendTickForTimer{
    
#ifdef ACNetCenter_UseGCDAsyncSocket
    if(g_loopInquireTcpSocket.isConnected){
        [self _loopInquireTcp_SendTick];
    }
#elif defined(ACNetCenter_UseNSOutputStream)
    if(g_loopInquireWriteStream){
        [self _loopInquireTcp_SendTick];
    }
#else
    [self _loopInquireTcp_SendTick];
#endif
    
    //超时检查
    [self loopInquireCheckTCPConnect];
}

-(void)_loopInquireTcp_SendFirstData{
    _lastLoopInquireTI = [[NSDate date] timeIntervalSince1970];
    
#ifndef ACNetCenter_UseWebSocket
    //webSocket 不发送这个信息了，在URL中带着
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:5];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *aclSid = [defaults objectForKey:kAclSid];
    if ([aclSid length]>0){
        [dic setObject:aclSid forKey:@"s"];
    }
    
    NSString *aclDomain = [defaults objectForKey:kAclDomain];
    if ([aclDomain length]>0){
        [dic setObject:aclDomain forKey:@"d"];
    }
    
    NSString *userID = [defaults objectForKey:kUserID];
    if ([userID length]>0){
        [dic setObject:userID forKey:@"u"];
    }
    [dic setObject:@"ios" forKey:@"t"];
    [dic setObject:[ACConfigs shareConfigs].deviceToken forKey:@"k"];
    
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:kCFBundleVersion];
    [dic setObject:appVersion forKey:@"v"];
    
    [dic  setObject:[NSLocale preferredLanguages].firstObject forKey:@"locale"];


    [self _loopInquireTcp_SendDict:dic];
#endif
    
    
    //    NSDictionary *tokenDic = [NSDictionary dictionaryWithObject:[ACConfigs shareConfigs].deviceToken forKey:@"ios"];
    //    NSDictionary *postDic = [NSDictionary dictionaryWithObjectsAndKeys:[[ACDataCenter shareDataCenter] getDicArray],@"entities",tokenDic,@"token", nil];
    //
    //
    //    [self _loopInquireTcp_SendDict:postDic withTag:loopInquireTcpSocket_Data_Tag_Sync];
    
#ifdef ACNetCenter_UseGCD_Timer
    //    _loopInquireTcpTickTime = 20000;
    //    [_loopInquireTcpConnectTimer fire];
    if(NULL==g_loopInquireTcpGCDTimer){
        g_loopInquireTcpGCDTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,_loopInquireGCD);
        
        //_loopInquireTcpTickTime/1000.0
        dispatch_source_set_timer(g_loopInquireTcpGCDTimer,DISPATCH_TIME_NOW,(_loopInquireTcpTickTimeS)*NSEC_PER_SEC, 0); //执行
        
        dispatch_source_set_event_handler(g_loopInquireTcpGCDTimer, ^{
            [self _loopInquireTcp_SendTickForTimer];
         });
        dispatch_resume(g_loopInquireTcpGCDTimer);
    }
#endif
}


-(void)loopInquireTcp_closeWithDelayConnect:(BOOL)bDelayConnect withWhy:(NSString*)why{
    //关闭TCP套接口
    dispatch_async(_loopInquireGCD, ^{
        //    [_loopInquireTcpConnectTimer invalidate];
        ITLogEX(@"TCP Close:(%@) for %@",bDelayConnect?@"延时重连":@"直接关闭",why);
        
        //    if(bDelayConnect==0){
        //        NSLog(@"%@",[NSThread callStackSymbols]);
        //    }
    #ifdef ACNetCenter_UseGCD_Timer
        if(g_loopInquireTcpGCDTimer){
            dispatch_source_cancel(g_loopInquireTcpGCDTimer);
            //        dispatch_release(_loopInquireTcpConnectTimer);
            g_loopInquireTcpGCDTimer = NULL;
        }
    #endif
        [self _loopInquireTcp_Close];
        
        if(bDelayConnect){
            [self delayAfterLoopInquire];
        }
    });
}

-(void)_GCDLoopInquireTcp_CheckRecvDict:(NSDictionary*)responseDic{
    dispatch_async(_loopInquireGCD, ^{
        
#ifdef ACNetCenter_CheckTick_In_CheckRecvData
        NSTimeInterval oldTime = _lastLoopInquireTI;
#endif
        _lastLoopInquireTI = [[NSDate date] timeIntervalSince1970];
        self.bShowDisconnectStatInfo = YES;
        g_LoopInquire_SendingData = NO;
        
        
        //    ITLogEX(@"%f",_lastLoopInquireTI);
        
        //    if(loopInquireTcpSocket_Data_Tag_Tick==tag){
        //        //心跳不处理
        //        return;
        //    }
        /*
         #define loopInquireTcpSocket_Data_Tag_Init  1   //初始化
         #define loopInquireTcpSocket_Data_Tag_Sync  2   //同步
         #define loopInquireTcpSocket_Data_Tag_Read  3   //读取服务器信息
         #define loopInquireTcpSocket_Data_Tag_Tick  4   //心跳
         
         读取到得流都是连续的,不会乱
         */
        
        
//        ITLogEX(@"TCP轮询:%@",responseDic);
        
        int responseCode = [[responseDic objectForKey:kCode] intValue];
        if (responseCode == ResponseCodeType_Nomal){
            
            if([responseDic objectForKey:@"ping"]){
                _loopInquireUseTcpConnectRetryCount = 0;
            }
            else{
                NSDictionary* pTopic = responseDic[@"topic"];
                if(pTopic){
                    [self.chatCenter sendMsgFromTCP_Success:pTopic];
                }
                else{
                    id pTheEventCounter = [responseDic objectForKey:@"c"];
                    
                    if(pTheEventCounter){
                        _eventCounter = [pTheEventCounter longValue];
                    }
                    
                    [self doSyncData:responseDic needCheck:YES];
                    
                    if(LoopInquireState_synchronizing!=self.loopInquireState){
                        //第一步读取到得数据必须是synchronizing
                        self.loopInquireState = LoopInquireState_synchronized;
                        //关闭状态信息
                    }
                }
            }
            [self.chatCenter sendMsgFromTCP_CheckMsgNeedSend];
        }
        else{
            g_LoopInquire_IsCloseByUser = YES;
            if([self checkServerResponseCode:(enum ResponseCodeType)responseCode withResponseDic:responseDic]){
                //处理了错误,不再继续
                [self loopInquireTcp_closeWithDelayConnect:NO withWhy:([NSString stringWithFormat:@"TCP轮询:%d 错误,停止轮询!",(int)responseCode])];
                return;
            }
            
            if(1020==responseCode){
                //    code = 1202;
                // description = "Server disconnected";
                [self loopInquireTcp_closeWithDelayConnect:NO withWhy:@"TCP轮询:1202 Server disconnected!"];
                [self autoLoginDelay:3];
                return;
            }
            
            [self loopInquireTcp_closeWithDelayConnect:YES withWhy:@"轮询错误，重新连接"];
            return;
        }
        
        if(!g_LoopInquire_SendingData){
            /*没有发送数据
             当你write完数据后，
             [_socket writeData:header withTimeout:ABSOCKET_TIMEOUT tag:tagg];
             
             最好不要立即调用
             _socket readDataWithTimeout:-1.0 tag:tagg]
             
             而是在 回调函数里面调用：
             - (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tagg {
             [self listenSocketOfTag:tagg];
             }
             
             否则，你的
             - (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tagg {
             
             可能会有问题。
             
             */
#ifdef ACNetCenter_CheckTick_In_CheckRecvData
            if((_lastLoopInquireTI-oldTime)>_loopInquireTcpTickTimeS){
                [self _loopInquireTcp_SendTick];
            }
#endif
            
        }
        
    });

}

#pragma mark -
#pragma mark SendMsgFromTCP
//{
//    ACMessage *message = object;
//    NSString *sourceMessageID = message.messageID;
//    [message updateWithDic:responseDic];
//    [ACMessageDB saveMessageToDBWithMessage:message];
//    [_chatCenter sendMessage:message SuccessWithSourceMsgID:sourceMessageID];
//
//}

+(BOOL)sendMsgFromTCP_IsReady{
    return g_loopInquireWebSocket&&SR_OPEN==g_loopInquireWebSocket.readyState;
}

+(BOOL)sendMsgFromTCP:(ACMessage*)pMsg{
    if([self sendMsgFromTCP_IsReady]){
//        NSString* pString = [@{@"topic":[ACChatNetCenter getMsgSendDict:pMsg]} JSONString];
//        ITLogEX(@"%@",pString);
//        [g_loopInquireWebSocket send:pString];
        [g_loopInquireWebSocket send:[@{@"topic":[ACChatNetCenter getMsgSendDict:pMsg]} JSONString]];
        return YES;
    }
    return NO;
    return [g_loopInquireWebSocket sendString:[@{@"topic":[ACChatNetCenter getMsgSendDict:pMsg]} JSONString] error:nil];
}


#ifndef ACNetCenter_UseWebSocket
-(void)_GCDLoopInquireTcp_CheckRecvData:(NSData*)pData{
    
    _lastLoopInquireTI = [[NSDate date] timeIntervalSince1970];
    self.bShowDisconnectStatInfo = YES;
    g_LoopInquire_SendingData = NO;

    [_loopInquireTcpReadedData appendData:pData];
    
    //寻找结束符
    NSRange findEnd = [_loopInquireTcpReadedData rangeOfData:_loopInquireTcpPkgEnd
                                                     options:0
                                                       range:NSMakeRange(0, _loopInquireTcpReadedData.length)];
    
    if(NSNotFound!=findEnd.location){
        pData = [_loopInquireTcpReadedData subdataWithRange:NSMakeRange(0,findEnd.location)];
        NSRange remaindData = NSMakeRange(findEnd.location+findEnd.length, _loopInquireTcpReadedData.length-(findEnd.location+findEnd.length));
        if(remaindData.length>0){
            [_loopInquireTcpReadedData setData:[_loopInquireTcpReadedData subdataWithRange:remaindData]];
        }
        else{
            _loopInquireTcpReadedData.length = 0;
        }
        
        
        {
            NSString* pBase64String = [[NSString alloc] initWithData:pData encoding:NSUTF8StringEncoding];
            NSData* pAES_Data =  [[NSData alloc] initWithBase64EncodedString: pBase64String options:0];
            //解密
            pData = [pAES_Data AES256ParmDecryptWithKey: _loopInquireTcpPWD];
        }
        [self _GCDLoopInquireTcp_CheckRecvDict:[ACNetCenter getJOSNFromHttpData:pData]];
    }

}
#endif //ACNetCenter_UseWebSocket

#define GetLasetTopicEntityLimit    50
-(void)_Call_handleEventOperateWithEventDic:(NSDictionary*)responseDic forSync:(BOOL)bSync{
    NSArray *eventDicArray = [responseDic objectForKey:@"events"];
    NSMutableArray* pGetLasetTopicEntity = nil;
    NSMutableArray* pGetLasetTopicKeys = nil;
    if(bSync){
        pGetLasetTopicEntity = [[NSMutableArray alloc] initWithCapacity:eventDicArray.count];
        pGetLasetTopicKeys  = [[NSMutableArray alloc] initWithCapacity:eventDicArray.count];
    }
    
    //#ifdef ACUtility_Need_Log
    //    enum LoopInquireState old_stat = _loopInquireState;
    //#endif
    
    for (NSDictionary *eventDic in eventDicArray){
        @synchronized(self){
            ACTopicEntity* pRet = [ACEntityEvent handleEventOperateWithEventDic:eventDic forSync:bSync];
            if(pRet&&pGetLasetTopicEntity){
                //检查数据库
                NSMutableArray* pDBMsgSeqs = [ACMessageDB getMessageSeqsFromDBWithTopicEntityID:pRet.entityID
                                                                                        fromSeq:pRet.lastestSequence-GetLasetTopicEntityLimit];
                if(GetLasetTopicEntityLimit==pDBMsgSeqs.count&&
                   [@(pRet.lastestSequence) isEqualToNumber:pDBMsgSeqs.lastObject]){
                    //全部在数据库中了
                    continue;
                }
                
                int     nLimit  =   GetLasetTopicEntityLimit;
                long    lLoadSeq=   pRet.lastestSequence+1;
                if(pDBMsgSeqs.count){
                    //寻找是否有不连续的地方
                    long lPre =  (((NSNumber*) pDBMsgSeqs.firstObject).longValue);
                    if(1==lPre&&pDBMsgSeqs.count==pRet.lastestSequence){
                        //消息数量少，全部加载了
                        continue;
                    }
                    
                    if(1==lPre||(pRet.lastestSequence-GetLasetTopicEntityLimit+1)==lPre){
                        //数据在头部有效范围内，就是说数据不在中间
                        lPre ++; //用于比较
                        for(NSInteger n=1;n<pDBMsgSeqs.count;n++){
                            long lSeqTemp = ((NSNumber*) pDBMsgSeqs[n]).longValue;
                            if(lSeqTemp!=lPre){
                                break;
                            }
                            lPre =  lSeqTemp+1;
                        }
                        nLimit  =   (int)(lLoadSeq-lPre);
                        if(nLimit<=0){
                            continue;
                        }
                        nLimit ++; //多一个冗余
                    }
                }
                
                
                [pGetLasetTopicEntity addObject:@{kTeid:pRet.entityID,@"o":@(lLoadSeq),@"l":@(nLimit)}];
                [pGetLasetTopicKeys addObject:[NSString stringWithFormat:@"range_%ld_%d_%@",lLoadSeq,nLimit,pRet.entityID]];
            }
        }
    }
    
    if(bSync){
        if(pGetLasetTopicEntity.count){
            //取得改变了Topic的前50个数据
            NSString * const urlString = [NSString stringWithFormat:@"%@topics",REQUEST_TOPIC_MAPPING_ROOT];
            ITLogEX(@"Load more msg for %d topic beging",(int)pGetLasetTopicEntity.count);
            wself_define();
            [ACNetCenter callURL:urlString forPut:NO withPostData:@{@"range":pGetLasetTopicEntity} withBlock:^(ASIHTTPRequest *request, BOOL bIsFail) {
                if(!bIsFail){
                    NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
                    //                ITLogEX(@"%@",responseDic);
                    if(ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]){
#ifdef ACUtility_Need_Log
                        NSInteger nCount = 0;
#endif
                        for(NSString* pKey in pGetLasetTopicKeys){
                            NSArray *topicArray = responseDic[pKey];
#ifdef ACUtility_Need_Log
                            if(nil==topicArray){
                                ITLogEX(@"%@ No find Messages",pKey);
                            }
                            nCount +=   topicArray.count;
#endif
                            for (NSDictionary *dic in topicArray){
                                //保存
                                [ACMessageDB saveMessageToDBWithMessage:[ACMessage messageWithDic:dic]];
                            }
                        }
                        ITLogEX(@"Load more %d msg for %d topic",(int)nCount,(int)pGetLasetTopicEntity.count);
                    }
#ifdef ACUtility_Need_Log
                    else{
                        ITLogEX(@"Load more msg Fail %@",responseDic);
                    }
#endif
                } //if(!bIsFail)
                wself.loopInquireState = LoopInquireState_synchronized;
                self.loopInquireState = LoopInquireState_synchronized;
                [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterSyncFinishNotifation object:nil];
            }];
            return;
        }
        
        self.loopInquireState = LoopInquireState_synchronized;
        [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterSyncFinishNotifation object:nil];
    }
    
    //#ifdef ACUtility_Need_Log
    //    if(old_stat!=_loopInquireState){
    //        ITLogEX(@"loopInquireState Change = %d to %d",old_stat,_loopInquireState);
    //    }
    //#endif
    
    //    if(LoopInquireState_synchronized!=_loopInquireState||bSync){
    //        //状态改变或强制同步
    //        self.loopInquireState = LoopInquireState_synchronized;
    //        [[NSNotificationCenter defaultCenter] postNotificationName:kNetCenterSyncFinishNotifation object:nil];
    //    }
}

-(void)doSyncData:(NSDictionary*)responseDic needCheck:(BOOL)bCheck{
    
    
    BOOL bSync = !bCheck;
    
    //"noteTime" : 145345435454, //这个是新增的字段， 用于返回当前最新的note或comment的updatetime。
    
    NSNumber*       pNoteTime =   [responseDic objectForKey:@"noteTime"];
    NSNumber*       pNotifycation = [responseDic objectForKey:@"notification"];
    NSDictionary*   permDic = [responseDic objectForKey:@"perm"];
    
    if(pNotifycation){
        [ACConfigs notificationCfgSave:NotificationCfg_ON forSave:pNotifycation.boolValue];
    }
    
    if(pNoteTime||permDic){
        bSync = YES;
        if(pNoteTime){
            //                            long long llTime =   pNoteTime.longLongValue;
            //                            long lTime = pNoteTime.longValue;
            //                            NSLog(@"%d,%d",sizeof(long long),sizeof(long));
            [[ACConfigs shareConfigs] chageNoteLastTime:[pNoteTime longLongValue] andCurTime:-1L];
        }
    }
    
    [self _Call_handleEventOperateWithEventDic:responseDic forSync:bSync];
    
    //    NSArray *eventDicArray = [responseDic objectForKey:@"events"];
    //    for (NSDictionary *eventDic in eventDicArray)
    //    {
    //        @synchronized(self)
    //        {
    //            [ACEntityEvent handleEventOperateWithEventDic:eventDic forSync:bSync];
    //        }
    //    }
    
    if(bSync){
        
        if(permDic){
            NSNumber* pcanSearchInCR = [permDic objectForKey:@"scr"];
            [ACConfigs shareConfigs].canSearchInCR = 1==pcanSearchInCR.intValue;
        }
        
        
        /*    NSData *jsonData = [responseDic JSONData];
         NSString *saveAddress = [ACAddress getAddressWithFileName:fileNameID fileType:ACFile_Type_SyncData isTemp:NO subDirName:nil];
         BOOL success = [jsonData writeToFile:saveAddress atomically:YES];*/
        //        [ACConfigs shareConfigs].isSynced = YES;
        //        self.loginState = LoginState_synchronized;
        [[ACConfigs shareConfigs] updateApplicationUnreadCount];
    }
}

#if (!defined(ACNetCenter_UseGCDAsyncSocket))&&(!defined(ACNetCenter_UseWebSocket))
//处理从套接口读取的的BYTE
-(void)_loopInquireTcp_RecvMsg:(const char*)pMsg withLen:(int)nLen{
    @autoreleasepool {
        if(nLen<=0){
            if(ACTCP_STAT_CONNECTED==nLen){
                dispatch_async(_loopInquireGCD, ^{
                    [self _loopInquireTcp_SendFirstData];
                });
                return;
            }
            if(ACTCP_STAT_CONNECT_FAILED==nLen||ACTCP_STAT_DISCONNECT==nLen){
//                dispatch_async(_loopInquireGCD, ^{
                    [self loopInquireTcp_closeWithDelayConnect:!g_LoopInquire_IsCloseByUser
                                                       withWhy:ACTCP_STAT_CONNECT_FAILED==nLen?@"TCP轮询:连接失败":@"TCP轮询:连接断开"];
//                });
            }
            return;
        }
        [self _GCDLoopInquireTcp_CheckRecvData:[NSData dataWithBytes:pMsg length:nLen]];
    }
}
#endif //#ifndef ACNetCenter_UseGCDAsyncSocket


#ifdef ACNetCenter_UseACTCP_client_app
#pragma mark ACTCP_client_app
static  ACTCP_ClientApp*    g_pClientApp = NULL;


static void _loopInquireTcp_ACTCP_ClientApp_RecvMsg( int nLen,const char* pMsg){
    [[ACNetCenter shareNetCenter] _loopInquireTcp_RecvMsg:pMsg withLen:nLen];
}

-(void)_loopInquireTcp_ConnectToServer{
    [self _loopInquireTcp_Close];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        g_pClientApp = new  ACTCP_ClientApp(_loopInquireTcpServer.UTF8String,_loopInquireTcpServerPort);
//        g_pClientApp->SetCallback(_loopInquireTcp_ACTCP_ClientApp_RecvMsg);
//        g_pClientApp->Start();
//    });
    g_pClientApp = new  ACTCP_ClientApp(_loopInquireTcpServer.UTF8String,_loopInquireTcpServerPort);
    g_pClientApp->SetCallback(_loopInquireTcp_ACTCP_ClientApp_RecvMsg);
    g_pClientApp->Start();

    
//    while(YES){
//        sleep(1);
//    }
}

-(void)_loopInquireTcp_Close{
    if(g_pClientApp){
        g_pClientApp->Stop();
        delete g_pClientApp;
        g_pClientApp = NULL;
    }
}

-(void)_loopInquireTcp_SendData:(NSData*)pData{
    if(g_pClientApp){
        g_pClientApp->SendMsg((const uint8_t*)pData.bytes, (int)pData.length);
    }
}


#endif

#ifdef ACNetCenter_UseGCDAsyncSocket

#pragma mark GCDAsyncSocketDelegate


- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
#ifdef  ACNetCenter_UseGCDAsyncSocket_ECHO
    if(sock==g_tcpSocketECHO){
        return;
    }
#endif
    ITLogEX(@"TCP轮询:断开 %@",err);
    if(err!=nil&&!g_LoopInquire_IsCloseByUser){
        // 服务器掉线，重连
        [self delayAfterLoopInquire];
    }
}

-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    
#ifdef  ACNetCenter_UseGCDAsyncSocket_ECHO
    if(sock==g_tcpSocketECHO){
        return;
    }
#endif
    
#if 1
    ITLog(@"TCP轮询:连接成功");
    //    [sock readDataWithTimeout:_loopInquireTcpTickTimeS tag:loopInquireTcpSocket_Data_Tag_Read];
    //在这里调一次，以后全都不超时即可
//    [self _loopInquireTcp_SendTick];
    [self _loopInquireTcp_SendFirstData];
#else
    
    
    /*
     ITLog(@"TCP轮询:连接成功,开始设置TLS");
     // The root self-signed certificate I have created
     NSString *certificatePath = [[NSBundle mainBundle] pathForResource:@"trust" ofType:@"p12"];
     NSData *certData = [[NSData alloc] initWithContentsOfFile:certificatePath];
     SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
     
     // the "identity" certificate
     SecIdentityRef identityRef;
     SecTrustCreateWithCertificates(NULL, cert, &identityRef);
     
     // the certificates array, containing the identity then the root certificate
     NSArray *certs = [[NSArray alloc] initWithObjects:(__bridge id)(identityRef), cert, nil];
     
     // the SSL configuration
     NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:3];
     [settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
     [settings setObject:[NSNumber numberWithBool:NO] forKey:(NSString *)kCFStreamSSLValidatesCertificateChain];
     [settings setObject:certs forKey:(NSString *)kCFStreamSSLCertificates];
     
     [sock startTLS:settings];*/
    
    //TLS
    /*
     
     NSMutableDictionary *sslSettings = [[NSMutableDictionary alloc] init];
     NSData *pkcs12data = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"trust" ofType:@"p12"]];
     CFDataRef inPKCS12Data = (CFDataRef)CFBridgingRetain(pkcs12data);
     CFStringRef password = CFSTR("cAcule@rn");
     const void *keys[] = { kSecImportExportPassphrase };
     const void *values[] = { password };
     CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
     
     CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
     
     OSStatus securityError = SecPKCS12Import(inPKCS12Data, options, &items);
     CFRelease(options);
     CFRelease(password);
     
     if(securityError == errSecSuccess)
     NSLog(@"Success opening p12 certificate.");
     
     CFDictionaryRef identityDict = CFArrayGetValueAtIndex(items, 0);
     SecIdentityRef myIdent = (SecIdentityRef)CFDictionaryGetValue(identityDict,
     kSecImportItemIdentity);
     
     SecIdentityRef  certArray[1] = { myIdent };
     CFArrayRef myCerts = CFArrayCreate(NULL, (void *)certArray, 1, NULL);
     
     [sslSettings setObject:(id)CFBridgingRelease(myCerts) forKey:(NSString *)kCFStreamSSLCertificates];
     //    [sslSettings setObject:NSStreamSocketSecurityLevelNegotiatedSSL forKey:(NSString *)kCFStreamSSLLevel];
     //    [sslSettings setObject:(id)kCFBooleanTrue forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
     [sslSettings setObject:host forKey:(NSString *)kCFStreamSSLPeerName];
     [sock startTLS:sslSettings];
     */
    // Configure SSL/TLS settings
    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:3];
    
    // If you simply want to ensure that the remote host's certificate is valid,
    // then you can use an empty dictionary.
    
    // If you know the name of the remote host, then you should specify the name here.
    //
    // NOTE:
    // You should understand the security implications if you do not specify the peer name.
    // Please see the documentation for the startTLS method in GCDAsyncSocket.h for a full discussion.
    
    //    settings[(NSString*)kCFStreamSSLPeerName] =    host;
    //    [settings setObject:[NSNumber numberWithBool:YES] forKey:GCDAsyncSocketUseCFStreamForTLS];
    settings[GCDAsyncSocketManuallyEvaluateTrust] = @(YES);
    
    // To connect to a test server, with a self-signed certificate, use settings similar to this:
    
    // Allow expired certificates
    //	[settings setObject:[NSNumber numberWithBool:YES]
    //				 forKey:(NSString *)kCFStreamSSLAllowsExpiredCertificates];
    
    // Allow self-signed certificates
    //	[settings setObject:[NSNumber numberWithBool:YES]
    //				 forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
    
    // In fact, don't even validate the certificate chain
    //	[settings setObject:[NSNumber numberWithBool:NO]
    //				 forKey:(NSString *)kCFStreamSSLValidatesCertificateChain];
    
    
    
    
    
    [sock startTLS:settings];
    
    // You can also pass nil to the startTLS method, which is the same as passing an empty dictionary.
    // Again, you should understand the security implications of doing so.
    // Please see the documentation for the startTLS method in GCDAsyncSocket.h for a full discussion.
#endif
}

//- (void)socket:(GCDAsyncSocket *)sock didReceiveTrust:(SecTrustRef)trust
//completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler{
//    completionHandler(YES);
//}

//- (void)socketDidSecure:(GCDAsyncSocket *)sock{
//     ITLog(@"TCP轮询:TSL成功....!");
//    [self _loopInquireTcp_SendFirstData];
//}



-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
#ifdef  ACNetCenter_UseGCDAsyncSocket_ECHO
    if(sock==g_tcpSocketECHO){
        ITLogEX(@"ECHO:%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        if(sock.readingCount<3){
            [sock readDataWithTimeout:GCDAsyncSocket_readDataWithTimeout tag:0];
        }
        return;
    }
#endif

    [self _GCDLoopInquireTcp_CheckRecvData:data];
    if(sock.readingCount<3){
        [sock readDataWithTimeout:GCDAsyncSocket_readDataWithTimeout tag:loopInquireTcpSocket_Data_Tag_Read];
    }
}


-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    
#ifdef  ACNetCenter_UseGCDAsyncSocket_ECHO
    if(sock==g_tcpSocketECHO){
        if(sock.readingCount<3){
            [sock readDataWithTimeout:GCDAsyncSocket_readDataWithTimeout tag:0];
        }
        return;
    }
#endif
    
//不在这里处理，因为发送成功不一定服务器收到    _lastLoopInquireTI = [[NSDate date] timeIntervalSince1970];
    
    if(sock.readingCount<3){
        [sock readDataWithTimeout:GCDAsyncSocket_readDataWithTimeout tag:loopInquireTcpSocket_Data_Tag_Read];
    }
    //    ITLogEX(@"TCP轮询:ReadingCount=%ld",sock.readingCount);
}

#ifndef  ACNetCenter_UseGCD_Timer
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length{
#ifdef  ACNetCenter_UseGCDAsyncSocket_ECHO
    if(sock==g_tcpSocketECHO){
        return -1L;
    }
#endif
//    ITLogEX(@"TCP轮询:读超时 Readed(%d)",(int)length);
    [self _loopInquireTcp_SendTick];
    return _loopInquireTcpTickTimeS;
}
#endif


- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length{
#ifdef  ACNetCenter_UseGCDAsyncSocket_ECHO
    if(sock==g_tcpSocketECHO){
        return -1L;
    }
#endif
    [self loopInquireTcp_closeWithDelayConnect:YES withWhy:@"TCP轮询:写超时"];
    return -1L;
}

static dispatch_queue_t   g_GCDAsyncSocket_socketQueue = NULL;
//static dispatch_queue_t   g_GCDAsyncSocket_delegateQueue = NULL;

-(void)_loopInquireTcp_ConnectToServer{
    [self _loopInquireTcp_Close];
    
    if(nil==g_loopInquireTcpSocket){
        g_GCDAsyncSocket_socketQueue = dispatch_queue_create("Socket TCP Queue", nil);
//      g_GCDAsyncSocket_delegateQueue = dispatch_queue_create("Socket Delegate Queue", nil);
        g_loopInquireTcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self
                                                            delegateQueue:_loopInquireGCD
                                                              socketQueue:g_GCDAsyncSocket_socketQueue];
        
#ifdef  ACNetCenter_UseGCDAsyncSocket_ECHO
        g_tcpSocketECHO = [[GCDAsyncSocket alloc] initWithDelegate:self
                                                     delegateQueue:_loopInquireGCD
                                                       socketQueue:g_GCDAsyncSocket_socketQueue];
#endif
    }
    
    NSError *error = nil;
    [g_loopInquireTcpSocket connectToHost:_loopInquireTcpServer
                                   onPort:_loopInquireTcpServerPort //8090
                              withTimeout:3
                                    error:&error];
    
#ifdef  ACNetCenter_UseGCDAsyncSocket_ECHO
    [g_tcpSocketECHO connectToHost:@"acucom2.aculearn.com"
                                   onPort:28090
                              withTimeout:3
                                    error:&error];
#endif
    
#ifdef ACUtility_Need_Log
    if(error){
        ITLogEX(@"TCP轮询(%@:%ld):%@",_loopInquireTcpServer,_loopInquireTcpServerPort,error.localizedDescription);
    }
#endif
}

-(void)_loopInquireTcp_Close{
    [g_loopInquireTcpSocket disconnect];
#ifdef  ACNetCenter_UseGCDAsyncSocket_ECHO
    [g_tcpSocketECHO disconnect];
#endif
}

-(void)_loopInquireTcp_SendData:(NSData*)pData{
    [g_loopInquireTcpSocket writeData:pData withTimeout:2 tag:1];
}

#endif //ACNetCenter_UseGCDAsyncSocket

#ifdef ACNetCenter_UseWebSocket
#pragma mark SRWebSocketDelegate


- (void)webSocketDidOpen:(SRWebSocket *)webSocket{
    ITLog(@"TCP轮询:连接成功");
    [self _loopInquireTcp_SendFirstData];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    ITLogEX(@"%@,stat=%d",error.localizedDescription,(int)webSocket.readyState);
    //    [self _stopWithTip:nil];
    if(SR_CONNECTING==webSocket.readyState||
       (!g_LoopInquire_IsCloseByUser)){
        //再试试
        [self delayAfterLoopInquire];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(nullable NSString *)reason wasClean:(BOOL)wasClean{
    ITLogEX(@"TCP轮询:断开 [%d]%@",(int)code,reason);
    if(!g_LoopInquire_IsCloseByUser){
        // 服务器掉线，重连
        [self delayAfterLoopInquire];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    [self _GCDLoopInquireTcp_CheckRecvDict:[(NSString*)message objectFromJSONString]];
-(void)webSocket:(SRWebSocket *)webSocket didReceiveMessageWithString:(nonnull NSString *)string{
    [self _GCDLoopInquireTcp_CheckRecvDict:[string objectFromJSONString]];
}



-(void)_loopInquireTcp_ConnectToServer{

    if(g_loopInquireWebSocket){
        //关闭旧的
        [self _loopInquireTcp_Close];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *aclSid = [defaults objectForKey:kAclSid]; //s
    NSString *aclDomain = [defaults objectForKey:kAclDomain]; //d
    NSString *userID = [defaults objectForKey:kUserID]; //u
    if(nil==aclSid) aclSid = @"";
    if(nil==aclDomain) aclDomain = @"";
    if(nil==userID) userID = @"";
//    [dic setObject:@"ios" forKey:@"t"];
//    [dic setObject:[ACConfigs shareConfigs].deviceToken forKey:@"k"];
    
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:kCFBundleVersion]; //v
//    [dic  setObject:[NSLocale preferredLanguages].firstObject forKey:@"locale"];
    
    NSString* pURL = [NSString stringWithFormat:@"%@?d=%@&u=%@&s=%@&t=ios&k=%@&v=%@&locale=%@",_loopInquireTcpServer,[aclDomain URL_Encode],userID,aclSid,[[ACConfigs shareConfigs].deviceToken URL_Encode],[appVersion URL_Encode],[[NSLocale preferredLanguages].firstObject URL_Encode]]; //URL_Encode];
    
    g_loopInquireWebSocket =    [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:pURL]];
    g_loopInquireWebSocket.delegate =   self;
    [g_loopInquireWebSocket open];
}

-(void)_loopInquireTcp_Close{
    g_loopInquireWebSocket.delegate = nil;
    [g_loopInquireWebSocket close];
    g_loopInquireWebSocket = nil;
}

//-(void)_loopInquireTcp_SendData:(NSData*)pData{
//#ifdef ACUtility_Need_Log
//    NSError* pErr = nil;
//    ITLogEX(@"send %ld",pData.length);
//    if(![g_loopInquireWebSocket sendData:pData error:&pErr]){
//        ITLogEX(@"%@",pErr.localizedDescription);
//    }
//#else
//    [g_loopInquireWebSocket sendData:pData error:nil];
//#endif
//    
//}
#endif //ACNetCenter_UseWebSocket





#ifdef ACNetCenter_UseNSOutputStream

#pragma mark NSStreamDelegate
static NSInputStream  *g_loopInquireReadStream = nil;
static NSOutputStream  *g_loopInquireWriteStream = nil;
static NSMutableArray  *g_loopInquireTcpSendDatas = nil; //需要发送的数据
static NSData          *g_loopInquireTcpNowSendData = nil; //当前正在发送的数据
static NSInteger        g_loopInquireTcpNowSendedLen = 0; //已经发送的数据长度

-(void)_NSThread_loopInquireTcp{
    @autoreleasepool {
        NSInputStream * readStream = nil;
        NSOutputStream* writeStream = nil;
        
        [NSStream getStreamsToHostNamed:_loopInquireTcpServer
                                   port:(int)_loopInquireTcpServerPort
                            inputStream:&readStream
                           outputStream:&writeStream];
        
        if(readStream&&writeStream){
            [self _stream:readStream close:NO];
            [self _stream:writeStream close:NO];
            
            g_loopInquireWriteStream = writeStream;
            g_loopInquireReadStream = readStream;
            [self _loopInquireTcp_RecvMsg:NULL withLen:ACTCP_STAT_CONNECTED];
            
            NSRunLoop* curRunLoop = [NSRunLoop currentRunLoop];
            NSTimer *timer = [NSTimer timerWithTimeInterval:_loopInquireTcpTickTimeS target:self selector:@selector(_stream_Timer_Func) userInfo:nil repeats:YES];
            //使用NSRunLoopCommonModes模式，把timer加入到当前Run Loop中。
            [curRunLoop addTimer:timer forMode:NSRunLoopCommonModes];
            [curRunLoop run];
        }
        else{
            [self _loopInquireTcp_RecvMsg:NULL withLen:ACTCP_STAT_CONNECT_FAILED];
        }
    };
}

-(void)_stream:(NSStream *)stream close:(BOOL)bClose{
    if(stream){
        if(bClose){
            [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [stream close];
        }
        else{
            [stream setDelegate:self];
            [stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [stream open];
        }
    }
}

-(void)_stream_Timer_Func{
    [self _loopInquireTcp_SendTickForTimer];
}


-(void)_streamNSThread_ExitFunc{
    [self _stream:g_loopInquireReadStream close:YES];
    [self _stream:g_loopInquireWriteStream close:YES];
    [NSThread exit];
    g_loopInquireWriteStream = nil;
    g_loopInquireReadStream = nil;
    g_loopInquireThread = nil;
    g_loopInquireTcpNowSendData = nil;
    [g_loopInquireTcpSendDatas removeAllObjects];
}




-(void)_loopInquireTcp_ConnectToServer{
    [self _loopInquireTcp_Close];
    if(nil==g_loopInquireTcpSendDatas){
        g_loopInquireTcpSendDatas = [[NSMutableArray alloc] initWithCapacity:10];
    }
    g_loopInquireThread = [[NSThread alloc] initWithTarget:self
                                                  selector:@selector(_NSThread_loopInquireTcp)
                                                    object:nil];
    [g_loopInquireThread start];
}

-(void)_loopInquireTcp_Close{
    if(g_loopInquireThread){
        [self performSelector:@selector(_streamNSThread_ExitFunc)
                     onThread:g_loopInquireThread
                   withObject:nil waitUntilDone:NO];
        g_loopInquireThread = nil;
    }
}

-(void)_streamNSThread_SendData_Func:(NSData*)pData{
    [self stream:g_loopInquireWriteStream handleEvent:NSStreamEventHasSpaceAvailable];
}

-(void)_loopInquireTcp_SendData:(NSData*)pData{
    if(g_loopInquireThread){
        @synchronized(g_loopInquireTcpSendDatas) {
            [g_loopInquireTcpSendDatas addObject:pData];
//            if(pData.length==55){
//                for(int i=0;i<1000;i++){
//                    [g_loopInquireTcpSendDatas addObject:pData];
//                }
//                ITLogEX(@"%d",(int)g_loopInquireTcpSendDatas.count);
//            }
        }
        
        if(nil==g_loopInquireTcpNowSendData){
            [self performSelector:@selector(_streamNSThread_SendData_Func:)
                         onThread:g_loopInquireThread
                       withObject:pData
                    waitUntilDone:NO];
        }
    }
}

-(BOOL)_loopInquireWriteStream_WriteData{
    @synchronized(g_loopInquireTcpSendDatas) {
        if(nil==g_loopInquireTcpNowSendData){
            g_loopInquireTcpNowSendData = g_loopInquireTcpSendDatas.firstObject;
            if(nil==g_loopInquireTcpNowSendData){
                //没有数据可以发送
                return NO;
            }
            [g_loopInquireTcpSendDatas removeObjectAtIndex:0];
            g_loopInquireTcpNowSendedLen = 0;
            ITLogEX(@"NSStream write BEGIN(%d)",(int)g_loopInquireTcpNowSendData.length);
        }
    }
    
    const uint8_t* pByData =    (const uint8_t*)g_loopInquireTcpNowSendData.bytes;
    NSInteger nLen = [g_loopInquireWriteStream write:pByData+g_loopInquireTcpNowSendedLen
                                           maxLength:g_loopInquireTcpNowSendData.length-g_loopInquireTcpNowSendedLen];
    if(nLen<0){
        [self _loopInquireTcp_RecvMsg:NULL withLen:ACTCP_STAT_DISCONNECT];
        return NO;
    }
    
    @synchronized(g_loopInquireTcpSendDatas){

        g_loopInquireTcpNowSendedLen += nLen;
        
        if(g_loopInquireTcpNowSendedLen>=g_loopInquireTcpNowSendData.length){
            //发送完毕
            ITLogEX(@"NSStream write END(%d) %d",(int)g_loopInquireTcpNowSendedLen,g_loopInquireTcpSendDatas.count);
            g_loopInquireTcpNowSendData = nil;
            g_loopInquireTcpNowSendedLen = 0;
            return [self _loopInquireWriteStream_WriteData];
        }
    }
    
    return NO;
}

#define kBufferSize 10*1024
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    //    NSLog(@" >> NSStreamDelegate in Thread %@", [NSThread currentThread]);
    @autoreleasepool {
        switch (eventCode) {
            case NSStreamEventHasBytesAvailable: {
                
                uint8_t buf[kBufferSize];
                NSInteger numBytesRead = [(NSInputStream *)stream read:buf maxLength:kBufferSize];
                if(0==numBytesRead){
                    return;
                }
                if(numBytesRead<0){
                    numBytesRead = ACTCP_STAT_DISCONNECT;
                }
                
                [self _loopInquireTcp_RecvMsg:(const char*)buf withLen:(int)numBytesRead];
                break;
            }
                
            case NSStreamEventErrorOccurred: {
                ITLogEX(@"%@",[stream streamError].localizedDescription);
                [self _loopInquireTcp_RecvMsg:NULL withLen:ACTCP_STAT_DISCONNECT];
                break;
            }
            case NSStreamEventHasSpaceAvailable:{
                [self _loopInquireWriteStream_WriteData];
                break;
            }
                
//            case NSStreamEventEndEncountered: {
//                [self _stream:stream close:YES];
//                dispatch_async(_loopInquireGCD, ^{
//                    [self delayAfterLoopInquire];
//                });
//                break;
//            }
                
            default:
                break;
        }
    }
}
#endif //#ifdef ACNetCenter_UseNSOutputStream

#ifdef ACNetCenter_BSD_Socket
#pragma mark BSD_Socket

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
#import <netdb.h>

static NSThread *g_pBSD_Socket_Thread = nil;
static int      g_pBSD_Socket = 0;

-(BOOL)_BSD_Socket_connectServer_Func{
    
//    ITLog(@"TCP轮询: 开始连接....");
    int socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0);
    if (-1 == socketFileDescriptor) {
        ITLog(@"创建套接口失败");
        return NO;
    }
    
    // Get IP address from host
    //
    struct hostent * remoteHostEnt = gethostbyname([_loopInquireTcpServer UTF8String]);
    if (NULL == remoteHostEnt) {
        ITLogEX(@"%@域名解析失败",_loopInquireTcpServer);
        close(socketFileDescriptor);
        return NO;
    }
    
    struct in_addr * remoteInAddr = (struct in_addr *)remoteHostEnt->h_addr_list[0];
    
    // Set the socket parameters
    //
    struct sockaddr_in socketParameters;
    socketParameters.sin_family = AF_INET;
    socketParameters.sin_addr = *remoteInAddr;
    socketParameters.sin_port = htons(_loopInquireTcpServerPort);
    
    // Connect the socket
    //
    int ret = connect(socketFileDescriptor, (struct sockaddr *) &socketParameters, sizeof(socketParameters));
    if (-1 == ret) {
        ITLog(@"connect失败");
        close(socketFileDescriptor);
        return NO;
    }
    g_pBSD_Socket   =   socketFileDescriptor;
    return YES;
}

-(void)_BSD_Socket_Thread_Func{
    
    // Create socket
    //
    if(![self _BSD_Socket_connectServer_Func]){
        [self _loopInquireTcp_RecvMsg:NULL withLen:ACTCP_STAT_CONNECT_FAILED];
        return;
    }
    
    [self _loopInquireTcp_RecvMsg:NULL withLen:ACTCP_STAT_CONNECTED];
    
    // Continually receive data until we reach the end of the data
    //
    while (g_pBSD_Socket) {
        const char * buffer[1024];
        
        // Read a buffer's amount of data from the socket; the number of bytes read is returned
        //
        ssize_t result = recv(g_pBSD_Socket, &buffer, 1024, 0);
        if (result > 0) {
            [self _loopInquireTcp_RecvMsg:(const char*)buffer withLen:(int)result];
        }
        else {
            [self _loopInquireTcp_RecvMsg:NULL withLen:ACTCP_STAT_DISCONNECT];
            break;
        }
    }
    
    // Close the socket
    //
    @synchronized(g_pBSD_Socket_Thread) {
        if(g_pBSD_Socket){
            close(g_pBSD_Socket);
            g_pBSD_Socket = 0;
        }
    }
    [NSThread exit];
}



-(void)_BSD_Socket_Thread_WriteData:(NSData*)pData{
    const char* pcData = (const char*)pData.bytes;
    int nLen = (int)pData.length;
    
    while(nLen>0&&g_pBSD_Socket){
        ssize_t nSended = send(g_pBSD_Socket, pcData, nLen, 0);
        if(nSended<=0){
            [self _loopInquireTcp_RecvMsg:NULL withLen:ACTCP_STAT_DISCONNECT];
            return;
        }
        else{
            nLen    -=  nSended;
            pcData  +=  nSended;
        }
    }
}

-(void)_loopInquireTcp_ConnectToServer{
    [self _loopInquireTcp_Close];
    
    g_pBSD_Socket_Thread = [[NSThread alloc] initWithTarget:self
                                                  selector:@selector(_BSD_Socket_Thread_Func)
                                                    object:nil];

    [g_pBSD_Socket_Thread start];
}


-(void)_loopInquireTcp_Close{
    
    if(g_pBSD_Socket_Thread){
        @synchronized(g_pBSD_Socket_Thread) {
            if(g_pBSD_Socket){
                close(g_pBSD_Socket);
                g_pBSD_Socket = 0;
            }
            g_pBSD_Socket_Thread = nil;
        }
    }
}

-(void)_loopInquireTcp_SendData:(NSData*)pData{
    if(g_pBSD_Socket_Thread){
        [self _BSD_Socket_Thread_WriteData:pData];
//        [self performSelector:@selector(_BSD_Socket_Thread_WriteData:)
//                     onThread:g_pBSD_Socket_Thread
//                   withObject:pData
//                waitUntilDone:NO];
    }
}



#endif //ACNetCenter_BSD_Socket


#pragma mark LoopInquire
//同步数据
-(void)syncData
{
    //        [self GCDSyncData];
    self.loopInquireState = LoopInquireState_synchronizing;
    [ACReadSeqDB updateReadSeqDBToSeqMax];
    
    //        NSArray *entityDicArray = [[ACDataCenter shareDataCenter] getDicArray];
    NSDictionary *tokenDic = [NSDictionary dictionaryWithObject:[ACConfigs shareConfigs].deviceToken forKey:@"ios"];
    NSDictionary *postDic = [NSDictionary dictionaryWithObjectsAndKeys:[[ACDataCenter shareDataCenter] getDicArray],@"entities",tokenDic,@"token", nil];
    
#ifndef ACNetCenter_loopInquireTcpOnly
    if(_loopInquireUseTcp){
#endif
        [self _loopInquireTcp_SendDict:postDic];
        
#ifndef ACNetCenter_loopInquireTcpOnly
    }
    else{
        NSString *fileName = kSyncDataJsonName;
        NSString * const acSyncDataUrl = [NSString stringWithFormat:@"%@/%@",[[ACNetCenter shareNetCenter] acucomServer],@"rest/events"];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self startDownloadWithFileName:fileName
                                   fileType:ACFile_Type_SyncData urlString:acSyncDataUrl
                                saveAddress:nil
                                tempAddress:nil
                           progressDelegate:nil
                             postDictionary:postDic
                              postPathArray:nil
                                     object:nil
                              requestMethod:requestMethodType_Post];
            
        });
    }
#endif
}

//轮询
static  BOOL    g_GCDLoopInquireIsRuning = NO;

-(void)GCDLoopInquire
{
    dispatch_async(_loopInquireGCD, ^{
        //        __block BOOL isFail = NO;
        //            static NSString *cancelID = nil;
        
        @synchronized(self){
            if(!self.isForeground){
                ITLog(@"轮询:后台停止轮询");
                return;
            }
        }
        
        //
        //        if (_loginState == LoginState_notConnected)
        //        {
        //            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //                if (!isFail)
        //                {
        //                    self.loginState = LoginState_synchronized;
        //                }
        //            });
        //        }
        
        if(g_GCDLoopInquireIsRuning){
            ITLog(@"轮询:重复运行");
            return;
        }
        
        if (![ASIHTTPRequest isValidNetWork]){
            //网络不存在,则延迟检查
            ITLog(@"轮询:断网,延迟启动");
            [self delayAfterLoopInquire];
            return;
        }
        
        if(0==[ACConfigs shareConfigs].deviceToken.length){
            ITLog(@"轮询:等待deviceToken,延迟启动");
            _lastLoopInquireTI = [[NSDate date] timeIntervalSince1970];
            [ACAppDelegate registerForRemoteNotification];
            [self delayAfterLoopInquire];
            return;
        }
        
        if((LoginState_logined!=[ACConfigs shareConfigs].loginState)||
           nil==_acucomServer){
            ITLogEX(@"轮询:还没有登录,延迟启动 %@",self.isFromUILogin?@"":@"重新登录");
            //如果是自动连接再来
            [self autoLoginDelay:3];
            //            [self delayAfterLoopInquire];
            return;
        }
        
#ifndef ACNetCenter_loopInquireTcpOnly
        
        //    #if TARGET_IPHONE_SIMULATOR
        //        _loopInquireUseTcp = YES;
        //    #endif
        if(_loopInquireUseTcp)
#endif
            
        {
            if(_loopInquireUseTcpConnectRetryCount>3){
                //重试次数>5,则
                ITLog(@"TCP 连接失败次数太多，需要重新登录");
                _loopInquireUseTcpConnectRetryCount = 0;
                [self autoLoginDelay:3];
                return;
            }
            
            //连接服务器
#ifdef ACNetCenter_UseWebSocket
            ITLogEX(@"TCP轮询: 连接webSocket %@",_loopInquireTcpServer);
#else
            if(nil==_loopInquireTcpReadedData){
                _loopInquireTcpReadedData = [[NSMutableData alloc] init];
            }
            _loopInquireTcpReadedData.length = 0;
            ITLogEX(@"TCP轮询: 连接Host %@:%ld",_loopInquireTcpServer,_loopInquireTcpServerPort);
#endif
            
            g_LoopInquire_IsCloseByUser      = NO;
            g_LoopInquire_ConnectCount       = 0;
            _loopInquireUseTcpConnectRetryCount ++;
            self.loopInquireState            = LoopInquireState_Connecting;
            
            [self _loopInquireTcp_ConnectToServer];
            
            return;
        }
        
#ifndef ACNetCenter_loopInquireTcpOnly
        [self _LoopInquireHttpFunc];
#endif
        
    });
}

//轮询

-(void)loopInquire
{
    //    ITLog(([NSString stringWithFormat:@"%@",[NSThread callStackSymbols]]));
    //    if (_isForeground)
    /*    {
     dispatch_async(_loopInquireGCD, ^{
     [self GCDLoopInquire];
     });
     }*/
    _lastLoopInquireTI = [[NSDate date] timeIntervalSince1970];
    [self GCDLoopInquire];
}

//进入后台停止轮询
-(void)deleteLoopInquireForLoginUI:(BOOL)forLogInUI
{
    g_LoopInquire_IsCloseByUser =   YES;
    [self loopInquireTcp_closeWithDelayConnect:NO withWhy:@"关闭轮询,deleteLoopInquire"];
    if (LoginState_logined==[ACConfigs shareConfigs].loginState&&!forLogInUI)
    {
        //关闭loopInquire
        NSString * const acDeleteloopInquireUrl = [NSString stringWithFormat:@"%@/%@",[[ACNetCenter shareNetCenter] acucomServer],@"rest/events"];
        
#if 0
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:acDeleteloopInquireUrl]];
        [request setHTTPMethod:[[ACNetCenter shareNetCenter] getRequestMethodWithType:requestMethodType_Delete]];
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
#else
        ASIHTTPRequest* request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:acDeleteloopInquireUrl]];
        [request setRequestMethod:[self getRequestMethodWithType:requestMethodType_Delete]];
        //      [request setRequestHeaders:[self getRequestHeader]];
        //      [request setTimeOutSeconds:90];
        [request setValidatesSecureCertificate:NO];
        [request startSynchronous];
        NSData *data    = [request responseData];
#endif
        NSDictionary *dic = [data objectFromJSONData];
        if ([[dic objectForKey:kCode] intValue] == 1 && !_isLogoutDeleteLoop)
        {
            [ACNetCenter shareNetCenter].backgrounLoopInquireClose = YES;
        }
        ITLogEX(@"%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
    }
}


-(BOOL)loopInquireCheckTCPConnect{
    NSTimeInterval nNowTime = [[NSDate date] timeIntervalSince1970];
    if(_loopInquireTcpTickTimeS&&(nNowTime-_lastLoopInquireTI)>_loopInquireTcpTickTimeS*2){
        _loopInquireUseTcpConnectRetryCount = 0;
        [self loopInquireTcp_closeWithDelayConnect:YES withWhy:@"轮询检查超时，重新连接"];
        return NO;
    }
    
    return YES;
}



#ifndef ACNetCenter_loopInquireTcpOnly

-(void)_LoopInquireHttpFunc{


    #ifdef ACUtility_Need_Log
    time_t timeBegin = time(NULL);
    #endif
    g_GCDLoopInquireIsRuning   =   YES;
    ITLog(@"HTTP轮询:开始");


    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDic objectForKey:kCFBundleVersion];
    NSString *acloopInquireUrl = [NSString stringWithFormat:@"%@/%@?c=%ld&v=%@&n=%d",_acucomServer,@"rest/events",_eventCounter,appVersion,g_LoopInquire_ConnectCount++];

    //        static NSString * const acloopInquireUrl = [NSString stringWithFormat:@"%@/%@",[[ACNetCenter shareNetCenter] acucomServer],@"rest/events"];
    acloopInquireUrl = [acloopInquireUrl stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    int responseStatusCode = 0;

    #if 0
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:acloopInquireUrl] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:90];
        NSError *error = nil;
        [request setHTTPMethod:@"Get"];
        [request setAllHTTPHeaderFields:[self getRequestHeader]];
        //            [request setValue:@"Keep-Alive" forKey:@"connection"];

        NSHTTPURLResponse *response = nil;
        NSData *received = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        responseStatusCode = response.statusCode;
    #else
        ASIHTTPRequest* request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:acloopInquireUrl]];
        [request setRequestMethod:@"get"];
        [request setRequestHeaders:[self getRequestHeader]];
        [request setTimeOutSeconds:59]; //服务器会在60秒内保持通道，如果客户端超时断开，就会重建通道做同步操作。
        [request setValidatesSecureCertificate:NO];

        [request startSynchronous];

        NSError *error =    request.error;

        NSData *received = [request responseData];
        responseStatusCode = request.responseStatusCode;
    #endif

    //        if (![ACConfigs shareConfigs].isLogined)
    //        {
    //            return ;
    //        }

    g_GCDLoopInquireIsRuning   =   NO;
    ITLogEX(@"HTTP轮询:结束(耗时%ld秒)",time(NULL)-timeBegin);

    if([ACConfigs shareConfigs].loginState!=LoginState_logined){
        ITLog(@"HTTP轮询:正在登录或正在退出!");
        return;
    }

    if (HttpCodeType_Success==responseStatusCode)
    {
        
    }
    else if (HttpCodeType_ServerUpdate==responseStatusCode)
    {
        ITLog(@"HTTP轮询: ServerUpdate 自动登录!");
        [self autoLoginDelay:3];
        return ;
    }
    else
    {
        if(error){
            NSLog(@"%@ %@",acloopInquireUrl,error);
        }
        
        //            isFail = YES;
        [self delayAfterLoopInquire];
        return;
    }

    if (error){
        ITLog(error);
        [self delayAfterLoopInquire];
    }
    else
    {
        /*
         NSString *responseString = [[received objectFromJSONData] JSONString];
         responseString = [responseString stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
         responseString = [responseString stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
         NSDictionary *responseDic = [responseString objectFromJSONString];*/
        NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:received];
        
        ITLog(responseDic);
        int responseCode = [[responseDic objectForKey:kCode] intValue];
        if (responseCode == ResponseCodeType_Nomal){
            _eventCounter = [[responseDic objectForKey:@"c"] longValue];
        }
        else{
            
            if([self checkServerResponseCode:(enum ResponseCodeType)responseCode withResponseDic:responseDic]){
                //处理了错误,不再继续
                ITLog(([NSString stringWithFormat:@"HTTP轮询:%d 错误,停止轮询!",(int)responseCode]));
                return;
            }
            
            if(1020==responseCode){
                //    code = 1202;
                // description = "Server disconnected";
                ITLog(@"HTTP轮询:1202 Server disconnected!");
                return;
            }
            
            [self delayAfterLoopInquire];
        }
        
        _lastLoopInquireTI = [[NSDate date] timeIntervalSince1970];
        
        [self _Call_handleEventOperateWithEventDic:responseDic forSync:NO];
        
        //            NSArray *events = [responseDic objectForKey:@"events"];
        //            for (NSDictionary *eventDic in events)
        //            {
        //                @synchronized(self)
        //                {
        //                    [ACEntityEvent handleEventOperateWithEventDic:eventDic forSync:NO];
        //                }
        //            }
        
        [self GCDLoopInquire];
    }
}
#endif //#ifndef ACNetCenter_loopInquireTcpOnly


@end
