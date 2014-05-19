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
        self.runningInvocations = [[NSMutableArray alloc] init];
        self.invocations = [[NSMutableArray alloc] init];
        self.name = AHNSStringF(@"%d",[self hash]);
    }
    return self;
}

-(instancetype) initWithInvocations:(NSArray*)invocations andCompletionBlock:(CompletionBlock)complete
{
    if (self = [super init])
    {
        self.runningInvocations = [[NSMutableArray alloc] init];
        self.invocations = [invocations mutableCopy];
        self.name = AHNSStringF(@"%d",[self hash]);
        
        [self setFinishedBlock:complete];
        [self prepareInvocations];
        
    }
    return self;
}

-(void)setFinishedBlock:(CompletionBlock)complete
{
    finishedBlock = complete;
}

-(void)prepareInvocations
{
    __block BOOL successful = YES;
    __block AHParallelInvocation* bself = self;

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
        if (invocation.result != nil)
        {
            resultDict[invocation.name] = invocation.result;
        }
    }
    
    return [NSDictionary dictionaryWithDictionary:resultDict];
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

-(NSString*)description
{
    return AHNSStringF(@"%@: name:%@ invocations count:%d result:%@ isRunning:%d",NSStringFromClass([self class]),self.name,self.invocations.count,self.result,self.isRunning);
}

@end
