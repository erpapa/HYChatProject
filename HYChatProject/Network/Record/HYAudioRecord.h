//
//  HYAudioRecord.h
//  HYChatProject
//
//  Created by erpapa on 16/5/12.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "HYAudioRecordDelegate.h"
#import "HYAudioRecordSettings.h"

@interface HYAudioRecord : NSObject

@property (nonatomic,readonly)BOOL isRecording;

@property (nonatomic,readonly)CGFloat soundMouter;

@property (nonatomic,assign)NSTimeInterval limitRecordDuration;

/* 最小有小时间,默认1秒 */
@property (nonatomic,assign)NSTimeInterval minEffectDuration;

@property (nonatomic,weak)id<HYAudioRecordDelegate> delegate;

@property (nonatomic,strong)HYAudioRecordSettings *recordSettings;

/* 获取当前录制音频文件*/
- (HYAudioModel*)getCurrentRecordAudioFile;

- (void)startRecord;

- (void)finishRecord;

- (void)cancelRecord;

- (NSTimeInterval)currentRecordFileDuration;

@end
