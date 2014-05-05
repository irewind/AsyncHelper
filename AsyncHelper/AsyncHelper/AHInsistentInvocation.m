//
//  AHInsistentInvocation.m
//  AsyncHelper
//
//  Created by Walter Fettich on 05/05/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "AHInsistentInvocation.h"

@interface AHInsistentInvocation ()
@property (strong,nonatomic) id<AHInvocationProtocol> invocation;
@property (assign,nonatomic) NSNumber* retryAfterSeconds;
@property (assign,nonatomic) NSNumber* timesToRetry;
@property (assign,nonatomic) int remainingRetries;
@end

@implementation AHInsistentInvocation
@synthesize isRunning;
@synthesize finishedBlock;

-(instancetype) initWithInvocation:(id<AHInvocationProtocol>)invocation retryEverySeconds:(NSNumber*)sec  andCompletionBlock:(CompletionBlock)complete
{
    if (self = [super init])
    {
        self.invocation = invocation;
        self.retryAfterSeconds = sec;
        
        [self setFinishedBlock:complete];
    }
    return self;
}

-(instancetype) initWithInvocation:(id<AHInvocationProtocol>)invocation retryEverySeconds:(NSNumber*)sec forTimes:(NSNumber*)times andCompletionBlock:(CompletionBlock)complete;
{
    if (self = [super init])
    {
        self.invocation = invocation;
        self.retryAfterSeconds = sec;
        self.timesToRetry = times;
        
        [self setFinishedBlock:complete];
        
    }
    return self;
}


-(void)setFinishedBlock:(CompletionBlock)finishedBlock
{
    if (self.timesToRetry != nil)
        self.remainingRetries = self.timesToRetry.intValue;
    
//    NSUInteger nrArgs = [[self.invocation methodSignature] numberOfArguments];
//    [invocation setArgument:&block1 atIndex:nrArgs-1];

    CompletionBlock completionBlock =
    ^(BOOL success, id<AHInvocationProtocol> invocation)
    {
        if (
            (self.timesToRetry != nil && self.remainingRetries!=0) //this order is important here
            && success == NO
            )
        {
            double delayInSeconds = self.retryAfterSeconds.doubleValue;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(),
               ^(void)
               {
                   if (self.timesToRetry != nil && self.remainingRetries!=0)
                       self.remainingRetries--;
                   
                   [self.invocation invoke];
               });
        }
        else
        {
            self.isRunning = NO;
            if (self.finishedBlock)
                self.finishedBlock(success,self);
        }
    };
    
    [self.invocation setFinishedBlock:completionBlock];
}

-(void)invoke
{
    self.isRunning = YES;
    [self.invocation invoke];
}
@end
