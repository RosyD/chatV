//
//  ACPicSendController.m
//  chat
//
//  Created by 李朝霞 on 2017/5/16.
//  Copyright © 2017年 李朝霞. All rights reserved.
//

#import "ACPicSendController.h"


@interface ACPicSendController ()

@property(assign,nonatomic)int tempPicNum;

@end

@implementation ACPicSendController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
    
    UIView* viewSe = [[UIView alloc]init];
    viewSe.backgroundColor = [UIColor whiteColor];
    viewSe.layer.cornerRadius = 10;
    [self.view addSubview:viewSe];
    [viewSe setFrame:CGRectMake(70 , (self.view.frame.size.height - 152)/2, self.view.frame.size.width - 140, 152)];
    
    NSLog(@"%@",NSStringFromCGRect(self.view.frame));
    
    //获取通知中心单例对象
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    //添加当前类对象为一个观察者，name和object设置为nil，表示接收一切通知
    [center addObserver:self selector:@selector(notice:) name:@"progress" object:nil];

//    标题
    self.nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(50, 10, viewSe.frame.size.width - 100, 40)];
    //    [self.nameLabel setCenter:CGPointMake(viewSe.center.x, 30)];
//    [self.nameLabel setPreferredMaxLayoutWidth:viewSe.frame.size.width];
    self.nameLabel.text = NSLocalizedString(@"Sending", nil);
    self.nameLabel.textColor = [UIColor blackColor];
    self.nameLabel.font = [UIFont systemFontOfSize:18];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    [viewSe addSubview:self.nameLabel];
    
//    进度条
    self.progressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
    [viewSe addSubview:self.progressView];
    [self.progressView setFrame:CGRectMake(50, 60, viewSe.frame.size.width - 100, 2)];
    //设置进度条颜色
    _progressView.trackTintColor = [UIColor lightGrayColor];
    //设置进度默认值，这个相当于百分比，范围在0~1之间，不可以设置最大最小值
    //设置进度条上进度的颜色
    _progressView.progressTintColor = [UIColor blueColor];
    //设置进度值并动画显示
//    [_progressView setProgress:0.7 animated:YES];
    
//    图片数量
    self.numLable = [[UILabel alloc]initWithFrame:CGRectMake(50, 72, viewSe.frame.size.width - 100, 30)];
    self.numLable.text = self.picnum;
    self.numLable.textColor = [UIColor darkGrayColor];
    self.numLable.font = [UIFont systemFontOfSize:15];
    self.numLable.textAlignment = NSTextAlignmentCenter;
    [viewSe addSubview:self.numLable];
    
    //分界线
    self.lineView = [[UIView alloc]init];
    [viewSe addSubview:self.lineView];
    [self.lineView setFrame:CGRectMake(0, 110 , viewSe.frame.size.width, 1)];
    self.lineView.backgroundColor = [UIColor lightGrayColor];
    
//    隐藏按钮
    self.btn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.btn.frame = CGRectMake(0, 112, viewSe.frame.size.width, 38);
    [self.btn setTitle:NSLocalizedString(@"Hide", nil) forState:UIControlStateNormal];
    self.btn.titleLabel.font = [UIFont systemFontOfSize:18];
//    self.btn.backgroundColor = [UIColor grayColor];
    self.btn.showsTouchWhenHighlighted = YES;
    [self.btn addTarget:self action:@selector(btnTouch) forControlEvents:UIControlEventTouchUpInside];
    [viewSe addSubview:self.btn];
    
}

-(void)notice:(NSNotification*)sender{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        CGFloat pro = [[sender.userInfo objectForKey:@"1"]floatValue];
        
      
        
        if (_picn == 1) {
            
            [self.progressView setProgress:pro animated:YES];
            
        }else{
            
            if ( _tempPicNum < _picn -1 && self.progressView.progress < pro*0.9 ) {
                
                [self.progressView setProgress:pro*0.9 animated:YES];
                
            }else if(_tempPicNum == _picn - 1){
                
                NSLog(@"%D",_tempPicNum);
                
                if (self.progressView.progress < pro ) {
                    
                    [self.progressView setProgress:pro animated:YES];

                }
             
            }else  if (pro == 1 && _tempPicNum == _picn){
                    
                    [self.shareVc.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                    
                }
          
        }
        
          if (pro == 1) {
            _tempPicNum = _tempPicNum + 1;
            
        }
        
    });


}

- (void)btnTouch
{
//    [self dismissViewControllerAnimated:YES completion:nil];
//    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil ];
    
    [self.shareVc.extensionContext completeRequestReturningItems:@[] completionHandler:nil];

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

@end
