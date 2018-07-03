//
//  JKH264Decoder.h
//  ffmpegKit
//
//  Created by zhangjie on 2018/7/3.
//  Copyright © 2018年 zhangjie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>
#import <libswscale/swscale.h>

typedef struct YUVFrameDef{
    unsigned int length;
    unsigned char *dataBuffer;
    
}YUVFrame;

typedef struct H265YUVDef{
    unsigned int width;
    unsigned int height;
    YUVFrame luma;
    YUVFrame chronaB;
    YUVFrame  chronaR;
}H264YUV_Frame;


@class JKH264Decoder;
@protocol JKH264DecoderDelegate <NSObject>
- (void)updateDecodeH264FrameData:(JKH264Decoder *)decoder data:(H264YUV_Frame *)data;
@end

@interface JKH264Decoder : NSObject {
    AVCodec *pCodec;
    AVCodecContext *pCodeCtx;
    AVFrame *pVideoFrame;
    AVPacket *pVideoPacket;
    
}
@property (nonatomic,weak) id<JKH264DecoderDelegate> delegate;
- (int)decodeH264Frames:(uint8_t *)inputBuffer length:(unsigned int)length;

@end
