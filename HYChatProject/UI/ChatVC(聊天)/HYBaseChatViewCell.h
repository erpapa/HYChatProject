//
//  HYChatViewCell.h
//  HYChatProject
//
//  Created by erpapa on 16/4/28.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HYChatMessageFrame.h"

@protocol HYBaseChatViewCellDelegate <NSObject>

@end

@interface HYBaseChatViewCell : UITableViewCell
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIImageView *contentImageView;
@property (nonatomic, strong) UIImageView *headView;
@property (nonatomic, strong) HYChatMessageFrame *messageFrame;
@property (nonatomic, weak) id<HYBaseChatViewCellDelegate> delegate;

- (void)showLongPressMenu:(UILongPressGestureRecognizer *)sender; // 长按
- (void)copyMesssage:(UIMenuItem *)item; // 复制消息
- (void)forwardMessage:(UIMenuItem *)item; // 转发消息
- (void)deleteMessage:(UIMenuItem *)item; // 删除消息
- (void)reSendMessage:(UIMenuItem *)item; // 发送失败(重新发送)
@end
