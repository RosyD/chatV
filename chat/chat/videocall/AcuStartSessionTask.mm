//
//  AcuStartSessionTask.m
//  AcuConference
//
//  Created by aculearn on 13-7-29.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

/*
 zhiyuan mark: should start conference in main thread by : dispatch_get_main_queue() ??????
 */

#import "AcuStartSessionTask.h"
#import "ASIHTTPRequest.h"
#import "TouchXML.h"
#import "AcuGlobalParams.h"

@interface AcuStartSessionTask() <ASIHTTPRequestDelegate>

@end

@implementation AcuStartSessionTask
{
    NSString            *_sError;
    bool                _bResult;
}

@synthesize startSessionDelegate;

- (id)init
{
    self = [super init];
    if (self)
    {
        _sError = @"";
        _bResult = false;
        _session = nil;
        _bJoin = false;
    }
    return self;
}


- (void)startSession:(NSMutableDictionary*)sessionParams onServer:(NSString*)server
{
    //NSLog(@"start Session Params: %@", sessionParams);
    NSMutableString* req = [[NSMutableString alloc] initWithString:@"http://"];
    
    AcuGlobalParams *params = [AcuGlobalParams sharedInstance];
    if (params.ProtocolType == 1 || params.ProtocolType == 3)
    {
        [req setString:@"https://"];
    }
    
    [req appendString:server];
    [req appendString:@"/aculearn-idm/v7/ci/default.asp?"];
    
    bool bFirst = true;
    for (NSString* key in sessionParams)
    {
        if (bFirst)
        {
            bFirst = false;
            [req appendFormat:@"%@=%@", key, [sessionParams valueForKey:key]];
        }
        else
        {
            [req appendFormat:@"&%@=%@", key, [sessionParams valueForKey:key]];
        }
        
    }
    NSLog(@"request url = %@", req);
#if 0
    req = [[req stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] copy];
    
    NSURL *url = [NSURL URLWithString:req];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
	request = [ASIHTTPRequest requestWithURL:url];
    [request setValidatesSecureCertificate:NO];
    [request setDelegate:self];
    [request setDidFailSelector:@selector(ASIHttpRequestFailed:)];
    [request setDidFinishSelector:@selector(ASIHttpRequestSucceed:)];
    [request setDefaultResponseEncoding:NSUTF8StringEncoding];
    [request startAsynchronous];
#else
    ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:req]];
    //request.timeOutSeconds = 100;
    __weak ASIHTTPRequest *requestTmp = request;
    [request setCompletionBlock:^{
        NSString *response = [requestTmp responseString];
        //NSLog(@"Start Session response : %@", response);
        NSError *error = [NSError alloc];
        
        //first, load an XML document
        CXMLDocument *xmlDoc = [[CXMLDocument alloc] initWithXMLString:response options:0 error:&error];
        
        //get node
        CXMLNode *codeNode = [xmlDoc nodeForXPath:@"//AcuMsg/RetCode" error:&error];
        
        if (!codeNode)
        {
            _sError = NSLocalizedString(@"Failed to connect server.", @"StartSession Task RetCode Node");
            if (self.startSessionDelegate)
            {
                [self.startSessionDelegate acuStartSessionTask:self
                                                      onResult:false
                                                      withInfo:_sError];
            }
            return;
        }
        
        bool bOK = false;
        
        NSString *codeString = [codeNode stringValue];
        if (codeString)
        {
            if (_bJoin)
            {
                if ([codeString isEqualToString:@"1"])
                {
                    bOK = true;
                }
                else if ([codeString isEqualToString:@"2"])
                {
                    _sError = NSLocalizedString(@"Invalid conference room.", @"StartSession Task RetCode Value");
                    bOK = false;
                }
                else if ([codeString isEqualToString:@"3"])
                {
                    _sError = NSLocalizedString(@"This conference room has been disabled.", @"StartSession Task RetCode Value");
                    bOK = false;
                }
                else if ([codeString isEqualToString:@"4"])
                {
                    _sError = NSLocalizedString(@"This conference session is not in progress.", @"StartSession Task RetCode Value");
                    bOK = false;
                }
                else if ([codeString isEqualToString:@"5"])
                {
                    _sError = NSLocalizedString(@"User anthentication failed.", @"StartSession Task RetCode Value");
                    bOK = false;
                }
                else if ([codeString isEqualToString:@"6"])
                {
                    _sError = NSLocalizedString(@"Cannot use host account to join this conference session. ", @"StartSession Task RetCode Value");
                    bOK = false;
                }
                else if ([codeString isEqualToString:@"7"])
                {
                    _sError = NSLocalizedString(@"This account has been locked for another conference session.", @"StartSession Task RetCode Value");
                    bOK = false;
                }
                else if ([codeString isEqualToString:@"8"])
                {
                    _sError = NSLocalizedString(@"Invalid access code.", @"StartSession Task RetCode Value");
                    bOK = false;
                }
            }
            else
            {
                //not join
                if ([codeString isEqualToString:@"1"])
                {
                    bOK = true;
                }
                else if ([codeString isEqualToString:@"2"])
                {
                    _sError = NSLocalizedString(@"Invalid conference room.", @"StartSession Task RetCode Value");
                    bOK = false;
                }
                else if ([codeString isEqualToString:@"3"])
                {
                    _sError = NSLocalizedString(@"This account is not allowed to start conference.", @"StartSession Task RetCode Value");
                    bOK = false;
                }
                else if ([codeString isEqualToString:@"4"])
                {
                    _sError = NSLocalizedString(@"This account has been locked for another conference session.", @"StartSession Task RetCode Value");
                    bOK = false;
                }
            }
        }
        else
        {
            //no RetCode Value
        }
        
        if (!bOK)
        {
            if (self.startSessionDelegate)
            {
                [self.startSessionDelegate acuStartSessionTask:self
                                                      onResult:bOK
                                                      withInfo:_sError];
                return;
            }
        }
        
        if (codeString && [codeString isEqualToString:@"1"])
        {
            NSArray *records = nil;
            records = [xmlDoc nodesForXPath:@"//AcuMsg/Records/Record" error:nil];
            
            for (CXMLElement *record in records)
            {
                
                NSArray *nodes = [record children];
                
                for (CXMLNode *node in nodes)
                {
                    if ([[node name] isEqualToString:@"Title"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"ModuleName"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"ModuleType"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"Description"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"UserID"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"UserName"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"UserDisplayName"])
                    {
                        _session->HostDisplayName = [node stringValue];
                    }
                    else if ([[node name] isEqualToString:@"CompanyID"])
                    {
                        _session->HostCompany = [node stringValue];
                    }
                    else if ([[node name] isEqualToString:@"IsModerator"])
                    {
                        _session->IsModerator = [node stringValue];
                    }
                    else if ([[node name] isEqualToString:@"AMHost"])
                    {
                        _session->AcuManager = [node stringValue];
                    }
                    else if ([[node name] isEqualToString:@"GatewayPort"])
                    {
                        _session->Port = [node stringValue];
                    }
                    else if ([[node name] isEqualToString:@"StandAlone"])
                    {
                        _session->IsStandalone = [node stringValue];
                    }
                    else if ([[node name] isEqualToString:@"BasePath"])
                    {
                        _session->BasePath = [node stringValue];
                    }
                    else if ([[node name] isEqualToString:@"HasContent"])
                    {
                        _session->HasContent = [node stringValue];
                    }
                    else if ([[node name] isEqualToString:@"MaxUser"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"MaxSpeaker"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"MaxSpeed"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"VBRMode"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"ConfMode"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"ConfQuality"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"QualityPower"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"AVMode"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"StartMode"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"ClearTOC"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"AllowAllRecord"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"CallOut"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"CallYou"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"CallMe"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"HDMode"])
                    {
                        _session->HDMode = [node stringValue];
                    }
                    else if ([[node name] isEqualToString:@"AutoAccept"])
                    {
                        _session->AutoAccept = [node stringValue];
                    }
                    else if ([[node name] isEqualToString:@"AlreadyStarted"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if ([[node name] isEqualToString:@"AccessCode"])
                    {
                        [_session->room setValue:[node stringValue] forKey:[node name]];
                    }
                    else if([[node name] isEqualToString:@"Version"])
                    {
                        _session->_amVersion = [[node stringValue] intValue];
                    }
                }
            }
        }
        
        if (self.startSessionDelegate)
        {
            [self.startSessionDelegate acuStartSessionTask:self
                                                  onResult:bOK
                                                  withInfo:_sError];
        }
    }];
    [request setFailedBlock:^{
        _sError = NSLocalizedString(@"Failed to connect server.", @"StartSession Task failed");
        if (self.startSessionDelegate)
        {
            [self.startSessionDelegate acuStartSessionTask:self
                                                  onResult:false
                                                  withInfo:_sError];
        }
    }];
    [request startAsynchronous];
#endif
}

- (void)ASIHttpRequestFailed:(ASIHTTPRequest *)request
{
    _sError = NSLocalizedString(@"Failed to connect server.", @"StartSession Task failed");
    if (self.startSessionDelegate)
    {
        [self.startSessionDelegate acuStartSessionTask:self
                                              onResult:false
                                              withInfo:_sError];
    }
}

//
- (void)ASIHttpRequestSucceed:(ASIHTTPRequest *)request
{
    NSString *response = [request responseString];
    //NSLog(@"Start Session response : %@", response);
    NSError *error = [NSError alloc];
    
    //first, load an XML document
    CXMLDocument *xmlDoc = [[CXMLDocument alloc] initWithXMLString:response options:0 error:&error];
    
    //get node
    CXMLNode *codeNode = [xmlDoc nodeForXPath:@"//AcuMsg/RetCode" error:&error];
    
    if (!codeNode)
    {
        _sError = NSLocalizedString(@"Failed to connect server.", @"StartSession Task RetCode Node");
        if (self.startSessionDelegate)
        {
            [self.startSessionDelegate acuStartSessionTask:self
                                                  onResult:false
                                                  withInfo:_sError];
        }
        return;
    }
    
    bool bOK = false;

    NSString *codeString = [codeNode stringValue];
    if (codeString)
    {
        if (_bJoin)
        {
            if ([codeString isEqualToString:@"1"])
            {
                bOK = true;
            }
            else if ([codeString isEqualToString:@"2"])
            {
                _sError = NSLocalizedString(@"Invalid conference room.", @"StartSession Task RetCode Value");
                bOK = false;
            }
            else if ([codeString isEqualToString:@"3"])
            {
                _sError = NSLocalizedString(@"This conference room has been disabled.", @"StartSession Task RetCode Value");
                bOK = false;
            }
            else if ([codeString isEqualToString:@"4"])
            {
                _sError = NSLocalizedString(@"This conference session is not in progress.", @"StartSession Task RetCode Value");
                bOK = false;
            }
            else if ([codeString isEqualToString:@"5"])
            {
                _sError = NSLocalizedString(@"User anthentication failed.", @"StartSession Task RetCode Value");
                bOK = false;
            }
            else if ([codeString isEqualToString:@"6"])
            {
                _sError = NSLocalizedString(@"Cannot use host account to join this conference session. ", @"StartSession Task RetCode Value");
                bOK = false;
            }
            else if ([codeString isEqualToString:@"7"])
            {
                _sError = NSLocalizedString(@"This account has been locked for another conference session.", @"StartSession Task RetCode Value");
                bOK = false;
            }
            else if ([codeString isEqualToString:@"8"])
            {
                _sError = NSLocalizedString(@"Invalid access code.", @"StartSession Task RetCode Value");
                bOK = false;
            }
        }
        else
        {
            //not join
            if ([codeString isEqualToString:@"1"])
            {
                bOK = true;
            }
            else if ([codeString isEqualToString:@"2"])
            {
                _sError = NSLocalizedString(@"Invalid conference room.", @"StartSession Task RetCode Value");
                bOK = false;
            }
            else if ([codeString isEqualToString:@"3"])
            {
                _sError = NSLocalizedString(@"This account is not allowed to start conference.", @"StartSession Task RetCode Value");
                bOK = false;
            }
            else if ([codeString isEqualToString:@"4"])
            {
                _sError = NSLocalizedString(@"This account has been locked for another conference session.", @"StartSession Task RetCode Value");
                bOK = false;
            }
        }
    }
    else
    {
        //no RetCode Value
    }
    
    if (!bOK)
    {
        if (self.startSessionDelegate)
        {
            [self.startSessionDelegate acuStartSessionTask:self
                                                  onResult:bOK
                                                  withInfo:_sError];
        }
        return;
    }
    
    if (codeString && [codeString isEqualToString:@"1"])
    {
        NSArray *records = nil;
        records = [xmlDoc nodesForXPath:@"//AcuMsg/Records/Record" error:nil];
        
        for (CXMLElement *record in records)
        {
            
            NSArray *nodes = [record children];
            
            for (CXMLNode *node in nodes)
            {
                if ([[node name] isEqualToString:@"Title"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"ModuleName"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"ModuleType"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"Description"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"UserID"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"UserName"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"UserDisplayName"])
                {
                    _session->HostDisplayName = [node stringValue];
                }
                else if ([[node name] isEqualToString:@"CompanyID"])
                {
                    _session->HostCompany = [node stringValue];
                }
                else if ([[node name] isEqualToString:@"IsModerator"])
                {
                    _session->IsModerator = [node stringValue];
                }
                else if ([[node name] isEqualToString:@"AMHost"])
                {
                    _session->AcuManager = [node stringValue];
                }
                else if ([[node name] isEqualToString:@"GatewayPort"])
                {
                    _session->Port = [node stringValue];
                }
                else if ([[node name] isEqualToString:@"StandAlone"])
                {
                    _session->IsStandalone = [node stringValue];
                }
                else if ([[node name] isEqualToString:@"BasePath"])
                {
                    _session->BasePath = [node stringValue];
                }
                else if ([[node name] isEqualToString:@"HasContent"])
                {
                    _session->HasContent = [node stringValue];
                }
                else if ([[node name] isEqualToString:@"MaxUser"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"MaxSpeaker"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"MaxSpeed"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"VBRMode"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"ConfMode"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"ConfQuality"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"QualityPower"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"AVMode"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"StartMode"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"ClearTOC"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"AllowAllRecord"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"CallOut"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"CallYou"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"CallMe"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"HDMode"])
                {
                    _session->HDMode = [node stringValue];
                }
                else if ([[node name] isEqualToString:@"AutoAccept"])
                {
                    _session->AutoAccept = [node stringValue];
                }
                else if ([[node name] isEqualToString:@"AlreadyStarted"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if ([[node name] isEqualToString:@"AccessCode"])
                {
                    [_session->room setValue:[node stringValue] forKey:[node name]];
                }
                else if([[node name] isEqualToString:@"Version"])
                {
                    _session->_amVersion = [[node stringValue] intValue];
                }
            }
        }
    }
    
    if (self.startSessionDelegate)
    {
        [self.startSessionDelegate acuStartSessionTask:self
                                              onResult:bOK
                                              withInfo:_sError];
    }
    

}



@end
