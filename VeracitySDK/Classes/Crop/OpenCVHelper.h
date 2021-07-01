//
//  OpenCVHelper.h
//  TakeFPTest
//
//  Created by Lukáš Tesař on 22.12.16.
//  Copyright © 2018 Lukáš Tesař. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, OpenCVFingerPrintResult) {
    OpenCVFingerPrintResultOK = 0,
    OpenCVFingerPrintResultEmpty = 1,
    OpenCVFingerPrintResultWrongSize = 2,
    OpenCVFingerPrintResultToSmall = 3,
    OpenCVFingerPrintResultNoMatches = 4,
    OpenCVFingerPrintResultBlurred = 5
};

typedef void (^OpenCVFingerPrintCallback)(OpenCVFingerPrintResult result, NSArray<NSValue *> * _Nonnull values);


@interface OpenCVHelper : NSObject

+ (BOOL) isImageBlurred:(nonnull UIImage *)image;

+ (nonnull NSDictionary<NSNumber *, NSValue *> *) detectEdges:(nonnull UIImageView *)imageView;
+ (nonnull NSArray<NSValue *> *) detectAllEdges:(nonnull UIImageView *)imageView;

+ (nonnull UIImage *) cropImageView:(nonnull UIImage *)adjustImage points:(nonnull NSArray *)points;

+ (void) getFingerPrintProposals:(nonnull UIImage *)image width:(CGFloat)width height:(CGFloat)height numOfProposals:(NSInteger)numOfProposals
                    isBorder:(BOOL)isBorder callback:(nonnull OpenCVFingerPrintCallback)callback;

@end
