//
//  CALayer+Progress.m
//  videoShootCompress
//
//  Created by hyjet on 2018/3/20.
//  Copyright © 2018年 vsc. All rights reserved.
//  github:https://github.com/DeveloperCWG/videoShootCompress
//  简书:https://www.jianshu.com/p/7d9537a891e9

#import "CAShapeLayer+Progress.h"
#import <UIKit/UIKit.h>


@implementation CAShapeLayer (Progress)

CGPoint old_center;
CGFloat old_radius;
CGFloat old_width;
CGColorRef old_bgColor;
CGColorRef old_color;

float old_progress = 0;

//创建圆环进度CAShapeLayer
- (CAShapeLayer *)createProgress:(CGPoint)center
                     radius:(CGFloat)radius
                  lineWidth:(CGFloat)width
            backgroundColor:(CGColorRef)bgColor
                  fillColor:(CGColorRef)color
{
    CAShapeLayer *bgLayer = [self backgroundLayer:center radius:radius lineWidth:width fillColor:bgColor];
    
    old_center = center;
    old_radius = radius;
    old_width = width;
    old_bgColor = bgColor;
    old_color = color;
    
    CAShapeLayer *layer = [CAShapeLayer new];
    layer.lineWidth = width;
    //圆环绘制的填充颜色
    layer.strokeColor = color;
    //圆环内部圆形的填充色
    layer.fillColor = [UIColor clearColor].CGColor;
    //按照顺时针方向
    BOOL clockWise = true;
    //初始化一个路径
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:(-0.5*M_PI) endAngle:(old_progress*2-0.5)*M_PI clockwise:clockWise];
    layer.path = [path CGPath];
    [bgLayer addSublayer:layer];
    return bgLayer;
}

//绘制进度圆环背景环
- (CAShapeLayer *)backgroundLayer:(CGPoint)center
                           radius:(CGFloat)radius
                        lineWidth:(CGFloat)width
                        fillColor:(CGColorRef)color{
    CAShapeLayer *layer = [CAShapeLayer new];
    layer.lineWidth = width;
    //圆环绘制的填充颜色
    layer.strokeColor = color;
    //圆环内部圆形的填充色
    layer.fillColor = [UIColor clearColor].CGColor;
    //按照顺时针方向
    BOOL clockWise = true;
    //初始化一个路径
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:(-0.5*M_PI) endAngle:1.5*M_PI clockwise:clockWise];
    layer.path = [path CGPath];
    return layer;
}

//更新进度
- (void)updateProgress:(float)progress{
    [self removeAllChildLayer];
    old_progress = progress;
    CAShapeLayer *layer =[self createProgress:old_center radius:old_radius lineWidth:old_width backgroundColor:old_bgColor fillColor:old_color];
    [self addSublayer:layer];
}

- (void)resetProgress{
    [self updateProgress:0];
}

- (void)removeAllChildLayer{
    for (CAShapeLayer *lay in self.sublayers)
    {
        [lay removeFromSuperlayer];
    }
}

@end
