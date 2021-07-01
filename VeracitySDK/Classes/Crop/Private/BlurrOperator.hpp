//
//  BlurrOperator.hpp
//  Ownership
//
//  Created by Lukáš Foldýna on 03/08/2017.
//  Copyright © 2017 Oneprove. All rights reserved.
//

#ifndef Header_h
#define Header_h

#include <iostream>
#include "opencv2/core/core.hpp"
#include "opencv2/highgui/highgui.hpp"
#include <opencv2/imgproc/imgproc.hpp>


/* Sharpness measurement operator. Bigger output value means that input image is more sharper than image with smaller value
 * @param image - input image
 * @return sharpness measurement score
 */
double variance_of_laplacian(cv::Mat image);

#endif /* Header_h */
