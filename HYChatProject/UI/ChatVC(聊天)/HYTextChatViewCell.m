//
//  HYTextChatViewCell.m
//  HYChatProject
//
//  Created by erpapa on 16/4/28.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYTextChatViewCell.h"
#import "YYText.h"

@interface HYTextChatViewCell()
@property (nonatomic, strong) YYLabel *textView; // 富文本

@end

@implementation HYTextChatViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupContentView];
    }
    return self;
}

- (void)setupContentView
{
    self.textView = [[YYLabel alloc] init];
    self.textView.textVerticalAlignment = YYTextVerticalAlignmentTop;
    self.textView.displaysAsynchronously = YES;
    self.textView.ignoreCommonProperties = YES;
    self.textView.fadeOnAsynchronouslyDisplay = NO;
    self.textView.fadeOnHighlight = NO;
    [self.contentBgView addSubview:self.textView];
}

- (void)setMessageFrame:(HYChatMessageFrame *)messageFrame
{
    [super setMessageFrame:messageFrame];
    self.textView.frame = messageFrame.textViewFrame;
    self.textView.textLayout = messageFrame.chatMessage.textLayout;
}

#pragma mark - 继承方法

- (void)showPopMenu:(UILongPressGestureRecognizer *)sender
{
    [super showPopMenu:sender];
    UIMenuController *popMenu = [UIMenuController sharedMenuController];
    if (popMenu.isMenuVisible) {
        return;
    }
    
    UIMenuItem *item1 = [[UIMenuItem alloc] initWithTitle:@"复制" action:@selector(copyMesssage:)];
    UIMenuItem *item2 = [[UIMenuItem alloc] initWithTitle:@"删除" action:@selector(deleteMessage:)];
    UIMenuItem *item3 = [[UIMenuItem alloc] initWithTitle:@"转发" action:@selector(forwardMessage:)];
    NSArray *menuItems = @[item1,item2,item3];
    [popMenu setMenuItems:menuItems];
    [popMenu setArrowDirection:UIMenuControllerArrowDown];
    
    [popMenu setTargetRect:self.contentBgView.frame inView:self];
    [popMenu setMenuVisible:YES animated:YES];
}


- (void)copyMesssage:(UIMenuItem *)item
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setString:self.messageFrame.chatMessage.textMessage];
}

- (void)deleteMessage:(UIMenuItem *)item
{
    
}

- (void)forwardMessage:(UIMenuItem *)item
{
    
}


- (void)reSendMessage:(UIMenuItem *)item
{
    
}
@end
