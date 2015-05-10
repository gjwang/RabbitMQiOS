//
//  RBConnection.h
//  JSQMessages
//
//  Created by gjwang on 5/8/15.
//  Copyright (c) 2015 Hexed Bits. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "amqp_tcp_socket.h"
#import "JSQMessage.h"

static char * const rabbit_hostname = "localhost";
static char * const login_rabbit_username = "test";
static char * const login_rabbit_password = "test";
static int    const rabbit_port = 5672;
NSInteger a;

extern NSString * const RecvMsgNotification;
extern NSString * const ConnectionLostNotification;

//Application should not use RBConnection directly,
//Use NetworkManager instead
@interface RBConnection : NSObject
//@property (strong, nonatomic) NSString *exchange;
//@property (strong, nonatomic) NSString *routingkey;
@property (readwrite, nonatomic) char *username;
@property (readwrite, nonatomic) char *password;

//TODO: Use enum{}status instead
@property (readwrite, nonatomic) BOOL isLoginSuccess;
//@property BOOL isLoginSuccess;
@property (readwrite, nonatomic) BOOL isLogging;

- (BOOL)login;
- (void)sendMessage: (JSQMessage *)msg;
- (void)close;

@end
