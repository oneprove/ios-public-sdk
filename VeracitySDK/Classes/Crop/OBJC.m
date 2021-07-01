//
//  ObjC.m
//  Ownership
//
//  Created by Marek Pohl on 12/02/2018.
//  Copyright © 2018 Oneprove. All rights reserved.
//
#import "OBJC.h"


@implementation ObjC

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    } @catch (NSException *exception) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:exception.userInfo];
        userInfo[NSLocalizedDescriptionKey] = exception.reason;
        userInfo[NSUnderlyingErrorKey] = exception.name;
        
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:userInfo];
        return NO;
    }
}

@end
