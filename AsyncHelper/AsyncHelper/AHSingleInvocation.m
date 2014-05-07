//
//  AHParallelInvocation.m
//  AsyncHelper
//
//  Created by Walter Fettich on 30/04/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "AHSingleInvocation.h"

@interface AHSingleInvocation ()
    @property(strong,nonatomic) NSInvocation* invocation;
@end

@implementation AHSingleInvocation
@synthesize finishedBlock;
@synthesize isRunning;

-(instancetype) init
{
    if (self = [super init])
    {
    }
    return self;
}

-(instancetype) initWithNSInvocation:(NSInvocation*)invocation;
{
    if (self = [super init])
    {
        self.invocation = invocation;
    }
    return self;
}

-(instancetype) initWithTarget:(id)target selector:(SEL)selector arguments:(NSArray*)arguments
{
    if (self = [super init])
    {
        NSMethodSignature* signature = [[target class] instanceMethodSignatureForSelector:selector];
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:selector];
        [invocation setTarget:target];
        
        NSInteger index = 2;
        for (NSObject* arg in arguments)
        {
            [invocation setArgument:(void*)(&arg) atIndex:index];
            index++;
        }
        [invocation retainArguments];
        
        self.invocation = invocation;
    }
    return self;
}

-(void)setFinishedBlock:(CompletionBlock)complete
{
    finishedBlock = complete;
    __block AHSingleInvocation* bself = self;
    void (^completionBlock) (BOOL success) =
    ^(BOOL success)
    {
        bself.isRunning = NO;
        if (bself.finishedBlock)
        bself.finishedBlock(success,bself);
    };
    
    NSUInteger nrArgs = [[self.invocation methodSignature] numberOfArguments];
    [self.invocation setArgument:&completionBlock atIndex:nrArgs-1];
}

-(void)invoke
{
    if (self.isRunning == NO)
    {
        self.isRunning = YES;
        [self.invocation invoke];
    }
}

@end
