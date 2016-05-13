//
//  HYExpandKeyboardView.h
//  HYChatProject
//
//  Created by erpapa on 16/4/30.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kInputBarHeight 50         // 工具条高度
#define kPanelHeight 216           // 面板高度

typedef NS_ENUM(NSInteger, HYExpandType) {
    HYExpandTypePicture,      // 照片
    HYExpandTypeCamera,       // 拍照
    HYExpandTypeVideo,        // 视频
    HYExpandTypeFolder        // 文件
};

@class HYExpandKeyboardView;
@protocol HYExpandKeyboardViewDelegate <NSObject>
@optional

- (void)expandKeyboardView:(HYExpandKeyboardView *)expandKeyboardView clickWithType:(HYExpandType)type;

@end

@interface HYExpandKeyboardView : UIView
@property (nonatomic, weak) id<HYExpandKeyboardViewDelegate> delegate;
@end

@interface HYExpandButton : UIButton

@end
