//
//  ACNoteSearchResultVC.m
//  chat
//
//  Created by Aculearn on 16/11/1.
//  Copyright © 2016年 Aculearn. All rights reserved.
//

#import "ACNoteSearchResultVC.h"
#import "UIView+Additions.h"
#import "UINavigationController+Additions.h"
#import "ACNoteMessage.h"
#import "ACNetCenter.h"
#import "ACDataCenter.h"
#import "ACConfigs.h"
#import "ACNoteListVC_Cell.h"
#import "ACNoteDetailVC.h"

@interface ACNoteSearchResultVC (){
    __weak IBOutlet UILabel *_titleLabel;
    NSArray<NSString*> *_highlights;
    ACNoteObject*   _noteObj;
    ACTopicEntity*      _topic;
    __weak UIViewController*   _superVC;
}


@end

@implementation ACNoteSearchResultVC

AC_MEM_Dealloc_implementation


+(void)showSearchResult:(NSDictionary*)pSearchResult
         withSearchText:(NSString*)pSearchText
              inSuperVC:(UIViewController*)_pSuperVC{
    //用在搜索中
    ACTopicEntity* pTopic = [[ACDataCenter shareDataCenter] findTopicEntity:pSearchResult[@"teid"]];
    if(nil==pTopic){
        AC_ShowTip(NSLocalizedString(@"Topic has been removed!",nil));
        return;
    }
    
    __weak UIViewController* pSuperVC = _pSuperVC;
    
//#define ACNoteObject_Type_Note      1   //数据类型是Note
//#define ACNoteObject_Type_Comment   10  //数据类型是Comment

    NSString* pURL = nil;
    BOOL bIsComment = ACNoteObject_Type_Comment==[pSearchResult[@"type"] integerValue];
    if(bIsComment){
        pURL = [NSString stringWithFormat:@"%@/rest/apis/note/getComment/%@",
                            [[ACNetCenter shareNetCenter] acucomServer],
                            pSearchResult[@"id"]];
    }
    else{
        NSString* pNoteID = pSearchResult[@"id"];
        [ACNetCenter searchHighLightWithKey:pSearchText topicEntityID:pTopic.entityID withBlock:^(NSArray *highlights) {
            [ACNoteDetailVC showNoteMsgWithNoteID:pNoteID
                                         andTopic:pTopic
                                     andHighlight:highlights
                                   inNomalSuperVC:pSuperVC];
            
        }];
        
        return;
//        pURL = [NSString stringWithFormat:@"%@/rest/apis/note/%@",
//                [[ACNetCenter shareNetCenter] acucomServer],
//                pSearchResult[@"id"]];
    }
    
    [pSuperVC.view showProgressHUD];
    
    //检查状态
    
    [ACNetCenter callURL:pURL forMethodDelete:NO withBlock:^(ASIHTTPRequest *request, BOOL bIsFail){
        NSString* pError  = NSLocalizedString(@"Network_Failed", nil);
        
        if(!bIsFail){
            NSDictionary *responseDic = [ACNetCenter getJOSNFromHttpData:request.responseData];
            ITLog(responseDic);
            int nCode = [[responseDic objectForKey:kCode] intValue];
            if(ResponseCodeType_Nomal==nCode){
                ACNoteObject* pNoteObj = nil;
                if(bIsComment){
                    NSDictionary* pCommentDict =   [responseDic objectForKey:@"noteComment"];
                    if(pCommentDict.count){
                        pNoteObj = [[ACNoteComment alloc] initWithDict:pCommentDict];
                    }
                }
                else{
                    NSDictionary* pNoteDict =   [responseDic objectForKey:@"note"];
                    if(pNoteDict.count){
                        pNoteObj    =   [[ACNoteMessage alloc] initWithDict:pNoteDict];
                    }
                }
                if(pNoteObj){
                    
                    [ACNetCenter searchHighLightWithKey:pSearchText topicEntityID:pTopic.entityID withBlock:^(NSArray *highlights) {
                        [pSuperVC.view hideProgressHUDWithAnimated:NO];
                        
                        ACNoteSearchResultVC* pVC = [[ACNoteSearchResultVC alloc] init];
                        AC_MEM_Alloc(pVC);
                        pVC->_highlights    =   highlights;
                        pVC->_noteObj       =   pNoteObj;
                        pVC->_superVC       =   pSuperVC;
                        pVC->_topic         =   pTopic;
                        [pVC.notesSourceArray addObject:pNoteObj];
                        [pSuperVC.navigationController pushViewController:pVC animated:YES];
                    }];

                    return;
                }
             }
            else if(ResponseCodeType_Note_Deleted==nCode){
                if(bIsComment){
                    pError  =   NSLocalizedString(@"This comment has been removed!",nil);
                }
                else{
                    pError  =   NSLocalizedString(@"This note has been removed!",nil);
                }
            }
        }
        [pSuperVC.view hideProgressHUDWithAnimated:NO];
        AC_ShowTip(pError);
    }];
}


- (void)viewDidLoad {
    // Do any additional setup after loading the view from its nib.
    
    self.nListType  =   ACNoteListVC_Type_SearchResult; //必须放在这里
    
    [super viewDidLoad];
    
    [self LoadDataFuncEnd_WithCount:1];
    
    _titleLabel.text = _noteObj.isNoteMessage?NSLocalizedString(@"Note", nil):NSLocalizedString(@"Comment", nil);
    
    if (![ACConfigs isPhone5]){
        [self.mainTableView setFrame_height:self.mainTableView.size.height-88];
        [_contentView setFrame_height:_contentView.size.height-88];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark -IBAction
- (IBAction)goBackup:(id)sender {
    [self.navigationController ACpopViewControllerAnimated:YES];
}

- (IBAction)gotoNoteDetail:(id)sender{
    ACNoteComment* pComment =   (ACNoteComment*)self.notesSourceArray.firstObject;
    [ACNoteDetailVC showNoteMsgWithNoteID:pComment.noteId
                                 andTopic:_topic
                             andHighlight:nil
                           inNomalSuperVC:self];
}

#pragma mark -UITableViewDelegate

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ACNoteListVC_Cell* cell = (ACNoteListVC_Cell*)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    [cell setHighlight:_highlights];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self gotoNoteDetail:nil];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
