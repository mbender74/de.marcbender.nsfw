//
//  MBClassifier.h
//  not-hotdog
//
//  Created by Jura on 03/04/2018.
//  Copyright © 2018 MicroBlink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "TiBase.h"
#import "TiUtils.h"
#import "TiBlob.h"
#import "TiApp.h"

@interface MBClassifier : NSObject

- (NSDictionary *)classify:(id)imageObj;
- (NSDictionary *)classify2:(id)imageObj;


//- (void)classify:(id)imageObj handler:(void(^)(NSString *))handler2;

- (void)classifyRequest:(id)imageObj handler:(void(^)(NSObject *))handler;

//- (void)classifyRequest2:(id)imageObj handler:(void(^)(NSString *))handler;

- (void)updateWithDeviceOrientation:(UIDeviceOrientation)deviceOrientation;

@end
