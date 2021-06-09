//
//  UIImage+Orientation.h
//  Ownership
//
//  Created by Marek Pohl on 17.01.17.
//  Copyright © 2018 Oneprove. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Orientation)

@property (nonatomic, readonly, strong) UIImage *fixOrientation;
+ (UIImage *) renderImage:(NSString *)imagName;
+ (UIImage *) scaleAndRotateImage:(UIImage *)image;

@end
