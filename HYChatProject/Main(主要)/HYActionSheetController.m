//
//  HYActionSheetViewController.m
//  colorv
//
//  Created by erpapa on 16/3/30.
//  Copyright © 2016年 apple. All rights reserved.
//

#import "HYActionSheetController.h"
#define kButtonH 46
#define kTitleBorder 20
#define kTitleFont [UIFont systemFontOfSize:14]

@interface HYActionSheetController ()
@property (strong, nonatomic) UIButton *maskView;
@property (strong, nonatomic) UIView *actionView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) NSMutableArray *actionArray;
@end

@implementation HYActionSheetController

- (instancetype)init
{
    self = [self initWithTitle:nil];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title
{
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;// 半透明
        self.title = title;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // 1.背景view
    self.maskView = [[UIButton alloc] initWithFrame:self.view.bounds];
    self.maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.15];
    [self.maskView addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.maskView];
    
    // 2.actionView
    NSInteger count = self.actionArray.count;
    CGFloat footerW = CGRectGetWidth(self.view.bounds);
    CGFloat footerH = [self titleHeight] + (kButtonH + 1) * count + 7 + kButtonH;
    CGFloat footerX = 0;
    CGFloat footerY = CGRectGetHeight(self.view.bounds);
    self.actionView = [[UIView alloc] initWithFrame:CGRectMake(footerX, footerY, footerW, footerH)];
    self.actionView.backgroundColor = [UIColor colorWithRed:234/255.0 green:234/255.0 blue:234/255.0 alpha:1.0f];
    [self.view addSubview:self.actionView];

    // 3.提示
    CGFloat titleHeight = [self titleHeight];
    if (titleHeight) {
        UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, footerW, titleHeight - 1)];
        titleView.backgroundColor = [UIColor whiteColor];
        [self.actionView addSubview:titleView];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kTitleBorder, 0, CGRectGetWidth(titleView.frame) - kTitleBorder * 2, titleHeight - 1)];
        self.titleLabel.textColor = [UIColor grayColor];
        self.titleLabel.text = self.title;
        self.titleLabel.font = kTitleFont;
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [titleView addSubview:self.titleLabel];
    }
    
    // 4.actionButton
    CGFloat buttonY = titleHeight;
    for (NSInteger index = 0; index < count; index++) {
        NSDictionary *dict = [self.actionArray objectAtIndex:index];
        NSString *title = [dict objectForKey:@"title"];
        buttonY = (kButtonH + 1) * index + titleHeight;
        UIButton *actionButton = [[UIButton alloc] initWithFrame:CGRectMake(0, buttonY, footerW, kButtonH)];
        actionButton.backgroundColor = [UIColor whiteColor];
//        NSString *colorStr = [dict objectForKey:@"colorStr"];
//        UIColor *titleColor = [HYUtils colorFromString:colorStr];
        [actionButton setTitleColor:[dict objectForKey:@"titleColor"] forState:UIControlStateNormal];
        actionButton.tag = index;
        actionButton.titleLabel.font = [UIFont systemFontOfSize:17];
        [actionButton setTitle:title forState:UIControlStateNormal];
        [actionButton addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.actionView addSubview:actionButton];
    }
    
    // 4.取消按钮
    self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.actionView.bounds) - kButtonH, footerW, kButtonH)];
    self.cancelButton.backgroundColor = [UIColor whiteColor];
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:17];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self.actionView addSubview:self.cancelButton];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [UIView animateWithDuration:0.25f animations:^{
        self.actionView.transform = CGAffineTransformMakeTranslation(0, -CGRectGetHeight(self.actionView.bounds));
    }];
}

- (void)buttonClick:(UIButton *)sender
{
    NSDictionary *dict = [self.actionArray objectAtIndex:sender.tag];
    HYActionBlock block = [dict objectForKey:@"block"];
    [self dismissViewControllerAnimated:NO completion:^{
        block();
    }];
}


- (void)addActionTitle:(NSString *)title withBlock:(HYActionBlock)block
{
    [self addActionTitle:title andColor:[UIColor blackColor] withBlock:block];
}

- (void)addActionTitle:(NSString *)title andColor:(UIColor *)titleColor withBlock:(HYActionBlock)block
{
//    NSString *colorStr = [HYUtils stringFromColor:titleColor];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:title forKey:@"title"];
    [dict setObject:titleColor forKey:@"titleColor"];
    [dict setObject:block forKey:@"block"];
    [self.actionArray addObject:dict];
}

- (CGFloat)titleHeight
{
    if (self.title.length == 0) {
        return 0;
    }
    CGFloat titleWidth = CGRectGetWidth(self.view.bounds) - kTitleBorder * 2;
    NSDictionary *attrs = @{NSFontAttributeName:kTitleFont};
    CGSize size = [self.title boundingRectWithSize:CGSizeMake(titleWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
    return size.height + 36;
}

- (NSMutableArray *)actionArray
{
    if (_actionArray == nil) {
        _actionArray = [NSMutableArray array];
    }
    return _actionArray;
}

- (void)dismiss
{
    [UIView animateWithDuration:0.25f animations:^{
        self.actionView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
