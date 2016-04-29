//
//  HYVoiceChatViewCell.m
//  HYChatProject
//
//  Created by erpapa on 16/4/28.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYVoiceChatViewCell.h"

@interface HYVoiceChatViewCell()
@property (nonatomic, strong) UIImageView *voiceView;
@property (nonatomic, strong) UILabel *voiceLabel;
@end

@implementation HYVoiceChatViewCell

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
    
}

- (void)setMessageFrame:(HYChatMessageFrame *)messageFrame
{
    [super setMessageFrame:messageFrame];
}

@end
