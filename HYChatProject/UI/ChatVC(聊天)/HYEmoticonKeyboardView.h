//
//  HYEmoticonKeyboardView.h
//  HYChatProject
//
//  Created by erpapa on 16/4/30.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HYEmoticonKeyboardViewDelegate <NSObject>
@optional
@optional
- (void)emoticonKeyboardDidTapText:(NSString *)text;
- (void)emoticonKeyboardDidTapBackspace;
- (void)emoticonKeyboardDidTapSendButton;
@end

@interface HYEmoticonKeyboardView : UIView
@property (nonatomic, weak) id<HYEmoticonKeyboardViewDelegate> delegate;
@end
