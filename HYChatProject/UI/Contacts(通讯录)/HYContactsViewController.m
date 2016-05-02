//
//  HYContactsViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/3/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "HYContactsViewController.h"
#import "HYContactsViewCell.h"
#import "HYContactsHeaderView.h"
#import "HYContacts.h"
#import "HYContactsModel.h"
#import "HYSearchBar.h"
#import "HYXMPPManager.h"
#import "HYLoginInfo.h"
#import "HYSingleChatViewController.h"
#import "HYNewFriendViewController.h"
#import "HYGroupListViewController.h"
#import "HYSearchDisplayController.h"
#import "HYAddFriendViewController.h"
#import "HYScanQRCodeViewController.h"

@interface HYContactsViewController ()<UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate,HYSearchBarDelegate>
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *dataSource;
@property (nonatomic,strong) NSFetchedResultsController *resultController;//查询结果集合

@end

@implementation HYContactsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    // 1.tableView
    self.tableView.tableHeaderView = [self tableHeaderView];
    [self.view addSubview:self.tableView];
    // 2.添加联系人
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addContacts:)];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.dataSource.count == 0) {
        // 加载好友列表
        [self loadContacts];
    }
}

- (UIView *)tableHeaderView
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44 + kContactsViewCellHeight * 2)];
    headerView.backgroundColor = [UIColor whiteColor];
    // 1.搜索
    HYSearchBar *searchBar = [[HYSearchBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44)];
    searchBar.delegate = self;
    [headerView addSubview:searchBar];
    
    CGFloat margin = 6.0;
    CGFloat panding = 8.0;
    CGFloat iconViewW = kContactsViewCellHeight - margin * 2;
    // 2.新朋友
    UIImageView *iconView0 = [[UIImageView alloc] initWithFrame:CGRectMake(panding, CGRectGetMaxY(searchBar.frame) + margin, iconViewW, iconViewW)];
    iconView0.layer.cornerRadius = iconViewW * 0.5;
    iconView0.layer.masksToBounds = YES;
    [headerView addSubview:iconView0];
    
    CGFloat labelX = CGRectGetMaxX(iconView0.frame) + panding;
    UILabel *label0 = [[UILabel alloc] initWithFrame:CGRectMake(labelX, CGRectGetMaxY(searchBar.frame), kScreenW - labelX, kContactsViewCellHeight)];
    label0.font = [UIFont systemFontOfSize:18];
    label0.text = @"新朋友";
    [headerView addSubview:label0];
    
    UIButton *button0 = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetMinY(label0.frame), kScreenW, kContactsViewCellHeight)];
    button0.tag = 0;
    [button0 setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRed:200/255.0 green:200/255.0 blue:212/255.0 alpha:0.2f]] forState:UIControlStateHighlighted];
    [button0 addTarget:self action:@selector(headerButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:button0];
    
    UIView *line0 = [[UIView alloc] initWithFrame:CGRectMake(labelX, CGRectGetMaxY(label0.frame) - 1, kScreenW - labelX, 1)];
    line0.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0f];
    [headerView addSubview:line0];
    
    // 3.群聊
    UIImageView *iconView1 = [[UIImageView alloc] initWithFrame:CGRectMake(panding, CGRectGetMaxY(line0.frame) + margin, iconViewW, iconViewW)];
    iconView1.layer.cornerRadius = iconViewW * 0.5;
    iconView1.layer.masksToBounds = YES;
    [headerView addSubview:iconView1];
    
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(labelX, CGRectGetMaxY(line0.frame), kScreenW - labelX, kContactsViewCellHeight)];
    label1.font = [UIFont systemFontOfSize:18];
    label1.text = @"群聊";
    [headerView addSubview:label1];
    
    UIButton *button1 = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetMinY(label1.frame), kScreenW, kContactsViewCellHeight)];
    button1.tag = 1;
    [button1 setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRed:200/255.0 green:200/255.0 blue:212/255.0 alpha:0.2f]] forState:UIControlStateHighlighted];
    [button1 addTarget:self action:@selector(headerButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:button1];
    
    return headerView;
}

#pragma mark - UITableViewDatasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    HYContacts *contacts = [self.dataSource objectAtIndex:section];
    return contacts.infoArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HYContacts *contacts = [self.dataSource objectAtIndex:indexPath.section];
    HYContactsModel *model = [contacts.infoArray objectAtIndex:indexPath.row];
    HYContactsViewCell *cell = [HYContactsViewCell cellWithTableView:tableView];
    cell.rightButtons = [self rightButtons];
    cell.allowsButtonsWithDifferentWidth = YES;
    cell.model = model;
    return cell;
}

#pragma mark - section头部
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    static NSString *kContactsHeaderIdentifier = @"kContactsHeaderIdentifier";
    HYContactsHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kContactsHeaderIdentifier];
    if (headerView == nil) {
        headerView = [[HYContactsHeaderView alloc] initWithReuseIdentifier:kContactsHeaderIdentifier];
    }
    HYContacts *contacts = [self.dataSource objectAtIndex:section];
    headerView.title = contacts.title;
    return headerView;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    HYContacts *contact = [self.dataSource objectAtIndex:section];
//    return contact.title;
//}

#pragma mark - 返回索引数组
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSMutableArray *array = [NSMutableArray array];
    [self.dataSource enumerateObjectsUsingBlock:^(HYContacts *contacts, NSUInteger idx, BOOL * _Nonnull stop) {
        if (contacts.title) {
            [array addObject:contacts.title];
        }
    }];
//    for(char c = 'A'; c <= 'Z'; c++)
//    {
//        NSString *str = [NSString stringWithFormat:@"%c",c];
//        [array addObject:str];
//    }
    return array;
}
/**
 *  索引列点击事件
 *
 *  @return 返回tableView索引
 */
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    NSInteger section = 0;
    for (NSInteger i = 0; i < self.dataSource.count; i++) {
        HYContacts *contact = [self.dataSource objectAtIndex:i];
        if ([contact.title isEqualToString:title]) {
            section = i;
            break;
        }
    }
    return section;
}
#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    HYContacts *contacts = [self.dataSource objectAtIndex:indexPath.section];
    HYContactsModel *model = [contacts.infoArray objectAtIndex:indexPath.row];
    HYSingleChatViewController *singleVC = [[HYSingleChatViewController alloc] init];
    singleVC.chatJid = model.jid;
    singleVC.hidesBottomBarWhenPushed = YES; // 隐藏tabBar
    [self.navigationController pushViewController:singleVC animated:YES];
}


- (NSArray *)rightButtons
{
    NSMutableArray *result = [NSMutableArray array];
    MGSwipeButton *nikeButton = [MGSwipeButton buttonWithTitle:@"备注"  backgroundColor:[UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0] padding:20.0 callback:^BOOL(MGSwipeTableCell * sender){
        
        return YES;
    }];
    [result addObject:nikeButton];
    
    return result;
}

#pragma mark - 加载最近联系人
/**
 *  加载最近联系人
 */
- (void)loadContacts
{
    //1.上下文   XMPPRoster.xcdatamodel
    NSManagedObjectContext *context = [[HYXMPPManager sharedInstance] managedObjectContext_roster];
    if (context == nil) { // 防止xmppStream没有连接会崩溃
        return;
    }
    //2.Fetch请求
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"XMPPUserCoreDataStorageObject"];
//    //3.排序和过滤
    NSPredicate *pre=[NSPredicate predicateWithFormat:@"streamBareJidStr == %@",[HYLoginInfo sharedInstance].jid.bare];
    fetchRequest.predicate=pre;
    //
    NSSortDescriptor *sort=[NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES];
    fetchRequest.sortDescriptors=@[sort];
    
    //4.执行查询获取数据
    _resultController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    _resultController.delegate=self;
    //执行
    NSError *error=nil;
    if(![_resultController performFetch:&error]){
        HYLog(@"%s---%@",__func__,error);
    } else {
        BACK(^{ // 后台处理数据
            [self.dataSource removeAllObjects];
            [_resultController.fetchedObjects enumerateObjectsUsingBlock:^(XMPPUserCoreDataStorageObject *object, NSUInteger idx, BOOL * _Nonnull stop) {
                [self addContacsObject:object];
            }];
            [self sortWithContacts]; // 排序
            MAIN(^{
                [self.tableView reloadData]; // 刷新数据
            });
        });
        
    }
    
}
/**
 *  设置model
 "displayName" = erpapa123,
 "streamBareJidStr" = admin@erpapa.cn,
 "subscription" = both,
 "jidStr" = erpapa123@erpapa.cn,
 "ask" = nil,
 "unreadMessages" = 0,
 "jid" = (...not nil..),
 "resources" = <relationship fault: 0x16e31b30 'resources'>,
 "sectionNum" = 0,
 "photo" = nil,
 "primaryResource" = 0x16d42b90 <x-coredata://E5A2E05A-3C00-4B6F-A508-991608571F21/XMPPResourceCoreDataStorageObject/p87>,
 "section" = (...not nil..),
 "groups" = <relationship fault: 0x16e32700 'groups'>,
 "sectionName" = E,
 "nickname" = erpapa123,
 */
- (void)addContacsObject:(XMPPUserCoreDataStorageObject *)object
{
    HYContactsModel *contactsModel = [self modelWithStorageObject:object];
    NSString *firstLetter = [contactsModel.firstLetterStr substringToIndex:1];// 截取首字母(并转换为大写)
    NSInteger count = self.dataSource.count;
    if (count == 0) {
        HYContacts *contact = [[HYContacts alloc] init];
        contact.title = firstLetter;
        [contact.infoArray addObject:contactsModel];
        [self.dataSource addObject:contact];
    } else {
        for (NSInteger index = 0; index < count; index++) {
            HYContacts *contact = [self.dataSource objectAtIndex:index];
            if ([contact.title isEqualToString:firstLetter]) {// 如果title相同，添加到该组
                [contact.infoArray addObject:contactsModel];
                break;// 跳出循环
            }
            if (index == count - 1) {
                HYContacts *con = [[HYContacts alloc] init];
                con.title = firstLetter;
                [con.infoArray addObject:contactsModel];
                [self.dataSource addObject:con];
            }
        }
    }
}

/**
 *  排序
 */
- (void)sortWithContacts
{
    // 1.首字母排序
    NSArray *array = [self.dataSource sortedArrayUsingComparator:^NSComparisonResult(HYContacts *obj1, HYContacts *obj2) {
        return [obj1.title compare:obj2.title];
    }];
    // 2.数组内排序
    for (HYContacts *contact in array) {
        NSArray *infoArray = [contact.infoArray sortedArrayUsingComparator:^NSComparisonResult(HYContactsModel *obj1, HYContactsModel *obj2) {
            return [obj1.firstLetterStr compare:obj2.firstLetterStr];
        }];
        contact.infoArray = [NSMutableArray arrayWithArray:infoArray];
    }
    self.dataSource = [NSMutableArray arrayWithArray:array];
}

#pragma mark - NSFetchedResultsControllerDelegate
/**
 *  数据更新
 */
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath
{
    XMPPUserCoreDataStorageObject *object = anObject; // 当前改变的object
    switch (type) {
        case NSFetchedResultsChangeInsert:{
            // 插入数据
            [self addContacsObject:object];
            [self sortWithContacts];
            [self.tableView reloadData];
            break;
        }
        case NSFetchedResultsChangeDelete:{
            // 删除数据
            for (NSInteger i = 0; i < self.dataSource.count; i++) {// 查找当前联系人
                HYContacts *contact = [self.dataSource objectAtIndex:i];
                for (NSInteger j = 0; j < contact.infoArray.count; j++) {
                    HYContactsModel *model = [contact.infoArray objectAtIndex:j];
                    if ([model.jid.bare isEqualToString:object.jid.bare]) {
                        [contact.infoArray removeObjectAtIndex:j];
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:j inSection:i];
                        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        return;
                    }
                }
            }
            break;
        }
        case NSFetchedResultsChangeMove:{
            
            break;
        }
        case NSFetchedResultsChangeUpdate:{
            // 更新当前联系人
            for (NSInteger i = 0; i < self.dataSource.count; i++) {
                HYContacts *contact = [self.dataSource objectAtIndex:i];
                for (NSInteger j = 0; j < contact.infoArray.count; j++) {
                    HYContactsModel *model = [contact.infoArray objectAtIndex:j];
                    if ([model.jid.bare isEqualToString:object.jid.bare]) {
                        HYContactsModel *currentModel = [self modelWithStorageObject:object];
                        [contact.infoArray removeObjectAtIndex:j];
                        [contact.infoArray insertObject:currentModel atIndex:j];
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:j inSection:i];
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        return;
                    }
                }
            }
            break;
        }
        default:
            break;
    }
}

- (HYContactsModel *)modelWithStorageObject:(XMPPUserCoreDataStorageObject *)object
{
    NSString *userName = object.displayName.length ? object.displayName : object.jid.user; // 昵称
    NSString *firstLetterStr = [NSString new];
    if (userName.length) {
        CFMutableStringRef string = CFStringCreateMutableCopy(NULL, 0, (__bridge CFStringRef)userName);
        CFStringTransform(string, NULL, kCFStringTransformMandarinLatin, NO);// 拼音
        CFStringTransform(string, NULL, kCFStringTransformStripDiacritics, NO);// 没有音标
        NSString *name = (__bridge NSString *)string;// 姓名拼音
        NSArray *letterArray = [name componentsSeparatedByString:@" "];
        for (NSString *str in letterArray) {
            firstLetterStr =[firstLetterStr stringByAppendingString:[[str substringToIndex:1] uppercaseString]];// 截取首字母(并转换为大写)
        }
    }
    
    HYContactsModel *contactsModel = [[HYContactsModel alloc] init];
    contactsModel.jid = object.jid;
    contactsModel.displayName = userName;
    contactsModel.firstLetterStr = firstLetterStr;
    contactsModel.sectionNum = [object.sectionNum integerValue];
    contactsModel.isGroup = NO;
    return contactsModel;
}

#pragma mark - 搜索 - HYSearchBarDelegate
- (void)searchBarDidClicked:(HYSearchBar *)searchBar
{
    
}

#pragma mark - 新朋友、群聊
- (void)headerButtonClick:(UIButton *)sender
{
    if (sender.tag == 0) {
        HYNewFriendViewController *newFriendVC = [[HYNewFriendViewController alloc] init];
        [self.navigationController pushViewController:newFriendVC animated:YES];
    } else if (sender.tag == 1) {
        HYGroupListViewController *groupListVC = [[HYGroupListViewController alloc] init];
        [self.navigationController pushViewController:groupListVC animated:YES];
    }
}

#pragma mark - 添加联系人
- (void)addContacts:(id)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加用户，用Chat聊天" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *textAction = [UIAlertAction actionWithTitle:@"输入帐号" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showAddFriendViewController];
    }];
    UIAlertAction *QRAction = [UIAlertAction actionWithTitle:@"扫一扫" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:textAction];
    [alert addAction:QRAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (void)showAddFriendViewController
{
    HYAddFriendViewController *addFriendVC = [[HYAddFriendViewController alloc] init];
    [self presentViewController:addFriendVC animated:YES completion:nil];
}

- (void)showScanQRViewController
{
    HYScanQRCodeViewController *scanQRVC = [[HYScanQRCodeViewController alloc] init];
    [self presentViewController:scanQRVC animated:YES completion:nil];
}

#pragma mark - 懒加载

- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.rowHeight = kContactsViewCellHeight;
        _tableView.sectionHeaderHeight = kContactsHeaderViewHeight;
        _tableView.sectionFooterHeight = 0.0f;
        _tableView.sectionIndexColor = [UIColor grayColor]; // 索引文字颜色
        _tableView.sectionIndexBackgroundColor = [UIColor clearColor]; // 索引的背景色
        _tableView.sectionIndexTrackingBackgroundColor = [UIColor clearColor]; // 选中索引的背景色
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}

// 懒加载
- (NSMutableArray *)dataSource
{
    if (_dataSource == nil) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
