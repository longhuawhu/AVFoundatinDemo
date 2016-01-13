//
//  ViewController.m
//  AVFoundatinDemo
//
//  Created by lh on 16/1/13.
//  Copyright © 2016年 lh. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#define  MOVIEPATH  @"movie"

@interface ViewController () <AVCaptureFileOutputRecordingDelegate>
@property (nonatomic, strong)AVCaptureSession *captureSession;
@property (nonatomic, strong)AVCaptureMovieFileOutput *captureMovieFileOutput;
@property (nonatomic, strong)UIView *displayView;
@property (nonatomic, assign)UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupSubViews];
    
    [self setupDevice];
}

- (void)setupSubViews {
    
    UIButton *startBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, 400, 60, 30)];
    [self.view addSubview:startBtn];
    
    [startBtn setTitle:@"start" forState:UIControlStateNormal];
    [startBtn setTitle:@"stop" forState:UIControlStateSelected];
    [startBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [startBtn addTarget:self action:@selector(start:) forControlEvents:UIControlEventTouchUpInside];
    
    
    _displayView = [[UIView alloc] initWithFrame:CGRectMake(10, 100, 300, 250)];
    [self.view addSubview:_displayView];

}

- (void)start:(UIButton *)btn {
    btn.selected = !btn.selected;
    if (btn.selected) {
       [_captureSession startRunning];
    
        //如果支持多任务则则开始多任务
        if ([[UIDevice currentDevice] isMultitaskingSupported]) {
            self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
        }

        
        // 设置视频输出的文件路径，这里设置为 temp 文件
        NSString *outputFielPath=[NSTemporaryDirectory() stringByAppendingString:MOVIEPATH];
        
        // 路径转换成 URL 要用这个方法，用 NSBundle 方法转换成 URL 的话可能会出现读取不到路径的错误
        NSURL *fileUrl=[NSURL fileURLWithPath:outputFielPath];
        
        // 往路径的 URL 开始写入录像 Buffer ,边录边写
        [self.captureMovieFileOutput startRecordingToOutputFileURL:fileUrl recordingDelegate:self];
    }
    else {
        [self.captureMovieFileOutput stopRecording];
        [_captureSession stopRunning];

    }
}

- (void)stop {
    [_captureSession stopRunning];
}

- (void)setupDevice{
    _captureSession = [[AVCaptureSession alloc] init];
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
    
    _captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    if (audioInput) {
        [_captureSession addInput:audioInput];
        AVCaptureConnection *captureConnection = [_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        // 标识视频录入时稳定音频流的接受，我们这里设置为自动
        if ([captureConnection isVideoStabilizationSupported]) {
            captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
    }
    else {
        // Handle the failure.
    }
    
    NSArray *videos = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDevice *backCamera;
    for (AVCaptureDevice *video in videos) {
        if(video.position == AVCaptureDevicePositionBack) {
            backCamera = video;
        }
    }
    
    
    if (backCamera != nil) {
        AVCaptureDeviceInput *cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
        
        AVCaptureVideoStabilizationMode stabilizationMode = AVCaptureVideoStabilizationModeCinematic;
        if ([cameraInput.device.activeFormat isVideoStabilizationModeSupported:stabilizationMode]) {
            AVCaptureConnection *captureConnection = [_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            [captureConnection setPreferredVideoStabilizationMode:stabilizationMode];
            
            // 预览图层和视频方向保持一致,这个属性设置很重要，如果不设置，那么出来的视频图像可以是倒向左边的。
            //captureConnection.videoOrientation=[self.captureVideoPreviewLayer connection].videoOrientation;
        }
        
        
        if (cameraInput) {
            [_captureSession addInput:cameraInput];
        }
        
    }
    
    
    
    // 通过会话 (AVCaptureSession) 创建预览层
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    
    // 显示在视图表面的图层
    CALayer *layer = self.displayView.layer;
    layer.masksToBounds = true;
    
    captureVideoPreviewLayer.frame = layer.bounds;
    captureVideoPreviewLayer.masksToBounds = true;
    captureVideoPreviewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;//填充模式
    [layer addSublayer:captureVideoPreviewLayer];
    
  
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    NSLog(@"didStartRecordingToOutputFileAtURL");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    NSLog(@"didFinishRecordingToOutputFileAtURL");
}

@end
