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
    self.textView.numberOfLines = 0;
    self.textView.textVerticalAlignment = YYTextVerticalAlignmentTop;
    self.textView.displaysAsynchronously = YES;
    self.textView.ignoreCommonProperties = YES;
    self.textView.fadeOnAsynchronouslyDisplay = NO;
    self.textView.fadeOnHighlight = NO;
    [self.contentImageView addSubview:self.textView];
}

- (void)setMessageFrame:(HYChatMessageFrame *)messageFrame
{
    [super setMessageFrame:messageFrame];
    HYChatMessage *message = messageFrame.chatMessage;
    self.textView.textLayout = message.textLayout;
    self.textView.frame = messageFrame.textViewFrame;
}

@end
