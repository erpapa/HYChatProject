//
//  HYInputViewController.h
//  HYChatProject
//
//  Created by erpapa on 16/4/29.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kInputBarHeight 50         // 工具条高度
#define kPanelHeight 216           // 表情面板高度

@class HYInputViewController, HYChatMessage;
@protocol HYInputViewControllerDelegate <NSObject>
@optional
- (void)inputViewController:(HYInputViewController *)inputViewController newHeight:(CGFloat)height; // 调整高度
- (void)inputViewController:(HYInputViewController *)inputViewController sendMessage:(HYChatMessage *)message;
@end

@interface HYInputViewController : UIViewController
@property (nonatomic, weak) id<HYInputViewControllerDelegate> delegate;
@end
