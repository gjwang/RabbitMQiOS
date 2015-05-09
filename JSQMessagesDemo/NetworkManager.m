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

@interface NetworkManager()
@property (readwrite, atomic) RBConnection* rbConn;
//@property (readwrite, atomic) NSMutableArray* rbConnArray;

@end

@implementation NetworkManager

+ (instancetype)shareNetworkManager{
    static NetworkManager * _shareNetworkManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareNetworkManager = [[NetworkManager alloc] init];
    });
    
    return _shareNetworkManager;
}

- (instancetype) init{
    //maybe use singleton
    self = [super init];
    if (self){
        self.rbConn = nil;
        self.isNetworkReachable = NO;//network status is Unknown actully;
        //self.rbConnArray = [[NSMutableArray alloc]init];
        
        [self networkReachability];
        [self registerRecvMsgObserver];
        [self registerConnLostObserver];
    }
    return self;
}


- (void) closeConn{
    //[self.rbConnArray removeObject:self.rbConn];
    
    @synchronized(self){
        if (self.rbConn) {
            [self.rbConn close];
        }
        
        self.rbConn = nil;
    }
    
    //NSLog(@"closed rbConnArray count=%lu", (unsigned long)[self.rbConnArray count]);

}

/*
- (BOOL)startConnetionBlock
{
    NSLog(@"startConnetionBlock");
    [self closeConn];
    
    @synchronized(self) {
        self.rbConn = [[RBConnection alloc] init];
        return [self.rbConn login];
    }
}
*/

- (void) startConnetionAsync
{
    @synchronized(self) {
        //It is not thread safe, but if keep operation NetworkManger in main queue, it should be OK
        if ([self.rbConn isLogging]) {
            NSLog(@"startConnetionAsync prev connection is still logging");
            return;
        }
        
        if (self.rbConn) {
            NSLog(@"startConnetionAsync close the old connection");
        }
        [self closeConn];
        
        //RBConnection *rbConn = nil;
        NSLog(@"startConnetionAsync start a new connetion");
        self.rbConn = [[RBConnection alloc] init];
        //self.rbConn = rbConn;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            [self.rbConn login];
        });
        
        //[self.rbConnArray addObject:rbConn];
    }
    
    //NSLog(@"started rbConnArray count=%lu", (unsigned long)[self.rbConnArray count]);
}

- (BOOL)isLoginSuccess{
    @synchronized(self) {
        if (self.rbConn) {
            return [self.rbConn isLoginSuccess];
        }else{
            return NO;
        }
    }
}

#pragma mark - Process Msg arrived notification
//base on the msg type, and senderid, dispatch the msg
- (void)dispatchRecvMsg:(NSString *)recvRawMsg
{
    //dispatch Recv Msg
}

- (void) registerRecvMsgObserver{
    NSLog(@"Register recvMsg Notification = %@", RecvMsgNotification);
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    __weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:RecvMsgNotification
                                                      object:nil
                                                       queue:mainQueue
                                                  usingBlock:^(NSNotification *note) {
                                                NSLog(@"recv msg=%@", note.userInfo[@"RecvMsg"]);
                                                [weakSelf dispatchRecvMsg:note.userInfo[@"RecvMsg"]];
                                                  }
                        ];
    
    
}

- (void) sendMessage: (JSQMessage *)msg
{
    @synchronized(self) {
        if (self.rbConn) {
            [self.rbConn sendMessage:msg];
        }
    }
}


- (void) registerConnLostObserver{
    NSLog(@"Register %@", ConnectionLostNotification);
    //_recvMsgNotificationCenter = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    //__weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:ConnectionLostNotification
                                                               object:nil
                                                                queue:mainQueue
                                                           usingBlock:^(NSNotification *note) {
                                                               NSLog(@"recv ConnectionLostNotification");
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
            [self closeConn];
        });

        //TODO: fire a nofitcation
        //self.isNetworkReachable = NO;
    };
    
    // Start the notifier, which will cause the reachability object to retain itself!
    [reach startNotifier];
}

@end