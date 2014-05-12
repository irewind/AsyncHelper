//
//  AHInvocationProtocol.h
//  AsyncHelper
//
//  Created by Walter Fettich on 30/04/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AHInvocationProtocol;

@protocol AHInvocationProtocol <NSObject>
@property (strong,nonatomic) void(^finishedBlock)(BOOL success, id<AHInvocationProtocol>);
-(void)invoke;
@property (assign,nonatomic) BOOL isRunning;
@property (strong,nonatomic) NSObject* result;
@end

typedef void (^CompletionBlock)(BOOL success, id<AHInvocationProtocol> invocation);