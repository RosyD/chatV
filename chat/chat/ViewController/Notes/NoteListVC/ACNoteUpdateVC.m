//
//  ACNoteUpdateVC.m
//  chat
//
//  Created by Aculearn on 14/12/29.
//  Copyright (c) 2014年 Aculearn. All rights reserved.
//

#import "ACNoteUpdateVC.h"
#import "UINavigationController+Additions.h"

@interface ACNoteUpdateVC ()

@property (weak, nonatomic) IBOutlet UIView *navBarView;///导航栏
@property (weak, nonatomic) IBOutlet UIView *navBackView;///导航背景view
@property (weak, nonatomic) IBOutlet UIView *navView;///导航view
@property (weak, nonatomic) IBOutlet UIButton *backBtn;///返回按钮
@property (weak, nonatomic) IBOutlet UIButton *checkBtn;///对勾
@property (weak, nonatomic) IBOutlet UILabel *note;///note
@property (weak, nonatomic) IBOutlet UIImageView *navBackImage;///导航背景

@property (weak, nonatomic) IBOutlet UITextView *textViewForNote;//／正文

@end

@implementation ACNoteUpdateVC

AC_MEM_Dealloc_implementation



- (void)viewDidLoad {
    [super viewDidLoad];
    ///
    [_navBarView setFrame:CGRectMake(0, 0, kScreen_Width, 64)];
    [_navBackView setFrame:CGRectMake(0, 0, kScreen_Width, 64)];
    [_navBackImage setFrame:CGRectMake(0, 0, kScreen_Width, 64)];
    [_navView setFrame:CGRectMake(0, 20, kScreen_Width, 44)];
    [_backBtn setFrame:CGRectMake(5, 0, 44, 44)];
    [_checkBtn setFrame:CGRectMake(kScreen_Width - 44-5, 0, 44, 44)];
    _note.center = CGPointMake(kScreen_Width/2, 22);
    [_textViewForNote setFrame:CGRectMake(0, 64, kScreen_Width, kScreen_Height - 64)];
    
    [self.view bringSubviewToFront:_navBarView];
    
    _textViewForNote.text   =   _superVC.noteMessage.content;

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

//    [nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
//    [nc addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    
    [_textViewForNote becomeFirstResponder];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//-(void)viewDidAppear:(BOOL)animated{
//    [super viewDidAppear:animated];
//    }

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark -keyboardNotification
-(void)keyboardWillShow:(NSNotification *)noti{
    NSDictionary *userInfo      = [noti userInfo];
    NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    // Get the top of the keyboard as the y coordinate of its origin in self's view's coordinate system. The bottom of the text view's frame should align with the top of the keyboard's final position.
//    CGFloat keyboardShowedY = CGRectGetMinY([aValue CGRectValue]);
    
//    ITLogEX(@"%f",keyboardShowedY);
    CGRect frame =  _textViewForNote.frame;
    frame.size.height = CGRectGetMinY([aValue CGRectValue])-frame.origin.y;
    _textViewForNote.frame =    frame;
}



#pragma mark action


- (IBAction)updateNote:(id)sender {
    if(![_superVC.noteMessage.content isEqualToString:_textViewForNote.text]){
        _superVC.noteMessage.content = _textViewForNote.text;
        [_superVC noteContentUpdated];
    }
    [self.navigationController ACpopViewControllerAnimated:YES];
}

- (IBAction)goback:(id)sender {
    [self.navigationController ACpopViewControllerAnimated:YES];
}

@end
