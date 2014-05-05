//
//  AHInsistentInvocation.h
//  AsyncHelper
//
//  Created by Walter Fettich on 05/05/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AHInvocationProtocol.h"
@interface AHInsistentInvocation : NSObject <AHInvocationProtocol>

-(instancetype) initWithInvocation:(id<AHInvocationProtocol>)invocation retryEverySeconds:(NSNumber*)sec forTimes:(NSNumber*)times andCompletionBlock:(CompletionBlock)complete;
-(instancetype) initWithInvocation:(id<AHInvocationProtocol>)invocation retryEverySeconds:(NSNumber*)sec  andCompletionBlock:(CompletionBlock)complete;

@end
