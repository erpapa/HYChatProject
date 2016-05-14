//
//  HYEncodeAndDecode.h
//  HYChatProject
//
//  Created by erpapa on 16/5/12.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HYAudioModel.h"

/*
 * iOS 支持自身的格式是Wav格式，
 * 我们将需要转成Wav格式的文件都认为是临时编码文件
 */
@interface HYEncodeAndDecode : NSObject

/* 将音频文件转为AMR格式，会为其创建AMR编码的临时文件 */
+ (BOOL)convertAudioFileToAMR:(HYAudioModel *)audioFile;

/* 将音频文件转为WAV格式 */
+ (BOOL)convertAudioFileToWAV:(HYAudioModel *)audioFile;

@end
