//
//  HYNotifactionViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/15.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYNotifactionViewController.h"

@interface HYNotifactionViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation HYNotifactionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *kCellIdentifier=@"kCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if(cell == nil){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
        UISwitch *switchView = [[UISwitch alloc] init];
        [switchView addTarget:self action:@selector(switchChange:) forControlEvents:UIControlEventValueChanged];
        switchView.tag = indexPath.section;
        cell.accessoryView = switchView;
    }
    if (indexPath.section == 0) {
        cell.textLabel.text = @"消息免打扰";
        UISwitch *switchView = (UISwitch *)cell.accessoryView;
        switchView.on = [[NSUserDefaults standardUserDefaults] boolForKey:HYChatShieldNotifaction];
    } else if (indexPath.section == 1) {
        cell.textLabel.text = @"显示预览";
        UISwitch *switchView = (UISwitch *)cell.accessoryView;
        switchView.on = ![[NSUserDefaults standardUserDefaults] boolForKey:HYChatNotShowBody];
    }
    
    return cell;
    
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return @"";
    }
    return @"不使用应用时，显示或隐藏消息提醒和横幅式消息预览。";
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 12.0;
    }
    return 8.0;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)switchChange:(UISwitch *)sender
{
    if (sender.tag == 0) {
        [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:HYChatShieldNotifaction];
    } else if (sender.tag == 1) {
        [[NSUserDefaults standardUserDefaults] setBool:!sender.on forKey:HYChatNotShowBody];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
