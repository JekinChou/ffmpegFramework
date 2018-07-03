//
//  FFmpegInputViewController.m
//  ffmpegKit
//
//  Created by zhangjie on 2018/4/26.
//  Copyright © 2018年 zhangjie. All rights reserved.
//

#import "FFmpegInputViewController.h"
#include "avformat.h"
#include "avfilter.h"
#include <memory.h>
@interface FFmpegInputViewController ()
@end
static FFmpegInputViewController *controller;
@implementation FFmpegInputViewController {
    AVFormatContext *_inputContext;
    AVFormatContext *_outputContext;
}
//log
void coustom_error_log(char *contentString){
    av_log(NULL, AV_LOG_ERROR, "%s", contentString);
}
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        controller = self;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initFFmeg];
    [self openIOWithUrl:@""];
    
    
}
- (void)openIOWithUrl:(NSString *)url {
    const char *_Nullable url2 = [url cStringUsingEncoding:NSUTF8StringEncoding];
    int ret = OpenInput(url2);
    if (ret == 0) {
        ret = openOutPut("路径");
    }
    if (ret <0) {
        goto ERROR;
    }
    //读取
    while (1) {
        AVPacket *packet = readPacketFromSouce();
        if (!packet)goto ERROR;
        //包有了,将他写到文件中去
        ret = writePacket(packet);
        if (ret < 0) {
            
        }else {
            
        }
    }
    
ERROR:
    while (1) {
        [NSThread sleepForTimeInterval:100];
    }
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
//读取数据包
AVPacket *readPacketFromSouce(){
    AVPacket *packet =  av_packet_alloc();
    int ret = av_read_frame(controller->_inputContext, packet);
    if (ret>=0) {
        return packet;
    }
    return NULL;
}
//写入包
int writePacket(AVPacket *packet){
    
    AVStream *inputStream = controller->_inputContext->streams[packet->stream_index];
    AVStream *outputStream = controller->_outputContext->streams[packet->stream_index];
    //修正时间基准
    av_packet_rescale_ts(packet, inputStream->time_base, outputStream->time_base);
    int ret = av_interleaved_write_frame(controller->_outputContext, packet);
    return ret;
}

//创建输入的上下文
int OpenInput(char *_Nullable url){
    controller->_inputContext = avformat_alloc_context();
    int ret = avformat_open_input(&controller->_inputContext, url, NULL, NULL);
    if (ret!= 0) {
        av_log(NULL, AV_LOG_ERROR, "input file is error");
        return ret;
    }
    ret = avformat_find_stream_info(controller->_inputContext, NULL);
    if(ret == 0)av_log(NULL, AV_LOG_FATAL, "input file is successful");
    return ret;
}


/**
 创建输出上下文

 @param outputUrl 输出路径
 @return 错误码
 */
int openOutPut(char *outputUrl){
    //"mpegts"->输出格式 为ts
    int ret = avformat_alloc_output_context2(&controller->_outputContext, NULL, "mpegts", outputUrl);//输出
    if (ret <0) {
        coustom_error_log("open Output file is Out");
        goto ERROR;
    }

    /**
     @param controller->_outputContext->pb 输出上下文
     @param outputUrl outputUrl description
     @param AVIO_FLAG_READ_WRITE 可读可写

     */
    ret = avio_open2(&controller->_outputContext->pb, outputUrl, AVIO_FLAG_READ_WRITE, NULL, NULL);
    if (ret<0) {
        coustom_error_log("open out put is fail");
        
        goto ERROR;
    }
 
    //输出上下文所包含的留信息
    for (int i = 0; i<controller->_inputContext->nb_streams; i++) {
        //输入的想对应的流做为参数
        //编码器
        //输出上下文依赖输入上下文
        
        AVStream *stream = avformat_new_stream(controller->_outputContext,NULL);
        //将输入流->输到输出流
//  我用的还是3.0.0的方式,注释的是新的方式读取
//        avcodec_parameters_from_context(controller->_inputContext->streams[i]->codecpar, controller->_inputContext->streams[i]->codec);
//        avcodec_parameters_to_context(stream->codec,controller->_outputContext->streams[i]->codecpar);
//
        ret = avcodec_copy_context(stream->codec, controller->_inputContext->streams[i]->codec);
        if (ret<0) {
             coustom_error_log("copy coddec context failed");
            goto ERROR;
        }
    }
    ret = avformat_write_header(controller->_outputContext, NULL);
    if (ret<0) {
        coustom_error_log("write header is fail");
        goto  ERROR;
    }
    return ret;
    
    
    
ERROR:
    if (controller->_outputContext) {
        for (int i = 0; i <controller->_outputContext->nb_streams; i++) {
            avcodec_close(controller->_outputContext->streams[i]->codec);
        }
        avformat_close_input(&controller->_inputContext);
        controller->_inputContext = NULL;
    }
    return ret;
}


@end
