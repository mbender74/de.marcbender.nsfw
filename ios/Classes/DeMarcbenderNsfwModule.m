/**
 * ti.nsfw
 *
 * Created by Your Name
 * Copyright (c) 2019 Your Company. All rights reserved.
 */

#import "DeMarcbenderNsfwModule.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiBase.h"
#import "TiUtils.h"
#import "TiViewProxy.h"
#import "TiUIView.h"
#import "TiProxy.h"
#import "TiBlob.h"
#import "TiApp.h"
#import <AVFoundation/AVFoundation.h>
#import "MBClassifier.h"
#import "MAGNudityDetector.h"
#import "UIImage+MBResize.h"

@implementation DeMarcbenderNsfwModule

NSString *nsfwContent = @"";
NSString *nsfwClass = @"";
NSDictionary *dictionary;
NSObject *object;


#pragma mark Internal



// This is generated for your module, please do not change it
- (id)moduleGUID
{
  return @"312aa9b7-4f90-412e-9e38-29049b289a8b";
}

// This is generated for your module, please do not change it
- (NSString *)moduleId
{
  return @"de.marcbender.nsfw";
}

#pragma mark Lifecycle

- (void)startup
{
  // This method is called when the module is first loaded
  // You *must* call the superclass
  [super startup];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self->_classifier = [[MBClassifier alloc] init];
        DebugLog(@"[DEBUG] %@ loaded", self);

    });
    
}

#pragma Public APIs

- (NSDictionary *)checkImageClass:(id)args
{
        TiBlob *blob = [args objectAtIndex:0];
    
        NSObject *resultObject = nil;

        if ([blob isKindOfClass:[TiBlob class]]) {
            dictionary = [_classifier classify:blob];
        }
    return dictionary;
}

- (NSDictionary *)checkImageClass2:(id)args
{
        TiBlob *blob = [args objectAtIndex:0];
   
        NSObject *resultObject = nil;

        if ([blob isKindOfClass:[TiBlob class]]) {
            dictionary = [_classifier classify2:blob];
        }
    return dictionary;
}


- (void)checkNudity:(id)args{
    TiBlob *blob = [args objectAtIndex:0];
    if ([blob isKindOfClass:[TiBlob class]]) {
        
        UIImage *resizedImage = [blob image];
        
        [[MAGNudityDetector sharedInstance] analyzeImage:resizedImage
                                                 withCompletionBlock:^(NSDictionary *result) {
                                                     [self showResult:result];
                                                 }];
    }
}

- (void)showResult:(NSDictionary *)result {
    NSString *nudityResult = [NSString stringWithFormat:@"Potential nudity result: %@ (%f%%)",
    [result[kPotentialNudityResultKey] boolValue] ? @"YES" : @"NO",
    [result[kPotentialNudityPixelPercentageKey] floatValue]];
   
    
    NSMutableDictionary * event = [NSMutableDictionary dictionary];
    [event setValue:nudityResult
             forKey:@"nudityresult"];
    [self fireEvent:@"nudity" withObject:event];
}

- (void)checkImage:(id)args
{
    ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);

    TiBlob *blob = [args valueForKey:@"image"];

    NSObject *resultObject = nil;
    
        if ([blob isKindOfClass:[TiBlob class]]) {
            
            [_classifier classifyRequest:blob handler:^(NSObject *class) {

                object = class;
                
                NSMutableDictionary * event = [NSMutableDictionary dictionary];

                [event setValue:object
                         forKey:@"class"];
                [self fireEvent:@"classification" withObject:event];
            }];
        }
};

@end
