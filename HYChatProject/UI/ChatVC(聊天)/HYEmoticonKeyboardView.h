//
//  HYEmoticonInputView.h
//  HYChatProject
//
//  Created by erpapa on 16/4/30.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HYEmoticonKeyboardViewDelegate <NSObject>
@optional

@end

@interface HYEmoticonKeyboardView : UIView
@property (nonatomic, weak) id<HYEmoticonKeyboardViewDelegate> delegate;
+ (instancetype)sharedView;
@end
