//
//  AHParallelInvocation.h
//  AsyncHelper
//
//  Created by Walter Fettich on 30/04/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHInvocationProtocol.h"
#import "AHSingleInvocation.h"

@interface AHParallelInvocation : NSObject<AHInvocationProtocol>
-(instancetype) initWithInvocations:(NSArray*)invocations andCompletionBlock:(CompletionBlock)complete;
-(void)addInvocation:(id<AHInvocationProtocol>)invocation;
-(NSArray*)invocations;
@end
