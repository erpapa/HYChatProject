//
//  HYAudioRecordSettings.m
//  HYChatProject
//
//  Created by erpapa on 16/5/12.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYAudioRecordSettings.h"

@implementation HYAudioRecordSettings

- (id)initWithSampleRate:(CGFloat)rate
             withFormate:(NSInteger)formateID
            withBitDepth:(NSInteger)bitDepth
            withChannels:(NSInteger)channels
            withPCMIsBig:(BOOL)isBig
          withPCMIsFloat:(BOOL)isFloat
             withQuality:(NSInteger)quality
{
    if (self = [super init]) {
        
        self.sampleRate = rate;
        self.Formate = formateID;
        self.LinearPCMBitDepth = bitDepth;
        self.numberOfChnnels = channels;
        self.LinearPCMIsBigEndian = isBig;
        self.LinearPCMIsFloat = isFloat;
        self.EncoderAudioQuality = quality;
    }
    return self;
}


+ (HYAudioRecordSettings *)defaultQualitySetting
{
    HYAudioRecordSettings *settings = [[self alloc]initWithSampleRate:8000.0f withFormate:kAudioFormatLinearPCM withBitDepth:16 withChannels:1 withPCMIsBig:NO withPCMIsFloat:NO withQuality:AVAudioQualityMedium];
    
    return settings;
}

+ (HYAudioRecordSettings *)lowQualitySetting
{
    HYAudioRecordSettings *settings = [[self alloc]initWithSampleRate:8000.0f withFormate:kAudioFormatLinearPCM withBitDepth:16 withChannels:1 withPCMIsBig:NO withPCMIsFloat:NO withQuality:AVAudioQualityLow];
    
    return settings;
}

+ (HYAudioRecordSettings *)highQualitySetting
{
    HYAudioRecordSettings *settings = [[self alloc]initWithSampleRate:8000.0f withFormate:kAudioFormatLinearPCM withBitDepth:16 withChannels:1 withPCMIsBig:NO withPCMIsFloat:NO withQuality:AVAudioQualityHigh];
    
    return settings;
}

+ (HYAudioRecordSettings *)MaxQualitySetting
{
    HYAudioRecordSettings *settings = [[self alloc]initWithSampleRate:8000.0f withFormate:kAudioFormatLinearPCM withBitDepth:16 withChannels:1 withPCMIsBig:NO withPCMIsFloat:NO withQuality:AVAudioQualityMax];
    
    return settings;
}

- (NSDictionary *)settingDict
{
    NSDictionary *aSettingDict = @{
                                   AVSampleRateKey: @(self.sampleRate),
                                   AVFormatIDKey:@(self.Formate),
                                   AVLinearPCMBitDepthKey:@(self.LinearPCMBitDepth),
                                   AVNumberOfChannelsKey:@(self.numberOfChnnels),
                                   AVLinearPCMIsBigEndianKey:@(self.LinearPCMIsBigEndian),
                                   AVLinearPCMIsFloatKey:@(self.LinearPCMIsFloat),
                                   AVEncoderAudioQualityKey:@(self.EncoderAudioQuality)
                                   
                                   };
    
    return aSettingDict;
}
@end
