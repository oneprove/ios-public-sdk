//
//  FPOverviewProposals.cpp
//  Ownership
//
//  Created by Kamil on 16/01/2017.
//  Copyright © 2017 Oneprove. All rights reserved.
//
#include <iostream>
#include <cstdlib>
#include "opencv2/core/core.hpp"
#include "opencv2/highgui/highgui.hpp"
#include <opencv2/imgproc/imgproc.hpp>
#include <math.h>
#include "FPOverviewProposals.hpp"

bool comp(const doubleIntPair& l, const doubleIntPair& r) {
    return l.first > r.first;
}

void check_swap_sizes(cv::Size image_size, float &real_width, float &real_height) {
    if ((real_width < real_height && image_size.width > image_size.height) || (real_width > real_height && image_size.width < image_size.height)) {
        float tmp_sz = real_width;
        real_width = real_height;
        real_height = tmp_sz;
    }
    
}

double get_ratio_score(cv::Mat roi, float roi_ratio=1.0/3.0) {
    
    cv::Mat vec = roi.clone().reshape(0,1);
    sort(vec,vec,CV_SORT_EVERY_ROW+CV_SORT_DESCENDING);
    
    int amount = (float)vec.cols * roi_ratio;
    double score = 0.0;
    
    for (int i=0; i < amount; i++) {
        score += vec.at<float>(i);
    }
    
    score = score / amount;
    
    return score;
}



void compute_real_interest_size(const float *credit_card_real_size, float wh_ratio, float *interest_area_real_size) {
    float wh_ratio_CC = credit_card_real_size[0] / credit_card_real_size[1];
    
    if (wh_ratio_CC > wh_ratio) {
        interest_area_real_size[0] = credit_card_real_size[0];
        interest_area_real_size[1] = credit_card_real_size[0] / wh_ratio;
    }
    else {
        interest_area_real_size[0] = credit_card_real_size[1] / wh_ratio;
        interest_area_real_size[1] = credit_card_real_size[1];
    }
    
}

cv::Mat create_mask(cv::Mat &energy, int *interest_area_pixel_size) {
    
    cv::Mat mask = cv::Mat::zeros(energy.size(),energy.type());
    for (int i=0; i < mask.size().height; i++) {
        if (i >= floor((float)interest_area_pixel_size[1] / 2.0) - 1 &&  i <= energy.size().height - floor((float)interest_area_pixel_size[1] / 2.0)-1) {
            for (int j=0; j < mask.size().width; j++) {
                if (j >= floor((float)interest_area_pixel_size[0] / 2.0) - 1 &&  j <= energy.size().width - floor((float)interest_area_pixel_size[0] / 2.0)-1) {
                    mask.at<double>(i,j) = 1;
                }
            }
        }
    }
    
    return mask;
}

void compute_energy(cv::Mat &image, double gb_sigma, int *interest_area_pixel_size, cv::Mat &energy, cv::Mat &cumul_energy) {
    
    GaussianBlur(image, image, cv::Size(3,3), gb_sigma, cv::BORDER_REPLICATE);
    
    if (image.channels() > 1) {
        cvtColor(image, image, CV_BGR2GRAY);
    }
    
    cv::Mat Gx, Gy;
    
    Sobel(image, Gx, CV_32F, 1, 0, 3, 1, 0, cv::BORDER_REPLICATE);
    Sobel(image, Gy, CV_32F, 0, 1, 3, 1, 0, cv::BORDER_REPLICATE);
    magnitude(Gx, Gy, energy);
    
    cv::Mat kernel_average = cv::Mat::ones(interest_area_pixel_size[1], interest_area_pixel_size[0], CV_32F) / (interest_area_pixel_size[0] * interest_area_pixel_size[1]);
    
    filter2D(energy,cumul_energy,CV_64F, kernel_average, cv::Point(-1,-1), 0, cv::BORDER_CONSTANT);
    
}

cv::Mat find_local_maxima(cv::Mat &energy, int *interest_area_pixel_size, cv::Mat mask) {
    
    cv::Mat kernel_dilate = cv::Mat::ones(round((float)interest_area_pixel_size[1]/10), round((float)interest_area_pixel_size[0]/10), CV_32F);
    
    cv::Mat dil_energy;
    
    dilate(energy,dil_energy,kernel_dilate);
    
    cv::Mat diff_mat = dil_energy - energy;
    
    cv::Mat bin_img_local_maxs(diff_mat == 0);
    
    bin_img_local_maxs = bin_img_local_maxs.mul(mask);
    
    cv::Mat local_maxs;
    
    findNonZero(bin_img_local_maxs,local_maxs);
    
    return local_maxs;
}

void centre_local_maxima(cv::Size image_size, int *interest_area_pixel_size, cv::Mat &local_maxs) {
    
    int interest_area_pixel_offset_x = floor((float)interest_area_pixel_size[0] / 2);
    int interest_area_pixel_offset_y = floor((float)interest_area_pixel_size[1] / 2);
    
    for (int i=0; i < local_maxs.rows; i++) {
        
        local_maxs.at<cv::Point>(i).x -= interest_area_pixel_offset_x;
        local_maxs.at<cv::Point>(i).y -= interest_area_pixel_offset_y;
    }
    
}

bool select_proposal_from_local_maxima(cv::Mat &energy, cv::Mat &local_maxs, std::vector<doubleIntPair> &local_maxs_energy, int *interest_area_pixel_size, int num_of_proposals, float minimal_score_thr, std::vector<cv::Point> &final_proposals) {
    
    for (int i=0; i < local_maxs.rows; i++) {
        //double i_sc = local_maxs_energy[i].first;
        int idx = local_maxs_energy[i].second;
        
        cv::Point curr_loc_max = local_maxs.at<cv::Point>(idx);
        
        local_maxs_energy[i].first = get_ratio_score(energy(cv::Rect(curr_loc_max.x, curr_loc_max.y, interest_area_pixel_size[0], interest_area_pixel_size[1])));
    }
    
    sort(local_maxs_energy.begin(), local_maxs_energy.end(), comp);
    
    final_proposals.clear();
    
    bool exist_proposal = false;
    
    for (int i=0; i < local_maxs.rows; i++) {
        
        //double i_sc = local_maxs_energy[i].first;
        int idx = local_maxs_energy[i].second;
        
        cv::Point curr_loc_max = local_maxs.at<cv::Point>(idx);
        
        bool ok = true;
        
        for (int j=0; j < final_proposals.size(); j++) {
            if (abs(curr_loc_max.x - final_proposals[j].x) <= interest_area_pixel_size[0] && abs(curr_loc_max.y - final_proposals[j].y) <= interest_area_pixel_size[1]) {
                
                ok = false;
                break;
            }
        }
        
        if (ok) {
            
            exist_proposal = true;
            
            double f_sc = get_ratio_score(energy(cv::Rect(curr_loc_max.x, curr_loc_max.y, interest_area_pixel_size[0], interest_area_pixel_size[1])));
            
            if (f_sc >= minimal_score_thr) {
                cv::Point tmp;
                
                tmp.x = curr_loc_max.x;
                tmp.y = curr_loc_max.y;
                final_proposals.push_back(tmp);
            }
            
        }
        
        if (final_proposals.size() >= num_of_proposals) {
            break;
        }
    }
    
    return exist_proposal;
    
}

bool find_proposals(cv::Mat &image, double gb_sigma, int num_of_proposals, float minimal_score_thr, int *interest_area_pixel_size, std::vector<cv::Point> &final_proposals) {
    
    cv::Mat energy, cumul_energy;
    
    compute_energy(image, gb_sigma, interest_area_pixel_size, energy, cumul_energy);
    
    cv::Mat mask = create_mask(cumul_energy, interest_area_pixel_size);
    
    cumul_energy = cumul_energy.mul(mask);
    
    cv::Mat local_maxs = find_local_maxima(cumul_energy, interest_area_pixel_size, mask == 1);
    
    std::vector<doubleIntPair> local_maxs_energy;
    
    for (int i=0; i < local_maxs.rows; i++) {
        local_maxs_energy.push_back(doubleIntPair(cumul_energy.at<double>(local_maxs.at<cv::Point>(i).y, local_maxs.at<cv::Point>(i).x),i));
        
    }
    
    centre_local_maxima(image.size(), interest_area_pixel_size, local_maxs);
    
    bool exist_proposal = select_proposal_from_local_maxima(energy, local_maxs, local_maxs_energy, interest_area_pixel_size, num_of_proposals, minimal_score_thr, final_proposals);
    
    return exist_proposal;
}

/* Fingerprint proposals for input overview image
 * @param image - Input color of grayscale overview image
 * @param real_width - real width of artwork in cm
 * @param real_height - real height of artwork in cm
 * @param num_of_proposals - maximal number of required prposals od fingerprint positions
 * @param wh_ratio - aspect ratio: width / height of camera output image
 * @return Output array of proposals
 */
ALL_PROPOSALS FPOverviewProposals::get_fp_proposals(cv::Mat image, float real_width, float real_height, int num_of_proposals, float wh_ratio) {
    
    const float gb_sigma = 4;
    const float border_offset_real_size = 1;
    //const int virtual_CC_width = 25;
    const int virtual_CC_width = 40;
    //const double minimal_score_thr = 17; // pod 40 moze mat problem so zarovnanim
    const double minimal_score_thr = 8.5; // pod 40 moze mat problem so zarovnanim
    
    const float credit_card_real_size[2] = {53.98 / 10, 85.6 / 10}; // credit card size in cm
    
    int border_offset_pixel_size;
    float interest_area_real_size[2];
    
    ALL_PROPOSALS output_proposals;
    output_proposals.num_of_proposals = 0;
    output_proposals.proposals = NULL;
    output_proposals.status = 0;
    
    if(image.empty()) {
        output_proposals.status = 1;
        return output_proposals;
    }
    
    check_swap_sizes(image.size(), real_width, real_height);
    
    compute_real_interest_size(credit_card_real_size, wh_ratio, interest_area_real_size);
    
    if (real_width < interest_area_real_size[0] + border_offset_real_size*2 || real_height < interest_area_real_size[1] + border_offset_real_size*2) {
        output_proposals.status = 3;
        return output_proposals;
    }
    
    int interest_area_pixel_size[2] = {virtual_CC_width, (int)round((float)virtual_CC_width*interest_area_real_size[1]/interest_area_real_size[0])};
    
    float curr_scale = (real_width * (float) virtual_CC_width / interest_area_real_size[0]) / (float) image.size().width;
    
    if (curr_scale != 1) {
        resize(image, image, cv::Size(), curr_scale, curr_scale, cv::INTER_CUBIC);
    }
    
    border_offset_pixel_size = round(border_offset_real_size * ((float)interest_area_pixel_size[0] / interest_area_real_size[0]));
    
    image = image(cv::Rect(border_offset_pixel_size, border_offset_pixel_size,image.size().width - 2*border_offset_pixel_size, image.size().height - 2*border_offset_pixel_size));
    
    std::vector<cv::Point> final_proposals;
    
    bool exist_proposal = find_proposals(image, gb_sigma, num_of_proposals, minimal_score_thr, interest_area_pixel_size, final_proposals);
    
    output_proposals.proposals = new PROPOSAL_POSITION[final_proposals.size()];
    output_proposals.num_of_proposals = final_proposals.size();
    
    if (exist_proposal && final_proposals.size() == 0) {
        output_proposals.status = 4;
    } else if (final_proposals.size() == 0) {
        output_proposals.status = 2;
    }
    
    for (int i=0; i < final_proposals.size(); i++) {
        output_proposals.proposals[i].width = round((float)interest_area_pixel_size[0] / curr_scale);
        output_proposals.proposals[i].height = round((float)interest_area_pixel_size[1] / curr_scale);
        output_proposals.proposals[i].x = round((float)(border_offset_pixel_size + final_proposals[i].x) / curr_scale);
        output_proposals.proposals[i].y = round((float)(border_offset_pixel_size + final_proposals[i].y) / curr_scale);
    }
    
    return output_proposals;
}


ALL_PROPOSALS FPOverviewProposals::get_fp_proposals_border(cv::Mat image, float real_width, float real_height, int num_of_proposals, float border_offset_real_size, float wh_ratio) {
    
    const float credit_card_real_size[2] = {53.98 / 10, 85.6 / 10}; // credit card size in cm
    
    int border_offset_pixel_size;
    float interest_area_real_size[2];
    
    ALL_PROPOSALS output_proposals;
    output_proposals.num_of_proposals = 0;
    output_proposals.proposals = NULL;
    output_proposals.status = 0;
    
    if(image.empty()) {
        output_proposals.status = 1;
        return output_proposals;
    }
    
    check_swap_sizes(image.size(), real_width, real_height);
    
    compute_real_interest_size(credit_card_real_size, wh_ratio, interest_area_real_size);
    
    if (real_width < interest_area_real_size[0] + border_offset_real_size*2 || real_height < interest_area_real_size[1] + border_offset_real_size*2) {
        output_proposals.status = 3;
        return output_proposals;
    }
    
    float cm_pixel_size =  (float) image.size().width / (float) real_width;
    
    int interest_area_pixel_size[2] = {static_cast<int>(round(cm_pixel_size * interest_area_real_size[0])), static_cast<int>(round(cm_pixel_size * interest_area_real_size[1]))};
    border_offset_pixel_size = round(cm_pixel_size * border_offset_real_size);
    
    output_proposals.proposals = new PROPOSAL_POSITION[1];
    output_proposals.num_of_proposals = 1;
    
    output_proposals.proposals[0].width = interest_area_pixel_size[0];
    output_proposals.proposals[0].height = interest_area_pixel_size[1];
    output_proposals.proposals[0].x = image.size().width - border_offset_pixel_size - interest_area_pixel_size[0];
    output_proposals.proposals[0].y = image.size().height - border_offset_pixel_size - interest_area_pixel_size[1];
    
    return output_proposals;
}
