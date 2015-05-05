//
//  NetworkManager.h
//  JSQMessages
//
//  Created by gjwang on 5/5/15.
//  Copyright (c) 2015 Hexed Bits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import "JSQMessages.h"
#import "amqp_tcp_socket.h"

static char * const rabbit_hostname = "localhost";
static char * const login_rabbit_username = "test";
static char * const login_rabbit_password = "test";
static int    const rabbit_port = 5672;

extern NSString * const RecvMsgNotification;

@interface NetworkManager : NSObject

@property (readwrite, atomic) BOOL isNetworkReachable;
@property (readwrite, atomic) BOOL isLoginSuccess;
//@property (strong, nonatomic) NSString *exchange;
//@property (strong, nonatomic) NSString *routingkey;
@property (readwrite, atomic) amqp_connection_state_t conn;
@property (readwrite, nonatomic) BOOL isStop;


- (void)sendMessage: (JSQMessage *)msg;
- (NSString *)consumeMsg;

@end