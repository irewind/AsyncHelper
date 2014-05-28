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
    @property(strong,nonatomic) NSInvocation* invocation;
@end

@implementation AHSingleInvocation
@synthesize finishedBlock;
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
        self.name = AHNSStringF(@"%d_%@",[self hash], NSStringFromSelector(invocation.selector));
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
        
        self.name = AHNSStringF(@"%d_%@",[self hash], NSStringFromSelector(invocation.selector));
        
        NSInteger index = 2;
        for (NSObject* arg in arguments)
        {
            [invocation setArgument:(void*)(&arg) atIndex:index];
            index++;
        }
        [invocation retainArguments];
        
        self.invocation = invocation;
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
    };
    
    NSUInteger nrArgs = [[self.invocation methodSignature] numberOfArguments];
    [self.invocation setArgument:&completionBlock atIndex:nrArgs-1];
    
    [self.invocation retainArguments];
}

-(void)setFinishedBlock:(CompletionBlock)complete
{
    finishedBlock = [complete copy];
    
    [self prepareInvocation];
}

-(void)invoke
{
    if (self.isRunning == NO)
    {
        self.isRunning = YES;
        [self.invocation invoke];
    }
}

-(NSString*)description
{
    return AHNSStringF(@"%@: name:%@ target:%@(%p) cmd:%@ result:%@ isRunning:%d",NSStringFromClass([self class]),self.name,NSStringFromClass(self.invocation.target),self.invocation.target,NSStringFromSelector(self.invocation.selector),self.result,self.isRunning);
}

-(void)dealloc
{
    NSLog(@"dealloc %@",self.name);
    self.invocation = nil;
}

@end
