//
//  HYPhotoSettingViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/15.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYPhotoSettingViewController.h"
#import "HYVideosViewController.h"

@interface HYPhotoSettingViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation HYPhotoSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *kCellIdentifier=@"kCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if(cell == nil){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kCellIdentifier];
    }
    if (indexPath.row == 0) {
        cell.textLabel.text = @"视频短片";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.textLabel.text = @"即拍即存";
        UISwitch *switchView = [[UISwitch alloc] init];
        [switchView addTarget:self action:@selector(switchChange:) forControlEvents:UIControlEventValueChanged];
        switchView.on = [[NSUserDefaults standardUserDefaults] boolForKey:HYChatSaveWhenTakePhoto];
        cell.accessoryView = switchView;
    }
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 12.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"将新拍的照片保存到相机胶卷。";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        HYVideosViewController *videosVC = [[HYVideosViewController alloc] init];
        [self.navigationController pushViewController:videosVC animated:YES];
    }
}


- (void)switchChange:(UISwitch *)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:HYChatSaveWhenTakePhoto];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
