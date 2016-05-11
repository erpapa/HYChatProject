//
//  HYContactsSearchResultsController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/5.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYContactsSearchResultsController.h"
#import "HYSingleChatViewController.h"
#import "HYContactsViewCell.h"
#import "HYContactsModel.h"
#import "HYSearchController.h"

@interface HYContactsSearchResultsController ()

@end

@implementation HYContactsSearchResultsController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.rowHeight = kContactsViewCellHeight;
}

#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HYContactsModel *model = [self.searchResults objectAtIndex:indexPath.row];
    HYContactsViewCell *cell = [HYContactsViewCell cellWithTableView:tableView];
    cell.model = model;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    HYContactsModel *model = [self.searchResults objectAtIndex:indexPath.row];
    HYSingleChatViewController *singleVC = [[HYSingleChatViewController alloc] init];
    singleVC.chatJid = model.jid;
    singleVC.hidesBottomBarWhenPushed = YES;
    [self.presentingViewController.navigationController pushViewController:singleVC animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
