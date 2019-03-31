//
//  ACSimpleSelectViewController.m
//  chat
//
//  Created by Aculearn on 15/4/15.
//  Copyright (c) 2015年 Aculearn. All rights reserved.
//

#import "ACSimpleSelectViewController.h"
#import "UINavigationController+Additions.h"

@interface ACSimpleSelectItemInfo : NSObject{
    @public
    NSString*   pInfo;
    BOOL        bSelected;
}
@end
@implementation ACSimpleSelectItemInfo
@end

@interface ACSimpleSelectViewController (){
    NSArray*    _pSelectItems; //<ACSimpleSelectItemInfo>
    BOOL        _bIsSimpleSelect;
    NSString*   _pTitle;
    ACSimpleSelectViewControllerOnExit  _pOnExitFunc;
}
@property (weak, nonatomic) IBOutlet UILabel *labeTitle;
@property (weak, nonatomic) IBOutlet UITableView *tableList;

@end

@implementation ACSimpleSelectViewController

AC_MEM_Dealloc_implementation

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _labeTitle.text = _pTitle;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

+(void)_showSelects:(NSArray*)pSelectInfos withDefaults:(NSArray*) selectedNos fromParentVC:(UIViewController*) pParentVC  withTitle:(NSString*)pTitle withExitBlock:(ACSimpleSelectViewControllerOnExit) pFunc forSimpleSelect:(BOOL)bIsSimpleSelect{
    
    NSMutableArray* pArray = [[NSMutableArray alloc] init];
    for(NSString* pStr in pSelectInfos){
        ACSimpleSelectItemInfo* pItem = [[ACSimpleSelectItemInfo alloc] init];
        pItem->pInfo    =   pStr;
        [pArray addObject:pItem];
    }
    
    for(NSNumber* pNum in selectedNos){
        NSInteger nNo = pNum.integerValue;
        if(nNo<pArray.count){
            ((ACSimpleSelectItemInfo*)pArray[nNo])->bSelected = YES;
        }
    }
    
    ACSimpleSelectViewController* pVC  = [[ACSimpleSelectViewController alloc] init];
    AC_MEM_Alloc(pVC);
    pVC->_pSelectItems =    pArray;
    pVC->_bIsSimpleSelect   =   bIsSimpleSelect;
    pVC->_pTitle    =   pTitle;
    pVC->_pOnExitFunc   = pFunc;
    [pParentVC.navigationController pushViewController:pVC animated:YES];
//    [pParentVC ACpresentViewController:pVC animated:YES completion:nil];
}


//多选
+(void)showSelects:(NSArray*)pSelectInfos withDefaults:(NSArray*) selectedNos fromParentVC:(UIViewController*) pParentVC  withTitle:(NSString*)pTitle withExitBlock:(ACSimpleSelectViewControllerOnExit) pFunc{
    
    [ACSimpleSelectViewController _showSelects:pSelectInfos
                                  withDefaults:selectedNos
                                  fromParentVC:pParentVC
                                     withTitle:pTitle
                                 withExitBlock:pFunc
                               forSimpleSelect:NO];
    
}

//单选
+(void)showSelects:(NSArray*)pSelectInfos withDefaultNo:(NSInteger) selectedNo fromParentVC:(UIViewController*) pParentVC  withTitle:(NSString*)pTitle withExitBlock:(ACSimpleSelectViewControllerOnExit) pFunc{
    [ACSimpleSelectViewController _showSelects:pSelectInfos
                                  withDefaults:@[@(selectedNo)]
                                  fromParentVC:pParentVC
                                     withTitle:pTitle
                                 withExitBlock:pFunc
                               forSimpleSelect:YES];
}

#pragma mark UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _pSelectItems.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString* pACSimpleSelectViewController_Cell = @"ACSimpleSelectViewController_Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:pACSimpleSelectViewController_Cell];
    if(nil==cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:pACSimpleSelectViewController_Cell];
    }
    ACSimpleSelectItemInfo* pItem = _pSelectItems[indexPath.row];
    cell.textLabel.text = pItem->pInfo;
    cell.accessoryType = pItem->bSelected?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
    return cell;
}

#pragma mark UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    ACSimpleSelectItemInfo* pItem = _pSelectItems[indexPath.row];
    pItem->bSelected = !pItem->bSelected;
    if(_bIsSimpleSelect&&pItem->bSelected){
        for(ACSimpleSelectItemInfo* pTemp in _pSelectItems){
            if(pTemp!=pItem){
                pTemp->bSelected = NO;
            }
        }
    }
    [tableView reloadData];
}


- (IBAction)onBackup:(id)sender {
    NSInteger nSelectedNo = -1L;
    NSMutableArray* selectedNos = nil;
    
    for(NSInteger nNo=0;nNo<_pSelectItems.count;nNo++){
        ACSimpleSelectItemInfo* pTemp = _pSelectItems[nNo];
        if(pTemp->bSelected){
            if(_bIsSimpleSelect){
                nSelectedNo = nNo;
                break;
            }
            
            if(nil==selectedNos){
                selectedNos = [[NSMutableArray alloc] init];
            }
            [selectedNos addObject:@(nNo)];
        }
    }
    [self.navigationController popViewControllerAnimated:YES];
    _pOnExitFunc(selectedNos,nSelectedNo);
}


@end
