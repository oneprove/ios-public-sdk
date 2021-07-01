//
//  OpenCVHelper.m
//  TakeFPTest
//
//  Created by Lukáš Tesař on 22.12.16.
//  Copyright © 2018 Lukáš Tesař. All rights reserved.
//



#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#include <opencv2/imgcodecs.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/videostab/deblurring.hpp>
#include <iostream>
#include <cstdlib>
#include <math.h>
#include <vector>
#import "FPOverviewProposals.hpp"
#import "BlurrOperator.hpp"
#pragma clang pop

#import "OpenCVHelper.h"
#import "UIImage+Orientation.h"
#import "UIImageView+ContentFrame.h"

@implementation OpenCVHelper

+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                     // Width
                                        cvMat.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * cvMat.elemSize(),                           // Bits per pixel
                                        cvMat.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    data = nil;
    return image;
}

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols,rows;
    if (image.imageOrientation == UIImageOrientationLeft || image.imageOrientation == UIImageOrientationRight) {
        cols = image.size.height;
        rows = image.size.width;
    } else {
        cols = image.size.width;
        rows = image.size.height;
        
    }
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    cv::Mat cvMatTest;
    cv::transpose(cvMat, cvMatTest);
    
    if (image.imageOrientation == UIImageOrientationLeft || image.imageOrientation == UIImageOrientationRight) {
        // skip
    } else{
        return cvMat;
        
    }
    cvMat.release();
    
    cv::flip(cvMatTest, cvMatTest, 1);
    return cvMatTest;
}

+ (cv::Mat)cvMatFromAdjustedUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    return cvMat;
}

+ (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    cv::Mat cvMat = [self cvMatFromUIImage:image];
    cv::Mat grayMat;
    if ( cvMat.channels() == 1 ) {
        grayMat = cvMat;
    } else {
        grayMat = cv :: Mat( cvMat.rows,cvMat.cols, CV_8UC1 );
        cv::cvtColor( cvMat, grayMat, cv::COLOR_BGR2GRAY );
    }
    cvMat.release();
    return grayMat;
}

+ (cv::Mat)cvMatGrayFromAdjustedUIImage:(UIImage *)image
{
    cv::Mat cvMat = [self cvMatFromAdjustedUIImage:image];
    cv::Mat grayMat;
    if ( cvMat.channels() == 1 ) {
        grayMat = cvMat;
    } else {
        grayMat = cv :: Mat( cvMat.rows,cvMat.cols, CV_8UC1 );
        cv::cvtColor( cvMat, grayMat, cv::COLOR_BGR2GRAY );
    }
    cvMat.release();
    return grayMat;
}

+ (cv::Mat)fft2:(cv::Mat) gray_image
{
    cv::Mat planes[] = {cv::Mat_<float>(gray_image), cv::Mat::zeros(gray_image.size(), CV_32F)};
    
    cv::Mat complex_spec;
    merge(planes, 2, complex_spec);
    
    dft(complex_spec, complex_spec);
    
    return complex_spec;
}

+ (cv::Mat)get_fft2_magnitude:(cv::Mat)spec
{
    cv::Mat planes[2];
    split(spec, planes);
    magnitude(planes[0], planes[1], planes[0]);
    cv::Mat magnitude = planes[0];
    
    return magnitude;
}

+ (cv::Mat)fftshift:(cv::Mat)spec
{
    spec = spec(cv::Rect(0, 0, spec.cols & -2, spec.rows & -2));
    
    int cx = spec.cols/2;
    int cy = spec.rows/2;
    
    cv::Mat q0(spec, cv::Rect(0, 0, cx, cy));
    cv::Mat q1(spec, cv::Rect(cx, 0, cx, cy));
    cv::Mat q2(spec, cv::Rect(0, cy, cx, cy));
    cv::Mat q3(spec, cv::Rect(cx, cy, cx, cy));
    
    cv::Mat tmp;
    q0.copyTo(tmp);
    q3.copyTo(q0);
    tmp.copyTo(q3);
    
    q1.copyTo(tmp);
    q2.copyTo(q1);
    tmp.copyTo(q2);
    
    return spec;
}

/* Blurred image test optimized for fingerprints.
 * @param image - Input color of grayscale image
 * @return If image is3 blurred, this function returns 1. If it is ok, this function returns 0. -1 is returned for error.
 */
+ (BOOL) isCvImageBlurred:(cv::Mat)image
{
    if (image.empty()) {
        return false;
    }
    
    float blur_threshold = 0.0000455;
    float gb_sigma = 1;
    float perc_of_high = 0.05;

    if (image.channels() > 1) {
        cvtColor(image, image, CV_BGR2GRAY);
    }
    
    cv::Mat orig_spec = [OpenCVHelper fft2:image];
    cv::Mat orig_mag = [OpenCVHelper get_fft2_magnitude: orig_spec];
    orig_mag = [OpenCVHelper fftshift:orig_mag];
    
    cv::Mat filt_image = cv::Mat(image.size(),image.type());
    
    GaussianBlur(image, filt_image, cv::Size(5,5), gb_sigma, cv::BORDER_REPLICATE);
    
    cv::Mat filt_spec = [OpenCVHelper fft2:filt_image];
    cv::Mat filt_mag = [OpenCVHelper get_fft2_magnitude:filt_spec];
    filt_mag = [OpenCVHelper fftshift:filt_mag];
    
    cv::Size spec_size = filt_mag.size();
    
    int mask_half_width = round(spec_size.width / (2 + perc_of_high * 2));
    int mask_half_height = round(spec_size.height / (2 + perc_of_high * 2));
    
    cv::Rect supp_area = cv::Rect(spec_size.width / 2 - mask_half_width, spec_size.height / 2 - mask_half_height, mask_half_width * 2 + 1, mask_half_height * 2 + 1);
    
    cv::Mat mask = cv::Mat::ones(filt_mag.size(),CV_8U) * 255;
    cv::Mat roi(mask, supp_area);
    roi = cv::Scalar(0);
    
    cv::Scalar orig_m, orig_stdv;
    cv::Scalar filt_m, filt_stdv;
    
    meanStdDev(orig_mag,orig_m,orig_stdv,mask);
    meanStdDev(filt_mag,filt_m,filt_stdv,mask);
    
    if (filt_m[0] / orig_m[0] > blur_threshold) {
        return 1;
    }
    return 0;  
}

double angle( cv::Point pt1, cv::Point pt2, cv::Point pt0 ) {
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

// http://stackoverflow.com/questions/8667818/opencv-c-obj-c-detecting-a-sheet-of-paper-square-detection
void find_squares(cv::Mat& image, std::vector<std::vector<cv::Point>>&squares)
{
    // blur will enhance edge detection
    cv::Mat blurred(image);
    
    GaussianBlur(image, blurred, cvSize(11,11), 0); // change from median blur to gaussian for more accuracy of square detection
    
    cv::Mat gray0(blurred.size(), CV_8U), gray;
    std::vector<std::vector<cv::Point> > contours;
    
    // find squares in every color plane of the image
    for (int c = 0; c < 3; c++) {
        int ch[] = {c, 0};
        mixChannels(&blurred, 1, &gray0, 1, ch, 1);
        
        // try several threshold levels
        const int threshold_level = 2;
        for (int l = 0; l < threshold_level; l++) {
            // Use Canny instead of zero threshold level!
            // Canny helps to catch squares with gradient shading
            if (l == 0) {
                Canny(gray0, gray, 10, 20, 3); //
                
                // Dilate helps to remove potential holes between edge segments
                dilate(gray, gray, cv::Mat(), cv::Point(-1,-1));
            } else {
                gray = gray0 >= (l+1) * 255 / threshold_level;
            }
            
            // Find contours and store them in a list
            findContours(gray, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
            
            // Test contours
            std::vector<cv::Point> approx;
            for (size_t i = 0; i < contours.size(); i++) {
                // approximate contour with accuracy proportional
                // to the contour perimeter
                approxPolyDP(cv::Mat(contours[i]), approx, arcLength(cv::Mat(contours[i]), true)*0.02, true);
                
                // Note: absolute value of an area is used because
                // area may be positive or negative - in accordance with the
                // contour orientation
                if (approx.size() == 4 &&
                    fabs(contourArea(cv::Mat(approx))) > 1000 &&
                    isContourConvex(cv::Mat(approx))) {
                    double maxCosine = 0;
                    
                    for (int j = 2; j < 5; j++) {
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                    }
                    
                    if (maxCosine < 0.3)
                        squares.push_back(approx);
                }
            }
        }
    }
}

void find_largest_square(const std::vector<std::vector<cv::Point> >& squares, std::vector<cv::Point>& biggest_square, CGSize contentSize)
{
    if (!squares.size()) {
        // no squares detected
        return;
    }
    int max_width = 0;
    int max_height = 0;
    int min_width = contentSize.width * 0.5;
    int min_height = contentSize.height * 0.5;
    NSUInteger max_square_idx = 0;
    
    for (size_t i = 0; i < squares.size(); i++) {
        // Convert a set of 4 unordered Points into a meaningful cv::Rect structure.
        cv::Rect rectangle = boundingRect(cv::Mat(squares[i]));
        
//        std::cout << "find_largest_square: #" << i << " rectangle x:" << rectangle.x << " y:" << rectangle.y << " " << rectangle.width << "x" << rectangle.height << std::endl;
        
        // Store the index position of the biggest square found
        if ((rectangle.width >= max_width) && (rectangle.height >= max_height)) {
            //But only if it's bigger than 50% of content width & height
            if (rectangle.width > min_width && rectangle.height > min_height) {
                max_width = rectangle.width;
                max_height = rectangle.height;
                max_square_idx = i;
            }
        }
    }
    if (max_width > 0 && max_height > 0) {
        biggest_square = squares[max_square_idx];
    }
}

cv::Mat debugSquares(std::vector<std::vector<cv::Point> > squares, cv::Mat image)
{
    for (size_t i = 0; i< squares.size(); i++ ) {
        // draw contour
        cv::drawContours(image, squares, (int)i, cv::Scalar(255,0,0), 1, 8, std::vector<cv::Vec4i>(), 0, cv::Point());
        
        // draw bounding rect
        cv::Rect rect = boundingRect(cv::Mat(squares[i]));
        cv::rectangle(image, rect.tl(), rect.br(), cv::Scalar(0,255,0), 2, 8, 0);
        
        // draw rotated rect
        cv::RotatedRect minRect = minAreaRect(cv::Mat(squares[i]));
        cv::Point2f rect_points[4];
        minRect.points( rect_points );
        for ( int j = 0; j < 4; j++ ) {
            cv::line( image, rect_points[j], rect_points[(j+1)%4], cv::Scalar(0,0,255), 1, 8 ); // blue
        }
    }
    
    return image;
}

+ (BOOL) isImageBlurred:(UIImage *)image
{
    cv::Mat original = [OpenCVHelper cvMatFromUIImage:image];
    BOOL blurred = [OpenCVHelper isCvImageBlurred:original];
    original.release();
    return blurred;
}

+ (std::vector<std::vector<cv::Point> >) findSquaresInImage:(cv::Mat)_image
{
    std::vector<std::vector<cv::Point> > squares;
    cv::Mat pyr, timg, gray0(_image.size(), CV_8U), gray;
    int thresh = 50, N = 11;
    cv::pyrDown(_image, pyr, cv::Size(_image.cols/2, _image.rows/2));
    cv::pyrUp(pyr, timg, _image.size());
    std::vector<std::vector<cv::Point>> contours;
    for (int c = 0; c < 3; c++) {
        int ch[] = {c, 0};
        mixChannels(&timg, 1, &gray0, 1, ch, 1);
        for (int l = 0; l < N; l++) {
            if( l == 0 ) {
                cv::Canny(gray0, gray, 0, thresh, 5);
                cv::dilate(gray, gray, cv::Mat(), cv::Point(-1,-1));
            } else {
                gray = gray0 >= (l+1)*255/N;
            }
            cv::findContours(gray, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
            std::vector<cv::Point> approx;
            for( size_t i = 0; i < contours.size(); i++ ) {
                cv::approxPolyDP(cv::Mat(contours[i]), approx, arcLength(cv::Mat(contours[i]), true)*0.02, true);
                if( approx.size() == 4 && fabs(contourArea(cv::Mat(approx))) > 1000 && cv::isContourConvex(cv::Mat(approx))) {
                    double maxCosine = 0;
                    
                    for( int j = 2; j < 5; j++ ) {
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                    }
                    
                    if( maxCosine < 0.3 ) {
                        squares.push_back(approx);
                    }
                }
            }
        }
    }
    return squares;
}
    
+ (NSArray<NSValue *> *) detectAllEdges:(UIImageView *)imageView
{
    cv::Mat original = [OpenCVHelper cvMatFromUIImage:imageView.image];
    CGSize targetSize = [imageView contentSize];
    cv::resize(original, original, cvSize(targetSize.width, targetSize.height));
 
    NSMutableArray<NSValue *> *points = [NSMutableArray array];
    std::vector<std::vector<cv::Point>> squares = [self findSquaresInImage:original];
    for (size_t i = 0; i < squares.size(); i++) {
        std::vector<cv::Point> square = squares[i];
        for (size_t e = 0; e < square.size(); e++) {
            cv::Point point = square[e];
            [points addObject:[NSValue valueWithCGPoint:CGPointMake(point.x, point.y)]];
        }
    }
    
    original.release();
    return [points copy];
}

+ (NSDictionary<NSNumber *, NSValue *> *) detectEdges:(UIImageView *)imageView
{
    cv::Mat original = [OpenCVHelper cvMatFromUIImage:imageView.image];
    CGSize targetSize = [imageView contentSize];
    cv::resize(original, original, cvSize(targetSize.width, targetSize.height));
    
    std::vector<std::vector<cv::Point>>squares;
    std::vector<cv::Point> largest_square;
    
    find_squares(original, squares);
    find_largest_square(squares, largest_square, imageView.contentSize);
    
    NSMutableDictionary<NSNumber *, NSValue *> *sortedPoints = [[NSMutableDictionary alloc] init];
    if (largest_square.size() == 4) {
        NSMutableArray<NSDictionary *> *points = [NSMutableArray array];

        for (int i = 0; i < 4; i++) {
            NSDictionary *dict = @{@"point": [NSValue valueWithCGPoint:CGPointMake(largest_square[i].x, largest_square[i].y)],
                                   @"value": @(largest_square[i].x + largest_square[i].y)};
            [points addObject:dict];
        }
        
        int min = [[points valueForKeyPath:@"@min.value"] intValue];
        int max = [[points valueForKeyPath:@"@max.value"] intValue];
        
        int minIndex = 0;
        int maxIndex = 0;
        
        int missingIndexOne = 0;
        int missingIndexTwo = 0;
        
        for (int i = 0; i < 4; i++) {
            NSDictionary *dict = points[i];
            
            if ([dict[@"value"] intValue] == min) {
                sortedPoints[@0] = dict[@"point"];
                minIndex = i;
                continue;
            }
            
            if ([dict[@"value"] intValue] == max) {
                sortedPoints[@2] = dict[@"point"];
                maxIndex = i;
                continue;
            }
            
            missingIndexOne = i;
        }
        
        for (int i = 0; i < 4; i++) {
            if (missingIndexOne != i && minIndex != i && maxIndex != i) {
                missingIndexTwo = i;
            }
        }
        
        
        if (largest_square[missingIndexOne].x < largest_square[missingIndexTwo].x) {
            //2nd Point Found
            sortedPoints[@3] = points[missingIndexOne][@"point"];
            sortedPoints[@1] = points[missingIndexTwo][@"point"];
        } else {
            //4rd Point Found
            sortedPoints[@1] = points[missingIndexOne][@"point"];
            sortedPoints[@3] = points[missingIndexTwo][@"point"];
        }
    }
    
    original.release();
    return [sortedPoints copy];
}

+ (UIImage *) cropImageView:(UIImage *)adjustImage points:(NSArray *)points {
    CGPoint ptBottomLeft = [points[3] CGPointValue];
    CGPoint ptBottomRight = [points[2] CGPointValue];
    CGPoint ptTopRight = [points[1] CGPointValue];
    CGPoint ptTopLeft = [points[0] CGPointValue];
    //TODO: - ABS can be quicker⚠️
    CGFloat w1 = sqrt(pow(ptBottomRight.x - ptBottomLeft.x , 2) + pow(ptBottomRight.x - ptBottomLeft.x, 2));
    CGFloat w2 = sqrt(pow(ptTopRight.x - ptTopLeft.x , 2) + pow(ptTopRight.x - ptTopLeft.x, 2));
    
    CGFloat h1 = sqrt(pow(ptTopRight.y - ptBottomRight.y , 2) + pow(ptTopRight.y - ptBottomRight.y, 2));
    CGFloat h2 = sqrt(pow(ptTopLeft.y - ptBottomLeft.y , 2) + pow(ptTopLeft.y - ptBottomLeft.y, 2));
    
    CGFloat widthDiff = w1 - w2;
    CGFloat heightDiff = h1 - h2;
    CGFloat maxWidth;
    CGFloat maxHeight;
    
    if (widthDiff > 40) {
        maxWidth = MIN(w1, w2);
    }else {
        maxWidth = MAX(w1, w2);
    }
    
    if (heightDiff > 40) {
        maxHeight = MIN(h1, h2);
    }else {
        maxHeight = MAX(h1, h2);
    }
    
    cv::Point2f src[4], dst[4];
    src[0].x = ptTopLeft.x;
    src[0].y = ptTopLeft.y;
    src[1].x = ptTopRight.x;
    src[1].y = ptTopRight.y;
    src[2].x = ptBottomRight.x;
    src[2].y = ptBottomRight.y;
    src[3].x = ptBottomLeft.x;
    src[3].y = ptBottomLeft.y;
    
    dst[0].x = 0;
    dst[0].y = 0;
    dst[1].x = maxWidth - 1;
    dst[1].y = 0;
    dst[2].x = maxWidth - 1;
    dst[2].y = maxHeight - 1;
    dst[3].x = 0;
    dst[3].y = maxHeight - 1;
    
    cv::Mat undistorted = cv::Mat( cvSize(maxWidth,maxHeight), CV_8UC4);
    cv::Mat original = [OpenCVHelper cvMatFromUIImage:adjustImage];
    cv::warpPerspective(original, undistorted, cv::getPerspectiveTransform(src, dst), cvSize(maxWidth, maxHeight));
    
    UIImage *croppedImage = [OpenCVHelper UIImageFromCVMat:undistorted];
    
    original.release();
    undistorted.release();
    return croppedImage;
}

+ (void) getFingerPrintProposals:(UIImage *)image width:(CGFloat)width height:(CGFloat)height numOfProposals:(NSInteger)numOfProposals isBorder:(BOOL)isBorder callback:(OpenCVFingerPrintCallback)callback
{
    cv::Mat imageMat = [OpenCVHelper cvMatFromUIImage:image];
    ALL_PROPOSALS proposalsStruct;
    if (isBorder) {
        proposalsStruct = FPOverviewProposals::get_fp_proposals_border(imageMat, width, height, (int)numOfProposals);
    } else {
        proposalsStruct = FPOverviewProposals::get_fp_proposals(imageMat, width, height, (int)numOfProposals);
    }
    
    NSMutableArray<NSValue *> *proposals = [[NSMutableArray alloc] init];
    for (unsigned long i = 0; i < proposalsStruct.num_of_proposals; i++) {
        PROPOSAL_POSITION position = proposalsStruct.proposals[i];
        CGRect rect = CGRectMake(position.x, position.y, position.width, position.height);
        [proposals addObject:[NSValue valueWithCGRect:rect]];
    }
    imageMat.release();
    callback((OpenCVFingerPrintResult)proposalsStruct.status, [proposals copy]);
}

@end
