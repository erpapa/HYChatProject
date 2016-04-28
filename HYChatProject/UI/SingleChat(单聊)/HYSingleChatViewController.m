//
//  HYSingleChatViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/3/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYSingleChatViewController.h"
#import "HYXMPPManager.h"
#import "HYLoginInfo.h"

typedef XMPPMessageArchiving_Message_CoreDataObject HYMessageModel;

@interface HYSingleChatViewController ()<UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic,strong) NSFetchedResultsController *resultController;//查询结果集合
@end

@implementation HYSingleChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    // 1.tableView
    [self.view addSubview:self.tableView];
    // 2.获取聊天数据
    [self getChatHistory];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier=@"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(cell == nil){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    HYMessageModel *model = [self.dataSource objectAtIndex:indexPath.row];
    cell.textLabel.text = model.body;
    return cell;
}

- (void)getChatHistory
{
    // 1.上下文
    NSManagedObjectContext *context = [[HYXMPPManager sharedInstance] managedObjectContext_messageArchiving];
    if (context == nil) { // 防止xmppStream没有连接会崩溃
        return;
    }
    // 2.Fetch请求
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"XMPPMessageArchiving_Message_CoreDataObject"];
    // 3.过滤
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bareJidStr == %@ AND streamBareJidStr == %@",self.chatJid.bare, [HYLoginInfo sharedInstance].jid.bare];
    [fetchRequest setPredicate:predicate];
    // 4.排序(升序)
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    //4.执行查询获取数据
    _resultController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    _resultController.delegate=self;
    //执行
    NSError *error=nil;
    if(![_resultController performFetch:&error]){
        HYLog(@"%s---%@",__func__,error);
    } else {
        [self.dataSource removeAllObjects];
        [_resultController.fetchedObjects enumerateObjectsUsingBlock:^(HYMessageModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.dataSource addObject:model]; // 添加到数据源
        }];
    }
}

#pragma mark - NSFetchedResultsControllerDelegate
/**
 *  数据更新
 */
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath
{
    HYMessageModel *object = anObject;
    switch (type) {
        case NSFetchedResultsChangeInsert:{ // 插入(最后)
            [self.dataSource insertObject:object atIndex:newIndexPath.row];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
        case NSFetchedResultsChangeDelete:{ // 删除
            [self.dataSource removeObjectAtIndex:indexPath.row];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
        case NSFetchedResultsChangeMove:{ // 移动
            [self.dataSource removeObjectAtIndex:indexPath.row];
            [self.dataSource insertObject:object atIndex:newIndexPath.row];
            [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            [self.tableView reloadRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
        case NSFetchedResultsChangeUpdate:{ // 更新数据
            [self.dataSource removeObjectAtIndex:indexPath.row];
            [self.dataSource insertObject:object atIndex:indexPath.row];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
        default:
            break;
    }
}
#pragma mark - 懒加载
- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
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
