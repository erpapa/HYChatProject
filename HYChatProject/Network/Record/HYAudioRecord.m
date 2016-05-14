//
//  HYAudioRecord.m
//  HYChatProject
//
//  Created by erpapa on 16/5/12.
//  Copyright © 2016年 erpapa. All rights reserved.
//


#import "HYAudioRecord.h"
#import "HYUtils.h"

@interface HYAudioRecord ()<AVAudioRecorderDelegate>

@property (nonatomic,strong)AVAudioRecorder *audioRecord;

/* 当前只会有一个文件在录制 */
@property (nonatomic,strong)HYAudioModel *currentRecordFile;

@property (nonatomic,strong)NSTimer *soundMouterTimer;

@property (nonatomic,assign)NSTimeInterval recordProgress;

@end

@implementation HYAudioRecord

- (void)dealloc
{
    if (self.soundMouterTimer) {
        
        [self.soundMouterTimer invalidate];
    }
}

#pragma mark - 初始化配置
- (id)init
{
    if (self = [super init]) {
        
        // 默认无录音时间限制
        self.limitRecordDuration = 0;
        
    }
    return self;
}

/* 获取当前录制音频文件*/
- (HYAudioModel*)getCurrentRecordAudioFile
{
    return self.currentRecordFile;
}

- (void)createRecord
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&err];
    if(err){
        NSLog(@"HYAudioRecord audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        return;
    }
    [audioSession setActive:YES error:&err];
    if(err){
        NSLog(@"HYAudioRecord audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        return;
    }

    /* 阻止快速重复录音 */
    if (self.audioRecord.isRecording) {
        NSError *faildError = [NSError errorWithDomain:@"domain" code:-236 userInfo:@{@"msg": @"HYAuidoRecord 正在录音"}];
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecord:didOccusError:)]) {
            [self.delegate audioRecord:self didOccusError:faildError];
        }
        return;
    }
    
    if (!self.recordSettings) {
        self.recordSettings = [HYAudioRecordSettings defaultQualitySetting];
    }
    
    if (self.currentRecordFile) {
        self.currentRecordFile = nil;
    }
    
    /* 置空Timer */
    if (self.soundMouterTimer) {
        [self.soundMouterTimer invalidate];
        self.soundMouterTimer = nil;
    }
    
    /* 创建一个新得录制文件 */
    self.currentRecordFile = [[HYAudioModel alloc]init];
    /* 设置新得录音文件名 */
    self.currentRecordFile.fileName = [HYUtils currentTimeStampString];
    
    /* 开始新的录音实例 */
    if (self.audioRecord) {
        if (self.audioRecord.isRecording) {
            [self.audioRecord stop];
            [self.audioRecord deleteRecording];
        }
        self.audioRecord = nil;
    }
    
    if (!self.currentRecordFile.localStorePath) {
        NSLog(@"HYAudioRecord Create Error No cache path");
        return;
    }
    NSLog(@"HYAudioRecord Create cache path :%@",self.currentRecordFile.localStorePath);

    NSError *createRecordError = nil;
    self.audioRecord = [[AVAudioRecorder alloc]initWithURL:[NSURL URLWithString:self.currentRecordFile.localStorePath] settings:self.recordSettings.settingDict error:&createRecordError];
    self.audioRecord.delegate = self;
    self.audioRecord.meteringEnabled = YES;
    
    if (createRecordError) {
        
        NSLog(@"HYAudioRecord Create AVAudioRecorder Error:%@",createRecordError);
        
        [self startRecordErrorDetail];
        
        return;
    }
    
    [self.audioRecord prepareToRecord];
    
    /* 创建输入音量更新 */
    self.soundMouterTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(updateSoundMouter:) userInfo:nil repeats:YES];
    [self.soundMouterTimer fire];
}

#pragma mark - 录音错误处理
- (void)startRecordErrorDetail
{
    NSError *faildError = [NSError errorWithDomain:@"HY.AudioManager.com" code:-238 userInfo:@{@"msg": @"HYAuidoRecord启动录音失败"}];
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecord:didOccusError:)]) {
        [self.delegate audioRecord:self didOccusError:faildError];
    }
    
    /* 停止更新 */
    if (self.soundMouterTimer) {
        [self.soundMouterTimer invalidate];
        self.soundMouterTimer = nil;
    }
}

#pragma mark - 录音动作
- (void)startRecord
{
    /* 是否支持录音 */
    [self createRecord];
    
    if (self.limitRecordDuration > 0) {
        
      _isRecording = [self.audioRecord recordForDuration:self.limitRecordDuration];
        
        if (_isRecording) {
            
            NSLog(@"HYAudioRecord Limit start....");
            
        }else{
            
            [self startRecordErrorDetail];
            
            NSLog(@"HYAudioRecord Limit start error....");
        }
        
        return;
    }
    _isRecording = [self.audioRecord record];

    if (_isRecording) {
        
        NSLog(@"HYAudioRecord start....");
        
    }else{
        
        [self startRecordErrorDetail];
        
        NSLog(@"HYAudioRecord start error....");
    }
}

- (void)updateSoundMouter:(NSTimer *)timer
{
    
    [self.audioRecord updateMeters];
    
    float soundLoudly = [self.audioRecord peakPowerForChannel:0];
    _soundMouter = pow(10, (0.05 * soundLoudly));
    
    NSLog(@"audio soundMouter :%f",_soundMouter);
    
    if (self.delegate) {
        [self.delegate audioRecord:self soundMeter:_soundMouter];
    }
    
    /* 录音完成或者停止得时候拿不到这个时间 */
    self.currentRecordFile.duration = self.audioRecord.currentTime;
    
    /* 限制录音时间观察进度 */
    if (self.limitRecordDuration > 0) {
        
        self.recordProgress = self.audioRecord.currentTime;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecord:limitDurationProgress:)]) {
            
            [self.delegate audioRecord:self limitDurationProgress:self.recordProgress];
        }
        
        if (self.audioRecord.currentTime >= self.limitRecordDuration) {
            [self finishRecord];
            return;
        }
    }
}

- (void)finishRecord
{
    if ([self.audioRecord isRecording]) {
        [self.audioRecord stop];
        _isRecording = NO;
    }
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory:AVAudioSessionCategoryAmbient error:&err];
    [audioSession setActive:NO error:&err];
}

- (void)cancelRecord
{
    if (!self.audioRecord) {
        return;
    }
    if (!_isRecording) {
        return;
    }
    
    [self.audioRecord stop];
    _isRecording = NO;
    self.currentRecordFile = nil;
    [self.audioRecord deleteRecording];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecordDidCancel:)]) {
        
        [self.delegate audioRecordDidCancel:self];
    }
}

- (NSTimeInterval)currentRecordFileDuration
{
    return self.currentRecordFile.duration;
}

#pragma mark - AVAudioRecorder Delegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    /* 停止timer */
    if (self.soundMouterTimer) {
        [self.soundMouterTimer invalidate];
        self.soundMouterTimer = nil;
    }
    
    if (flag) {
        
        /* 如果录音时间小于最小要求时间 */
        if (self.recordProgress < self.minEffectDuration) {
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecord:didFaildByMinRecordDuration:)]) {
                
                [self.delegate audioRecord:self didFaildByMinRecordDuration:self.minEffectDuration];
                
                _isRecording = NO;

            }
            
            return;
        }
        
        /* 完成录制 */
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecord:finishRecord:)]) {
            
            _isRecording = NO;

            if (self.currentRecordFile) {
                
                [self.delegate audioRecord:self finishRecord:self.currentRecordFile];
                
            }else{
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecordDidCancel:)]) {
                    
                    [self.delegate audioRecordDidCancel:self];
                }
            }
        }
        
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecord:didOccusError:)]) {
        
        _isRecording = NO;

        [self.delegate audioRecord:self didOccusError:error];
    }
}

- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder
{
    
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withOptions:(NSUInteger)flags
{
    
}


@end
