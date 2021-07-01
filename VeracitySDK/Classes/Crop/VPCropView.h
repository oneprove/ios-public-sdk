//
//  VPCropView.h
//  Ownership
//
//  Created by Lukáš Tesař on 16.01.17.
//  Copyright © 2017 Oneprove. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Geometry.h"


NS_ASSUME_NONNULL_BEGIN

@interface VPCropView: UIView

@property (nonatomic, strong, readonly) NSArray<UIView *> *points;
@property (nonatomic, strong, readonly, nullable) UIView *activePoint;

/// Point A: Bottom Left
/// Point B: Bottom Right
/// Point C: Top Right
/// Point D: Top Left
@property (nonatomic, strong, readonly) UIView *pointA, *pointB, *pointC, *pointD;
@property (nonatomic, readonly) BOOL frameEdited;
@property (nonatomic, readonly) CGPoint touchInitPoint;

- (instancetype)init;
    
- (void)resetFrame: (CGFloat) width height: (CGFloat) height;
- (void)resetActivePoint;

- (NSArray<NSValue *> *)pointsPosition;
- (NSArray<NSValue *> *)pointsPositionWithScaleFactor:(CGFloat)scaleFactor;
- (CGPoint)positionForPointAtIndex:(NSInteger)index withScaleFactor:(CGFloat)scaleFactor;

- (void)bottomLeftCornerToPoint:(CGPoint)point;
- (void)bottomRightCornerToPoint:(CGPoint)point;
- (void)topRightCornerToPoint:(CGPoint)point;
- (void)topLeftCornerToPoint:(CGPoint)point;

- (void)checkAngle:(int)index;
- (void)findPointAtLocation:(CGPoint)location;
- (void)moveActivePointToLocation:(CGPoint)locationPoint onlyTwoCorners: (BOOL) twoCorners ;
- (void)touchBegun:(CGPoint)location;

@end

NS_ASSUME_NONNULL_END
