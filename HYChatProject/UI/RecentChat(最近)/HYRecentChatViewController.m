//
//  HYRecentContactsViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/3/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYRecentChatViewController.h"
#import "HYRecentChatViewCell.h"
#import "HYRecentChatModel.h"

@interface HYRecentChatViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *dataSource;
@end

@implementation HYRecentChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
//    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.rowHeight = 72;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
}

#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HYRecentChatViewCell *cell = [HYRecentChatViewCell cellWithTableView:tableView];
    cell.leftButtons = [self leftButtons];
    cell.rightButtons = [self rightButtons];
    cell.allowsButtonsWithDifferentWidth = YES;
    cell.textLabel.text = [self.dataSource objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
}

- (NSArray *)leftButtons
{
    NSMutableArray *result = [NSMutableArray array];
    MGSwipeButton * button = [MGSwipeButton buttonWithTitle:@"置顶"  backgroundColor:[UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0] padding:15.0 callback:^BOOL(MGSwipeTableCell * sender){
        return YES;
    }];
    [result addObject:button];
    return result;
}

- (NSArray *)rightButtons
{
    NSMutableArray *result = [NSMutableArray array];
    MGSwipeButton *delButton = [MGSwipeButton buttonWithTitle:@"删除"  backgroundColor:[UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f] padding:15.0 callback:^BOOL(MGSwipeTableCell * sender){
        return YES;
    }];
    MGSwipeButton *button = [MGSwipeButton buttonWithTitle:@"标为未读"  backgroundColor:[UIColor orangeColor] padding:10.0 callback:^BOOL(MGSwipeTableCell * sender){
        return YES;
    }];
    [result addObject:delButton];
    [result addObject:button];
    
    return result;
}

// 懒加载
- (NSMutableArray *)dataSource
{
    if (_dataSource == nil) {
        _dataSource = [NSMutableArray arrayWithObjects:@"1",@"2",@"3",@"4",@"5", nil];
    }
    return _dataSource;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
