//
//  AHParallelInvocation.m
//  AsyncHelper
//
//  Created by Walter Fettich on 30/04/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "AHParallelInvocation.h"
#import "AHInvocation.h"

@interface AHParallelInvocation ()
@property (strong,nonatomic) NSMutableArray* runningInvocations;
@property (strong,nonatomic) NSArray* invocations;
@end

@implementation AHParallelInvocation

-(instancetype) initWithInvocations:(NSArray*)invocations andCompletionBlock:(CompletionBlock)complete
{
    if (self = [super init])
    {
        self.runningInvocations = [[NSMutableArray alloc] init];
        self.invocations = invocations;
        
        __block BOOL successful = YES;
        
        CompletionBlock finishedBlock =
        ^(BOOL success, NSInvocation* invocation)
        {
            successful &= success;
            [self.runningInvocations removeObject:invocation];
            
            if (self.runningInvocations.count == 0)
            {
                if (complete)
                    complete (successful);
            }
        };
        
        for (AHInvocation* invocation in invocations)
        {
            [invocation setFinishBlock:complete];
        }
    }
    return self;
}


-(void)invoke
{
    for (NSInvocation* invocation in self.invocations)
    {
        [self.runningInvocations addObject:invocation];
        [invocation invoke];
    }
}

@end
