//
//  NSObject+AsyncHelper.m
//  AsyncHelper
//
//  Created by Walter Fettich on 05/03/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "NSObject+AsyncHelper.h"
#import "NSInvocation+AsyncHelper.h"

@implementation NSObject (AsyncHelper)

-(void)ifFailed:(NSInvocation*)invocation retryEverySeconds:(NSNumber*)sec andThen:(void(^)(BOOL))complete
{
    [self ifFailed:invocation retryEverySeconds:sec forTimes:@(-1) andThen:complete];
}

-(void)ifFailed:(NSInvocation*)invocation retryEverySeconds:(NSNumber*)sec forTimes:(NSNumber*)times andThen:(void(^)(BOOL))complete
{
   __block int count = times.intValue;
    
    void (^__block block1) (BOOL) =
    ^(BOOL success)
    {
        if (NO == success && count > 0 && count!=-1)
        {
            double delayInSeconds = sec.doubleValue;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(),
               ^(void)
               {
                   if (count!=-1) count--;
                   [invocation invoke];
               });
        }
        else
        {
            if (complete)
                complete(success);
        }
    };
    
    NSUInteger nrArgs = [[invocation methodSignature] numberOfArguments];
    
    [invocation setArgument:&block1 atIndex:nrArgs-1];
    [invocation invoke];
}

-(NSInvocation*)parallelize:(NSArray*)invocations andThen:(void(^)(BOOL success))complete
{
    __block BOOL successful = YES;
    void (^finishedBlock)(BOOL success, NSInvocation* invocation) =
    ^(BOOL success, NSInvocation* invocation)
    {
        successful &= success;
        [runningInvocations removeObject:invocation];
        
        if (runningInvocations.count == 0)
        {
            if (complete)
                complete (successful);
        }
    };
    
    return invf(self, @selector(doParallelize:andThen:),invocations,finishedBlock);
}

-(void)doParallelize:(NSArray*)invocations andThen:(void(^)(BOOL success,NSInvocation* invocation))complete
{
    NSMutableArray* runningInvocations = [[NSMutableArray alloc] init];
    
    __block BOOL successful = YES;
    
    void (^finishedBlock)(BOOL success, NSInvocation* invocation) =
    ^(BOOL success, NSInvocation* invocation)
    {
        successful &= success;
        [runningInvocations removeObject:invocation];
        
        if (runningInvocations.count == 0)
        {
            if (complete)
                complete (successful);
        }
    };
    
    for (NSInvocation* invocation in invocations)
    {
        NSUInteger nrArgs = [[invocation methodSignature] numberOfArguments];
        [invocation setArgument:&finishedBlock atIndex:nrArgs-1];
    }
    
    for (NSInvocation* invocation in invocations)
    {
        [runningInvocations addObject:invocation];
        [invocation invoke];
    }
}


-(void)old_parallelize:(NSArray*)invocations andThen:(void(^)(BOOL success))complete
{
    __block BOOL successful = YES;
    __block int operationCount = 0;
    
    void (^finishedBlock)(BOOL success) =
    ^(BOOL success)
    {
        --operationCount;
        successful &= success;
        
        if (operationCount == 0)
        {
            if (complete)
                complete (successful);
        }
    };
    
    for (NSInvocation* invocation in invocations)
    {
        operationCount++;
        NSUInteger nrArgs = [[invocation methodSignature] numberOfArguments];
        [invocation setArgument:&finishedBlock atIndex:nrArgs-1];
    }
    
    for (NSInvocation* invocation in invocations)
    {
        [invocation invoke];
    }
}

-(void)queue:(NSArray*)invocations andThen:(void(^)(BOOL success))complete
{
    __block BOOL successful = YES;
    __block int index = 0;
    
    NSOperationQueue* queue = [[NSOperationQueue alloc] init];
    [queue setSuspended:YES];
    [queue setMaxConcurrentOperationCount:1];
    
    void (^nextBlock)(BOOL success) =
    ^(BOOL success)
    {
        successful &= success;
        
        if (invocations.count == index)
        {
            if (complete)
                complete (successful);
        }
        else
        {
            NSInvocationOperation* op = [[NSInvocationOperation alloc] initWithInvocation:invocations[index++]];
            [queue addOperation:op];
        }
    };
    
    for (NSInvocation* invocation in invocations)
    {
        NSUInteger nrArgs = [[invocation methodSignature] numberOfArguments];
        [invocation setArgument:&nextBlock atIndex:nrArgs-1];
    }
    
    NSInvocationOperation* op = [[NSInvocationOperation alloc] initWithInvocation:invocations[index++]];
    
    [queue addOperation:op];

    [queue setSuspended:NO];
}

-(void)old_queue:(NSArray*)invocations andThen:(void(^)(BOOL success))complete
{
    __block BOOL successful = YES;
    __block int operationCount = 0;
    
    void (^nextBlock)(BOOL success) =
    ^(BOOL success)
    {
        successful &= success;
        
        ++operationCount;
        if (operationCount == invocations.count)
        {
            if (complete)
                complete (successful);
        }
        else
        {
            [invocations[operationCount] invoke];
        }
    };
    
    for (NSInvocation* invocation in invocations)
    {
        NSUInteger nrArgs = [[invocation methodSignature] numberOfArguments];
        [invocation setArgument:&nextBlock atIndex:nrArgs-1];
    }
    
    [invocations[0] invoke];
}

NSInvocation* inv(id target,SEL selector)
{
    NSInvocation* inv = [NSInvocation createWithTarget:target selector:selector arguments:@[]];
    
    return inv;
}

NSInvocation* invf(id target,SEL selector,...)
{    
    va_list arguments;
    va_start ( arguments, selector );
    
    NSMutableArray* argArray = [[NSMutableArray alloc] init];
    
    id arg = nil;
    while((arg = va_arg(arguments, id))!=0)
    {
        [argArray addObject:arg];
    }
    va_end ( arguments );
    
    NSInvocation* invocation = [NSInvocation createWithTarget:target selector:selector arguments:argArray];
    
    return invocation;
}

@end
