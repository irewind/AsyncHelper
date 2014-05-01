//
//  AHParallelInvocation.h
//  AsyncHelper
//
//  Created by Walter Fettich on 30/04/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHInvocationProtocol.h"

@interface AHParallelInvocation : NSObject<AHInvocationProtocol>
-(instancetype) initWithInvocations:(NSArray*)invocations andCompletionBlock:(CompletionBlock)complete
@end
