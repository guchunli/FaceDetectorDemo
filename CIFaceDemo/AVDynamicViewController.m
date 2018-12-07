//
//  AVDynamicViewController.m
//  CIFaceDemo
//
//  Created by Yomob on 2018/12/7.
//  Copyright © 2018年 Yomob. All rights reserved.
//

#import "AVDynamicViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface AVDynamicViewController ()<AVCaptureMetadataOutputObjectsDelegate>

//捕捉会话
@property(nonatomic,strong)AVCaptureSession *captureSession;
//展示layer
@property (nonatomic,strong)AVCaptureVideoPreviewLayer *videoPreviewLayer;
//保存屏幕中离开的人脸
@property(nonatomic,strong)NSMutableArray *leaveFaceArray;
//保存屏幕检测到脸对应的layer faceID 作为字典 key
@property(nonatomic,strong)NSMutableDictionary *faceLayerDic;

@end

@implementation AVDynamicViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    
    [self startReading];
    
}

-(NSMutableDictionary *)faceLayerDic{
    if (!_faceLayerDic) {
        
        _faceLayerDic = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    
    return _faceLayerDic;
}

// 检测摄像头数量
- (NSUInteger)cameraCounts {
    
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}

// 获取前置摄像头
- (AVCaptureDevice *)inactiveCamera {
    AVCaptureDevice *deviceSelect = nil;
    if (self.cameraCounts > 1) {
        
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in devices) {
            if (device.position == AVCaptureDevicePositionFront) {
                
                deviceSelect = device;
            }
        }
    }
    
    return deviceSelect;
}

// 开始识别
-(void)startReading{
    
    //读取摄像头授权状态
    NSString *mediaType = AVMediaTypeVideo;//读取媒体类型
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];//读取设备授权状态
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
        
        // 提示开启权限
        
        return;
    }
    
    NSError *error;
    
    //1.初始化捕捉设备（AVCaptureDevice），类型为AVMediaTypeVideo
    AVCaptureDevice *captureDevice = [self inactiveCamera];
    
    
    //2.用captureDevice创建输入流,输入设备转换成AVCaptureDeviceInput对象
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        
        return ;
    }
    //3.创建媒体数据输出流
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    
    //4.实例化捕捉会话
    self.captureSession = [[AVCaptureSession alloc] init];
    
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    //4.1.将输入设备添加到会话
    if ([self.captureSession canAddInput:input]) {
        
        [self.captureSession addInput:input];
    }
    //4.2.将媒体输出设备添加到会话
    if ([self.captureSession canAddOutput:captureMetadataOutput]) {
        
        [self.captureSession addOutput:captureMetadataOutput];
        
    }
    
    NSArray *metaDataObjectTypes = @[AVMetadataObjectTypeFace];
    //4.3.摄像头在捕捉数据时,只会对人脸元数据感兴趣
    captureMetadataOutput.metadataObjectTypes = metaDataObjectTypes;
    
    //获得主队列,因为人脸检测用到硬件加速,而且很多任务都在主线程执行
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    //设置代理 主队列
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:mainQueue];
    
    
    //5.实例化预览图层
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    
    //6.设置预览图层填充方式
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    //7.设置图层的frame
    CGFloat navH = ([[UIApplication sharedApplication] statusBarFrame].size.height+44);
    [_videoPreviewLayer setFrame:CGRectMake(0, navH, self.view.frame.size.width, self.view.frame.size.height-navH)];
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:2 animations:^{
        [weakSelf.view.layer addSublayer:weakSelf.videoPreviewLayer];
        
    }];
    
    //开启会话
    [self.captureSession startRunning];
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection {
    
    NSMutableArray *faceArray = [NSMutableArray arrayWithCapacity:10];
    
    //获取的人脸放到数组中
    
    for (AVMetadataFaceObject *face in metadataObjects) {
        
        //NSLog(@"faceID:%li",(long)face.faceID);
        // NSLog(@"face.bounds:%@",NSStringFromCGRect(face.bounds));
        
        //将摄像头捕捉的人脸位置转换到屏幕位置
        AVMetadataObject *tranformFace = [_videoPreviewLayer  transformedMetadataObjectForMetadataObject:face];
        
        [faceArray addObject:tranformFace];
    }
    
    //将获取的人脸数据进行处理
    [self faceOperation:faceArray];
    
}

-(void)faceOperation:(NSArray *)faceArray{
    
    NSMutableArray *leaveFaceArray = [self.faceLayerDic.allKeys mutableCopy];
    
    for (AVMetadataFaceObject *face in faceArray) {
        
        NSNumber *faceID = @(face.faceID);
        [leaveFaceArray removeObject:faceID];
        CALayer *layer = self.faceLayerDic[faceID];
        
        if(!layer){
            
            //makeFacelayer :新建一个人脸图层
            layer = [self makeFaceLayer];
            
            //将人脸图层添加到videoPreviewLayer
            
            [self.videoPreviewLayer addSublayer:layer];
            
            //将 layer加入字典中
            self.faceLayerDic[faceID] = layer;
        }
        //指定图层的位置
        layer.frame = face.bounds;
        
    }
    
    for (NSNumber *faceID in leaveFaceArray) {
        CALayer *layer = self.faceLayerDic[faceID];
        [layer removeFromSuperlayer];
        [self.faceLayerDic removeObjectForKey:faceID];
        
    }
}



- (CALayer *)makeFaceLayer {
    CALayer *layer = [CALayer layer];
    layer.borderWidth = 2.0f;
    layer.borderColor = [UIColor redColor].CGColor;
    return layer;
}

@end
