//
//  NetTransferViewController.m
//  ffmpegKit
//
//  Created by zhangjie on 2018/5/2.
//  Copyright © 2018年 zhangjie. All rights reserved.
//

#import "NetTransferViewController.h"
#import "avformat.h"
#import "time.h"
AVFormatContext *_inputContext;
AVFormatContext *_outputContext;
int64_t _lastReadPackTime;
static int interput_cb(void *ctx){
    int timeout = 10;
    if(av_gettime() - _lastReadPackTime>timeout*1000*1000){
        return -1;
    }
    return 0;
}
@interface NetTransferViewController ()


@end

@implementation NetTransferViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initFFmeg];
    [self setOutputWithUrl:@""];
}

- (void)initFFmeg {
    //激活输入输出相关
    av_register_all();
    //激活滤镜相关
    //    avfilter_register_all();
    //激活网络相关
    avformat_network_init();
    //设置log
    av_log_set_level(AV_LOG_ERROR);
}


//int
- (int)setOutputWithUrl:(NSString *)url {
    _inputContext = avformat_alloc_context();
    //为了解决当输出上下文找不到时停顿在此处,而解决
    _lastReadPackTime = av_gettime();
    //上下文循环回调我的函数
    _inputContext->interrupt_callback.callback = interput_cb;
    int ret = avformat_open_input(&_inputContext, [url cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL);
    if (ret != noErr) {
        av_log(NULL, AV_LOG_ERROR, "input create is faile");
        return ret;
    }
    ret = avformat_find_stream_info(_inputContext, NULL);
    if (ret!=noErr) {
       av_log(NULL, AV_LOG_ERROR, "input file stream is faile");
    }else {
      av_log(NULL, AV_LOG_ERROR, "input file stream is successful");
    }
    return ret;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
