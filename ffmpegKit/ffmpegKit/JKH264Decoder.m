//
//  JKH264Decoder.m
//  ffmpegKit
//
//  Created by zhangjie on 2018/7/3.
//  Copyright © 2018年 zhangjie. All rights reserved.
//

#import "JKH264Decoder.h"

@implementation JKH264Decoder
- (instancetype)init {
    if (self = [super init]) {
        [self configCodec];
    }
    return self;
}
- (void)dealloc {
    if (pCodeCtx) {
        avcodec_close(pCodeCtx);
        pCodeCtx = NULL;
    }
    if (pVideoFrame ) {
        av_frame_free(&pVideoFrame);
    }
}

static void copyDecodedFrame(unsigned char *src,unsigned char *dist ,int linesize,int width,int height){
    width = MIN(linesize, width);
    for (NSInteger i = 0; i<height; i++) {
        memcpy(dist, src, width);
        dist += width;
        src += linesize;
    }
}
- (BOOL)configCodec {
    av_register_all();
    avcodec_register_all();
    pCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
    if (!pCodec) {
        return NO;
    }
    
    pCodeCtx = avcodec_alloc_context3(pCodec);
    if (!pCodeCtx) {
        return NO;
    }
    avcodec_open2(pCodeCtx, pCodec , NULL);
    pVideoFrame = av_frame_alloc();
    
    return YES;
}
//解码
- (int)decodeH264Frames:(uint8_t *)inputBuffer length:(unsigned int)length {
    int gotPicPtr = 0;
    int result = 0;
    av_init_packet(pVideoPacket);
    pVideoPacket->data = inputBuffer;
    pVideoPacket->size = length;
//    result = avcodec_decode_video2(pCodeCtx, pVideoFrame, &gotPicPtr, pVideoPacket);
    //yuv 420
    result = avcodec_send_packet(pCodeCtx, pVideoPacket);
    if (result != 0) {
        return result;
    }
    while (avcodec_receive_frame(pCodeCtx, pVideoFrame) == AVERROR_EOF) {//需要一直读取
        
        unsigned int lumaLength = (pCodeCtx->height)*(MIN(pVideoFrame->linesize[0], pCodeCtx->width));
        unsigned int chrombLength = ((pCodeCtx->height)/2)*(MIN(pVideoFrame->linesize[1], (pCodeCtx->width)/2));
        unsigned int chromRLength = ((pCodeCtx->height)/2)*(MIN(pVideoFrame->linesize[1], (pCodeCtx->width)/2));
        H264YUV_Frame *yuv_frame = (H264YUV_Frame *)malloc(sizeof(H264YUV_Frame));
        memset(&yuv_frame, 0, sizeof(yuv_frame));
        yuv_frame->luma.length = lumaLength;
        yuv_frame->chronaB.length = chrombLength;
        yuv_frame->chronaR.length = chromRLength;
        yuv_frame->luma.dataBuffer = malloc(lumaLength);
        yuv_frame->chronaR.dataBuffer = malloc(chromRLength);
        yuv_frame->chronaB.dataBuffer = malloc(chrombLength);
        copyDecodedFrame(pVideoFrame->data[0], yuv_frame->luma.dataBuffer, pVideoFrame->linesize[0], pCodeCtx->width, pCodeCtx->height);
         copyDecodedFrame(pVideoFrame->data[1], yuv_frame->chronaR.dataBuffer, pVideoFrame->linesize[1], pCodeCtx->width / 2, pCodeCtx->height / 2);
         copyDecodedFrame(pVideoFrame->data[2], yuv_frame->chronaB.dataBuffer, pVideoFrame->linesize[2], pCodeCtx->width /2, pCodeCtx->height / 2);
        
        yuv_frame->width = pCodeCtx->width;
        yuv_frame->height= pCodeCtx->height;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateYUVFrameOnMainThread:yuv_frame];
        });
        free(yuv_frame->luma.dataBuffer);
        free(yuv_frame->chronaR.dataBuffer);
        free(yuv_frame->chronaB.dataBuffer);
        free(yuv_frame);
        

    }
    av_packet_unref(pVideoPacket);
    return 0;
}

- (void)updateYUVFrameOnMainThread:(H264YUV_Frame *)yuvframe {
    if (!yuvframe) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(updateYUVFrameOnMainThread:)]) {
        [self updateYUVFrameOnMainThread:yuvframe];
    }
}
@end
