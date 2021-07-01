//
//  FPOverviewProposals.hpp
//  Ownership
//
//  Created by Lukáš Foldýna on 03/08/2017.
//  Copyright © 2017 Oneprove. All rights reserved.
//

#ifndef Header_h
#define Header_h

struct PROPOSAL_POSITION {
    
    int x;
    int y;
    int width;
    int height;
    
};

struct ALL_PROPOSALS {
    
    int status;
    unsigned long num_of_proposals;
    PROPOSAL_POSITION *proposals;
    
};


typedef std::pair<double,int> doubleIntPair;

namespace FPOverviewProposals {

/* Fingerprint proposals for input overview image
 * @param image - Input color of grayscale overview image
 * @param real_width - real width of artwork in cm
 * @param real_height - real height of artwork in cm
 * @param num_of_proposals - maximal number of required prposals od fingerprint positions
 * @param wh_ratio - aspect ratio: width / height of camera output image
 * @return Output array of proposals
 */
ALL_PROPOSALS get_fp_proposals(cv::Mat image, float real_width, float real_height, int num_of_proposals, float wh_ratio=4.0/3.0);

/* Fingerprint proposals for input overview image
 * @param image - Input color of grayscale overview image
 * @param real_width - real width of artwork in cm
 * @param real_height - real height of artwork in cm
 * @param num_of_proposals - maximal number of required prposals od fingerprint positions
 * @param wh_ratio - aspect ratio: width / height of camera output image
 * @param border_offset_real_size - default 6.5cm
 * @return Output array of proposals
 */
ALL_PROPOSALS get_fp_proposals_border(cv::Mat image, float real_width, float real_height, int num_of_proposals, float border_offset_real_size=6.5, float wh_ratio=4.0/3.0);

}
#endif /* Header_h */
