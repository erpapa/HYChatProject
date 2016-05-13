//
//  HYVideoDecoder.h
//  HYChatProject
//
//  Created by erpapa on 16/5/13.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HYVideoDecoder;
@protocol HYVideoDecoderDelegate <NSObject>
@required
- (void)videoDecodeFinished:(HYVideoDecoder *)videoDecoder;
@end

@interface HYVideoDecoder : NSObject
@property (nonatomic, weak) id<HYVideoDecoderDelegate> delegate;
@property (nonatomic, strong) CAKeyframeAnimation *animation;

- (instancetype)initWithFile:(NSString *)filePath;
- (void)decode;

@end
