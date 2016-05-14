//
//  HYPhotoNetwork.h
//  HYChatProject
//
//  Created by erpapa on 16/5/12.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HYQNAuthPolicy.h"
#import "HYAudioModel.h"

typedef void (^HYPhotoNetworkDidUploadSuccessBlock) (BOOL success); // 上传成功/失败
typedef void (^HYPhotoNetworkDidDownloadSuccessBlock) (BOOL success); // 上传成功/失败

@interface HYNetworkManager : NSObject

+ (instancetype)sharedInstance;
/* 开始上传指定文件 */
- (void)uploadImage:(NSData *)imageData imageName:(NSString *)imageName successBlock:(HYPhotoNetworkDidUploadSuccessBlock)successBlock;

- (void)uploadFilePath:(NSString *)filePath fileName:(NSString *)fileName successBlock:(HYPhotoNetworkDidUploadSuccessBlock)successBlock;

/* 下载文件 */
- (void)downloadVideoUrl:(NSString *)videoUrl successBlock:(HYPhotoNetworkDidDownloadSuccessBlock)successBlock;
- (void)downloadAudioModel:(HYAudioModel *)audioModel successBlock:(HYPhotoNetworkDidDownloadSuccessBlock)successBlock;

@end
