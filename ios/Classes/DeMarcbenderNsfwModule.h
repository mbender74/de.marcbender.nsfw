/**
 * ti.nsfw
 *
 * Created by Your Name
 * Copyright (c) 2019 Your Company. All rights reserved.
 */

#import "TiModule.h"
#import "MBClassifier.h"
#import "MAGNudityDetector.h"

@interface DeMarcbenderNsfwModule : TiModule {

}

@property (nonatomic) dispatch_queue_t sessionQueue;
//
@property (nonatomic) dispatch_queue_t processingQueue;


@property (nonatomic) MBClassifier *classifier;


@end
