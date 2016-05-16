//
//  HYForwardingViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/14.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYForwardingViewController.h"
#import "HYForwardingViewCell.h"
#import "HYContactsModel.h"
#import "HYRecentChatModel.h"
#import "HYDatabaseHandler+HY.h"
#import "HYChatMessage.h"
#import "HYXMPPManager.h"
#import "HYXMPPRoomManager.h"
#import "XMPPUserCoreDataStorageObject.h"
#import "XMPPRoom.h"
#import "HYUtils.h"
#import "HYLoginInfo.h"

#define kFooterHeight 49.0
static NSString *kForwardingViewCellIdentifier = @"kForwardingViewCellIdentifier";
static NSString *kForwardingHeaderViewIdentifier = @"kForwardingHeaderViewIdentifier";
static NSString *kForwardingIconViewCellIdentifier = @"kForwardingIconViewCellIdentifier";

@interface HYForwardingViewController ()<UITableViewDataSource,UITableViewDelegate,UICollectionViewDataSource,UICollectionViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIView *footerView;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) NSMutableArray *selectedArray;
@property (nonatomic, strong) NSMutableArray *normalArray;
@property (nonatomic, strong) NSMutableArray *repeatArray;
@end

@implementation HYForwardingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self.tableView registerClass:[HYForwardingViewCell class] forCellReuseIdentifier:kForwardingViewCellIdentifier];
    [self.view addSubview:self.tableView];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelClick:)];
    
    self.selectedArray = [NSMutableArray array];
    self.normalArray = [NSMutableArray array];
    self.repeatArray = [NSMutableArray array];
    [self setupContentView]; // UI
    [self setupDataSource];  // 数据
    
}

- (void)setupDataSource
{
    // 1.加载最近联系人/群组
    NSMutableArray *tempArray = [NSMutableArray array];
    NSMutableArray *currentContacts = [NSMutableArray array];
    [[HYDatabaseHandler sharedInstance] recentChatModels:tempArray];
    [tempArray enumerateObjectsUsingBlock:^(HYRecentChatModel *recentModel, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![recentModel.jid.bare isEqualToString:self.message.jid.bare]) { // 去掉当前聊天对象
            HYContactsModel *model = [[HYContactsModel alloc] init];
            model.jid = recentModel.jid;
            NSString *nickName = [[HYLoginInfo sharedInstance].nickNameDict objectForKey:recentModel.jid.bare];
            model.nickName = nickName.length ? nickName : recentModel.jid.user;
            model.sectionNum = 0;                   // 规定sectionNum为1时为选中
            model.isGroup = recentModel.isGroup;
            [currentContacts addObject:model];
        }
    }];
    [self.dataSource addObject:currentContacts]; // -->最近联系人
    
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
    NSMutableArray *contacts = [NSMutableArray array];
    [fetchObjects enumerateObjectsUsingBlock:^(XMPPUserCoreDataStorageObject *object, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![object.jid.bare isEqualToString:self.message.jid.bare]) {
            HYContactsModel *model = [[HYContactsModel alloc] init];
            model.jid = object.jid;
            model.nickName = object.nickname.length ? object.nickname : object.jid.user;
            model.sectionNum = 0;
            model.isGroup = NO;
            [contacts addObject:model];
        }
    }];
    [self.dataSource addObject:contacts]; //  -->联系人
    
    // 3.聊天室
    NSMutableArray *rooms = [NSMutableArray array];
    NSArray *bookmarkedRooms = [HYXMPPRoomManager sharedInstance].bookmarkedRooms;
    [bookmarkedRooms enumerateObjectsUsingBlock:^(XMPPRoom *room, NSUInteger idx, BOOL * _Nonnull stop) {
        HYContactsModel *model = [[HYContactsModel alloc] init];
        model.jid = room.roomJID;
        model.nickName = room.roomJID.user;
        model.sectionNum = 0;
        model.isGroup = YES;
        [rooms addObject:model];
    }];
    [self.dataSource addObject:rooms]; //  -->聊天室
}



- (void)setupContentView
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionArray = [self.dataSource objectAtIndex:section];
    return sectionArray.count;;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *sectionArray = [self.dataSource objectAtIndex:indexPath.section];
    HYContactsModel *chatModel = [sectionArray objectAtIndex:indexPath.row];
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
    NSArray *titles = @[@"最近联系人",@"好友",@"聊天室"];
    headerView.titleLabel.text = [titles objectAtIndex:section];
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
    NSArray *sectionArray = [self.dataSource objectAtIndex:indexPath.section];
    HYContactsModel *model = [sectionArray objectAtIndex:indexPath.row];
    if (model.sectionNum == 0) {
        model.sectionNum = 1;
        BOOL fond = NO;
        for (HYContactsModel *selectedModel in self.normalArray) {
            if ([selectedModel.jid.bare isEqualToString:model.jid.bare]) {
                fond = YES;
                break;
            }
        }
        if (fond == YES) { // 重复
            [self.repeatArray addObject:model];
        } else {
            [self.normalArray addObject:model];
        }
        
    } else {
        model.sectionNum = 0;
        [self.normalArray removeObject:model];
        [self.repeatArray removeObject:model];
        
    }
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.selectedArray removeAllObjects];
    [self.selectedArray addObjectsFromArray:self.normalArray];
    [self.repeatArray enumerateObjectsUsingBlock:^(HYContactsModel *repeatModel, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL fond = NO;
        for (HYContactsModel *normalModel in self.normalArray) {
            if ([normalModel.jid.bare isEqualToString:repeatModel.jid.bare]) {
                fond = YES;
                break;
            }
        }
        if (fond == NO) { // 没有找到重复项才添加
            [self.selectedArray addObject:repeatModel];
        }
    }];
    
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
    [self dismissViewControllerAnimated:YES completion:nil];
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
    
    [HYUtils showWaitingMsg:@"正在发送..."];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.selectedArray enumerateObjectsUsingBlock:^(HYContactsModel *chatModel, NSUInteger idx, BOOL * _Nonnull stop) {
            if (chatModel.isGroup) { // 群组
                self.message.messageID = [HYUtils currentTimeStampString];
                self.message.jid = [XMPPJID jidWithString:chatModel.jid.bare resource:[HYXMPPRoomManager sharedInstance].xmppStream.myJID.user];
                self.message.time = [[NSDate date] timeIntervalSince1970];
                self.message.isRead = YES;
                self.message.isOutgoing = YES;
                self.message.isGroup = YES;
                BOOL sendSuccess = [[HYXMPPRoomManager sharedInstance] sendText:[self.message jsonString] toRoomJid:chatModel.jid];
                if (sendSuccess) {
                    self.message.sendStatus = HYChatSendMessageStatusSuccess;
                    [[HYDatabaseHandler sharedInstance] addGroupChatMessage:self.message];
                } else {
                    self.message.sendStatus = HYChatSendMessageStatusFaild;
                    [[HYDatabaseHandler sharedInstance] addGroupChatMessage:self.message];
                }
            } else { // 个人
                self.message.messageID = [HYUtils currentTimeStampString];
                self.message.jid = chatModel.jid;
                self.message.time = [[NSDate date] timeIntervalSince1970];
                self.message.isRead = YES;
                self.message.isOutgoing = YES;
                self.message.isGroup = NO;
                BOOL sendSuccess = [[HYXMPPManager sharedInstance] sendText:[self.message jsonString] toJid:chatModel.jid];
                if (sendSuccess) {
                    self.message.sendStatus = HYChatSendMessageStatusSuccess;
                    [[HYDatabaseHandler sharedInstance] addChatMessage:self.message];
                } else {
                    self.message.sendStatus = HYChatSendMessageStatusFaild;
                    [[HYDatabaseHandler sharedInstance] addChatMessage:self.message];
                }
            }
            usleep(10000);// -->0.01s 进程挂起一段时间,单位是微秒（百万分之一秒)
        }];
        
        [HYUtils alertWithSuccessMsg:@"发送成功！"];
        [self dismissViewControllerAnimated:YES completion:nil];
        
    });
    
    
    
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
