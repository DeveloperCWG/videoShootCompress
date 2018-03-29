//
//  CWVideoAssetWrite.h
//  videoShootCompress
//
//  Created by 程文广 on 2018/3/25.
//  Copyright © 2018年 vsc. All rights reserved.
//  github:https://github.com/DeveloperCWG/videoShootCompress
//  简书:https://www.jianshu.com/p/7d9537a891e9

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>
//录制状态
typedef enum{
    CWAssetStateWaiting = 0, //准备中
    CWAssetStateRecording,//录制中
    CWAssetStateFinish,//录制结束
    CWAssetStateFail,//录制出错
}CWRecordAssetState;

typedef void(^Callback)(BOOL isFinished,CGFloat progress,NSError *error);

@interface CWVideoAssetWrite : NSObject
//当前录制写入状态
@property (nonatomic,readonly)CWRecordAssetState state;

- (instancetype)initWithWriteSize:(CGSize)size writeDir:(NSString *)path;
//开始写入数据
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType;
//重置录制画幅
- (void)restSize:(CGSize)size;
//开始录制写入
- (void)startWriteWithMaxInterval:(CGFloat)interval writeName:(NSString *)name completionHandler:(Callback)block;
//结束录制写入
- (void)stopWriteWithCompletionHandler:(void (^)(NSURL *videoUrl,UIImage *coverImage))handler;

@end
