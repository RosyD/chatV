//
//  ACNoteTimeLineVC.m
//  chat
//
//  Created by Aculearn on 14/12/30.
//  Copyright (c) 2014年 Aculearn. All rights reserved.
//

#import "ACNoteTimeLineVC.h"
#import "ACNetCenter+Notes.h"
#import "UIView+Additions.h"
#import "UINavigationController+Additions.h"
#import "ACNoteDetailVC.h"
#import "ACDataCenter.h"

@interface ACNoteTimeLineVC (){
    __weak IBOutlet UILabel *_titleLabel;
    
    
    __weak IBOutlet UIView *_navgstionBarView;
    __weak IBOutlet UIImageView *_navImage;
    __weak IBOutlet UIView *_navView;
    __weak IBOutlet UIView *_navBarView;
    __weak IBOutlet UIButton *_backBtn;
    
}

@end

@implementation ACNoteTimeLineVC

AC_MEM_Dealloc_implementation

- (void)viewDidLoad {
    
    self.nListType  =   ACNoteListVC_Type_TimeLine_List; //必须放在这里

    [super viewDidLoad];
    ///
  // [view setFrame:CGRectMake(0, 0, kScreen_Width, kScreen_Height)];
    [self.view setFrame:CGRectMake(0, 0, kScreen_Width, kScreen_Height)];
    [_navgstionBarView setFrame:CGRectMake(0, 0, kScreen_Width, 64)];
    [_navView setFrame:CGRectMake(0, 0, kScreen_Width, 64)];
    [_navImage setFrame:CGRectMake(0, 0, kScreen_Width, 64)];
    [_navBarView setFrame:CGRectMake(0, 20, kScreen_Width, 44)];
    [_backBtn setFrame:CGRectMake(3, 20, 44, 44)];
    [_titleLabel setCenter:CGPointMake(kScreen_Width*0.5, 44)];
    [_contentView setFrame:CGRectMake(0, 64, kScreen_Width,kScreen_Height - 64)];
    [self.mainTableView setFrame:CGRectMake(0, 0, kScreen_Width, kScreen_Height-64)];
    NSLog(@".... _contentView..... %@ ,self.mainTableView ....... %@ ,.....screen ...  %@",NSStringFromCGSize(_contentView.size),NSStringFromCGSize(self.mainTableView.size),NSStringFromCGSize([[UIScreen mainScreen] bounds].size));
    
    
    _titleLabel.text = NSLocalizedString(@"Timeline", nil);
    
    if (![ACConfigs isPhone5]){
        [self.mainTableView setFrame_height:self.mainTableView.size.height-88];
        [_contentView setFrame_height:_contentView.size.height-88];
    }
    
    [[NSNotificationCenter defaultCenter]  addObserver:self selector:@selector(topicInfoChange) name:kDataCenterTopicInfoChangedNotifation object:nil];
    
    
//    if(_noteIdForNotification){
//        [self _showDetailVCWithNoteObj:_noteIdForNotification withIndexPath:nil];
//        _noteIdForNotification = nil;
//        
//        //1秒后加载数据
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC),dispatch_get_main_queue(), ^{
//            [self LoadDataFunc];
//        });
//    }
//    else{
        [self LoadDataFunc];
//    }
    ///
    self.mainTableView.estimatedRowHeight = 300;
    self.mainTableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)topicInfoChange{
    [self.mainTableView reloadData];
}


#pragma mark - ACNoteListVC_Base

-(void)LoadDataFunc{ //加载更多,头或尾,被调用

    /*
     rest/apis/note/latest?s={startTime}&e={endTime}&l={limit}
     Url parameters
     
     startTime: 起始（更大的）时间
     endTime: 截止（更小的）时间
     limit: 限制返回数量
     
     Method: GET
     Response:
     
     {
     "code" : 1,
     "notebases" : [{note json object}, {note comment json object}], //在note或comment的json对象中有字段"type"是noteType的含义， 如果noteType = 1， 则是Note， 如果noteType = 10， 则是Comment。
     }
     */
    
    NSString* pStartTime = @"";
    NSString* pEndTime = @"";
    
    if(self.notesSourceArray.count){
//        头部全刷新
//        if(ACTableViewVC_Base_RefreshType_Head==self.nRefreshType){
//            pEndTime = [NSString stringWithFormat:@"&e=%lld",((ACNoteObject*)self.notesSourceArray[0]).updateTime ];
//        }
//        else
        
            if(ACTableViewVC_Base_RefreshType_Tail==self.nRefreshType){
            pStartTime  = [NSString stringWithFormat:@"&s=%lld",((ACNoteObject*)self.notesSourceArray[self.notesSourceArray.count-1]).updateTime];
        }
    }
    
    NSString* const acLoadUrl = [NSString stringWithFormat:@"%@/rest/apis/note/latest?l=20%@%@",[[ACNetCenter shareNetCenter] acucomServer],pStartTime,pEndTime];
    
    wself_define();
    [ACNetCenter callURL:acLoadUrl forMethodDelete:NO withBlock:^(ASIHTTPRequest *request, BOOL bIsFail){
        
        NSInteger nCount = 0;
        if(!bIsFail){
            NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
//            ITLog(responseDic);
            if(ResponseCodeType_Nomal==[[responseDic objectForKey:kCode] intValue]){
                NSArray* pArray =   [responseDic objectForKey:@"notebases"];
                
                if(ACTableViewVC_Base_RefreshType_Head==wself.nRefreshType||
                   ACTableViewVC_Base_RefreshType_Focus==wself.nRefreshType){
                    [wself.notesSourceArray removeAllObjects];
                }
                
                for(NSDictionary* pNoteOrComment in pArray){
                    int nType = [[pNoteOrComment objectForKey:@"type"] intValue];
                    ACNoteObject* pObj = nil;
                    if(ACNoteObject_Type_Note==nType){
                        //如果noteType = 1， 则是Note，
                        pObj= [[ACNoteMessage alloc] initWithDict:pNoteOrComment];
                    }
                    else if(ACNoteObject_Type_Comment==nType){
                        // 如果noteType = 10， 则是Comment
                        pObj= [[ACNoteComment alloc] initWithDict:pNoteOrComment];
                    }
                    
                    if(pObj){
                        [wself.notesSourceArray addObject:pObj];
                        nCount  ++;
                    }
                }
                
                if(ACTableViewVC_Base_RefreshType_Tail!=wself.nRefreshType&&nCount){
                    ACNoteObject* pObj = wself.notesSourceArray[0];
                    [[ACConfigs shareConfigs] chageNoteLastTimeForTimeLine:pObj.updateTime];
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [wself LoadDataFuncEnd_WithCount:nCount];
        });
    }];
}

#pragma mark -IBAction
- (IBAction)goBackup:(id)sender {
    [self.navigationController ACpopViewControllerAnimated:YES];
}

#pragma mark - ACNoteListVC_Base
-(void)onDeleteNote:(NSIndexPath*)pIndexPath{
    //删除Note 不做任何处理
}

#pragma mark -UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ACNoteObject* pNoteObj =    self.notesSourceArray[indexPath.row];
    
    //寻找ACTopicEntity
    self.topicEntity = pNoteObj.topicEntity;
    
    if(self.topicEntity){
        [ACNoteDetailVC showNote:pNoteObj withTopic:self.topicEntity inTimeLineVC:self];
    }
    else{
        //没有信息
        AC_ShowTip(NSLocalizedString(@"Topic has been removed!",nil));
    }
}

@end
