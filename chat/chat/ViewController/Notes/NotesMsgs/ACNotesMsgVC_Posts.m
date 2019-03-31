//
//  ACNotesMsgViewController.m
//  chat
//
//  Created by 王方帅 on 14-6-3.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACNotesMsgVC_Posts.h"
#import "UINavigationController+Additions.h"
#import "ACMessageDB.h"
#import "ACNetCenter+Notes.h"
#import "ACContributeViewController.h"
#import "ACDataCenter.h"
#import "ACNoteMessage.h"
#import "ACConfigs.h"



@implementation ACNotesMsgVC_Posts

AC_MEM_Dealloc_implementation

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    
    _postButton.hidden = YES;
    
    [self LoadDataFunc];
}


-(void)didMoveToParentViewController:(UIViewController *)parent{
    [super didMoveToParentViewController:parent];
    
   /// int nHight =    self.view.bounds.size.height;
    
    ///[self.mainTableView setFrame_height:nHight];
   /// [_postButton setFrame_y:nHight-_postButton.frame.size.height-20];
//    CGRect rect =   self.mainTableView.frame;
//    CGRect oldRect = _postButton.frame;
//    
//    NSLog(@"...");
    ///
    self.mainTableView.size= CGSizeMake(kScreen_Width, kScreen_Height - 104);
    
    
}



#pragma mark - ACNoteListVC_Base


//#define TEST_FOR_SCROLL_TO_MAX_COMMNET

-(void)LoadDataFunc{ //加载更多,头或尾,被调用
    
    NSString* pStartTime =  @"";
    NSString* pEndTime =  @"";
    
    if(self.notesSourceArray.count){
//        if(ACTableViewVC_Base_RefreshType_Head==self.nRefreshType){
//          头部刷新刷全部
//            pEndTime = [@(((ACNoteMessage*)self.notesSourceArray[0]).createTime) stringValue];
//        }
//        else
        
            if(ACTableViewVC_Base_RefreshType_Tail==self.nRefreshType){
                pStartTime = [@(((ACNoteMessage*)self.notesSourceArray[self.notesSourceArray.count-1]).createTime) stringValue];
        }
    }
   
    
    NSString * const acLoadUrl = [[[ACNetCenter shareNetCenter] acucomServer] stringByAppendingFormat:@"/rest/apis/note/%@/notes?s=%@&e=%@&l=%d",self.topicEntity.entityID,pStartTime,pEndTime,20];
    
    
    wself_define();
    [ACNetCenter callURL:acLoadUrl forMethodDelete:NO withBlock:^(ASIHTTPRequest *request, BOOL bIsFail){
        
        NSInteger nCount = 0;
        if(!bIsFail){
            NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
            ITLog(responseDic);
            if(ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]){
                if(ACTableViewVC_Base_RefreshType_Head==wself.nRefreshType){
                    //头部刷新删除全部
                    [wself.notesSourceArray removeAllObjects];
                }
                
                NSArray* pNotes =   [responseDic objectForKey:@"notes"];
                for(NSDictionary* pDict in pNotes){
                    ACNoteMessage *pNoteMsg = [[ACNoteMessage alloc] initWithDict:pDict];
                    if(pNoteMsg){
                        [wself.notesSourceArray addObject:pNoteMsg];
                        nCount  ++;
                    }
                }
                
                if(ACTableViewVC_Base_RefreshType_Tail!=wself.nRefreshType&&nCount){
                    ACNoteObject* pObj = wself.notesSourceArray[0];
                    [[ACConfigs shareConfigs] chageNoteLastTimeForRefreshNoteOrComment:pObj.updateTime];
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [wself LoadDataFuncEnd_WithCount:nCount];
            if(ACNotePermission_ADDNOTE_ALLOW==wself.topicEntity.topicPerm.note_add){
                wself.postButton.hidden = NO;
            }
        });
    }];

    
    
 /*
    NSInteger endTime = 0;
    NSInteger startTime = 0;
    
    if(ACTableViewVC_Base_RefreshType_Head==self.nRefreshType){
        if(self.notesSourceArray.count){
            endTime = ((ACNoteMessage*)self.notesSourceArray[0]).createTime;
        }
    }
    else  if(ACTableViewVC_Base_RefreshType_Tail==self.nRefreshType&&
       self.notesSourceArray.count){
        startTime = ((ACNoteMessage*)self.notesSourceArray[self.notesSourceArray.count-1]).createTime;
    }
    
    
    
    
    [[ACNetCenter shareNetCenter] Notes_LoadNoteList_WithTopicEntityID:self.topicEntity.entityID withStartTime:startTime withEndTime:endTime withLimit:20];*/
}

-(void)sendNoteMessageSuccess:(id)message{
    NSAssert([message isKindOfClass:[ACNoteMessage class]],@"sendNoteMessageSuccess ACNoteMessage");
    
    //更新时间
    [[ACConfigs shareConfigs] chageNoteLastTimeForNewUpdateTime:((ACNoteMessage*)message).updateTime];
    
    [self.notesSourceArray insertObject:message atIndex:0];
    [self.mainTableView reloadData];
    [self scrollToIndex:0 animated:YES];
}

#pragma mark -IBAction
-(IBAction)notesButtonTouchUp:(id)sender
{
    /*WB
    ACWallBoardViewController *notesVC = [[ACWallBoardViewController alloc] init];
    notesVC.topicEntity = self.topicEntity;
    notesVC.dataSourceArray = self.dataSourceArray;
    [self.navigationController pushViewController:notesVC animated:YES];*/
}

-(IBAction)onPostButton:(id)sender{
    [super onNewNoteMessge];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
