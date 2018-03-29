//
//  ViewController.m
//  videoShootCompress
//
//  Created by hyjet on 2018/3/20.
//  Copyright © 2018年 vsc. All rights reserved.
//  github:https://github.com/DeveloperCWG/videoShootCompress
//  简书:https://www.jianshu.com/p/7d9537a891e9

#import "ViewController.h"
#import "CAShapeLayer+Progress.h"
#import "CWVideoShootController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


- (IBAction)startShoot:(UIButton *)sender {
    CWVideoShootController *vc = [[CWVideoShootController alloc]init];
    UINavigationController *navc = [[UINavigationController alloc]initWithRootViewController:vc];
    navc.navigationBar.hidden = YES;
    [self presentViewController:navc animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
