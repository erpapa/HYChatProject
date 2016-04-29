//
//  HYVideoChatViewCell.m
//  HYChatProject
//
//  Created by erpapa on 16/4/28.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYVideoChatViewCell.h"

@interface HYVideoChatViewCell()
@property (nonatomic, strong) UIImageView *videoView;

@end

@implementation HYVideoChatViewCell

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
