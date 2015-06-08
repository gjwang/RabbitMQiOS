//
//  NetworkManager.m
//  JSQMessages
//
//  Created by gjwang on 5/5/15.
//  Copyright (c) 2015 Hexed Bits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkManager.h"
#import "amqp_tcp_socket.h"
#import "Reachability.h"
#import "RBConnection.h"
#import "DemoModelData.h"

@interface NetworkManager()
@property (strong, readwrite, atomic) RBConnection* rbConn;

@end

@implementation NetworkManager

+ (instancetype)shareNetworkManager{
    static NetworkManager * _shareNetworkManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *receiverId = [DemoModelData shareDemoDodelData].myselfId;
        _shareNetworkManager = [[NetworkManager alloc] initWithReceiverId:receiverId];
    });
    
    return _shareNetworkManager;
}

- (instancetype) initWithReceiverId:(NSString *)receiverId{
    NSParameterAssert(receiverId != nil);
    
    //maybe use singleton
    self = [super init];
    if (self){
        _rbConn = nil;
        _isNetworkReachable = NO;//network status is Unknown actully;
        _receiverId = receiverId;
        
        [self networkReachability];
        [self registerRecvMsgObserver];
        [self registerConnLostObserver];
        [self registerRBConnObserver];
        
        //For runs on simulator
        [self startConnetionAsync];
    }
    return self;
}


- (void) closeConn{
    @synchronized(self){
        if (self.rbConn) {
            [self.rbConn close];
        }
        
        self.rbConn = nil;
    }
}

/*
- (BOOL)startConnetionBlock
{
    NSLog(@"startConnetionBlock");
    [self closeConn];
    
    @synchronized(self) {
        self.rbConn = [[RBConnection alloc] initWithReiverId:self.receiverId];
        return [self.rbConn login];
    }
}
*/


- (void) startConnetionAsync
{
    @synchronized(self) {
        //It is not thread safe, but if keep operation NetworkManger in main queue, it should be OK
        if (self.rbConn.rbConnStatus == RBConnLogging) {
            NSLog(@"startConnetionAsync: prev connection is still logging");
            return;
        }
        
        if (self.rbConn) {
            NSLog(@"startConnetionAsync: close the old connection");
        }
        [self closeConn];
        
        NSLog(@"startConnetionAsync start a new connetion");
        self.rbConn = [[RBConnection alloc] initWithReiverId:self.receiverId];
        
        [self.rbConn loginAsync];
    }
}

#pragma mark - Process Msg arrived notification
//base on the msg type, and senderid, dispatch the msg
- (void)dispatchRecvMsg:(NSString *)recvRawMsg
{
    //dispatch Recv Msg
}

- (void) registerRecvMsgObserver{
    NSLog(@"Register recvMsg Notification = %@", RBRecvMsgNotification);
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    __weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:RBRecvMsgNotification
                                                      object:nil
                                                       queue:mainQueue
                                                  usingBlock:^(NSNotification *note) {
                                                //NSLog(@"notify recv msg=%@", note.userInfo[@"RecvMsg"]);
                                                [weakSelf dispatchRecvMsg:note.userInfo[@"RecvMsg"]];
                                                  }
                        ];
    
    
}

- (void) sendMessage: (RBTMessage *)msg
{
    //not thread safe
    @synchronized(self) {
        if (self.rbConn) {
            [self.rbConn sendMessage:msg];
        }
    }
}

- (void) registerRBConnObserver{
    NSLog(@"Register %@", RBLoginFailedNotification);
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:RBLoginFailedNotification
                                                      object:nil
                                                       queue:mainQueue
                                                  usingBlock:^(NSNotification *note) {
                                                      NSLog(@"recv %@", RBLoginFailedNotification);
                                                      
                                                      //if (self.retry_times < MAX_RETRY_TIMES) {
                                                      //    self.retry_times++;
                                                      //    [self startConnetionAsync];
                                                      //}
                                                      NSLog(@"relogin 1 sec late");
                                                      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                          [self startConnetionAsync];
                                                      });

                                                  }
     ];
}

- (void) registerConnLostObserver{
    NSLog(@"Register %@", RBLostNotification);
    //_recvMsgNotificationCenter = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    //__weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:RBLostNotification
                                                               object:nil
                                                                queue:mainQueue
                                                           usingBlock:^(NSNotification *note) {
                                                               NSLog(@"recv %@", RBLostNotification);
                                                               [self startConnetionAsync];
                                                           }
                        ];
    
    
}

- (void) networkReachability
{
    //it seems not totally works in simulator
    //when swith beteewn WIFI, or 3G/4G and WiFi, would receive network status change notification
    
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.baidu.com"];
    
    //reach.reachableOnWWAN = YES;
    
    // Set the blocks
    reach.reachableBlock = ^(Reachability *reach)
    {
        // keep in mind this is called on a background thread
        // and if you are updating the UI it needs to happen
        // on the main thread, like this:

        dispatch_async(dispatch_get_main_queue(), ^{
            self.isNetworkReachable = YES;
            //TODO: Fire a notification
            NSLog(@"REACHABLE!");
            [self startConnetionAsync];
        });
    };
    
    reach.unreachableBlock = ^(Reachability *reach)
    {
        

        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"UNREACHABLE!");
            //[self closeConn];
        });

        //TODO: fire a nofitcation
        //self.isNetworkReachable = NO;
    };
    
    // Start the notifier, which will cause the reachability object to retain itself!
    [reach startNotifier];
}

- (void) dealloc{
    NSLog(@"NetworkManger dealloc");
}
@end