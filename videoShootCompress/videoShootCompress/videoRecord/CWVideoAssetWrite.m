//
//  CWVideoAssetWrite.m
//  videoShootCompress
//
//  Created by 程文广 on 2018/3/25.
//  Copyright © 2018年 vsc. All rights reserved.
//  github:https://github.com/DeveloperCWG/videoShootCompress
//  简书:https://www.jianshu.com/p/7d9537a891e9

#import "CWVideoAssetWrite.h"
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

#define TIMER_INTERVAL 0.05         //定时器刷新率

@interface CWVideoAssetWrite()

@property (nonatomic, copy) NSString *writeDir;

@property (nonatomic, strong) NSURL *writeVideoUrl;

@property (nonatomic, strong)AVAssetWriter *assetWriter;

@property (nonatomic, strong)AVAssetWriterInput *assetWriterVideoInput;
@property (nonatomic, strong)AVAssetWriterInput *assetWriterAudioInput;

@property (nonatomic, strong) NSDictionary *videoCompressionSettings;
@property (nonatomic, strong) NSDictionary *audioCompressionSettings;

@property (nonatomic, assign)CGSize videoSize;

@property (nonatomic, assign)CGFloat recordedTime;

@property (nonatomic, assign)CGFloat maxRecordTime;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) Callback callback;

@property (nonatomic,readwrite)CWRecordAssetState state;

/**视频录制锁*/
@property (nonatomic, strong) NSLock *assetLock;

@end

@implementation CWVideoAssetWrite

- (instancetype)initWithWriteSize:(CGSize)size writeDir:(NSString *)path
{
    if (self = [super init]) {
        self.videoSize = size;
        self.writeDir = path;
        self.assetLock = [[NSLock alloc]init];
    }
    return self;
}

//刷新录制画幅
- (void)restSize:(CGSize)size{
    self.videoSize = size;
}

//开始录制
- (void)startWriteWithMaxInterval:(CGFloat)interval writeName:(NSString *)name completionHandler:(Callback)block{
    self.callback = [block copy];
    self.writeVideoUrl = [NSURL fileURLWithPath:[_writeDir stringByAppendingString:name]];
    self.maxRecordTime = interval;
    if (!self.assetWriter) {
        [self setUpWriterSettings];
    }
}

//完成录制
- (void)stopWriteWithCompletionHandler:(void (^)(NSURL *videoUrl,UIImage *coverImage))handler{
    [self.assetLock lock];
    [self.timer invalidate];
    __weak __typeof(self)weakSelf = self;
    [_assetWriter finishWritingWithCompletionHandler:^{
        weakSelf.state = CWAssetStateFinish;
        [weakSelf movieCoverImage:^(UIImage *movieImage) {
            handler(weakSelf.writeVideoUrl,movieImage);
        }];
        [weakSelf.assetLock unlock];
    }];
}

//获取视频第一帧的截图作封面
- (void)movieCoverImage:(void (^)(UIImage *coverImage))handler {
    NSURL *url = self.writeVideoUrl;
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = TRUE;
    CMTime thumbTime = CMTimeMakeWithSeconds(0, 60);
    generator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    AVAssetImageGeneratorCompletionHandler generatorHandler =
    ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result == AVAssetImageGeneratorSucceeded) {
            UIImage *thumbImg = [UIImage imageWithCGImage:im];
            if (handler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(thumbImg);
                });
            }
        }
    };
    [generator generateCGImagesAsynchronouslyForTimes:
     [NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:generatorHandler];
}

//设置写入视频属性,在这里进行压缩
- (void)setUpWriterSettings
{
    NSError *error = nil;
    self.assetWriter = [AVAssetWriter assetWriterWithURL:self.writeVideoUrl fileType:AVFileTypeMPEG4 error:&error];
    //写入视频大小
    NSInteger numPixels = self.videoSize.width * self.videoSize.height;
    //每像素比特
    CGFloat bitsPerPixel = 6.0;
    NSInteger bitsPerSecond = numPixels * bitsPerPixel;
    
    // 码率和帧率设置
    NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
                                             AVVideoExpectedSourceFrameRateKey : @(30),
                                             AVVideoMaxKeyFrameIntervalKey : @(30),
                                             AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel };
    
    //视频属性
    self.videoCompressionSettings = @{ AVVideoCodecKey : AVVideoCodecTypeH264,
                                       AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                       AVVideoWidthKey : @(self.videoSize.width*2),
                                       AVVideoHeightKey : @(self.videoSize.height*2),
                                       AVVideoCompressionPropertiesKey : compressionProperties };
    
    _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoCompressionSettings];
    //expectsMediaDataInRealTime 必须设为yes，需要从capture session 实时获取数据
    _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    _assetWriterVideoInput.transform = CGAffineTransformMakeTranslation(M_PI_2, M_PI_2);
    _assetWriterVideoInput.transform  = CGAffineTransformScale(_assetWriterVideoInput.transform, -1, 1);
    
    // 音频设置
    self.audioCompressionSettings = @{ AVEncoderBitRatePerChannelKey : @(28000),
                                       AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                       AVNumberOfChannelsKey : @(1),
                                       AVSampleRateKey : @(22050) };
    
    
    _assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.audioCompressionSettings];
    _assetWriterAudioInput.expectsMediaDataInRealTime = YES;
    
    
    if ([_assetWriter canAddInput:_assetWriterVideoInput]) {
        [_assetWriter addInput:_assetWriterVideoInput];
    }else {
        NSLog(@"AssetWriter error");
        [self resetAsset];
    }
    if ([_assetWriter canAddInput:_assetWriterAudioInput]) {
        [_assetWriter addInput:_assetWriterAudioInput];
    }else {
        NSLog(@"AssetWriter error");
        [self resetAsset];
    }
    
}

- (void)resetAsset{
    self.assetWriter = nil;
    self.assetWriterAudioInput = nil;
    self.assetWriterVideoInput = nil;
    [self setUpWriterSettings];
}


//开始写入数据
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType
{
    if (self.assetWriter.status == AVAssetWriterStatusUnknown) {
        self.state = CWAssetStateWaiting;
    }
    
    //数据是否准备完毕
    if (CMSampleBufferDataIsReady(sampleBuffer)) {
        [self.assetLock lock];
        //写入状态为未知,保证视频先写入
        if (self.assetWriter.status == AVAssetWriterStatusUnknown && mediaType==AVMediaTypeVideo) {
            //获取开始写入的CMTime
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            //开始写入
            @try {
                [self.assetWriter startWriting];
                [self.assetWriter startSessionAtSourceTime:startTime];
            }@catch(NSException * e){
                NSLog(@"写入错误:%@",e);
                self.callback(NO, 0, self.assetWriter.error);
            }
            if (!_timer) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    _timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
                });
                
            }
        }
        //写入失败
        if (self.assetWriter.status == AVAssetWriterStatusFailed) {
            self.state = CWAssetStateFail;
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (self.callback) {
                    self.callback(NO, 0, self.assetWriter.error);
                }
            });
            NSLog(@"writer error %@", self.assetWriter.error);
            [self destroy];
            return;
        }
        if (mediaType==AVMediaTypeVideo && _assetWriterVideoInput) {
            //视频输入是否准备接受更多的媒体数据
            if (_assetWriterVideoInput.readyForMoreMediaData == YES) {
                //拼接数据
                BOOL isSuccess = [_assetWriterVideoInput appendSampleBuffer:sampleBuffer];
                if (!isSuccess) {
                    self.state = CWAssetStateFail;
                    [self destroy];
                }else{
                    self.state = CWAssetStateRecording;
                }
            }
        }else if(mediaType==AVMediaTypeAudio && _assetWriterAudioInput) {
            //音频输入是否准备接受更多的媒体数据
            if (_assetWriterAudioInput.readyForMoreMediaData) {
                //拼接数据
                BOOL isSuccess = [_assetWriterAudioInput appendSampleBuffer:sampleBuffer];
                if (!isSuccess) {
                    self.state = CWAssetStateFail;
                    [self destroy];
                }else{
                    self.state = CWAssetStateRecording;
                }
            }
        }
        [self.assetLock unlock];
    }
}

- (void)updateProgress{
    if (_recordedTime >= _maxRecordTime) {
        if (self.callback) {
            self.callback(YES, 1.00,nil);
        }
        return;
    }
    _recordedTime += TIMER_INTERVAL;
    if (self.callback) {
        self.callback(NO, _recordedTime/_maxRecordTime,nil);
    }
}

- (void)destroy
{
    [self.assetLock unlock];
    self.assetWriter = nil;
    self.assetWriterAudioInput = nil;
    self.assetWriterVideoInput = nil;
    self.writeVideoUrl = nil;
    [self.timer invalidate];
    self.timer = nil;
    self.callback = nil;
    self.assetLock = nil;
}

- (void)dealloc{
    [self destroy];
}
@end
