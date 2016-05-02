//
//  HYExpandKeyboardView.h
//  HYChatProject
//
//  Created by erpapa on 16/4/30.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HYExpandKeyboardViewDelegate <NSObject>
@optional

@end

@interface HYExpandKeyboardView : UIView
@property (nonatomic, weak) id<HYExpandKeyboardViewDelegate> delegate;
@end
