//
//  HYVideoDecoder.h
//  HYChatProject
//
//  Created by erpapa on 16/5/13.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void(^HYdecodeFinished)(BOOL finished);

@interface HYVideoDecoder : NSObject
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) CAKeyframeAnimation *animation;
@property (nonatomic, strong) NSMutableArray *images;

- (instancetype)initWithFile:(NSString *)filePath;
- (void)decodeVideo:(HYdecodeFinished)finished;

@end
