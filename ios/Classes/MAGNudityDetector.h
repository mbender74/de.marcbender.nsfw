//
//  MAGNudityDetector.h
//  Utility class for identifiyng potentially pornographic images
//
//  Created by Andrew Petrus on 27.10.14.
//  Copyright (c) 2014 Andrew Petrus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSString *const kPotentialNudityPixelPercentageKey = @"potentialNudityPixelPercentageKey";
static NSString *const kPotentialNudityResultKey = @"potentialNudityResultKey";

@interface MAGNudityDetector : NSObject

@property (nonatomic) CGFloat thresholdLimit;

+ (instancetype)sharedInstance;
- (void)analyzeImage:(UIImage *)image withCompletionBlock:(void(^)(NSDictionary *result))completionBlock;

@end
