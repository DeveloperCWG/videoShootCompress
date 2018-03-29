//
//  CWVideoRecord.h
//  videoShootCompress
//
//  Created by 程文广 on 2018/3/24.
//  Copyright © 2018年 vsc. All rights reserved.
//  github:https://github.com/DeveloperCWG/videoShootCompress
//  简书:https://www.jianshu.com/p/7d9537a891e9

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

//录制视频的size比例
typedef enum{
    CWSizeScreenFull = 0,
    CWSize1X1,
    CWSize4X3,
}CWVideoSize;

@protocol CWVideoRecordDelegate <NSObject>
@optional
//录制中时间更新
- (void)recording:(NSInteger)timeInterval;
//录制中进度更新
- (void)recordProgress:(CGFloat)progress;
//录制完成
- (void)recordEnd:(NSURL *)videoUrl coverImage:(UIImage *)img;
//录制出错是否重新开始
- (BOOL)recordErrorForReset:(NSError *)error;

@end

@interface CWVideoRecord : NSObject

/**录制的视频的名称*/
@property (nonatomic, readonly)NSString *wirteName;

@property (nonatomic, weak)id<CWVideoRecordDelegate>delegate;

- (instancetype)initWithPreset:(AVCaptureSessionPreset)preset writePath:(NSString *)path;
//展示预览层
- (void)displayRecordLayer:(UIView *)displayView;
//调整预览层画幅
- (void)changeVideoSize:(CWVideoSize)sizeType displayView:(UIView *)displayView;
//对焦
- (void)videoFocus:(CGPoint)focusPoint completionHandler:(void (^)(BOOL finished))block;
//切换摄像头
- (void)changePrimaryOrSecondaryCamera:(BOOL)isFront;


//关闭闪光灯
- (void)closeFlashLight;

//开启闪光灯
- (void)openFlashLight;
//开始录制
- (void)startMaxInterval:(CGFloat)interval writeName:(NSString *)name;
//停止录制
- (void)stop;

@end
