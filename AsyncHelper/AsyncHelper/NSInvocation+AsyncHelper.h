//
//  NSInvocation+AsyncHelper.h
//  AsyncHelper
//
//  Created by Walter Fettich on 30/04/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSInvocation (AsyncHelper)

+(NSInvocation*) createWithTarget:(id)target selector:(SEL)selector arguments:(NSArray*)arguments;

@end
