//
//  HYAudioRecordDelegate.h
//  HYChatProject
//
//  Created by erpapa on 16/5/12.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HYAudioModel.h"

@class HYAudioRecord;
@protocol HYAudioRecordDelegate <NSObject>

@optional

- (void)audioRecord:(HYAudioRecord *)audioRecord finishRecord:(HYAudioModel*)resultAudio;

- (void)audioRecord:(HYAudioRecord *)audioRecord soundMeter:(CGFloat)soundMeter;

- (void)audioRecord:(HYAudioRecord *)audioRecord didFaildByMinRecordDuration:(NSTimeInterval)minDuration;

- (void)audioRecordDidCancel:(HYAudioRecord*)audioRecord;

- (void)audioRecord:(HYAudioRecord *)audioRecord limitDurationProgress:(CGFloat)progress;

- (void)audioRecord:(HYAudioRecord *)audioRecord didOccusError:(NSError *)error;

@end
