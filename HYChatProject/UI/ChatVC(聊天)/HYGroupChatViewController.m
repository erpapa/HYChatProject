//
//  HYGroupChatViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/3/20.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYGroupChatViewController.h"
#import "HYInputViewController.h"
#import "HYChatMessageFrame.h"
#import "HYXMPPManager.h"
#import "HYXMPPRoomManager.h"
#import "HYDatabaseHandler+HY.h"
#import "YYImageCache.h"
#import "HYUtils.h"
#import "HYAudioPlayer.h"
#import "AFNetworking.h"
#import "HYNetworkManager.h"

#import "ODRefreshControl.h"
#import "HYForwardingViewController.h"
#import "HYVideoCaptureController.h"
#import "HYVideoPlayController.h"
#import "HYPhotoBrowserController.h"
#import "HYUservCardViewController.h"
#import "HYGroupInfoViewController.h"

#import "HYBaseChatViewCell.h"
#import "HYTextChatViewCell.h"
#import "HYImageChatViewCell.h"
#import "HYAudioChatViewCell.h"
#import "HYVideoChatViewCell.h"

static NSString *kTextChatViewCellIdentifier = @"kTextChatViewCellIdentifier";
static NSString *kImageChatViewCellIdentifier = @"kImageChatViewCellIdentifier";
static NSString *kAudioChatViewCellIdentifier = @"kAudioChatViewCellIdentifier";
static NSString *kVideoChatViewCellIdentifier = @"kVideoChatViewCellIdentifier";
@interface HYGroupChatViewController ()<UITableViewDataSource, UITableViewDelegate,NSFetchedResultsControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, HYInputViewControllerDelegate, HYBaseChatViewCellDelegate,HYVideoCaptureControllerDelegate,HYAudioPlayerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) HYInputViewController *inputVC;
@property (nonatomic, strong) NSFetchedResultsController *resultController;//查询结果集合
@property (nonatomic, strong) ODRefreshControl *refreshControl;

@property (nonatomic, strong) HYAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSString *playingMessageID;// 当前播放的消息
@property (nonatomic, assign) BOOL isShowMultimedia;
@end

@implementation HYGroupChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = self.roomJid.user;
    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"anon_group_header"] style:UIBarButtonItemStylePlain target:self action:@selector(roomInfo:)];
    
    // 1.tableView
    [self.tableView registerClass:[HYTextChatViewCell class] forCellReuseIdentifier:kTextChatViewCellIdentifier];
    [self.tableView registerClass:[HYImageChatViewCell class] forCellReuseIdentifier:kImageChatViewCellIdentifier];
    [self.tableView registerClass:[HYAudioChatViewCell class] forCellReuseIdentifier:kAudioChatViewCellIdentifier];
    [self.tableView registerClass:[HYVideoChatViewCell class] forCellReuseIdentifier:kVideoChatViewCellIdentifier];
    
    [self.view addSubview:self.tableView];
    
    // 2.下拉刷新
    self.refreshControl = [[ODRefreshControl alloc] initInScrollView:self.tableView];
    self.refreshControl.tintColor = [UIColor colorWithRed:241/255.0 green:241/255.0 blue:241/255.0 alpha:1.0];
    [self.refreshControl addTarget:self action:@selector(loadMoreChatMessage) forControlEvents:UIControlEventValueChanged];
    
    // 3.聊天工具条
    self.inputVC = [[HYInputViewController alloc] init];
    self.inputVC.delegate = self;
    self.inputVC.view.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - kInputBarHeight, CGRectGetWidth(self.view.bounds), kInputBarHeight);
    [self.view addSubview:self.inputVC.view];
    
    // 4.设置当前聊天对象
    [HYXMPPManager sharedInstance].chatJID = self.roomJid;
    
    // 5.获取聊天数据
    [self getChatHistory];
    
    // 6.监听网络状态改变
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusNotReachable) { // 网络不可用
            [HYUtils alertWithErrorMsg:@"网络不可用！"];
        }
    }];
    
    // 7.音频
    self.audioPlayer = [[HYAudioPlayer alloc] init];
    self.audioPlayer.delegate = self;
    
    // 8.注册通知
    [HYNotification addObserver:self selector:@selector(receiveGroupMessage:) name:HYChatDidReceiveGroupMessage object:nil];
    [HYNotification addObserver:self selector:@selector(resignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [HYNotification addObserver:self selector:@selector(becomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.isShowMultimedia) {
        self.isShowMultimedia = NO;
        return;
    }
    // 自动滚动表格到最后一行
    if (self.dataSource.count) {
        NSIndexPath *lastPath = [NSIndexPath indexPathForRow:self.dataSource.count - 1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:lastPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self settingKeyboard];
    NSArray *indexPaths = [self.tableView indexPathsForVisibleRows];
    NSMutableArray *indexs = [NSMutableArray array];
    for (NSIndexPath *indexPath in indexPaths) {
        HYChatMessageFrame *messageFrame = [self.dataSource objectAtIndex:indexPath.row];
        if (messageFrame.chatMessage.type == HYChatMessageTypeVideo) {
            [indexs addObject:indexPath];
        }
    }
    [self.tableView reloadRowsAtIndexPaths:indexs withRowAnimation:UITableViewRowAnimationNone];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.audioPlayer stop];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HYBaseChatViewCell *cell = nil;
    HYChatMessageFrame *messageFrame = [self.dataSource objectAtIndex:indexPath.row];
    HYChatMessage *message = messageFrame.chatMessage;
    switch (message.type) {
        case HYChatMessageTypeText:{
            cell = [tableView dequeueReusableCellWithIdentifier:kTextChatViewCellIdentifier];
            break;
        }
        case HYChatMessageTypeImage:{
            cell = [tableView dequeueReusableCellWithIdentifier:kImageChatViewCellIdentifier];
            break;
        }
        case HYChatMessageTypeAudio:{
            cell = [tableView dequeueReusableCellWithIdentifier:kAudioChatViewCellIdentifier];
            break;
        }
        case HYChatMessageTypeVideo:{
            cell = [tableView dequeueReusableCellWithIdentifier:kVideoChatViewCellIdentifier];
            break;
        }
        default:
            break;
    }
    cell.messageFrame = messageFrame;
    cell.delegate = self;
    return cell;
}

/**
 *  cell即将显示
 */
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    HYBaseChatViewCell *displayCell = (HYBaseChatViewCell *)cell;
    if (displayCell.messageFrame.chatMessage.type == HYChatMessageTypeVideo) {
        HYVideoChatViewCell *videoCell = (HYVideoChatViewCell *)displayCell;
        [videoCell decodeVideo];
    }
}

/**
 *  cell离开显示范围
 */
- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    HYBaseChatViewCell *displayCell = (HYBaseChatViewCell *)cell;
    if (displayCell.messageFrame.chatMessage.type == HYChatMessageTypeVideo) {
        HYVideoChatViewCell *videoCell = (HYVideoChatViewCell *)displayCell;
        [videoCell endDisplay];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HYChatMessageFrame *messageFrame = [self.dataSource objectAtIndex:indexPath.row];
    return messageFrame.cellHeight;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    UIMenuController *popMenu = [UIMenuController sharedMenuController];
    if (popMenu.isMenuVisible) {
        [popMenu setMenuVisible:NO animated:YES];
    }
    if (self.inputVC.isFirstResponder) {
        [self.inputVC resignFirstResponder]; // 输入框取消第一响应者
        [self settingKeyboard];
    }
    
}

#pragma mark - 获取聊天数据

- (void)getChatHistory
{
    NSMutableArray *chatMessages = [NSMutableArray array];
    [self.dataSource removeAllObjects];
    [[HYDatabaseHandler sharedInstance] recentGroupChatMessages:chatMessages fromRoomJID:self.roomJid];
    // 处理数据
    [chatMessages enumerateObjectsUsingBlock:^(HYChatMessage *message, NSUInteger idx, BOOL * _Nonnull stop) {
        // 判断是否显示时间
        message.timeString = [HYUtils timeStringSince1970:message.time];
        HYChatMessageFrame *lastMessageFrame = [self.dataSource lastObject];
        message.isHidenTime = [lastMessageFrame.chatMessage.timeString isEqualToString:message.timeString];
        HYChatMessageFrame *messageFrame = [[HYChatMessageFrame alloc] init];
        messageFrame.chatMessage = message;
        [self.dataSource addObject:messageFrame];
        [self downlodMultimediaMessage:message]; // 下载
    }];
}

// 获取更多数据
- (void)loadMoreChatMessage
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSMutableArray *chatMessages = [NSMutableArray array];
        HYChatMessageFrame *firstMessageFrame = [self.dataSource firstObject];
        [[HYDatabaseHandler sharedInstance] moreGroupChatMessages:chatMessages fromRoomJID:self.roomJid beforeTime:firstMessageFrame.chatMessage.time];
        // 处理数据
        [self.refreshControl endRefreshing];
        if (chatMessages.count == 0) {
            return;
        }
        
        NSMutableArray *tempArray = [NSMutableArray array];
        [chatMessages enumerateObjectsUsingBlock:^(HYChatMessage *message, NSUInteger idx, BOOL * _Nonnull stop) {
            // 判断是否显示时间
            message.timeString = [HYUtils timeStringSince1970:message.time];
            HYChatMessageFrame *lastMessageFrame = [tempArray lastObject];
            message.isHidenTime = [lastMessageFrame.chatMessage.timeString isEqualToString:message.timeString];
            HYChatMessageFrame *messageFrame = [[HYChatMessageFrame alloc] init];
            messageFrame.chatMessage = message;
            [tempArray addObject:messageFrame];
            [self downlodMultimediaMessage:message]; // 下载
        }];
        [tempArray addObjectsFromArray:self.dataSource];
        self.dataSource = tempArray;
        [self.tableView reloadData];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:chatMessages.count - 1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    });
}

#pragma mark - 键盘inputViewControllerDelegate
// 发送照片/视频/文件
- (void)inputViewController:(HYInputViewController *)inputViewController clickExpandType:(HYExpandType)type
{
    self.isShowMultimedia = YES;
    switch (type) {
        case HYExpandTypePicture:{ // 照片
            UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
            pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            pickerController.delegate = self;
            [self presentViewController:pickerController animated:YES completion:nil];
            break;
        }
        case HYExpandTypeCamera:{ // 拍照
            UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
            pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            pickerController.delegate = self;
            [self presentViewController:pickerController animated:YES completion:nil];
            break;
        }
        case HYExpandTypeVideo:{ // 视频
            HYVideoCaptureController *videoVapture = [[HYVideoCaptureController alloc] init];
            videoVapture.modalPresentationStyle = UIModalPresentationOverCurrentContext;// 半透明
            videoVapture.delegate = self;
            [self presentViewController:videoVapture animated:NO completion:nil];
            break;
        }
        case HYExpandTypeFolder:{ // 文件
            
            break;
        }
            
        default:
            break;
    }
}

#pragma mark UIImagePickerControllerDelegate

/**
 *  发送图片
 */
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [picker dismissViewControllerAnimated:YES completion:^{
        
        //获取照片的原图
        UIImage* original = [info objectForKey:UIImagePickerControllerOriginalImage];
        if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
        {
            BOOL saveImage = [[NSUserDefaults standardUserDefaults] boolForKey:HYChatSaveWhenTakePhoto];
            if (saveImage) {
                UIImageWriteToSavedPhotosAlbum(original, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
            }
        }
        //发送消息
        HYChatMessage *message = [[HYChatMessage alloc] init];
        NSString *imageName = [NSString stringWithFormat:@"%@.jpg",message.messageID];
        CGFloat quality = original.size.width > 1600 ? 0.6 : 0.9;
        NSData *imageData = UIImageJPEGRepresentation(original, quality);
        // NSData *imageData = [YYImageEncoder encodeImage:original type:YYImageTypeWebP quality:quality];// webP格式，但是由于太消耗内存，舍弃
        [[YYImageCache sharedCache] setImage:nil imageData:imageData forKey:QN_FullURL(imageName) withType:YYImageCacheTypeAll]; // 设置缓存，重要！！！！
        message.imageUrl = QN_FullURL(imageName);
        [self sendSingleMessage:message withObject:original];
        __weak typeof(self) weakSelf = self;
        [[HYNetworkManager sharedInstance] uploadImage:imageData imageName:imageName successBlock:^(BOOL success) {
            if(success){ // 上传照片成功
                BOOL sendSuccess = [[HYXMPPRoomManager sharedInstance] sendText:[message jsonString] toRoomJid:weakSelf.roomJid];
                if (sendSuccess) {
                    message.sendStatus = HYChatSendMessageStatusSuccess;
                } else {
                    message.sendStatus = HYChatSendMessageStatusFaild;
                }
            } else {
                message.sendStatus = HYChatSendMessageStatusFaild;
            }
            [weakSelf refreshMessage:message];
        }];
        
    }]; // dismiss
    
}

// 指定回调方法
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        HYLog(@"保存相片失败");
    } else {
        HYLog(@"保存相片成功");
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - HYVideoCaptureControllerDelegate

// 上传视频
- (void)videoCaptureController:(HYVideoCaptureController *)videoCaptureController captureVideo:(NSString *)filePath screenShot:(UIImage *)screenShot
{
    //发送消息
    HYChatMessage *message = [[HYChatMessage alloc] init];
    
    NSString *videoName = [filePath lastPathComponent];
    NSString *imageName = [NSString stringWithFormat:@"%@.jpg",[videoName stringByDeletingPathExtension]];
    HYVideoModel *videoModel = [[HYVideoModel alloc] init];
    videoModel.videoThumbImageUrl = QN_FullURL(imageName);
    videoModel.videoUrl = QN_FullURL(videoName);
    videoModel.videoSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize]; // 视频大小
    // NSData *imageData = [YYImageEncoder encodeImage:original type:YYImageTypeWebP quality:quality];// webP格式，但是由于太消耗内存，舍弃
    NSData *imageData = UIImageJPEGRepresentation(screenShot, 0.9);
    [[YYImageCache sharedCache] setImage:nil imageData:imageData forKey:QN_FullURL(imageName) withType:YYImageCacheTypeAll]; // 设置缓存，重要！！！！
    [self sendSingleMessage:message withObject:videoModel];
    // 上传到七牛云
    
    __weak typeof(self) weakSelf = self;
    [[HYNetworkManager sharedInstance] uploadImage:imageData imageName:imageName successBlock:^(BOOL success) { // 上传封面
        if (success) {
            [[HYNetworkManager sharedInstance] uploadFilePath:filePath fileName:videoName successBlock:^(BOOL success) { // 上传视频
                if (success) {
                    BOOL sendSuccess = [[HYXMPPRoomManager sharedInstance] sendText:[message jsonString] toRoomJid:weakSelf.roomJid];
                    if (sendSuccess) {
                        message.sendStatus = HYChatSendMessageStatusSuccess;
                    } else {
                        message.sendStatus = HYChatSendMessageStatusFaild;
                    }
                } else {
                    message.sendStatus = HYChatSendMessageStatusFaild;
                }
                [self refreshMessage:message];
            }];
            
        } else {
            message.sendStatus = HYChatSendMessageStatusFaild;
            [self refreshMessage:message];
        }
    }];
}


// 发送文本/表情消息
- (void)inputViewController:(HYInputViewController *)inputViewController sendText:(NSString *)text
{
    //发送消息
    HYChatMessage *message = [[HYChatMessage alloc] init];
    message.type = HYChatMessageTypeText;
    message.textMessage = text;
    BOOL sendSuccess = [[HYXMPPRoomManager sharedInstance] sendText:[message jsonString] toRoomJid:self.roomJid];
    if (sendSuccess) {
        message.sendStatus = HYChatSendMessageStatusSuccess;
        [self sendSingleMessage:message withObject:text];
    } else {
        message.sendStatus = HYChatSendMessageStatusFaild;
        [self sendSingleMessage:message withObject:text];
    }
    
}

// 发送语音消息
- (void)inputViewController:(HYInputViewController *)inputViewController sendAudioModel:(HYAudioModel *)audioModel
{
    HYChatMessage *message = [[HYChatMessage alloc] init];
    [self sendSingleMessage:message withObject:audioModel];
    __weak typeof(self) weakSelf = self;
    [[HYNetworkManager sharedInstance] uploadFilePath:audioModel.tempEncodeFilePath fileName:[audioModel.tempEncodeFilePath lastPathComponent] successBlock:^(BOOL success) {
        if(success){ // 上传音频文件成功
            BOOL sendSuccess = [[HYXMPPRoomManager sharedInstance] sendText:[message jsonString] toRoomJid:weakSelf.roomJid];
            if (sendSuccess) {
                message.sendStatus = HYChatSendMessageStatusSuccess;
            } else {
                message.sendStatus = HYChatSendMessageStatusFaild;
            }
        } else {
            message.sendStatus = HYChatSendMessageStatusFaild;
        }
        [weakSelf refreshMessage:message];
    }];
}

// 调整高度
- (void)inputViewController:(HYInputViewController *)inputViewController newHeight:(CGFloat)height
{
    self.tableView.contentInset = UIEdgeInsetsMake(64, 0, height, 0);
    if (self.dataSource.count) {
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:self.dataSource.count - 1 inSection:0];
        if ([[self.tableView indexPathsForVisibleRows] containsObject:lastIndexPath]) { // 最后一个row可见
            [self.tableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
        }
    }
}


#pragma mark - HYBaseChatViewCellDelegate
// 点击音频
- (void)chatViewCellClickAudio:(HYBaseChatViewCell *)chatViewCell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:chatViewCell];
    HYChatMessageFrame *messageFrame = [self.dataSource objectAtIndex:indexPath.row];
    HYChatMessage *message = messageFrame.chatMessage;
    if ([self.playingMessageID isEqualToString:message.messageID]) { // 当前播放
        [self.audioPlayer stop];// 停止播放
        message.isRead = YES;
        message.isPlayingAudio = NO;
    } else {
        [self.audioPlayer stop];// 停止播放
        [self.audioPlayer playAudioFile:message.audioModel]; // 播放
        message.isRead = YES;
        message.isPlayingAudio = YES;
        self.playingMessageID = message.messageID;
    }
    [[HYDatabaseHandler sharedInstance] updateGroupChatMessage:message];// 更新数据库操作
    [self.dataSource replaceObjectAtIndex:indexPath.row withObject:messageFrame];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - HYAudioPlayerDelegate 停止播放

- (void)audioPlayer:(HYAudioPlayer *)audioPlay didFinishPlayAudio:(HYAudioModel *)audioFile
{
    NSInteger count = self.dataSource.count;
    for (NSInteger index = 0; index < count; index++) {
        HYChatMessageFrame *messageFrame = [self.dataSource objectAtIndex:index];
        HYChatMessage *message = messageFrame.chatMessage;
        if ([message.messageID isEqualToString:self.playingMessageID]) {
            message.isPlayingAudio = NO;
            self.playingMessageID = nil;
            MAIN(^{
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            });
            return;
        }
    }
}

// 点击头像
- (void)chatViewCell:(HYBaseChatViewCell *)chatViewCell didClickHeaderWithJid:(XMPPJID *)jid
{
    HYUservCardViewController *userVC = [[HYUservCardViewController alloc] init];
    userVC.userJid = jid;
    [self.navigationController pushViewController:userVC animated:YES];
}

// 点击图片
- (void)chatViewCellClickImage:(HYBaseChatViewCell *)chatViewCell
{
    NSMutableArray *photos = [NSMutableArray array];
    [self.dataSource enumerateObjectsUsingBlock:^(HYChatMessageFrame *messageFrame, NSUInteger idx, BOOL * _Nonnull stop) {
        HYChatMessage *message = messageFrame.chatMessage;
        if (message.imageUrl.length) {
            [photos addObject:message.imageUrl];
        }
    }];
    NSInteger currentImageIndex = photos.count - 1;;
    for (NSInteger index = 0; index < photos.count; index++) {
        NSString *imageUrl = [photos objectAtIndex:index];
        if ([imageUrl isEqualToString:chatViewCell.messageFrame.chatMessage.imageUrl]) {
            currentImageIndex = index;
            break;
        }
    }
    self.isShowMultimedia = YES;
    HYPhotoBrowserController *photoBrowser = [[HYPhotoBrowserController alloc] init];
    photoBrowser.currentImageIndex = currentImageIndex;
    photoBrowser.dataSource = photos;
    [self presentViewController:photoBrowser animated:YES completion:nil];
}

// 点击视频
- (void)chatViewCellClickVideo:(HYBaseChatViewCell *)chatViewCell
{
    self.isShowMultimedia = YES;
    HYChatMessageFrame *messsageFrame = chatViewCell.messageFrame;
    HYVideoModel *videoModel = messsageFrame.chatMessage.videoModel;
    HYVideoPlayController *playController = [[HYVideoPlayController alloc] initWithPath:videoModel.videoLocalPath];
    [self presentViewController:playController animated:YES completion:nil];
}

// 删除消息
- (void)chatViewCellDelete:(HYBaseChatViewCell *)chatViewCell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:chatViewCell];
    [[HYDatabaseHandler sharedInstance] deleteGroupChatMessage:chatViewCell.messageFrame.chatMessage];
    [self.dataSource removeObjectAtIndex:indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

// 转发
- (void)chatViewCellForward:(HYBaseChatViewCell *)chatViewCell
{
    HYForwardingViewController *forwardingVC = [[HYForwardingViewController alloc] init];
    forwardingVC.message = chatViewCell.messageFrame.chatMessage;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:forwardingVC] animated:YES completion:nil];
}

// 重发
- (void)chatViewCellReSend:(HYBaseChatViewCell *)chatViewCell
{
    HYChatMessageFrame *messsageFrame = chatViewCell.messageFrame;
    HYChatMessage *message = messsageFrame.chatMessage;
    switch (message.type) {
        case HYChatMessageTypeText:{ // 文本
            BOOL sendSuccess = [[HYXMPPRoomManager sharedInstance] sendText:[message jsonString] toRoomJid:self.roomJid];
            if (sendSuccess) {
                message.sendStatus = HYChatSendMessageStatusSuccess;
            } else {
                message.sendStatus = HYChatSendMessageStatusFaild;
            }
            [self refreshMessage:message];
            break;
        }
        case HYChatMessageTypeImage:{ // 图片
            NSString *imageName = [NSString stringWithFormat:@"%@.jpg",message.messageID];
            NSData *imageData = [[YYImageCache sharedCache] getImageDataForKey:QN_FullURL(imageName)]; // 从缓存读取图片
            message.sendStatus = HYChatSendMessageStatusSending;
            [self refreshMessage:message]; // 刷新
            __weak typeof(self) weakSelf = self;
            [[HYNetworkManager sharedInstance] uploadImage:imageData imageName:imageName successBlock:^(BOOL success) {
                if(success){ // 上传照片成功
                    BOOL sendSuccess = [[HYXMPPRoomManager sharedInstance] sendText:[message jsonString] toRoomJid:weakSelf.roomJid];
                    if (sendSuccess) {
                        message.sendStatus = HYChatSendMessageStatusSuccess;
                    } else {
                        message.sendStatus = HYChatSendMessageStatusFaild;
                    }
                } else {
                    message.sendStatus = HYChatSendMessageStatusFaild;
                }
                [weakSelf refreshMessage:message];
            }];
            break;
        }
        case HYChatMessageTypeAudio:{ // 音频
            message.sendStatus = HYChatSendMessageStatusSending;
            [self refreshMessage:message]; // 刷新
            __weak typeof(self) weakSelf = self;
            [[HYNetworkManager sharedInstance] uploadFilePath:message.audioModel.tempEncodeFilePath fileName:[message.audioModel.tempEncodeFilePath lastPathComponent] successBlock:^(BOOL success) {
                if(success){ // 上传音频文件成功
                    BOOL sendSuccess = [[HYXMPPRoomManager sharedInstance] sendText:[message jsonString] toRoomJid:weakSelf.roomJid];
                    if (sendSuccess) {
                        message.sendStatus = HYChatSendMessageStatusSuccess;
                    } else {
                        message.sendStatus = HYChatSendMessageStatusFaild;
                    }
                } else {
                    message.sendStatus = HYChatSendMessageStatusFaild;
                }
                [weakSelf refreshMessage:message];
            }];
            break;
        }
            
        case HYChatMessageTypeVideo:{ // 视频
            
            NSString *filePath = message.videoModel.videoLocalPath;
            NSString *videoName = [filePath lastPathComponent];
            NSString *imageName = [NSString stringWithFormat:@"%@.jpg",[videoName stringByDeletingPathExtension]];
            NSData *imageData = [[YYImageCache sharedCache] getImageDataForKey:QN_FullURL(imageName)]; // 从缓存读取图片
            message.sendStatus = HYChatSendMessageStatusSending;
            [self refreshMessage:message]; // 刷新
            // 上传到七牛云
            __weak typeof(self) weakSelf = self;
            [[HYNetworkManager sharedInstance] uploadImage:imageData imageName:imageName successBlock:^(BOOL success) { // 上传封面
                if (success) {
                    [[HYNetworkManager sharedInstance] uploadFilePath:filePath fileName:videoName successBlock:^(BOOL success) { // 上传视频
                        if (success) {
                            BOOL sendSuccess = [[HYXMPPRoomManager sharedInstance] sendText:[message jsonString] toRoomJid:weakSelf.roomJid];
                            if (sendSuccess) {
                                message.sendStatus = HYChatSendMessageStatusSuccess;
                            } else {
                                message.sendStatus = HYChatSendMessageStatusFaild;
                            }
                        } else {
                            message.sendStatus = HYChatSendMessageStatusFaild;
                        }
                        [self refreshMessage:message];
                    }];
                    
                } else {
                    message.sendStatus = HYChatSendMessageStatusFaild;
                    [self refreshMessage:message];
                }
            }];
            break;
        }
            
        default:
            break;
    }
}

/**
 *  控制keyboard显示
 */
- (void)settingKeyboard
{
    CGRect section = [self.tableView rectForSection:0];
    CGFloat h = CGRectGetHeight(self.view.bounds) - 64 - section.size.height;
    if (h > kPanelHeight) {
        self.inputVC.onlyMoveKeyboard = YES;// 数据太少就不整体向上移动
    } else {
        self.inputVC.onlyMoveKeyboard = NO;// 整体向上移动
    }
}

#pragma mark - 发送消息

- (void)sendSingleMessage:(HYChatMessage *)chatMessage withObject:(id)obj
{
    if ([obj isKindOfClass:[NSString class]]) {
        chatMessage.type = HYChatMessageTypeText;
        chatMessage.textMessage = obj;
    }else if ([obj isKindOfClass:[HYAudioModel class]]) { // 语音
        chatMessage.type = HYChatMessageTypeAudio;
        chatMessage.audioModel = obj;
        chatMessage.sendStatus = HYChatSendMessageStatusSending;
    } else if ([obj isKindOfClass:[UIImage class]]) { // 图片
        UIImage *image = (UIImage *)obj;
        chatMessage.type = HYChatMessageTypeImage;
        chatMessage.imageWidth = image.size.width;
        chatMessage.imageHeight = image.size.height;
        chatMessage.sendStatus = HYChatSendMessageStatusSending;
    } else if ([obj isKindOfClass:[HYVideoModel class]]) { // 视频
        chatMessage.type = HYChatMessageTypeVideo;
        chatMessage.videoModel = obj;
        chatMessage.sendStatus = HYChatSendMessageStatusSending;
    }
    chatMessage.jid = [XMPPJID jidWithString:self.roomJid.bare resource:[HYXMPPRoomManager sharedInstance].xmppStream.myJID.user];
    chatMessage.time = [[NSDate date] timeIntervalSince1970];
    chatMessage.isRead = YES;
    chatMessage.isOutgoing = YES;
    chatMessage.isGroup = NO;
    // 判断是否显示时间
    chatMessage.timeString = [HYUtils timeStringSince1970:chatMessage.time];
    HYChatMessageFrame *lastMessageFrame = [self.dataSource lastObject];
    chatMessage.isHidenTime = [lastMessageFrame.chatMessage.timeString isEqualToString:chatMessage.timeString];
    HYChatMessageFrame *messageFrame = [[HYChatMessageFrame alloc] init];
    messageFrame.chatMessage = chatMessage;
    [self.dataSource addObject:messageFrame];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.dataSource.count - 1 inSection:0];
    MAIN(^{
        [[HYDatabaseHandler sharedInstance] addGroupChatMessage:chatMessage]; // 储存
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
    });
    
}


#pragma mark - 接收消息通知

- (void)receiveGroupMessage:(NSNotification *)noti
{
    HYChatMessage *message = noti.object;
    if (![message.jid.bare isEqualToString:self.roomJid.bare]) {
        return;
    }
    // 判断是否显示时间
    message.timeString = [HYUtils timeStringSince1970:message.time];
    HYChatMessageFrame *lastMessageFrame = [self.dataSource lastObject];
    message.isHidenTime = [lastMessageFrame.chatMessage.timeString isEqualToString:message.timeString];
    HYChatMessageFrame *messageFrame = [[HYChatMessageFrame alloc] init];
    messageFrame.chatMessage = message;
    [self.dataSource addObject:messageFrame];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.dataSource.count - 1 inSection:0];
    MAIN(^{
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
    });
    [self downlodMultimediaMessage:message]; // 下载
}

/**
 *  下载音频、视频
 */

- (void)downlodMultimediaMessage:(HYChatMessage *)message
{
    __weak typeof(self) weakSelf = self;
    if (message.type == HYChatMessageTypeAudio) {// 下载audio
        [[HYNetworkManager sharedInstance] downloadAudioModel:message.audioModel successBlock:^(BOOL success) {
            if (success) {
                message.receiveStatus = HYChatReceiveMessageStatusSuccess;
            } else {
                message.receiveStatus = HYChatReceiveMessageStatusFaild;
            }
            [weakSelf refreshMessage:message];
        }];
    } else if (message.type == HYChatMessageTypeVideo) {// 下载视频
        [[HYNetworkManager sharedInstance] downloadVideoUrl:message.videoModel.videoUrl successBlock:^(BOOL success) {
            if (success) {
                message.receiveStatus = HYChatReceiveMessageStatusSuccess;
            } else {
                message.receiveStatus = HYChatReceiveMessageStatusFaild;
            }
            [weakSelf refreshMessage:message];
        }];
    }
}


#pragma mark - 更新消息

- (void)refreshMessage:(HYChatMessage *)message
{
    NSInteger count = self.dataSource.count;
    for (NSInteger index = 0; index < count; index++) {
        HYChatMessageFrame *messageFrame = [self.dataSource objectAtIndex:index];
        HYChatMessage *chatMessage = messageFrame.chatMessage;
        if ([chatMessage.messageID isEqualToString:message.messageID]) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            MAIN(^{
                [[HYDatabaseHandler sharedInstance] updateGroupChatMessage:chatMessage];// 更新数据库
                if ([[self.tableView indexPathsForVisibleRows] containsObject:indexPath]) { // row可见才需要刷新
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                }
                
            });
            return;
        }
    }
}

- (void)resignActive:(NSNotification *)noti
{
    [HYXMPPManager sharedInstance].chatJID = nil;
    [self.inputVC resignFirstResponder];
}

- (void)becomeActive:(NSNotification *)noti
{
    [HYXMPPManager sharedInstance].chatJID = self.roomJid;
    [self getChatHistory];
    [self.tableView reloadData];
}

- (void)roomInfo:(id)sender
{
    HYGroupInfoViewController *groupInfo = [[HYGroupInfoViewController alloc] init];
    groupInfo.roomJid = self.roomJid;
    [self.navigationController pushViewController:groupInfo animated:YES];
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

- (void)dealloc
{
    self.dataSource = nil;
    self.inputVC = nil;
    [HYXMPPManager sharedInstance].chatJID = nil;
    [HYNotification removeObserver:self];
    HYLog(@"%@-dealloc",self);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*
 - (void)getChatHistory
 {
 // 1.上下文
 NSManagedObjectContext *context = [[HYXMPPRoomManager sharedInstance] managedObjectContext_room];
 if (context == nil) { // 防止xmppStream没有连接会崩溃
 return;
 }
 // 2.Fetch请求
 NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"XMPPRoomMessageCoreDataStorageObject"];
 // 3.过滤
 NSPredicate *predicate = [NSPredicate predicateWithFormat:@"roomJIDStr == %@ AND streamBareJidStr == %@",self.roomJid.bare, [HYXMPPManager sharedInstance].myJID.bare];
 [fetchRequest setPredicate:predicate];
 // 4.排序(降序)
 NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"localTimestamp" ascending:YES];
 [fetchRequest setSortDescriptors:@[sortDescriptor]];
 //    [fetchRequest setFetchLimit:20]; // 分页
 //    [fetchRequest setFetchOffset:0];
 
 // 5.执行查询获取数据
 _resultController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
 _resultController.delegate=self;
 // 6.执行
 NSError *error=nil;
 if(![_resultController performFetch:&error]){
 HYLog(@"%s---%@",__func__,error);
 } else {
 [self.dataSource removeAllObjects];
 [_resultController.fetchedObjects enumerateObjectsUsingBlock:^(XMPPRoomMessageCoreDataStorageObject *object, NSUInteger idx, BOOL * _Nonnull stop) {
 HYChatMessageFrame *messageFrame = [self chatmessageFrameFromObject:object];
 [self.dataSource addObject:messageFrame]; // 添加到数据源
 }];
 }
 }
 
 #pragma mark - NSFetchedResultsControllerDelegate
 // 数据更新
 - (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath
 {
 XMPPRoomMessageCoreDataStorageObject *object = anObject;
 if (object.body.length == 0) return; // 如果body为空，返回
 HYChatMessageFrame *messageFrame = [self chatmessageFrameFromObject:object];
 switch (type) {
 case NSFetchedResultsChangeInsert:{ // 插入
 [self.dataSource addObject:messageFrame];
 [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.dataSource.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
 [self scrollToBottom];
 break;
 }
 case NSFetchedResultsChangeDelete:{ // 删除
 [self.dataSource removeObjectAtIndex:indexPath.row];
 [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
 break;
 }
 case NSFetchedResultsChangeMove:{ // 移动
 break;
 }
 case NSFetchedResultsChangeUpdate:{ // 更新
 [self.dataSource removeObjectAtIndex:indexPath.row];
 [self.dataSource insertObject:messageFrame atIndex:indexPath.row];
 [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
 break;
 }
 default:
 break;
 }
 }
 
 #pragma mark - 转换模型
 
 - (HYChatMessageFrame *)chatmessageFrameFromObject:(XMPPRoomMessageCoreDataStorageObject *)object
 {
 HYChatMessage *message = [[HYChatMessage alloc] initWithJsonString:object.body];
 message.jid = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@@%@",object.jid.resource,[HYXMPPManager sharedInstance].myJID.domain]];
 message.isOutgoing = object.isFromMe;
 message.timeString = [HYUtils timeStringFromDate:object.localTimestamp];
 // 判断是否显示时间
 HYChatMessageFrame *lastMessageFrame = [self.dataSource lastObject];
 message.isHidenTime = [lastMessageFrame.chatMessage.timeString isEqualToString:message.timeString];
 // 计算message的Frame
 HYChatMessageFrame *messageFrame = [[HYChatMessageFrame alloc] init];
 messageFrame.chatMessage = message;
 return messageFrame;
 }
 
 */
@end
