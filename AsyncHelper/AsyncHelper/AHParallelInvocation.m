//
//  AHParallelInvocation.m
//  AsyncHelper
//
//  Created by Walter Fettich on 30/04/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "AHParallelInvocation.h"
#import "AHSingleInvocation.h"

@interface AHParallelInvocation ()
@property (strong,nonatomic) NSMutableArray* runningInvocations;
@property (strong,nonatomic) NSMutableArray* invocations;
@end

@implementation AHParallelInvocation
@synthesize finishedBlock;
@synthesize isRunning;
@synthesize result;

-(instancetype) init
{
    if (self = [super init])
    {
        self.runningInvocations = [[NSMutableArray alloc] init];
        self.invocations = [[NSMutableArray alloc] init];
    }
    return self;
}

-(instancetype) initWithInvocations:(NSArray*)invocations andCompletionBlock:(CompletionBlock)complete
{
    if (self = [super init])
    {
        self.runningInvocations = [[NSMutableArray alloc] init];
        self.invocations = [invocations mutableCopy];
        
        [self setFinishedBlock:complete];
        
    }
    return self;
}

-(void)setFinishedBlock:(CompletionBlock)complete
{
    __block BOOL successful = YES;
    __block AHParallelInvocation* bself = self;
    finishedBlock = complete;
    
    CompletionBlock completionBlock =
    ^(BOOL success, id<AHInvocationProtocol> invocation)
    {
        if (NO == success)
        {
            int x = 0;
            x++;
        }
        
        successful &= success;
        [bself.runningInvocations removeObject:invocation];
        
        if (bself.runningInvocations.count == 0)
        {
            bself.isRunning = NO;
            if (bself.finishedBlock)
                bself.finishedBlock (successful,bself);
        }
    };

    for (AHSingleInvocation* invocation in self.invocations)
    {
        [invocation setFinishedBlock:completionBlock];
    }
}

-(void)addInvocation:(id<AHInvocationProtocol>)invocation
{
    [_invocations addObject:invocation];
    
    if (self.finishedBlock)
        [invocation setFinishedBlock:self.finishedBlock];
    
    if (self.isRunning)
    {
        [invocation invoke];
    }
}

-(void)invoke
{
    if (self.invocations.count > 0)
    {
        for (AHSingleInvocation* invocation in self.invocations)
        {
            [self.runningInvocations addObject:invocation];
            [invocation invoke];
        }
    }
    else if (self.finishedBlock)
    {
        self.finishedBlock (YES,self);
    }
}

-(NSArray*)invocations
{
    return _invocations;
}
@end
