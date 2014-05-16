//
//  AHQueueInvocation.m
//  AsyncHelper
//
//  Created by Walter Fettich on 02/05/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "AHQueueInvocation.h"
#import "AHSingleInvocation.h"

@interface AHQueueInvocation ()

@property (strong,nonatomic) NSMutableArray* runningInvocations;
@property (strong,nonatomic) NSMutableArray* invocations;
@end

@implementation AHQueueInvocation
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
        
        [self setFinishBlock:complete];
        
    }
    return self;
}

-(void)setFinishBlock:(CompletionBlock)complete
{
    __block BOOL successful = YES;
    __block AHQueueInvocation* bself = self;
    finishedBlock = complete;
    
    CompletionBlock completionBlock =
    ^(BOOL success, id<AHInvocationProtocol> invocation)
    {
        successful &= success;
        [bself.runningInvocations removeObject:invocation];
        
        if (bself.runningInvocations.count == 0)
        {
            bself.isRunning = NO;
            if (bself.finishedBlock)
                bself.finishedBlock (successful,bself);
        }
        else
        {
            [bself.runningInvocations[0] invoke];
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
    
    [invocation setFinishedBlock:self.finishedBlock];
}


//-(void) setResult:(NSObject *)result
//{
//}
//
//-(NSObject*) result
//{
//    NSMutableArray* resultArray = [NSMutableArray array];
//    
//    for (id<AHInvocationProtocol> invocation in self.invocations)
//    {
//        if (invocation.result != nil)
//        {
//            [resultArray addObject:invocation.result];
//        }
//    }
//    
//    return [NSArray arrayWithArray:resultArray];
//}

-(void)invoke
{
    if (self.invocations.count > 0 )
    {
        [self.runningInvocations addObjectsFromArray:self.invocations];
        
        [self.runningInvocations[0] invoke];
        self.isRunning = YES;
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
