@interface ACChatMessageViewController(Tap) <MFMailComposeViewControllerDelegate>

-(void)_displayImageWithFileMessageLoadFromServer:(int)dir
                                     withMsgCache:(ACFileMessageCache*)pMsgCache;
-(int)_displayImageWithFileMessageGetData;
-(NSInteger)_displayImageWithFileMessageFindItem:(ACFileMessageCache*)pMsgCache forInsert:(BOOL)forInsert;


-(void)displayImageWithFileMessage:(ACFileMessage *)fileMessage;

-(void)moviePlayWithFilePath:(NSString *)filePath;

-(void)playAudioWithFilePath:(NSString *)filePath audioMsg:(ACFileMessage *)audioMsg;




-(void)fileBrowserWithFileMsgData:(ACFileMessage *)fileMsg;

//-(void)previewTextWithTextMessage:(ACTextMessage *)textMessage;
-(void)previewText:(NSString*)pText;

-(void)showWhoReadVCWithMsg:(ACMessage*)pMsg;

-(void)openUrl:(NSURL *)url;
-(void)openTel:(NSString*)pTel;
-(void)openMail:(NSString*)mail;

- (void)videoHasFinishedPlaying:(NSNotification *)paramNotification;

@end

extern NSString *const kAudioPlayFinishedNotification;
