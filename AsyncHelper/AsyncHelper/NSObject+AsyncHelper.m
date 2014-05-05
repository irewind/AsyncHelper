//
//  NSObject+AsyncHelper.m
//  AsyncHelper
//
//  Created by Walter Fettich on 05/03/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "NSObject+AsyncHelper.h"
#import "NSInvocation+AsyncHelper.h"
#import "AHInvocationProtocol.h"
#import "AHSingleInvocation.h"
#import "AHInsistentInvocation.h"

@implementation NSObject (AsyncHelper)

-(AHInsistentInvocation*)ifFailed:(AHSingleInvocation*)invocation retryEverySeconds:(NSNumber*)sec andThen:(CompletionBlock)complete
{
    AHInsistentInvocation* inv = [[AHInsistentInvocation alloc] initWithInvocation:invocation retryEverySeconds:sec andCompletionBlock:complete];
    
    return inv;
}

-(AHInsistentInvocation*)ifFailed:(AHSingleInvocation*)invocation retryEverySeconds:(NSNumber*)sec forTimes:(NSNumber*)times andThen:(CompletionBlock)complete
{
    AHInsistentInvocation* inv = [[AHInsistentInvocation alloc] initWithInvocation:invocation retryEverySeconds:sec forTimes:times andCompletionBlock:complete];
    
    [inv invoke];
    
    return inv;
}

-(void)old_ifFailed:(NSInvocation*)invocation retryEverySeconds:(NSNumber*)sec forTimes:(NSNumber*)times andThen:(void(^)(BOOL))complete
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

-(AHParallelInvocation*)parallelize:(NSArray*)invocations andThen:(CompletionBlock)complete
{
    AHParallelInvocation* inv = [[AHParallelInvocation alloc] initWithInvocations:invocations andCompletionBlock:complete];
    
    return inv;
}

//-(void)old_parallelize:(NSArray*)invocations andThen:(void(^)(BOOL success))complete
//{
//    __block BOOL successful = YES;
//    __block int operationCount = 0;
//    
//    void (^finishedBlock)(BOOL success) =
//    ^(BOOL success)
//    {
//        --operationCount;
//        successful &= success;
//        
//        if (operationCount == 0)
//        {
//            if (complete)
//                complete (successful);
//        }
//    };
//    
//    for (NSInvocation* invocation in invocations)
//    {
//        operationCount++;
//        NSUInteger nrArgs = [[invocation methodSignature] numberOfArguments];
//        [invocation setArgument:&finishedBlock atIndex:nrArgs-1];
//    }
//    
//    for (NSInvocation* invocation in invocations)
//    {
//        [invocation invoke];
//    }
//}

-(AHQueueInvocation*)queue:(NSArray*)invocations andThen:(CompletionBlock)complete
{
    AHQueueInvocation* inv = [[AHQueueInvocation alloc] initWithInvocations:invocations andCompletionBlock:complete];
    
    return inv;
}

//-(void)old_queue:(NSArray*)invocations andThen:(void(^)(BOOL success))complete
//{
//    __block BOOL successful = YES;
//    __block int operationCount = 0;
//    
//    void (^nextBlock)(BOOL success) =
//    ^(BOOL success)
//    {
//        successful &= success;
//        
//        ++operationCount;
//        if (operationCount == invocations.count)
//        {
//            if (complete)
//                complete (successful);
//        }
//        else
//        {
//            [invocations[operationCount] invoke];
//        }
//    };
//    
//    for (NSInvocation* invocation in invocations)
//    {
//        NSUInteger nrArgs = [[invocation methodSignature] numberOfArguments];
//        [invocation setArgument:&nextBlock atIndex:nrArgs-1];
//    }
//    
//    [invocations[0] invoke];
//}

AHSingleInvocation* inv(id target,SEL selector)
{
    AHSingleInvocation* inv = [[AHSingleInvocation alloc] initWithTarget:target selector:selector arguments:@[]];
    return inv;
}

AHSingleInvocation* invf(id target,SEL selector,...)
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
    
    AHSingleInvocation* invocation = [[AHSingleInvocation alloc] initWithTarget:target selector:selector arguments:argArray];
    
    return invocation;
}

@end
