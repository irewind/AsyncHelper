//
//  AHInsistentInvocation.m
//  AsyncHelper
//
//  Created by Walter Fettich on 05/05/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "AHInsistentInvocation.h"
#import "NSString+Utils.h"

@interface AHInsistentInvocation ()
@property (strong,nonatomic) id<AHInvocationProtocol> invocation;
@property (strong,nonatomic) NSNumber* retryAfterSeconds;
@property (strong,nonatomic) NSNumber* timesToRetry;
@property (assign,nonatomic) int remainingRetries;
@end

@implementation AHInsistentInvocation
@synthesize isRunning;
@synthesize finishedBlock;
@synthesize name;
@synthesize result;

-(instancetype) initWithInvocation:(id<AHInvocationProtocol>)invocation retryEverySeconds:(NSNumber*)sec  andCompletionBlock:(CompletionBlock)complete
{
    if (self = [super init])
    {
        self.invocation = invocation;
        self.retryAfterSeconds = sec;
        self.name = AHNSStringF(@"%d_%@(%@)",[self hash], NSStringFromClass([self class]), invocation.name);
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
        self.name = AHNSStringF(@"%d_%@",[self hash], NSStringFromClass([self class]));
        self.timesToRetry = times;
        
        [self setFinishedBlock:complete];
        
    }
    return self;
}


-(void)setFinishedBlock:(CompletionBlock)complete
{
    finishedBlock = [complete copy];
    
    if (self.timesToRetry != nil)
        self.remainingRetries = self.timesToRetry.intValue;
    
    __block AHInsistentInvocation* bself = self;
    
    CompletionBlock completionBlock =
    ^(BOOL success, id<AHInvocationProtocol> invocation)
    {
        if (
            success == NO && (bself.timesToRetry == nil || (bself.timesToRetry != nil && bself.remainingRetries>0))
            )
        {
            double delayInSeconds = bself.retryAfterSeconds.doubleValue;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(),
               ^(void)
               {
                   if (bself.timesToRetry != nil && bself.remainingRetries!=0)
                       bself.remainingRetries--;
                   
                   [bself.invocation invoke];
               });
        }
        else
        {
            bself.isRunning = NO;
            bself.result = invocation.result;
            if (bself.finishedBlock)
                bself.finishedBlock(success,bself);
        }
    };
    
    [self.invocation setFinishedBlock:completionBlock];
}

-(void)invoke
{
    self.isRunning = YES;
    [self.invocation invoke];
}

-(NSString*)description
{
    return AHNSStringF(@"%@: name:%@ retries:%@ interval:%@ result:%@ isRunning:%d",NSStringFromClass([self class]),self.name,self.timesToRetry,self.retryAfterSeconds,self.result,self.isRunning);
}
@end
