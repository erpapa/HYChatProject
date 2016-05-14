//
//  HYAudioPlayerDelegate.h
//  HYChatProject
//
//  Created by erpapa on 16/5/12.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HYAudioModel.h"

@class HYAudioPlayer;

@protocol HYAudioPlayerDelegate <NSObject>

@optional

- (void)audioPlayer:(HYAudioPlayer *)audioPlay didFinishPlayAudio:(HYAudioModel *)audioFile;

- (void)audioPlayer:(HYAudioPlayer *)audioPlay playingProgress:(CGFloat)progressValue;

- (void)audioPlayer:(HYAudioPlayer *)audioPlay playingProgress:(NSTimeInterval)playCurrentTime duration:(NSTimeInterval)duration;

- (void)audioPlayer:(HYAudioPlayer *)audioPlay didOccusError:(NSError *)error;

- (void)audioPlayer:(HYAudioPlayer *)audioPlay didUpdateSoundMouter:(CGFloat)soundMouter;

@end