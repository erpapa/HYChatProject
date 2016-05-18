//
//  HYFirstLoginViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/4/22.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYFirstLoginViewController.h"
#import "HYLoginViewController.h"
#import "HYRegisterViewController.h"
#import "YYImage.h"

@interface HYFirstLoginViewController ()

@property (weak, nonatomic) IBOutlet UIButton *LoginBtn;
@property (weak, nonatomic) IBOutlet UIButton *registerBtn;
@property (strong, nonatomic) YYAnimatedImageView *imageView;

@end

@implementation HYFirstLoginViewController

/**
 *  从storyBord加载
 */
+ (instancetype)firstLoginViewController
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    HYFirstLoginViewController *currentLoginVC = [storyboard instantiateViewControllerWithIdentifier:@"firstLoginVC"];
    return currentLoginVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.LoginBtn.layer.cornerRadius = 5;
    self.LoginBtn.layer.masksToBounds = YES;
    self.registerBtn.layer.cornerRadius = 5;
    self.registerBtn.layer.masksToBounds = YES;
    
    self.imageView = [[YYAnimatedImageView alloc] initWithFrame:CGRectMake(0, 64, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds) * 0.75)];
    YYImage *image = [YYImage imageNamed:@"firstLogin"];
    self.imageView.image = image;
    [self.view addSubview:self.imageView];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
