//
//  PersonInfoVC.m
//  TestForContens
//
//  Created by Aculearn on 14/12/9.
//  Copyright (c) 2014年 Aculearn. All rights reserved.
//

#import "ACPersonContactVC.h"



@interface PersonInfoItem : NSObject{
    @public
    BOOL        _bSelected; //是否使用
    NSString*   _pLabel;
    NSString*   _pValue;
}
@end

@interface PersonInfoGroup : NSObject{
    @public
    ABPropertyID    _PropertyID;
    NSString*       _pLable;
    NSMutableArray* _pItems; //<PersonInfoItem>
}
@end


@implementation PersonInfoItem
@end

@implementation PersonInfoGroup


AC_MEM_Dealloc_implementation


-(id)initWithPerson:(ABRecordRef) person forProperty:(ABPropertyID) PropertyID andPropertyLable:(NSString*)pLable{
    
    self = [super init];
    if(nil==self){
        return nil;
    }
    
    ABMultiValueRef Infos = ABRecordCopyValue(person, PropertyID);
    if(Infos) {
        NSInteger nCount =    ABMultiValueGetCount(Infos);
        _PropertyID =   PropertyID;
        _pItems =    [[NSMutableArray alloc] initWithCapacity:nCount];
        _pLable =    pLable; //NSLocalizedString(pLable, nil);//NSLocalizedString
        for (int k = 0; k < nCount; k++) {
            PersonInfoItem *pItem = [[PersonInfoItem alloc] init];
            pItem->_bSelected   =   YES;
            pItem->_pLabel      =   (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(Infos, k));
            pItem->_pValue       =   (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(Infos, k);
            [_pItems addObject:pItem];
        }
        CFRelease(Infos);
    }
    
    return _pItems.count?self:nil;
}

-(void)setToPerson:(ABRecordRef) person{
    ABMutableMultiValueRef multi= ABMultiValueCreateMutable(kABMultiStringPropertyType);
    for (PersonInfoItem* item in _pItems) {
        if(item->_bSelected){
            ABMultiValueAddValueAndLabel(multi,(__bridge CFTypeRef)(item->_pValue),(__bridge CFTypeRef)(item->_pLabel),NULL);
        }
    }
    
    if(ABMultiValueGetCount(multi)){
        CFErrorRef error =NULL;
        ABRecordSetValue(person, _PropertyID, multi, &error);
    }
    CFRelease(multi);
}


@end


@interface ACPersonContactVC (){
    NSMutableArray*     _pGroupsInfo; // <PersonInfoGroup>
    ABRecordRef         _personNewInfoRef;
    id<ACPersonContactVC_Delegate> _delegate;
 }

@end



@implementation ACPersonContactVC


static void   _ClonePersonProperty(ABRecordRef destPerson,ABRecordRef sourcePerson, ABPropertyID propertyID){
    CFTypeRef  property = ABRecordCopyValue(sourcePerson, propertyID);
    if(property){
        CFErrorRef error =NULL;
        ABRecordSetValue(destPerson,propertyID,property, &error);
        CFRelease(property);
    }
}

+(id) ACPersonContactVCWithPersonRecord:(ABRecordRef) person andDelegate:(id<ACPersonContactVC_Delegate>) delegate{
    
    NSMutableArray* pSectionsInfo = [[NSMutableArray alloc] initWithCapacity:2];
   
    {
        PersonInfoGroup* pGroupTel =    [[PersonInfoGroup alloc] initWithPerson:person forProperty:kABPersonPhoneProperty andPropertyLable:NSLocalizedString(@"PersonContace_lable_Tel", nil)];
        if(pGroupTel){
            [pSectionsInfo addObject:pGroupTel];
        }
    }

    {
        PersonInfoGroup* pGroupMail =    [[PersonInfoGroup alloc] initWithPerson:person forProperty:kABPersonEmailProperty andPropertyLable:NSLocalizedString(@"PersonContace_lable_Mail", nil)];
        if(pGroupMail){
            [pSectionsInfo addObject:pGroupMail];
        }
    }
    
    if(pSectionsInfo.count){
        ACPersonContactVC* pPersonInfoVC =   [[ACPersonContactVC alloc] initWithStyle:UITableViewStylePlain];
        
        ABRecordRef newPerson = ABPersonCreate();
        _ClonePersonProperty(newPerson,person,kABPersonFirstNameProperty);
        _ClonePersonProperty(newPerson,person,kABPersonLastNameProperty);
        _ClonePersonProperty(newPerson,person,kABPersonMiddleNameProperty);
        _ClonePersonProperty(newPerson,person,kABPersonPrefixProperty);
        _ClonePersonProperty(newPerson,person,kABPersonSuffixProperty);
        _ClonePersonProperty(newPerson,person,kABPersonNicknameProperty);
        _ClonePersonProperty(newPerson,person,kABPersonFirstNamePhoneticProperty);
        _ClonePersonProperty(newPerson,person,kABPersonLastNamePhoneticProperty);
        
        pPersonInfoVC->_pGroupsInfo =  pSectionsInfo;
        pPersonInfoVC->_personNewInfoRef =  newPerson;
        pPersonInfoVC->_delegate = delegate;
        
        return pPersonInfoVC;
    }
    
    return nil;
 }

-(void) dealloc{
    CFRelease(_personNewInfoRef);
    _personNewInfoRef = NULL;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    //navigationController被隐藏了
    self.navigationController.navigationBarHidden = NO;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    self.title  =   (__bridge_transfer NSString*) ABRecordCopyCompositeName(_personNewInfoRef);
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem  alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onDone:)];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    //恢复隐藏
    self.navigationController.navigationBarHidden = YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSString*)getPersonName{
    return self.title;
}


-(PersonInfoItem*)getItemFromIndexPath:(NSIndexPath *)indexPath{
    PersonInfoGroup* group = _pGroupsInfo[indexPath.section];
    return (PersonInfoItem*)(group->_pItems[indexPath.row]);
}

-(void)onDone:(id)sender{
    for (PersonInfoGroup* group in _pGroupsInfo) {
        [group setToPerson:_personNewInfoRef];
    }
//    [self.navigationController popViewControllerAnimated:YES];
    
    if(_delegate&&[_delegate respondsToSelector:@selector(ACPersonContactOnDone:)]){
        [_delegate ACPersonContactOnDone:self];
    }
}

-(void) saveVcfFile:(NSString*)pFilePathName{
    CFArrayRef  contacts    =   CFArrayCreate(kCFAllocatorDefault, &_personNewInfoRef, 1,NULL);
    CFDataRef vcards = (CFDataRef)ABPersonCreateVCardRepresentationWithPeople(contacts);
    NSString *vcardString = [[NSString alloc] initWithData:(__bridge NSData *)vcards encoding:NSUTF8StringEncoding];
    [vcardString writeToFile:pFilePathName atomically:YES encoding:NSUTF8StringEncoding error:nil];
    CFRelease(vcards);
    CFRelease(contacts);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _pGroupsInfo.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    PersonInfoGroup* group = _pGroupsInfo[section];
    return group->_pItems.count;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    PersonInfoGroup* group = _pGroupsInfo[section];
    return group->_pLable;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString* pCellIdentifier = @"PersonInfoCell";
    UITableViewCell *cell   =   [tableView dequeueReusableCellWithIdentifier:pCellIdentifier];
    if(nil==cell){
        cell    =   [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:pCellIdentifier];
    }
    
    PersonInfoItem* item =  [self getItemFromIndexPath:indexPath];
    
    cell.textLabel.text         =   item->_pLabel;
    cell.detailTextLabel.text   =   item->_pValue;
    cell.accessoryType          =   item->_bSelected?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell =    [tableView cellForRowAtIndexPath:indexPath];
    PersonInfoItem* item =  [self getItemFromIndexPath:indexPath];
    item->_bSelected    =   !item->_bSelected;
    cell.accessoryType =    item->_bSelected?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
