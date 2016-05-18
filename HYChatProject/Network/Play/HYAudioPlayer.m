//
//  HYAudioPlayer.m
//  HYChatProject
//
//  Created by erpapa on 16/5/12.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYAudioPlayer.h"
#import "HYNetworkManager.h"

@interface HYAudioPlayer ()<AVAudioPlayerDelegate>

@property (nonatomic,strong)AVAudioPlayer *audioPlayer;

@property (nonatomic,strong)HYAudioModel *currentPlayAudioFile;

@property (nonatomic,strong)NSTimer *progressTimer;

@property (nonatomic,assign)CGFloat soundMouter;

@property (nonatomic,assign)NSTimeInterval currentPlayAudioDuration;

@end

@implementation HYAudioPlayer

- (void)dealloc
{
    if (self.progressTimer) {
        [self.progressTimer invalidate];
    }
}

- (void)createPlayer
{
    /* 阻止重复快速重复播放 */
    if (self.audioPlayer.isPlaying) {
        NSError *faildError = [NSError errorWithDomain:@"erpapa.cn" code:-235 userInfo:@{@"msg": @"HYAuidoPlayer正在播放失败"}];
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayer:didOccusError:)]) {
            [self.delegate audioPlayer:self didOccusError:faildError];
        }
        return;
    }
    
    /* 没有可以播放的文件 */
    if (!self.currentPlayAudioFile) {
        
        NSLog(@"HYAudioPlayer No File To Play");
        
        NSError *faildError = [NSError errorWithDomain:@"erpapa.cn" code:-235 userInfo:@{@"msg": @"HYAuidoPlayer正在播放失败"}];
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayer:didOccusError:)]) {
            [self.delegate audioPlayer:self didOccusError:faildError];
        }
        
        return;
    }
    
    /* 播放进度停止 */
    if (self.progressTimer) {
        
        [self.progressTimer invalidate];
        
        self.progressTimer = nil;
    }
    
    /* 如果存在播放，那么停止播放 */
    if (self.audioPlayer) {
        
        _isPlaying = NO;
        
        [self.audioPlayer stop];
        
        self.audioPlayer = nil;
    }
    
    NSError *playerError = nil;
    self.audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL URLWithString:self.currentPlayAudioFile.localStorePath] error:&playerError];
    if (playerError) {
        _isPlaying = NO;
        NSError *faildError = [NSError errorWithDomain:@"erpapa.cn" code:-234 userInfo:@{@"msg": @"HYAuidoPlayer播放失败"}];
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayer:didOccusError:)]) {
            [self.delegate audioPlayer:self didOccusError:faildError];
        }
        return;
    }
    
    self.audioPlayer.delegate = self;
    self.audioPlayer.meteringEnabled = YES;//允许显示波形
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    BOOL isPrepare = [self.audioPlayer prepareToPlay];
    if (!isPrepare) {
        
        NSError *faildError = [NSError errorWithDomain:@"domain" code:-235 userInfo:@{@"msg": @"HYAuidoPlayer准备播放失败"}];
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayer:didOccusError:)]) {
            [self.delegate audioPlayer:self didOccusError:faildError];
        }
        return;
    }
    
    _isPlaying = [self.audioPlayer play];
    /* 获取当前播放文件得时间总长度 */
    self.currentPlayAudioDuration = [self getLocalWavFileDuration:self.currentPlayAudioFile.localStorePath];
    
    if (_isPlaying) {
        
        /* 播放进度 */
        self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(updatePlayingProgress:) userInfo:nil repeats:YES];
        [self.progressTimer fire];
        
    }else{
        
        NSError *faildError = [NSError errorWithDomain:@"domain" code:-235 userInfo:@{@"msg": @"HYAuidoPlayer正在播放失败"}];
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayer:didOccusError:)]) {
            [self.delegate audioPlayer:self didOccusError:faildError];
        }
    }
}

#pragma mark - 公开方法
- (void)playAudioFile:(HYAudioModel *)audioFile
{
    /* 阻止重复快速重复播放 */
    if (self.audioPlayer.isPlaying) {
        NSError *faildError = [NSError errorWithDomain:@"domain" code:-235 userInfo:@{@"msg": @"HYAuidoPlayer正在播放失败"}];
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayer:didOccusError:)]) {
            [self.delegate audioPlayer:self didOccusError:faildError];
        }
        return;
    }
    
    if (self.currentPlayAudioFile != audioFile) { // 不是当前下载(播放)对象
        if (![[NSFileManager defaultManager] fileExistsAtPath:audioFile.localStorePath]) {
            self.currentPlayAudioFile = audioFile;
            __weak typeof(self) weakSelf = self;
            [[HYNetworkManager sharedInstance] downloadAudioModel:audioFile successBlock:^(BOOL success) {
                if (success) { // 下载成功，播放
                    if (weakSelf.currentPlayAudioFile == audioFile) { // 只有是当前播放对象，才播放
                        [weakSelf createPlayer];
                    }
                }
            }];
        }
    }
    
    
    if (self.currentPlayAudioFile) {
        self.currentPlayAudioFile = nil;
    }
    
    self.currentPlayAudioFile = audioFile;
    
    [self createPlayer];
}

- (void)playAtDuration:(NSTimeInterval)duration
{
    if (!self.audioPlayer) {
        return;
    }
    
    [self.audioPlayer playAtTime:duration];
}

- (HYAudioModel *)getCurrentPlayingAudioFile
{
    return self.currentPlayAudioFile;
}

- (void)play
{
    if (!self.audioPlayer) {
        return;
    }
    if (self.audioPlayer.isPlaying) {
        NSError *faildError = [NSError errorWithDomain:@"erpapa.cn" code:-235 userInfo:@{@"msg": @"HYAuidoPlayer正在播放失败"}];
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayer:didOccusError:)]) {
            [self.delegate audioPlayer:self didOccusError:faildError];
        }
        return;
    }
    _isPlaying = [self.audioPlayer play];
    
    if (!self.progressTimer) {
        /* 播放进度 */
        self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(updatePlayingProgress:) userInfo:nil repeats:YES];
    }
    [self.progressTimer fire];

}

- (void)stop
{
    if (!self.audioPlayer) {
        return;
    }
    if (!self.audioPlayer.isPlaying) {
        return;
    }
    [self.audioPlayer stop];
    _isPlaying = NO;
    
    if (self.progressTimer) {
        [self.progressTimer invalidate];
        self.progressTimer = nil;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayer:didFinishPlayAudio:)]) {
        [self.delegate audioPlayer:self didFinishPlayAudio:self.currentPlayAudioFile];
    }
}

- (NSTimeInterval)getLocalWavFileDuration:(NSString *)audioPath
{
    if (!audioPath) {
        return 0;
    }
    
    AVURLAsset* audioAsset =[AVURLAsset assetWithURL:[NSURL fileURLWithPath:audioPath]];
    
    CMTime audioDuration = audioAsset.duration;
    
    return  CMTimeGetSeconds(audioDuration);
}

- (NSInteger)currentPlayAudioFileDuration
{
    return self.currentPlayAudioDuration;
}

- (NSString *)currentPlayAudioFileLocalPath
{
    return self.currentPlayAudioFile.localStorePath;
}

- (void)pause
{
    if (!self.audioPlayer) {
        return;
    }
    if (!self.audioPlayer.isPlaying) {
        return;
    }
    [self.audioPlayer pause];
    
    if (self.progressTimer) {
        [self.progressTimer invalidate];
        self.progressTimer = nil;
    }
    _isPlaying = NO;
}

#pragma mark - 更新播放进度
- (void)updatePlayingProgress:(NSTimer *)timer
{
    CGFloat progress = self.audioPlayer.currentTime/self.audioPlayer.duration;
    
    /* 播放进度百分比 */
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayer:playingProgress:)]) {
        
        [self.delegate audioPlayer:self playingProgress:progress];
    }
    
    /* 播放进度 */
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayer:playingProgress:duration:)]) {
        [self.delegate audioPlayer:self playingProgress:self.audioPlayer.currentTime duration:self.audioPlayer.duration];
    }
    
    /* 更新音量波形 */
    [self updateSoundMouter:timer];

    /* 0.9进度就应该停止了，因为1.0在完成方法更新 */
    if (progress >= 0.9f || !self.audioPlayer.isPlaying) {
        
        [timer invalidate];
    }
    
}

- (void)updateSoundMouter:(NSTimer *)timer
{
    
    [self.audioPlayer updateMeters];
    
    float soundLoudly = [self.audioPlayer peakPowerForChannel:0];
    _soundMouter = pow(10, (0.05 * soundLoudly));
    
    NSLog(@"audio soundMouter :%f",_soundMouter);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayer:didUpdateSoundMouter:)]) {
        [self.delegate audioPlayer:self didUpdateSoundMouter:self.soundMouter];
    }
}



#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (flag) {
        
        /* 进度完成 */
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayer:playingProgress:)]) {
                        
            [self.delegate audioPlayer:self playingProgress:1.f];
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayer:didFinishPlayAudio:)]) {
            
            [self.delegate audioPlayer:self didFinishPlayAudio:self.currentPlayAudioFile];
            
            _isPlaying = NO;
            
        }
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"AVAudioPlayer error:%@",error);
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayer:didOccusError:)]) {
        [self.delegate audioPlayer:self didOccusError:error];
    }
    _isPlaying = NO;
}

@end
