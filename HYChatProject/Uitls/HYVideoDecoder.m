//
//  HYVideoDecoder.m
//  HYChatProject
//
//  Created by erpapa on 16/5/13.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYVideoDecoder.h"
#import <AVFoundation/AVFoundation.h>
#import "HYChatMessage.h"

@implementation HYVideoDecoder

- (instancetype)initWithFile:(NSString *)filePath
{
    self = [super init];
    if (self) {
        _filePath = filePath;
    }
    return self;
}


- (void)decodeVideo:(HYdecodeFinished)finished;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *url = [NSURL fileURLWithPath:_filePath];
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
        
        NSError *error = nil;
        AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
        if (error) {
            finished(NO);
            return;
        }
        
        NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        AVAssetTrack *videoTrack =[videoTracks objectAtIndex:0];
        
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        [options setObject:@(kCVPixelFormatType_32BGRA) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        AVAssetReaderTrackOutput *videoReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:options];
        [reader addOutput:videoReaderOutput];
        [reader startReading];
        
        @autoreleasepool {
            NSMutableArray *images = [NSMutableArray array];
            while ([reader status] == AVAssetReaderStatusReading && videoTrack.nominalFrameRate > 0) {
                CMSampleBufferRef sampleBufferRef = [videoReaderOutput copyNextSampleBuffer];
                if (sampleBufferRef) {
                    CGImageRef cgimage = [self imageFromSampleBufferRef:sampleBufferRef];
                    if (!(__bridge id)(cgimage)) {
                        CMSampleBufferInvalidate(sampleBufferRef);
                        CFRelease(sampleBufferRef);
                        continue;
                    }
                    [images addObject:((__bridge id)(cgimage))];
                    CGImageRelease(cgimage);
                    CMSampleBufferInvalidate(sampleBufferRef);
                    CFRelease(sampleBufferRef);
                }
                //[NSThread sleepForTimeInterval:0.001];
            }
            _animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
            _animation.duration = asset.duration.value/asset.duration.timescale;
            _animation.values = images;
            _animation.repeatCount = MAXFLOAT;
            _animation.autoreverses = YES;
        }
        finished(YES);
    });
}


- (CGImageRef)imageFromSampleBufferRef:(CMSampleBufferRef)sampleBufferRef
{
    // 为媒体数据设置一个CMSampleBufferRef
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
    // 锁定 pixel buffer 的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    // 得到 pixel buffer 的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // 得到 pixel buffer 的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到 pixel buffer 的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // 创建一个依赖于设备的 RGB 颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphic context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    //根据这个位图 context 中的像素创建一个 Quartz image 对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁 pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    // 释放 context 和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    // 用 Quzetz image 创建一个 UIImage 对象
    // UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // 释放 Quartz image 对象
    //    CGImageRelease(quartzImage);
    
    return quartzImage;
    
}

@end
