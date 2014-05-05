//
//  AppDelegate.m
//  DemoAsyncHelper
//
//  Created by Walter Fettich on 05/03/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "AppDelegate.h"
#import <NSObject+AsyncHelper.h>

@implementation AppDelegate


-(void)op1AndThen:(void(^)(BOOL success))complete
{
    NSLog(@"started op1");    
    dispatch_async(dispatch_get_main_queue(),
       ^{
           NSLog(@"op1 done");
           complete(YES);
       });
}


-(void)op2AndThen:(void(^)(BOOL success))complete
{
    // do smth
    NSLog(@"started op2");
    dispatch_async(dispatch_get_main_queue(),
       ^{
           NSLog(@"op2 done");
           complete(YES);
       });
}

-(void)op3AndThen:(void(^)(BOOL success))complete
{
    static int n = 3;
    NSLog(@"started op3, remaining %d",n);
    
    dispatch_async(dispatch_get_main_queue(),
    ^{
       n--;
       BOOL ok = n<=0;
       NSLog(@"op3 done %d, remaining %d",ok,n);
       complete(ok);
       if (ok)
       {
           n=3;
       }
    });
}

-(void)op4AndThen:(void(^)(BOOL success))complete
{
    static int n2 = 200;
//    NSLog(@"started op4, remaining %d",n2);
    
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       n2--;
                       BOOL ok = n2<=0;
//                       NSLog(@"op4 done %d, remaining %d",ok,n2);
                       complete(ok);
                       if (ok)
                       {
                           n2=200;
                       }
                   });
}


-(void)test1
{
    NSLog(@"begin test1");
    
    [[self parallelize:@[
                        _inv(op1AndThen:),
                        _inv(op2AndThen:),
                        _inv(op3AndThen:)
                        ]
              andThen:
     ^(BOOL success, id<AHInvocationProtocol> inv)
     {
         NSLog(@"test1 done %d",success);
     }] invoke]
    ;
}


-(void)test2
{
    NSLog(@"begin test2");
    [[self queue:@[
                  _inv(op1AndThen:)
                  ,_inv(op2AndThen:)
                  ]
        andThen:
     ^(BOOL success, id<AHInvocationProtocol> invocation)
     {
         NSLog(@"queue all done %d",success);
         
         [[self parallelize:@[
                             _inv(op2AndThen:)
                             ,_inv(op2AndThen:)
                             ,_inv(op2AndThen:)
                             ] andThen:
          ^(BOOL success, id<AHInvocationProtocol> inv)
          {
              NSLog(@"test2 done %d",success);
          }] invoke];
         
     }] invoke]
    ;
}

-(void)test3
{
    NSLog(@"begin test3");
    [[self queue:@[
                  _inv(op1AndThen:),
                  [self parallelize:
                       @[
                         _inv(op2AndThen:),
                         _inv(op2AndThen:)
                         ] andThen:nil]
                  ]
        andThen:
     ^(BOOL success, id<AHInvocationProtocol> inv)
     {
         NSLog(@"test3 done %d",success);
     }] invoke]
    ;
    
}

-(void)test4
{
    NSLog(@"begin test4");
    [[self ifFailed:_inv(op3AndThen:) retryEverySeconds:@(2) andThen:
     ^(BOOL success, id<AHInvocationProtocol> inv)
     {
         NSLog(@"test4 done %d",success);
     }] invoke];
}

-(void)test5
{
    NSLog(@"begin test5");
    [[self queue:@[
                  _inv(op1AndThen:),
                  [self parallelize:
                       @[
                          [self ifFailed:_inv(op3AndThen:) retryEverySeconds:@(2) andThen:nil]
                         ,_inv(op2AndThen:)
                         ] andThen:nil]
                  ]
        andThen:
     ^(BOOL success, id<AHInvocationProtocol> inv)
     {
         NSLog(@"test5 done %d",success);
     }] invoke]
    ;
}

-(void)test6
{
    NSLog(@"begin test6");
     AHQueueInvocation* queue = [self queue:@[
                  _inv(op1AndThen:),
                  _inv(op2AndThen:),
                  _inv(op1AndThen:),
                  _inv(op2AndThen:),
                  ]
        andThen:
     ^(BOOL success, id<AHInvocationProtocol> inv)
     {
         NSLog(@"test6 done %d",success);
     }];
    [queue invoke];
    
    [queue addInvocation:_inv(op3AndThen:)];
}

-(void)test7
{
    NSLog(@"begin test7");
    
    [[self ifFailed:_inv(op3AndThen:) retryEverySeconds:@2 forTimes:@1 andThen:
     ^(BOOL success, id<AHInvocationProtocol> inv)
    {
        [self op2AndThen:
         ^(BOOL success)
        {
            NSLog(@"test7 done %d",success);
        }];
    }] invoke]
    ;
}

-(void)test8
{
    NSLog(@"begin test8");
    
    [[self ifFailed:_inv(op4AndThen:) retryEverySeconds:@(0.1) andThen:
     ^(BOOL success, id<AHInvocationProtocol> inv)
     {
         [self op2AndThen:
          ^(BOOL success)
          {
              NSLog(@"test8 done %d",success);
          }];
     }] invoke]
    ;
}

-(void)doStuff
{
    
//    [self ifFailed:_inv(op1AndThen:) retryEverySeconds:@2 andThen:
//     ^(BOOL success)
//    {
//        [self op2AndThen:
//         ^(BOOL success)
//        {
//            NSLog(@"OK!!!!");
//
//        }];
//    }];

    [self test1];

    [self test2];

    [self test3];

    [self test4];

    [self test5];

    [self test6];

    [self test7];
    
    [self test8];        
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    [self doStuff];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
