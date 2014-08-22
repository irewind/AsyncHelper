//
//  AppDelegate.m
//  DemoAsyncHelper
//
//  Created by Walter Fettich on 05/03/14.
//  Copyright (c) 2014 Walter Fettich. All rights reserved.
//

#import "AppDelegate.h"
#import <NSObject+AsyncHelper.h>
#import <AHLogLevel.h>
#import "NSString+Utils.h"
#import "DDLogNSLogger.h"
#import "DDLog.h"


@implementation AppDelegate

#define _classStr NSStringFromClass([self class])
#define _selStr NSStringFromSelector(_cmd)
#define _a(x) /*NSAssert(x,@"[%@] %@ ASSERT FAILED!",_classStr,_selStr);*/ if (NO == (x)) { [AppDelegate breakPoint]; NSString* assertMsg = [NSString stringWithFormat:@"[%@] %@ ASSERT FAILED! %s",_classStr,_selStr,#x]; NSLog(@"%@",assertMsg);}

+(void)breakPoint
{
    int x = 0;
    x++;
}

-(void)op11AndThen:(void(^)(BOOL success,NSObject* result))complete
{
    NSLog(@"started op11");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(),
    ^{
        NSLog(@"op11 done");
        complete(YES,@(666));
    });
}

-(void)op1AndThen:(void(^)(BOOL success,NSObject* result))complete
{
    NSLog(@"started op1");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(),
       ^{
           NSLog(@"op1 done");
           complete(YES,nil);
       });
}


-(void)op2AndThen:(void(^)(BOOL success,NSObject* result))complete
{
    // do smth
    NSLog(@"started op2");
    dispatch_async(dispatch_get_main_queue(),
       ^{
           NSLog(@"op2 done");
           complete(YES,nil);
       });
}

-(void)op3AndThen:(void(^)(BOOL success,NSObject* result))complete
{
    static int n = 3;
    NSLog(@"started op3, remaining %d",n);
    
    dispatch_async(dispatch_get_main_queue(),
    ^{
       n--;
       BOOL ok = n<=0;
       NSLog(@"op3 done %d, remaining %d",ok,n);
       complete(ok,@"res3");
       if (ok)
       {
           n=3;
       }
    });
}

-(void)op4AndThen:(void(^)(BOOL success,NSObject* result))complete
{
    static int n2 = 200;
//    NSLog(@"started op4, remaining %d",n2);
    
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       n2--;
                       BOOL ok = n2<=0;
//                       NSLog(@"op4 done %d, remaining %d",ok,n2);
                       complete(ok,@"res4");
                       if (ok)
                       {
                           n2=200;
                       }
                   });
}

-(void) op5WithNum:(NSNumber*)num andStr:(NSString*)str andThen:(void(^)(BOOL success,NSObject* result))complete
{
    NSLog(@"begin op5 args: %@ %@",num,str);
    
    dispatch_async(dispatch_get_main_queue(),
        ^{
            NSLog(@"op5 done args: %@ %@",num,str);
            if (complete)
                complete(YES,@"res5");
        });
}

-(void)op6AndThen:(void(^)(BOOL success,NSObject* result))complete
{
    AHParallelInvocation* parallel = [self parallelize:@[] andThen:
                                      ^(BOOL success, id<AHInvocationProtocol> invocation)
                                      {
                                          NSLog(@"finished op6 success: %d, result: %@",success,invocation.result);
                                          if (complete)
                                              complete(success,invocation.result);
                                      }];
    
    for (int i = 0; i < 3; i++)
    {
        [parallel addInvocation:_inv(op1AndThen:)];
    }
    
    [parallel invoke];
}

-(void)op7AndThen:(void(^)(BOOL success,NSObject* result))complete
{
    if (complete)
        complete(YES,nil);
}

-(void)test16AndThen:(ResponseBlock)complete
{
    [[self queue:@[
                  _inv(op1AndThen:),
                  [self parallelize:@[
                                      _inv(op1AndThen:)
                                      ]],
                  [self queue:@[
                                _inv(op1AndThen:)
                                ]],
                 ]
    andThen:^(BOOL success, id<AHInvocationProtocol> invocation) {
      
        if (complete)
            complete(success,invocation.result);
    }] invoke];
    
}


-(void)test1AndThen:(ResponseBlock)complete
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
         NSLog(@"test1 done %d, results: %@",NO == success, inv.result);
         NSLog(@"--------1--------");
         _a(NO == success);
         
         if (complete)
             complete (NO == success,nil);
         
     }] invoke]
    ;
}


-(void)test2AndThen:(ResponseBlock)complete
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
              NSLog(@"--------2--------");
              _a(success);
              if (complete)
                  complete (success,nil);
              
          }] invoke];
    
     }] invoke]
    ;
}

-(void)test3AndThen:(ResponseBlock)complete
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
         NSLog(@"--------3--------");
          _a(success);
         if (complete)
             complete (success,nil);

     }] invoke]
    ;
    
}

-(void)test4AndThen:(ResponseBlock)complete
{
    NSLog(@"begin test4");
    [[self ifFailed:_inv(op3AndThen:) retryEverySeconds:@(2) andThen:
     ^(BOOL success, id<AHInvocationProtocol> inv)
     {
         NSLog(@"test4 done %d",success);
         NSLog(@"--------4--------");
          _a(success);
         if (complete)
             complete (success,nil);

     }] invoke];
}

-(void)test5AndThen:(ResponseBlock)complete
{
    NSLog(@"begin test5");
    [[self queue:@[
//                  _inv(op1AndThen:),
                  [self parallelize:
                       @[
                          [self ifFailed:_inv(op3AndThen:) retryEverySeconds:@(2) andThen:nil]
//                         ,_inv(op2AndThen:)
                         ] andThen:nil]
                  ]
        andThen:
     ^(BOOL success, id<AHInvocationProtocol> inv)
     {
         NSLog(@"test5 done %d",success);
         NSLog(@"--------5--------");
          _a(success);
         if (complete)
             complete (success,nil);

     }] invoke]
    ;
}

-(void)test6AndThen:(ResponseBlock)complete
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
         NSLog(@"--------6--------");
          _a(success);
         if (complete)
             complete (success,nil);

     }];
    [queue invoke];
    
    [queue addInvocation:_inv(op3AndThen:)];
}

-(void)test7AndThen:(ResponseBlock)complete
{
    NSLog(@"begin test7");
    
    [[self ifFailed:_inv(op3AndThen:) retryEverySeconds:@2 forTimes:@1 andThen:
     ^(BOOL success, id<AHInvocationProtocol> inv)
    {
        [self op2AndThen:
         ^(BOOL success,NSObject* result)
        {
            NSLog(@"test7 done %d",success);
            NSLog(@"--------7--------");
              _a(success);
            if (complete)
                complete (success,nil);

        }];
    }] invoke]
    ;
}

-(void)test8AndThen:(ResponseBlock)complete
{
    NSLog(@"begin test8");
    
    [[self ifFailed:_inv(op4AndThen:) retryEverySeconds:@(0.1) andThen:
     ^(BOOL success, id<AHInvocationProtocol> inv)
     {
         [self op2AndThen:
          ^(BOOL success,NSObject* result)
          {
              NSLog(@"test8 done %d",success);
              NSLog(@"--------8--------");
              _a(success);
              if (complete)
                  complete (success,nil);

          }];
     }] invoke]
    ;
}

-(void)test9AndThen:(ResponseBlock)complete
{
    NSLog(@"begin test9");
    
    [[self parallelize:
        @[
          invf(self, @selector(op5WithNum:andStr:andThen:),@1,@"lala",nil)
          ,invf(self, @selector(op5WithNum:andStr:andThen:),@1,@"lala",nil)
        ]
        andThen:
    ^(BOOL success, id<AHInvocationProtocol> invocation)
    {
        NSLog(@"test9 done %d",success);
         NSLog(@"--------9--------");
          _a(success);
        if (complete)
            complete (success,nil);

    }] invoke];
    ;
}

-(void)test10AndThen:(ResponseBlock)complete
{
    NSLog(@"begin test10");
    
    AHSingleInvocation* invocation = _inv(op11AndThen:);
    
    [invocation setFinishedBlock:^(BOOL success, id<AHInvocationProtocol> invocation)
    {
       NSLog(@"test10 done succes: %d, result: %@",success,invocation.result);
       NSLog(@"--------10--------");
      _a(success);
        if (complete)
            complete (success,nil);

    }];
    
     [invocation invoke];
}

-(void)test11AndThen:(ResponseBlock)complete
{
    NSLog(@"begin test11");
    
    AHParallelInvocation* parallel = [self parallelize:
      @[]
               andThen:
      ^(BOOL success, id<AHInvocationProtocol> invocation)
      {
          NSLog(@"test11 done %d, results: %@",success,invocation.result);
          NSLog(@"--------11--------");
          _a(success);
          if (complete)
              complete (success,nil);

      }];
    
    [parallel addInvocation:invf(self, @selector(op5WithNum:andStr:andThen:),@1,@"lala",nil)];
    [parallel addInvocation:invf(self, @selector(op11AndThen:),nil)];
    
    [parallel invoke];
}


-(void)test13AndThen:(ResponseBlock)complete
{
    NSLog(@"begin test13");
    
    
    AHParallelInvocation* parallel = [self parallelize:
                                      @[]
                                               andThen:
                                      ^(BOOL success, id<AHInvocationProtocol> invocation)
                                      {
                                          NSLog(@"parallel done %d, results: %@",success,invocation.result);
                                      }];
    
    [parallel addInvocation:invf(self, @selector(op5WithNum:andStr:andThen:),@1,@"lala",nil)];
    [parallel addInvocation:invf(self, @selector(op11AndThen:),nil)];

    
    AHQueueInvocation* queue = [self queue:
                                      @[]
                                               andThen:
                                      ^(BOOL success, id<AHInvocationProtocol> invocation)
                                      {
                                          NSLog(@"test13 done %d, results: %@",success,invocation.result);
                                          NSLog(@"--------13-------");
                                          _a(success);
                                          if (complete)
                                              complete (success,nil);

                                      }];
    
    [queue addInvocation:invf(self, @selector(op5WithNum:andStr:andThen:),@1,@"lala",nil)];
    [queue addInvocation:invf(self, @selector(op11AndThen:),nil)];
    [queue addInvocation:parallel];
    
    AHInsistentInvocation* insist = [self ifFailed:_inv(op3AndThen:) retryEverySeconds:@2];
    
    [queue addInvocation:insist];
    
    [queue invoke];
}


-(void)test12AndThen:(ResponseBlock)complete
{
    NSLog(@"begin test12");
    
    AHQueueInvocation* queue = [self queue:
                                @[]
                                   andThen:
                                ^(BOOL success, id<AHInvocationProtocol> invocation)
                                {
                                    NSLog(@"test12 done %d, results: %@",success,invocation.result);
                                    NSLog(@"--------12--------");                                    
                                      _a(success);
                                    if (complete)
                                        complete (success,nil);

                                }];
    
    [queue addInvocation:invf(self, @selector(op5WithNum:andStr:andThen:),@1,@"lala",nil)];
    [queue addInvocation:invf(self, @selector(op11AndThen:),nil)];
    
    [queue invoke];
}


-(void)test14AndThen:(ResponseBlock)complete
{
    NSLog(@"begin test14");

    
    AHParallelInvocation* parallel1 = [self parallelize:@[] andThen:^(BOOL success, id<AHInvocationProtocol> invocation) {
        
        NSLog(@"finished %@",invocation.name);
    }];

    AHParallelInvocation* parallel2 = [self parallelize:@[] andThen:^(BOOL success, id<AHInvocationProtocol> invocation) {
        
        NSLog(@"finished %@",invocation.name);
    }];

    AHQueueInvocation* queue = [self queue:@[parallel1,parallel2] andThen:
            ^(BOOL success, id<AHInvocationProtocol> invocation)
    {
        NSLog(@"test14 done %d, results: %@",success,invocation.result);
        NSLog(@"--------14--------");
        _a(success);
        if (complete)
            complete (success,nil);
        
    }];
    
    
    [queue invoke];
//    [parallel1 addInvocation:invf(self, @selector(op11AndThen:),nil)];
    
//    [parallel1 invoke];
}

-(void)test15AndThen:(ResponseBlock)complete
{
    /*
    create parallel with
	queue of 2 items,
    
	inv (
         create parallel with finish block
         
         for x times
         add inv to parallel
         
         invoke parallel
         )
    
    and finish block
    */
    
    [[self parallelize:
        @[
            [self queue:@[
                          _inv(op11AndThen:),
                          _inv(op11AndThen:),
                          _inv(op7AndThen:),
                          ]],
             _inv(op7AndThen:),
             _inv(op7AndThen:),
             _inv(op1AndThen:),
             _inv(op11AndThen:),
             _inv(op6AndThen:)
         ]
    andThen:
    ^(BOOL success, id<AHInvocationProtocol> invocation)
    {
        NSLog(@"test15 done %d, results: %@",success,invocation.result);
        NSLog(@"--------15--------");

        if (complete)
            complete(success,invocation.result);
    }] invoke];
    
}


-(void)testSingle
{
    @autoreleasepool {
        
       AHSingleInvocation* op =  _inv(op1AndThen:);
        
        [op invoke];
    }
}

-(void)testQueue
{
    @autoreleasepool {
    
        AHQueueInvocation* queue = [self queue:@[] andThen:^(BOOL success, id<AHInvocationProtocol> invocation) {
            
            NSLog(@"queue done, success: %d",success);
        }];

        [queue addInvocation:_inv(op1AndThen:)];
        [queue addInvocation:_inv(op1AndThen:)];
        
        [queue invoke];
        
        AHQueueInvocation* queue2 = [self queue:@[
                                                  _inv(op1AndThen:),
                                                  _inv(op1AndThen:)
                                                  ] andThen:^(BOOL success, id<AHInvocationProtocol> invocation) {
            
            NSLog(@"queue2 done, success: %d",success);
        }];
        
        [queue2 invoke];
    }
}

-(void)testParallel
{
    @autoreleasepool {
        
        AHParallelInvocation* parallel = [self parallelize:@[] andThen:^(BOOL success, id<AHInvocationProtocol> invocation) {
            
            NSLog(@"all done, success: %d",success);
        }];
        
        [parallel addInvocation:_inv(op1AndThen:)];
        [parallel addInvocation:_inv(op1AndThen:)];
        
        [parallel invoke];
        
        AHParallelInvocation* parallel2 = [self parallelize:@[
                                                  _inv(op1AndThen:),
                                                  _inv(op1AndThen:)
                                                  ] andThen:^(BOOL success, id<AHInvocationProtocol> invocation) {
                                                      
                                                      NSLog(@"parallel2 done, success: %d",success);
                                                  }];
        
        [parallel2 invoke];

    }
}

-(void)testInsist
{
    @autoreleasepool {
        
        AHInsistentInvocation* insist = [self ifFailed:_inv(op3AndThen:) retryEverySeconds:@2 andThen:
         ^(BOOL success, id<AHInvocationProtocol> invocation)
        {
            NSLog(@"all done, success: %d, result: %@",success, invocation.result);
        }];
        
        [insist invoke];
    }
}

-(void)testAll
{
    @autoreleasepool
    {
        AHQueueInvocation* queue = [self queue:@[] andThen:
        ^(BOOL success, id<AHInvocationProtocol> invocation)
        {
            NSLog(@"all done, success: %d",success);
        }];
        
        queue.name = @"main_AHQueueInvocation";

          [queue addInvocation:_inv(test16AndThen:)]; //leak
        
        [queue addInvocation:_inv(test1AndThen:)]; //no leak

        [queue addInvocation:_inv(test2AndThen:)]; //no leak

        [queue addInvocation:_inv(test3AndThen:)]; //no leak



        [queue addInvocation:_inv(test4AndThen:)];

        [queue addInvocation:_inv(test5AndThen:)]; //leak!


        [queue addInvocation:_inv(test6AndThen:)]; //no leak
        

        [queue addInvocation:_inv(test7AndThen:)]; // leak
        
        [queue addInvocation:_inv(test8AndThen:)]; //leak

        
        [queue addInvocation:_inv(test9AndThen:)]; //no leak

        [queue addInvocation:_inv(test10AndThen:)]; //no leak

        [queue addInvocation:_inv(test11AndThen:)]; //no leak

        [queue addInvocation:_inv(test12AndThen:)]; //no leak

        [queue addInvocation:_inv(test13AndThen:)]; //leak

        [queue addInvocation:_inv(test14AndThen:)]; //no leak
        
        [queue addInvocation:_inv(test15AndThen:)]; //no leak

        [queue invoke];
        
    }
    
}



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    ddLogLevel = LOG_LEVEL_VERBOSE;
    [DDLog addLogger:[DDLogNSLogger sharedInstance]];

    
//    [self testSingle];
//    [self testQueue];
//    [self testParallel];
//    [self testInsist];
    [self testAll];
    
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
