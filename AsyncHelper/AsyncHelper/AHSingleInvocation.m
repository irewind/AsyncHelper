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

-(instancetype) initWithTarget:(id)target selector:(SEL)selector arguments:(NSArray*)arguments
{
    if (self = [super init])
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
        
        self.invocation = invocation;
    }
    return self;
}

-(void)setFinishBlock:(CompletionBlock)finishedBlock
{
    NSUInteger nrArgs = [[self.invocation methodSignature] numberOfArguments];
    [self.invocation setArgument:&finishedBlock atIndex:nrArgs-1];
}

-(void)invoke
{
    [self.invocation invoke];
}

@end
