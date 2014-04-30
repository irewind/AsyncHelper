//
//  NSInvocation+AsyncHelper.m
//  AsyncHelper
//
//  Created by Walter Fettich on 30/04/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "NSInvocation+AsyncHelper.h"

@implementation NSInvocation (AsyncHelper)

+(NSInvocation*) createWithTarget:(id)target selector:(SEL)selector arguments:(NSArray*)arguments
{
    NSMethodSignature* signature = [[target class] instanceMethodSignatureForSelector:selector];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setSelector:selector];
    [invocation setTarget:target];
    
    NSInteger index = 2;
    for (id arg in arguments)
    {
        [invocation setArgument:(__bridge void *)(arg) atIndex:index];
        index++;
    }
    
    [invocation retainArguments];
    
    return invocation;
}
@end
