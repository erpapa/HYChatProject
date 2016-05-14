//
//  HYAudioModel.h
//  HYChatProject
//
//  Created by erpapa on 16/5/12.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HYAudioModel : NSObject

/* 文件唯一标示 */
@property (nonatomic,readonly)NSString *uniqueIdentifier;

/* 文件时长单位是秒 */
@property (nonatomic,assign)NSTimeInterval duration;

/* 文件名(不包含扩展名) */
@property (nonatomic,strong)NSString *fileName;

/* wav文件存储路径 */
@property (nonatomic,strong)NSString *localStorePath;

/* 文件在服务器的远程地址 */
@property (nonatomic,strong)NSString *remotePath;

/* 临时转换编码时候的文件,默认iOS本地应该保存wav格式的文件，
 * 但是在上传服务器可能要求是别的格式，比如AMR,所以，
 * 我们提供一个属性，来保存我们临时转换的文件路径 
 * 在下载服务器上的临时编码音频文件的时候，我们也将文件缓存到这个路径，
 * 然后对应的通过解码生成一份iOS本地的Wav格式文件，存在localStorePath路径下
 * 这样就可以确保我们始终访问localStorePath路径是iOS本地wav格式音频，tempEncodeFilePath是
 * 临时编码音频文件
 */
@property (nonatomic,strong)NSString *tempEncodeFilePath;

/* 限制录音时长 */
@property (nonatomic,assign)NSTimeInterval limitRecordDuration;

/* 限制播放时长 */
@property (nonatomic,assign)NSTimeInterval limitPlayDuration;

/* 文件扩展名 */
@property (nonatomic,strong)NSString *extensionName;

/* 临时转编码文件的扩展名 */
@property (nonatomic,strong)NSString *tempEncodeFileExtensionName;

/* 多媒体文件类型 */
@property (nonatomic,strong)NSString *mimeType;


/* 是否下载完就播放 */
@property (nonatomic,assign)BOOL shouldPlayWhileFinishDownload;

/* 当转码成本地iOS支持格式之后，是否将临时编码文件删除 */
@property (nonatomic,assign)BOOL isDeleteWhileFinishConvertToLocalFormate;

/* 当临时转码文件上传完成后，是否将临时编码文件删除 */
@property (nonatomic,assign)BOOL isDeleteWhileUploadFinish;

/* 删除临时编码文件 */
- (void)deleteTempEncodeFile;

/* 删除本地wav格式文件 */
- (void)deleteWavFile;


@end
