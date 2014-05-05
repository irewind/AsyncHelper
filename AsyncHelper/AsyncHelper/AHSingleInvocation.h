//
//  AHParallelInvocation.h
//  AsyncHelper
//
//  Created by Walter Fettich on 30/04/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//


#import "AHInvocationProtocol.h"

@interface AHSingleInvocation : NSObject<AHInvocationProtocol>

-(instancetype) initWithTarget:(id)target selector:(SEL)selector arguments:(NSArray*)arguments;
-(instancetype) initWithNSInvocation:(NSInvocation*)invocation;

@end
