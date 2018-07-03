//
//  PushStreamViewController.m
//  ffmpegKit
//
//  Created by zhangjie on 2018/5/2.
//  Copyright © 2018年 zhangjie. All rights reserved.
//

#import "PushStreamViewController.h"
#import "avformat.h"
#import "mathematics.h"
#import "time.h"
@interface PushStreamViewController ()

@end

@implementation PushStreamViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self pushToRtmp];
}
- (void)pushToRtmp {
    
    av_register_all();
    avformat_network_init();
    
    char input_str_full[500] = {0};
    char output_str_full[500] = {0};
    
    NSString *input_str= [NSString stringWithFormat:@"resource.bundle/%@",@"输入文件"];
    NSString *input_nsstr=[[[NSBundle mainBundle]resourcePath] stringByAppendingPathComponent:input_str];
    
    sprintf(input_str_full,"%s",[input_nsstr UTF8String]);
    sprintf(output_str_full,"%s",[@"输出路径" UTF8String]);
    //输出格式
    AVOutputFormat *ofmt = NULL;
    //创建格式输出上下文
    AVFormatContext *ifmt_ctx = NULL, *ofmt_ctx = NULL;
    
    AVPacket pkt;
    char in_filename[500]={0};
    char out_filename[500]={0};
    int ret, i;
    int videoindex=-1;
    int frame_index=0;
    int64_t start_time=0;
    strcpy(in_filename,input_str_full);
    strcpy(out_filename,output_str_full);
    
    if ((ret = avformat_open_input(&ifmt_ctx, in_filename, NULL, NULL))!=noErr) {
        //打开输入出错
        goto Error;
    }
    if((ret = avformat_find_stream_info(ifmt_ctx,NULL))!=noErr){
        goto Error;
    }
    for(i=0; i<ifmt_ctx->nb_streams; i++){
        if(ifmt_ctx->streams[i]->codec->codec_type==AVMEDIA_TYPE_VIDEO){
            videoindex=i;
            break;
        }
    }
    av_dump_format(ifmt_ctx, 0, in_filename, 0);
    avformat_alloc_output_context2(&ofmt_ctx, NULL, "flv", "输出文件名"); //RTMP
    //avformat_alloc_output_context2(&ofmt_ctx, NULL, "mpegts", out_filename);//UDP
    //输出
    if (!ofmt_ctx) {
        printf( "Could not create output context\n");
        ret = AVERROR_UNKNOWN;
        goto Error;
    }
     ofmt = ofmt_ctx->oformat;
    for (i = 0; i < ifmt_ctx->nb_streams; i++) {
        
        AVStream *in_stream = ifmt_ctx->streams[i];
        AVStream *out_stream = avformat_new_stream(ofmt_ctx, in_stream->codec->codec);
        if (!out_stream) {
            printf( "Failed allocating output stream\n");
            ret = AVERROR_UNKNOWN;
            goto Error;
        }
        
        ret = avcodec_copy_context(out_stream->codec, in_stream->codec);
        if (ret < 0) {
            printf( "Failed to copy context from input to output stream codec context\n");
            goto Error;
        }
        out_stream->codec->codec_tag = 0;
        if (ofmt_ctx->oformat->flags & AVFMT_GLOBALHEADER)
            out_stream->codec->flags |= CODEC_FLAG_GLOBAL_HEADER;
    }
    //转存
    av_dump_format(ofmt_ctx, 0, "输出路径", 1);
     
    
Error:
    avformat_close_input(&ifmt_ctx);
    /* close output */
    if (ofmt_ctx && !(ofmt->flags & AVFMT_NOFILE))
        avio_close(ofmt_ctx->pb);
    avformat_free_context(ofmt_ctx);
    if (ret < 0 && ret != AVERROR_EOF) {
        printf( "Error occurred.\n");
        return;
    }
    return;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
