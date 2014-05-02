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
    // do smth
    
    dispatch_async(dispatch_get_main_queue(),
       ^{
           NSLog(@"op1 done");
           complete(YES);
       });
}


-(void)op2AndThen:(void(^)(BOOL success))complete
{
    // do smth
    
    dispatch_async(dispatch_get_main_queue(),
       ^{
           NSLog(@"op2 done");
           complete(YES);
       });
}

-(void)op3AndThen:(void(^)(BOOL success))complete
{
    static int n = 3;
    NSLog(@"exec op3 n=%d",n);
    
    dispatch_async(dispatch_get_main_queue(),
       ^{
           n--;
           BOOL ok = n<=0;
           NSLog(@"op3 done %d n=%d",ok,n);
           complete(ok);
           if (ok)
           {
               n=3;
           }
       });
}



-(void)test1
{
    [self parallelize:@[
                        _inv(op1AndThen:),
                        _inv(op2AndThen:),
                        _inv(op3AndThen:)
                        ]
              andThen:
     ^(BOOL success, id<AHInvocationProtocol> inv)
     {
         NSLog(@"parallel all done %d",success);
     }];
}


-(void)test2
{
    [self queue:@[
                  _inv(op1AndThen:),
                  _inv(op2AndThen:)
                  ]
        andThen:
     ^(BOOL success)
     {
         NSLog(@"queue all done %d",success);
         
         [self parallelize:@[
                             _inv(op2AndThen:),
                             _inv(op2AndThen:),
                             _inv(op2AndThen:),
                             _inv(op2AndThen:)
                             ] andThen:
          ^(BOOL success, id<AHInvocationProtocol> inv)
          {
              NSLog(@"parallel 2 all done %d",success);
          }];
     }];
}

-(void)test3
{
    [self queue:@[
                  _inv(op1AndThen:),
                  invf(self,@selector(parallelize:andThen:),
                       @[
                         _inv(op2AndThen:),
                         _inv(op2AndThen:)
                         ],nil)
                  ]
        andThen:
     ^(BOOL success)
     {
         NSLog(@"queue all done %d",success);
     }];
    
}

-(void)test4
{
    [self ifFailed:_inv(op3AndThen:) retryEverySeconds:@(2) andThen:
     ^(BOOL success)
     {
         NSLog(@"test 4 done %d",success);
     }];
}

-(void)test5
{
    
    [self queue:@[
                  _inv(op1AndThen:),
                  invf(self,@selector(parallelize:andThen:),
                       @[
                         invf(self,@selector(ifFailed:retryEverySeconds:andThen:),
                              _inv(op3AndThen:),
                              @(2),nil),
                         
                         _inv(op2AndThen:)
                         ],nil)
                  ]
        andThen:
     ^(BOOL success)
     {
         NSLog(@"queue all done %d",success);
     }];
    
    //    [self ifFailed:_inv(op3AndThen:) repeatEvery:@(2) andOnSuccess:
    //     ^(BOOL success)
    //     {
    //         NSLog(@"test 4 done %d",success);
    //     }];
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
//
//    [self test2];

//    [self test3];
//
//    [self test4];
//    
//    [self test5];
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
