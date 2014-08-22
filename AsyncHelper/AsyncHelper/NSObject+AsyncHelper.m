//
//  NSObject+AsyncHelper.m
//  AsyncHelper
//
//  Created by Walter Fettich on 05/03/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "NSObject+AsyncHelper.h"
#import "AHInvocationProtocol.h"
#import "AHSingleInvocation.h"
#import "AHInsistentInvocation.h"

@implementation NSObject (AsyncHelper)

-(AHInsistentInvocation*)ifFailed:(AHSingleInvocation*)invocation retryEverySeconds:(NSNumber*)sec
{
    return [self ifFailed:invocation retryEverySeconds:sec andThen:nil];
}

-(AHInsistentInvocation*)ifFailed:(AHSingleInvocation*)invocation retryEverySeconds:(NSNumber*)sec forTimes:(NSNumber*)times
{
    return [self ifFailed:invocation retryEverySeconds:sec forTimes:times andThen:nil];
}

-(AHInsistentInvocation*)ifFailed:(AHSingleInvocation*)invocation retryEverySeconds:(NSNumber*)sec andThen:(CompletionBlock)complete
{
    AHInsistentInvocation* inv = [[[AHInsistentInvocation alloc] initWithInvocation:invocation retryEverySeconds:sec andCompletionBlock:complete] autorelease];
    
    return inv;
}

-(AHInsistentInvocation*)ifFailed:(AHSingleInvocation*)invocation retryEverySeconds:(NSNumber*)sec forTimes:(NSNumber*)times andThen:(CompletionBlock)complete
{
    AHInsistentInvocation* inv = [[[AHInsistentInvocation alloc] initWithInvocation:invocation retryEverySeconds:sec forTimes:times andCompletionBlock:complete] autorelease];
    
//    [inv invoke];
    
    return inv;
}

-(AHParallelInvocation*)parallelize:(NSArray*)invocations andThen:(CompletionBlock)complete
{
    AHParallelInvocation* inv = [[[AHParallelInvocation alloc] initWithInvocations:invocations andCompletionBlock:complete] autorelease];
    
    return inv;
}

-(AHParallelInvocation*)parallelize:(NSArray*)invocations
{
    return [self parallelize:invocations andThen:nil];
}

-(AHQueueInvocation*)queue:(NSArray*)invocations andThen:(CompletionBlock)complete
{
    AHQueueInvocation* inv = [[[AHQueueInvocation alloc] initWithInvocations:invocations andCompletionBlock:complete] autorelease];
    
    return inv;
}

-(AHQueueInvocation*)queue:(NSArray*)invocations
{
    return [self queue:invocations andThen:nil];
}

AHSingleInvocation* inv(id target,SEL selector)
{
    AHSingleInvocation* inv = [[[AHSingleInvocation alloc] initWithTarget:target selector:selector arguments:@[]] autorelease];
    return inv;
}

AHSingleInvocation* invf(id target,SEL selector,...)
{    
    va_list arguments;
    va_start ( arguments, selector );
    
    NSMutableArray* argArray = [NSMutableArray array];
    
    id arg = nil;
    
    do
    {
        arg = va_arg(arguments, id);
        if (arg!=nil)
            [argArray addObject:arg];
    }
    while(arg!=nil);
    va_end ( arguments );
    
    AHSingleInvocation* invocation = [[[AHSingleInvocation alloc] initWithTarget:target selector:selector arguments:argArray] autorelease];
    
    return invocation;
}

@end
