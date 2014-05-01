//
//  NSObject+AsyncHelper.h
//  AsyncHelper
//
//  Created by Walter Fettich on 05/03/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHSingleInvocation.h"

#define _inv(x) inv(self,@selector(x))
#define _inv1(x,y) inv(self,@selector(x),y,nil)

id<AHInvocationProtocol> inv(id target,SEL selector);
id<AHInvocationProtocol> invf(id target,SEL selector,...);

@interface NSObject (AsyncHelper)

-(id<AHInvocationProtocol>)parallelize:(NSArray*)invocations andThen:(CompletionBlock)complete;
-(void)queue:(NSArray*)invocations andThen:(void(^)(BOOL success))complete;
-(void)ifFailed:(NSInvocation*)invocation retryEverySeconds:(NSNumber*)sec andThen:(void(^)(BOOL))complete;
-(void)ifFailed:(NSInvocation*)invocation retryEverySeconds:(NSNumber*)sec forTimes:(NSNumber*)times andThen:(void(^)(BOOL))complete;

@end
