//
//  AHQueueInvocation.h
//  AsyncHelper
//
//  Created by Walter Fettich on 02/05/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AHInvocationProtocol.h"
#import "AHSingleInvocation.h"

@interface AHQueueInvocation : NSObject<AHInvocationProtocol>
-(instancetype) initWithInvocations:(NSArray*)invocations andCompletionBlock:(CompletionBlock)complete;
-(void)addInvocation:(id<AHInvocationProtocol>)invocation;
-(NSArray*)invocations;
@end
