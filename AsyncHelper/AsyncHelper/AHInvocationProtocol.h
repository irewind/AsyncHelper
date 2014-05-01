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
-(void)setFinishBlock:(void(^)(BOOL success, id<AHInvocationProtocol>))finishedBlock;
-(void)invoke;
@end

typedef void (^CompletionBlock)(BOOL success, id<AHInvocationProtocol>);