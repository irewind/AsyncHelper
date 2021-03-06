//
//  AHParallelInvocation.m
//  AsyncHelper
//
//  Created by Walter Fettich on 30/04/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "AHParallelInvocation.h"
//#import "AHSingleInvocation.h"
#import "NSString+Utils.h"

#import "DDLog.h"

#ifdef DEMO_ASYNC
static int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
//static int ddLogLevel = LOG_LEVEL_ERROR;
#endif

@interface AHParallelInvocation ()
@property (strong,nonatomic) NSMutableArray* runningInvocations;
@property (strong,nonatomic) NSMutableArray* preparedInvocations;
@property (strong,nonatomic) NSMutableArray* invocations;
@end

@implementation AHParallelInvocation
@synthesize finishedBlock;
@synthesize isRunning;
@synthesize wasSuccessful;
@synthesize result;
@synthesize name;

-(instancetype) init
{
    if (self = [super init])
    {
        self.runningInvocations = [NSMutableArray array];
        self.invocations = [NSMutableArray array];
        self.preparedInvocations = [NSMutableArray array];
        self.name = [NSString stringWithFormat:@"%lu_%@",(unsigned long)[self hash], NSStringFromClass([self class])];
        
        self.wasSuccessful = YES;
//        DDLogVerbose(@"[%@] alloc %@ %p",_classStr,self.name,self);
    }
    return self;
}

-(instancetype) initWithInvocations:(NSArray*)invocations andCompletionBlock:(CompletionBlock)complete
{
    if (self = [super init])
    {
        self.runningInvocations = [NSMutableArray array];
        self.invocations = [[invocations mutableCopy] autorelease];
        self.preparedInvocations = [NSMutableArray array];        
        self.name = [NSString stringWithFormat:@"%lu_%@",(unsigned long)[self hash], NSStringFromClass([self class])];
        
        [self setFinishedBlock:complete];
        [self prepareInvocations];
        
        self.wasSuccessful = YES;
//        DDLogVerbose(@"[%@] alloc %@ %p",_classStr,self.name,self);
    }
    return self;
}

-(void)prepareInvocations
{
    __block AHParallelInvocation* bself = self;
    
    CompletionBlock invocationCompleted =
    ^(BOOL success, id<AHInvocationProtocol> invocation)
    {
        bself.wasSuccessful &= success;
        [bself.runningInvocations removeObject:invocation];
        if (bself.runningInvocations.count == 0)
        {
            bself.isRunning = NO;
            if (bself.finishedBlock)
                bself.finishedBlock (bself.wasSuccessful,bself);
            [bself release];
        }
    };
    
    for (id<AHInvocationProtocol> invocation in self.invocations)
    {
        if (NO == [self.preparedInvocations containsObject:invocation])
        {
            CompletionBlock originalBlock = [[invocation.finishedBlock copy] autorelease];
            
            CompletionBlock b;
            CompletionBlock* pb = &b;

            b =  ^(BOOL success, id<AHInvocationProtocol> theInvocation)
            {
                if (originalBlock)
                {
                    originalBlock(success,theInvocation);
                }
                invocationCompleted(success,theInvocation);
                [theInvocation setFinishedBlock:originalBlock];
            };

            [invocation setFinishedBlock:*pb];
            
            [self.preparedInvocations addObject:invocation];
        }
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
//    DDLogVerbose(@"[%@] invoking %@",_classStr,self.name);
    
    [self retain];
    
    if (self.invocations.count > 0)
    {
        for (id<AHInvocationProtocol>invocation in self.invocations)
        {
            [self.runningInvocations addObject:invocation];
        }
        
        for (id<AHInvocationProtocol> invocation in self.invocations)
        {
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
    return [NSString stringWithFormat:@"%@: name:%@ invocations count:%lu wasSuccessful:%d result:%@ isRunning:%d",NSStringFromClass([self class]),self.name,(unsigned long)self.invocations.count,self.wasSuccessful,self.result,self.isRunning];
}

-(void)dealloc
{
//    DDLogVerbose(@"[%@] dealloc %@ %p",_classStr,self.name,self);
    
    self.invocations = nil;
    self.runningInvocations = nil;
    [self setFinishedBlock:nil];
    self.preparedInvocations = nil;
    self.name = nil;
    self.result = nil;
    
    [super dealloc];
}

@end
