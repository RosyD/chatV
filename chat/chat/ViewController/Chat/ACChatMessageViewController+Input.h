/**
 处理消息文本输入，录音发送
*/


#import "TPAACAudioConverter.h"
#import "THChatInput.h"


@interface ACChatMessageViewController(Input) <TPAACAudioConverterDelegate,THChatInputDelegate>

-(void)chatInputSetting;
-(void)ACTopicEntityDB_TopicEntityDraft_save:(NSString*) pStr; //保存草稿
-(void)setSendReadCountWithMessage:(ACMessage *)message;
-(void)resendMessage:(ACMessage *)message;
-(void)sendMessageReadedToServer:(long)sendSequence;
-(BOOL)sendFile:(NSString*) strFileName withFileDataBlock:(void (^)(NSString*))pFileDataBlock;



-(void)resignKeyBoard:(id)sender; //隐藏输入界面，包括哪些按钮
-(void)sendMessageSuccessNotification:(NSNotification *)notification;
-(void)sendMessageFailNotification:(NSNotification *)notification;
-(void)keyboardWillShow:(NSNotification *)noti;
-(void)keyboardWillHide:(NSNotification *)noti;
-(void)keyboardInputModeChanged:(NSNotification *)noti;

@end
