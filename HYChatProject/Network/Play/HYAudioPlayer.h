//
//  HYAudioPlayer.h
//  HYChatProject
//
//  Created by erpapa on 16/5/12.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "HYAudioPlayerDelegate.h"
#import "HYAudioModel.h"

@interface HYAudioPlayer : NSObject

@property (nonatomic,readonly)BOOL isPlaying;

@property (nonatomic,weak)id<HYAudioPlayerDelegate> delegate;

- (HYAudioModel *)getCurrentPlayingAudioFile;

- (void)playAudioFile:(HYAudioModel *)audioFile;

- (void)playAtDuration:(NSTimeInterval)duration;

- (void)play;

- (void)stop;

- (void)pause;

- (NSTimeInterval)getLocalWavFileDuration:(NSString *)audioPath;

- (NSInteger)currentPlayAudioFileDuration;

- (NSString *)currentPlayAudioFileLocalPath;


@end
