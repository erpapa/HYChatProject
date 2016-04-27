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
#import "HYContacts.h"
#import "HYContactsModel.h"
#import "HYXMPPManager.h"
#import "HYLoginInfo.h"

@interface HYContactsViewController ()<UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *dataSource;
@property (nonatomic,strong) NSFetchedResultsController *resultController;//查询结果集合

@end

@implementation HYContactsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // 1.tableView
    [self.view addSubview:self.tableView];
    // 2.加载好友列表
    [self loadContacts];
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
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    HYContacts *contact = [self.dataSource objectAtIndex:section];
    return contact.title;
}

/**
 *  返回索引数组
 */
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
    //2.Fetch请求
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"XMPPUserCoreDataStorageObject"];
//    //3.排序和过滤
    NSPredicate *pre=[NSPredicate predicateWithFormat:@"streamBareJidStr=%@",[HYLoginInfo sharedInstance].jid.bare];
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
        [_resultController.fetchedObjects enumerateObjectsUsingBlock:^(XMPPUserCoreDataStorageObject *object, NSUInteger idx, BOOL * _Nonnull stop) {
            [self addContacsObject:object];
        }];
        [self sortWithContacts]; // 排序
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
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    XMPPUserCoreDataStorageObject *object = [controller.fetchedObjects lastObject];
    for (NSInteger i = 0; i < self.dataSource.count; i++) {// 查找当前联系人，如果找到就更新
        HYContacts *contact = [self.dataSource objectAtIndex:i];
        for (NSInteger j = 0; j < contact.infoArray.count; j++) {
            HYContactsModel *model = [contact.infoArray objectAtIndex:j];
            if ([model.jid.bare isEqualToString:object.jid.bare]) {
                HYContactsModel *currentModel = [self modelWithStorageObject:object];
                [contact.infoArray removeObjectAtIndex:j];
                [contact.infoArray insertObject:currentModel atIndex:j];
                [self.tableView reloadData];
                return;
            }
        }
    }
    // 如果没有找到，就插入数据
    [self addContacsObject:object];
    [self sortWithContacts];
    [self.tableView reloadData];
}

- (HYContactsModel *)modelWithStorageObject:(XMPPUserCoreDataStorageObject *)object
{
    NSString *userStr = object.nickname.length ? object.nickname : object.jid.user; // 昵称
    CFMutableStringRef string = CFStringCreateMutableCopy(NULL, 0, (__bridge CFStringRef)userStr);
    CFStringTransform(string, NULL, kCFStringTransformMandarinLatin, NO);// 拼音
    CFStringTransform(string, NULL, kCFStringTransformStripDiacritics, NO);// 没有音标
    NSString *name = (__bridge NSString *)string;// 姓名拼音
    NSArray *letterArray = [name componentsSeparatedByString:@" "];
    NSString *firstLetterStr = [NSString string];
    for (NSString *str in letterArray) {
        firstLetterStr =[firstLetterStr stringByAppendingString:[[str substringToIndex:1] uppercaseString]];// 截取首字母(并转换为大写)
    }
    HYContactsModel *contactsModel = [[HYContactsModel alloc] init];
    contactsModel.jid = object.jid;
    contactsModel.firstLetterStr = firstLetterStr;
    contactsModel.sectionNum = [object.sectionNum integerValue];
    contactsModel.isGroup = NO;
    return contactsModel;
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
