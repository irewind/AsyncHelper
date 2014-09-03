//
//  AHQueueInvocation.m
//  AsyncHelper
//
//  Created by Walter Fettich on 02/05/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "AHQueueInvocation.h"
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
        self.invocations = [invocations mutableCopy];
        [self.invocations release];
        
        self.name = [NSString stringWithFormat:@"%lu_%@",(unsigned long)[self hash], NSStringFromClass([self class])];
        
        [self setFinishedBlock:complete];
        [self prepareInvocations];
        DDLogVerbose(@"[%@] alloc %@ %p",_classStr,self.name,self);
        
        self.wasSuccessful = YES;        
    }
    return self;
}

#define _log_line DDLogVerbose(@"%s %d",__FILE__,__LINE__);

-(void)prepareInvocations
{
    __block AHQueueInvocation* bself = self;
    _log_line
    
    CompletionBlock invocationCompleted =
    ^(BOOL success, id<AHInvocationProtocol> invocation)
    {
        _log_line
        bself.wasSuccessful &= success;
        _log_line
        [bself.runningInvocations removeObject:invocation];
        _log_line
        
        if (bself.runningInvocations.count == 0)
        {
            _log_line
            bself.isRunning = NO;
            _log_line
            if (bself.finishedBlock)
            {
                _log_line
                bself.finishedBlock (bself.wasSuccessful,bself);
            }
            _log_line
            [bself release];
            _log_line
        }
        else
        {
            _log_line
            [bself.runningInvocations[0] invoke];
            _log_line
        }
    };
    
    for (id<AHInvocationProtocol> inv in self.invocations)
    {
        if (NO == [self.preparedInvocations containsObject:inv])
        {
            CompletionBlock originalBlock = [[inv.finishedBlock copy] autorelease];
            
            __block CompletionBlock b;
            CompletionBlock* pb = &b;
            b =
            [[^(BOOL success, id<AHInvocationProtocol> invocation)
            {
                if (originalBlock)
                {
                    originalBlock(success,invocation);
                }

                [bself retain];
                invocationCompleted(success,invocation);
                [bself release];

                [invocation setFinishedBlock:originalBlock];
                
            } copy] autorelease];
            
            [inv setFinishedBlock:*pb];
            
            [self.preparedInvocations addObject:inv];
        }
    }
    _log_line
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
