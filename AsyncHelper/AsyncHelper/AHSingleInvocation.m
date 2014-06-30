//
//  AHParallelInvocation.m
//  AsyncHelper
//
//  Created by Walter Fettich on 30/04/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "AHSingleInvocation.h"
#import "NSString+Utils.h"
#import "DDLog.h"

#ifdef DEBUG
static int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static int ddLogLevel = LOG_LEVEL_ERROR;
#endif

@interface AHSingleInvocation ()
    @property(retain,nonatomic) NSInvocation* invocation;
    @property(copy, nonatomic) CompletionBlock internalFinishedBlock;
@end

@implementation AHSingleInvocation
@synthesize isRunning;
@synthesize wasSuccessful;
@synthesize result;
@synthesize name;

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
        self.name = [NSString stringWithFormat:@"%lu_%@",(unsigned long)[self hash], NSStringFromSelector(invocation.selector)];
        DDLogVerbose(@"alloc %@ %p",self.name,self);
        [self prepareInvocation];
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
        
        self.name = [NSString stringWithFormat:@"%lu_%@",(unsigned long)[self hash], NSStringFromSelector(invocation.selector)];
        DDLogVerbose(@"alloc %@ %p",self.name,self);
        
        NSInteger index = 2;
        for (NSObject* arg in arguments)
        {
            [invocation setArgument:(void*)(&arg) atIndex:index];
            index++;
        }
        
        self.invocation = invocation;
        
        [self prepareInvocation];
    }
    return self;
}

-(void)prepareInvocation
{
    __block AHSingleInvocation* bself = self;

    ResponseBlock completionBlock =
    ^(BOOL success, NSObject* res)
    {
        bself.isRunning = NO;
        bself.wasSuccessful = success;
        bself.result = res == nil?res : @{name:res};
        if (bself.finishedBlock)
            bself.finishedBlock(success,bself);
        [bself release];
    };
    
    NSUInteger nrArgs = [[self.invocation methodSignature] numberOfArguments];
    
    [self.invocation setArgument:&completionBlock atIndex:nrArgs-1];
    
    [self.invocation retainArguments];
}

-(void)setFinishedBlock:(CompletionBlock)complete
{
    [self setInternalFinishedBlock:complete];
    
    [self prepareInvocation];
}

-(CompletionBlock)finishedBlock
{
    return self.internalFinishedBlock;
}

-(void)invoke
{
    if (self.isRunning == NO && self.invocation != nil)
    {
        [self retain];
        self.isRunning = YES;
        DDLogVerbose(@"invoking %@",self.name);
        [self.invocation invoke];
    }
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"%@: name:%@ target:%@(%p) cmd:%@ wasSuccessful:%d result:%@ isRunning:%d",NSStringFromClass([self class]),self.name,NSStringFromClass(self.invocation.target),self.invocation.target,NSStringFromSelector(self.invocation.selector),self.wasSuccessful,self.result,self.isRunning];
}

-(void)dealloc
{
    DDLogVerbose(@"dealloc %@ %p",self.name,self);
    
    self.internalFinishedBlock = nil;
    self.invocation = nil;
    self.name = nil;
    self.result = nil;
    
    [super dealloc];
}

@end
