//
//  HYInputBar.h
//  HYChatProject
//
//  Created by erpapa on 16/4/30.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HYInputKeyboardBarDelegate <NSObject>
@optional

@end

@interface HYInputKeyboardBar : UIView
@property (nonatomic, weak) id<HYInputKeyboardBarDelegate> delegate;
@end
