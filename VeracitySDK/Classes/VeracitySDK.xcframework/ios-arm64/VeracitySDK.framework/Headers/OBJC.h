//
//  ObjC.h
//  Ownership
//
//  Created by Marek Pohl on 12/02/2018.
//  Copyright © 2018 Oneprove. All rights reserved.
//
@import Foundation;


@interface ObjC : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end
