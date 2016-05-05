//
//  HYGroupSearchListController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/5.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYGroupSearchListController.h"
#import "HYGroupListViewCell.h"
#import "HYContactsModel.h"
#import "HYGroupChatViewController.h"

@interface HYGroupSearchListController ()

@end

@implementation HYGroupSearchListController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.rowHeight = kGroupListViewCellHeight;
}

#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HYGroupListViewCell *cell = [HYGroupListViewCell cellWithTableView:tableView];
    HYContactsModel *model = [self.searchResults objectAtIndex:indexPath.row];
    cell.model = model;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    HYContactsModel *model = [self.searchResults objectAtIndex:indexPath.row];
    HYGroupChatViewController *groupVC = [[HYGroupChatViewController alloc] init];
    groupVC.roomJid = model.jid;
    [self.presentingViewController.navigationController pushViewController:groupVC animated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
