//
//  AHParallelInvocation.h
//  AsyncHelper
//
//  Created by Walter Fettich on 30/04/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//


#import "AHInvocationProtocol.h"

@interface AHInvocation : NSObject

-(instancetype) initWithTarget:(id)target selector:(SEL)selector arguments:(NSArray*)arguments;
-(void)setFinishBlock:(CompletionBlock)finishedBlock;
-(void)invoke;

@end
