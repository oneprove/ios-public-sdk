//
//  FingerprintFinder.hpp
//  FingerprintFinder
//
//  Created by Petr Bobák on 22/11/2018.
//  Copyright © 2018 Oneprove. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The enemuration of supported return codes.
 */
typedef NS_ENUM(NSInteger, FingerprintFinderStatus) {
    FingerprintFinderStatusRegular = 0,
    FingerprintFinderStatusEmptyInput = 1,
    FingerprintFinderStatusNotFound = 2,
    FingerprintFinderStatusSmall = 3,
    FingerprintFinderStatusInsufficientScore = 4,
};

/**
 * The structure for FingerprintFinder result.
 */
@interface FingerprintFinderResult : NSObject
    /// Indicates the result status of fingerprint localization.
    @property FingerprintFinderStatus status;

    /// NSArray of CGRect fingerprints.
    @property(nonatomic, strong) NSArray<NSValue *> *fingerprints;
@end

typedef void (^FingerprintCompletion)(FingerprintFinderStatus status, CGRect fingerprint);
typedef void (^FingerprintWithImageCompletion)(FingerprintFinderStatus status, CGRect fingerprint, UIImage *image);
typedef void (^FingerprintCollectionCompletion)(FingerprintFinderStatus status, NSArray<NSValue *> *fingerprints);

@interface FingerprintFinder : NSObject

// MARK: Find just one fingerprint

/**
 * Asynchronously find single fingerprint in overview image.
 *
 * @param overview The overview image of the artwork.
 * @param overviewSize The real artwork size in centimeters.
 * @param completion The completion block called after execution. You shoud check FingerprintFinderStatus before further use of located fingerprint CGRect.
 *
 */
+ (void) findFingerprintIn:(UIImage *)overview withOverviewSize:(CGSize)overviewSize completion:(FingerprintCompletion)completion
    NS_SWIFT_NAME(find(overview:overviewSize:completion:));

/**
 * Synchronously find single fingerprint in overview image.
 *
 * @param overview The overview image of the artwork.
 * @param overviewSize The real artwork size in centimeters.
 *
 * @return The return structure with FingerprintFinderStatus and fingerprints NSArray of CGRect. You shoud check FingerprintFinderStatus before further use of located fingerprint CGRect.
 */
+ (FingerprintFinderResult *) findFingerprintIn:(UIImage *)overview withOverviewSize:(CGSize)overviewSize
    NS_SWIFT_NAME(find(overview:overviewSize:));

// MARK: Find one fingerprint of defined size

/**
 * Asynchronously find single fingerprint of defined size in overview image.
 *
 * @param overview The overview image of the artwork.
 * @param overviewSize The real artwork size in centimeters.
 * @param fingerprintSize The real fingerprint size in centimeters.
 * @param completion The completion block called after execution. You shoud check FingerprintFinderStatus before further use of located fingerprint CGRect.
 *
*/
+ (void) findFingerprintIn:(UIImage *)overview withOverviewSize:(CGSize)overviewSize fingerprintSize:(CGSize)fingerprintSize completion:(FingerprintCompletion)completion
    NS_SWIFT_NAME(find(overview:overviewSize:fingerprintSize:completion:));

/**
 * Synchronously find single fingerprint of defined size in overview image.
 *
 * @param overview The overview image of the artwork.
 * @param overviewSize The real artwork size in centimeters.
 * @param fingerprintSize The real fingerprint size in centimeters.
 *
 * @return The return structure with FingerprintFinderStatus and fingerprints NSArray of CGRect. You shoud check FingerprintFinderStatus before further use of located fingerprint CGRect.
*/
+ (FingerprintFinderResult *) findFingerprintIn:(UIImage *)overview withOverviewSize:(CGSize)overviewSize fingerprintSize:(CGSize)fingerprintSize
    NS_SWIFT_NAME(find(overview:overviewSize:fingerprintSize:));

// MARK: Find multiple fingerprints

/**
 * Asynchronously find single fingerprint in overview image.
 *
 * @param overview The overview image of the artwork.
 * @param overviewSize The real artwork size in centimeters.
 * @param quantity The number of fingerprints to locate.
 *
 * @param completion The completion block called after execution. You shoud check FingerprintFinderStatus before further use of located fingerprints in NSArray of CGRect.
 */
+ (void) findFingerprintIn:(UIImage *)overview withOverviewSize:(CGSize)overviewSize quantity:(NSInteger)quantity completion:(FingerprintCollectionCompletion)completion
    NS_SWIFT_NAME(find(overview:overviewSize:quantity:completion:));

/**
 * Synchronously find several fingerprint in overview image.
 *
 * @param overview The overview image of the artwork.
 * @param overviewSize The real artwork size in centimeters.
 * @param quantity The number of fingerprints to locate.
 *
 * @return The return structure with FingerprintFinderStatus and fingerprints NSArray of CGRect. You shoud check FingerprintFinderStatus before further use of located fingerprint CGRect.
 */
+ (FingerprintFinderResult *) findFingerprintIn:(UIImage *)overview withOverviewSize:(CGSize)overviewSize quantity:(NSInteger)quantity
    NS_SWIFT_NAME(find(overview:overviewSize:quantity:));


// MARK: Find multiple fingerprints of defined size

/**
 * Asynchronously find single fingerprint in overview image.
 *
 * @param overview The overview image of the artwork.
 * @param overviewSize The real artwork size in centimeters.
 * @param fingerprintSize The real fingerprint size in centimeters.
 * @param quantity The number of fingerprints to locate.
 *
 * @param completion The completion block called after execution. You shoud check FingerprintFinderStatus before further use of located fingerprints in NSArray of CGRect.
 */
+ (void) findFingerprintIn:(UIImage *)overview withOverviewSize:(CGSize)overviewSize fingerprintSize:(CGSize)fingerprintSize quantity:(NSInteger)quantity completion:(FingerprintCollectionCompletion)completion
    NS_SWIFT_NAME(find(overview:overviewSize:fingerprintSize:quantity:completion:));

/**
 * Synchronously find several fingerprint of defined size in overview image.
 *
 * @param overview The overview image of the artwork.
 * @param overviewSize The real artwork size in centimeters.
 * @param fingerprintSize The real fingerprint size in centimeters.
 * @param quantity The number of fingerprints to locate.
 *
 * @return The return structure with FingerprintFinderStatus and fingerprints NSArray of CGRect. You shoud check FingerprintFinderStatus before further use of located fingerprint CGRect.
*/
+ (FingerprintFinderResult *) findFingerprintIn:(UIImage *)overview withOverviewSize:(CGSize)overviewSize fingerprintSize:(CGSize)fingerprintSize quantity:(NSInteger)quantity
    NS_SWIFT_NAME(find(overview:overviewSize:fingerprintSize:quantity:));


// MARK: Check Size of Overview
/**
 * Check the overview size with requred minimum.
 *
 * @param overviewSize The real artwork size in centimeters.
 *
 * @return `FingerprintFinderStatus` with only possible value of `.ok` or `.small`.
 */
+ (FingerprintFinderStatus) overviewSizeMeetsMinimum:(CGSize)overviewSize
    NS_SWIFT_NAME(overviewMeetsMinimum(overviewSize:));

/**
 * Check the overview size with required minimum.
 *
 * @param overviewSize The real artwork size in centimeters.
 * @param fingerprintSize The real fingerprint size in centimeters.
 *
 * @return `FingerprintFinderStatus` with only possible value of `.ok` or `.small`.
 */
+ (FingerprintFinderStatus) overviewSizeMeetsMinimum:(CGSize)overviewSize fingerprintSize:(CGSize)fingerprintSize
    NS_SWIFT_NAME(overviewMeetsMinimum(overviewSize:fingerprintSize:));

// MARK: Crop Fingerprint of Small Overview

/**
 * Crop Fingerprint of small item
 *
 * @param fingerprint The overview image of the artwork.
 * @param overviewSize The real artwork size in centimeters.
 */

+ (UIImage *) croppedFingerprint:(UIImage *)fingerprint overviewSize:(CGSize)overviewSize
NS_SWIFT_NAME(cropped(fingerprint:overviewSize:));

// MARK: Crop Fingerprint of Small Overview

/**
 * Crop Fingerprint of small item
 *
 * @param fingerprint The overview image of the artwork.
 * @param fingerprintSize The real fingerprint size in centimeters.
 * @param overviewSize The real artwork size in centimeters.
 */
+ (UIImage *) croppedFingerprint:(UIImage *)fingerprint fingerprintSize:(CGSize)fingerprintSize overviewSize:(CGSize)overviewSize
    NS_SWIFT_NAME(cropped(fingerprint:fingerprintSize:overviewSize:));

// MARK: Rescale and draw for CGRect

/**
 * Rescale rectangle by given scale.
 *
 * @param rect The rectangle to scale.
 * @param scale The scale to rescale rectangle.
 *
 * @return The rescale rectangle.
 */
+ (CGRect)rescaledCGRect:(CGRect)rect withScale:(double)scale
    NS_SWIFT_NAME(rescaled(rect:scale:));

/**
 * Draw rectangle into given image.
 *
 * @param rect The rectangle to draw.
 * @param image The image to draw into.
 *
 * @return The modified image by rectangle drawing.
 */
+ (UIImage *)drawRectangle:(CGRect)rect onImage:(UIImage *)image
    NS_SWIFT_NAME(draw(rect:image:));

@end

NS_ASSUME_NONNULL_END
