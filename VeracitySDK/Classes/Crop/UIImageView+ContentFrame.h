//
//  UIImageView+ContentFrame.h
//  Ownership
//
//  Created by Marek Pohl on 17.01.17.
//  Copyright © 2018 Oneprove. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface UIImageView (UIImageView_ContentFrame)

@property (nonatomic, readonly) CGRect contentFrame;
@property (nonatomic, readonly) CGFloat contentScale;
@property (nonatomic, readonly) CGSize contentSize;

@end
