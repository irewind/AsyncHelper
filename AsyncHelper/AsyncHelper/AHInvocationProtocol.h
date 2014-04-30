//
//  AHInvocationProtocol.h
//  AsyncHelper
//
//  Created by Walter Fettich on 30/04/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AHInvocationProtocol;
typedef void (^CompletionBlock)(BOOL success, id<AHInvocationProtocol>);

@protocol AHInvocationProtocol <NSObject>
-(void)setFinishBlock:(CompletionBlock)finishedBlock;
-(void)invoke;
@end
