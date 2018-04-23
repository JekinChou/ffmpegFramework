//
//  ViewController.m
//  ffmpegKit
//
//  Created by zhangjie on 2018/4/23.
//  Copyright © 2018年 zhangjie. All rights reserved.
//

#import "ViewController.h"
#include "avformat.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    av_register_all();
    NSLog(@"配置成功");
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
