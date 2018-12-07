//
//  CIFaceViewController.m
//  CIFaceDemo
//
//  Created by Yomob on 2018/12/7.
//  Copyright © 2018年 Yomob. All rights reserved.
//

#import "CIFaceViewController.h"

@interface CIFaceViewController ()<UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic,strong) UIImageView *imageView;

@end

@implementation CIFaceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat navH = ([[UIApplication sharedApplication] statusBarFrame].size.height+44);
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake((self.view.frame.size.width-100)*0.5, navH, 100, 50)];
    btn.backgroundColor = [UIColor orangeColor];
    [btn setTitle:@"选择图片" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(choosePic) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    CGFloat imgY = CGRectGetMaxY(btn.frame);
    self.imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, imgY, self.view.frame.size.width, self.view.frame.size.height-imgY)];
    self.imageView.backgroundColor = [UIColor lightGrayColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
}

- (void)choosePic{
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self)weakSelf = self;
    
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf takePhoto];
    }];
    [actionSheet addAction:cameraAction];
    UIAlertAction *calbumAction = [UIAlertAction actionWithTitle:@"相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf choosePhoto];
    }];
    [actionSheet addAction:calbumAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [actionSheet addAction:cancelAction];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

#pragma mark == private method
- (void)choosePhoto
{
    // 从相册中选取
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    controller.delegate = self;
    [self presentViewController:controller
                       animated:YES
                     completion:^(void){
                         NSLog(@"Picker View Controller is presented");
                     }];
}

- (void)takePhoto
{
    // 拍照
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.sourceType = UIImagePickerControllerSourceTypeCamera;
    //前摄像头
    controller.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    controller.delegate = (id)self;
    [self presentViewController:controller
                       animated:YES
                     completion:^(void){
                         NSLog(@"Picker View Controller is presented");
                     }];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    __weak typeof(self) weakSelf = self;
    [picker dismissViewControllerAnimated:YES completion:^() {
        
        UIImage *portraitImg = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
        weakSelf.imageView.image = portraitImg;
        [weakSelf faceDetectWithImage:portraitImg];
        
    }];
}

#pragma mark - 识别人脸
- (void)faceDetectWithImage:(UIImage *)image {
    
    for (UIView *view in _imageView.subviews) {
        [view removeFromSuperview];
    }
    
    // 图像识别能力：可以在CIDetectorAccuracyHigh(较强的处理能力)与CIDetectorAccuracyLow(较弱的处理能力)中选择，因为想让准确度高一些在这里选择CIDetectorAccuracyHigh
    NSDictionary *opts = [NSDictionary dictionaryWithObject:
                          CIDetectorAccuracyHigh forKey:CIDetectorAccuracy];
    // 将图像转换为CIImage
    CIImage *faceImage = [CIImage imageWithCGImage:image.CGImage];
    CIDetector *faceDetector=[CIDetector detectorOfType:CIDetectorTypeFace context:nil options:opts];
    // 识别出人脸数组
    NSArray *features = [faceDetector featuresInImage:faceImage];
    //    // 得到图片的尺寸
    //    CGSize inputImageSize = [faceImage extent].size;
    //    //将image沿y轴对称
    //    CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, -1);
    //    //将图片上移
    //    transform = CGAffineTransformTranslate(transform, 0, -inputImageSize.height);
    
    // 取出所有人脸
    NSLog(@"%@",[NSString stringWithFormat:@"识别出了%ld张脸", features.count]);
    if (features.count < 1) {
        NSLog(@"未识别出人脸");
        return;
    }
    for (CIFaceFeature *faceFeature in features){
        //获取人脸的frame
        //        CGRect faceViewBounds = CGRectApplyAffineTransform(faceFeature.bounds, transform);
        //        CGSize viewSize = _imageView.bounds.size;
        //        CGFloat scale = MIN(viewSize.width / inputImageSize.width,
        //                            viewSize.height / inputImageSize.height);
        //        CGFloat offsetX = (viewSize.width - inputImageSize.width * scale) / 2;
        //        CGFloat offsetY = (viewSize.height - inputImageSize.height * scale) / 2;
        //        // 缩放
        //        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scale, scale);
        //        // 修正
        //        faceViewBounds = CGRectApplyAffineTransform(faceViewBounds,scaleTransform);
        //        faceViewBounds.origin.x += offsetX;
        //        faceViewBounds.origin.y += offsetY;
        //
        //        //描绘人脸区域
        //        UIView* faceView = [[UIView alloc] initWithFrame:faceViewBounds];
        //        faceView.layer.borderWidth = 2;
        //        faceView.layer.borderColor = [[UIColor redColor] CGColor];
        //        [_imageView addSubview:faceView];
        
        // 判断是否有左眼位置
        CGFloat circleRadius = 10;
        if(faceFeature.hasLeftEyePosition){
            NSLog(@"左眼位置：%@",NSStringFromCGPoint(faceFeature.leftEyePosition));
            UIView* leftEyeView = [self getRedView:[self getViewFrame:CGRectMake(faceFeature.leftEyePosition.x-circleRadius*0.5, faceFeature.leftEyePosition.y-circleRadius*0.5, circleRadius, circleRadius) faceImage:image]];
            [_imageView addSubview:leftEyeView];
        }
        // 判断是否有右眼位置
        if(faceFeature.hasRightEyePosition){
            NSLog(@"右眼位置：%@",NSStringFromCGPoint(faceFeature.rightEyePosition));
            UIView* rightEyeView = [self getRedView:[self getViewFrame:CGRectMake(faceFeature.rightEyePosition.x-circleRadius*0.5, faceFeature.rightEyePosition.y-circleRadius*0.5, circleRadius, circleRadius) faceImage:image]];
            [_imageView addSubview:rightEyeView];
        }
        // 判断是否有嘴位置
        if(faceFeature.hasMouthPosition){
            NSLog(@"嘴位置：%@",NSStringFromCGPoint(faceFeature.mouthPosition));
            UIView* mouthEyeView = [self getRedView:[self getViewFrame:CGRectMake(faceFeature.mouthPosition.x-circleRadius*0.5, faceFeature.mouthPosition.y-circleRadius*0.5, circleRadius, circleRadius) faceImage:image]];
            [_imageView addSubview:mouthEyeView];
        }
        // 判断下巴位置
        NSLog(@"根据脸确定下巴位置：%@",NSStringFromCGPoint(CGPointMake(faceFeature.bounds.origin.x+faceFeature.bounds.size.width*0.5, faceFeature.bounds.origin.y)));
        NSLog(@"根据嘴确定下巴位置：%@",NSStringFromCGPoint(CGPointMake(faceFeature.mouthPosition.x, faceFeature.bounds.origin.y)));
        UIView* jawEyeView = [self getRedView:[self getViewFrame:CGRectMake(faceFeature.mouthPosition.x-circleRadius*0.5, faceFeature.bounds.origin.y-circleRadius*0.5, circleRadius, circleRadius) faceImage:image]];
        [_imageView addSubview:jawEyeView];
    }
}

- (UIView *)getRedView:(CGRect)frame{
    UIView* mouthEyeView = [[UIView alloc] initWithFrame:frame];
    mouthEyeView.layer.borderWidth = 2;
    mouthEyeView.layer.borderColor = [[UIColor redColor] CGColor];
    return mouthEyeView;
}

- (CGRect)getViewFrame:(CGRect)rect faceImage:(UIImage *)image{
    
    // 将图像转换为CIImage
    CIImage *faceImage = [CIImage imageWithCGImage:image.CGImage];
    // 得到图片的尺寸
    CGSize inputImageSize = [faceImage extent].size;
    //将image沿y轴对称
    CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, -1);
    //将图片上移
    transform = CGAffineTransformTranslate(transform, 0, -inputImageSize.height);
    
    //获取人脸的frame
    CGRect faceViewBounds = CGRectApplyAffineTransform(rect, transform);
    CGSize viewSize = _imageView.bounds.size;
    CGFloat scale = MIN(viewSize.width / inputImageSize.width,
                        viewSize.height / inputImageSize.height);
    CGFloat offsetX = (viewSize.width - inputImageSize.width * scale) / 2;
    CGFloat offsetY = (viewSize.height - inputImageSize.height * scale) / 2;
    
    // 缩放
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scale, scale);
    // 修正
    faceViewBounds = CGRectApplyAffineTransform(faceViewBounds,scaleTransform);
    faceViewBounds.origin.x += offsetX;
    faceViewBounds.origin.y += offsetY;
    
    return faceViewBounds;
}

@end
