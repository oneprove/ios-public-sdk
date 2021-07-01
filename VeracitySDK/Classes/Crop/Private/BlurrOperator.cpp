//
//  BlurrOperator.cpp
//  Ownership
//
//  Created by Kamil on 16/01/2017.
//  Copyright © 2017 Oneprove. All rights reserved.
//

#include "BlurrOperator.hpp"


/* Sharpness measurement operator. Bigger output value means that input image is more sharper than image with smaller value
 * @param image - input image
 * @return sharpness measurement score
 */
double variance_of_laplacian(cv::Mat image) {
    if(image.empty()) {
        return -1;
    }
    
    if (image.channels() > 1) {
        cvtColor(image, image, CV_BGR2GRAY);
    }
    
    cv::Mat filtered;
    
    Laplacian(image,filtered,CV_64F);
  
    cv::Scalar filt_m, filt_stdv;
    
    meanStdDev(abs(filtered),filt_m,filt_stdv);
    
    return filt_stdv[0] * filt_stdv[0];
    
}
