//
//  VPCropView.m
//  Ownership
//
//  Created by Lukáš Tesař on 16.01.17.
//  Copyright © 2017 Oneprove. All rights reserved.
//

#import "VPCropView.h"

#define kCropButtonSize 40.0
#define kCropHalfButtonSize (kCropButtonSize / 2)
#define kCropLineWidth 4.0


@implementation VPCropView
{
    NSInteger _currentIndex, _previousIndex;
    int _k;
}

- (instancetype) init
{
    self = [super init];

    if (self) {
        [self _setup];
    }
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self) {
        [self _setup];
    }
    return self;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self _setup];
    }
    return self;
}

- (void) _setup
{
    NSMutableArray *points = [[NSMutableArray alloc] init];
    _pointA = [self _createPointView];
    _pointB = [self _createPointView];
    _pointC = [self _createPointView];
    _pointD = [self _createPointView];

    [points addObject:_pointD];
    [points addObject:_pointC];
    [points addObject:_pointB];
    [points addObject:_pointA];

    _points = [points copy];

    [self setClipsToBounds:NO];
    [self setBackgroundColor:[UIColor colorWithRed:36 / 255 green:32 / 255 blue:33 / 255 alpha:0.6]];
    [self setUserInteractionEnabled:YES];
    [self setContentMode:UIViewContentModeRedraw];
}

- (UIView *) _createPointView {
    UIView *pointView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, kCropButtonSize, kCropButtonSize)];
    [pointView setBackgroundColor:[UIColor clearColor]];
    ///Creates rounded corner view
    UIView *innerPointView = [[UIView alloc] initWithFrame:CGRectInset(pointView.bounds, kCropHalfButtonSize / 2, kCropHalfButtonSize / 2)];
    innerPointView.layer.cornerRadius = kCropHalfButtonSize / 2;
    [pointView addSubview:innerPointView];
    [self addSubview:pointView];
    return pointView;
}

- (void)updatePointView:(UIView *)pointView frame:(CGRect)frame {
    CGRect superFrame = [self bounds];
    CGRect updatedFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    pointView.frame = updatedFrame;
    pointView.center = CGPointMake(MAX(0, MIN(frame.origin.x, superFrame.size.width - kCropLineWidth)),
                                   MAX(0, MIN(frame.origin.y, superFrame.size.height - kCropLineWidth)));
}

- (void)moveActivePointToLocation:(CGPoint)locationPoint onlyTwoCorners: (BOOL) twoCorners {
    if (_activePoint){
        [self updatePointView:_activePoint frame:CGRectMake(locationPoint.x, locationPoint.y, kCropButtonSize, kCropButtonSize)];
    }
    
    if (twoCorners) {
        [self applyMovingPointForTwoCorners];
    }
    
    [self setNeedsDisplay];
}


/// Moving Point A (Bottom Left), or Point C (Top Right)
/// => Auto move Point B (Bottom Right), and Point D (Top Left)
- (void) applyMovingPointForTwoCorners {
    if (_activePoint == _pointA || _activePoint == _pointC) {
        // Point B
        CGPoint pointB = CGPointMake(_pointC.frame.origin.x + kCropHalfButtonSize,
                                     _pointA.frame.origin.y + kCropHalfButtonSize);
        [self updatePointView:_pointB frame:CGRectMake(pointB.x, pointB.y, kCropButtonSize, kCropButtonSize)];

        // Point D
        CGPoint pointD = CGPointMake(_pointA.frame.origin.x + kCropHalfButtonSize,
                                     _pointC.frame.origin.y + kCropHalfButtonSize);
        [self updatePointView:_pointD frame:CGRectMake(pointD.x, pointD.y, kCropButtonSize, kCropButtonSize)];
    }
}

- (NSArray<NSValue *> *)pointsPosition {
    return [self pointsPositionWithScaleFactor:1];
}

- (NSArray<NSValue *> *)pointsPositionWithScaleFactor:(CGFloat)scaleFactor {
    NSMutableArray<NSValue *> *points = [NSMutableArray array];
    for (NSInteger i = 0; i < _points.count; i++) {
        [points addObject:[NSValue valueWithCGPoint:[self positionForPointAtIndex:i withScaleFactor:scaleFactor]]];
    }
    return points;
}

- (CGPoint)positionForPointAtIndex:(NSInteger)index withScaleFactor:(CGFloat)scaleFactor {
    UIView *view = _points[index];
    if (view == nil) {
        return CGPointMake(0, 0);
    } else {
        CGFloat offset = kCropLineWidth / 2;
        return CGPointMake((view.center.x + offset) / scaleFactor, (view.center.y + offset) / scaleFactor);
    }
}

- (void)resetFrame: (CGFloat) width height: (CGFloat) height {
    [self setButtons:width andHeight:height];
    [self setNeedsDisplay];
}

- (void)resetActivePoint {
    if (_activePoint != nil) {
        _activePoint.subviews.firstObject.backgroundColor = [UIColor whiteColor];
        _activePoint = nil;
    }
}

- (UIImage *)squareButtonWithWidth:(CGFloat)width {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, width), NO, 0.0);
    UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return blank;
}

- (void)setButtons: (CGFloat) width andHeight: (CGFloat) height {
    CGRect superFrame = [self bounds];
    CGFloat offsetY = 50.0;
    CGFloat offsetX = 50.0;
    if (width != 0.0 && height != 0.0) {
        offsetY = (superFrame.size.height - height) / 2.0;
        offsetX = (superFrame.size.width - width) / 2.0;
    }
    
    CGPoint a = CGPointMake(0 + offsetX, superFrame.size.height - offsetY);
    CGPoint b = CGPointMake(superFrame.size.width - offsetX, superFrame.size.height - offsetY);
    CGPoint c = CGPointMake(superFrame.size.width - offsetX, 0 + offsetY);
    CGPoint d = CGPointMake(0 + offsetX, 0 + offsetY);
    
    [self updatePointView:_pointD frame:CGRectMake(d.x, d.y, kCropButtonSize, kCropButtonSize)];
    [self updatePointView:_pointC frame:CGRectMake(c.x, c.y, kCropButtonSize, kCropButtonSize)];
    [self updatePointView:_pointB frame:CGRectMake(b.x, b.y, kCropButtonSize, kCropButtonSize)];
    [self updatePointView:_pointA frame:CGRectMake(a.x, a.y, kCropButtonSize, kCropButtonSize)];
    
    [_pointA.subviews.firstObject setBackgroundColor:[UIColor whiteColor]];
    [_pointB.subviews.firstObject setBackgroundColor:[UIColor whiteColor]];
    [_pointC.subviews.firstObject setBackgroundColor:[UIColor whiteColor]];
    [_pointD.subviews.firstObject setBackgroundColor:[UIColor whiteColor]];
}

- (void)bottomLeftCornerToPoint:(CGPoint)point {
    [self updatePointView:_pointA frame:CGRectMake(point.x, point.y, kCropButtonSize, kCropButtonSize)];
    [self needsRedraw];
}

- (void)bottomRightCornerToPoint:(CGPoint)point {
    [self updatePointView:_pointB frame:CGRectMake(point.x, point.y, kCropButtonSize, kCropButtonSize)];
    [self needsRedraw];
}

- (void)topRightCornerToPoint:(CGPoint)point {
    [self updatePointView:_pointC frame:CGRectMake(point.x, point.y, kCropButtonSize, kCropButtonSize)];
    [self needsRedraw];
}

- (void)topLeftCornerToPoint:(CGPoint)point {
    [self updatePointView:_pointD frame:CGRectMake(point.x, point.y, kCropButtonSize, kCropButtonSize)];
    [self needsRedraw];
}

- (void)needsRedraw {
    [self setNeedsDisplay];
    [self drawRect:self.bounds];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return;
    }
    CGContextSetRGBFillColor(context, 0.0f, 0.0f, 0.0f, 0.0f);
    if ([self checkForNeighbouringPoints:_currentIndex] >= 0) {
        _frameEdited = YES;
        CGContextSetRGBStrokeColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
    } else{
        _frameEdited = NO;
        CGContextSetRGBStrokeColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
    }
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextSetLineWidth(context, kCropLineWidth);
    
    CGRect boundingRect = CGContextGetClipBoundingBox(context);
    CGContextAddRect(context, boundingRect);
    CGContextFillRect(context, boundingRect);
    
    CGMutablePathRef pathRef = CGPathCreateMutable();
    
    CGFloat plusOrigin = kCropHalfButtonSize + kCropLineWidth / 2;
    CGPathMoveToPoint(pathRef, NULL, _pointA.frame.origin.x + plusOrigin, _pointA.frame.origin.y + plusOrigin);
    CGPathAddLineToPoint(pathRef, NULL, _pointB.frame.origin.x + plusOrigin, _pointB.frame.origin.y + plusOrigin);
    CGPathAddLineToPoint(pathRef, NULL, _pointC.frame.origin.x + plusOrigin, _pointC.frame.origin.y + plusOrigin);
    CGPathAddLineToPoint(pathRef, NULL, _pointD.frame.origin.x + plusOrigin, _pointD.frame.origin.y + plusOrigin);
    
    CGPathCloseSubpath(pathRef);
    CGContextAddPath(context, pathRef);
    CGContextStrokePath(context);
    
    CGContextSetBlendMode(context, kCGBlendModeClear);
    
    CGContextAddPath(context, pathRef);
    CGContextFillPath(context);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    
    CGPathRelease(pathRef);
}

//MARK: - Condition For Valid Rect
- (double)checkForNeighbouringPoints:(NSInteger)index {
    NSArray<NSValue *> *points = [self pointsPosition];
    CGPoint p1, p2, p3;
    
    for (NSInteger i = 0; i < points.count; i++) {
        switch (i) {
            case 0: {
                p1 = [points[0] CGPointValue];
                p2 = [points[1] CGPointValue];
                p3 = [points[3] CGPointValue];
            } break;
            case 1: {
                p1 = [points[1] CGPointValue];
                p2 = [points[2] CGPointValue];
                p3 = [points[0] CGPointValue];
            } break;
            case 2: {
                p1 = [points[2] CGPointValue];
                p2 = [points[3] CGPointValue];
                p3 = [points[1] CGPointValue];
            } break;
            default: {
                p1 = [points[3] CGPointValue];
                p2 = [points[0] CGPointValue];
                p3 = [points[2] CGPointValue];
            } break;
        }
        CGPoint ab = CGPointMake(p2.x - p1.x, p2.y - p1.y);
        CGPoint cb = CGPointMake(p2.x - p3.x, p2.y - p3.y);
        float dot = (ab.x * cb.x + ab.y * cb.y); // dot product
        float cross = (ab.x * cb.y - ab.y * cb.x); // cross product
        float alpha = atan2(cross, dot);
        
        if ((-1 * (float)floor(alpha * 180. / 3.14 + 0.5)) < 0) {
            return -1 * (float)floor(alpha * 180. / 3.14 + 0.5);
        }
    }
    return 0;
}

- (void)swapTwoPoints {
    [self updatePointView:_points[_currentIndex] frame:CGRectMake(_touchInitPoint.x, _touchInitPoint.y, kCropButtonSize, kCropButtonSize)];
    
    //FIXME
    /*if (_k == 2) {
        if ([self checkForHorizontalIntersection]) {
            CGRect temp0 = [_points[0] frame];
            CGRect temp3 = [_points[3] frame];
            
            [self updatePointView:_points[0] frame:CGRectMake(temp3.origin.x, temp3.origin.y,
                                                              kCropButtonSize, kCropButtonSize)];
            [self updatePointView:_points[3] frame:CGRectMake(temp0.origin.x, temp0.origin.y,
                                                              kCropButtonSize, kCropButtonSize)];
            
            [self checkAngle:0];
            [self setNeedsDisplay];
        }
        if ([self checkForVerticalIntersection]) {
            CGRect temp0 = [_points[2] frame];
            CGRect temp3 = [_points[3] frame];
            
            [self updatePointView:_points[2] frame:CGRectMake(temp3.origin.x, temp3.origin.y,
                                                              kCropButtonSize, kCropButtonSize)];
            [self updatePointView:_points[3] frame:CGRectMake(temp0.origin.x, temp0.origin.y,
                                                              kCropButtonSize, kCropButtonSize)];
            
            [self checkAngle:0];
            [self setNeedsDisplay];
        }
    } else{
        CGRect temp2 = [_points[2] frame];
        CGRect temp0 = [_points[0] frame];
        
        [self updatePointView:_points[0] frame:CGRectMake(temp2.origin.x + kCropHalfButtonSize, temp2.origin.y + kCropHalfButtonSize,
                                                          kCropButtonSize, kCropButtonSize)];
        [self updatePointView:_points[2] frame:CGRectMake(temp0.origin.x + kCropHalfButtonSize, temp0.origin.y + kCropHalfButtonSize,
                                                          kCropButtonSize, kCropButtonSize)];
        
        [self setNeedsDisplay];
    }*/
}

- (void)checkAngle:(int)index {
    NSArray<NSValue *> *points = [self pointsPosition];
    CGPoint p1, p2, p3;
    _k = 0;
    
    for (int i = 0; i < points.count; i++) {
        switch (i) {
            case 0: {
                p1 = [points[0] CGPointValue];
                p2 = [points[1] CGPointValue];
                p3 = [points[3] CGPointValue];
            } break;
            case 1: {
                p1 = [points[1] CGPointValue];
                p2 = [points[2] CGPointValue];
                p3 = [points[0] CGPointValue];
                
            } break;
            case 2: {
                p1 = [points[2] CGPointValue];
                p2 = [points[3] CGPointValue];
                p3 = [points[1] CGPointValue];
            } break;
            default: {
                p1 = [points[3] CGPointValue];
                p2 = [points[0] CGPointValue];
                p3 = [points[2] CGPointValue];
            } break;
        }
        CGPoint ab = CGPointMake(p2.x - p1.x, p2.y - p1.y);
        CGPoint cb = CGPointMake(p2.x - p3.x, p2.y - p3.y);
        float dot = (ab.x * cb.x + ab.y * cb.y); // dot product
        float cross = (ab.x * cb.y - ab.y * cb.x); // cross product
        float alpha = atan2(cross, dot);
        
        if ((-1 * (float)floor(alpha * 180. / 3.14 + 0.5)) < 0) {
            _k++;
        }
    }
   
    if (_k >= 2) {
        [self swapTwoPoints];
    }
    _previousIndex = _currentIndex;
}

- (BOOL)checkForHorizontalIntersection {
    CGLine line1 = CGLineMake(CGPointMake([_points[0] frame].origin.x, [_points[0] frame].origin.y),
                              CGPointMake([_points[1] frame].origin.x, [_points[1] frame].origin.y));
    
    CGLine line2 = CGLineMake(CGPointMake([_points[2] frame].origin.x, [_points[2] frame].origin.y),
                              CGPointMake([_points[3] frame].origin.x, [_points[3] frame].origin.y));
    
    CGPoint temp=CGLinesIntersectAtPoint(line1, line2);
    if (temp.x != INFINITY && temp.y != INFINITY) {
        return YES;
    }
    return NO;
}

- (BOOL)checkForVerticalIntersection {
    CGLine line3 = CGLineMake(CGPointMake([_points[0] frame].origin.x, [_points[0] frame].origin.y),
                              CGPointMake([_points[3] frame].origin.x, [_points[3] frame].origin.y));
    
    CGLine line4 = CGLineMake(CGPointMake([_points[2] frame].origin.x, [_points[2] frame].origin.y),
                              CGPointMake([_points[1] frame].origin.x, [_points[1] frame].origin.y));
    
    CGPoint temp=CGLinesIntersectAtPoint(line3, line4);
    if (temp.x != INFINITY && temp.y != INFINITY) {
        return YES;
    }
    return NO;
}

//MARK: - Support methods
- (CGFloat)_distanceBetweenFirstPoint:(CGPoint)first lastPoint:(CGPoint)last {
    CGFloat xDist = (last.x - first.x);
    if (xDist < 0)
        xDist = xDist * -1;
    CGFloat yDist = (last.y - first.y);
    if (yDist < 0)
        yDist = yDist * -1;
    return sqrt((xDist * xDist) + (yDist * yDist));
}

- (void)findPointAtLocation:(CGPoint)location {
    _activePoint.subviews.firstObject.backgroundColor = [UIColor whiteColor];
    _activePoint = nil;
    CGFloat smallestDistance = kCropButtonSize;
    NSInteger i = 0;
    for (UIView *point in _points) {
        CGRect extentedFrame = CGRectInset(point.frame, -kCropButtonSize, -kCropButtonSize);
        
        if (CGRectContainsPoint(extentedFrame, location)) {
            CGFloat distanceToThis = [self _distanceBetweenFirstPoint:point.center lastPoint:location];
          
            if (distanceToThis < smallestDistance) {
                _activePoint = point;
                smallestDistance = distanceToThis;
                _currentIndex = i;
            }
        }
        i++;
    }
    _activePoint.subviews.firstObject.backgroundColor = [UIColor clearColor];
}

- (void)touchBegun:(CGPoint)location {
    _touchInitPoint = location;
}

@end
