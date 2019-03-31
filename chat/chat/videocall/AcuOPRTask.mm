//
//  AcuOPRTask.m
//  AcuConference
//
//  Created by aculearn on 13-7-26.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import "AcuOPRTask.h"
#import "AcuOPRResult.h"
#import "ASIHTTPRequest.h"
#import "TouchXML.h"
#import "AcuStartSessionCancelParam.h"
#import "AcuGlobalParams.h"

@interface AcuOPRTask() <ASIHTTPRequestDelegate>

@end

@implementation AcuOPRTask
{
    NSString        *_oprServer;
    NSString        *_oprSession;
    NSString        *_sError;
    AcuOPRResult    *_oprResult;
    NSMutableArray  *_asServerList;
    //bool            *_serverChecked;
    NSTimer         *_timeoutTimer;
    BOOL            _isTimeout;
    BOOL            _gotServer;
    int             _serverID;
    NSLock          *_mutex;
    
    NSOperationQueue    *_operationQueue;
    NSUInteger          _oprServerIndex;
    
    AcuStartSessionCancelParam *_cancelParam;
}

@synthesize oprDelegate;

- (id)init
{
    self = [super init];
    if (self)
    {
        _oprServer = @"";
        _oprSession = @"";
        _sError = @"";
        _oprResult = nil;
        _asServerList = nil;
        //_serverChecked = nil;
        _timeoutTimer = nil;
        _isTimeout = NO;
        _gotServer = NO;
        _serverID = -1;
        _mutex = nil;
        _operationQueue = nil;
        _oprServerIndex = 0;
        _cancelParam = [AcuStartSessionCancelParam sharedInstance];
    }
    
    return self;
}

- (void)startOPR:(NSString*)server
      roomHostID:(NSString*)hostId
 roomHostCompany:(NSString*)hostCompany
   roomSessionID:(NSString*)sessionID
{
    _oprServer = server;
    _oprSession = sessionID;
    
    AcuGlobalParams *params = [AcuGlobalParams sharedInstance];
    
    {
        NSMutableString* req = [[NSMutableString alloc] initWithString:@"http://"];
        [req appendString:server];
        [req appendString:@"/aculearn-idm/v7/ci/default.asp?functionid=get_protocol_type"];
        
        req = [[req stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] copy];
        
        NSURL *url = [NSURL URLWithString:req];
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        [request setValidatesSecureCertificate:NO];
        [request startSynchronous];
        NSError *error = [request error];
        if (error)
        {
            req = [[NSMutableString alloc] initWithString:@"https://"];
            [req appendString:server];
            [req appendString:@"/aculearn-idm/v7/ci/default.asp?functionid=get_protocol_type"];
            
            req = [[req stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] copy];
            
            url = [NSURL URLWithString:req];
            request = [ASIHTTPRequest requestWithURL:url];
            [request setValidatesSecureCertificate:NO];
            [request startSynchronous];
            error = [request error];
            if (error)
            {
                return;
            }
        }
        
        NSString *response = [request responseString];
        
        //first, load an XML document
        CXMLDocument *xmlDoc = [[CXMLDocument alloc] initWithXMLString:response options:0 error:&error];
        
        //get node
        CXMLNode *codeNode = [xmlDoc nodeForXPath:@"//AcuMsg/RetCode" error:&error];
        
        //or get actual value of node
        params.ProtocolType = [[codeNode stringValue] intValue];
    }

    
    NSMutableString* req = [[NSMutableString alloc] initWithString:@"http://"];
    if (params.ProtocolType == 1 || params.ProtocolType == 3)
    {
        [req setString:@"https://"];
    }
    
    [req appendString:server];
    [req appendString:@"/aculearn-idm/v7/ci/default.asp?"];
    
    [req appendFormat:@"%@=%@", @"functionid", @"opr_conf_acucom"];
    [req appendFormat:@"&%@=%@", @"userid", hostId];
    [req appendFormat:@"&%@=%@", @"company", hostCompany];
    [req appendFormat:@"&%@=%@", @"modulename", sessionID];
    [req appendString:@"&from=ios"];
    
    //NSLog(@"---- opr_conf url ---- :\n%@", req);
    
    req = [[req stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] copy];
#if 0
    NSURL *url = [NSURL URLWithString:req];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
	request = [ASIHTTPRequest requestWithURL:url];
    [request setValidatesSecureCertificate:NO];
    [request setDelegate:self];
    [request setDidFailSelector:@selector(oprStartASIHttpRequestFailed:)];
    [request setDidFinishSelector:@selector(oprStartASIHttpRequestSucceed:)];
    [request setDefaultResponseEncoding:NSUTF8StringEncoding];
    [request startAsynchronous];
#else
    ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:req]];
    [request setValidatesSecureCertificate:NO];
    __weak ASIHTTPRequest *requestTmp = request;
    [request setCompletionBlock:^{
        NSString *response = [requestTmp responseString];
        //NSLog(@"---- opr_conf response ---- : \n%@", response);
        NSError *error = [NSError alloc];
        
        if (_cancelParam.sessionCanceled)
        {
            return;
        }
        
        //first, load an XML document
        CXMLDocument *xmlDoc = [[CXMLDocument alloc] initWithXMLString:response options:0 error:&error];
        
        //get node
        CXMLNode *codeNode = [xmlDoc nodeForXPath:@"//AcuMsg/RetCode" error:&error];
        
        if (!codeNode)
        {
            _sError = NSLocalizedString(@"Failed to connect server.", @"OPR Task with opr_conf RetCode Node");
            if (self.oprDelegate)
            {
                [self.oprDelegate acuOPRTask:self
                               withErrorInfo:_sError];
            }
            return;
        }
        
        bool bOK = false;
        NSString *codeString = [codeNode stringValue];
        
        if (codeString && [codeString isEqualToString:@"1"])
        {
            bOK = true;
            _oprResult = [[AcuOPRResult alloc] init];
            NSArray *records = nil;
            records = [xmlDoc nodesForXPath:@"//AcuMsg/Records/Record" error:nil];
            for (CXMLElement *record in records)
            {
                NSArray *nodes = [record children];
                
                for (CXMLNode *node in nodes)
                {
                    //NSLog(@"node name : %@", [node name]);
                    if ([[node name] isEqualToString:@"ModuleName"])
                    {
                        _oprResult->session = [node stringValue];
                    }
                    else if ([[node name] isEqualToString:@"SessionStatus"])
                    {
                        _oprResult->sessionStatus = [node stringValue];
                    }
                    else if ([[node name] isEqualToString:@"AMStatus"])
                    {
                        _oprResult->amStatus = [node stringValue];
                    }
                    else if ([[node name] isEqualToString:@"AM"])
                    {
                        NSArray *amNodes = nil;
                        amNodes = [xmlDoc nodesForXPath:@"//AcuMsg/Records/Record/AM" error:nil];
                        for (CXMLElement *amNode in amNodes)
                        {
                            NSArray *amInfoNodes = [amNode children];
                            for (CXMLNode *amInfoNode in amInfoNodes)
                            {
                                if ([[amInfoNode name] isEqualToString:@"IP"])
                                {
                                    _oprResult->am->iisIP = [amInfoNode stringValue];
                                }
                                else if ([[amInfoNode name] isEqualToString:@"GatewayIP"])
                                {
                                    _oprResult->am->gatewayIP = [amInfoNode stringValue];
                                }
                                else if ([[amInfoNode name] isEqualToString:@"AccessType"])
                                {
                                    _oprResult->am->type = [amInfoNode stringValue];
                                }
                                else if ([[amInfoNode name] isEqualToString:@"WaitTime"])
                                {
                                    _oprResult->am->waittime = [amInfoNode stringValue];
                                }
                                else if ([[amInfoNode name] isEqualToString:@"DelayTime"])
                                {
                                    _oprResult->am->delaytime = [amInfoNode stringValue];
                                }
                            }
                            
                        }
                        
                    }   //end AM List
                    else if([[node name] isEqualToString:@"MainAS"])
                    {
                        NSArray *mainASNodes = nil;
                        mainASNodes = [xmlDoc nodesForXPath:@"//AcuMsg/Records/Record/MainAS" error:nil];
                        for (CXMLElement *mainASNode in mainASNodes)
                        {
                            NSArray *mainASInfoNodes = [mainASNode children];
                            for (CXMLNode *mainASInfoNode in mainASInfoNodes)
                            {
                                if ([[mainASInfoNode name] isEqualToString:@"IP"])
                                {
                                    _oprResult->mainAS->iisIP = [mainASInfoNode stringValue];
                                }
                                else if ([[mainASInfoNode name] isEqualToString:@"GatewayIP"])
                                {
                                    _oprResult->mainAS->gatewayIP = [mainASInfoNode stringValue];
                                }
                                else if ([[mainASInfoNode name] isEqualToString:@"AccessType"])
                                {
                                    _oprResult->mainAS->type = [mainASInfoNode stringValue];
                                }
                                else if ([[mainASInfoNode name] isEqualToString:@"WaitTime"])
                                {
                                    _oprResult->mainAS->waittime = [mainASInfoNode stringValue];
                                }
                                else if ([[mainASInfoNode name] isEqualToString:@"DelayTime"])
                                {
                                    _oprResult->mainAS->delaytime = [mainASInfoNode stringValue];
                                }
                            }
                            
                        }
                    }   //end MainAS List
                    else if ([[node name] isEqualToString:@"ASs"])
                    {
                        NSArray *asList = nil;
                        asList= [xmlDoc nodesForXPath:@"//AcuMsg/Records/Record/ASs/AS" error:nil];
                        for (CXMLElement *asNode in asList)
                        {
                            AcuServerProperty *asProperty = [[AcuServerProperty alloc] init];
                            NSArray *asInfos = [asNode children];
                            for (CXMLNode *asInfo in asInfos)
                            {
                                if ([[asInfo name] isEqualToString:@"IP"])
                                {
                                    asProperty->iisIP = [asInfo stringValue];
                                }
                                else if ([[asInfo name] isEqualToString:@"GatewayIP"])
                                {
                                    asProperty->gatewayIP = [asInfo stringValue];
                                }
                                else if ([[asInfo name] isEqualToString:@"AccessType"])
                                {
                                    asProperty->type = [asInfo stringValue];
                                }
                                else if ([[asInfo name] isEqualToString:@"WaitTime"])
                                {
                                    asProperty->waittime = [asInfo stringValue];
                                }
                                else if ([[asInfo name] isEqualToString:@"DelayTime"])
                                {
                                    asProperty->delaytime = [asInfo stringValue];
                                }
                                else if ([[asInfo name] isEqualToString:@"Priority"])
                                {
                                    asProperty->priority = [asInfo stringValue];
                                }
                                
                            }
                            [_oprResult->asList addObject:asProperty];
                        }
                    }   //end ASs List
                }
            }
        }
        else
        {
            _sError = NSLocalizedString(@"Login failed.", @"OPR Task with opr_conf RetCode Value");
            bOK = false;
        }
        
#if 0
        if (bOK && [_oprResult->amStatus isEqualToString:@"1"])
        {
            AcuServerProperty *asProperty = [[AcuServerProperty alloc] init];
            asProperty->iisIP = _oprResult->am->iisIP;
            asProperty->gatewayIP = _oprResult->am->gatewayIP;
            asProperty->type = _oprResult->am->type;
            asProperty->waittime = _oprResult->am->waittime;
            asProperty->delaytime = _oprResult->am->delaytime;
            asProperty->priority = _oprResult->am->priority;
            [_oprResult->asList addObject:asProperty];
        }
#endif
        
        
        if (bOK)
        {
//            if (self.oprDelegate)
//            {
//                [self.oprDelegate acuOPRTask:self
//                                  reportInfo:NSLocalizedString(@"Looking for the best server...", @"OPR Task with opr_conf")];
//            }
            
        }
        else
        {
            if (self.oprDelegate)
            {
                [self.oprDelegate acuOPRTask:self
                               withErrorInfo:_sError];
            }
            return;
        }
        
        if (_cancelParam.sessionCanceled)
        {
            return;
        }
        
        
        _asServerList = [NSMutableArray new];
        for (AcuServerProperty *server in _oprResult->asList)
        {
            //NSLog(@"---- opr_conf return list ----: \n iis : %@\ngateway : %@", server->iisIP, server->gatewayIP);
            [_asServerList addObject:server];
        }
        
        
        if ([_asServerList count] <= 0)
        {
            _sError = NSLocalizedString(@"No server available.", @"OPR Task with opr_conf");
            if (self.oprDelegate)
            {
                [self.oprDelegate acuOPRTask:self
                               withErrorInfo:_sError];
            }
            return;
        }
        
        if (_cancelParam.sessionCanceled)
        {
            return;
        }
        
        _mutex = [NSLock new];
        _operationQueue = [NSOperationQueue new];
        _oprServerIndex = 0;
        //_serverChecked = new bool[[_asServerList count]];
        
        [self addOPRServerQueue];
        
        _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:15.0
                                                         target:self
                                                       selector:@selector(oprTimeout:)
                                                       userInfo:nil
                                                        repeats:NO];

    }];
    [request setFailedBlock:^{
        _sError = NSLocalizedString(@"Failed to communicate with server.", @"OPR Task with opr_conf failed");
        if (self.oprDelegate)
        {
            [self.oprDelegate acuOPRTask:self
                           withErrorInfo:_sError];
        }
    }];
    [request startAsynchronous];
#endif
}

- (void)oprStartASIHttpRequestFailed:(ASIHTTPRequest *)request
{
    _sError = NSLocalizedString(@"Failed to communicate with server.", @"OPR Task with opr_conf failed");
    if (self.oprDelegate)
    {
        [self.oprDelegate acuOPRTask:self
                       withErrorInfo:_sError];
    }
}

//
- (void)oprStartASIHttpRequestSucceed:(ASIHTTPRequest *)request
{
    NSString *response = [request responseString];
    //NSLog(@"---- opr_conf response ---- : \n%@", response);
    NSError *error = [NSError alloc];
    
    //first, load an XML document
    CXMLDocument *xmlDoc = [[CXMLDocument alloc] initWithXMLString:response options:0 error:&error];
    
    //get node
    CXMLNode *codeNode = [xmlDoc nodeForXPath:@"//AcuMsg/RetCode" error:&error];
    
    if (!codeNode)
    {
        _sError = NSLocalizedString(@"Failed to connect server.", @"OPR Task with opr_conf RetCode Node");
        if (self.oprDelegate)
        {
            [self.oprDelegate acuOPRTask:self
                           withErrorInfo:_sError];
        }
        return;
    }
    
    bool bOK = false;
    NSString *codeString = [codeNode stringValue];
    
    if (codeString && [codeString isEqualToString:@"1"])
    {
        bOK = true;
        _oprResult = [[AcuOPRResult alloc] init];
        NSArray *records = nil;
        records = [xmlDoc nodesForXPath:@"//AcuMsg/Records/Record" error:nil];
        for (CXMLElement *record in records)
        {   
            NSArray *nodes = [record children];
            
            for (CXMLNode *node in nodes)
            {
                //NSLog(@"node name : %@", [node name]);
                if ([[node name] isEqualToString:@"ModuleName"])
                {
                    _oprResult->session = [node stringValue];
                }
                else if ([[node name] isEqualToString:@"SessionStatus"])
                {
                    _oprResult->sessionStatus = [node stringValue];
                }
                else if ([[node name] isEqualToString:@"AMStatus"])
                {
                    _oprResult->amStatus = [node stringValue];
                }
                else if ([[node name] isEqualToString:@"AM"])
                {
                    NSArray *amNodes = nil;
                    amNodes = [xmlDoc nodesForXPath:@"//AcuMsg/Records/Record/AM" error:nil];
                    for (CXMLElement *amNode in amNodes)
                    {
                        NSArray *amInfoNodes = [amNode children];
                        for (CXMLNode *amInfoNode in amInfoNodes)
                        {
                            if ([[amInfoNode name] isEqualToString:@"IP"])
                            {
                                _oprResult->am->iisIP = [amInfoNode stringValue];
                            }
                            else if ([[amInfoNode name] isEqualToString:@"GatewayIP"])
                            {
                                _oprResult->am->gatewayIP = [amInfoNode stringValue];
                            }
                            else if ([[amInfoNode name] isEqualToString:@"AccessType"])
                            {
                                _oprResult->am->type = [amInfoNode stringValue];
                            }
                            else if ([[amInfoNode name] isEqualToString:@"WaitTime"])
                            {
                                _oprResult->am->waittime = [amInfoNode stringValue];
                            }
                            else if ([[amInfoNode name] isEqualToString:@"DelayTime"])
                            {
                                _oprResult->am->delaytime = [amInfoNode stringValue];
                            }
                        }
                        
                    }
                    
                }   //end AM List
                else if([[node name] isEqualToString:@"MainAS"])
                {
                    NSArray *mainASNodes = nil;
                    mainASNodes = [xmlDoc nodesForXPath:@"//AcuMsg/Records/Record/MainAS" error:nil];
                    for (CXMLElement *mainASNode in mainASNodes)
                    {
                        NSArray *mainASInfoNodes = [mainASNode children];
                        for (CXMLNode *mainASInfoNode in mainASInfoNodes)
                        {
                            if ([[mainASInfoNode name] isEqualToString:@"IP"])
                            {
                                _oprResult->mainAS->iisIP = [mainASInfoNode stringValue];
                            }
                            else if ([[mainASInfoNode name] isEqualToString:@"GatewayIP"])
                            {
                                _oprResult->mainAS->gatewayIP = [mainASInfoNode stringValue];
                            }
                            else if ([[mainASInfoNode name] isEqualToString:@"AccessType"])
                            {
                                _oprResult->mainAS->type = [mainASInfoNode stringValue];
                            }
                            else if ([[mainASInfoNode name] isEqualToString:@"WaitTime"])
                            {
                                _oprResult->mainAS->waittime = [mainASInfoNode stringValue];
                            }
                            else if ([[mainASInfoNode name] isEqualToString:@"DelayTime"])
                            {
                                _oprResult->mainAS->delaytime = [mainASInfoNode stringValue];
                            }
                        }
                        
                    }
                }   //end MainAS List
                else if ([[node name] isEqualToString:@"ASs"])
                {
                    NSArray *asList = nil;
                    asList= [xmlDoc nodesForXPath:@"//AcuMsg/Records/Record/ASs/AS" error:nil];
                    for (CXMLElement *asNode in asList)
                    {
                        AcuServerProperty *asProperty = [[AcuServerProperty alloc] init];
                        NSArray *asInfos = [asNode children];
                        for (CXMLNode *asInfo in asInfos)
                        {
                            if ([[asInfo name] isEqualToString:@"IP"])
                            {
                                asProperty->iisIP = [asInfo stringValue];
                            }
                            else if ([[asInfo name] isEqualToString:@"GatewayIP"])
                            {
                                asProperty->gatewayIP = [asInfo stringValue];
                            }
                            else if ([[asInfo name] isEqualToString:@"AccessType"])
                            {
                                asProperty->type = [asInfo stringValue];
                            }
                            else if ([[asInfo name] isEqualToString:@"WaitTime"])
                            {
                                asProperty->waittime = [asInfo stringValue];
                            }
                            else if ([[asInfo name] isEqualToString:@"DelayTime"])
                            {
                                asProperty->delaytime = [asInfo stringValue];
                            }
                            else if ([[asInfo name] isEqualToString:@"Priority"])
                            {
                                asProperty->priority = [asInfo stringValue];
                            }
                            
                        }
                        [_oprResult->asList addObject:asProperty];
                    }
                }   //end ASs List
            }
        }
    }
    else
    {
        _sError = NSLocalizedString(@"Login failed.", @"OPR Task with opr_conf RetCode Value");
        bOK = false;
    }
	
#if 0
	if (bOK && [_oprResult->amStatus isEqualToString:@"1"])
	{
		AcuServerProperty *asProperty = [[AcuServerProperty alloc] init];
		asProperty->iisIP = _oprResult->am->iisIP;
		asProperty->gatewayIP = _oprResult->am->gatewayIP;
		asProperty->type = _oprResult->am->type;
		asProperty->waittime = _oprResult->am->waittime;
		asProperty->delaytime = _oprResult->am->delaytime;
		asProperty->priority = _oprResult->am->priority;
		[_oprResult->asList addObject:asProperty];
	}
#endif
    

    if (bOK)
    {
//        if (self.oprDelegate)
//        {
//            [self.oprDelegate acuOPRTask:self
//                              reportInfo:NSLocalizedString(@"Looking for the best server...", @"OPR Task with opr_conf")];
//        }
    
    }
    else
    {
        if (self.oprDelegate)
        {
            [self.oprDelegate acuOPRTask:self
                           withErrorInfo:_sError];
        }
        return;
    }
    

    _asServerList = [NSMutableArray new];
    for (AcuServerProperty *server in _oprResult->asList)
    {
		//NSLog(@"---- opr_conf return list ----: \n iis : %@\ngateway : %@", server->iisIP, server->gatewayIP);
        [_asServerList addObject:server];
    }
    
    
    if ([_asServerList count] <= 0)
    {
        _sError = NSLocalizedString(@"No server available.", @"OPR Task with opr_conf");
        if (self.oprDelegate)
        {
            [self.oprDelegate acuOPRTask:self
                           withErrorInfo:_sError];
        }
        return;
    }
    
    _mutex = [NSLock new];
    _operationQueue = [NSOperationQueue new];
    _oprServerIndex = 0;
    //_serverChecked = new bool[[_asServerList count]];
    
    [self addOPRServerQueue];
    
    _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:15.0
                                                     target:self
                                                   selector:@selector(oprTimeout:)
                                                   userInfo:nil
                                                    repeats:NO];
    
}

- (void)addOPRServerQueue
{
    [_operationQueue cancelAllOperations];
    
    size_t indexOfServer = 0;
    NSUInteger asCount = [_asServerList count];
    for (; _oprServerIndex < asCount; )
    {
        AcuServerProperty *server = [_asServerList objectAtIndex:_oprServerIndex];
        
        NSMutableDictionary *oprParam = [NSMutableDictionary new];
        [oprParam setValue:[NSNumber numberWithUnsignedLong:_oprServerIndex] forKey:@"Index"];
        [oprParam setValue:server->iisIP forKey:@"IP"];
        [oprParam setValue:server->type forKey:@"Type"];
        [oprParam setValue:server->waittime forKey:@"WaitTime"];
        [oprParam setValue:server->delaytime forKey:@"DelayTime"];
        _oprServerIndex++;
        NSInvocationOperation *oprOperation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                                   selector:@selector(oprRun:)
                                                                                     object:oprParam];
        
        [_operationQueue addOperation:oprOperation];
        
        indexOfServer ++;
        if (indexOfServer >= 3)
        {
            break;
        }
    }
}

- (void)oprRun:(id)oprParams
{
    NSMutableDictionary *params = (NSMutableDictionary*)oprParams;
    NSNumber *index = [params valueForKey:@"Index"];
    NSString *iisIP = [params valueForKey:@"IP"];
    NSString *serverType = [params valueForKey:@"Type"];
    NSString *waitTime = [params valueForKey:@"WaitTime"];
    NSString *delayTime = [params valueForKey:@"DelayTime"];
    
    //NSLog(@"---- opr on server:%@", iisIP);
    
    int delay = [delayTime intValue];
    if (delay > 0)
    {
        [NSThread sleepForTimeInterval:delay/1000.0];
    }
    
    [self checkServer:iisIP type:serverType waitTime:waitTime indexOf:index];
    
}

- (void)checkServer:(NSString*)server
               type:(NSString*)serverType
           waitTime:(NSString*)waitTime
            indexOf:(NSNumber*)index
{
    AcuGlobalParams *params = [AcuGlobalParams sharedInstance];
    
    NSMutableString* req = [[NSMutableString alloc] initWithString:@"http://"];
    
    if (params.ProtocolType == 1 || params.ProtocolType == 3)
    {
        [req setString:@"https://"];
    }
    
    [req appendString:server];
    if ([serverType isEqualToString:@"am"])
    {
        [req appendString:@"/aculearn-idm/v7/ci/default.asp?"];
    }
    else
    {
        [req appendString:@"/aculearn-me/v7/ci/default.asp?"];
    }
    
    [req appendFormat:@"%@=%@", @"functionid", @"opr_conf_image"];
    [req appendFormat:@"&%@=%@", @"waittime", waitTime];
    [req appendFormat:@"&%@=%d", @"id", [index intValue]];
    
    //NSLog(@"----opr_conf_image url ---- : \n%@", req);
    
    req = [[req stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] copy];
#if 0
    NSURL *url = [NSURL URLWithString:req];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
	request = [ASIHTTPRequest requestWithURL:url];
    [request setValidatesSecureCertificate:NO];
    [request setDelegate:self];
    [request setDidFailSelector:@selector(oprCheckServerASIHttpRequestFailed:)];
    [request setDidFinishSelector:@selector(oprCheckServerASIHttpRequestSucceed:)];
    [request setDefaultResponseEncoding:NSUTF8StringEncoding];
    [request startAsynchronous];
#else
    ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:req]];
    [request setValidatesSecureCertificate:NO];
    __weak ASIHTTPRequest *requestTmp = request;
    [request setCompletionBlock:^{
        
        if (_cancelParam.sessionCanceled)
        {
            [_operationQueue cancelAllOperations];
            [_operationQueue waitUntilAllOperationsAreFinished];
            return;
        }
        
        
        [_mutex lock];
        
        if (_gotServer)
        {
            [_mutex unlock];
            return;
        }
        
        NSString *response = [requestTmp responseString];
        //NSLog(@"---- opr_conf_image response ---- : \n%@", response);
        NSError *error = [NSError alloc];
        
        //first, load an XML document
        CXMLDocument *xmlDoc = [[CXMLDocument alloc] initWithXMLString:response options:0 error:&error];
        
        //get node
        CXMLNode *codeNode = [xmlDoc nodeForXPath:@"//AcuMsg/RetCode" error:&error];
        
        if (!codeNode)
        {
            [_mutex unlock];
            return;
        }
        
        bool bOK = false;
        NSString *codeString = [codeNode stringValue];
        
        if (codeString)
        {
            if ([codeString isEqualToString:@"1"])
            {
                //_oprResult = [[AcuOPRResult alloc] init];
                NSArray *records = nil;
                records = [xmlDoc nodesForXPath:@"//AcuMsg/Records/Record" error:nil];
                for (CXMLElement *record in records)
                {
                    NSArray *nodes = [record children];
                    
                    for (CXMLNode *node in nodes)
                    {
                        if ([[node name] isEqualToString:@"Status"])
                        {
                            NSString *statusValue = [node stringValue];
                            NSArray *services = [statusValue componentsSeparatedByString:@"|"];
                            if ([services count] == 5)
                            {
                                if ([services[0] isEqualToString:@"1"])
                                {
                                    [_operationQueue cancelAllOperations];
                                    bOK = true;
                                }
                            }
                        }
                        else if([[node name] isEqualToString:@"ID"])
                        {
                            _serverID = [[node stringValue] intValue];
                            break;
                        }
                    }
                }
            }
            else
            {
                _sError = NSLocalizedString(@"Login failed.", @"OPR Task with opr_conf_image RetCode Value");
                [_mutex lock];
                return;
            }
        }
        else
        {
            [_mutex unlock];
            return;
        }
        
        [_mutex unlock];
        
        if (_cancelParam.sessionCanceled)
        {
            [_operationQueue cancelAllOperations];
            [_operationQueue waitUntilAllOperationsAreFinished];
            return;
        }
        
        if (bOK && _serverID != -1)
        {
            //NSLog(@"----found best server! ----");
            _gotServer = true;
            AcuServerProperty *server = [_asServerList objectAtIndex:_serverID];
            //NSLog(@"---- best server info ---- : \n iis : %@\ngateway : %@", server->iisIP, server->gatewayIP);
//            if (self.oprDelegate)
//            {
//                [self.oprDelegate acuOPRTask:self
//                                  reportInfo:NSLocalizedString(@"Found the best server.", @"OPR Task with opr_conf_image")];
//            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self getGatewayParams:_oprServer
                               session:_oprSession
                              mainASIP:server->gatewayIP];
            });
        }
        //add by zhiyuan for old gateway on 2013-10-30
        else if(bOK && _serverID == -1)
        {
            //NSLog(@"NOT found best server!");
            _gotServer = true;
            AcuServerProperty *server = [_asServerList objectAtIndex:0];
//            if (self.oprDelegate)
//            {
//                [self.oprDelegate acuOPRTask:self
//                                  reportInfo:NSLocalizedString(@"Found the best server.", @"OPR Task with opr_conf_image")];
//            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self getGatewayParams:_oprServer
                               session:_oprSession
                              mainASIP:server->gatewayIP];
            });
        }
        //end by zhiyuan for old gateway on 2013-10-30
    }];
    [request setFailedBlock:^{
        [_mutex lock];
        
        if (!_gotServer)
        {
            _sError = NSLocalizedString(@"Failed to communicate with server.", "OPR Task with opr_conf_image failed");
        }
        
        
        [_mutex unlock];
    }];
    [request startAsynchronous];
#endif
}

- (void)oprTimeout:(NSTimer*)timer
{
    if (_cancelParam.sessionCanceled)
    {
        [_timeoutTimer invalidate];
        _timeoutTimer = nil;
        return;
    }
    
    [_mutex lock];
    
    if (_gotServer)
    {
        [_timeoutTimer invalidate];
        _timeoutTimer = nil;
    }
    else
    {
        if (_oprServerIndex >= [_asServerList count])
        {
            [_timeoutTimer invalidate];
            _timeoutTimer = nil;
            
            _isTimeout = YES;
            
            //stop all opr operation
            [_operationQueue cancelAllOperations];
            
            _sError = NSLocalizedString(@"No server available.", "OPR Task with opr_conf_image");
            if (self.oprDelegate)
            {
                [self.oprDelegate acuOPRTask:self
                               withErrorInfo:_sError];
            }
        }
        else
        {
            [_operationQueue cancelAllOperations];
            [_operationQueue waitUntilAllOperationsAreFinished];
            
            [self addOPRServerQueue];
            _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:15.0
                                                             target:self
                                                           selector:@selector(oprTimeout:)
                                                           userInfo:nil
                                                            repeats:NO];
        }
    }
    
    [_mutex unlock];
}

- (void)oprCheckServerASIHttpRequestFailed:(ASIHTTPRequest *)request
{
    [_mutex lock];
    
    if (!_gotServer)
    {
        _sError = NSLocalizedString(@"Failed to communicate with server.", "OPR Task with opr_conf_image failed");
    }
    
    
    [_mutex unlock];
}

//
- (void)oprCheckServerASIHttpRequestSucceed:(ASIHTTPRequest *)request
{
    [_mutex lock];
    
    if (_gotServer)
    {
        [_mutex unlock];
        return;
    }
    
    NSString *response = [request responseString];
    //NSLog(@"---- opr_conf_image response ---- : \n%@", response);
    NSError *error = [NSError alloc];
    
    //first, load an XML document
    CXMLDocument *xmlDoc = [[CXMLDocument alloc] initWithXMLString:response options:0 error:&error];
    
    //get node
    CXMLNode *codeNode = [xmlDoc nodeForXPath:@"//AcuMsg/RetCode" error:&error];
    
    if (!codeNode)
    {
        [_mutex unlock];
        return;
    }
    
    bool bOK = false;
    NSString *codeString = [codeNode stringValue];
    
    if (codeString)
    {
        if ([codeString isEqualToString:@"1"])
        {
            //_oprResult = [[AcuOPRResult alloc] init];
            NSArray *records = nil;
            records = [xmlDoc nodesForXPath:@"//AcuMsg/Records/Record" error:nil];
            for (CXMLElement *record in records)
            {
                NSArray *nodes = [record children];
                
                for (CXMLNode *node in nodes)
                {
                    if ([[node name] isEqualToString:@"Status"])
                    {
                        NSString *statusValue = [node stringValue];
                        NSArray *services = [statusValue componentsSeparatedByString:@"|"];
                        if ([services count] == 5)
                        {
                            if ([services[0] isEqualToString:@"1"])
                            {
                                [_operationQueue cancelAllOperations];
                                bOK = true;
                            }
                        }
                    }
                    else if([[node name] isEqualToString:@"ID"])
                    {
                        _serverID = [[node stringValue] intValue];
                        break;
                    }
                }
            }
        }
        else
        {
            _sError = NSLocalizedString(@"Login failed.", @"OPR Task with opr_conf_image RetCode Value");
            [_mutex lock];
            return;
        }
    }
    else
    {
        [_mutex unlock];
        return;
    }
    
    [_mutex unlock];
    
    if (bOK && _serverID != -1)
    {
        //NSLog(@"----found best server! ----");
        _gotServer = true;
        AcuServerProperty *server = [_asServerList objectAtIndex:_serverID];
        //NSLog(@"---- best server info ---- : \n iis : %@\ngateway : %@", server->iisIP, server->gatewayIP);
//        if (self.oprDelegate)
//        {
//            [self.oprDelegate acuOPRTask:self
//							  reportInfo:NSLocalizedString(@"Found the best server.", @"OPR Task with opr_conf_image")];
//        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self getGatewayParams:_oprServer
                           session:_oprSession
                          mainASIP:server->gatewayIP];
        });
    }
    //add by zhiyuan for old gateway on 2013-10-30
    else if(bOK && _serverID == -1)
    {
        //NSLog(@"NOT found best server!");
        _gotServer = true;
        AcuServerProperty *server = [_asServerList objectAtIndex:0];
//        if (self.oprDelegate)
//        {
//            [self.oprDelegate acuOPRTask:self
//							  reportInfo:NSLocalizedString(@"Found the best server.", @"OPR Task with opr_conf_image")];
//        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self getGatewayParams:_oprServer
                           session:_oprSession
                          mainASIP:server->gatewayIP];
        });
    }
    //end by zhiyuan for old gateway on 2013-10-30
    
}

- (void) getGatewayParams:(NSString*)oprServer
                  session:(NSString*)oprSession
                 mainASIP:(NSString*)mainAS
{
    NSMutableString *req = [[NSMutableString alloc] initWithString:@"http://"];
    AcuGlobalParams *params = [AcuGlobalParams sharedInstance];
    if (params.ProtocolType == 1 || params.ProtocolType == 3)
    {
        [req setString:@"https://"];
    }
    [req appendString:oprServer];
    [req appendString:@"/aculearn-idm/v7/ci/default.asp?"];
    
    [req appendFormat:@"%@=%@", @"functionid", @"choose_main_as_acucom"];
    [req appendFormat:@"&%@=%@", @"modulename", oprSession];
    [req appendFormat:@"&%@=%@", @"mainas", mainAS];
    
    
    req = [[req stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] copy];
#if 0
    NSURL *url = [NSURL URLWithString:req];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
	request = [ASIHTTPRequest requestWithURL:url];
    [request setValidatesSecureCertificate:NO];
    [request setDelegate:self];
    [request setDidFailSelector:@selector(oprGetGatewayParamsASIHttpRequestFailed:)];
    [request setDidFinishSelector:@selector(oprGetGatewayParamsASIHttpRequestSucceed:)];
    [request setDefaultResponseEncoding:NSUTF8StringEncoding];
    [request startAsynchronous];
#else
    ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:req]];
    [request setValidatesSecureCertificate:NO];
    __weak ASIHTTPRequest *requestTmp = request;
    [request setCompletionBlock:^{
        NSString *response = [requestTmp responseString];
        //NSLog(@"Start Session response : %@", response);
        NSError *error = [NSError alloc];
        
        if (_cancelParam.sessionCanceled)
        {
            return;
        }
        
        //first, load an XML document
        CXMLDocument *xmlDoc = [[CXMLDocument alloc] initWithXMLString:response options:0 error:&error];
        
        //get node
        CXMLNode *codeNode = [xmlDoc nodeForXPath:@"//AcuMsg/RetCode" error:&error];
        
        if (!codeNode)
        {
            _sError = NSLocalizedString(@"Failed to connect server.", @"OPR Task with choose_main_as RetCode Node");
            if (self.oprDelegate)
            {
                [self.oprDelegate acuOPRTask:self
                               withErrorInfo:_sError];
            }
            return;
        }
        
        bool bOK = false;
        NSString *codeString = [codeNode stringValue];
        
        if (codeString)
        {
            if ([codeString isEqualToString:@"1"])
            {
                NSArray *records = nil;
                records = [xmlDoc nodesForXPath:@"//AcuMsg/Records/Record" error:nil];
                for (CXMLElement *record in records)
                {
                    NSArray *nodes = [record children];
                    
                    for (CXMLNode *node in nodes)
                    {
                        if ([[node name] isEqualToString:@"Prefix"])
                        {
                            _oprResult->prefix = [node stringValue];
                        }
                        else if([[node name] isEqualToString:@"Gateway"])
                        {
                            _oprResult->gatewayParam = [node stringValue];
                        }
                        else if([[node name] isEqualToString:@"MainAS"])
                        {
                            //get node
                            CXMLNode *mainASGatewayIPNode = [xmlDoc nodeForXPath:@"//AcuMsg/Records/Record/MainAS/GatewayIP"
                                                                           error:&error];
                            if (mainASGatewayIPNode)
                            {
                                bOK = true;
                                _oprResult->gatewayIP = [mainASGatewayIPNode stringValue];
                            }
                            
                        }
                        
                    }
                }
            }
            else
            {
                _sError = NSLocalizedString(@"Login failed.", @"OPR Task with choose_main_as RetCode Value");
            }
        }
        else
        {
            _sError = NSLocalizedString(@"Failed to connect server.", @"OPR Task with choose_main_as RetCode Value");
        }
        
        if (!bOK)
        {
            if (self.oprDelegate)
            {
                [self.oprDelegate acuOPRTask:self
                               withErrorInfo:_sError];
            }
            return;
        }
        
        _oprResult->iisIP = @"";
        for (AcuServerProperty *serverProperty in _asServerList)
        {
            if ([serverProperty->gatewayIP isEqualToString:_oprResult->gatewayIP])
            {
                _oprResult->iisIP = serverProperty->iisIP;
                break;
            }
        }
        
        if ([_oprResult->iisIP length] <= 0)
        {
            // cannot find as info in the as list
            if ([_oprResult->mainAS->iisIP length] <= 0)
            {
                // no main as info, use am.
                _oprResult->iisIP = _oprResult->am->iisIP;
                _oprResult->gatewayIP = _oprResult->am->gatewayIP;
            }
            else
            {
                // use main as
                _oprResult->iisIP = _oprResult->mainAS->iisIP;
                _oprResult->gatewayIP = _oprResult->mainAS->gatewayIP;
            }
        }
        
        if (bOK)
        {
            if ([_oprResult->prefix isEqualToString:@"+"])
            {
                //_oprResult->myStream = _oprServer;
                _oprResult->myStream = _oprResult->mainAS->gatewayIP;
            }
            else
            {
                _oprResult->myStream = _oprResult->gatewayIP;
            }
        }
        
        if (self.oprDelegate)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.oprDelegate acuOPRTask:self
                                    onResult:_oprResult
                                    withInfo:NSLocalizedString(@"Connecting to conference server...", @"OPR Task with choose_main_as RetCode Value")];
            });
        }

    }];
    [request setFailedBlock:^{
        [_mutex lock];
        
        _sError = NSLocalizedString(@"Failed to communicate with server.", @"OPR Task with choose_main_as failed");
        if (self.oprDelegate)
        {
            [self.oprDelegate acuOPRTask:self
                           withErrorInfo:_sError];
        }
        
        [_mutex unlock];
    }];
    [request startAsynchronous];
#endif
}

- (void)oprGetGatewayParamsASIHttpRequestFailed:(ASIHTTPRequest *)request
{
    [_mutex lock];
    
    _sError = NSLocalizedString(@"Failed to communicate with server.", @"OPR Task with choose_main_as failed");
    if (self.oprDelegate)
    {
        [self.oprDelegate acuOPRTask:self
                       withErrorInfo:_sError];
    }
    
    [_mutex unlock];
}

//
- (void)oprGetGatewayParamsASIHttpRequestSucceed:(ASIHTTPRequest *)request
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
        _sError = NSLocalizedString(@"Failed to connect server.", @"OPR Task with choose_main_as RetCode Node");
        if (self.oprDelegate)
        {
            [self.oprDelegate acuOPRTask:self
                           withErrorInfo:_sError];
        }
        return;
    }
    
    bool bOK = false;
    NSString *codeString = [codeNode stringValue];
    
    if (codeString)
    {
        if ([codeString isEqualToString:@"1"])
        {
            NSArray *records = nil;
            records = [xmlDoc nodesForXPath:@"//AcuMsg/Records/Record" error:nil];
            for (CXMLElement *record in records)
            {
                NSArray *nodes = [record children];
                
                for (CXMLNode *node in nodes)
                {
                    if ([[node name] isEqualToString:@"Prefix"])
                    {
                        _oprResult->prefix = [node stringValue];
                    }
                    else if([[node name] isEqualToString:@"Gateway"])
                    {
                        _oprResult->gatewayParam = [node stringValue];
                    }
                    else if([[node name] isEqualToString:@"MainAS"])
                    {
                        //get node
                        CXMLNode *mainASGatewayIPNode = [xmlDoc nodeForXPath:@"//AcuMsg/Records/Record/MainAS/GatewayIP"
                                                                     error:&error];
                        if (mainASGatewayIPNode)
                        {
                            bOK = true;
                            _oprResult->gatewayIP = [mainASGatewayIPNode stringValue];
                        }
                        
                    }
                    
                }
            }
        }
        else
        {
            _sError = NSLocalizedString(@"Login failed.", @"OPR Task with choose_main_as RetCode Value");
        }
    }
    else
    {
        _sError = NSLocalizedString(@"Failed to connect server.", @"OPR Task with choose_main_as RetCode Value");
    }
    
    if (!bOK)
    {
        if (self.oprDelegate)
        {
            [self.oprDelegate acuOPRTask:self
                           withErrorInfo:_sError];
        }
        return;
    }
    
    _oprResult->iisIP = @"";
    for (AcuServerProperty *serverProperty in _asServerList)
    {
        if ([serverProperty->gatewayIP isEqualToString:_oprResult->gatewayIP])
        {
            _oprResult->iisIP = serverProperty->iisIP;
            break;
        }
    }
    
    if ([_oprResult->iisIP length] <= 0)
    {
        // cannot find as info in the as list
        if ([_oprResult->mainAS->iisIP length] <= 0)
        {
            // no main as info, use am.
            _oprResult->iisIP = _oprResult->am->iisIP;
            _oprResult->gatewayIP = _oprResult->am->gatewayIP;
        }
        else
        {
            // use main as
            _oprResult->iisIP = _oprResult->mainAS->iisIP;
            _oprResult->gatewayIP = _oprResult->mainAS->gatewayIP;
        }
    }
	
	if (bOK)
	{
		if ([_oprResult->prefix isEqualToString:@"+"])
		{
			//_oprResult->myStream = _oprServer;
			_oprResult->myStream = _oprResult->mainAS->gatewayIP;
		}
		else
		{
			_oprResult->myStream = _oprResult->gatewayIP;
		}
	}
    
    if (self.oprDelegate)
    {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.oprDelegate acuOPRTask:self
								onResult:_oprResult
								withInfo:NSLocalizedString(@"Connecting to conference server...", @"OPR Task with choose_main_as RetCode Value")];
		});
    }
}

@end
