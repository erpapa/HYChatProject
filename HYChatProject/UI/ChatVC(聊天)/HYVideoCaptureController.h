//
//  HYVideoCaptureController.h
//  HYChatProject
//
//  Created by erpapa on 16/5/12.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HYVideoCaptureController;
@protocol HYVideoCaptureControllerDelegate <NSObject>
@optional
- (void)videoCaptureController:(HYVideoCaptureController *)videoCaptureController captureVideo:(NSString *)filePath screenShot:(UIImage *)screenShot;
@end

@interface HYVideoCaptureController : UIViewController
@property (nonatomic, weak) id<HYVideoCaptureControllerDelegate> delegate;
@end
