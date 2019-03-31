/*
    ChatMessageViewController的发送非文字内容的Msg的功能
    如图片、视频、位置等
 
*/

#import "ACSuit.h"
#import "ACConfigs.h"
#import "ACPersonContactVC.h"
#import "ELCImagePickerController.h"

#define kEmojiBoardHeight           214

#define addBoardItemType_Video_Call_Allow   //允许Video功能呢

enum addBoardItemType
{
    addBoardItemType_Photo = 0,
    addBoardItemType_Camera,
    addBoardItemType_Video,
    addBoardItemType_VCamera,
#ifdef addBoardItemType_Video_Call_Allow
    addBoardItemType_Chat_VideoCall,
    addBoardItemType_Chat_RadioCall,
#endif
    addBoardItemType_Location,
    addBoardItemType_Contact,
    addBoardItemType_Chat_With_Destrct,
    addBoardItemType_Chat_With_Location,
};

@interface ACChatMessageViewController(Borad) <MWPhotoBrowserDelegate,ACPersonContactVC_Delegate,
                                                ABPeoplePickerNavigationControllerDelegate,ELCImagePickerControllerDelegate>

-(void) faceBoardSetting;
-(void) addBoardSetting;


-(void) emojiButtonScrollSetting:(BOOL)isFirst;
-(void) emojiSelectHide;
-(void) sendLocationMessageWithCoordinate:(CLLocationCoordinate2D)coordinate;

-(void) reloadSuit;
-(void) suitChange:(NSNotification *)noti;
-(void) stickerDownloadSuccess:(NSNotification *)noti;


-(void) callBack:(ACMessage*)message;

+(void) callTopic:(ACTopicEntity*)topic forVideoCall:(BOOL)forVideoCall withParentController:(UIViewController*)parent;

@end
