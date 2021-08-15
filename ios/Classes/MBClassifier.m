//
//  MBClassifier.m
//  not-hotdog
//
//  Created by Jura on 03/04/2018.
//  Copyright © 2018 MicroBlink. All rights reserved.
//

#import "MBClassifier.h"

#import "Nudity.h"
#import "Nudity2.h"

#import <CoreML/CoreML.h>
#import <Vision/Vision.h>
#import "TiBase.h"
#import "TiUtils.h"
#import "TiBlob.h"
#import "TiApp.h"
#import "UIImage+MBResize.h"
#import "MBImage.h"

@interface MBClassifier ()

@property (nonatomic) Nudity* nudity;

@property (nonatomic) Nudity2* nudity2;

@property (nonatomic) VNCoreMLModel *vnModel;

@property (nonatomic) VNCoreMLModel *vnModel2;

@property (nonatomic) UIImageOrientation orientation;

@property (nonatomic) BOOL processing;


@end

@implementation MBClassifier

- (instancetype)init {
    self = [super init];
    if (self) {
        _nudity = [[Nudity alloc] init];
        _nudity2 = [[Nudity2 alloc] init];
        _vnModel = [VNCoreMLModel modelForMLModel:_nudity.model error:nil];
        _vnModel2 = [VNCoreMLModel modelForMLModel:_nudity2.model error:nil];
        _orientation = UIImageOrientationRight;
        _processing = NO;
    }
    return self;
}

- (void)updateWithDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            self.orientation = UIImageOrientationRight;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            self.orientation = UIImageOrientationLeft;
            break;
        case UIDeviceOrientationLandscapeLeft:
            self.orientation = UIImageOrientationUp;
            break;
        case UIDeviceOrientationLandscapeRight:
            self.orientation = UIImageOrientationDown;
            break;
        default:
            self.orientation = UIImageOrientationUp;
            break;
    }
}




- (UIImage *)normalizedImage:(UIImage *)image
{
    UIGraphicsBeginImageContext(CGSizeMake(224, 224));
    [image drawInRect:CGRectMake(0, 0, 224, 224)];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

- (CVPixelBufferRef)pixelBufferForNukeDFromImage:(UIImage *)image
{
    CGImageRef cgRef = image.CGImage;
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    // nukeD model要求224*224的输入！
    CGFloat frameWidth = 224.0;
    CGFloat frameHeight = 224.0;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    // gzw todo: 记录数据！ 1/2/3。
    //1.直接使用标准变换 CGContextConcatCTM(context, CGAffineTransformIdentity) = 不加任何变换
    //2.加上下面的三种变换： Rotation + flipVertical + flipHorizontal
    //3.注释掉flipHorizontal
    // 测试用pic A B C D..（默认取左上） 注：为避免不必要的问题，这里不把样本贴出。
    // pic A:纯黄图，上半身，无衣物
    // pic B:上半身，有胸罩，不能算严格的黄图
    // pic C:正常人物图，非黄
    // pic D:擦边球类型的性感图，取右上。
    // pic E:大概率认定为黄图，左侧有物体遮挡。
    // results:(A/B/C/D/E)
    // 1. 97.76黄/56.44黄/99.57正常/93.10黄/90.39黄
    // 2. 89.97黄/71.70黄/97.48正常/71.09黄/54.96正常
    // 3. 92.48黄/64.39黄/93.62正常/81.03黄/55.44正常
    //
    //结论：对于无疑的判例A和C，1的置信度更高，结果更可信;
    //对于判例B, 2和3更高概率认定为黄图，不理想;
    //对于判例D, 1的置信度更高（三种都认定其为黄图，取0.7的时候），我们认为也没有问题。
    //对于判例E, 输入的画面基本全裸体，1认定为黄图，另外两种认定为正常；1是最理想的。
    
    // 实验表明转换会降低精度。说明这里的输入应该不转换为宜。？？！！！
    // 不同的输入，不同的结果！
    
//    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0)); //0
//    CGAffineTransform flipVertical = CGAffineTransformMake( 1, 0, 0, -1, 0, CGImageGetHeight(cgRef));
//    CGContextConcatCTM(context, flipVertical);

//    CGAffineTransform flipHorizontal = CGAffineTransformMake( -1.0, 0.0, 0.0, 1.0, CGImageGetWidth(cgRef), 0.0);
//    CGContextConcatCTM(context, flipHorizontal);
    
    //gzw
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           frameWidth,
                                           frameHeight),
                       cgRef);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}















//- (NSString *)classify:(id)imageObj handler:(void(^)(NSString*))handler2 {

- (NSDictionary *)classify:(id)imageObj {
   // NSLog(@"Classify ");

//    if (self.processing) {
//        return;
//    }
//    self.processing = YES;
    NSDictionary *dictionary;

    TiBlob *blob = (TiBlob*)imageObj;

    UIImage *resizedImage = [[blob image] resizedImage:CGSizeMake(224, 224) interpolationQuality:kCGInterpolationHigh];

    CVPixelBufferRef pixelRef = [resizedImage pixelBuffer];

    NudityOutput *output = [self.nudity predictionFromData:pixelRef error:nil];

//    NudityOutput *output = [self.nudity predictionFromImage:pixelRef error:nil];
  //  NSLog(@"Class %@", output.classLabel);

    CVPixelBufferRelease(pixelRef);
  //  self.processing = NO;
    
   // dictionary = output.prob;
    
    NSMutableDictionary * event = [NSMutableDictionary dictionary];
    //
    //        [event setValue:nsfwClass
    //                 forKey:@"class"];
    
    [event setValue:output.classLabel
            forKey:@"classLabel"];
    [event setValue:output.prob
            forKey:@"prob"];
    
    return event;
    
  //  handler2(output.classLabel);
//    NSString *resultObject = [NSString stringWithFormat:@"{\"identifier\":\"%@\"}", output.classLabel];
//    handler(resultObject);
}




- (NSDictionary *)classify2:(id)imageObj {
   // NSLog(@"Classify ");

//    if (self.processing) {
//        return;
//    }
//    self.processing = YES;
    NSDictionary *dictionary;

    TiBlob *blob = (TiBlob*)imageObj;

    UIImage *resizedImage = [[blob image] resizedImage:CGSizeMake(224, 224) interpolationQuality:kCGInterpolationHigh];

    CVPixelBufferRef pixelRef = [resizedImage pixelBuffer];

  //  NudityOutput *output = [self.nudity predictionFromData:pixelRef error:nil];

    Nudity2Output *output = [self.nudity2 predictionFromImage:pixelRef error:nil];
  //  NSLog(@"Class %@", output.classLabel);

    CVPixelBufferRelease(pixelRef);
  //  self.processing = NO;
    
   // dictionary = output.prob;
    
    NSMutableDictionary * event = [NSMutableDictionary dictionary];
    //
    //        [event setValue:nsfwClass
    //                 forKey:@"class"];
    
    [event setValue:output.classLabel
            forKey:@"classLabel"];
    [event setValue:output.output
            forKey:@"output"];
    
    return event;
    
  //  handler2(output.classLabel);
//    NSString *resultObject = [NSString stringWithFormat:@"{\"identifier\":\"%@\"}", output.classLabel];
//    handler(resultObject);
}





- (void)classifyRequest:(id)imageObj handler:(void(^)(NSObject*))handler {
//    NSLog(@"ClassifyRequest ");

    TiBlob *blob = (TiBlob*)imageObj;
    
  //  NSLog(@"After to Blob ");

                        
    UIImage *resizedImage = [[blob image] resizedImage:CGSizeMake(224, 224) interpolationQuality:kCGInterpolationHigh];

    CVPixelBufferRef pixelRef = [resizedImage pixelBuffer];

    
  //  NSLog(@"After to Resize ");

    
    VNCoreMLRequest *request = [[VNCoreMLRequest alloc] initWithModel:self.vnModel completionHandler:(VNRequestCompletionHandler)^(VNRequest *request, NSError *error){
        
    //    NSLog(@"In check ");

//        VNImageRequestHandler *handlerTwo = [[VNImageRequestHandler alloc] initWithCGImage:resizedImage.CGImage options:@{}];
//        [handlerTwo performRequests:@[request] error:nil];
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            VNClassificationObservation *topResult = ((VNClassificationObservation *)(request.results[0]));

        VNClassificationObservation *secondResult = ((VNClassificationObservation *)(request.results[1]));

        
            
            
            NSDictionary * dictionary = [self classify2:blob];
        
            NSObject *resultObject = @{ @"identifier": topResult.identifier, @"confidence": NUMFLOAT(topResult.confidence), @"second": dictionary };

            
     //       NSString *resultObject = [NSString stringWithFormat:@"{\"identifier\":\"%@\",\"confidence\":\"%@\",\"second_identifier\":\"%@\",\"second_confidence\":\"%@\"}", topResult.identifier, NUMFLOAT(topResult.confidence),secondResult.identifier, NUMFLOAT(secondResult.confidence)];
        
        handler(resultObject);


        
    //    [self fireEvent:@"result" withObject:@{ @"identifier": topResult.identifier, @"confidence": NUMFLOAT(topResult.confidence) }];
        
        
     //       NSLog(@"Identified: %@", [topResult identifier]);
        });
    }];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        VNImageRequestHandler *handlerTwo = [[VNImageRequestHandler alloc] initWithCGImage:resizedImage.CGImage options:@{}];
        [handlerTwo performRequests:@[request] error:nil];
    });
}






//
//
//- (void)classifyRequest2:(id)imageObj handler:(void(^)(NSString*))handler {
////    NSLog(@"ClassifyRequest ");
//
//    TiBlob *blob = (TiBlob*)imageObj;
//    
//  //  NSLog(@"After to Blob ");
//
//                        
//    UIImage *resizedImage = [[blob image] resizedImage:CGSizeMake(224, 224) interpolationQuality:kCGInterpolationHigh];
//
//    CVPixelBufferRef pixelRef = [resizedImage pixelBuffer];
//
//    
//  //  NSLog(@"After to Resize ");
//
//    
//    VNCoreMLRequest *request = [[VNCoreMLRequest alloc] initWithModel:self.vnModel2 completionHandler:(VNRequestCompletionHandler)^(VNRequest *request, NSError *error){
//        
//    //    NSLog(@"In check ");
//
////        VNImageRequestHandler *handlerTwo = [[VNImageRequestHandler alloc] initWithCGImage:resizedImage.CGImage options:@{}];
////        [handlerTwo performRequests:@[request] error:nil];
//        
//        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            VNClassificationObservation *topResult = ((VNClassificationObservation *)(request.results[0]));
//
//        VNClassificationObservation *secondResult = ((VNClassificationObservation *)(request.results[1]));
//
//        
//     //   NSObject *resultObject = @{ @"identifier": topResult.identifier, @"confidence": NUMFLOAT(topResult.confidence) };
//        
//        
//            NSString *resultObject = [NSString stringWithFormat:@"{\"identifier\":\"%@\",\"confidence\":\"%@\",\"second_identifier\":\"%@\",\"second_confidence\":\"%@\"}", topResult.identifier, NUMFLOAT(topResult.confidence),secondResult.identifier, NUMFLOAT(secondResult.confidence)];
//        
//        handler(resultObject);
//
//
//        
//    //    [self fireEvent:@"result" withObject:@{ @"identifier": topResult.identifier, @"confidence": NUMFLOAT(topResult.confidence) }];
//        
//        
//     //       NSLog(@"Identified: %@", [topResult identifier]);
//        });
//    }];
//
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        VNImageRequestHandler *handlerTwo = [[VNImageRequestHandler alloc] initWithCGImage:resizedImage.CGImage options:@{}];
//        [handlerTwo performRequests:@[request] error:nil];
//    });
//}









@end
