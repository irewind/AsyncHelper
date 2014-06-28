//
//  AHInsistentInvocation.m
//  AsyncHelper
//
//  Created by Walter Fettich on 05/05/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "AHInsistentInvocation.h"
#import "NSString+Utils.h"

#import "DDLog.h"

#ifdef DEMO_ASYNC
    static int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
    static int ddLogLevel = LOG_LEVEL_ERROR;
#endif

@interface AHInsistentInvocation ()
@property (strong,nonatomic) id<AHInvocationProtocol> invocation;
@property (copy, nonatomic) CompletionBlock internalFinishedBlock;
@property (strong,nonatomic) NSNumber* retryAfterSeconds;
@property (strong,nonatomic) NSNumber* timesToRetry;
@property (assign,nonatomic) int remainingRetries;
@end

@implementation AHInsistentInvocation
@synthesize isRunning;
@synthesize name;
@synthesize wasSuccessful;
@synthesize result;

-(instancetype) initWithInvocation:(id<AHInvocationProtocol>)invocation retryEverySeconds:(NSNumber*)sec  andCompletionBlock:(CompletionBlock)complete
{
    if (self = [super init])
    {
        self.invocation = invocation;
        self.retryAfterSeconds = sec;
        self.name = [NSString stringWithFormat:@"%lu_%@",(unsigned long)[self hash], NSStringFromClass([self class])];
        
        DDLogVerbose(@"alloc %@ %p",self.name,self);
        
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
        self.name = [NSString stringWithFormat:@"%lu_%@",(unsigned long)[self hash], NSStringFromClass([self class])];
        
        DDLogVerbose(@"alloc %@ %p",self.name,self);
        
        self.timesToRetry = times;
        
        [self setFinishedBlock:complete];
        
    }
    return self;
}

-(void)prepareInvocation
{
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
            bself.wasSuccessful = success;            
            bself.result = invocation.result;
            if (bself.internalFinishedBlock)
                bself.internalFinishedBlock(success,bself);
            [bself release];
        }
    };
    
    [self.invocation setFinishedBlock:completionBlock];
}

-(void)setFinishedBlock:(CompletionBlock)complete
{
    [self setInternalFinishedBlock:complete];
    
    [self prepareInvocation];
}

-(CompletionBlock)finishedBlock
{
    return self.internalFinishedBlock;
}

-(void)invoke
{
    DDLogVerbose(@"invoking %@",self.name);
    
    self.isRunning = YES;
    [self retain];
    [self.invocation invoke];
}

-(NSString*)description
{
    return AHNSStringF(@"%@: name:%@ retries:%@ interval:%@ wasSuccessful:%d result:%@ isRunning:%d",NSStringFromClass([self class]),self.name,self.timesToRetry,self.retryAfterSeconds,self.wasSuccessful,self.result,self.isRunning);
}

-(void)dealloc
{
    DDLogVerbose(@"dealloc %@ %p",self.name,self);
    
    self.invocation = nil;
    self.retryAfterSeconds = nil;
    self.timesToRetry = nil;
    self.name = nil;
    self.result = nil;
    self.internalFinishedBlock = nil;
    
    [super dealloc];
}

@end
