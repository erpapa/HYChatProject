//
//  HYEncodeAndDecode.h
//  HYChatProject
//
//  Created by erpapa on 16/5/12.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYEncodeAndDecode.h"
#import "VoiceConverter.h"
#import "HYUtils.h"

@implementation HYEncodeAndDecode

/* 将音频文件转为AMR格式，会为其创建AMR编码的临时文件 */
+ (BOOL)convertAudioFileToAMR:(HYAudioModel *)audioFile
{
    /* 如果没有WAV的缓存路径，那么是不能转的 */
    if (!audioFile.localStorePath) {
        
        NSLog(@"HYEncodeAndDecode 错误:没有可转码的本地Wav文件路径");
        
        return NO;
    }
    
    /* 设置一个amr临时编码文件的路径 */
    if (!audioFile.tempEncodeFilePath) {
        NSString *fileName = audioFile.tempEncodeFilePath.lastPathComponent;
        NSString *amrName = [NSString stringWithFormat:@"%@.amr",fileName.stringByDeletingPathExtension];
        audioFile.tempEncodeFilePath = [HYUtils audioTempEncodeFilePath:amrName];

    }
    
    if (!audioFile.tempEncodeFilePath) {
        
        NSLog(@"HYEncodeAndDecode 错误:没有可以保存转码音频文件的路径");
        
        return NO;
    }
    
    /* 开始转换 */
    int result = [VoiceConverter wavToAmr:audioFile.localStorePath amrSavePath:audioFile.tempEncodeFilePath];
    
    if (result) {
        
        NSLog(@"HYEncodeAndDecode wavToAmr 成功:%@",audioFile.tempEncodeFilePath);
        
    }else{
        
        NSLog(@"HYEncodeAndDecode wavToAmr 失败:%@",audioFile.tempEncodeFilePath);
        
    }
    
    return result;
}

/* 将音频文件转为WAV格式 */
+ (BOOL)convertAudioFileToWAV:(HYAudioModel *)audioFile
{
    /* 如果没有临时编码文件的缓存路径，那么是不能转的 */
    if (!audioFile.tempEncodeFilePath) {
        
        NSLog(@"HYEncodeAndDecode 错误:没有可以用来转码的临时音频文件");
        
        return NO;
    }
    
    /* 设置一个需要转成Wav存储的路径 */
    if (!audioFile.localStorePath) {
        NSString *fileName = audioFile.tempEncodeFilePath.lastPathComponent;
        NSString *wavName = [NSString stringWithFormat:@"%@.wav",fileName.stringByDeletingPathExtension];
        audioFile.localStorePath = [HYUtils audioCachePath:wavName];

    }
    
    if (!audioFile.localStorePath) {
        
        NSLog(@"HYEncodeAndDecode 错误:没有可以用来保存本地Wav文件的路径");

        return NO;
    }
    
    /* 开始转换 */
    int result = [VoiceConverter amrToWav:audioFile.tempEncodeFilePath wavSavePath:audioFile.localStorePath];
    
    if (result) {
        
        
        NSLog(@"HYEncodeAndDecode amrToWav 转码成功:%@",audioFile.localStorePath);
        
        /* 如果设置了转码完成之后将临时编码文件删除 */
        if (audioFile.isDeleteWhileFinishConvertToLocalFormate) {
            
            NSError *removeTempError = nil;
            [[NSFileManager defaultManager] removeItemAtPath:audioFile.tempEncodeFilePath error:&removeTempError];
            
            if (removeTempError) {
                
                NSLog(@"删除临时转码文件失败");
                
                return YES;
                
            }else{
                
                NSLog(@"删除临时转码文件成功");

                return YES;
            }
            
        }
        
        return YES;
        
    }else{
        
        NSLog(@"HYEncodeAndDecode amrToWav faild");
        
        return NO;
        
    }
    
    return result;
}


@end
