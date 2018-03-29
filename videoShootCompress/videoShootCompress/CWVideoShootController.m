//
//  CWVideoShootController.m
//  videoShootCompress
//
//  Created by hyjet on 2018/3/23.
//  Copyright © 2018年 vsc. All rights reserved.
//  github:https://github.com/DeveloperCWG/videoShootCompress
//  简书:https://www.jianshu.com/p/7d9537a891e9

#import "CWVideoShootController.h"
#import "CWVideoRecord.h"
#import "CWVideoView.h"
#import <Photos/Photos.h>

@interface CWVideoShootController ()<CWVideoViewDelegate,CWVideoRecordDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>

//拍摄预览界面
@property (nonatomic, strong)CWVideoView *videoView;

//拍摄管理对象
@property (nonatomic, strong)CWVideoRecord *videoRecord;

//画面模式的数组
@property (nonatomic, strong)NSArray *sizeTypeArr;

//视频选择器
@property (strong, nonatomic) UIImagePickerController *moviePickerVc;

@end

@implementation CWVideoShootController

-(NSArray *)sizeTypeArr{
    if (!_sizeTypeArr) {
        _sizeTypeArr = @[
                         @{
                             @"type":@(CWSize4X3),
                             @"text":@"4x3"
                             },
                         @{
                             @"type":@(CWSizeScreenFull),
                             @"text":@"9x16"
                             },
                         @{
                             @"type":@(CWSize1X1),
                             @"text":@"1x1"
                             }
                         ];
    }
    return _sizeTypeArr;
}


-(CWVideoView *)videoView{
    if (!_videoView) {
        _videoView = [[CWVideoView alloc]initWithDelegate:self];
        [self.view addSubview:_videoView];
    }
    return _videoView;
}

-(UIImagePickerController *)moviePickerVc
{
    if (!_moviePickerVc) {
        _moviePickerVc = [[UIImagePickerController alloc] init];
        _moviePickerVc.delegate = self;
        _moviePickerVc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
//        _moviePickerVc.mediaTypes = @[(NSString *)kUTTypeMovie];
    }
    return _moviePickerVc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self.videoView addFlashLampChange:self action:@selector(flashLampChange:) forControlEvents:UIControlEventTouchUpInside];
    [self.videoView addSubCameraChange:self action:@selector(subCameraChange:) forControlEvents:UIControlEventTouchUpInside];
    [self.videoView addRecordChange:self action:@selector(recordChange:) forControlEvents:UIControlEventTouchUpInside];
    [self.videoView addCloseChange:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [self.videoView addPhotosChange:self action:@selector(openPhotos) forControlEvents:UIControlEventTouchUpInside];
    
    //在主线程异步加载录制管理器对象，然后刷新视图
    dispatch_async(dispatch_get_main_queue(), ^{
        _videoRecord = [[CWVideoRecord alloc]initWithPreset:AVCaptureSessionPresetHigh writePath:NSTemporaryDirectory()];
        _videoRecord.delegate = self;
        [_videoRecord displayRecordLayer:_videoView];
        [_videoView reloadRecord:CWRecordReady];
    });
    
    __weak typeof(self) weakSelf = self;
    [self lastAssetWithResultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        [weakSelf.videoView updateLibraryCover:result firstTime:YES];
    }];
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)close{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)flashLampChange:(UIButton *)sender{
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self.videoRecord openFlashLight];
    }else {
        [self.videoRecord closeFlashLight];
    }
}
- (void)subCameraChange:(UIButton *)sender{
    sender.selected = !sender.selected;
    if (sender.selected) {
        //前置摄像头
        [self.videoRecord closeFlashLight];
        [self.videoRecord changePrimaryOrSecondaryCamera:YES];
    }else {
        [self.videoRecord changePrimaryOrSecondaryCamera:NO];
    }
}

- (void)recordChange:(UIButton *)sender{
    sender.selected = !sender.selected;
    if (sender.selected) {
        NSLog(@"开始录制");
        [_videoView reloadRecord:CWRecordRecording];
        [self.videoRecord startMaxInterval:10 writeName:[self createVideoFileName]];
    }else{
        NSLog(@"结束录制");
        [_videoView reloadRecord:CWRecordReady];
        [self.videoRecord stop];
    }
}

- (void)openPhotos{
    UIImagePickerController *picker=[[UIImagePickerController alloc] init];
    
    picker.delegate=self;
    picker.allowsEditing=NO;
    picker.videoMaximumDuration = 1.0;//视频最长长度
    picker.videoQuality = UIImagePickerControllerQualityTypeHigh;//视频质量
    
    //媒体类型：@"public.movie" 为视频  @"public.image" 为图片
    //这里只选择展示视频
    picker.mediaTypes = [NSArray arrayWithObjects:@"public.movie", nil];
    
    picker.sourceType= UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    
    [self presentViewController:picker animated:YES completion:nil];
}

//写入的视频名称
- (NSString *)createVideoFileName
{
    NSArray *arr = [[NSUUID UUID].UUIDString componentsSeparatedByString:@"-"];
    NSString *videoName = [NSString stringWithFormat:@"%@.mp4", arr[arr.count-1]];
    return videoName;
    
}

//获取相册最近的流媒体的封面图
- (void)lastAssetWithResultHandler:(void (^)(UIImage *__nullable result, NSDictionary *__nullable info))resultHandler

{
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    
    PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
    
    PHAsset *phasset = [assetsFetchResults lastObject];
    
    PHCachingImageManager *imageManager = [[PHCachingImageManager alloc] init];
    
    [imageManager requestImageForAsset:phasset targetSize:CGSizeMake(300, 300) contentMode:PHImageContentModeAspectFill options:nil resultHandler:resultHandler];
    
}

#pragma CWVideoViewDelegate

-(NSArray *)renderDataSource
{
    return self.sizeTypeArr;
}

- (NSDictionary *)defaultSelectedItem {
    return self.sizeTypeArr[0];
}

- (void)didSelectedItemIndexPath:(NSInteger)index
{
    NSDictionary *dic = self.sizeTypeArr[index];
    CWVideoSize type = [dic[@"type"] intValue];
    [_videoRecord changeVideoSize:type displayView:self.view];
}

- (void)triggetFocusChange:(CGPoint)focusPoint
{
    [self.videoRecord videoFocus:focusPoint completionHandler:^(BOOL finished) {
        
    }];
}

#pragma CWVideoRecordDelegate

-(void)recording:(NSInteger)timeInterval
{
    [self.videoView updateTime:timeInterval];
}

-(void)recordProgress:(CGFloat)progress
{
    [self.videoView updateProgress:progress];
}

-(void)recordEnd:(NSURL *)videoUrl coverImage:(UIImage *)img
{
    __weak typeof(self) weakSelf = self;
    //                保存到系统相册
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoUrl];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"保存成功");
            dispatch_sync(dispatch_get_main_queue(), ^{
                [weakSelf.videoView updateLibraryCover:img firstTime:NO];
            });
        }else{
            NSLog(@"保存失败:%@",error);
        }
    }];
    [_videoView reloadRecord:CWRecordReady];
}

-(BOOL)recordErrorForReset:(NSError *)error
{
//    [self.videoRecord stop];
//    [_videoView reloadRecord:CWRecordReady];
//    [_videoRecord startMaxInterval:10 writeName:_videoRecord.wirteName];
    return YES;
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
    NSString *mediaType=[info objectForKey:UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:@"public.movie"]){
        //如果是视频
        NSURL *url = info[UIImagePickerControllerMediaURL];//获得视频的URL
        NSLog(@"%@",url);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
