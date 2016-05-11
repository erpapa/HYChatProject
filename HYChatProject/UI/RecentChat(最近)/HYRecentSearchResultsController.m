//
//  HYRecentSearchResultsController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/5.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYRecentSearchResultsController.h"
#import "HYRecentChatViewCell.h"
#import "HYRecentChatModel.h"
#import "HYSingleChatViewController.h"
#import "HYGroupChatViewController.h"
#import "HYSearchController.h"

@interface HYRecentSearchResultsController ()

@end

@implementation HYRecentSearchResultsController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.rowHeight = kRecentChatViewCellHeight;
}

#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HYRecentChatModel *chatModel = [self.searchResults objectAtIndex:indexPath.row];
    HYRecentChatViewCell *cell = [HYRecentChatViewCell cellWithTableView:tableView];
    cell.chatModel = chatModel;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    HYRecentChatModel *chatModel = [self.searchResults objectAtIndex:indexPath.row];
    if (chatModel.isGroup) { // 群聊
        HYGroupChatViewController *groupVC = [[HYGroupChatViewController alloc] init];
        groupVC.roomJid = chatModel.jid;
        groupVC.hidesBottomBarWhenPushed = YES; // 隐藏tabBar
        [self.presentingViewController.navigationController pushViewController:groupVC animated:YES];
    }else{
        HYSingleChatViewController *singleVC = [[HYSingleChatViewController alloc] init];
        singleVC.chatJid = chatModel.jid;
        singleVC.hidesBottomBarWhenPushed = YES; // 隐藏tabBar
        [self.presentingViewController.navigationController pushViewController:singleVC animated:YES];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
