//
//  HYImageChatViewCell.m
//  HYChatProject
//
//  Created by erpapa on 16/4/28.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYImageChatViewCell.h"
#import "YYWebImage.h"

@interface HYImageChatViewCell()
@property (nonatomic, strong) UIImageView *photoView;

@end

@implementation HYImageChatViewCell

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
    // 图片
    self.photoView = [[UIImageView alloc] init];
    self.photoView.layer.cornerRadius = 4;
    self.photoView.layer.masksToBounds = YES;
    self.photoView.contentMode = UIViewContentModeScaleAspectFill;
    self.photoView.backgroundColor = [UIColor colorWithRed:211/255.0 green:211/255.0 blue:211/255.0 alpha:1.0f];
    [self.contentBgView addSubview:self.photoView];
    
    //tap
    UITapGestureRecognizer *tapR = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapOnSelf)];
    tapR.numberOfTapsRequired = 1;
    [self.contentBgView addGestureRecognizer:tapR];
}

- (void)setMessageFrame:(HYChatMessageFrame *)messageFrame
{
    [super setMessageFrame:messageFrame];
    HYChatMessage *message = messageFrame.chatMessage;
    self.photoView.frame = self.contentBgView.bounds;
    UIImage *normalImage = nil;
    if (message.isOutgoing) {
         normalImage =[[UIImage imageNamed:@"chat_send_nor"] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 40, 30, 70) resizingMode:UIImageResizingModeStretch];
    } else {
        normalImage = [[UIImage imageNamed:@"chat_receive_nor"] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 40, 30, 70) resizingMode:UIImageResizingModeStretch];
    }
    [self makeMaskView:self.photoView withImage:normalImage]; // 设置mask，遮盖
    if (message.image) {
        self.photoView.image = message.image;
    } else {
        [self.photoView yy_setImageWithURL:[NSURL URLWithString:message.imageUrl] placeholder:[UIImage imageNamed:@"chat_images_failed"] options:YYWebImageOptionProgressive completion:nil];
    }
    
    
    
}

- (void)makeMaskView:(UIView *)view withImage:(UIImage *)image
{
    UIImageView *imageViewMask = [[UIImageView alloc] initWithImage:image];
    imageViewMask.frame = CGRectInset(view.frame, 0.0f, 0.0f);
    view.layer.mask = imageViewMask.layer;
}

- (void)tapOnSelf
{
    if ([self.delegate respondsToSelector:@selector(chatViewCellClickImage:)]) {
        [self.delegate chatViewCellClickImage:self];
    }
}

#pragma mark - 继承方法

- (void)showPopMenu:(UILongPressGestureRecognizer *)sender
{
    [super showPopMenu:sender];
    UIMenuController *popMenu = [UIMenuController sharedMenuController];
    if (popMenu.isMenuVisible) {
        return;
    }
    UIMenuItem *item1 = [[UIMenuItem alloc] initWithTitle:@"删除" action:@selector(deleteMessage:)];
    UIMenuItem *item2;
    if (self.messageFrame.chatMessage.sendStatus == HYChatSendMessageStatusFaild) {
        item2 = [[UIMenuItem alloc] initWithTitle:@"重发" action:@selector(reSendMessage:)];
    } else {
        item2 = [[UIMenuItem alloc] initWithTitle:@"转发" action:@selector(forwardMessage:)];
    }
    [popMenu setMenuItems:@[item1,item2]];
    [popMenu setArrowDirection:UIMenuControllerArrowDown];
    
    [popMenu setTargetRect:self.contentBgView.frame inView:self];
    [popMenu setMenuVisible:YES animated:YES];
}

- (void)deleteMessage:(UIMenuItem *)item
{
    if ([self.delegate respondsToSelector:@selector(chatViewCellDelete:)]) {
        [self.delegate chatViewCellDelete:self];
    }
}

- (void)forwardMessage:(UIMenuItem *)item
{
    if ([self.delegate respondsToSelector:@selector(chatViewCellForward:)]) {
        [self.delegate chatViewCellForward:self];
    }
}


- (void)reSendMessage:(UIMenuItem *)item
{
    if ([self.delegate respondsToSelector:@selector(chatViewCellReSend:)]) {
        [self.delegate chatViewCellReSend:self];
    }
}

@end
