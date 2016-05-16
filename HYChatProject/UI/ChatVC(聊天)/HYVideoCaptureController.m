//
//  HYVideoCaptureController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/12.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYVideoCaptureController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "HYUtils.h"
#define Max_Viedo_Length 8

#define Color_Green [UIColor colorWithRed:9/255.0 green:187/255.0 blue:7/255.0 alpha:1.0]
#define Color_Red [UIColor colorWithRed:225/255.0 green:53/255.0 blue:0/255.0 alpha:1.0]

@interface HYVideoCaptureController ()<AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic, strong) AVCaptureDeviceInput *audioDeviceInput;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) UIButton *maskView;       // 背景
@property (nonatomic, strong) UIView *footerView;       // 底部view
@property (nonatomic, strong) UIButton *pressButton;    // 拍摄
@property (nonatomic, strong) UILabel *releaseTipLabel; // 提示
@property (nonatomic, strong) UIView *timeBar;          // 进度条
@property (nonatomic, strong) NSTimer *timer;
@property (assign, nonatomic) CGFloat length;
@property (assign, nonatomic) BOOL isFinished;

@end

@implementation HYVideoCaptureController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.length = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self prepare]; // 准备
    [self setupContentView];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [_session startRunning];
    [UIView animateWithDuration:0.25f animations:^{
        self.footerView.transform = CGAffineTransformMakeTranslation(0, -CGRectGetHeight(self.footerView.bounds));
    }];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [_session stopRunning];
}


- (void)setupContentView
{
    // 1.背景view
    self.maskView = [[UIButton alloc] initWithFrame:self.view.bounds];
    self.maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];
    [self.maskView addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.maskView];
    
    // 2.底部view
    CGFloat footerWidth = self.view.bounds.size.width;
    CGFloat margin = 10;
    CGFloat previewLayerHeight = footerWidth * 0.75;
    CGFloat pressButtonHeight = 72;
    CGFloat footerHeight = previewLayerHeight + pressButtonHeight + margin * 2;
    self.footerView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.view.frame), footerWidth, footerHeight)];
    self.footerView.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0f];
    [self.view addSubview:self.footerView];
    
    // 3.预览窗口
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    self.previewLayer.frame = CGRectMake(0, 0, footerWidth, previewLayerHeight);
    self.previewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    [self.footerView.layer insertSublayer:_previewLayer atIndex:0];
    
    // 4.时间状态条
    self.timeBar = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.previewLayer.frame),footerWidth, 3)];
    self.timeBar.backgroundColor = Color_Green;
    self.timeBar.hidden = YES;
    [self.footerView addSubview:self.timeBar];
    
    // 5.提示上移释放label
    _releaseTipLabel = [[UILabel alloc] initWithFrame:CGRectMake((footerWidth - 80) * 0.5, CGRectGetMaxY(_previewLayer.frame) - 25, 80, 20)];
    _releaseTipLabel.backgroundColor = Color_Red;
    _releaseTipLabel.text = @"上移取消";
    _releaseTipLabel.textAlignment = NSTextAlignmentCenter;
    _releaseTipLabel.textColor = [UIColor whiteColor];
    _releaseTipLabel.font = [UIFont systemFontOfSize:13];
    _releaseTipLabel.hidden = YES;
    _releaseTipLabel.layer.cornerRadius = 2;
    _releaseTipLabel.layer.masksToBounds = YES;
    [self.footerView addSubview:_releaseTipLabel];
    
    
    // 6.按钮
    _pressButton = [UIButton buttonWithType: UIButtonTypeCustom];
    _pressButton.frame = CGRectMake((footerWidth - pressButtonHeight) * 0.5, footerHeight - pressButtonHeight - margin, pressButtonHeight, pressButtonHeight);
    [_pressButton setTitle:@"按住拍" forState:UIControlStateNormal];
    [_pressButton setTitleColor:Color_Green forState:UIControlStateNormal];
    [_pressButton setBackgroundImage:[UIImage imageNamed:@"press_btn_green"] forState:UIControlStateNormal];
    [_pressButton addTarget:self action:@selector(onVoiceButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [_pressButton addTarget:self action:@selector(btnDragged:withEvent:) forControlEvents:UIControlEventTouchDragInside];
    [_pressButton addTarget:self action:@selector(btnDragged:withEvent:) forControlEvents:UIControlEventTouchDragOutside];
    [_pressButton addTarget:self action:@selector(btnTouchUp:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    [_pressButton addTarget:self action:@selector(btnTouchUp:withEvent:) forControlEvents:UIControlEventTouchUpOutside];
    [self.footerView addSubview:_pressButton];
    
    
    
}
- (void)prepare
{
    _session = [[AVCaptureSession alloc] init];
    if ([_session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        _session.sessionPreset = AVCaptureSessionPreset640x480;
    }
    
    AVCaptureDevice *videoDeivice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
    
    NSError *error = nil;
    _videoDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoDeivice error: &error];
    
    if (error) {
        NSLog(@"添加Video设备异常");
    }
    
    
    if ([_session canAddInput:_videoDeviceInput]) {
        [_session addInput:_videoDeviceInput];
    }
    
    
    AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    _audioDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:&error];
    if (error) {
        NSLog(@"添加Audio设备异常");
    }
    
    
    if ([_session canAddInput:_audioDeviceInput]) {
        [_session addInput:_audioDeviceInput];
    }
    
    
    _movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    
    if ([_session canAddOutput:_movieFileOutput]) {
        [_session addOutput:_movieFileOutput];
    }
}

- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position]==position) {
            return camera;
        }
    }
    return nil;
}




#pragma mark - Button Action

- (void)btnDragged:(UIButton *)sender withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGFloat boundsExtension = 5.0f;
    CGRect outerBounds = CGRectInset(sender.bounds, -1 * boundsExtension, -1 * boundsExtension);
    BOOL touchOutside = !CGRectContainsPoint(outerBounds, [touch locationInView:sender]);
    if (touchOutside) {
        BOOL previewTouchInside = CGRectContainsPoint(outerBounds, [touch previousLocationInView:sender]);
        if (previewTouchInside) {
            NSLog(@"移出区域");
            // UIControlEventTouchDragExit
            
            _timeBar.backgroundColor = Color_Red;
            _releaseTipLabel.hidden = YES;
        } else {
            // UIControlEventTouchDragOutside
            
        }
    } else {
        BOOL previewTouchOutside = !CGRectContainsPoint(outerBounds, [touch previousLocationInView:sender]);
        if (previewTouchOutside) {
            // UIControlEventTouchDragEnter
            NSLog(@"移入区域");
            _timeBar.backgroundColor = Color_Green;
            _releaseTipLabel.hidden = NO;
        } else {
            // UIControlEventTouchDragInside
        }
    }
}




- (void)btnTouchUp:(UIButton *)sender withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGFloat boundsExtension = 5.0f;
    CGRect outerBounds = CGRectInset(sender.bounds, -1 * boundsExtension, -1 * boundsExtension);
    BOOL touchOutside = !CGRectContainsPoint(outerBounds, [touch locationInView:sender]);
    if (touchOutside) {
        // UIControlEventTouchUpOutside
        [self onVoiceButtonTouchUpOutside];
    } else {
        // UIControlEventTouchUpInside
        [self onVoiceButtonTouchUpInside];
    }
}


- (void)onVoiceButtonTouchDown:(UIButton *) button
{
    NSLog(@"按下拍摄按钮");
    _length = 0;
    _isFinished = NO;
    
    [self changeTimeBarwidth:1.0];
    _timeBar.hidden = NO;
    _timeBar.backgroundColor = Color_Green;
    _releaseTipLabel.hidden = NO;
    
    if (_timer == nil) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(onCapture:) userInfo:nil repeats:YES];
    }
    
    [self startCapture];
    
}

- (void)onVoiceButtonTouchUpOutside
{
    NSLog(@"从外部释放");
    if (_length >= Max_Viedo_Length) {
        return;
    }
    
    //取消拍摄
    [self stopCapture];
}



- (void)onVoiceButtonTouchUpInside
{
    NSLog(@"从内部释放");
    if (_length >= Max_Viedo_Length) {
        return;
    }
    
    //完成拍摄
    [self stopCapture];
    
    if (_length > 1.0) {
        _isFinished = YES;
    }
}


#pragma mark - Method
- (void)changeTimeBarwidth:(CGFloat)rate
{
    CGFloat x, y, width, height;
    y=_timeBar.frame.origin.y;
    height = _timeBar.frame.size.height;
    width = self.view.frame.size.width * (1-rate);
    x= (self.view.frame.size.width - width)/2;
    _timeBar.frame = CGRectMake(x, y, width, height);
    
}

- (void)onCapture:(NSTimer *) timer
{
    _length = timer.timeInterval + _length;
    
    [self changeTimeBarwidth:_length/Max_Viedo_Length];
    
    if (_length >= Max_Viedo_Length) {
        NSLog(@"时间到 完成拍摄");
        
        [self stopCapture];
        _isFinished = YES;
        
        return;
    }
    
}

- (void)restore
{
    NSLog(@"恢复现场");
    _timeBar.hidden = YES;
    _releaseTipLabel.hidden = YES;
    [self stopTimer];
}

- (void)stopTimer
{
    [_timer invalidate];
    _timer = nil;
}


#pragma mark - Capture

- (void)startCapture
{
    AVCaptureConnection *captureConnection=[_movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([captureConnection isVideoStabilizationSupported ]) {
        captureConnection.preferredVideoStabilizationMode=AVCaptureVideoStabilizationModeAuto;
    }
    
    if (![_movieFileOutput isRecording]) {
        captureConnection.videoOrientation=[_previewLayer connection].videoOrientation;
        
        NSString *document = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *dirPath = [NSString stringWithFormat:@"%@/videoCache",document];
        BOOL isDir = YES;
        if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSString *filePath = [dirPath stringByAppendingPathComponent:@"temp.mov"];
        NSURL *url=[NSURL fileURLWithPath:filePath];
        [_movieFileOutput startRecordingToOutputFileURL:url recordingDelegate:self];
    }
    
}

- (void)stopCapture
{
    [self restore];
    
    if ([_movieFileOutput isRecording]) {
        [_movieFileOutput stopRecording];
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    NSLog(@"开始录制");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    NSLog(@"结束录制，文件路径: %@", outputFileURL);
    
    NSData *data = [NSData dataWithContentsOfURL:outputFileURL];
    NSLog(@"原始文件大小: %luKB", (unsigned long)([data length]/1024));
    
    if (_isFinished) {
        self.footerView.transform = CGAffineTransformIdentity;
        [HYUtils showWaitingMsg:@"正在处理视频..."];
        NSString *document = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *scaledFilePath = [NSString stringWithFormat:@"%@/videoCache/%d.mov",document, (NSInteger)[[NSDate date] timeIntervalSince1970]];
        [self scaleAndPress:outputFileURL savePath:scaledFilePath];
    }
}




- (void)scaleAndPress:(NSURL *) url savePath:(NSString *) savePath
{
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.frameDuration = CMTimeMake(1, 30);
    
    CGRect rect = CGRectMake(0, 0, clipVideoTrack.naturalSize.height, clipVideoTrack.naturalSize.height);
    
    videoComposition.renderSize = rect.size;
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction
                                                                   videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
    
    [layerInstruction setCropRectangle:rect atTime:kCMTimeZero];
    
    CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(M_PI*0.5);
    CGAffineTransform rotateTranslate = CGAffineTransformTranslate(rotationTransform,0, -rect.size.width);
    
    [layerInstruction setTransform:rotateTranslate atTime:kCMTimeZero];
    
    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    videoComposition.instructions = [NSArray arrayWithObject: instruction];
    
    AVAssetExportSession *avAssetExportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetLowQuality];
    [avAssetExportSession setVideoComposition:videoComposition];
    [avAssetExportSession setOutputURL:[NSURL fileURLWithPath:savePath]];
    [avAssetExportSession setOutputFileType:AVFileTypeQuickTimeMovie];
    [avAssetExportSession setShouldOptimizeForNetworkUse:YES];
    [avAssetExportSession exportAsynchronouslyWithCompletionHandler:^(void){
        switch (avAssetExportSession.status) {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"处理失败 %@",[avAssetExportSession error]);
                break;
            case AVAssetExportSessionStatusCompleted:{
                CGFloat fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:savePath error:nil] fileSize];
                NSLog(@"处理成功，压缩后文件大小: %luKB", (unsigned long)(fileSize/1024));
                MAIN(^{
                    [HYUtils clearWaitingMsg];
                    [self handleViedo:savePath];
                });
                
                break;
            }
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"处理取消");
                break;
            default:
                break;
        }
    }];
}


- (void)handleViedo:(NSString *)filePath
{
    [self dismissViewControllerAnimated:NO completion:^{
        UIImage *screenShot = [self generateScreenshot:[NSURL fileURLWithPath:filePath]];
        if (_delegate && [_delegate respondsToSelector:@selector(videoCaptureController:captureVideo:screenShot:)]) {
            [_delegate videoCaptureController:self captureVideo:filePath screenShot:screenShot];
        }
    }];
}


- (UIImage *)generateScreenshot:(NSURL *) url
{
    AVURLAsset *urlAsset=[AVURLAsset assetWithURL:url];
    AVAssetImageGenerator *imageGenerator=[AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    
    NSError *error=nil;
    CMTime time=CMTimeMakeWithSeconds(1, 10);
    CMTime actualTime;
    CGImageRef cgImage= [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
    if(error){
        NSLog(@"截取视频缩略图时发生错误，错误信息：%@",error.localizedDescription);
        return nil;
    }
    CMTimeShow(actualTime);
    UIImage *image=[UIImage imageWithCGImage:cgImage];
    //保存到相册
    //UIImageWriteToSavedPhotosAlbum(image,nil, nil, nil);
    CGImageRelease(cgImage);
    
    return image;
}

- (void)dismiss
{
    [UIView animateWithDuration:0.25f animations:^{
        self.footerView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
