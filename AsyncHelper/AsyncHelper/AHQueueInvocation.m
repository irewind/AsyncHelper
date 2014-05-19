//
//  AHQueueInvocation.m
//  AsyncHelper
//
//  Created by Walter Fettich on 02/05/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "AHQueueInvocation.h"
#import "AHSingleInvocation.h"
#import "NSString+Utils.h"

@interface AHQueueInvocation ()

@property (strong,nonatomic) NSMutableArray* runningInvocations;
@property (strong,nonatomic) NSMutableArray* invocations;
@end

@implementation AHQueueInvocation
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
        self.name = AHNSStringF(@"%d_%@",[self hash], NSStringFromClass([self class]));
    }
    return self;
}

-(instancetype) initWithInvocations:(NSArray*)invocations andCompletionBlock:(CompletionBlock)complete
{
    if (self = [super init])
    {
        self.runningInvocations = [[NSMutableArray alloc] init];
        self.invocations = [invocations mutableCopy];
        self.name = AHNSStringF(@"%d_%@",[self hash], NSStringFromClass([self class]));
        
        [self setFinishBlock:complete];
        [self prepareInvocations];
        
    }
    return self;
}

-(void)prepareInvocations
{
    __block BOOL successful = YES;
    __block AHQueueInvocation* bself = self;

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

-(void)setFinishBlock:(CompletionBlock)complete
{
    finishedBlock = complete;
    
//    [self prepareInvocations];
}

-(void)addInvocation:(id<AHInvocationProtocol>)invocation
{
    [_invocations addObject:invocation];
    
    [self prepareInvocations];
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
    if (self.invocations.count > 0 )
    {
        [self.runningInvocations addObjectsFromArray:self.invocations];
        self.isRunning = YES;
        [self.runningInvocations[0] invoke];
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
