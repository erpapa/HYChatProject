//
//  HYHelpDetailViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/6/2.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYHelpDetailViewController.h"
#import "YYText.h"

@interface HYHelpDetailViewController ()

@end

@implementation HYHelpDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSMutableAttributedString *text = [NSMutableAttributedString new];
    if ([self.title isEqualToString:@"聊天服务器"]) {
        NSMutableAttributedString *server = [[NSMutableAttributedString alloc] initWithString:@"客户端默认服务器地址：erpapa.cn。"];
        server.yy_font = [UIFont systemFontOfSize:17];
        server.yy_color = [UIColor blackColor];
        [text appendAttributedString:server];
        
    } else if ([self.title isEqualToString:@"用户帐号"]) {
        NSMutableAttributedString *account = [[NSMutableAttributedString alloc] initWithString:@"客户端支持两种帐号格式：\n\t1.node;\n\t2.node@domain。\n\t其中，node是节点，domain为域名。\n\t在不指定domain(域名)的情况下，使用默认服务器地址：erpapa.cn。\n\t如果需要使用自己的聊天服务器，则需要指定domain。"];
        account.yy_font = [UIFont systemFontOfSize:17];
        account.yy_color = [UIColor blackColor];
        [text appendAttributedString:account];
    } else if ([self.title isEqualToString:@"二维码"]) {
        NSMutableAttributedString *qrcode = [[NSMutableAttributedString alloc] initWithString:@"\t二维码帐号格式为node@domain，不能识别不符合本格式的地址。"];
        qrcode.yy_font = [UIFont systemFontOfSize:17];
        qrcode.yy_color = [UIColor blackColor];
        [text appendAttributedString:qrcode];
    }
    YYLabel *label = [[YYLabel alloc] initWithFrame:CGRectMake(12, 74, CGRectGetWidth(self.view.bounds) - 24, CGRectGetHeight(self.view.bounds) - 74)];
    label.attributedText = text;
    label.textAlignment = NSTextAlignmentLeft;
    label.textVerticalAlignment = YYTextVerticalAlignmentTop;
    label.numberOfLines = 0;
    [self.view addSubview:label];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
