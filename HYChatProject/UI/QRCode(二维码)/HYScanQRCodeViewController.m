//
//  HYScanQRCodeViewController.m
//  HYChatProject
//
//  Created by erpapa on 16/5/1.
//  Copyright © 2016年 erpapa. All rights reserved.
//

#import "HYScanQRCodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "HYQRCodeViewController.h"
#import "HYUservCardViewController.h"
#import "HYUtils.h"
#import "HYXMPPManager.h"

@interface HYScanQRCodeViewController ()<AVCaptureMetadataOutputObjectsDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) UIView *scanRectView;      // 扫描区域
@property (nonatomic, strong) UIView *headerView;        // 头部
@property (nonatomic, strong) UIView *footerView;        // 底部
@property (nonatomic, strong) UIButton *readButton;      // 从相册读取
@property (nonatomic, strong) UIButton *flashButton;     // 闪光灯
@property (nonatomic, strong) UIButton *codeButton;      // 生成我的二维码
@property (nonatomic, strong) AVCaptureDevice            *device;
@property (nonatomic, strong) AVCaptureDeviceInput       *input;
@property (nonatomic, strong) AVCaptureMetadataOutput    *output;
@property (nonatomic, strong) AVCaptureSession           *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preview;

@end

@implementation HYScanQRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGSize windowSize = [UIScreen mainScreen].bounds.size;
    
    CGSize scanSize = CGSizeMake(windowSize.width*3/4, windowSize.width*3/4);
    CGRect scanRect = CGRectMake((windowSize.width-scanSize.width) * 0.5, (windowSize.height-scanSize.height) * 0.4, scanSize.width, scanSize.height);
    
    scanRect = CGRectMake(scanRect.origin.y/windowSize.height, scanRect.origin.x/windowSize.width, scanRect.size.height/windowSize.height,scanRect.size.width/windowSize.width);
    
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    
    self.output = [[AVCaptureMetadataOutput alloc]init];
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    self.session = [[AVCaptureSession alloc]init];
    [self.session setSessionPreset:([UIScreen mainScreen].bounds.size.height<500)?AVCaptureSessionPreset640x480:AVCaptureSessionPresetHigh];
    [self.session addInput:self.input];
    [self.session addOutput:self.output];
    self.output.metadataObjectTypes=@[AVMetadataObjectTypeQRCode];
    self.output.rectOfInterest = scanRect;
    
    self.preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.preview.frame = [UIScreen mainScreen].bounds;
    [self.view.layer insertSublayer:self.preview atIndex:0];
    
    // 识别区域
    self.scanRectView = [[UIView alloc] init];
    [self.view addSubview:self.scanRectView];
    self.scanRectView.frame = CGRectMake((windowSize.width-scanSize.width) * 0.5, (windowSize.height-scanSize.height) * 0.4, scanSize.width, scanSize.height);
    self.scanRectView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.scanRectView.layer.borderWidth = 1;
    
    // 头部
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
    
    CGFloat headerHeight = 64;
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), headerHeight)];
    self.headerView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
    [self.view addSubview:self.headerView];
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 20, 44, 44)];
    [backButton setImage:[UIImage imageNamed:@"qrcode_scan_titlebar_back_nor"] forState:UIControlStateNormal];
    [backButton setImage:[UIImage imageNamed:@"qrcode_scan_titlebar_back_pressed"] forState:UIControlStateHighlighted];
    [backButton addTarget:self action:@selector(backButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:backButton];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.headerView.frame) - 60) * 0.5, 20, 60, 44)];
    titleLabel.text = @"扫一扫";
    titleLabel.font = [UIFont systemFontOfSize:20];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.headerView addSubview:titleLabel];
    
    
    // 提示
    CGFloat tipLabelWidth = 160;
    UILabel *tipLabel = [[UILabel alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.view.frame) - tipLabelWidth) * 0.5, CGRectGetMaxY(self.headerView.frame) + 8, tipLabelWidth, 44)];
    tipLabel.text = @"将取景框对准二维码即可自动扫描";
    tipLabel.numberOfLines = 2;
    tipLabel.textColor = [UIColor whiteColor];
    tipLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:tipLabel];
    
    // 底部
    CGFloat footerHeight = 107;
    self.footerView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.view.frame) - footerHeight, CGRectGetWidth(self.view.frame), footerHeight)];
    self.footerView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
    [self.view addSubview:self.footerView];
    
    // 从相册识别
    CGFloat buttonW = 65;
    CGFloat buttonH = 87;
    CGFloat buttonY = 10;
    CGFloat margin = (CGRectGetWidth(self.footerView.frame) - buttonW * 3) * 0.25;
    
    self.readButton = [[UIButton alloc] initWithFrame:CGRectMake(margin, buttonY, buttonW, buttonH)];
    [self.readButton setBackgroundImage:[UIImage imageNamed:@"qrcode_scan_btn_photo_nor"] forState:UIControlStateNormal];
    [self.readButton setBackgroundImage:[UIImage imageNamed:@"qrcode_scan_btn_photo_down"] forState:UIControlStateHighlighted];
    [self.readButton addTarget:self action:@selector(readButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.footerView addSubview:self.readButton];
    
    // 闪光灯
    self.flashButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.readButton.frame) + margin, buttonY, buttonW, buttonH)];
    [self.flashButton setBackgroundImage:[UIImage imageNamed:@"qrcode_scan_btn_flash_nor"] forState:UIControlStateNormal];
    [self.flashButton setBackgroundImage:[UIImage imageNamed:@"qrcode_scan_btn_flash_down"] forState:UIControlStateSelected];
    [self.flashButton addTarget:self action:@selector(flashButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.footerView addSubview:self.flashButton];
    
    // 生成二维码
    self.codeButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.flashButton.frame) + margin, buttonY, buttonW, buttonH)];
    [self.codeButton setBackgroundImage:[UIImage imageNamed:@"qrcode_scan_btn_myqrcode_nor"] forState:UIControlStateNormal];
    [self.codeButton setBackgroundImage:[UIImage imageNamed:@"qrcode_scan_btn_myqrcode_down"] forState:UIControlStateHighlighted];
    [self.codeButton addTarget:self action:@selector(codeButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.footerView addSubview:self.codeButton];
    
    // 开始捕获
    [self.session startRunning];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    if (self.session.isRunning) {
        return;
    } else {
        [self.session startRunning];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    if (self.session.isRunning) {
        [self.session stopRunning];;
    }
}

#pragma mark - 二维码识别
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects.count==0) return;
    [self.session stopRunning];
    AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects.firstObject;
    //输出扫描字符串
    NSString *string = metadataObject.stringValue;
    XMPPJID *jid = [XMPPJID jidWithString:string];
    if (jid.user.length && jid.domain.length) {
        HYUservCardViewController *vCardVC = [[HYUservCardViewController alloc] init];
        vCardVC.isAddFriend = YES;
        vCardVC.userJid = jid;
        [self.navigationController pushViewController:vCardVC animated:YES];
    } else {
        [HYUtils alertWithErrorMsg:[NSString stringWithFormat:@"帐号不合法！\n%@",string]];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.session startRunning];
        });
    }
}


#pragma mark - 图片二维码识别

- (void)readButtonClick:(UIButton *)sender
{
    UIImagePickerController *photoPicker = [[UIImagePickerController alloc] init];
    
    photoPicker.delegate = self;
    photoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    photoPicker.allowsEditing = YES;
    [self presentViewController:photoPicker animated:YES completion:NULL];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [HYUtils showWaitingMsg:@"正在识别..."];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //获得编辑过的图片
        UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
        CIContext *context = [CIContext contextWithOptions:nil];
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:context options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
        CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
        NSArray *features = [detector featuresInImage:ciImage];
        CIQRCodeFeature *feature = [features firstObject];
        NSString *result = feature.messageString; // 获取扫描结果
        
        if (result.length == 0) {
            [self dismissViewControllerAnimated:YES completion:^{
                [HYUtils alertWithErrorMsg:@"没有扫描到二维码！"];
            }];
            
        } else {
            [self dismissViewControllerAnimated:YES completion:^{
                //输出扫描字符串
                XMPPJID *jid = [XMPPJID jidWithString:result];
                if (jid.user.length && jid.domain.length) {
                    [HYUtils clearWaitingMsg];
                    HYUservCardViewController *vCardVC = [[HYUservCardViewController alloc] init];
                    vCardVC.isAddFriend = YES;
                    vCardVC.userJid = jid;
                    [self.navigationController pushViewController:vCardVC animated:YES];
                } else {
                    [HYUtils alertWithErrorMsg:[NSString stringWithFormat:@"帐号不合法！\n%@",result]];
                }
            }];
            
        }
        
        
    });
    
}

#pragma mark - 闪光灯

- (void)flashButtonClick:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
    if ([self.device hasTorch] && [self.device hasFlash]) {
        [self.session beginConfiguration];
        [self.device lockForConfiguration:nil];
        if(self.device.torchMode == AVCaptureTorchModeOn) {
            [self.device setTorchMode:AVCaptureTorchModeOff];
            [self.device setFlashMode:AVCaptureFlashModeOff];
        } else if(self.device.torchMode == AVCaptureTorchModeOff) {
            [self.device setTorchMode:AVCaptureTorchModeOn];
            [self.device setFlashMode:AVCaptureFlashModeOn];
        }
        [self.device unlockForConfiguration];
        [self.session commitConfiguration];
        [self.session startRunning];
    }
}


#pragma mark - 显示我的二维码

- (void)codeButtonClick:(UIButton *)sender
{
    HYQRCodeViewController *QRCodeVC = [[HYQRCodeViewController alloc] init];
    QRCodeVC.jid = [HYXMPPManager sharedInstance].myJID;
    [self.navigationController pushViewController:QRCodeVC animated:YES];
}

// 返回
- (void)backButtonClick:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
