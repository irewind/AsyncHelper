//
//  NSObject+AsyncHelper.h
//  AsyncHelper
//
//  Created by Walter Fettich on 05/03/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHSingleInvocation.h"
#import "AHParallelInvocation.h"
#import "AHQueueInvocation.h"
#import "AHInsistentInvocation.h"

#define _inv(x) inv(self,@selector(x))
#define _inv1(x,y) invf(self,@selector(x),y,nil)
#define _inv2(x,y,z) invf(self,@selector(x),y,z,nil)

AHSingleInvocation* inv(id target,SEL selector);
AHSingleInvocation* invf(id target,SEL selector,...);

@interface NSObject (AsyncHelper)

-(AHParallelInvocation*)parallelize:(NSArray*)invocations;
-(AHParallelInvocation*)parallelize:(NSArray*)invocations andThen:(CompletionBlock)complete;

-(AHQueueInvocation*)queue:(NSArray*)invocations;
-(AHQueueInvocation*)queue:(NSArray*)invocations andThen:(CompletionBlock)complete;

-(AHInsistentInvocation*)ifFailed:(AHSingleInvocation*)invocation retryEverySeconds:(NSNumber*)sec;
-(AHInsistentInvocation*)ifFailed:(AHSingleInvocation*)invocation retryEverySeconds:(NSNumber*)sec forTimes:(NSNumber*)times;
-(AHInsistentInvocation*)ifFailed:(AHSingleInvocation*)invocation retryEverySeconds:(NSNumber*)sec forTimes:(NSNumber*)times andThen:(CompletionBlock)complete;
-(AHInsistentInvocation*)ifFailed:(AHSingleInvocation*)invocation retryEverySeconds:(NSNumber*)sec andThen:(CompletionBlock)complete;
@end
