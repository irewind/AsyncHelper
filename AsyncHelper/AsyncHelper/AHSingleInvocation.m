//
//  AHParallelInvocation.m
//  AsyncHelper
//
//  Created by Walter Fettich on 30/04/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "AHSingleInvocation.h"
#import "NSString+Utils.h"

@interface AHSingleInvocation ()
    @property(retain,nonatomic) NSInvocation* invocation;
    @property(copy, nonatomic) CompletionBlock internalFinishedBlock;
@end

@implementation AHSingleInvocation
//@synthesize finishedBlock;
@synthesize isRunning;
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
        NSLog(@"alloc %@ %p",self.name,self);
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
        
        NSInteger index = 2;
        for (NSObject* arg in arguments)
        {
            [invocation setArgument:(void*)(&arg) atIndex:index];
            index++;
        }
        
        self.invocation = invocation;
        
        [self prepareInvocation];
        NSLog(@"alloc %@ %p",self.name,self);        
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
        bself.result = res == nil?res : @{bself.name:res};
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
        NSLog(@"invoking %@",self.name);
        [self.invocation invoke];
    }
}

-(NSString*)description
{    
    return [NSString stringWithFormat:@"%@: name:%@ target:%@(%p) cmd:%@ result:%@ isRunning:%d",NSStringFromClass([self class]),self.name,NSStringFromClass(self.invocation.target),self.invocation.target,NSStringFromSelector(self.invocation.selector),self.result,self.isRunning ];
    
//    return AHNSStringF(@"%@: name:%@ target:%@(%p) cmd:%@ result:%@ isRunning:%d",NSStringFromClass([self class]),self.name,NSStringFromClass(self.invocation.target),self.invocation.target,NSStringFromSelector(self.invocation.selector),self.result,self.isRunning);
}

-(void)dealloc
{
    NSLog(@"dealloc %@ %p",self.name,self);
    
    [_internalFinishedBlock release];
    [_invocation release];
    [name release];
    [result release];
    
    [super dealloc];
}

@end
