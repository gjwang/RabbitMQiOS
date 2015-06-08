//
//  RBConnection.h
//  JSQMessages
//
//  Created by gjwang on 5/8/15.
//  Copyright (c) 2015 Hexed Bits. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "amqp_tcp_socket.h"
#import "RBTMessage.h"

static char * const rabbit_hostname = "localhost";
static char * const login_rabbit_username = "test";
static char * const login_rabbit_password = "test";
static int    const rabbit_port = 5672;


extern NSString * const RBRecvMsgNotification;
extern NSString * const RBLostNotification;
extern NSString * const RBLoginFailedNotification;

//Application should not use RBConnection directly,
//Use NetworkManager instead

typedef enum: NSUInteger {
    RBConnLogout,
    RBConnLogging,
    RBConnLogSuccess,
    RBConnLogFailed
}RBConnStatus;

@interface RBConnection : NSObject
//@property (strong, nonatomic) NSString *exchange;
//@property (strong, nonatomic) NSString *routingkey;
@property (readwrite, nonatomic) char *username;
@property (readwrite, nonatomic) char *password;
@property (readonly, nonatomic, copy) NSString *receiveFromId;
@property (readwrite, nonatomic) RBConnStatus rbConnStatus;

- (instancetype)initWithReiverId: (NSString*) receiverId;
- (RBConnStatus)login;
- (RBConnStatus) loginAsync;
- (void)sendMessage: (JSQMessage *)msg;
- (void)close;

@end
