//
//  HYPhotoNetwork.h
//  HYChatProject
//
//  Created by erpapa on 16/5/12.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HYQNAuthPolicy.h"

typedef void (^HYPhotoNetworkDidUploadSuccessBlock) (BOOL success); // 上传成功/失败
typedef void (^HYPhotoNetworkDidDownloadSuccessBlock) (BOOL success); // 上传成功/失败

@interface HYUploadNetwork : NSObject

+ (instancetype)sharedInstance;
/* 开始上传指定文件 */
- (void)startUploadImage:(UIImage *)image imageName:(NSString *)imageName successBlock:(HYPhotoNetworkDidUploadSuccessBlock)successBlock;

- (void)startUploadVideo:(NSString *)filePath videoName:(NSString *)videoName successBlock:(HYPhotoNetworkDidUploadSuccessBlock)successBlock;

- (void)startDownloadVideoUrl:(NSString *)videoUrl successBlock:(HYPhotoNetworkDidDownloadSuccessBlock)successBlock;

@end
