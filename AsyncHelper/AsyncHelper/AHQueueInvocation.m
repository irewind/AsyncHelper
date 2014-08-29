//
//  AHQueueInvocation.m
//  AsyncHelper
//
//  Created by Walter Fettich on 02/05/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "AHQueueInvocation.h"
//#import "AHSingleInvocation.h"
#import "NSString+Utils.h"

#import "DDLog.h"

//#ifdef DEBUG
//static int ddLogLevel = LOG_LEVEL_VERBOSE;
//#else
//static int ddLogLevel = LOG_LEVEL_ERROR;
//#endif


@interface AHQueueInvocation ()

@property (retain,nonatomic) NSMutableArray* runningInvocations;
@property (retain,nonatomic) NSMutableArray* preparedInvocations;
@property (retain,nonatomic) NSMutableArray* invocations;
@end

@implementation AHQueueInvocation
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
        self.preparedInvocations = [NSMutableArray array];
        self.invocations = [NSMutableArray array];
        self.name = [NSString stringWithFormat:@"%lu_%@",(unsigned long)[self hash], NSStringFromClass([self class])];
        DDLogVerbose(@"[%@] alloc %@ %p",_classStr,self.name,self);
        
        self.wasSuccessful = YES;
    }
    return self;
}

-(instancetype) initWithInvocations:(NSArray*)invocations andCompletionBlock:(CompletionBlock)complete
{
    if (self = [super init])
    {
        self.runningInvocations = [NSMutableArray array];
        self.preparedInvocations = [NSMutableArray array];
        self.invocations = [[invocations mutableCopy] autorelease];
        
        self.name = [NSString stringWithFormat:@"%lu_%@",(unsigned long)[self hash], NSStringFromClass([self class])];
        
        [self setFinishedBlock:complete];
        [self prepareInvocations];
        DDLogVerbose(@"[%@] alloc %@ %p",_classStr,self.name,self);
        
        self.wasSuccessful = YES;        
    }
    return self;
}

-(void)prepareInvocations
{
//    __block BOOL successful = YES;
    __block AHQueueInvocation* bself = self;

    CompletionBlock invocationCompleted =
    ^(BOOL success, id<AHInvocationProtocol> invocation)
    {
        bself.wasSuccessful &= success;
        [bself.runningInvocations removeObject:invocation];
        
        if (bself.runningInvocations.count == 0)
        {
//            bself.wasSuccessful = successful;
            bself.isRunning = NO;
            if (bself.finishedBlock)
                bself.finishedBlock (bself.wasSuccessful,bself);
            [bself release];
        }
        else
        {
            [bself.runningInvocations[0] invoke];
        }
    };
    
    for (id<AHInvocationProtocol> inv in self.invocations)
    {
        if (NO == [self.preparedInvocations containsObject:inv])
        {
            CompletionBlock originalBlock = inv.finishedBlock;
            
            CompletionBlock b =
            ^(BOOL success, id<AHInvocationProtocol> invocation)
            {
                if (originalBlock)
                {
                    originalBlock(success,invocation);
                    [originalBlock release];
                }
                [bself retain];
                invocationCompleted(success,invocation);
                [bself release];
            };
            
            [inv setFinishedBlock:b];
            
            [b release];
            
            [self.preparedInvocations addObject:inv];
        }
    }
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
    DDLogVerbose(@"[%@] invoking %@",_classStr,self.name);
    
    [self retain];
    if (self.invocations.count > 0 )
    {
        [self.runningInvocations addObjectsFromArray:self.invocations];
        self.isRunning = YES;
        [self.runningInvocations[0] invoke];
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
    DDLogVerbose(@"[%@] dealloc %@ %p",_classStr,self.name,self);
    
    self.preparedInvocations = nil;
    self.invocations = nil;
    self.runningInvocations = nil;
    self.name = nil;
    [self setFinishedBlock:nil];
    self.result = nil;
        
    [super dealloc];
}

@end
