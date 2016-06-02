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
#import "HYContactsCustomViewCell.h"
#import "HYContactsHeaderView.h"
#import "HYContacts.h"
#import "HYContactsModel.h"
#import "HYLoginInfo.h"
#import "HYXMPPManager.h"
#import "HYSingleChatViewController.h"
#import "HYNewFriendViewController.h"
#import "HYGroupListViewController.h"
#import "HYSearchController.h"
#import "HYAddFriendViewController.h"
#import "HYScanQRCodeViewController.h"
#import "HYSearchController.h"
#import "HYContactsSearchResultsController.h"

@interface HYContactsViewController ()<UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate,UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating>
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *dataSource;
@property (nonatomic,strong) NSFetchedResultsController *resultController;//查询结果集合
@property (nonatomic, strong) HYSearchController *searchController;
@property (nonatomic, strong) HYContactsSearchResultsController *resultsController;
@property (nonatomic, assign) BOOL shouldRefresh;

@end

@implementation HYContactsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    // 搜索
    self.resultsController = [[HYContactsSearchResultsController alloc] init];
    self.searchController = [[HYSearchController alloc] initWithSearchResultsController:self.resultsController];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    [self.searchController.searchBar sizeToFit];
    self.searchController.searchBar.delegate = self; // so we can monitor text changes + others
    self.definesPresentationContext = YES;// know where you want UISearchController to be displayed
    self.tableView.tableHeaderView = self.searchController.searchBar;
    [self.view addSubview:self.tableView];
    // 添加联系人
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addContacts:)];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.dataSource.count == 0) {
        // 加载好友列表
        [self loadContacts];
    }
    if (self.shouldRefresh == YES) {
        [self reloadDataSource]; // 刷新
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.searchController.active = NO;
}

#pragma mark - 更新搜索结果 UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSMutableArray *searchResults = [NSMutableArray array];
    [self.dataSource enumerateObjectsUsingBlock:^(HYContacts *contacts, NSUInteger idx, BOOL *stop) {
        [contacts.infoArray enumerateObjectsUsingBlock:^(HYContactsModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([model.jid.user containsString:self.searchController.searchBar.text] ||[model.nickName containsString:self.searchController.searchBar.text]) {
                [searchResults addObject:model];
            }
        }];
    }];
    HYContactsSearchResultsController *tableController = (HYContactsSearchResultsController *)self.searchController.searchResultsController;
    tableController.searchResults = searchResults;//传递搜索结果
    [tableController.tableView reloadData];
}

#pragma mark - UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}


#pragma mark - UITableViewDatasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataSource.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 2;// 新朋友、聊天室
    }
    HYContacts *contacts = [self.dataSource objectAtIndex:section - 1];
    return contacts.infoArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        HYContactsCustomViewCell *customCell = [HYContactsCustomViewCell cellWithTableView:tableView];
        if (indexPath.row == 0) { // 新朋友
            customCell.nameLabel.text = @"新朋友";
            customCell.headView.image = [UIImage imageNamed:@"menu_newfriend"];
        } else if (indexPath.row == 1) { // 聊天室
            customCell.nameLabel.text = @"聊天室";
            customCell.headView.image = [UIImage imageNamed:@"menu_group"];
        }
        return customCell;
    }
    HYContacts *contacts = [self.dataSource objectAtIndex:indexPath.section - 1];
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
    if (section == 0) return nil;
    static NSString *kContactsHeaderIdentifier = @"kContactsHeaderIdentifier";
    HYContactsHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kContactsHeaderIdentifier];
    if (headerView == nil) {
        headerView = [[HYContactsHeaderView alloc] initWithReuseIdentifier:kContactsHeaderIdentifier];
    }
    HYContacts *contacts = [self.dataSource objectAtIndex:section - 1];
    headerView.title = contacts.title;
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 0.0f;
    }
    return kContactsHeaderViewHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.0f;
}

#pragma mark - 返回索引数组
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSMutableArray *array = [NSMutableArray array];
    [self.dataSource enumerateObjectsUsingBlock:^(HYContacts *contacts, NSUInteger idx, BOOL * _Nonnull stop) {
        if (contacts.title) {
            [array addObject:contacts.title];
        }
    }];
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
    return section + 1;
}
#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) { // 新朋友
            HYNewFriendViewController *newFriendVC = [[HYNewFriendViewController alloc] init];
            newFriendVC.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:newFriendVC animated:YES];
        } else if (indexPath.row == 1) { // 群聊
            HYGroupListViewController *groupListVC = [[HYGroupListViewController alloc] init];
            groupListVC.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:groupListVC animated:YES];
        }
        return;
    }
    HYContacts *contacts = [self.dataSource objectAtIndex:indexPath.section - 1];
    HYContactsModel *model = [contacts.infoArray objectAtIndex:indexPath.row];
    HYSingleChatViewController *singleVC = [[HYSingleChatViewController alloc] init];
    singleVC.chatJid = model.jid;
    singleVC.hidesBottomBarWhenPushed = YES; // 隐藏tabBar
    [self.navigationController pushViewController:singleVC animated:YES];
}


- (NSArray *)rightButtons
{
    NSMutableArray *result = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    MGSwipeButton *nikeButton = [MGSwipeButton buttonWithTitle:@"备注" backgroundColor:[UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0] padding:20.0 callback:^BOOL(MGSwipeTableCell * sender){
        NSIndexPath *indexPath = [weakSelf.tableView indexPathForCell:sender];
        HYContacts *contacts = [weakSelf.dataSource objectAtIndex:indexPath.section - 1];
        HYContactsModel *model = [contacts.infoArray objectAtIndex:indexPath.row];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"设置好友昵称" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
            textField.text = model.nickName;
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UITextField *textField = alertController.textFields.firstObject;
            NSString *inputText = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *nickName = inputText.length ? inputText : model.jid.user;
            [[HYXMPPManager sharedInstance] setNickname:nickName forUser:model.jid];
        }];
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        [weakSelf presentViewController:alertController animated:YES completion:nil];
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
    NSPredicate *pre=[NSPredicate predicateWithFormat:@"streamBareJidStr == %@",[HYXMPPManager sharedInstance].myJID.bare];
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
        [self reloadDataSource];
    }
    
}

/**
 *  添加联系人model
 */
- (void)addContacsObject:(XMPPUserCoreDataStorageObject *)object
{
    if (object.jid == nil) return;
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
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath
{
    if (type == NSFetchedResultsChangeUpdate || type == NSFetchedResultsChangeMove) {
        [self reloadDataSource];
    } else {
        self.shouldRefresh = YES;
    }
}

#pragma mark - 更新数据

- (void)reloadDataSource
{
    BACK(^{
        [self.dataSource removeAllObjects];
        [_resultController.fetchedObjects enumerateObjectsUsingBlock:^(XMPPUserCoreDataStorageObject *object, NSUInteger idx, BOOL * _Nonnull stop) {
            // 如果是none表示对方还没有确认   // to 我关注对方  // from 对方关注我  // both 互粉
            if ([object.subscription isEqualToString:@"both"]) {
                NSString *nickName = object.nickname;
                if (nickName.length == 0) {
                    nickName = object.jid.user;
                }
                if (object.jid) {
                    [[HYLoginInfo sharedInstance].nickNameDict setObject:nickName forKey:object.jid.bare]; // 储存到字典
                }
                [self addContacsObject:object];
            }
        }];
        [[HYLoginInfo sharedInstance] saveNickNameDictToSanbox];
        [self sortWithContacts]; // 排序
        MAIN(^{
            [self.tableView reloadData]; // 刷新数据
            self.shouldRefresh = NO;
        });
        
        
    });
    
}

/**
 *  object转model
 */
- (HYContactsModel *)modelWithStorageObject:(XMPPUserCoreDataStorageObject *)object
{
    NSString *userName = object.nickname.length ? object.nickname : object.jid.user; // 昵称
    NSString *firstLetterStr = object.sectionName;
    if (userName.length) {
        //转成了可变字符串
        NSMutableString *str = [NSMutableString stringWithString:firstLetterStr];
        //先转换为带音标的拼音
        CFStringTransform((CFMutableStringRef)str,NULL, kCFStringTransformMandarinLatin,NO);
        //再转换为没有音标的拼音
        CFStringTransform((CFMutableStringRef)str,NULL, kCFStringTransformStripDiacritics,NO);
        //转化为大写拼音
        firstLetterStr = [str capitalizedString];
    }
    HYContactsModel *contactsModel = [[HYContactsModel alloc] init];
    contactsModel.jid = object.jid;
    contactsModel.nickName = userName;
    contactsModel.firstLetterStr = firstLetterStr;
    contactsModel.sectionNum = [object.sectionNum integerValue];
    contactsModel.isGroup = NO;
    return contactsModel;
}

#pragma mark - 添加联系人
- (void)addContacts:(id)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"输入帐号或者扫描二维码添加好友" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *textAction = [UIAlertAction actionWithTitle:@"输入帐号" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        HYAddFriendViewController *addFriendVC = [[HYAddFriendViewController alloc] init];
        addFriendVC.type = HYAddFriendTypeFriend;
        addFriendVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:addFriendVC animated:YES];
    }];
    UIAlertAction *QRAction = [UIAlertAction actionWithTitle:@"扫一扫" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        HYScanQRCodeViewController *scanQRVC = [[HYScanQRCodeViewController alloc] init];
        scanQRVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:scanQRVC animated:YES];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:textAction];
    [alert addAction:QRAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
    
}


#pragma mark - 懒加载

- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - CGRectGetHeight(self.tabBarController.tabBar.frame))];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.rowHeight = kContactsViewCellHeight;
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


/**
 *  数据更新
 */
//- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath
//{
//    XMPPUserCoreDataStorageObject *object = anObject; // 当前改变的object
//    switch (type) {
//        case NSFetchedResultsChangeDelete:{
//            // 删除数据
//            for (NSInteger i = 0; i < self.dataSource.count; i++) {// 查找当前联系人
//                HYContacts *contact = [self.dataSource objectAtIndex:i];
//                for (NSInteger j = 0; j < contact.infoArray.count; j++) {
//                    HYContactsModel *model = [contact.infoArray objectAtIndex:j];
//                    if ([model.jid.bare isEqualToString:object.jid.bare]) {
//                        [contact.infoArray removeObjectAtIndex:j];
//                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:j inSection:i+1];
//                        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
//                        return;
//                    }
//                }
//            }
//            break;
//        }
//        case NSFetchedResultsChangeMove:{
//            [self reloadDataSource];
//            break;
//        }
//        case NSFetchedResultsChangeUpdate:{
//            // 更新当前联系人
//            for (NSInteger i = 0; i < self.dataSource.count; i++) {
//                HYContacts *contact = [self.dataSource objectAtIndex:i];
//                for (NSInteger j = 0; j < contact.infoArray.count; j++) {
//                    HYContactsModel *model = [contact.infoArray objectAtIndex:j];
//                    if ([model.jid.bare isEqualToString:object.jid.bare]) {
//                        // 如果更改昵称后还是在当前index，不会更新header, 在这里比较nickname,如果昵称改变就重新reload
//                        if (![model.nickName isEqualToString:object.nickname]) {
//                            [self reloadDataSource];
//                            return;
//                        }
//                        HYContactsModel *currentModel = [self modelWithStorageObject:object];
//                        [contact.infoArray removeObjectAtIndex:j];
//                        [contact.infoArray insertObject:currentModel atIndex:j];
//                        NSIndexPath *path = [NSIndexPath indexPathForRow:j inSection:i+1];
//                        [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
//                        return;
//                    }
//                }
//            }
//            break;
//        }
//        default:
//            break;
//    }
//}

@end
