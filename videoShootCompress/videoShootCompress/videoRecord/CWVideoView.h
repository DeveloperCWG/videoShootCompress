//
//  CWVideoView.h
//  videoShootCompress
//
//  Created by 程文广 on 2018/3/24.
//  Copyright © 2018年 vsc. All rights reserved.
//  github:https://github.com/DeveloperCWG/videoShootCompress
//  简书:https://www.jianshu.com/p/7d9537a891e9

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


//录制状态
typedef enum{
    CWRecordWaiting = 0, //准备中
    CWRecordReady,  //已就绪
    CWRecordRecording,//录制中
}CWRecordState;

@protocol CWVideoViewDelegate <NSObject>
@required
//提供数据源
- (NSArray *)renderDataSource;
@optional
//默认的画幅模式
- (NSDictionary *)defaultSelectedItem;
//点击的索引
- (void)didSelectedItemIndexPath:(NSInteger)index;
//点击对焦的坐标
- (void)triggetFocusChange:(CGPoint)focusPoint;
@end

@interface CWVideoView : UIView

@property (nonatomic, weak, readonly) id<CWVideoViewDelegate>delegate;

-(instancetype)initWithDelegate:(id)delegate;
//是否正在录制
//@property (nonatomic, assign)BOOL isRecording;
//监听闪光灯状态切换
- (void)addFlashLampChange:(id)obj action:(SEL)sel forControlEvents:(UIControlEvents)events;
//监听摄像头切换
- (void)addSubCameraChange:(id)obj action:(SEL)sel forControlEvents:(UIControlEvents)events;
//监听拍摄按钮点击
- (void)addRecordChange:(id)obj action:(SEL)sel forControlEvents:(UIControlEvents)events;
//监听关闭按钮点击
- (void)addCloseChange:(id)obj action:(SEL)sel forControlEvents:(UIControlEvents)events;
//监听媒体库按钮点击
- (void)addPhotosChange:(id)obj action:(SEL)sel forControlEvents:(UIControlEvents)events;
//更新进度条
- (void)updateProgress:(CGFloat)progress;
//更新时间显示
- (void)updateTime:(NSInteger)time;
//更新媒体库图标（isFirst:是否第一次设置）
- (void)updateLibraryCover:(UIImage *)img firstTime:(BOOL)isFirst;
//根据录制管理器状态刷新视图
- (void)reloadRecord:(CWRecordState)state;

@end
