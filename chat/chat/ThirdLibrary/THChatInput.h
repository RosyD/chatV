//
//  Created by Marat Alekperov (aka Timur Harleev) (m.alekperov@gmail.com) on 18.11.12.
//  Copyright (c) 2012 Me and Myself. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol THChatInputDelegate <NSObject>

@optional

-(void)showAudioInput:(id)sender;

-(void)pressSayButtonDown:(id)sender;

-(void)pressSayButtonUpInside:(id)sender;

-(void)pressSayButtonUpOutside:(id)sender;

- (void) sendButtonPressed:(id)sender;

- (void) showEmojiInput:(id)sender;

- (void) showAddInput:(id)sender;

- (void) showStickerShop:(id)sender;

@end

enum inputType
{
    inputType_Text,
    inputType_Audio,
    inputType_Emoji,
    inputType_Add,
};

@interface THChatInput : UIView <UITextViewDelegate> {
    BOOL _isDragOut;
    BOOL _isSimpleInput; //是简单的，普通的输入界面，不显示audioButton,addButton,emojiButton,pressSayButton
}
@property (assign) IBOutlet id<THChatInputDelegate> delegate;

@property (assign) int inputHeight;
@property (assign) int inputHeightWithShadow;
@property (assign) BOOL autoResizeOnKeyboardVisibilityChanged;

@property (strong, nonatomic) UIButton* audioButton;
@property (strong, nonatomic) UIButton* addButton;
@property (strong, nonatomic) UIButton* emojiButton;
@property (retain, nonatomic) UIButton* pressSayButton;
@property (retain, nonatomic) UIButton* sendButton;
@property (strong, nonatomic) UITextView* textView;
@property (strong, nonatomic) UILabel* lblPlaceholder;
@property (strong, nonatomic) UIImageView* inputBackgroundView;
@property (assign) BOOL             inputState;
@property (assign) enum inputType   inputType;
@property (strong, nonatomic) NSString  *textString;

- (void) setForSimpleInput;

- (void) fitText;

- (void) setText:(NSString*)text;

- (BOOL) textView:(UITextView*)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString*)text;

-(void) setPlaceholderText:(NSString*)pPlaceholderText;

@end
