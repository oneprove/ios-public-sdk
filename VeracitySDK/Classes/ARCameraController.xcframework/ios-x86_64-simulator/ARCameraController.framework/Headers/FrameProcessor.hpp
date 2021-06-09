//
//  FrameProcessor.hpp
//  ARNavigator
//
//  Created by Petr Bobák on 13.10.17.
//  Copyright © 2017 Oneprove. All rights reserved.
//

#ifdef __cplusplus
#include "Navigator.hpp"
#include "ImageProcessing.hpp"
#include "Visualizator.hpp"
#endif

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, NavigatorStatus) {
    NavigatorStatusUNSUCCESS = INT_MAX,
    NavigatorStatusSUCCESS = 0,
    NavigatorStatusNO_GOOD_FEATURES_FOUND = 1,
    NavigatorStatusNOT_ENOUGH_TRACKING_CORRESPONDENCES = 2,
    NavigatorStatusNOT_ENOUGH_HOMOGRAPHY_INLIERS = 3,
    NavigatorStatusNO_INITIAL_HOMOGRAPHY_FOUND = 4,
    NavigatorStatusNO_INITIAL_GOOD_FEATURES_FOUND = 5,
    NavigatorStatusNOT_ENOUGH_OVERVIEW_DESCRIPTORS = 6,
    NavigatorStatusDETAIL_IN_POSITION = 7,
    NavigatorStatusUNSATISFACTORY_NUMBER_OF_OVERVIEW_DESCRIPTORS = 8,
    NavigatorStatusDETAIL_TOO_CLOSE = 9
};

typedef NS_ENUM(NSInteger, DescriptorStatus) {
    DescriptorStatusNonoptimal,
    DescriptorStatusSuboptimal,
    DescriptorStatusOptimal,
};

typedef struct {
    double overviewDownscale;
    double initialInliers;
    NSInteger numOfGoodMatches;
    NSInteger ransacMaxIterations;
} NavigatorSettings;

@interface FrameProcessor : NSObject

@property (nonatomic, weak) id delegate;

@property (nonatomic, assign) BOOL keypointVisible;
@property (nonatomic, assign) BOOL safezoneVisible;
@property (nonatomic, assign) BOOL overviewVisible;

@property (readonly) CGFloat cropFactor;

@property (readonly) NavigatorSettings navigatorSettings;

- (instancetype)
    initWithNavigatorSettings:(NavigatorSettings)navSettings
    overviewImage:(UIImage *)overview fingerprintRect:(CGRect)rect status:(DescriptorStatus *)status
    NS_SWIFT_NAME(init(navigatorSettings:overview:fingerprintRect:status:));

- (void)resetProcessing
    NS_SWIFT_NAME(reset());

- (NSDictionary *)processImage:(UIImage *)image
    NS_SWIFT_NAME(process(image:));

- (void)processVideo:(NSString *)path withImageView:(UIImageView *)imageView
    NS_SWIFT_NAME(process(video:imageView:));

@end

