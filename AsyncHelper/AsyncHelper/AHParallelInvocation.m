//
//  AHParallelInvocation.m
//  AsyncHelper
//
//  Created by Walter Fettich on 30/04/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "AHParallelInvocation.h"
#import "AHSingleInvocation.h"
#import "NSString+Utils.h"

@interface AHParallelInvocation ()
@property (strong,nonatomic) NSMutableArray* runningInvocations;
@property (strong,nonatomic) NSMutableArray* invocations;
@end

@implementation AHParallelInvocation
@synthesize finishedBlock;
@synthesize isRunning;
@synthesize result;
@synthesize name;

-(instancetype) init
{
    if (self = [super init])
    {
        self.runningInvocations = [NSMutableArray array];
        self.invocations = [NSMutableArray array];
        self.name = [NSString stringWithFormat:@"%lu_%@",(unsigned long)[self hash], NSStringFromClass([self class])];
    }
    return self;
}

-(instancetype) initWithInvocations:(NSArray*)invocations andCompletionBlock:(CompletionBlock)complete
{
    if (self = [super init])
    {
        self.runningInvocations = [NSMutableArray array];
        self.invocations = [[invocations mutableCopy] autorelease];
        self.name = [NSString stringWithFormat:@"%lu_%@",(unsigned long)[self hash], NSStringFromClass([self class])];
        
        [self setFinishedBlock:complete];
        [self prepareInvocations];
        
    }
    return self;
}

-(void)setFinishedBlock:(CompletionBlock)complete
{
    finishedBlock = [complete copy];
}

-(void)prepareInvocations
{
    __block BOOL successful = YES;
    __block AHParallelInvocation* bself = self;

    CompletionBlock invocationCompleted =
    ^(BOOL success, id<AHInvocationProtocol> invocation)
    {
        successful &= success;
        [bself.runningInvocations removeObject:invocation];
        
        if (bself.runningInvocations.count == 0)
        {
            bself.isRunning = NO;
            if (bself.finishedBlock)
                bself.finishedBlock (successful,bself);
            [bself release];
        }
    };
    
    for (AHSingleInvocation* invocation in self.invocations)
    {
        ResponseBlock originalBlock = invocation.finishedBlock;
        
        [invocation setFinishedBlock:
         ^(BOOL success, id<AHInvocationProtocol> theInvocation)
         {
             if (originalBlock)
                  originalBlock(success,theInvocation);
             invocationCompleted(success,theInvocation);
         }];
    }

}

-(void)addInvocation:(id<AHInvocationProtocol>)invocation
{
    [_invocations addObject:invocation];
    
    [self prepareInvocations];
    
    if (self.isRunning)
    {
        [invocation invoke];
    }
}

-(void) setResult:(NSObject *)result
{
}

-(NSObject*) result
{
    NSMutableDictionary* resultDict = [NSMutableDictionary dictionary];
    
    for (id<AHInvocationProtocol> invocation in self.invocations)
    {
        if (invocation.result != nil && ((NSDictionary*)invocation.result)[invocation.name] != nil)
        {
            resultDict[invocation.name] = ((NSDictionary*)invocation.result)[invocation.name];
        }
    }
    
    return @{self.name:resultDict};
}

-(void)invoke
{
    [self retain];
    if (self.invocations.count > 0)
    {
        for (AHSingleInvocation* invocation in self.invocations)
        {
            [self.runningInvocations addObject:invocation];
            [invocation invoke];
        }
    }
    else
    {
        if (self.finishedBlock)
            self.finishedBlock (YES,self);
        [self release];
    }
}

-(NSArray*)invocations
{
    return _invocations;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"%@: name:%@ invocations count:%lu result:%@ isRunning:%d",NSStringFromClass([self class]),self.name,(unsigned long)self.invocations.count,self.result,self.isRunning];
}

-(void)dealloc
{
    [_invocations release];
    [_runningInvocations release];
    [finishedBlock release];
    [name release];
    [result release];
    
    NSLog(@"dealloc %@",self.name);
    
    [super dealloc];
}

@end
