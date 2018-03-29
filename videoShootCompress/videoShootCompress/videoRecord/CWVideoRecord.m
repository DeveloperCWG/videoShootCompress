//
//  CWVideoRecord.m
//  videoShootCompress
//
//  Created by 程文广 on 2018/3/24.
//  Copyright © 2018年 vsc. All rights reserved.
//  github:https://github.com/DeveloperCWG/videoShootCompress
//  简书:https://www.jianshu.com/p/7d9537a891e9

#import "CWVideoRecord.h"
#import <Photos/Photos.h>
#import "CWVideoAssetWrite.h"

@interface CWVideoRecord()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>

/**数据流中枢控制器*/
@property (nonatomic,strong)AVCaptureSession *videoRecordSession;
/**前置摄像头*/
@property (nonatomic,strong)AVCaptureDevice *secondaryCamera;
/**后置摄像头*/
@property (nonatomic,strong)AVCaptureDevice *primaryCamera;
/**后置摄像头输入对象*/
@property (nonatomic,strong)AVCaptureDeviceInput *primaryInput;
/**前置摄像头输入对象*/
@property (nonatomic,strong)AVCaptureDeviceInput *secondaryInput;
/**麦克风输入对象*/
@property (strong, nonatomic) AVCaptureDeviceInput *audioMicInput;
/**音频输出流对象*/
@property (nonatomic,strong)AVCaptureAudioDataOutput *audioOutput;
/**视频输出流对象*/
@property (nonatomic,strong)AVCaptureVideoDataOutput *videoOutput;
/**视频连接对象*/
@property (nonatomic,strong)AVCaptureConnection *videoConnection;
/**音频连接对象*/
@property (nonatomic,strong)AVCaptureConnection *audioConnection;
/**数据流预览图层*/
@property (nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;
/**写录制数据对象*/
@property (nonatomic, strong)CWVideoAssetWrite *assetWrite;
/**视频录制队列*/
@property (nonatomic, copy) dispatch_queue_t videoRecordQueue;
/**视频录制队列*/
@property (nonatomic, strong) NSLock *videoLock;
//录制的视频质量
@property (nonatomic, copy)AVCaptureSessionPreset preset;
//
@property (nonatomic, assign)CWVideoSize sizeType;

@property (nonatomic, assign)CGRect rect;
//
@property (nonatomic, strong) NSTimer *timer;
//录制的当前时长
@property (nonatomic, assign) NSInteger recordTimeInterval;
//录制的最大时长
@property (nonatomic, assign) CGFloat maxInterval;
/**视频的存储文件夹路径*/
@property (nonatomic, copy)NSString *videoPath;
/**录制的视频的名称*/
@property (nonatomic, copy)NSString *wirteName;

@end

@implementation CWVideoRecord

- (instancetype)initWithPreset:(AVCaptureSessionPreset)preset writePath:(NSString *)path{
    if (self = [super init]) {
        self.videoPath = path;
        self.preset = preset;
        [self videoRecordSession];
    }
    return self;
}

- (dispatch_queue_t)videoRecordQueue
{
    if (!_videoRecordQueue) {
        _videoRecordQueue = dispatch_queue_create("com.videoRecord.queue", DISPATCH_QUEUE_SERIAL);
    }
    return _videoRecordQueue;
}

-(NSLock *)videoLock{
    if (!_videoLock) {
        _videoLock = [[NSLock alloc]init];
    }
    return _videoLock;
}
//捕获视频的会话
- (AVCaptureSession *)videoRecordSession {
    if (_videoRecordSession == nil) {
        _videoRecordSession = [[AVCaptureSession alloc] init];
        //设置录制的原始分辨率
        if ([_videoRecordSession canSetSessionPreset:self.preset]) {
            _videoRecordSession.sessionPreset=self.preset;
        }
        //添加后置摄像头的输出
        if ([_videoRecordSession canAddInput:self.primaryInput]) {
            [_videoRecordSession addInput:self.primaryInput];
        }
        //添加后置麦克风的输出
        if ([_videoRecordSession canAddInput:self.audioMicInput]) {
            [_videoRecordSession addInput:self.audioMicInput];
        }
        //添加视频输出
        if ([_videoRecordSession canAddOutput:self.videoOutput]) {
            [_videoRecordSession addOutput:self.videoOutput];
        }
        //添加音频输出
        if ([_videoRecordSession canAddOutput:self.audioOutput]) {
            [_videoRecordSession addOutput:self.audioOutput];
        }
        //设置视频录制的方向
        self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
        self.videoConnection.videoMirrored = YES;
    }
    return _videoRecordSession;
}

//返回前置摄像头
- (AVCaptureDevice *)secondaryCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

//返回后置摄像头
- (AVCaptureDevice *)primaryCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

//用来返回是前置摄像头还是后置摄像头
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    //返回和视频录制相关的所有默认设备
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //遍历这些设备返回跟position相关的设备
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

//后置摄像头输入
- (AVCaptureDeviceInput *)primaryInput {
    if (_primaryInput == nil) {
        NSError *error;
        _primaryInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self primaryCamera] error:&error];
        if (error) {
            NSLog(@"获取后置摄像头失败~");
            //            [SVProgressHUD showErrorWithStatus:@"获取后置摄像头失败~"];
        }
    }
    return _primaryInput;
}

//前置摄像头输入
- (AVCaptureDeviceInput *)secondaryInput {
    if (_secondaryInput == nil) {
        NSError *error;
        _secondaryInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self secondaryCamera] error:&error];
        if (error) {
            NSLog(@"获取前置摄像头失败~");
            //            [SVProgressHUD showErrorWithStatus:@"获取前置摄像头失败~"];
        }
    }
    return _secondaryInput;
}

//麦克风输入
- (AVCaptureDeviceInput *)audioMicInput {
    if (_audioMicInput == nil) {
        AVCaptureDevice *mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error;
        _audioMicInput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:&error];
        if (error) {
            NSLog(@"获取麦克风失败~");
        }
    }
    return _audioMicInput;
}

//视频输出
- (AVCaptureVideoDataOutput *)videoOutput {
    if (_videoOutput == nil) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoOutput setSampleBufferDelegate:self queue:self.videoRecordQueue];
        NSDictionary* setcapSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,
                                        nil];
        _videoOutput.videoSettings = setcapSettings;
    }
    return _videoOutput;
}

//音频输出
- (AVCaptureAudioDataOutput *)audioOutput {
    if (_audioOutput == nil) {
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioOutput setSampleBufferDelegate:self queue:self.videoRecordQueue];
    }
    return _audioOutput;
}

//视频连接
- (AVCaptureConnection *)videoConnection {
    _videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    return _videoConnection;
}

//音频连接
- (AVCaptureConnection *)audioConnection {
    if (_audioConnection == nil) {
        _audioConnection = [self.audioOutput connectionWithMediaType:AVMediaTypeAudio];
    }
    return _audioConnection;
}

//捕获到的视频呈现的layer
- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (_previewLayer == nil) {
        //通过AVCaptureSession初始化
        AVCaptureVideoPreviewLayer *preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.videoRecordSession];
        //设置比例为铺满全屏
        preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _previewLayer = preview;
    }
    [self.videoRecordSession startRunning];
    return _previewLayer;
}

- (CWVideoAssetWrite *)assetWrite{
    if (!_assetWrite) {
        _assetWrite = [[CWVideoAssetWrite alloc]initWithWriteSize:self.rect.size writeDir:self.videoPath];
    }
    return _assetWrite;
}

//展示预览层
- (void)displayRecordLayer:(UIView *)displayView{
    self.sizeType = self.sizeType?self.sizeType:CWSizeScreenFull;
    [self changeVideoSize:self.sizeType displayView:displayView];
    [displayView.layer insertSublayer:self.previewLayer atIndex:0];
}

//开启闪光灯
- (void)openFlashLight {
    AVCaptureDevice *primaryCamera = [self primaryCamera];
    if (primaryCamera.torchMode == AVCaptureTorchModeOff) {
        [primaryCamera lockForConfiguration:nil];
        primaryCamera.torchMode = AVCaptureTorchModeOn;
        [primaryCamera unlockForConfiguration];
    }
}
//关闭闪光灯
- (void)closeFlashLight {
    AVCaptureDevice *primaryCamera = [self primaryCamera];
    if (primaryCamera.torchMode == AVCaptureTorchModeOn) {
        [primaryCamera lockForConfiguration:nil];
        primaryCamera.torchMode = AVCaptureTorchModeOff;
        [primaryCamera unlockForConfiguration];
    }
}

- (void)changeCameraAnimation:(BOOL)isFront {
    CATransition *animation = [CATransition animation];
    animation.duration = .5f;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = @"oglFlip";
    if (isFront) {
        animation.subtype = kCATransitionFromRight;
    }else{
        animation.subtype = kCATransitionFromLeft;
    
    }
    [self.previewLayer addAnimation:animation forKey:nil];
}

//切换前后摄像头
- (void)changePrimaryOrSecondaryCamera:(BOOL)isFront {
    if (isFront) {
        [self.videoRecordSession stopRunning];
        [self.videoRecordSession removeInput:self.primaryInput];
        if ([self.videoRecordSession canAddInput:self.secondaryInput]) {
            [self changeCameraAnimation:isFront];
            [self.videoRecordSession addInput:self.secondaryInput];
            self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
    }else {
        [self.videoRecordSession stopRunning];
        [self.videoRecordSession removeInput:self.secondaryInput];
        if ([self.videoRecordSession canAddInput:self.primaryInput]) {
            [self changeCameraAnimation:isFront];
            [self.videoRecordSession addInput:self.primaryInput];
            self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
    }
}

//调整画幅
- (void)changeVideoSize:(CWVideoSize)sizeType displayView:(UIView *)displayView{
    self.rect = displayView.frame;
    self.sizeType = sizeType;
    switch (sizeType) {
        case CWSize4X3:
            _rect = CGRectMake(_rect.origin.x, (_rect.size.height-_rect.size.width*3/4)*0.5, _rect.size.width, _rect.size.width*3/4);
            break;
        case CWSize1X1:
            _rect = CGRectMake(_rect.origin.x, (_rect.size.height-_rect.size.width)*0.5, _rect.size.width, _rect.size.width);
            break;
        case CWSizeScreenFull:
            break;
        default:
            break;
    }
    [UIView animateWithDuration:0.25 animations:^{
        self.previewLayer.frame = _rect;
    }];
    [self.assetWrite restSize:_rect.size];
}

//手动对焦
- (void)videoFocus:(CGPoint)focusPoint completionHandler:(void (^)(BOOL finished))block
{
    //将UI坐标转化为摄像头坐标,摄像头对焦点范围0~1
    CGPoint cameraPoint= [_previewLayer captureDevicePointOfInterestForPoint:focusPoint];

    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        /*
         @constant AVCaptureFocusModeLocked 锁定在当前焦距

         @constant AVCaptureFocusModeAutoFocus 自动对焦一次,然后切换到焦距锁定

         @constant AVCaptureFocusModeContinuousAutoFocus 当需要时.自动调整焦距
         */
        //对焦
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            block(YES);
            NSLog(@"聚焦模式修改为%zd",AVCaptureFocusModeContinuousAutoFocus);
        }else{
            NSLog(@"聚焦模式修改失败");
        }
        //焦点的位置
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:cameraPoint];
        }
        /*
         @constant AVCaptureExposureModeLocked  曝光锁定在当前值
         
         @constant AVCaptureExposureModeAutoExpose 曝光自动调整一次然后锁定

         @constant AVCaptureExposureModeContinuousAutoExposure 曝光自动调整
         
         @constant AVCaptureExposureModeCustom 曝光只根据设定的值来
         */
        //曝光模式
        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            
            [captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }else{
            NSLog(@"曝光模式修改失败");
        }
        //曝光点的位置
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:cameraPoint];
            
        }
    }];
}

//更改设备属性前一定要锁上

-(void)changeDevicePropertySafety:(void (^)(AVCaptureDevice *captureDevice))propertyChange{
    AVCaptureDevice *captureDevice= [_primaryInput device];
    
    NSError *error;
    
    //改变设备属性前一定要首先调用lockForConfiguration:处理完之后使用unlockForConfiguration方法解锁,防止多处同时修改
    
    BOOL lockAcquired = [captureDevice lockForConfiguration:&error];
    
    NSLog(@"锁定设备:lockForConfiguration");
    
    if (!lockAcquired) {
        NSLog(@"锁定设备error，信息：%@",error.localizedDescription);
    }else{
        [_videoRecordSession beginConfiguration];
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
        [_videoRecordSession commitConfiguration];
        NSLog(@"解锁设备:unlockForConfiguration");
    }
    
}

- (void)startMaxInterval:(CGFloat)interval writeName:(NSString *)name{
    _recordTimeInterval = 0;
    self.maxInterval = interval;
    self.wirteName = name;
    __weak __typeof(self)weakSelf = self;
    [self.assetWrite startWriteWithMaxInterval:interval writeName:name completionHandler:^(BOOL isFinished, CGFloat progress, NSError *error) {
        if (error) {
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(recordErrorForReset:)]) {
                if ([weakSelf.delegate recordErrorForReset:error]) {
                    //重新开始录制
                    [weakSelf startMaxInterval:weakSelf.maxInterval writeName:weakSelf.wirteName];
                }
            }
            [weakSelf.timer invalidate];
            weakSelf.timer = nil;
            return;
        }
        if (isFinished) {
            [weakSelf stop];
        }else{
            if (!_timer) {
                _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateRecordTime) userInfo:nil repeats:YES];
            }
        }
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(recordProgress:)]) {
            [weakSelf.delegate recordProgress:progress];
        }
    }];
}

- (void)updateRecordTime{
    _recordTimeInterval ++;
    if (self.delegate && [self.delegate respondsToSelector:@selector(recording:)]) {
        [self.delegate recording:_recordTimeInterval];
    }
}

- (void)stop{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    __weak __typeof(self)weakSelf = self;
    dispatch_async(self.videoRecordQueue, ^{
        [self.assetWrite stopWriteWithCompletionHandler:^(NSURL *videoUrl, UIImage *coverImage) {
            weakSelf.assetWrite = nil;
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(recordEnd:coverImage:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.delegate recordEnd:videoUrl coverImage:coverImage];
                });
            }
        }];
    });
}

#pragma AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    @autoreleasepool{
        CFRetain(sampleBuffer);
        if (connection == [captureOutput connectionWithMediaType:AVMediaTypeVideo]) {
            [self.assetWrite appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
        }
        
        //音频
        if (connection == [captureOutput connectionWithMediaType:AVMediaTypeAudio]) {
            [self.assetWrite appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeAudio];
            
        }
        CFRelease(sampleBuffer);
    }
}


- (void)dealloc{
    [self.videoRecordSession stopRunning];
    self.videoRecordSession = nil;
    self.primaryCamera = nil;
    self.secondaryCamera = nil;
    self.primaryInput = nil;
    self.secondaryCamera = nil;
    self.audioMicInput = nil;
    self.audioOutput = nil;
    self.assetWrite = nil;
    self.videoLock = nil;
}


@end
