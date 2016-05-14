//
//  HYPhotoBrowerController.h
//  HYChatProject
//
//  Created by erpapa on 16/5/13.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger, HYIndicatorViewMode) {
    HYIndicatorViewModeLoopDiagram, // 环形
    HYIndicatorViewModePieDiagram // 饼型
};

@interface HYIndicatorView : UIView
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) HYIndicatorViewMode viewMode; //显示模式
@end

@interface HYPhotoBrowserView : UICollectionViewCell
@property (nonatomic, strong) UIScrollView *scrollview;
@property (nonatomic, strong) UIImageView *imageview;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) BOOL beginLoadingImage;
@property (nonatomic, assign) BOOL isFullWidthForLandScape; //是否在横屏的时候直接满宽度，而不是满高度，一般是在有长图需求的时候设置为YES


//单击回调
@property (nonatomic, strong) void (^singleTapBlock)(UITapGestureRecognizer *recognizer);

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder;
@end

@interface HYPhotoBrowserController : UIViewController

@property (nonatomic, assign) CGRect sourceImageRect;      // 图片位置
@property (nonatomic, assign) NSInteger currentImageIndex; // 当前index
@property (nonatomic, strong) NSArray *dataSource;         // 图片链接数组

@end
