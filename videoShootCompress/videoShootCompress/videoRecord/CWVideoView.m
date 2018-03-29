//
//  CWVideoView.m
//  videoShootCompress
//
//  Created by 程文广 on 2018/3/24.
//  Copyright © 2018年 vsc. All rights reserved.
//  github:https://github.com/DeveloperCWG/videoShootCompress
//  简书:https://www.jianshu.com/p/7d9537a891e9

#import "CWVideoView.h"
#import "CWVideoRecord.h"
#import "CAShapeLayer+Progress.h"

#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

#define headHeight 60.f
#define footHeight 120.f
#define btn_item_width ScreenWidth*0.2

@interface CWVideoView()<UIGestureRecognizerDelegate>

@property (nonatomic, weak, readwrite) id<CWVideoViewDelegate>delegate;
//顶部
@property (nonatomic, strong)UIView *headView;
//底部
@property (nonatomic, strong)UIView *footView;
//底部画面比例
@property (nonatomic, strong)UIView *footToolView;
//底部画面比例
@property (nonatomic, strong)UILabel *timeLabel;
//选中的画面比例对应的btn
@property (nonatomic, strong)UIButton *selectedBtn;
//拍摄圆环进度条
@property (nonatomic, strong)CAShapeLayer *progressLayer;
//启动或停止拍摄的按钮
@property (nonatomic, strong)UIButton *startBtn;
//闪光灯按钮
@property (nonatomic, strong)UIButton *flashLamp;
//摄像头切换按钮
@property (nonatomic, strong)UIButton *subCamera;
//摄像头切换按钮
@property (nonatomic, strong)UIButton *photosBtn;
//摄像头切换按钮
@property (nonatomic, strong)UIButton *close;
//对焦光圈视图
@property (nonatomic, strong)UIView *focusCircleView;
//画面模式的数组
@property (nonatomic, strong)NSArray *sizeTypeArr;
//画面模式对应的按钮数组
@property (nonatomic, strong)NSMutableArray *btnItemArr;
//指向当前画面模式的游标
@property (nonatomic, assign)NSInteger vernier;
//状态
@property (nonatomic, assign)CWRecordState state;
//
@property (nonatomic, assign)BOOL isFirst;

@end

@implementation CWVideoView

-(NSArray *)sizeTypeArr{
    if (self.delegate && [self.delegate respondsToSelector:@selector(renderDataSource)]) {
        _sizeTypeArr = [self.delegate renderDataSource];
    }
    return _sizeTypeArr;
}

- (NSMutableArray *)btnItemArr
{
    if (!_btnItemArr) {
        _btnItemArr = [NSMutableArray array];
    }
    return _btnItemArr;
}

-(UIView *)headView
{
    if (!_headView) {
        _headView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, headHeight)];
        _headView.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.3];
    }
    return _headView;
}

-(UIView *)footView
{
    if (!_footView) {
        _footView = [[UIView alloc]initWithFrame:CGRectMake(0, ScreenHeight-footHeight, ScreenWidth, footHeight)];
        _footView.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.3];
    }
    return _footView;
}

- (UILabel *)timeLabel
{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 150, 60)];
        _timeLabel.center = self.headView.center;
        _timeLabel.text = @"00:00:00";
        _timeLabel.font = [UIFont systemFontOfSize:22];
        _timeLabel.textColor = [UIColor whiteColor];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0];
    }
    return _timeLabel;
}

-(UIView *)footToolView{
    if (!_footToolView) {
        _footToolView = [[UIView alloc]initWithFrame:CGRectZero];
    }
    return _footToolView;
}

-(UIButton *)startBtn
{
    if (!_startBtn) {
        _startBtn = [[UIButton alloc]initWithFrame:CGRectZero];
    }
    return _startBtn;
}

-(UIButton *)flashLamp
{
    if (!_flashLamp) {
        _flashLamp = [[UIButton alloc]init];
        [_flashLamp setImage:[UIImage imageNamed:@"listing_flash_off"] forState:UIControlStateNormal];
        [_flashLamp setImage:[UIImage imageNamed:@"listing_flash_on"] forState:UIControlStateSelected];
        [_flashLamp sizeToFit];
    }
    return _flashLamp;
}

-(UIButton *)subCamera
{
    if (!_subCamera) {
        _subCamera = [[UIButton alloc]init];
        [_subCamera setImage:[UIImage imageNamed:@"listing_camera_lens"] forState:UIControlStateNormal];
        [_subCamera sizeToFit];
    }
    return _subCamera;
}

-(UIButton *)photosBtn
{
    if (!_photosBtn) {
        _photosBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, 50)];
        _photosBtn.layer.cornerRadius = 5;
        _photosBtn.layer.masksToBounds = YES;
    }
    return _photosBtn;
}

-(UIButton *)close
{
    if (!_close) {
        _close = [[UIButton alloc]init];
        [_close setImage:[UIImage imageNamed:@"close_record"] forState:UIControlStateNormal];
        [_close sizeToFit];
    }
    return _close;
}

- (UIView *)focusCircleView{
    
    if (!_focusCircleView) {
        _focusCircleView = [[UIView alloc] init];
        _focusCircleView.frame = CGRectMake(0, 0, 100, 100);
        _focusCircleView.layer.borderColor = [UIColor yellowColor].CGColor;
        _focusCircleView.layer.borderWidth = 2;
        _focusCircleView.layer.cornerRadius = 50;
        _focusCircleView.layer.masksToBounds =YES;
        [self addSubview:_focusCircleView];
    }
    return _focusCircleView;
    
}

-(instancetype)initWithDelegate:(id)delegate{
    if (self = [super initWithFrame:[UIScreen mainScreen].bounds]) {
        _delegate = delegate;
        self.backgroundColor = [UIColor blackColor];
        _vernier = [self indexPathForDataSource:self.sizeTypeArr];
        [self childView];
        [self addGestureRecognizer];
        self.state = CWRecordWaiting;
    }
    return self;
}

//拦截背景色设置防止被修改
- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:[UIColor blackColor]];
}

//子视图初始化
- (void)childView{
    [self addSubview:self.headView];
    [self addSubview:self.footView];
    self.footToolView.frame = CGRectMake(0, 0, self.sizeTypeArr.count*btn_item_width, 30);
    self.footToolView.center = CGPointMake(self.footView.center.x, _footToolView.frame.size.height*0.5);
    [self.footView addSubview:self.footToolView];
    for (NSInteger i=0; i<self.sizeTypeArr.count; i++) {
        NSDictionary *dic = self.sizeTypeArr[i];
        UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(i*btn_item_width, 0, btn_item_width, 30)];
        btn.tag = [dic[@"type"] intValue];
        [btn setTitle:dic[@"text"] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor yellowColor] forState:UIControlStateSelected];
        [btn addTarget:self action:@selector(itemAction:) forControlEvents:UIControlEventTouchDown];
        if (i == self.vernier) {
            [self itemAction:btn];
        }
        [self.btnItemArr addObject:btn];
        [self.footToolView addSubview:btn];
    }
    self.startBtn.frame = CGRectMake(0, 0, 54, 54);
    CGPoint center = CGPointMake(_footView.center.x, (_footView.bounds.size.height-27)*0.5+20);
    self.startBtn.center = center;
    self.startBtn.backgroundColor = [UIColor redColor];
    self.startBtn.layer.cornerRadius = 27;
    self.startBtn.layer.masksToBounds = YES;
//    [self.startBtn addTarget:self action:@selector(startBtnInside:) forControlEvents:UIControlEventTouchUpInside];
    [self.footView addSubview:self.startBtn];
    
    self.progressLayer = [[CAShapeLayer alloc]createProgress:center radius:32 lineWidth:5 backgroundColor:[UIColor whiteColor].CGColor fillColor:[UIColor redColor].CGColor];
    [self.footView.layer addSublayer:self.progressLayer];
    
    self.flashLamp.center = CGPointMake(ScreenWidth-30, headHeight*0.5);
    self.subCamera.center = CGPointMake(ScreenWidth-50, (_footView.bounds.size.height-27)*0.5+20);
    [self.subCamera addTarget:self action:@selector(subCameraEvent:) forControlEvents:UIControlEventTouchUpInside];
    self.close.center = CGPointMake(30, headHeight*0.5);
    self.photosBtn.center = CGPointMake(50, (_footView.bounds.size.height-27)*0.5+20);
    [self.headView addSubview:self.flashLamp];
    [self.footView addSubview:self.subCamera];
    
    [self.headView addSubview:self.timeLabel];
    [self.footView addSubview:self.photosBtn];
    [self.headView addSubview:self.close];
}

- (void)subCameraEvent:(UIButton *)btn{
    self.flashLamp.selected = NO;
    self.flashLamp.hidden = !self.flashLamp.hidden;
}

//默认选中的画幅
- (NSInteger)indexPathForDataSource:(NSArray *)dataSource{
    NSDictionary *defaultDic = nil;
    NSInteger index = 0;
    if (self.delegate && [self.delegate respondsToSelector:@selector(defaultSelectedItem)]) {
        defaultDic = [self.delegate defaultSelectedItem];
    }
    for (NSInteger i = 0;i<self.sizeTypeArr.count;i++) {
        NSDictionary *dic = self.sizeTypeArr[i];
        if ([dic isEqualToDictionary:defaultDic]) {
            index = i;
            break;
        }
    }
    return index;
}

//监听闪光灯状态切换
- (void)addFlashLampChange:(id)obj action:(SEL)sel forControlEvents:(UIControlEvents)events
{
    [self.flashLamp addTarget:obj action:sel forControlEvents:events];
}

//监听摄像头切换
- (void)addSubCameraChange:(id)obj action:(SEL)sel forControlEvents:(UIControlEvents)events
{
    [self.subCamera addTarget:obj action:sel forControlEvents:events];
}

//监听拍摄按钮点击
- (void)addRecordChange:(id)obj action:(SEL)sel forControlEvents:(UIControlEvents)events
{
    [self.startBtn addTarget:obj action:sel forControlEvents:events];
}

//监听关闭按钮点击
- (void)addCloseChange:(id)obj action:(SEL)sel forControlEvents:(UIControlEvents)events
{
    [self.close addTarget:obj action:sel forControlEvents:events];
}

//监听媒体库按钮点击
- (void)addPhotosChange:(id)obj action:(SEL)sel forControlEvents:(UIControlEvents)events
{
    [self.photosBtn addTarget:obj action:sel forControlEvents:events];
}


//画面对应的btn点击事件
- (void)itemAction:(UIButton *)sender{
    if (self.selectedBtn) {
        self.selectedBtn.selected = !self.selectedBtn.selected;
    }
    self.selectedBtn = sender;
    sender.selected = !sender.selected;
    for (NSInteger indx=0; indx<self.sizeTypeArr.count; indx++) {
        NSDictionary *dic = self.sizeTypeArr[indx];
        if ([dic[@"type"] intValue] == sender.tag) {
            self.vernier = indx;
            if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectedItemIndexPath:)]) {
                [self.delegate didSelectedItemIndexPath:_vernier];
            }
            break;
        }
    }
}
//更新视图状态
- (void)reloadRecord:(CWRecordState)state
{
    self.state = state;
}
//监听视图状态更新
- (void)setState:(CWRecordState)state
{
    _state = state;
    switch (_state) {
        case CWRecordWaiting:
            _startBtn.enabled = NO;
            _subCamera.hidden = _flashLamp.hidden = YES;
            break;
        case CWRecordReady:
            _startBtn.enabled = YES;
            [self starBtnAnimation:NO];
            _flashLamp.hidden = _close.hidden = _subCamera.hidden = NO;
            [self reset];
            for (UIGestureRecognizer *ges in self.gestureRecognizers) {
                ges.enabled = YES;
            }
            [self triggertFocus];
            break;
        case CWRecordRecording:
            [self starBtnAnimation:YES];
            for (UIGestureRecognizer *ges in self.gestureRecognizers) {
                ges.enabled = NO;
            }
            _close.hidden = _subCamera.hidden = YES;
            break;
        default:
            break;
    }
    [self vernierMovement:_vernier];
}

//触发对焦
- (void)triggertFocus{
    if (self.isFirst) {
        [self setFocusCursorAnimationWithPoint:self.center];
        if (self.delegate && [self.delegate respondsToSelector:@selector(triggetFocusChange:)]) {
            [self.delegate triggetFocusChange:self.center];
        }
    }
}

//添加手势
- (void)addGestureRecognizer{
    UISwipeGestureRecognizer *left = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipes:)];
    left.direction=UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer:left];
    
    UISwipeGestureRecognizer *right = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipes:)];
    right.direction=UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer:right];
    
    UITapGestureRecognizer *singleTapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTap:)];
    singleTapGesture.numberOfTapsRequired = 1;
    singleTapGesture.delaysTouchesBegan = YES;
    singleTapGesture.delegate = self;
 
    UITapGestureRecognizer *doubleTapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    doubleTapGesture.delaysTouchesBegan = YES;
    [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];
    [self addGestureRecognizer:singleTapGesture];
    [self addGestureRecognizer:doubleTapGesture];
}

//左右滑动手势事件监听
- (void)handleSwipes:(UISwipeGestureRecognizer *)recognizer{
    if(recognizer.direction==UISwipeGestureRecognizerDirectionLeft){
        if (_vernier<2) {
            _vernier++;
        }
    }
    if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        if (_vernier>0) {
            _vernier--;
        }
    }
    [self vernierMovement:_vernier];
}

//点击对焦
- (void)singleTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint point= [recognizer locationInView:self];
    //判断是否在有效区域
    BOOL isResultful = CGRectContainsPoint([self dispalyView],point);
    if (!isResultful) {
        return;
    }
    [self setFocusCursorAnimationWithPoint:point];
    if (self.delegate && [self.delegate respondsToSelector:@selector(triggetFocusChange:)]) {
        [self.delegate triggetFocusChange:point];
    }
}

- (void)doubleTap:(UITapGestureRecognizer *)recognizer
{

}

//返回手势识别区
- (CGRect)dispalyView{
    CGRect rect;
    NSDictionary *dic = self.sizeTypeArr[_vernier];
    CWVideoSize sizeType = [dic[@"type"] intValue];
    switch (sizeType) {
        case CWSize1X1:
            rect = CGRectMake(self.bounds.origin.x, (self.bounds.size.height-self.bounds.size.width)*0.5, self.bounds.size.width, self.bounds.size.width);  
            break;
        case CWSize4X3:
            rect = CGRectMake(self.bounds.origin.x, (self.bounds.size.height-self.bounds.size.width*3/4)*0.5, self.bounds.size.width, self.bounds.size.width*3/4);
            break;
        case CWSizeScreenFull:
            rect = self.bounds;
            break;
        default:
            break;
    }
    return rect;
}

//移动游标
- (void)vernierMovement:(NSInteger)indexPath{
    [self itemAction:self.btnItemArr[indexPath]];
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectedItemIndexPath:)]) {
        [self.delegate didSelectedItemIndexPath:indexPath];
    }
}


//光圈动画
-(void)setFocusCursorAnimationWithPoint:(CGPoint)point{
    self.focusCircleView.center = point;
    self.focusCircleView.transform = CGAffineTransformIdentity;
    self.focusCircleView.hidden = NO;
    [UIView animateWithDuration:0.4 animations:^{
        self.focusCircleView.transform=CGAffineTransformMakeScale(0.7, 0.7);
    }];
    [self performSelector:@selector(focusViewHidden) withObject:nil afterDelay:0.7];
}

//启动拍摄的启动按钮动画
- (void)starBtnAnimation:(BOOL)isStart{
    if (isStart) {
        CGAffineTransform transform = CGAffineTransformMakeScale(0.5, 0.5);
        [UIView animateWithDuration:0.2 animations:^{
            self.startBtn.layer.cornerRadius = 5;
            [self.startBtn setTransform:transform];
            self.footToolView.alpha = 0;
            self.footView.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0];
        }];
    } else {
        CGAffineTransform transform = CGAffineTransformIdentity;
        [UIView animateWithDuration:0.2 animations:^{
            self.startBtn.layer.cornerRadius = 27;
            [self.startBtn setTransform:transform];
            self.startBtn.selected = isStart;
            self.footToolView.alpha = 1;
            self.footView.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.3];
        }];
    }
}
//隐藏对焦光圈
- (void)focusViewHidden{
    self.focusCircleView.hidden = YES;
}
//更新进度
- (void)updateProgress:(CGFloat)progress{
    [self.progressLayer updateProgress:progress];
}
//更新计时
- (void)updateTime:(NSInteger)time{
    self.timeLabel.text = [self timeWithString:time];
}
//更新相册按钮封面
- (void)updateLibraryCover:(UIImage *)img firstTime:(BOOL)isFirst
{
    self.isFirst = isFirst;
    if (isFirst) {
        [self.photosBtn setBackgroundImage:img forState:UIControlStateNormal];
        return;
    }
    UIImageView *imgView = [[UIImageView alloc]initWithImage:img];
    UIWindow * window=[[[UIApplication sharedApplication] delegate] window];
    imgView.alpha = 0.8;
    imgView.center = self.center;
    [self addSubview:imgView];
    [UIView animateWithDuration:0.5 animations:^{
        imgView.frame = [_photosBtn convertRect: _photosBtn.bounds toView:window];
        imgView.layer.cornerRadius = 5;
        imgView.layer.masksToBounds = YES;
        imgView.alpha = 0.2;
    } completion:^(BOOL finished) {
        [self.photosBtn setBackgroundImage:img forState:UIControlStateNormal];
        [imgView removeFromSuperview];
    }];
}
//刷新进度和计时
- (void)reset{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.timeLabel.text = @"00:00:00";
        [self.progressLayer resetProgress];
    });
}
//整理时间格式
- (NSString *)timeWithString:(NSInteger)time{
    NSInteger timeH = time/3600;
    NSInteger timeM = time%3600/60;
    NSInteger timeS = time%3600%60;
    return [NSString stringWithFormat:@"%02zd:%02zd:%02zd",timeH,timeM,timeS];
}

#pragma UIGestureRecognizerDelegate
//防止手势事件穿透
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([touch.view isMemberOfClass:[self class]]) {
        return YES;
    }
    return NO;
}

@end
