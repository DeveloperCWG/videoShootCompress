//
//  CALayer+Progress.h
//  videoShootCompress
//
//  Created by hyjet on 2018/3/20.
//  Copyright © 2018年 vsc. All rights reserved.
//  github:https://github.com/DeveloperCWG/videoShootCompress
//  简书:https://www.jianshu.com/p/7d9537a891e9

#import <QuartzCore/QuartzCore.h>

@interface CAShapeLayer (Progress)

/**
 @param center 进度环的圆心
 @param radius 进度环的半径
 @param width 进度环的宽度(不是直径)
 @param bgColor 进度环的背景色
 @param color 进度环的填充色
 */
- (CAShapeLayer *)createProgress:(CGPoint)center
                     radius:(CGFloat)radius
                  lineWidth:(CGFloat)width
            backgroundColor:(CGColorRef)bgColor
                  fillColor:(CGColorRef)color;

//更新进度
- (void)updateProgress:(float)progress;

- (void)resetProgress;

@end
