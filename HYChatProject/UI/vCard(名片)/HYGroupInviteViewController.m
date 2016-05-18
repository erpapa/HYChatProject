//
//  HYGroupInviteViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/16.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYGroupInviteViewController.h"
#import "HYForwardingViewCell.h"
#import "HYContactsModel.h"
#import "HYXMPPManager.h"
#import "HYXMPPRoomManager.h"
#import "XMPPUserCoreDataStorageObject.h"
#import "HYUtils.h"

#define kFooterHeight 49.0
static NSString *kForwardingViewCellIdentifier = @"kForwardingViewCellIdentifier";
static NSString *kForwardingHeaderViewIdentifier = @"kForwardingHeaderViewIdentifier";
static NSString *kForwardingIconViewCellIdentifier = @"kForwardingIconViewCellIdentifier";

@interface HYGroupInviteViewController ()<UITableViewDataSource,UITableViewDelegate,UICollectionViewDataSource,UICollectionViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIView *footerView;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) NSMutableArray *selectedArray;
@end

@implementation HYGroupInviteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self.tableView registerClass:[HYForwardingViewCell class] forCellReuseIdentifier:kForwardingViewCellIdentifier];
    [self.view addSubview:self.tableView];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelClick:)];
    [self setupFooterView]; // UI
    [self setupDataSource];  // 数据
}

- (void)setupDataSource
{
    // 2.联系人   XMPPRoster.xcdatamodel
    NSManagedObjectContext *context = [[HYXMPPManager sharedInstance] managedObjectContext_roster];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSPredicate *pre=[NSPredicate predicateWithFormat:@"streamBareJidStr == %@",[HYXMPPManager sharedInstance].myJID.bare];
    fetchRequest.predicate=pre; // 过滤
    NSSortDescriptor *sort=[NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES];
    fetchRequest.sortDescriptors=@[sort]; // 排序
    NSError *error;
    NSArray *fetchObjects = [context executeFetchRequest:fetchRequest error:&error];
    [self.dataSource removeAllObjects];
    [fetchObjects enumerateObjectsUsingBlock:^(XMPPUserCoreDataStorageObject *object, NSUInteger idx, BOOL * _Nonnull stop) {
        HYContactsModel *model = [[HYContactsModel alloc] init];
        model.jid = object.jid;
        model.nickName = object.nickname.length ? object.nickname : object.jid.user;
        model.sectionNum = 0;
        model.isGroup = NO;
        [self.dataSource addObject:model];
    }];
}

- (void)setupFooterView
{
    // 1.底部view
    self.footerView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds) - kFooterHeight, CGRectGetWidth(self.view.bounds), kFooterHeight)];
    self.footerView.backgroundColor = [UIColor colorWithRed:241/255.0 green:241/255.0 blue:241/255.0 alpha:1.0f];
    [self.view addSubview:self.footerView];
    
    // 2.线
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.footerView.bounds), 1)];
    line.backgroundColor = [UIColor colorWithRed:222/255.0f green:222/255.0f blue:222/255.0f alpha:1.0f];
    [self.footerView addSubview:line];
    
    // 3.发送
    CGFloat buttonWidth = 64;
    CGFloat buttonX = CGRectGetWidth(self.footerView.bounds) - buttonWidth;
    self.sendButton = [[UIButton alloc] initWithFrame:CGRectMake(buttonX, 1, buttonWidth, kFooterHeight - 1)];
    [self.sendButton setTitle:@"发送" forState:UIControlStateNormal];
    [self.sendButton setTitleColor:[UIColor colorWithRed:50/255.0 green:155/255.0 blue:250/255.0 alpha:1.0] forState:UIControlStateNormal];
    [self.sendButton addTarget:self action:@selector(sendButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.footerView addSubview:self.sendButton];
    
    // 4.1.流水布局
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(kFooterHeight - 1, kFooterHeight - 1);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 0;
    // 4.2.实例化collectionView
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(10, 1, buttonX - 10, kFooterHeight - 1) collectionViewLayout:layout];
    // 4.3.注册cell(告诉collectionView将来创建怎样的cell)
    [self.collectionView registerClass:[HYForwardingIconViewCell class] forCellWithReuseIdentifier:kForwardingIconViewCellIdentifier];
    // 4.4.设置背景色和代理
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.footerView addSubview:self.collectionView];
}


#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HYContactsModel *chatModel = [self.dataSource objectAtIndex:indexPath.row];
    HYForwardingViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kForwardingViewCellIdentifier];
    cell.accessoryType = chatModel.sectionNum ? UITableViewCellAccessoryCheckmark :UITableViewCellAccessoryNone;
    cell.chatModel = chatModel;
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    HYForwardingHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kForwardingHeaderViewIdentifier];
    if (headerView == nil) {
        headerView = [[HYForwardingHeaderView alloc] initWithReuseIdentifier:kForwardingHeaderViewIdentifier];
    }
    headerView.titleLabel.text = @"好友";
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kForwardingHeaderViewHeight;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    HYContactsModel *model = [self.dataSource objectAtIndex:indexPath.row];
    if (model.sectionNum == 0) {
        model.sectionNum = 1;
        [self.selectedArray addObject:model];
    } else {
        model.sectionNum = 0;
        [self.selectedArray removeObject:model];
    }
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.collectionView reloadData];
}



#pragma mark - UICollectionView dataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.selectedArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HYForwardingIconViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kForwardingIconViewCellIdentifier forIndexPath:indexPath];
    HYContactsModel *chatModel = [self.selectedArray objectAtIndex:indexPath.row];
    cell.chatModel = chatModel;
    return cell;
}

/**
 *  取消发送
 */
- (void)cancelClick:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

/**
 *  发送
 */

- (void)sendButtonClick:(id)sender
{
    if (self.selectedArray.count == 0) {
        [HYUtils alertWithNormalMsg:@"请选择转发对象!"];
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"邀请理由" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
        textField.text = @"快来加入吧！";
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [HYUtils showWaitingMsg:@"正在发送..."];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UITextField *textField = alertController.textFields.firstObject;
            NSString *reason = textField.text;
            [self.selectedArray enumerateObjectsUsingBlock:^(HYContactsModel *chatModel, NSUInteger idx, BOOL * _Nonnull stop) {
                [[HYXMPPRoomManager sharedInstance] inviteUser:chatModel.jid toRoom:self.roomJid reason:reason];
                usleep(10000);// -->0.01s 进程挂起一段时间,单位是微秒（百万分之一秒)
            }];
            [HYUtils alertWithSuccessMsg:@"发送成功！"];
            [self.navigationController popViewControllerAnimated:YES];
            
        });
    }];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
    
}

#pragma mark - 懒加载

- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - kFooterHeight)];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.rowHeight = kForwardingViewCellHeight;
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

- (NSMutableArray *)selectedArray
{
    if (_selectedArray == nil) {
        _selectedArray = [NSMutableArray array];
    }
    return _selectedArray;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
