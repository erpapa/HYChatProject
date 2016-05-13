//
//  HYVideoPlayController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/13.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYVideoPlayController.h"
#import <AVFoundation/AVFoundation.h>

@interface HYVideoPlayController ()

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) AVPlayer *player;
@end

@implementation HYVideoPlayController

- (instancetype)initWithPath:(NSString *) filePath
{
    self = [super init];
    if (self) {
        _filePath = filePath;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self addNotification];
    
    [_player play];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self removeNotification];
    
    [_player pause];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    NSURL *fileUrl=[NSURL fileURLWithPath:_filePath];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:fileUrl];
    
    _player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:_player];
    CGFloat layerHeight = self.view.frame.size.width * 0.75;
    layer.frame = CGRectMake(0,(self.view.frame.size.height - layerHeight) * 0.5,self.view.frame.size.width,layerHeight);
    [self.view.layer addSublayer:layer];
    layer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [button addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)close:(id) sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

- (void)removeNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)playbackFinished:(NSNotification *)notification{
    [_player seekToTime:CMTimeMake(0, 1)];
    [_player play];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
