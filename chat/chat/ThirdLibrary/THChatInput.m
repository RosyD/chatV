//
//  Created by Marat Alekperov (aka Timur Harleev) (m.alekperov@gmail.com) on 18.11.12.
//  Copyright (c) 2012 Me and Myself. All rights reserved.
//


#import "THChatInput.h"
#import "UIView+Additions.h"
#import "ACConfigs.h"
#import "ACChatMessageViewController.h"
#import "ACNetCenter.h"
#import "ACVideoCall.h"

@implementation THChatInput

#define THChatInput_Show_SendButton

- (void) composeView {

   //CGSize size = self.frame.size;
    CGSize size = CGSizeMake(kScreen_Width, 55);
    //CGSize size = [[UIScreen mainScreen] bounds].size;
    _inputBackgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
	///_inputBackgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height+2)];
	_inputBackgroundView.autoresizingMask = UIViewAutoresizingNone;
//   _inputBackgroundView.contentMode = UIViewContentModeScaleToFill;
	//_inputBackgroundView.userInteractionEnabled = YES;
   //_inputBackgroundView.alpha = .5;
   _inputBackgroundView.backgroundColor = [UIColor clearColor];
   //_inputBackgroundView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:.5];
	[self addSubview:_inputBackgroundView];
   
	// Text field
    _textView = [[UITextView alloc] initWithFrame:CGRectMake(43.0f, 25, kScreen_Width - 118, 0)];
    _textView.backgroundColor = [UIColor clearColor];
   //_textView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:.3];
	_textView.delegate = self;
    _textView.contentInset = UIEdgeInsetsMake(0, -2, -4, 0);
    _textView.showsVerticalScrollIndicator = NO;
    _textView.showsHorizontalScrollIndicator = NO;
	_textView.font = [UIFont systemFontOfSize:16.0f];
#ifndef THChatInput_Show_SendButton
    _textView.returnKeyType = UIReturnKeySend;
#endif
	[self addSubview:_textView];
   
   [self adjustTextInputHeightForText:@"" animated:NO];
   
   _lblPlaceholder = [[UILabel alloc] initWithFrame:CGRectMake(45.0f, 22, 160, 20)];
   _lblPlaceholder.font = [UIFont systemFontOfSize:16.0f];
    [self setPlaceholderText:nil];
   _lblPlaceholder.textColor = [UIColor lightGrayColor];
   _lblPlaceholder.backgroundColor = [UIColor clearColor];
	[self addSubview:_lblPlaceholder];
    
    // audio button
	_audioButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_audioButton.frame = CGRectMake(2.0f, 12.0f, 35.0f, 35.0f);
	_audioButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
	_audioButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
	_audioButton.titleLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
	[_audioButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
	[_audioButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_audioButton addTarget:self action:@selector(showAudioInput:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:_audioButton];
	
	_emojiButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_emojiButton.frame = CGRectMake(size.width - 72, 12.0f, 35.0f, 35.0f);
	_emojiButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
   [_emojiButton addTarget:self action:@selector(showEmojiInput:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:_emojiButton];
    
    // Attach buttons
	_addButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_addButton.frame = CGRectMake(size.width - 37.0f, 12.0f, 35.0f, 35.0f);
	_addButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [_addButton addTarget:self action:@selector(showAddInput:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:_addButton];
    
    //按住说话
    _pressSayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    ///_pressSayButton.frame = CGRectMake([_audioButton getFrame_right]+1, 10, 210, 42);
    _pressSayButton.frame = CGRectMake([_audioButton getFrame_right]+1, 10,kScreen_Width - 110, 42);
    
	_pressSayButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [_pressSayButton addTarget:self action:@selector(pressSayButtonDown:) forControlEvents:UIControlEventTouchDown];
    [_pressSayButton addTarget:self action:@selector(pressSayButtonUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [_pressSayButton addTarget:self action:@selector(pressSayButtonUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
    [_pressSayButton addTarget:self action:@selector(pressSayButtonDragInside:) forControlEvents:UIControlEventTouchDragInside];
    [_pressSayButton addTarget:self action:@selector(pressSayButtonDragOutside:) forControlEvents:UIControlEventTouchDragOutside];
	[self addSubview:_pressSayButton];
    _pressSayButton.hidden = YES;
    
    [_pressSayButton setTitle:NSLocalizedString(@"Hold_To_Talk", nil) forState:UIControlStateNormal];
    [_pressSayButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_pressSayButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
   
    //Send
#ifdef THChatInput_Show_SendButton
    _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendButton.frame = CGRectMake(_emojiButton.frame.origin.x+4, _emojiButton.frame.origin.y, _addButton.origin.x+_addButton.size.width-_emojiButton.frame.origin.x-8, _emojiButton.frame.size.height);
    _sendButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [_sendButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_sendButton];
    _sendButton.hidden = YES;
    
    [_sendButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_sendButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [_sendButton setBackgroundColor:UIColor_RGB(69, 109, 225)];
    [_sendButton setRectRound:5];
    [_sendButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
#endif
    
   [self sendSubviewToBack:_inputBackgroundView];
}

-(void) setPlaceholderText:(NSString*)pPlaceholderText{
    _lblPlaceholder.text = pPlaceholderText?pPlaceholderText:NSLocalizedString(@"Input_Message", nil);
}

- (void) awakeFromNib {
   [super awakeFromNib];
   _inputHeight = 38.0f;
   _inputHeightWithShadow = 44.0f;
   _autoResizeOnKeyboardVisibilityChanged = YES;

   [self composeView];
}

- (void) setForSimpleInput{
    
    _isSimpleInput  =   YES;
    _audioButton.hidden = YES;
    _addButton.hidden = YES;
    _emojiButton.hidden = YES;
    _pressSayButton.hidden = YES;
    _inputBackgroundView.image = [[UIImage imageNamed:@"NoteCommentInputBK.png"] stretchableImageWithLeftCapWidth:35 topCapHeight:22];
    [_lblPlaceholder setFrame_x:26];
    
    
    CGRect textRect =   _textView.frame;
    _textView.frame = CGRectMake(25.0f, 25, textRect.size.width+textRect.origin.x-25, textRect.size.height);
    
    _sendButton.hidden = NO;
    [self showOrHideSendButton];
}


- (void) adjustTextInputHeightForText:(NSString*)text animated:(BOOL)animated {
    if ([text length] == 0)
    {
        text =@"哇";
    }
   int h1 = [text sizeWithFont:_textView.font].height;
   int h2 = [text sizeWithFont:_textView.font constrainedToSize:CGSizeMake(_textView.frame.size.width - 16, 52.0f) lineBreakMode:(NSLineBreakMode)UILineBreakModeWordWrap].height;
   
   [UIView animateWithDuration:(animated ? .1f : 0) animations:^
    {
       int h = (h2 == h1 ? _inputHeightWithShadow : h2 + 28) + 8;
       int delta = h - self.frame.size.height;
       ///CGRect r2 = CGRectMake(0, self.frame.origin.y - delta, self.frame.size.width, h);
     ///输入框字的最大宽度
        CGRect r2 = CGRectMake(0, self.frame.origin.y - delta, kScreen_Width, h);
        
        
       self.frame = r2; //CGRectMake(0, self.frame.origin.y - delta, self.superview.frame.size.width, h);
       //_inputBackgroundView.frame = CGRectMake(0, 0, self.frame.size.width, h+2);
        
        _inputBackgroundView.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, h+2);
       
       CGRect r = _textView.frame;
       r.origin.y = 14;
       r.size.height = h - 18;
       _textView.frame = r;
       
    } completion:^(BOOL finished)
    {
       //
    }];
}

- (id) initWithFrame:(CGRect)frame {
   
   self = [super initWithFrame:frame];
   
   if (self)
   {
      _inputHeight = 38.0f;
      _inputHeightWithShadow = 44.0f;
      _autoResizeOnKeyboardVisibilityChanged = YES;
      
      [self composeView];
   }
   return self;
}

- (void) fitText {
   
   [self adjustTextInputHeightForText:_textView.text animated:YES];
}

-(void)showOrHideSendButton{
    BOOL bHideSendButton    =   _textView.text.length > 0;
#ifdef THChatInput_Show_SendButton
    if(_isSimpleInput){
        _lblPlaceholder.hidden  =   bHideSendButton;
        _sendButton.enabled =   bHideSendButton;
    }
    else{
        _lblPlaceholder.hidden  =   _emojiButton.hidden     =   _addButton.hidden = bHideSendButton;
        _sendButton.hidden      =   !bHideSendButton;
    }
#else
    _lblPlaceholder.hidden  =   bHideSendButton;
#endif
}

- (void) setText:(NSString*)text {
   _textView.text = text;
   [self showOrHideSendButton];
   [self fitText];
}


#pragma mark UITextFieldDelegate Delegate

- (void) textViewDidBeginEditing:(UITextView*)textView {
    _inputType = inputType_Text;
   if (_autoResizeOnKeyboardVisibilityChanged)
   {
       if (!_inputState)
       {
           _inputState = YES;
           [UIView animateWithDuration:0.2f animations:^{
              /// int y = ([ACConfigs isPhone5]?504:504-88)-216-self.size.height;
               int y = kScreen_Height-64-216-self.size.height;
               if (((ACChatMessageViewController *)_delegate).isOpenHotspot)
               {
                   y -= 20;
               }
               [self setFrame_y:y];
           }];
       }
      

      [self fitText];
   }
   if ([_delegate respondsToSelector:@selector(textViewDidBeginEditing:)])
      [_delegate performSelector:@selector(textViewDidBeginEditing:) withObject:textView];
}

- (void) textViewDidEndEditing:(UITextView*)textView {
   
   if (_autoResizeOnKeyboardVisibilityChanged)
   {
//      [UIView animateWithDuration:.25f animations:^{
//         CGRect r = self.frame;
//         r.origin.y += 216;
//         [self setFrame:r];
//          
//      }];
      
      [self fitText];
   }
    [self showOrHideSendButton];
   
   if ([_delegate respondsToSelector:@selector(textViewDidEndEditing:)])
      [_delegate performSelector:@selector(textViewDidEndEditing:) withObject:textView];
}

- (BOOL) textView:(UITextView*)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString*)text {
   
    if ([text isEqualToString:@""] && range.length != 0)//删除
    {
        NSString *inputString = textView.text;
        NSString *string = nil;
        NSInteger stringLength = inputString.length;
        if (stringLength > 0)
        {
            // 去表情
            if ([@"]" isEqualToString:[inputString substringFromIndex:stringLength-1]])
            {
                if ([inputString rangeOfString:@"["].location == NSNotFound)
                {
                    string = [inputString substringToIndex:stringLength - 1];
                }
                else
                {
                    string = [inputString substringToIndex:[inputString rangeOfString:@"[" options:NSBackwardsSearch].location];
                }
                textView.text = string;
                return NO;
            }
        }
        
        return YES;
    }
    else if (![text isEqualToString:@""] && range.length == 0)//增加
    {
#ifndef THChatInput_Show_SendButton
        if ([text isEqualToString:@"\n"])
        {
            [self sendButtonPressed:nil];
            return NO;
        }
        else
#endif
        {
            // 当前内容长度
            NSString *content = [textView text];
            NSInteger contentLength = (content != nil) ? [content length] : 0;
            
            // 计算总长度
            NSInteger totalLength = contentLength + [text length];
            if(totalLength > kChatMessageMaxLength)
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil)
                                                                    message:NSLocalizedString(@"Can't_Input_More", nil)
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles: nil];
                [alertView show];
                return NO;
            }
            else
            {
                [self adjustTextInputHeightForText:[NSString stringWithFormat:@"%@%@", _textView.text, text] animated:YES];
            }
        }
    }
    return YES;
}

- (void) textViewDidChange:(UITextView*)textView {
   
    [self showOrHideSendButton];
    
    [self fitText];
   
   if ([_delegate respondsToSelector:@selector(textViewDidChange:)])
      [_delegate performSelector:@selector(textViewDidChange:) withObject:textView];
}


#pragma mark THChatInput Delegate
-(void)showAudioInput:(id)sender
{
    _pressSayButton.hidden = !_pressSayButton.hidden;
    if (_pressSayButton.hidden){
        if (_textString){
            [self setText:_textString];
            self.textString = nil;
        }
        [_textView becomeFirstResponder];
    }
    else
    {
        if([ACVideoCall inVideoCallAndShowTip]){
            _pressSayButton.hidden = YES;
            return;
        }
        _inputType = inputType_Audio;
        self.textString = _textView.text;
        [self setText:nil];
        [_textView resignFirstResponder];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.25];
        [UIView setAnimationCurve:7];
        
  ///解决点击语音按钮，chatview上调问题
//        int y = ([ACConfigs isPhone5]?504:504-88)-self.size.height;
        int y = kScreen_Height - 64 - self.size.height;
        if (((ACChatMessageViewController *)_delegate).isOpenHotspot)
        {
            y -= 20;
        }
        [self setFrame_y:y];
        
        [UIView commitAnimations];
    }
    if ([_delegate respondsToSelector:@selector(showAudioInput:)])
    {
        [_delegate performSelector:@selector(showAudioInput:) withObject:sender];
    }
}

-(void)pressSayButtonDown:(id)sender
{
    if([ACVideoCall inVideoCallAndShowTip]){
        return;
    }
    
    _isDragOut = NO;
    if ([_delegate respondsToSelector:@selector(pressSayButtonDown:)])
    {
        [_delegate performSelector:@selector(pressSayButtonDown:) withObject:sender];
    }
    [_pressSayButton setTitle:NSLocalizedString(@"Take_Off_Send", nil) forState:UIControlStateNormal];
}

-(void)pressSayButtonUpInside:(id)sender
{
    if ([_delegate respondsToSelector:@selector(pressSayButtonUpInside:)])
    {
        [_delegate performSelector:@selector(pressSayButtonUpInside:) withObject:sender];
    }
    [_pressSayButton setTitle:NSLocalizedString(@"Hold_To_Talk", nil) forState:UIControlStateNormal];
}

-(void)pressSayButtonUpOutside:(id)sender
{
    if ([_delegate respondsToSelector:@selector(pressSayButtonUpOutside:)])
    {
        [_delegate performSelector:@selector(pressSayButtonUpOutside:) withObject:sender];
    }
    [_pressSayButton setTitle:NSLocalizedString(@"Hold_To_Talk", nil) forState:UIControlStateNormal];
}

-(void)pressSayButtonDragInside:(id)sender
{
    if ([_delegate respondsToSelector:@selector(pressSayButtonDragInside:)])
    {
        [_delegate performSelector:@selector(pressSayButtonDragInside:) withObject:sender];
    }
    if (_isDragOut)
    {
        _isDragOut = NO;
        [_pressSayButton setTitle:NSLocalizedString(@"Take_Off_Send", nil) forState:UIControlStateNormal];
    }
}

-(void)pressSayButtonDragOutside:(id)sender
{
    _isDragOut = YES;
    if ([_delegate respondsToSelector:@selector(pressSayButtonDragOutside:)])
    {
        [_delegate performSelector:@selector(pressSayButtonDragOutside:) withObject:sender];
    }
    [_pressSayButton setTitle:NSLocalizedString(@"Hold_To_Talk", nil) forState:UIControlStateNormal];
}

//键盘点发送时执行
- (void) sendButtonPressed:(id)sender
{
    [_textView  unmarkText]; //防止中文输入法出错
    
//    NSLog(@"%@",_textView.text);
//    _textView.text = @"";

   if ([_delegate respondsToSelector:@selector(sendButtonPressed:)])
       [_delegate performSelector:@selector(sendButtonPressed:) withObject:sender];
    
    [self showOrHideSendButton];
    [self fitText];
}

- (void) showEmojiInput:(id)sender
{
    _pressSayButton.hidden = YES;
    if (_textString)
    {
        [self setText:_textString];
        self.textString = nil;
    }
    
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSArray *suitArray = [(ACChatMessageViewController *)_delegate ];//[defaults objectForKey:kDownloadSuitList];
//    if ([suitArray count] == 0)
//    {
//        if ([_delegate respondsToSelector:@selector(showStickerShop:)])
//        {
//            if ([_textView isFirstResponder] == YES) [_textView resignFirstResponder];
//            
//            [_delegate performSelector:@selector(showStickerShop:) withObject:sender];
//        }
//    }
//    else
    if ([_delegate respondsToSelector:@selector(showEmojiInput:)])
    {
        [_delegate performSelector:@selector(showEmojiInput:) withObject:sender];
    }
}

- (void) showAddInput:(id)sender
{
    _pressSayButton.hidden = YES;
    if (_textString)
    {
        [self setText:_textString];
        self.textString = nil;
    }
    if (_inputType != inputType_Add)
    {
        _inputType = inputType_Add;
        if ([_delegate respondsToSelector:@selector(showAddInput:)])
        {
            if ([_textView isFirstResponder] == YES) [_textView resignFirstResponder];
            
            [_delegate performSelector:@selector(showAddInput:) withObject:sender];
        }
    }
}

@end
