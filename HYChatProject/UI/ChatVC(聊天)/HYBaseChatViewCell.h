//
//  HYChatViewCell.h
//  HYChatProject
//
//  Created by erpapa on 16/4/28.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HYChatMessageFrame.h"

@class HYBaseChatViewCell;
@protocol HYBaseChatViewCellDelegate <NSObject>
- (void)chatViewCell:(HYBaseChatViewCell *)chatViewCell didClickHeaderWithJid:(XMPPJID *)jid; // 点击头像
- (void)chatViewCellDelete:(HYBaseChatViewCell *)chatViewCell;     // 删除
- (void)chatViewCellForward:(HYBaseChatViewCell *)chatViewCell;    // 转发
- (void)chatViewCellReSend:(HYBaseChatViewCell *)chatViewCell;     // 重发
- (void)chatViewCellClickImage:(HYBaseChatViewCell *)chatViewCell; // 点击语音
- (void)chatViewCellClickVoice:(HYBaseChatViewCell *)chatViewCell; // 点击语音
- (void)chatViewCellClickVideo:(HYBaseChatViewCell *)chatViewCell; // 点击视频
@end

@interface HYBaseChatViewCell : UITableViewCell
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIButton *contentBgView;
@property (nonatomic, strong) UIImageView *headView;
@property (nonatomic, strong) HYChatMessageFrame *messageFrame;
@property (nonatomic, weak) id<HYBaseChatViewCellDelegate> delegate;

- (void)showPopMenu:(UILongPressGestureRecognizer *)sender; // 长按
- (void)copyMesssage:(UIMenuItem *)item; // 复制消息
- (void)forwardMessage:(UIMenuItem *)item; // 转发消息
- (void)deleteMessage:(UIMenuItem *)item; // 删除消息
- (void)reSendMessage:(UIMenuItem *)item; // 发送失败(重新发送)
@end
