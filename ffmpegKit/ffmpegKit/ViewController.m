//
//  ViewController.m
//  ffmpegKit
//
//  Created by zhangjie on 2018/4/23.
//  Copyright © 2018年 zhangjie. All rights reserved.
//

#import "ViewController.h"
#include "avformat.h"
#include "SDL.h"
#include "file.h"
const int pixel_w = 375;//视频像素宽 需要按视频进行修改,不固定
const int pixel_h = 667;//视频像素高
const int bpp = 12;
@interface ViewController () {
    unsigned char buffer[pixel_w/pixel_h*bpp/8];
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //ffmpeg初始化
    av_register_all();
    NSLog(@"配置成功");
    //SDL初始化
    SDL_SetMainReady();//因为官网dll问题,在初始化之前需要调用此句代码
    if(SDL_Init(SDL_INIT_VIDEO))
    return;
    SDL_Window *window = SDL_CreateWindow("orignalWindow",SDL_WINDOWPOS_UNDEFINED,SDL_WINDOWPOS_UNDEFINED, pixel_w, pixel_h, SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);
    if(!window){
        NSLog(@"创建失败%s",SDL_GetError());
    }else {
        NSLog(@"创建成功");
    }
    //构造渲染器
    SDL_Renderer *render = SDL_CreateRenderer(window, -1, 0);
    //像素设置 
    UInt32 pixformat = 0;
    //IYUV:Y+U+V  (3 planes)
    //YV:Y+V+U (3 planes)
    pixformat = SDL_PIXELFORMAT_IYUV;
    //创建纹理
    SDL_Texture *sdlTexture = SDL_CreateTexture(render, pixformat, SDL_TEXTUREACCESS_STATIC, 375, 667);
    //选择文件路径
    FILE *fp = NULL;
    fp = fopen("xxx.yuv","rb+");
    //创建显示矩形(决定图形显示在widow的什么位置上(rect小于window大小的话,周围为黑边))
    SDL_Rect sdlRect;
    //读取数据
    while(1){//TEST
        //1点1点读取,当内容全部读完就不循环了
        //buffer 存储读取的数据
        //YUV:Y数据的量为宽*高  UV:宽*0.5 高*0.5
        //总数据为1+1/4+1/4 = 1.5
        
        if(fread(buffer, 1, pixel_w*pixel_h*bpp/8 , fp)!= pixel_w*pixel_h*bpp/8){
            //loop
            fseek(fp, 0, SEEK_SET);
            fread(buffer, 1, pixel_w/pixel_h*bpp/8, fp);
        }
        //更新纹理用于显示
        SDL_UpdateTexture(sdlTexture, NULL, buffer, pixel_w);
        sdlRect.x = 0;
        sdlRect.y = 0;
        sdlRect.w = pixel_w;
        sdlRect.h = pixel_h;
        
        SDL_RenderClear(render);
        //读取所填信息,将视频确定显示位置
        SDL_RenderCopy(render, sdlTexture, NULL, &sdlRect);
        SDL_RenderPresent(render);
        //放慢倍数,越大越慢(倍数 = num/10)
        SDL_Delay(40);
    }
    SDL_Quit();
}



@end
